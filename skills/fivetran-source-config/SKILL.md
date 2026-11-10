---
name: fivetran-source-config
description: Set up or refresh the `<package>__source_config` vars for every Fivetran dbt package in a project, so each package knows which expected source columns the connection does not sync and which are renamed. Use this whenever the user installs or adds a Fivetran dbt package (dbt_stripe, dbt_salesforce, and so on), asks to configure Fivetran packages for missing or renamed columns, hits column-not-found or silently null-filled columns in a Fivetran package, mentions Quickstart-style source config or "source_config", or wants to re-run package config after adding a package or changing a connection. One run covers all the Fivetran packages in the project's dependency tree. Writes to vars.yml or dbt_project.yml, whichever the project already uses.
---

# fivetran-source-config

Generate the `<package>__source_config` var for each Fivetran package in the project, from what is actually in the warehouse, and put it where the project already keeps its vars. One run handles every Fivetran package in the dependency tree. Re-run it whenever a package is added or a connection changes.

## Why this exists

A Fivetran package expects a fixed list of columns per source table. A connection that doesn't sync one of them would otherwise be silently null-filled, and a renamed column is silently dropped. The var makes both explicit: every expected column is either mapped to a real column or marked as not synced. The skill builds it from the diff each package reports, so nobody has to write it by hand.

Two bundled scripts do the deterministic parts so results are consistent and re-runs are safe: `scripts/find_packages.py` (which packages) and `scripts/source_config.py` (rename suggestions, merging into the vars file, checking). Run them with `uv run --with pyyaml` and `uv run --with ruamel.yaml` respectively.

## Step 1: Find the packages

Make sure packages are installed (`dbt deps`) and run, from the project root:

```
uv run --with pyyaml <skill-dir>/scripts/find_packages.py
```

It lists every package, root project included, that defines a `get_column_diffs` macro (the contract at the end of this file), with its `name`, `version`, `origin`, and `reads_var`. Transitive dependencies are covered because dbt installs them all in the same packages directory. If the user named specific packages, use only those. If the list is empty, say so: no installed Fivetran package supports this yet, and the usual fix is upgrading the packages.

`reads_var: false` means nothing in that package version references `<name>__source_config`, so the var has no effect yet. Generate it anyway, since it is harmless and will be ready when the package starts reading it, but say so plainly in your report. A config that silently does nothing would be worse than none, so never leave that out.

## Step 2: Get each package's diff

For each package, from the project root, using the project's own profile and vars, save its JSON line to a file:

```
dbt run-operation <name>.get_column_diffs | grep -m1 '^{' > <tmp>/<name>.json
```

`<name>` is the dbt project name from the script, which is not always the repo name (`dbt_stripe` is `stripe`). The JSON is the one line starting with `{`; the rest is dbt's own logging. It looks like:

```
{ "<source table>": { "missing": [...], "extra": [...], "source_missing": false, "source_schemas": ["..."] } }
```

Only sources with a difference appear, so an absent source is clean, and `{}` means nothing differs for that package. An **empty** file means the macro failed before printing: re-run it without the `grep` to read the error (usually an unreachable warehouse, or sources not configured the way the user normally runs dbt). Run it this way and not through `dbt show` or another macro: only `run-operation <package>.<macro>` resolves the package's own vars. Pass the same `--vars`/`--target` the user normally uses; adding `--vars '{fivetran__remove_empty_table_warnings: true}'` is optional and only silences the empty-table warnings.

- **`missing`**: columns the package expects that the source lacks.
- **`extra`**: source columns the package doesn't model. Report them; never add them to the var.
- **`source_missing: true`**: the source table isn't there at all, and `missing` is every expected column. Don't map each one. Fivetran packages already build an empty staging model when a source table is absent, so nothing needs configuring. Tell the user, and if they want the models off, look for an `enabled=var(...)` in that package's models (not every package has a switch).
- **`source_schemas`**: the schema(s) the source was found in. More than one means schemas are unioned, and the diff is merged across them, so it can't say which schema lacks which column. The scripts skip these and list them; ask the user instead of copying one mapping under every schema.

**Sanity-check large diffs before writing anything.** A source missing most of its expected columns (or with extras that look like another table's columns) usually means something is off upstream: an identifier var pointing at the wrong table, an old connector version, or the wrong schema. Marking dozens of columns "not synced" would paper over that. Raise it with the user first. If nobody is available to ask (an unattended run), still write the entries, since they match what the package does anyway (null-fill), but put the suspicious sources at the top of your report so the user can review them.

## Step 3: Decide where the vars go

dbt rejects `vars:` defined in both `vars.yml` and `dbt_project.yml` (`InvalidConfig dbt1005`), so exactly one convention is in use. Detect it from the project root, in this order:

1. `vars.yml` exists: write there.
2. Otherwise `dbt_project.yml` has a `vars:` block: write there.
3. Otherwise there are no vars yet: prefer `vars.yml` if the dbt version supports it, else `dbt_project.yml`. Create `vars.yml` containing a top-level `vars:` key.

For step 3 run `dbt --version`. `vars.yml` is supported on dbt Core v1.12 and later (dbt docs, "Project variables") and on dbt Fusion 2.x. Older uses `dbt_project.yml`. If the version can't be determined, use `dbt_project.yml`, because it works everywhere.

Both files use a top-level `vars:` key, and `<name>__source_config` sits directly under it (not nested under a package key).

## Step 4: Write each package's var

The var is keyed by destination schema, then source table, then `columns`. The schema comes from the diff's `source_schemas` and the table is the diff's key, so the scripts need no translation:

```yaml
vars:
  stripe__source_config:
    <destination schema>:         # from source_schemas
      <source table>:             # the diff's key
        columns:
          business_type: "<fivetran_not_synced>"
          company_phone: company_phone_number
```

Every `missing` column becomes `"<fivetran_not_synced>"` (quoted, since unquoted YAML breaks on the angle brackets), unless the column was renamed in the warehouse, in which case it maps to the new name. A rename appears as one `missing` plus one `extra`, and the diff can't tell they are linked, so get the pairs from the script and **confirm each with the user**. A wrong pairing silently maps the wrong data into a column.

```
uv run --with ruamel.yaml <skill-dir>/scripts/source_config.py suggest-renames --diff <tmp>/<name>.json
```

The suggestions are a heuristic (names that match ignoring leading underscores, one name inside the other, or the same last word); treat them as candidates, not answers, and also look at the remaining `extra` columns yourself. A pair that differs only by a leading underscore (`fivetran_synced` and `_fivetran_synced`) is usually a typo in the package's expected-columns list, not a rename the user made, because Fivetran's system columns start with `_fivetran_`. Report those to the user as a likely package bug instead of mapping them. Put the confirmed pairs in `<tmp>/<name>-renames.json` as `{"<source>": {"<missing column>": "<new name>"}}`, preview, then write:

```
uv run --with ruamel.yaml <skill-dir>/scripts/source_config.py apply --vars-file <vars file> --package <name> --diff <tmp>/<name>.json --renames <tmp>/<name>-renames.json --dry-run
uv run --with ruamel.yaml <skill-dir>/scripts/source_config.py apply --vars-file <vars file> --package <name> --diff <tmp>/<name>.json --renames <tmp>/<name>-renames.json
```

`apply` edits the file in place without disturbing the rest of it: comments, ordering and quoting are preserved. It reports what it added, what was already covered, anything stale, and the sources it skipped (absent, or unioned across schemas). It is safe to re-run:

- Existing entries are never overwritten, including keys you don't recognize (such as a `sync_mode`) and the user's own mappings. It only adds what is new.
- The diff compares against the package's expected names and ignores any var already set, so on a re-run it still lists columns the existing var handles. `apply` treats a `missing` column that already has an entry as covered, so don't re-ask about it.
- A `stale` entry is an existing `"<fivetran_not_synced>"` whose column is no longer missing (the source gained it). Point it out and offer to remove it; don't delete it silently.

`apply` doesn't keep a backup. The vars file is normally tracked in git, so a bad edit is one `git checkout` away; if it isn't tracked, copy it first. Do not rewrite the vars file by hand or with a YAML library that drops comments. If you need to edit it some other way, make the smallest textual change.

## Step 5: Verify and report

Re-run each package's `get_column_diffs` to a file and check the var against it:

```
uv run --with ruamel.yaml <skill-dir>/scripts/source_config.py check --vars-file <vars file> --package <name> --diff <tmp>/<name>.json
```

It exits non-zero if any `missing` column still has no entry, and lists stale entries and skipped sources. Then tell the user, per package: which file was edited and why that one, what was added, what is left for them to decide (renames, unioned schemas, sources that looked wrong), the unmodeled `extra` columns, and whether `reads_var` was false.

## The contract a package must meet

So that this works across packages, each Fivetran package that supports it provides a `get_column_diffs` macro:

- It returns, and when run with `dbt run-operation` also logs as JSON (`flags.WHICH == 'run-operation'`), a dict of `{source table: {missing, extra, source_missing, source_schemas}}` containing only sources with a difference. `missing` and `extra` are lowercase column names; the keys are source table names exactly as in the package's source yml.
- It compares the package's expected columns with the **source tables themselves**, resolved the way the package's staging models resolve them, not with built staging views, which go stale.
- Its sibling macro calls are qualified with the package name (`stripe.some_macro()`), because unqualified calls don't resolve when a package macro is invoked from outside.
- It reads `<name>__source_config` somewhere (macros or models) for the var to take effect.

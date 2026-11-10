---
name: fivetran-source-config
description: Set up or refresh the `<package>__source_config` vars for every Fivetran dbt package in a project, so each package knows which expected source columns the connection does not sync and which are renamed. Use this whenever the user installs or adds a Fivetran dbt package (dbt_stripe, dbt_salesforce, and so on), asks to configure Fivetran packages for missing or renamed columns, hits column-not-found or silently null-filled columns in a Fivetran package, mentions Quickstart-style source config or "source_config", or wants to re-run package config after adding a package or changing a connection. One run covers all the Fivetran packages in the project's dependency tree. Writes to vars.yml or dbt_project.yml, whichever the project already uses.
---

# fivetran-source-config

Generate the `<package>__source_config` var for each Fivetran package in the project, from what is actually in the warehouse, and put it where the project already keeps its vars. One run handles every Fivetran package in the dependency tree. Re-run it whenever a package is added or a connection changes.

## Why this exists

A Fivetran package expects a fixed list of columns per source table. A connection that doesn't sync one of them would otherwise be silently null-filled, and a renamed column is silently dropped. The var makes both explicit: every expected column is either mapped to a real column or marked as not synced. The skill builds it from the diff each package reports, so nobody has to write it by hand.

## Step 1: Find the packages

Make sure packages are installed (`dbt deps`) and run the bundled script from the project root:

```
uv run --with pyyaml <skill-dir>/scripts/find_packages.py
```

It lists every package, root project included, that defines a `get_column_diffs` macro (the contract at the end of this file), with its `name`, `version`, `origin`, and `reads_var`. Transitive dependencies are covered because dbt installs them all in the same packages directory. If the user named specific packages, use only those. If the list is empty, say so: no installed Fivetran package supports this yet, and the usual fix is upgrading the packages.

`reads_var: false` means nothing in that package version references `<name>__source_config`, so the var would have no effect yet. Still generate it if the user wants it, but tell them clearly, because a config that silently does nothing is worse than none.

## Step 2: Get each package's diff

For each package, from the project root, using the project's own profile and vars:

```
dbt run-operation <name>.get_column_diffs
```

`<name>` is the dbt project name from the script, which is not always the repo name (`dbt_stripe` is `stripe`). It prints a JSON line (the one starting with `{`; the rest is dbt's own logging) of:

```
{ "<source table>": { "missing": [...], "extra": [...], "source_missing": false, "source_schemas": ["..."] } }
```

Only sources with a difference appear, so an absent source is clean. Run it this way and not through `dbt show` or another macro: only `run-operation <package>.<macro>` resolves the package's own vars. The warehouse must be reachable and the package's sources configured the way the user normally runs it.

- **`missing`**: columns the package expects that the source lacks.
- **`extra`**: source columns the package doesn't model. Report them; don't add them to the var.
- **`source_missing: true`**: the source table isn't there at all, and `missing` is every expected column. Don't map each one. Tell the user and suggest disabling that table's models with the package's own enable var, instead.
- **`source_schemas`**: the schema(s) the source was found in. More than one means schemas are unioned, and the diff is merged across them, so it can't say which schema lacks which column. Ask the user; don't copy one mapping under every schema.

## Step 3: Decide where the vars go

dbt rejects `vars:` defined in both `vars.yml` and `dbt_project.yml` (`InvalidConfig dbt1005`), so exactly one convention is in use. Detect it from the project root, in this order:

1. `vars.yml` exists: write there.
2. Otherwise `dbt_project.yml` has a `vars:` block: write there.
3. Otherwise there are no vars yet: prefer `vars.yml` if the dbt version supports it, else `dbt_project.yml`.

For step 3 run `dbt --version`. `vars.yml` is supported on dbt Core v1.12 and later (dbt docs, "Project variables") and on dbt Fusion 2.x. Older uses `dbt_project.yml`. If the version can't be determined, use `dbt_project.yml`, because it works everywhere.

Both files use a top-level `vars:` key, and `<name>__source_config` sits directly under it (not nested under a package key).

## Step 4: Merge each package's var

The var is keyed by destination schema, then source table, then `columns`. Take the schema from `source_schemas` and the table from the diff's key:

```yaml
vars:
  stripe__source_config:
    <destination schema>:         # from source_schemas
      <source table>:             # the diff's key
        columns:
          business_type: "<fivetran_not_synced>"
          company_phone: company_phone_number
```

For each source with a non-empty diff, map every `missing` column:

- Truly absent: `"<fivetran_not_synced>"`. Quote it, because unquoted YAML breaks on the angle brackets.
- Renamed in the warehouse: the new name. A rename shows up as one `missing` plus one `extra`, and the diff can't tell they are linked, so propose likely pairs and **ask the user to confirm** each one. A wrong pairing silently maps the wrong data into a column.

**Make re-runs safe.** The diff compares against the package's expected names and ignores any var already set, so on a second run it still lists columns the existing var already handles. Therefore:

- Merge into the existing var and keep everything already there, including keys you don't recognize (such as a `sync_mode`) and the user's own comments. Add only what is new.
- A `missing` column that already has an entry for that schema and table is resolved. Don't re-ask or overwrite it, and don't report the rename target as an unmodeled `extra`.
- An existing `"<fivetran_not_synced>"` entry whose column is no longer in `missing` is stale: the source gained that column. Point it out and offer to remove it; don't delete silently.

Keep any other vars in the file untouched.

## Step 5: Verify and report

Re-run each package's `get_column_diffs` and confirm that every remaining `missing` column has an entry in the var. Then tell the user, per package: which file was edited and why that one, what was added, what was left for them to decide (renames, unioned schemas, absent sources, stale entries), the unmodeled `extra` columns, and whether `reads_var` was false.

## The contract a package must meet

So that this works across packages, each Fivetran package that supports it provides a `get_column_diffs` macro:

- It returns, and when run with `dbt run-operation` also logs as JSON (`flags.WHICH == 'run-operation'`), a dict of `{source table: {missing, extra, source_missing, source_schemas}}` containing only sources with a difference. `missing` and `extra` are lowercase column names; the keys are source table names exactly as in the package's source yml.
- It compares the package's expected columns with the **source tables themselves**, resolved the way the package's staging models resolve them, not with built staging views, which go stale.
- Its sibling macro calls are qualified with the package name (`stripe.some_macro()`), because unqualified calls don't resolve when a package macro is invoked from outside.
- It reads `<name>__source_config` somewhere (macros or models) for the var to take effect.

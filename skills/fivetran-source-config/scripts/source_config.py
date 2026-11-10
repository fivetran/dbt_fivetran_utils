#!/usr/bin/env python3
"""Deterministic helpers for the fivetran-source-config skill.

Takes the JSON a package's `get_column_diffs` prints and maintains the `<package>__source_config` var
in a vars.yml or dbt_project.yml file, without disturbing the rest of the file (comments, ordering and
quoting are preserved).

  source_config.py suggest-renames --diff DIFF.json
      Likely rename pairs (a `missing` column and an `extra` column with similar names). Heuristic only:
      the user must confirm every pairing.

  source_config.py apply --vars-file FILE --package NAME --diff DIFF.json [--renames RENAMES.json] [--dry-run]
      Add an entry for every `missing` column: "<fivetran_not_synced>", or the new name from RENAMES.json
      ({source: {missing_column: new_name}}). Existing entries are never overwritten. Prints a compact
      summary; --verbose lists every entry.

  source_config.py check --vars-file FILE --package NAME --diff DIFF.json
      Report `missing` columns that still have no entry, and stale entries. Exit 1 if any are uncovered.

Run with: uv run --with ruamel.yaml source_config.py <command> ...

The var is keyed schema -> source table -> columns, where schema comes from the diff's `source_schemas`.
Sources that are absent (`source_missing`) or found in more than one schema are skipped and reported,
because a column mapping can't be derived for them without a decision from the user.
"""
import argparse
import difflib
import json
import sys
from pathlib import Path

from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap
from ruamel.yaml.scalarstring import DoubleQuotedScalarString

NOT_SYNCED = "<fivetran_not_synced>"


def make_yaml() -> YAML:
    yaml = YAML(typ="rt")
    yaml.preserve_quotes = True
    yaml.width = 4096  # don't re-wrap long lines in the user's file
    yaml.indent(mapping=2, sequence=4, offset=2)
    return yaml


def load(path: str):
    yaml = make_yaml()
    data = yaml.load(Path(path).read_text())
    if data is None:
        data = CommentedMap()
    return yaml, data


def load_diff(path: str) -> dict:
    return json.loads(Path(path).read_text())


def classify(diff: dict):
    """Split sources into those we can map and those needing the user. Returns (mappable, skipped)."""
    mappable, skipped = {}, []
    for source, info in diff.items():
        if info.get("source_missing"):
            skipped.append({"source": source, "reason": "source table not found"})
        elif len(info.get("source_schemas", [])) != 1:
            skipped.append({"source": source, "reason": "found in several schemas (unioned); needs a per-schema decision"})
        else:
            mappable[source] = info
    return mappable, skipped


def existing_columns(cfg, schema: str, source: str) -> dict:
    if not cfg:
        return {}
    return ((cfg.get(schema) or {}).get(source) or {}).get("columns") or {}


def stale_entries(cfg, diff: dict, mappable: dict) -> list:
    """Existing "<fivetran_not_synced>" entries for columns the source now has."""
    stale = []
    for schema, sources in (cfg or {}).items():
        for source, body in (sources or {}).items():
            info = diff.get(source)
            if info is not None and source not in mappable:
                continue  # absent/unioned: can't judge
            still_missing = set(info["missing"]) if info else set()
            if info is not None and schema not in info["source_schemas"]:
                continue
            for column, value in ((body or {}).get("columns") or {}).items():
                if str(value) == NOT_SYNCED and column not in still_missing:
                    stale.append({"schema": schema, "source": source, "column": column})
    return stale


def rename_score(missing: str, extra: str) -> float:
    """How likely `extra` is a renamed `missing`. 0 means not a candidate.

    Real renames tend to be one of: the same name once leading underscores are ignored, one name
    contained in the other (company_phone -> company_phone_number), or the same trailing word with
    similar overall spelling (num_minutes -> total_minutes). Sharing only a leading word
    (invoice_pdf, invoice_id) is not enough, because that is just two columns of the same table.
    """
    a, b = missing.lstrip("_"), extra.lstrip("_")
    if a == b:
        return 1.0
    ta, tb = a.split("_"), b.split("_")
    smaller, larger = (ta, tb) if len(ta) <= len(tb) else (tb, ta)
    if len(smaller) >= 2 and all(t in larger for t in smaller):
        return 0.9
    ratio = difflib.SequenceMatcher(None, a, b).ratio()
    if ta[-1] == tb[-1] and ratio >= 0.6:
        return ratio
    return 0.0


def cmd_suggest(args) -> int:
    out = []
    for source, info in load_diff(args.diff).items():
        for missing in info["missing"]:
            scored = [(rename_score(missing, extra), extra) for extra in info["extra"]]
            score, extra = max(scored, default=(0.0, None))
            if score > 0:
                out.append({"source": source, "missing": missing, "candidate": extra, "score": round(score, 2)})
    print(json.dumps(sorted(out, key=lambda r: -r["score"]), indent=2))
    return 0


def cmd_apply(args) -> int:
    yaml, data = load(args.vars_file)
    diff = load_diff(args.diff)
    renames = json.loads(Path(args.renames).read_text()) if args.renames else {}
    mappable, skipped = classify(diff)

    if "vars" not in data or data["vars"] is None:
        data["vars"] = CommentedMap()
    key = f"{args.package}__source_config"
    if key not in data["vars"] or data["vars"][key] is None:
        data["vars"][key] = CommentedMap()
    cfg = data["vars"][key]

    added, kept = [], []
    for source, info in mappable.items():
        schema = info["source_schemas"][0]
        for column in info["missing"]:
            have = existing_columns(cfg, schema, source)
            if column in have:
                kept.append({"source": source, "column": column, "value": str(have[column])})
                continue
            value = renames.get(source, {}).get(column, NOT_SYNCED)
            node = cfg.setdefault(schema, CommentedMap())
            node = node.setdefault(source, CommentedMap())
            cols = node.setdefault("columns", CommentedMap())
            cols[column] = DoubleQuotedScalarString(NOT_SYNCED) if value == NOT_SYNCED else value
            added.append({"schema": schema, "source": source, "column": column, "value": value})

    by_source = {}
    for entry in added:
        by_source[entry["source"]] = by_source.get(entry["source"], 0) + 1
    summary = {
        "file": args.vars_file,
        "var": key,
        "dry_run": args.dry_run,
        "added_count": len(added),
        "added_by_source": by_source,
        "added_renames": [e for e in added if e["value"] != NOT_SYNCED],
        "already_covered_count": len(kept),
        "stale": stale_entries(cfg, diff, mappable),
        "skipped": skipped,
    }
    if args.verbose:
        summary["added"] = added
        summary["already_covered"] = kept
    if added and not args.dry_run:
        with open(args.vars_file, "w") as f:
            yaml.dump(data, f)
    print(json.dumps(summary, indent=2))
    return 0


def cmd_check(args) -> int:
    _, data = load(args.vars_file)
    diff = load_diff(args.diff)
    cfg = ((data or {}).get("vars") or {}).get(f"{args.package}__source_config")
    mappable, skipped = classify(diff)
    uncovered = []
    for source, info in mappable.items():
        have = existing_columns(cfg, info["source_schemas"][0], source)
        uncovered += [{"source": source, "column": c} for c in info["missing"] if c not in have]
    report = {
        "package": args.package,
        "uncovered": uncovered,
        "stale": stale_entries(cfg, diff, mappable),
        "skipped": skipped,
    }
    print(json.dumps(report, indent=2))
    return 1 if uncovered else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("suggest-renames")
    p.add_argument("--diff", required=True)
    p.set_defaults(func=cmd_suggest)

    for name, func in (("apply", cmd_apply), ("check", cmd_check)):
        p = sub.add_parser(name)
        p.add_argument("--vars-file", required=True)
        p.add_argument("--package", required=True)
        p.add_argument("--diff", required=True)
        if name == "apply":
            p.add_argument("--renames")
            p.add_argument("--dry-run", action="store_true")
            p.add_argument("--verbose", action="store_true", help="list every added and already-covered entry")
        p.set_defaults(func=func)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())

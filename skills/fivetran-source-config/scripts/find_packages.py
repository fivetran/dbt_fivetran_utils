#!/usr/bin/env python3
"""List the dbt packages in a project that implement the Fivetran column-diff contract.

A package qualifies when it defines a `get_column_diffs` macro. Every installed package is checked
(transitive dependencies included, since dbt flattens them into the packages directory), plus the
root project itself, so this works for a project that depends on several Fivetran packages and for a
package developer running from the package's own repo.

Usage: uv run --with pyyaml find_packages.py [PROJECT_DIR]    (default: current directory)

Prints a JSON list of:
  name       dbt project name; this is the namespace for `dbt run-operation <name>.get_column_diffs`
  version    version from the package's dbt_project.yml
  origin     "hub:fivetran/<x>", "git:<url>", "local:<path>", "root", or "unknown" (from package-lock.yml)
  reads_var  whether anything in the package references `<name>__source_config`; if false, the var has
             no effect with the installed version and the user should be told
"""
import json
import re
import sys
from pathlib import Path

import yaml

MACRO = re.compile(r"\{%-?\s*macro\s+get_column_diffs\s*\(")


def load_yaml(path: Path):
    try:
        return yaml.safe_load(path.read_text()) or {}
    except (OSError, yaml.YAMLError):
        return {}


def project_dirs(pkg_dir: Path, meta: dict, key: str, default: str) -> list:
    """The package's own directories for a path setting (macro-paths, model-paths).

    Only these are searched, never nested ones: the root project may contain installed or vendored
    packages, and matching their macros would wrongly credit the root with their contract.
    """
    return [pkg_dir / p for p in meta.get(key) or [default]]


def sql_files(dirs: list):
    for d in dirs:
        if d.is_dir():
            yield from d.rglob("*.sql")


def has_contract(pkg_dir: Path, meta: dict) -> bool:
    macro_dirs = project_dirs(pkg_dir, meta, "macro-paths", "macros")
    return any(MACRO.search(f.read_text(errors="ignore")) for f in sql_files(macro_dirs))


def references_var(pkg_dir: Path, meta: dict, name: str) -> bool:
    needle = f"{name}__source_config"
    files = list(sql_files(project_dirs(pkg_dir, meta, "macro-paths", "macros")))
    files += list(sql_files(project_dirs(pkg_dir, meta, "model-paths", "models")))
    files.append(pkg_dir / "dbt_project.yml")
    return any(f.is_file() and needle in f.read_text(errors="ignore") for f in files)


def origins(root: Path) -> dict:
    """Map package name -> origin string, from package-lock.yml when present."""
    out = {}
    for entry in load_yaml(root / "package-lock.yml").get("packages", []) or []:
        if "package" in entry:
            origin = f"hub:{entry['package']}"
            name = entry.get("name") or entry["package"].split("/")[-1]
        elif "git" in entry:
            origin = f"git:{entry['git']}"
            name = entry.get("name") or entry["git"].rstrip("/").split("/")[-1].removesuffix(".git")
        elif "local" in entry:
            origin = f"local:{entry['local']}"
            name = entry.get("name")
        else:
            continue
        if name:
            out[name] = origin
    return out


def main(project_dir: str) -> None:
    root = Path(project_dir).resolve()
    project = load_yaml(root / "dbt_project.yml")
    if not project:
        sys.exit(f"No dbt_project.yml in {root}")
    install_dir = root / project.get("packages-install-path", "dbt_packages")
    known = origins(root)

    found = []
    candidates = [(root, "root")]
    if install_dir.is_dir():
        candidates += [(d, None) for d in sorted(install_dir.iterdir()) if d.is_dir()]

    for pkg_dir, fixed_origin in candidates:
        meta = load_yaml(pkg_dir / "dbt_project.yml")
        name = meta.get("name")
        if not name or not has_contract(pkg_dir, meta):
            continue
        found.append(
            {
                "name": name,
                "version": str(meta.get("version", "")),
                "origin": fixed_origin or known.get(name, "unknown"),
                "reads_var": references_var(pkg_dir, meta, name),
            }
        )
    print(json.dumps(found, indent=2))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")

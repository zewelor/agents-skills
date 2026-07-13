#!/usr/bin/env python3
"""Validate Pyscript source syntax without importing or executing it."""

from __future__ import annotations

import argparse
import ast
import sys
from pathlib import Path


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Home Assistant configuration repository (default: current directory)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_arguments()
    pyscript_directory = args.repo_root.resolve() / "pyscript"
    sys.dont_write_bytecode = True
    files = sorted(pyscript_directory.rglob("*.py"))

    if not files:
        print(f"No Pyscript files found under {pyscript_directory}.")
        return 0

    failed = False
    for path in files:
        try:
            ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except (OSError, UnicodeError, SyntaxError) as error:
            failed = True
            print(f"{path}: {error}", file=sys.stderr)

    if failed:
        return 1

    print(f"Validated {len(files)} Pyscript file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

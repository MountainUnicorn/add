#!/usr/bin/env python3
"""Validate SKILL.md and rule frontmatter against JSON Schema.

Run locally or from CI (.github/workflows/schema-check.yml). Exits non-zero on any violation.

Requires: pyyaml (ships with most Python installs) and jsonschema.
Install once: pip install pyyaml jsonschema
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
    from jsonschema import Draft202012Validator, ValidationError  # type: ignore
except ImportError:
    print("ERROR: pip install pyyaml jsonschema", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT / "core"

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def extract_frontmatter(path: Path) -> dict | None:
    text = path.read_text()
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None
    return yaml.safe_load(m.group(1))


def validate_dir(target_dir: Path, schema_path: Path, pattern: str) -> list[str]:
    schema = json.loads(schema_path.read_text())
    validator = Draft202012Validator(schema)
    errors: list[str] = []
    for file in sorted(target_dir.rglob(pattern)):
        fm = extract_frontmatter(file)
        if fm is None:
            errors.append(f"{file.relative_to(ROOT)}: missing YAML frontmatter")
            continue
        for err in sorted(validator.iter_errors(fm), key=str):
            path = ".".join(str(p) for p in err.absolute_path) or "(root)"
            errors.append(f"{file.relative_to(ROOT)}: {path} — {err.message}")
    return errors


def main() -> int:
    all_errors: list[str] = []

    print("Validating SKILL.md files...")
    all_errors.extend(
        validate_dir(
            CORE / "skills",
            CORE / "schemas" / "skill-frontmatter.schema.json",
            "SKILL.md",
        )
    )

    print("Validating rule files...")
    all_errors.extend(
        validate_dir(
            CORE / "rules",
            CORE / "schemas" / "rule-frontmatter.schema.json",
            "*.md",
        )
    )

    if all_errors:
        print(f"\n✗ {len(all_errors)} violation(s):", file=sys.stderr)
        for e in all_errors:
            print(f"  {e}", file=sys.stderr)
        return 1

    print("\n✓ all frontmatter valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())

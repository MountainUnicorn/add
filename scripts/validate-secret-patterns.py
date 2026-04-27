#!/usr/bin/env python3
"""Validate that core/security/secret-patterns.json and core/knowledge/secret-patterns.md
agree on every named pattern.

Implements AC-007 of specs/secrets-scanner-executable.md (F-014). The markdown
catalog is the human-readable reference; the JSON is the executable source.
Drift between them is a release blocker — CI runs this validator alongside
the other guardrail suites.

Checks:
  1. Every `### NAME` heading in markdown § 1 has a matching JSON entry with
     the same `name`.
  2. Every JSON entry has a corresponding `### NAME` heading in markdown.
  3. Every JSON regex compiles via Python's `re` module.
  4. Every JSON entry has a stable `code` of the form SEC-NNN (3 digits).

Exits 0 on success, 1 on drift, 2 on invocation error.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "core" / "security" / "secret-patterns.json"
MD_PATH = ROOT / "core" / "knowledge" / "secret-patterns.md"

# Markdown headings under § 1 follow the form `### NAME` where NAME is the
# canonical pattern key. These are the *patterns* — anything else is prose.
MD_HEADING_RE = re.compile(r"^###\s+([A-Z][A-Z0-9_]+)\s*$", re.MULTILINE)
# Confine the search to § 1 ("## 1. Catalog Entries" through "## 2." or EOF).
MD_SECTION1_RE = re.compile(
    r"^##\s+1\.\s+Catalog Entries\s*$(.*?)(?=^##\s+\d+\.|\Z)",
    re.MULTILINE | re.DOTALL,
)


def collect_md_names() -> list[str]:
    text = MD_PATH.read_text()
    section1 = MD_SECTION1_RE.search(text)
    if not section1:
        raise SystemExit(
            f"ERROR: could not locate '## 1. Catalog Entries' section in {MD_PATH}"
        )
    return MD_HEADING_RE.findall(section1.group(1))


def collect_json_entries() -> list[dict]:
    if not JSON_PATH.exists():
        raise SystemExit(f"ERROR: {JSON_PATH} missing")
    data = json.loads(JSON_PATH.read_text())
    patterns = data.get("patterns")
    if not isinstance(patterns, list):
        raise SystemExit(f"ERROR: {JSON_PATH} has no 'patterns' array")
    return patterns


def main() -> int:
    md_names = collect_md_names()
    json_entries = collect_json_entries()
    json_names = [e.get("name", "") for e in json_entries]

    errors: list[str] = []

    # 1. Every markdown name must be in JSON.
    md_set = set(md_names)
    json_set = set(json_names)
    only_md = sorted(md_set - json_set)
    only_json = sorted(json_set - md_set)

    if only_md:
        errors.append(
            "patterns named in markdown but missing from JSON: " + ", ".join(only_md)
        )
    if only_json:
        errors.append(
            "patterns in JSON but not documented in markdown: " + ", ".join(only_json)
        )

    # 2. Every JSON regex must compile.
    code_re = re.compile(r"^SEC-\d{3}$")
    for entry in json_entries:
        name = entry.get("name", "<unnamed>")
        regex = entry.get("regex", "")
        code = entry.get("code", "")
        if not code_re.match(code):
            errors.append(f"{name}: code '{code}' is not of form SEC-NNN")
        try:
            re.compile(regex)
        except re.error as exc:
            errors.append(f"{name}: regex does not compile: {exc}")

    # 3. Codes must be unique.
    codes = [e.get("code", "") for e in json_entries]
    duplicates = sorted({c for c in codes if codes.count(c) > 1})
    if duplicates:
        errors.append("duplicate codes in JSON: " + ", ".join(duplicates))

    if errors:
        print("✗ secret-patterns drift detected", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        print(file=sys.stderr)
        print(
            "Fix: align core/security/secret-patterns.json and "
            "core/knowledge/secret-patterns.md.",
            file=sys.stderr,
        )
        return 1

    print(
        f"✓ secret-patterns drift check: {len(json_entries)} patterns aligned "
        f"between JSON and markdown."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

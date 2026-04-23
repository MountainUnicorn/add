#!/usr/bin/env python3
"""Validate cache-discipline layout in SKILL.md files.

The cache-discipline rule (see core/rules/cache-discipline.md) requires any
skill that dispatches sub-agents via the Task tool to wrap the emitted prompt
body in <!-- CACHE: STABLE --> ... <!-- CACHE: VOLATILE --> markers. A
byte-identical STABLE prefix across sub-agent dispatches lets Anthropic's
prompt cache reuse the prefix across calls (up to 90% input-cost discount,
85% latency reduction per the published case study).

This script lints SKILL.md files for layout violations and emits
machine-readable findings. It is warn-only by default — exit code 0 even
when findings are present — and flips to exit 1 on any finding with
--strict.

Usage:
    python3 scripts/validate-cache-discipline.py                # scan core/skills/*/SKILL.md
    python3 scripts/validate-cache-discipline.py path/to/FILE   # scan explicit paths
    python3 scripts/validate-cache-discipline.py --strict PATH  # exit 1 on any finding

Finding format:
    {file}:{line}: {severity}: {rule-id}: {message}

Rule IDs:
    CACHE-001  Task dispatch present but no CACHE markers found.
    CACHE-002  VOLATILE marker precedes STABLE (inverted layout).
    CACHE-003  Volatile placeholder (e.g., {user_message}) inside STABLE block.
    CACHE-004  Unrecognized marker keyword (e.g., <!-- CACHE: STABL -->).
    CACHE-100  (info) Markers present without dispatch — likely safe to remove.

Task dispatch detection (intentionally generous — warn-only in v0.9):
    The validator considers a file to dispatch a sub-agent if, outside the
    YAML frontmatter, it contains any of:
      - the literal string `Task tool`
      - a call-syntax match `Task(` or `Agent(`
      - a markdown reference like `/add:test-writer`, `/add:implementer`,
        `/add:reviewer`, `/add:verify`, or `/add:optimize` followed by the
        word `skill` / `invoke` / `dispatch` on the same line
    Frontmatter `allowed-tools: [..., Task, ...]` alone does NOT trigger the
    dispatch heuristic — it indicates capability, not emission.

Layout zones:
    Content BEFORE the first `<!-- CACHE: STABLE -->` marker is treated as
    documentation (not part of the emitted prompt) and is ignored.
    Content BETWEEN STABLE and VOLATILE markers is the STABLE zone.
    Content AFTER VOLATILE is the VOLATILE zone.

Volatile placeholders are identified by the regex `\\{[a-z_][a-z0-9_]*\\}`
inside the STABLE zone. A short allowlist of cache-safe placeholders
(e.g., `{project_name}`) can be extended here as the convention matures.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE_SKILLS = ROOT / "core" / "skills"

FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)

# Markers
MARKER_RE = re.compile(r"<!--\s*CACHE\s*:\s*([A-Za-z]+)\s*-->")
VALID_MARKERS = {"STABLE", "VOLATILE"}

# Dispatch signals — generous in v0.9 (warn-only)
DISPATCH_PATTERNS = [
    (re.compile(r"\bTask\s*\("), "Task("),
    (re.compile(r"\bAgent\s*\("), "Agent("),
    (re.compile(r"\bTask tool\b"), "Task tool"),
    (re.compile(
        r"/add:(?:test-writer|implementer|reviewer|verify|optimize)\b"
        r".*\b(?:skill|invoke|dispatch|run|call)\b",
        re.IGNORECASE,
    ), "/add:<subagent> skill/invoke/dispatch"),
]

# Volatile placeholders — matched inside STABLE zone only.
# Conservative allowlist of substitutions that resolve to session-stable
# literals at compile time may grow over time.
PLACEHOLDER_RE = re.compile(r"\{([a-z_][a-z0-9_]*)\}")
STABLE_SAFE_PLACEHOLDERS = {
    # Names resolved at session start and fixed for the session.
    "project_name",
    "project",
    "stack",
    "maturity",
    "version",
}


def strip_frontmatter(text: str) -> tuple[str, int]:
    """Return (body_without_frontmatter, line_offset).

    line_offset is the 1-based line number in the original file where the
    body starts — so finding lines can be reported in original coordinates.
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return text, 1
    # Count newlines consumed by the frontmatter block (incl. closing ---\n).
    consumed = text[: m.end()]
    offset = consumed.count("\n") + 1
    return text[m.end():], offset


def display_path(path: Path) -> str:
    """Emit a path relative to the repo root when possible."""
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def detect_dispatch(body: str, offset: int) -> tuple[bool, int | None, str | None]:
    """Return (dispatches, line_number_in_file, matched_pattern)."""
    for idx, line in enumerate(body.splitlines(), start=offset):
        for pattern, label in DISPATCH_PATTERNS:
            if pattern.search(line):
                return True, idx, label
    return False, None, None


def find_markers(body: str, offset: int) -> list[tuple[int, str]]:
    """List (line_in_file, marker_keyword) tuples. Includes malformed keywords."""
    out: list[tuple[int, str]] = []
    for idx, line in enumerate(body.splitlines(), start=offset):
        # A single line could contain multiple markers (unusual but valid)
        for m in MARKER_RE.finditer(line):
            out.append((idx, m.group(1).upper()))
    return out


def scan_file(path: Path) -> list[str]:
    """Return a list of finding lines for this file. Never raises on content."""
    findings: list[str] = []
    disp = display_path(path)

    try:
        text = path.read_text()
    except OSError as exc:
        print(f"ERROR: cannot read {disp}: {exc}", file=sys.stderr)
        raise

    body, offset = strip_frontmatter(text)

    markers = find_markers(body, offset)
    dispatches, dispatch_line, _match = detect_dispatch(body, offset)

    # CACHE-004: unrecognized marker keyword
    for line_no, kw in markers:
        if kw not in VALID_MARKERS:
            findings.append(
                f"{disp}:{line_no}: warn: CACHE-004: unrecognized marker keyword '{kw}'"
            )

    # Valid markers only (ignore the malformed ones for layout analysis)
    valid = [(ln, kw) for ln, kw in markers if kw in VALID_MARKERS]

    if not valid:
        if dispatches:
            findings.append(
                f"{disp}:{dispatch_line}: warn: CACHE-001: "
                f"Task dispatch present but no CACHE markers found"
            )
        # else: no markers, no dispatch → silent skip
        return findings

    # CACHE-002: first STABLE must come before first VOLATILE
    first_stable = next((ln for ln, kw in valid if kw == "STABLE"), None)
    first_volatile = next((ln for ln, kw in valid if kw == "VOLATILE"), None)

    if first_volatile is not None and (
        first_stable is None or first_volatile < first_stable
    ):
        findings.append(
            f"{disp}:{first_volatile}: warn: CACHE-002: "
            f"VOLATILE marker precedes STABLE — inverted layout"
        )
        # Continue — still check for volatile-in-stable below if a STABLE
        # block exists elsewhere.

    # CACHE-100: markers without dispatch (info)
    if not dispatches:
        first_marker_line = valid[0][0]
        findings.append(
            f"{disp}:{first_marker_line}: info: CACHE-100: "
            f"markers present without dispatch — likely safe to remove"
        )

    # CACHE-003: scan STABLE zone(s) for volatile placeholders.
    #
    # A STABLE zone starts at a STABLE marker and ends at the next VOLATILE
    # marker (or EOF). We walk markers in order and track which zone we are
    # in as we iterate body lines.
    stable_zones: list[tuple[int, int]] = []  # (start_line, end_line) inclusive
    in_stable = False
    zone_start = 0
    # Walk markers in file order
    for ln, kw in valid:
        if kw == "STABLE":
            if not in_stable:
                in_stable = True
                zone_start = ln
        else:  # VOLATILE
            if in_stable:
                stable_zones.append((zone_start, ln - 1))
                in_stable = False
    if in_stable:
        stable_zones.append((zone_start, offset + len(body.splitlines()) - 1))

    if stable_zones:
        for idx, line in enumerate(body.splitlines(), start=offset):
            in_zone = any(start <= idx <= end for start, end in stable_zones)
            if not in_zone:
                continue
            for m in PLACEHOLDER_RE.finditer(line):
                name = m.group(1)
                if name in STABLE_SAFE_PLACEHOLDERS:
                    continue
                findings.append(
                    f"{disp}:{idx}: warn: CACHE-003: "
                    f"volatile placeholder '{{{name}}}' inside STABLE block"
                )

    return findings


def iter_targets(args: list[str]) -> list[Path]:
    """Resolve CLI args into a list of SKILL.md files (plus any explicit file)."""
    targets: list[Path] = []
    if not args:
        # Default: every SKILL.md in core/skills/
        for skill_md in sorted(CORE_SKILLS.rglob("SKILL.md")):
            targets.append(skill_md)
        return targets

    for raw in args:
        p = Path(raw)
        if p.is_dir():
            for skill_md in sorted(p.rglob("SKILL.md")):
                targets.append(skill_md)
            # Also take any top-level *.md for non-skill directories (fixtures)
            if not any(t for t in targets if t.parent == p):
                for md in sorted(p.glob("*.md")):
                    targets.append(md)
        elif p.is_file():
            targets.append(p)
        else:
            print(f"ERROR: not found: {raw}", file=sys.stderr)
            raise SystemExit(2)
    return targets


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate cache-discipline layout in SKILL.md files.",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help=(
            "Files or directories to scan. Default: core/skills/*/SKILL.md. "
            "Directories are walked recursively for SKILL.md; fixture dirs "
            "also include any top-level *.md."
        ),
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit non-zero on any finding (v1.0 enforcement mode).",
    )
    args = parser.parse_args()

    try:
        targets = iter_targets(args.paths)
    except SystemExit as exc:
        return int(exc.code or 2)

    all_findings: list[str] = []
    for path in targets:
        try:
            all_findings.extend(scan_file(path))
        except OSError:
            # Parse/read error → real failure regardless of --strict
            return 2

    for line in all_findings:
        print(line)

    if args.strict and all_findings:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

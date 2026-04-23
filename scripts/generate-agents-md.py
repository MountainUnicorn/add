#!/usr/bin/env python3
"""Generate a portable AGENTS.md from an ADD-managed project's state.

Reads `.add/config.json`, `docs/prd.md`, `.add/handoff.md`, and `specs/*.md`
to produce a tool-portable `AGENTS.md` at the project root. Content is
wrapped in an ADD-managed marker block so user-authored sections survive
regeneration.

Usage:
    python3 scripts/generate-agents-md.py                 # --write (default)
    python3 scripts/generate-agents-md.py --check         # drift detection; non-zero on drift
    python3 scripts/generate-agents-md.py --merge         # prepend ADD block to existing file (non-interactive)
    python3 scripts/generate-agents-md.py --import        # absorb existing content as user-authored section
    python3 scripts/generate-agents-md.py --dry-run       # preview without writing

Exit codes:
    0   success (or no drift in --check)
    1   drift detected in --check mode
    2   existing AGENTS.md lacks marker block and --write was requested

Options:
    --project-root DIR   Operate against this directory (default: cwd)
    --generated ISO      Override the generated= timestamp (for reproducible fixtures)
    --skill-version VER  Override the version= field in the marker (default: read from core/VERSION)
"""

from __future__ import annotations

import argparse
import datetime as dt
import difflib
import json
import os
import re
import sys
from pathlib import Path

MARKER_START_RE = re.compile(
    r"<!--\s*ADD:MANAGED:START(?:\s+[^>]*)?\s*-->", re.MULTILINE
)
MARKER_END_RE = re.compile(r"<!--\s*ADD:MANAGED:END\s*-->", re.MULTILINE)
USER_START = "<!-- USER:AUTHORED:START -->"
USER_END = "<!-- USER:AUTHORED:END -->"

FRONTMATTER_RE = re.compile(
    r"\A(?:(---\n.*?\n---\n)|(\+\+\+\n.*?\n\+\+\+\n))", re.DOTALL
)


# ---------------------------------------------------------------------------
# Summaries for rule-driven sections. These are intentionally embedded so the
# generator produces deterministic output regardless of which rules are
# currently bundled with the plugin.
# ---------------------------------------------------------------------------

ENGAGEMENT_SUMMARY = (
    "The human is the architect and decision maker; the agent is the builder. "
    "Gather requirements via one-question-at-a-time interviews. Never batch "
    "questions. When stepping away, declare autonomy ceilings explicitly — "
    "the agent may climb local → dev → staging but never merges to main or "
    "ships to production without human approval."
)

SPEC_FIRST_SUMMARY = (
    "Every feature flows through the document hierarchy: PRD → Feature Spec → "
    "Implementation Plan → User Test Cases → Automated Tests → Implementation. "
    "No link may be skipped. Specs live in `specs/`, plans in `docs/plans/`. "
    "Code changes without a corresponding spec are rejected on review."
)

TDD_SUMMARY = (
    "Strict RED → GREEN → REFACTOR → VERIFY cycle. Tests are authored before "
    "implementation; failing tests prove the test is exercising new behavior. "
    "Quality gates run at VERIFY: full test suite, linter, type checker, "
    "spec-compliance check. Any gate failure blocks promotion."
)

POC_CRITICAL_RULES = [
    "Specifications precede code — even a one-paragraph spec beats none.",
    "Tests precede implementation; a failing test is proof you understood the requirement.",
    "The human decides; the agent executes and reports.",
    "Commit early, commit often, with conventional-commit messages.",
    "Surface surprises immediately — don't silently work around blockers.",
]


def read_version(project_root: Path) -> str:
    core_version = project_root / "core" / "VERSION"
    if core_version.exists():
        return core_version.read_text().strip()
    return "0.0.0"


def read_json(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return None


def read_text(path: Path) -> str | None:
    if not path.exists():
        return None
    return path.read_text()


def project_identity(config: dict, prd_text: str | None) -> tuple[str, str]:
    """Return (name, description) for the project identity header."""
    proj = (config or {}).get("project", {})
    name = proj.get("name") or "Unnamed Project"
    description = proj.get("description") or ""
    # Prefer a richer description from PRD intro if available. Walk paragraph
    # by paragraph; the first "prose-looking" paragraph wins. Skip metadata
    # blocks (all bold-key/value lines) and horizontal rules.
    if prd_text:
        paragraphs = _prd_paragraphs(prd_text)
        for para in paragraphs:
            if _looks_like_prose(para):
                description = para
                break
    return name, description


def _prd_paragraphs(text: str) -> list[str]:
    """Return paragraphs after the first H1 (or from top if no H1)."""
    lines = text.splitlines()
    start = 0
    for i, line in enumerate(lines):
        if line.startswith("# "):
            start = i + 1
            break
    paragraphs: list[list[str]] = []
    current: list[str] = []
    for line in lines[start:]:
        stripped = line.strip()
        if not stripped:
            if current:
                paragraphs.append(current)
                current = []
            continue
        if stripped.startswith("## ") or stripped == "---":
            if current:
                paragraphs.append(current)
                current = []
            continue
        current.append(stripped)
    if current:
        paragraphs.append(current)
    return [" ".join(p) for p in paragraphs]


def _looks_like_prose(paragraph: str) -> bool:
    """A paragraph is 'prose' if it isn't a metadata block or a list-lead."""
    if not paragraph:
        return False
    # Metadata blocks look like "**Key**: value **Key**: value ..."
    # If every visible token starts with ** and contains a colon, it's metadata.
    bold_pairs = len(re.findall(r"\*\*[^*]+\*\*:\s*[^*]+", paragraph))
    plain_words = len(re.findall(r"\b[A-Za-z]{4,}\b", paragraph))
    if bold_pairs >= 3 and plain_words < bold_pairs * 4:
        return False
    # Needs enough content
    if len(paragraph) < 40:
        return False
    # Skip list-lead paragraphs ("...leading to:" then a bullet list follows)
    if paragraph.rstrip().endswith(":"):
        return False
    # Skip paragraphs composed of markdown bullets
    stripped = paragraph.lstrip()
    if stripped.startswith(("- ", "* ", "+ ")):
        return False
    return True


def is_code_project(config: dict) -> bool:
    langs = (config or {}).get("architecture", {}).get("languages", []) or []
    names = {(l.get("name") or "").strip().lower() for l in langs}
    code_langs = names - {"markdown", "json", "yaml", "toml", ""}
    return bool(code_langs)


def current_maturity(config: dict) -> str:
    return ((config or {}).get("maturity", {}) or {}).get("level", "alpha") or "alpha"


def autonomy_ceiling(config: dict) -> list[str]:
    envs = (config or {}).get("environments", {}) or {}
    lines: list[str] = []
    for name in ("local", "dev", "staging", "production"):
        env = envs.get(name)
        if not isinstance(env, dict):
            continue
        auto = env.get("autoPromote")
        if auto is True:
            lines.append(f"- **{name}**: agents may auto-promote on green verification.")
        elif auto is False:
            lines.append(f"- **{name}**: human approval required.")
        else:
            if name == "production":
                lines.append(f"- **{name}**: human approval required (always).")
            else:
                lines.append(f"- **{name}**: auto-promotion not declared.")
    return lines


def find_active_spec(project_root: Path) -> str | None:
    handoff = project_root / ".add" / "handoff.md"
    if handoff.exists():
        text = handoff.read_text()
        m = re.search(r"specs/[A-Za-z0-9_\-]+\.md", text)
        if m:
            return m.group(0)
    specs_dir = project_root / "specs"
    if specs_dir.is_dir():
        candidates = [p for p in specs_dir.glob("*.md") if p.is_file()]
        if candidates:
            candidates.sort(key=lambda p: p.stat().st_mtime, reverse=True)
            return str(candidates[0].relative_to(project_root))
    return None


def pointers_block(project_root: Path) -> list[str]:
    lines: list[str] = []
    paths = [
        (".add/config.json", "project configuration"),
        ("docs/prd.md", "product requirements"),
        ("specs/", "feature specifications"),
        ("core/rules/", "behavioral rules (ADD-managed projects)"),
        (".add/learnings-active.md", "active learnings"),
    ]
    for rel, label in paths:
        if (project_root / rel).exists():
            lines.append(f"- [`{rel}`](./{rel}) — {label}")
    if not lines:
        lines.append("- (no ADD artifacts detected)")
    return lines


def render_marker_open(skill_version: str, maturity: str, generated: str) -> str:
    return (
        f"<!-- ADD:MANAGED:START version={skill_version} "
        f"maturity={maturity} generated={generated} -->"
    )


MARKER_CLOSE = "<!-- ADD:MANAGED:END -->"


def render_poc(name: str, description: str, project_root: Path) -> str:
    lines: list[str] = []
    lines.append(f"# {name}")
    lines.append("")
    if description:
        lines.append(description)
        lines.append("")
    lines.append("## Critical Rules")
    lines.append("")
    for rule in POC_CRITICAL_RULES:
        lines.append(f"- {rule}")
    lines.append("")
    lines.append("## Pointers")
    lines.append("")
    lines.extend(pointers_block(project_root))
    return "\n".join(lines).rstrip() + "\n"


def render_alpha(
    name: str, description: str, config: dict, project_root: Path
) -> str:
    lines: list[str] = []
    lines.append(f"# {name}")
    lines.append("")
    if description:
        lines.append(description)
        lines.append("")
    lines.append("## Engagement Protocol")
    lines.append("")
    lines.append(ENGAGEMENT_SUMMARY)
    lines.append("")
    lines.append("## Spec-First Invariants")
    lines.append("")
    lines.append(SPEC_FIRST_SUMMARY)
    lines.append("")
    lines.append("## Pointers")
    lines.append("")
    lines.extend(pointers_block(project_root))
    return "\n".join(lines).rstrip() + "\n"


def render_beta(
    name: str,
    description: str,
    config: dict,
    project_root: Path,
    include_team_conventions: bool = False,
) -> str:
    lines: list[str] = []
    lines.append(f"# {name}")
    lines.append("")
    if description:
        lines.append(description)
        lines.append("")

    lines.append("## Engagement Protocol")
    lines.append("")
    lines.append(ENGAGEMENT_SUMMARY)
    lines.append("")

    lines.append("## Spec-First Invariants")
    lines.append("")
    lines.append(SPEC_FIRST_SUMMARY)
    lines.append("")

    if is_code_project(config):
        lines.append("## TDD Discipline")
        lines.append("")
        lines.append(TDD_SUMMARY)
        lines.append("")

    lines.append("## Maturity & Autonomy Ceiling")
    lines.append("")
    mat = current_maturity(config)
    lines.append(f"Project maturity: **{mat}**.")
    lines.append("")
    ceiling = autonomy_ceiling(config)
    if ceiling:
        lines.extend(ceiling)
        lines.append("")
    lines.append(
        "Production deploys and merges to the default branch always require human approval."
    )
    lines.append("")

    active_spec = find_active_spec(project_root)
    lines.append("## Currently Active Spec")
    lines.append("")
    if active_spec:
        lines.append(f"- [`{active_spec}`](./{active_spec})")
    else:
        lines.append("- (no active spec identified — check `specs/`)")
    lines.append("")

    if include_team_conventions:
        lines.append("## Team Conventions")
        lines.append("")
        lines.append(
            "Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`). "
            "PRs require green CI and at least one reviewer. CHANGELOG entries land "
            "under `[Unreleased]` and promote on release."
        )
        lines.append("")

        lines.append("## Environment Promotion Ladder")
        lines.append("")
        lines.append(
            "Agents may climb `local → dev → staging` autonomously when verification "
            "passes. Production always requires human approval. See runbooks under `docs/`."
        )
        lines.append("")

    lines.append("## Pointers")
    lines.append("")
    lines.extend(pointers_block(project_root))
    return "\n".join(lines).rstrip() + "\n"


def render_managed_body(config: dict, prd_text: str | None, project_root: Path) -> str:
    name, description = project_identity(config, prd_text)
    mat = current_maturity(config)
    if mat == "poc":
        return render_poc(name, description, project_root)
    if mat == "alpha":
        return render_alpha(name, description, config, project_root)
    if mat == "ga":
        return render_beta(
            name, description, config, project_root, include_team_conventions=True
        )
    # beta (and any unknown) → beta render
    return render_beta(name, description, config, project_root)


def render_full_file(
    config: dict,
    prd_text: str | None,
    project_root: Path,
    skill_version: str,
    generated: str,
    existing_frontmatter: str = "",
    user_authored_tail: str = "",
) -> str:
    mat = current_maturity(config)
    marker_open = render_marker_open(skill_version, mat, generated)
    body = render_managed_body(config, prd_text, project_root)
    parts: list[str] = []
    if existing_frontmatter:
        parts.append(existing_frontmatter.rstrip("\n") + "\n\n")
    parts.append(marker_open + "\n\n")
    parts.append(body.rstrip("\n") + "\n\n")
    parts.append(MARKER_CLOSE + "\n")
    if user_authored_tail:
        tail = user_authored_tail.strip("\n")
        if tail:
            parts.append("\n" + tail + "\n")
    return "".join(parts)


def split_existing(content: str) -> tuple[str, str | None, str, str]:
    """Split an existing AGENTS.md into (frontmatter, managed_body_or_None, user_head, user_tail).

    Returns user_head (content above ADD marker, excluding frontmatter) and user_tail
    (content after the closing marker). If no marker is present, managed_body_or_None
    is None and user_head = everything-after-frontmatter, user_tail = "".
    """
    frontmatter = ""
    rest = content
    fm = FRONTMATTER_RE.match(content)
    if fm:
        frontmatter = fm.group(0)
        rest = content[fm.end():]

    start = MARKER_START_RE.search(rest)
    end = MARKER_END_RE.search(rest)
    if not start or not end or end.start() < start.end():
        return frontmatter, None, rest, ""

    head = rest[: start.start()].rstrip("\n")
    managed = rest[start.end(): end.start()].strip("\n")
    tail = rest[end.end():].lstrip("\n")
    return frontmatter, managed, head, tail


def load_state(project_root: Path) -> tuple[dict, str | None]:
    config = read_json(project_root / ".add" / "config.json") or {}
    prd = read_text(project_root / "docs" / "prd.md")
    return config, prd


def announce_stale(project_root: Path) -> str:
    marker = project_root / ".add" / "agents-md.stale"
    if not marker.exists():
        return ""
    try:
        data = json.loads(marker.read_text())
        changed = data.get("changed", [])
        ts = data.get("timestamp", "")
    except (json.JSONDecodeError, OSError):
        return ""
    lines = ["AGENTS.md marked stale."]
    if ts:
        lines.append(f"  detected: {ts}")
    if changed:
        lines.append("  sources changed:")
        for c in changed:
            lines.append(f"    - {c}")
    return "\n".join(lines) + "\n"


def clear_stale(project_root: Path) -> None:
    marker = project_root / ".add" / "agents-md.stale"
    try:
        marker.unlink()
    except FileNotFoundError:
        pass


def do_check(project_root: Path, skill_version: str, generated: str) -> int:
    target = project_root / "AGENTS.md"
    config, prd = load_state(project_root)
    if not target.exists():
        print("AGENTS.md missing — run /add:agents-md to generate.", file=sys.stderr)
        return 1
    existing = target.read_text()
    frontmatter, managed, head, tail = split_existing(existing)
    if managed is None:
        print(
            "AGENTS.md exists but has no ADD-managed marker block.\n"
            "Run /add:agents-md --merge or --import.",
            file=sys.stderr,
        )
        return 1
    would_be = render_full_file(
        config,
        prd,
        project_root,
        skill_version,
        generated,
        existing_frontmatter=frontmatter,
        user_authored_tail=tail,
    )
    # Also preserve user_head that came before the marker block
    if head.strip():
        # Put the user_head after frontmatter, before marker
        lines = would_be.splitlines(keepends=True)
        # Find line with marker open
        out: list[str] = []
        injected = False
        for ln in lines:
            if not injected and ln.lstrip().startswith("<!-- ADD:MANAGED:START"):
                out.append(head.strip("\n") + "\n\n")
                injected = True
            out.append(ln)
        would_be = "".join(out)
    if would_be == existing:
        print("AGENTS.md in sync.")
        return 0
    diff = "".join(
        difflib.unified_diff(
            existing.splitlines(keepends=True),
            would_be.splitlines(keepends=True),
            fromfile="AGENTS.md (current)",
            tofile="AGENTS.md (would-be)",
        )
    )
    sys.stdout.write("AGENTS.md drift detected.\n")
    sys.stdout.write(diff)
    return 1


def do_write(
    project_root: Path,
    skill_version: str,
    generated: str,
    dry_run: bool = False,
) -> int:
    target = project_root / "AGENTS.md"
    config, prd = load_state(project_root)

    existing_content = target.read_text() if target.exists() else ""
    frontmatter = ""
    head = ""
    tail = ""
    if existing_content:
        frontmatter, managed, head, tail = split_existing(existing_content)
        if managed is None:
            print(
                "AGENTS.md exists but has no ADD-managed marker block.\n"
                "Aborting. Run /add:agents-md --merge or --import to absorb existing content.",
                file=sys.stderr,
            )
            return 2

    stale_msg = announce_stale(project_root)
    if stale_msg:
        sys.stderr.write(stale_msg)

    output = render_full_file(
        config,
        prd,
        project_root,
        skill_version,
        generated,
        existing_frontmatter=frontmatter,
        user_authored_tail=tail,
    )
    if head.strip():
        lines = output.splitlines(keepends=True)
        out: list[str] = []
        injected = False
        for ln in lines:
            if not injected and ln.lstrip().startswith("<!-- ADD:MANAGED:START"):
                out.append(head.strip("\n") + "\n\n")
                injected = True
            out.append(ln)
        output = "".join(out)

    if dry_run:
        sys.stdout.write(output)
        return 0
    target.write_text(output)
    clear_stale(project_root)
    print(f"Wrote {target.relative_to(project_root)}")
    return 0


def do_merge(
    project_root: Path,
    skill_version: str,
    generated: str,
    dry_run: bool = False,
) -> int:
    """Prepend ADD-managed block to existing AGENTS.md; wrap existing as user-authored."""
    target = project_root / "AGENTS.md"
    config, prd = load_state(project_root)

    existing = target.read_text() if target.exists() else ""
    frontmatter = ""
    head = ""
    tail = ""
    managed = None
    if existing:
        frontmatter, managed, head, tail = split_existing(existing)
        if managed is not None:
            # Already has marker — just do a regular write.
            return do_write(project_root, skill_version, generated, dry_run=dry_run)

    user_body = (head + ("\n\n" + tail if tail else "")).strip("\n")
    wrapped_tail = ""
    if user_body:
        wrapped_tail = f"{USER_START}\n{user_body}\n{USER_END}\n"

    output = render_full_file(
        config,
        prd,
        project_root,
        skill_version,
        generated,
        existing_frontmatter=frontmatter,
        user_authored_tail=wrapped_tail,
    )
    if dry_run:
        sys.stdout.write(output)
        return 0
    target.write_text(output)
    clear_stale(project_root)
    print(f"Merged ADD block into {target.relative_to(project_root)}")
    return 0


def do_import(
    project_root: Path,
    skill_version: str,
    generated: str,
    dry_run: bool = False,
) -> int:
    """One-time absorption: same as merge but explicit about intent."""
    return do_merge(project_root, skill_version, generated, dry_run=dry_run)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Generate a portable AGENTS.md from ADD project state."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="Write AGENTS.md (default)")
    mode.add_argument("--check", action="store_true", help="Detect drift, exit non-zero on drift")
    mode.add_argument("--merge", action="store_true", help="Merge with existing hand-curated file")
    mode.add_argument("--import", dest="do_import", action="store_true", help="Absorb existing content as user-authored")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing")
    parser.add_argument(
        "--project-root",
        default=os.environ.get("ADD_PROJECT_ROOT", "."),
        help="Directory to operate against (default: cwd)",
    )
    parser.add_argument(
        "--generated",
        default=None,
        help="Override the generated= timestamp (ISO 8601) for reproducible output",
    )
    parser.add_argument(
        "--skill-version",
        default=None,
        help="Override the skill version= field in the marker",
    )
    args = parser.parse_args(argv)

    project_root = Path(args.project_root).resolve()
    skill_version = args.skill_version or read_version(project_root)
    generated = args.generated or dt.datetime.now(dt.timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%SZ"
    )

    if args.check:
        return do_check(project_root, skill_version, generated)
    if args.merge:
        return do_merge(project_root, skill_version, generated, dry_run=args.dry_run)
    if args.do_import:
        return do_import(project_root, skill_version, generated, dry_run=args.dry_run)
    return do_write(project_root, skill_version, generated, dry_run=args.dry_run)


if __name__ == "__main__":
    sys.exit(main())

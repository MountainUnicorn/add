#!/usr/bin/env python3
"""Compile ADD core + runtime adapters into runtime-specific distributions.

Usage:
    python3 scripts/compile.py               # Compile all runtimes
    python3 scripts/compile.py --runtime claude
    python3 scripts/compile.py --runtime codex
    python3 scripts/compile.py --check       # Exit non-zero if output would change

Produces:
    plugins/add/           (Claude runtime — marketplace install target)
    dist/codex/            (Codex runtime — install-codex.sh target)
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT / "core"
RUNTIMES = ROOT / "runtimes"


def read_version() -> str:
    return (CORE / "VERSION").read_text().strip()


def substitute_version(text: str, version: str) -> str:
    """Apply ADD version substitutions to file content."""
    text = re.sub(r"\[ADD v[0-9]+\.[0-9]+\.[0-9]+\]", f"[ADD v{version}]", text)
    text = re.sub(
        r"^# ADD (.+?) (Skill|Command) v[0-9]+\.[0-9]+\.[0-9]+",
        lambda m: f"# ADD {m.group(1)} {m.group(2)} v{version}",
        text,
        flags=re.MULTILINE,
    )
    text = text.replace("{{VERSION}}", version)
    return text


def copy_tree(src: Path, dst: Path, version: str, substitute: bool = True) -> int:
    """Copy src/ to dst/ with version substitution on text files. Returns file count."""
    count = 0
    if not src.exists():
        return 0
    for entry in src.rglob("*"):
        if entry.is_file():
            rel = entry.relative_to(src)
            out = dst / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            if substitute and entry.suffix in {".md", ".json", ".yaml", ".yml", ".txt"}:
                try:
                    text = entry.read_text()
                    text = substitute_version(text, version)
                    out.write_text(text)
                except UnicodeDecodeError:
                    shutil.copy2(entry, out)
            else:
                shutil.copy2(entry, out)
            count += 1
    return count


def clean_output(path: Path, keep: set[str] | None = None) -> None:
    """Remove contents of path, optionally keeping named top-level entries."""
    if not path.exists():
        return
    keep = keep or set()
    for entry in path.iterdir():
        if entry.name in keep:
            continue
        if entry.is_dir():
            shutil.rmtree(entry)
        else:
            entry.unlink()


# ---------------------------------------------------------------------------
# Claude runtime
# ---------------------------------------------------------------------------


def compile_claude(version: str) -> dict:
    output = ROOT / "plugins" / "add"
    output.mkdir(parents=True, exist_ok=True)
    clean_output(output)

    counts = {"core": 0, "adapter": 0}

    # Core content: rules, skills, templates, knowledge, schemas, security
    for src_name in ("rules", "skills", "templates", "knowledge", "schemas", "security"):
        counts["core"] += copy_tree(CORE / src_name, output / src_name, version)

    # Adapter content: .claude-plugin, hooks, CLAUDE.md, README.md, LICENSE
    adapter_src = RUNTIMES / "claude"
    for name in (".claude-plugin", "hooks"):
        counts["adapter"] += copy_tree(adapter_src / name, output / name, version)
    for file in ("CLAUDE.md", "README.md", "LICENSE"):
        src = adapter_src / file
        if src.exists():
            out = output / file
            if src.suffix in {".md"} or src.name == "LICENSE":
                out.write_text(substitute_version(src.read_text(), version))
            else:
                shutil.copy2(src, out)
            counts["adapter"] += 1

    # Ensure plugin.json carries the compiled version
    plugin_json = output / ".claude-plugin" / "plugin.json"
    if plugin_json.exists():
        data = json.loads(plugin_json.read_text())
        data["version"] = version
        plugin_json.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")

    return counts


# ---------------------------------------------------------------------------
# Codex runtime
# ---------------------------------------------------------------------------


CODEX_TOOL_SUBSTITUTIONS = {
    # Claude tool names → Codex equivalents or plain-text fallbacks
    "AskUserQuestion": "ask the user (use a clear, single-question prompt)",
    "${CLAUDE_PLUGIN_ROOT}": "~/.codex/add",
}


def strip_skill_frontmatter_for_codex(text: str) -> str:
    """Remove the Claude-specific frontmatter block; Codex prompts don't use it."""
    if not text.startswith("---\n"):
        return text
    try:
        end = text.index("\n---\n", 4)
    except ValueError:
        return text
    return text[end + len("\n---\n") :].lstrip()


def codex_substitute(text: str) -> str:
    for old, new in CODEX_TOOL_SUBSTITUTIONS.items():
        text = text.replace(old, new)
    return text


def compile_codex(version: str) -> dict:
    output = ROOT / "dist" / "codex"
    output.mkdir(parents=True, exist_ok=True)
    clean_output(output)

    counts = {"prompts": 0, "rules": 0, "agents_md_sections": 0}

    # 1. Build AGENTS.md from autoload rules and the knowledge/global.md file
    agents_sections = []
    agents_sections.append(f"# ADD — Agent Driven Development (Codex adapter v{version})\n")
    agents_sections.append(
        "This file is auto-generated from `core/` by `scripts/compile.py`.\n"
        "ADD is a methodology for agent-driven development — spec-driven, test-first,\n"
        "learning-accumulating, maturity-aware. The rules below are enforced by\n"
        "reading them at the start of every session.\n"
    )

    global_knowledge = (CORE / "knowledge" / "global.md").read_text()
    agents_sections.append("## Global Knowledge\n")
    agents_sections.append(codex_substitute(global_knowledge))
    counts["agents_md_sections"] += 1

    # Additional Tier-1 knowledge files (e.g. threat-model.md) — include each
    # as its own section so the Codex agent sees them on load.
    for kn_file in sorted((CORE / "knowledge").glob("*.md")):
        if kn_file.name == "global.md":
            continue
        text = codex_substitute(kn_file.read_text())
        agents_sections.append(f"\n---\n\n## Knowledge: {kn_file.stem}\n\n{text}")
        counts["agents_md_sections"] += 1

    rules_dir = CORE / "rules"
    for rule_file in sorted(rules_dir.glob("*.md")):
        text = rule_file.read_text()
        # Strip the autoload/maturity frontmatter
        if text.startswith("---\n"):
            try:
                end = text.index("\n---\n", 4)
                text = text[end + len("\n---\n") :].lstrip()
            except ValueError:
                pass
        text = codex_substitute(text)
        agents_sections.append(f"\n---\n\n## Rule: {rule_file.stem}\n\n{text}")
        counts["rules"] += 1
        counts["agents_md_sections"] += 1

    (output / "AGENTS.md").write_text("\n".join(agents_sections))

    # 2. Build flattened prompts: one file per skill at prompts/add-{name}.md
    prompts_dir = output / "prompts"
    prompts_dir.mkdir(parents=True, exist_ok=True)
    for skill_dir in sorted((CORE / "skills").iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue
        body = strip_skill_frontmatter_for_codex(skill_md.read_text())
        body = codex_substitute(body)
        body = substitute_version(body, version)
        (prompts_dir / f"add-{skill_dir.name}.md").write_text(body)
        counts["prompts"] += 1

    # 3. Ship templates verbatim so prompts can reference them
    templates_out = output / "templates"
    templates_out.mkdir(parents=True, exist_ok=True)
    copy_tree(CORE / "templates", templates_out, version)

    # 4. Emit a minimal config descriptor
    (output / "VERSION").write_text(version + "\n")
    (output / "README.md").write_text(
        f"""# ADD for Codex CLI — v{version}

This directory is the Codex adapter for ADD. Install with:

```bash
./scripts/install-codex.sh
```

That script copies `prompts/add-*.md` into `~/.codex/prompts/` and places
`AGENTS.md` at the root of your project (or merges if one exists).

**Differences from the Claude adapter:**
- No `PostToolUse` hooks (Codex has no hooks API — lint must be run manually).
- `AskUserQuestion` tool calls are rendered as plain-text prompts; answers are
  free-form rather than structured.
- Autoload rules are concatenated into a single `AGENTS.md` rather than loaded
  individually — the whole file is read on session start.
- Slash command namespacing (`/add:spec`) is approximated by prompt filename
  (`add-spec.md`); invoke with Codex's custom-prompt mechanism.

See [Codex install docs](../../docs/codex-install.md) for details.
"""
    )
    return counts


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def run_check(version: str) -> int:
    """Re-compile and verify the working tree matches (for CI drift check)."""
    import subprocess

    # Save existing state
    before = subprocess.run(
        ["git", "status", "--porcelain", "plugins/add", "dist/codex"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    ).stdout

    compile_claude(version)
    compile_codex(version)

    after = subprocess.run(
        ["git", "status", "--porcelain", "plugins/add", "dist/codex"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    ).stdout

    if before != after:
        print("✗ DRIFT DETECTED — committed plugins/add or dist/codex does not match compile output")
        print("  Run: python3 scripts/compile.py && git add plugins/add dist/codex && commit")
        print(f"  Before:\n{before}")
        print(f"  After:\n{after}")
        return 1
    print("✓ Compile output matches committed artifacts")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--runtime",
        choices=["claude", "codex", "all"],
        default="all",
        help="Which runtime to compile (default: all)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="CI mode: exit non-zero if compile output would change",
    )
    args = parser.parse_args()

    version = read_version()

    if args.check:
        return run_check(version)

    print(f"ADD compile — v{version}")

    if args.runtime in ("claude", "all"):
        counts = compile_claude(version)
        print(f"  [claude] → plugins/add/  ({counts['core']} core + {counts['adapter']} adapter files)")
    if args.runtime in ("codex", "all"):
        counts = compile_codex(version)
        print(
            f"  [codex]  → dist/codex/    "
            f"({counts['prompts']} prompts, {counts['rules']} rules into AGENTS.md)"
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())

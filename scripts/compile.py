#!/usr/bin/env python3
"""Compile ADD core + runtime adapters into runtime-specific distributions.

Usage:
    python3 scripts/compile.py               # Compile all runtimes
    python3 scripts/compile.py --runtime claude
    python3 scripts/compile.py --runtime codex
    python3 scripts/compile.py --check       # Exit non-zero if output would change

Produces:
    plugins/add/           (Claude runtime — marketplace install target)
    dist/codex/            (Codex runtime — install-codex.sh target, native Skills layout)
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT / "core"
RUNTIMES = ROOT / "runtimes"

# AGENTS.md hard cap per spec AC-014. Catches accidental regressions to the
# pre-v0.9 full-concat behavior.
CODEX_AGENTS_MD_MAX_LINES = 500


FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def parse_frontmatter(text: str) -> dict:
    """Best-effort YAML frontmatter parse for compile-time rule filtering.

    Handles the small subset of YAML we use: scalar booleans, strings, and flow-style arrays.
    Avoids a pyyaml dependency so compile.py can run in minimal CI environments.
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict = {}
    for line in m.group(1).splitlines():
        line = line.rstrip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, raw = line.partition(":")
        key = key.strip()
        raw = raw.strip()
        if raw in ("true", "false"):
            out[key] = raw == "true"
        elif raw.startswith("[") and raw.endswith("]"):
            items = [i.strip().strip('"').strip("'") for i in raw[1:-1].split(",") if i.strip()]
            out[key] = items
        elif raw.startswith('"') and raw.endswith('"'):
            out[key] = raw[1:-1]
        elif raw.startswith("'") and raw.endswith("'"):
            out[key] = raw[1:-1]
        else:
            out[key] = raw
    return out


def autoload_rules_block(rules_dir: Path) -> str:
    """Build the `@rules/*.md` list for CLAUDE.md, excluding rules with autoload:false.

    Preserves a deterministic order driven by filename so the list is stable across compiles.
    """
    lines: list[str] = []
    for rule_file in sorted(rules_dir.glob("*.md")):
        fm = parse_frontmatter(rule_file.read_text())
        if fm.get("autoload") is False:
            continue
        lines.append(f"@rules/{rule_file.name}")
    return "\n".join(lines)


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
# Frontmatter helpers
# ---------------------------------------------------------------------------


def split_frontmatter(text: str) -> tuple[str, str]:
    """Return (frontmatter_block, body). Frontmatter block includes delimiters.

    If the text doesn't begin with a YAML frontmatter block, returns
    ("", text).
    """
    if not text.startswith("---\n"):
        return "", text
    try:
        end = text.index("\n---\n", 4)
    except ValueError:
        return "", text
    return text[: end + len("\n---\n")], text[end + len("\n---\n") :].lstrip()


def parse_frontmatter_fields(fm_block: str) -> dict:
    """Minimal YAML-ish parser for the subset of keys ADD skills use.

    Handles: key: value, key: "quoted value", key: [a, b, c].
    Returns a dict of parsed top-level keys. Nested maps are not needed here.
    """
    if not fm_block:
        return {}
    lines = fm_block.splitlines()
    # Drop opening and closing '---' delimiters.
    body_lines = [ln for ln in lines if ln.strip() != "---"]
    result: dict[str, object] = {}
    for ln in body_lines:
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        if ":" not in ln:
            continue
        key, _, val = ln.partition(":")
        key = key.strip()
        val = val.strip()
        # Unquote simple double-quoted strings
        if len(val) >= 2 and val[0] == '"' and val[-1] == '"':
            val = val[1:-1]
            result[key] = val
            continue
        # Booleans
        if val == "true":
            result[key] = True
            continue
        if val == "false":
            result[key] = False
            continue
        result[key] = val
    return result


# ---------------------------------------------------------------------------
# Claude runtime
# ---------------------------------------------------------------------------


def compile_claude(version: str) -> dict:
    output = ROOT / "plugins" / "add"
    output.mkdir(parents=True, exist_ok=True)
    clean_output(output)

    counts = {"core": 0, "adapter": 0}

    # Core content: rules, skills, templates, knowledge, schemas, lib, security, references.
    # `references/` ships alongside `rules/` but is NOT referenced from CLAUDE.md —
    # skills load these files on demand via Read/@include when they need them
    # (per the rule's `references:` frontmatter or skill SKILL.md `references:`).
    for src_name in ("rules", "skills", "templates", "knowledge", "schemas", "lib", "security", "references"):
        counts["core"] += copy_tree(CORE / src_name, output / src_name, version)

    # Preserve executable bit on core/lib/*.sh shell helpers (compile.py uses shutil.copy2
    # which preserves mode, but the text-substitution path above strips it). Re-apply.
    lib_out = output / "lib"
    if lib_out.exists():
        for sh in lib_out.rglob("*.sh"):
            sh.chmod(0o755)

    # Adapter content: .claude-plugin, hooks, CLAUDE.md, README.md, LICENSE
    adapter_src = RUNTIMES / "claude"
    for name in (".claude-plugin", "hooks"):
        counts["adapter"] += copy_tree(adapter_src / name, output / name, version)

    rules_block = autoload_rules_block(CORE / "rules")
    for file in ("CLAUDE.md", "README.md", "LICENSE"):
        src = adapter_src / file
        if src.exists():
            out = output / file
            if src.suffix in {".md"} or src.name == "LICENSE":
                text = substitute_version(src.read_text(), version)
                text = text.replace("{{AUTOLOAD_RULES}}", rules_block)
                out.write_text(text)
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
# Codex runtime — native Skills layout (v0.9+)
# ---------------------------------------------------------------------------


CODEX_TOOL_SUBSTITUTIONS = {
    # Claude tool names → Codex equivalents or plain-text fallbacks
    "AskUserQuestion": "ask the user (use a clear, single-question prompt)",
    # ORDERING MATTERS: longest prefix first. Hooks live at the Codex-conventional
    # $CODEX_HOME/hooks/ (not namespaced under add/) because Codex's CLI loads
    # hooks from that exact path. Other shared assets are namespaced under
    # $CODEX_HOME/add/ to avoid collisions with the host and with other plugins.
    "${CLAUDE_PLUGIN_ROOT}/hooks": "~/.codex/hooks",
    "${CLAUDE_PLUGIN_ROOT}": "~/.codex/add",
}


def codex_substitute(text: str) -> str:
    for old, new in CODEX_TOOL_SUBSTITUTIONS.items():
        text = text.replace(old, new)
    return text


def load_skill_policy() -> dict[str, dict]:
    """Parse runtimes/codex/skill-policy.yaml into {skill_name: policy_entry}.

    Raises if any skill under core/skills/ is missing a policy entry (AC-009).
    Uses a minimal line-based YAML parser — avoids adding a PyYAML dependency,
    keeping ADD at zero runtime deps.
    """
    policy_file = RUNTIMES / "codex" / "skill-policy.yaml"
    if not policy_file.exists():
        raise SystemExit(
            f"ERROR: {policy_file} is required. Every core skill needs a policy entry."
        )

    entries: dict[str, dict] = {}
    current: dict | None = None
    current_list_key: str | None = None

    for raw in policy_file.read_text().splitlines():
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped == "skills:":
            continue
        # New entry begins with "  - skill: <name>"
        m = re.match(r"^\s*-\s*skill:\s*(\S+)\s*$", line)
        if m:
            if current is not None and "skill" in current:
                entries[current["skill"]] = current
            current = {"skill": m.group(1), "tools": []}
            current_list_key = None
            continue
        # Scalar key inside current entry: "    key: value"
        m = re.match(r"^\s+([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$", line)
        if m and current is not None:
            key = m.group(1)
            val = m.group(2).strip()
            current_list_key = None
            if val == "":
                # Start of a block — we only support inline lists below, so skip.
                continue
            # Inline list: [a, b, c]
            if val.startswith("[") and val.endswith("]"):
                inside = val[1:-1].strip()
                items = [x.strip() for x in inside.split(",") if x.strip()]
                current[key] = items
                continue
            # Booleans
            if val == "true":
                current[key] = True
            elif val == "false":
                current[key] = False
            else:
                # Strip quotes if present
                if len(val) >= 2 and val[0] == '"' and val[-1] == '"':
                    val = val[1:-1]
                current[key] = val
            continue

    if current is not None and "skill" in current:
        entries[current["skill"]] = current

    # Validate coverage
    skill_dirs = sorted(
        d.name for d in (CORE / "skills").iterdir() if d.is_dir()
    )
    missing = [s for s in skill_dirs if s not in entries]
    if missing:
        raise SystemExit(
            "ERROR: runtimes/codex/skill-policy.yaml is missing entries for: "
            + ", ".join(missing)
            + "\n       Every skill in core/skills/ needs a policy entry (AC-009)."
        )

    # Validate required fields
    for name, entry in entries.items():
        if "allow_implicit_invocation" not in entry:
            raise SystemExit(
                f"ERROR: skill-policy.yaml entry for '{name}' missing 'allow_implicit_invocation'."
            )
        if not entry.get("tools"):
            raise SystemExit(
                f"ERROR: skill-policy.yaml entry for '{name}' missing non-empty 'tools' list."
            )

    return entries


def load_askuser_shim() -> str:
    path = RUNTIMES / "codex" / "templates" / "askuser-shim.md"
    if not path.exists():
        raise SystemExit(f"ERROR: AskUserQuestion shim template missing at {path}")
    return path.read_text()


def emit_codex_native_skills(
    output: Path, version: str, policy: dict[str, dict]
) -> int:
    """Write each core skill to dist/codex/.agents/skills/add-<name>/.

    Emits SKILL.md (with preserved + namespaced frontmatter) and
    agents/openai.yaml (invocation policy). Applies the AskUserQuestion shim
    where policy.requires_askuser_shim is true.
    """
    shim = load_askuser_shim()
    skills_root = output / ".agents" / "skills"
    skills_root.mkdir(parents=True, exist_ok=True)

    count = 0
    for skill_dir in sorted((CORE / "skills").iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue

        entry = policy[skill_dir.name]
        namespaced = f"add-{skill_dir.name}"
        dest = skills_root / namespaced
        dest.mkdir(parents=True, exist_ok=True)

        raw_text = skill_md.read_text()
        # Apply version substitutions to the whole file before we split, so
        # [ADD vX.Y.Z] in the description frontmatter stays current.
        raw_text = substitute_version(raw_text, version)
        fm_block, body = split_frontmatter(raw_text)
        fm_fields = parse_frontmatter_fields(fm_block)
        description = fm_fields.get("description", "")
        # Preserve Claude's description verbatim; add the namespaced name.
        new_fm_lines = ["---", f"name: {namespaced}"]
        if description:
            new_fm_lines.append(f'description: "{description}"')
        # Retain other interesting fields for anyone who wants them; spec
        # requires name + description, but keeping argument-hint is harmless.
        for key in ("argument-hint",):
            if key in fm_fields:
                new_fm_lines.append(f'{key}: "{fm_fields[key]}"')
        new_fm_lines.append("---")
        new_fm = "\n".join(new_fm_lines) + "\n\n"

        body = codex_substitute(body)
        # version already substituted on raw_text above

        if entry.get("requires_askuser_shim"):
            body = shim + "\n" + body

        (dest / "SKILL.md").write_text(new_fm + body)

        # agents/openai.yaml — per-skill invocation policy
        agents_yaml_dir = dest / "agents"
        agents_yaml_dir.mkdir(parents=True, exist_ok=True)
        tools_list = ", ".join(entry["tools"])
        allow = "true" if entry["allow_implicit_invocation"] else "false"
        (agents_yaml_dir / "openai.yaml").write_text(
            f"# ADD skill policy — {namespaced}\n"
            f"# Generated by scripts/compile.py from runtimes/codex/skill-policy.yaml.\n"
            f"# See specs/codex-native-skills.md AC-006..AC-009.\n"
            f"\n"
            f"name: {namespaced}\n"
            f"allow_implicit_invocation: {allow}\n"
            f"tools: [{tools_list}]\n"
        )

        count += 1

    return count


def emit_codex_manifest_agents_md(
    output: Path, version: str, policy: dict[str, dict]
) -> int:
    """Generate the slim AGENTS.md manifest.

    Contains: project identity, invariant rules (autoload: always), and a
    generated skills table. Hard-fails if >CODEX_AGENTS_MD_MAX_LINES lines.
    """
    lines: list[str] = []
    lines.append(f"# ADD — Agent Driven Development (Codex runtime v{version})")
    lines.append("")
    lines.append(
        "Auto-generated by `scripts/compile.py` from `core/` + "
        "`runtimes/codex/`. Do not edit — change `core/` and recompile."
    )
    lines.append("")
    lines.append("ADD is a spec-driven, test-first, learning-accumulating, ")
    lines.append("maturity-aware methodology for agent-led development. Skills ")
    lines.append("dispatch by description match (Codex-native Skills layout); ")
    lines.append("the rules below are invariants that apply to every session.")
    lines.append("")

    # Invariants — only rules with `autoload: true` (always-loaded).
    lines.append("## Invariants (always-loaded rules)")
    lines.append("")

    rule_entries: list[tuple[str, str]] = []  # (slug, summary)
    rules_dir = CORE / "rules"
    for rule_file in sorted(rules_dir.glob("*.md")):
        text = rule_file.read_text()
        fm_block, body = split_frontmatter(text)
        fm = parse_frontmatter_fields(fm_block)
        # Rules in ADD use `autoload: true` (boolean). Conditional rules omit
        # the key or set it false. Per spec AC-012, only autoloaded rules land
        # in the slim AGENTS.md manifest.
        autoload = fm.get("autoload", False)
        if autoload not in (True, "true", "True"):
            continue
        # Capture the first non-empty heading/line as a summary.
        summary = ""
        for ln in body.splitlines():
            s = ln.strip()
            if not s:
                continue
            summary = s.lstrip("# ").strip()
            break
        rule_entries.append((rule_file.stem, summary))

    for slug, summary in rule_entries:
        lines.append(f"- **{slug}** — {summary}")
    lines.append("")
    lines.append(
        f"Full rule bodies live at `.agents/skills/add-<skill>/SKILL.md` where "
        f"the skill references them, and in `core/rules/` in the source repo."
    )
    lines.append("")

    # Skills table — generated from each SKILL.md's frontmatter.
    lines.append("## Skills")
    lines.append("")
    lines.append("| Command | Skill file | Implicit dispatch | Description |")
    lines.append("|---------|------------|-------------------|-------------|")

    skills_root = output / ".agents" / "skills"
    for skill_dir in sorted(skills_root.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue
        fm_block, _ = split_frontmatter(skill_md.read_text())
        fm = parse_frontmatter_fields(fm_block)
        name = fm.get("name", skill_dir.name)
        desc = fm.get("description", "")
        # Strip the leading "[ADD vX.Y.Z] " prefix from descriptions for the index
        desc_stripped = re.sub(r"^\[ADD v[0-9.]+\]\s*", "", desc)
        bare = name.removeprefix("add-") if isinstance(name, str) else skill_dir.name.removeprefix("add-")
        policy_entry = policy.get(bare, {})
        implicit = "yes" if policy_entry.get("allow_implicit_invocation") else "no"
        rel = f".agents/skills/{skill_dir.name}/SKILL.md"
        lines.append(f"| `/{name}` | `{rel}` | {implicit} | {desc_stripped} |")
    lines.append("")

    lines.append("## Sub-agents")
    lines.append("")
    lines.append(
        "Registered in `.codex/agents/`. Active when `[features] collab = true` "
        "(set in emitted `.codex/config.toml`)."
    )
    lines.append("")
    lines.append("- `test-writer` — TDD RED phase (workspace-write, high reasoning)")
    lines.append("- `implementer` — TDD GREEN phase (workspace-write, high reasoning)")
    lines.append("- `reviewer` — spec-compliance review (read-only, high reasoning)")
    lines.append("- `explorer` — broad codebase discovery (read-only, medium reasoning)")
    lines.append("")

    lines.append("## Hooks")
    lines.append("")
    lines.append(
        "Registered in `.codex/hooks.json`. Active when `[features] codex_hooks = true`. "
        "See `.codex/hooks/README.md` for the Claude-trigger mapping."
    )
    lines.append("")
    lines.append("- `SessionStart` → `load-handoff.sh` (surface prior `.add/handoff.md`)")
    lines.append("- `Stop` → `write-handoff.sh` (persist session-stop marker)")
    lines.append("- `UserPromptSubmit` → `handoff-detect.sh` (detect handoff intent)")
    lines.append("")

    content = "\n".join(lines) + "\n"
    line_count = content.count("\n")
    if line_count > CODEX_AGENTS_MD_MAX_LINES:
        raise SystemExit(
            f"ERROR: dist/codex/AGENTS.md exceeds {CODEX_AGENTS_MD_MAX_LINES}-line cap "
            f"(was: {line_count} lines). Did the legacy concat regress? "
            f"See spec AC-014."
        )
    (output / "AGENTS.md").write_text(content)
    return line_count


def emit_codex_agents_hooks_config(output: Path, version: str) -> dict:
    """Copy sub-agent TOMLs, global config.toml, and hook scripts into .codex/.

    Writes hooks.json registration file. Enforces 0755 on hook scripts.
    """
    codex_dir = output / ".codex"
    codex_dir.mkdir(parents=True, exist_ok=True)

    counts = {"agents": 0, "hooks": 0}

    # Sub-agent TOMLs
    agents_src = RUNTIMES / "codex" / "agents"
    agents_dst = codex_dir / "agents"
    agents_dst.mkdir(parents=True, exist_ok=True)
    for toml_file in sorted(agents_src.glob("*.toml")):
        text = toml_file.read_text()
        text = substitute_version(text, version)
        (agents_dst / toml_file.name).write_text(text)
        counts["agents"] += 1

    # Global config.toml
    config_src = RUNTIMES / "codex" / "config.toml"
    if config_src.exists():
        (codex_dir / "config.toml").write_text(
            substitute_version(config_src.read_text(), version)
        )

    # Hook scripts — preserve executable bit, enforce 0755
    hooks_src = RUNTIMES / "codex" / "hooks"
    hooks_dst = codex_dir / "hooks"
    hooks_dst.mkdir(parents=True, exist_ok=True)
    for entry in sorted(hooks_src.iterdir()):
        if entry.is_file():
            dest = hooks_dst / entry.name
            if entry.suffix == ".sh":
                dest.write_text(entry.read_text())
                os.chmod(dest, 0o755)
                # AC-024: build fails if any hook script lacks executable bit.
                if not os.access(dest, os.X_OK):
                    raise SystemExit(
                        f"ERROR: hook script {dest} is not executable after chmod."
                    )
                counts["hooks"] += 1
            else:
                shutil.copy2(entry, dest)

    # Also ship cross-runtime shell utilities that skills invoke imperatively.
    # These are NOT Codex lifecycle hooks — they don't appear in hooks.json —
    # but they live in $CODEX_HOME/hooks/ so skill references written as
    # `${CLAUDE_PLUGIN_ROOT}/hooks/<util>.sh` resolve after install without
    # runtime-specific substitution per call-site. (F-002 follow-up: unify
    # these into core/lib/ in v0.9.x so the path stops straddling two roles.)
    for util in ("filter-learnings.sh",):
        src = RUNTIMES / "claude" / "hooks" / util
        if src.exists():
            dest = hooks_dst / util
            dest.write_text(src.read_text())
            os.chmod(dest, 0o755)
            counts["hooks"] += 1

    # hooks.json registration manifest (AC-021)
    hooks_manifest = {
        "SessionStart": [{"command": ".codex/hooks/load-handoff.sh"}],
        "Stop": [{"command": ".codex/hooks/write-handoff.sh"}],
        "UserPromptSubmit": [{"command": ".codex/hooks/handoff-detect.sh"}],
    }
    (codex_dir / "hooks.json").write_text(
        json.dumps(hooks_manifest, indent=2) + "\n"
    )

    return counts


def emit_codex_plugin_manifest(
    output: Path, version: str, min_codex_version: str
) -> None:
    """Emit dist/codex/plugin.toml — the Codex plugin marketplace manifest.

    Per spec AC-029..AC-032. Simple TOML, no external deps.
    """
    skills_root = output / ".agents" / "skills"
    skill_paths = sorted(
        f".agents/skills/{d.name}/SKILL.md"
        for d in skills_root.iterdir()
        if d.is_dir() and (d / "SKILL.md").exists()
    )
    agents_root = output / ".codex" / "agents"
    agent_paths = sorted(
        f".codex/agents/{f.name}"
        for f in agents_root.iterdir()
        if f.suffix == ".toml"
    )

    lines: list[str] = []
    lines.append("# ADD Codex plugin manifest")
    lines.append("# Generated by scripts/compile.py. Consumed by the Codex CLI")
    lines.append("# plugin marketplace during `codex plugin install`.")
    lines.append("")
    lines.append('name = "add"')
    lines.append(f'version = "{version}"')
    lines.append(
        'description = "Agent Driven Development (ADD) — spec-driven, test-first '
        'SDLC methodology for AI agent teams."'
    )
    lines.append(f'min_codex_version = "{min_codex_version}"')
    lines.append("")
    lines.append("skills = [")
    for p in skill_paths:
        lines.append(f'  "{p}",')
    lines.append("]")
    lines.append("")
    lines.append("agents = [")
    for p in agent_paths:
        lines.append(f'  "{p}",')
    lines.append("]")
    lines.append("")
    lines.append('hooks = ".codex/hooks.json"')
    lines.append("")

    (output / "plugin.toml").write_text("\n".join(lines))


def load_adapter_metadata() -> dict:
    """Read min_codex_version and codex_cli_version from adapter.yaml.

    Minimal parse — we only need two top-level scalar keys.
    """
    adapter = RUNTIMES / "codex" / "adapter.yaml"
    meta = {"min_codex_version": "0.122.0", "codex_cli_version": "0.122.0"}
    if not adapter.exists():
        return meta
    for raw in adapter.read_text().splitlines():
        line = raw.strip()
        for key in ("min_codex_version", "codex_cli_version"):
            if line.startswith(f"{key}:"):
                val = line.split(":", 1)[1].strip()
                if len(val) >= 2 and val[0] == '"' and val[-1] == '"':
                    val = val[1:-1]
                meta[key] = val
    return meta


def compile_codex(version: str) -> dict:
    output = ROOT / "dist" / "codex"
    output.mkdir(parents=True, exist_ok=True)
    clean_output(output)

    counts = {
        "skills": 0,
        "rules_in_manifest": 0,
        "agents_md_lines": 0,
        "sub_agents": 0,
        "hooks": 0,
    }

    policy = load_skill_policy()
    meta = load_adapter_metadata()

    # 1. Native Skills: dist/codex/.agents/skills/add-<name>/
    counts["skills"] = emit_codex_native_skills(output, version, policy)

    # 2. Slim AGENTS.md manifest
    counts["agents_md_lines"] = emit_codex_manifest_agents_md(output, version, policy)

    # 3. Sub-agent TOMLs + global config + hook scripts + hooks.json
    agent_hook_counts = emit_codex_agents_hooks_config(output, version)
    counts["sub_agents"] = agent_hook_counts["agents"]
    counts["hooks"] = agent_hook_counts["hooks"]

    # 4. Templates — shipped verbatim (used by skills that reference them)
    templates_out = output / "templates"
    templates_out.mkdir(parents=True, exist_ok=True)
    copy_tree(CORE / "templates", templates_out, version)

    # 5. Ship core/lib/ shell helpers (test-deletion guardrail etc.)
    lib_src = CORE / "lib"
    if lib_src.exists():
        lib_out = output / "lib"
        copy_tree(lib_src, lib_out, version)
        for sh in lib_out.rglob("*.sh"):
            sh.chmod(0o755)

    # 6. Ship core/knowledge/ verbatim so prompts can reference data files
    knowledge_out = output / "knowledge"
    knowledge_out.mkdir(parents=True, exist_ok=True)
    copy_tree(CORE / "knowledge", knowledge_out, version)

    # 6b. Ship core/rules/ as individual files so skill bodies that reference
    # a specific rule by path (e.g. `rules/maturity-lifecycle.md`) resolve at
    # runtime. Rules are ALSO inlined into AGENTS.md (slim manifest), but the
    # individual files must exist on disk for path references in skills.
    rules_out = output / "rules"
    rules_out.mkdir(parents=True, exist_ok=True)
    copy_tree(CORE / "rules", rules_out, version)

    # 6c. Ship core/security/ (injection pattern catalog, etc.)
    security_src = CORE / "security"
    if security_src.exists():
        security_out = output / "security"
        security_out.mkdir(parents=True, exist_ok=True)
        copy_tree(security_src, security_out, version)

    # 6d. Ship core/references/ verbatim. Prompts load these on demand via
    # filesystem reads — matches the Claude adapter's
    # `${CLAUDE_PLUGIN_ROOT}/references/` pattern. The path is rewritten to
    # `~/.codex/add/references/` via the codex_substitute "${CLAUDE_PLUGIN_ROOT}"
    # → "~/.codex/add" rule. (PR #6 — on-demand rule/knowledge loading.)
    references_src = CORE / "references"
    if references_src.exists():
        references_out = output / "references"
        references_out.mkdir(parents=True, exist_ok=True)
        for ref in sorted(references_src.glob("*.md")):
            ref_text = codex_substitute(ref.read_text())
            ref_text = substitute_version(ref_text, version)
            (references_out / ref.name).write_text(ref_text)

    # 7. Plugin manifest
    emit_codex_plugin_manifest(output, version, meta["min_codex_version"])

    # 8. Adapter-level metadata: VERSION + install README
    (output / "VERSION").write_text(version + "\n")
    (output / "README.md").write_text(
        f"""# ADD for Codex CLI — v{version}

This directory is the compiled Codex adapter for ADD, in the **native Skills**
layout (`.agents/skills/add-<name>/SKILL.md`). Install with:

```bash
./scripts/install-codex.sh
```

That script installs:

- `.agents/skills/` → `~/.codex/.agents/skills/` — native Codex Skills, each
  with preserved YAML frontmatter for description-matched dispatch.
- `.codex/agents/` → `~/.codex/agents/` — sub-agent TOML definitions
  (test-writer, implementer, reviewer, explorer).
- `.codex/hooks/` → `~/.codex/hooks/` — POSIX shell hook scripts
  (SessionStart, Stop, UserPromptSubmit).
- `.codex/hooks.json` → `~/.codex/hooks.json` — hook registration.
- `.codex/config.toml` → merged into `~/.codex/config.toml` — `[agents]` +
  `[features]` settings.
- `AGENTS.md` → placed at the root of your project (or merged).
- `plugin.toml` — Codex plugin marketplace manifest.

**Pinned versions:**

- `min_codex_version = "{meta['min_codex_version']}"` — the oldest Codex CLI that
  supports every feature ADD emits (native Skills, sub-agents, hooks, plugin
  marketplace).
- `codex_cli_version = "{meta['codex_cli_version']}"` — the version ADD's CI
  validates against.

**Differences from the Claude adapter:**

- `PostToolUse(Write/Edit)` triggers move to `UserPromptSubmit` + `Stop` —
  Codex's `PostToolUse` is Bash-only. See `.codex/hooks/README.md`.
- `AskUserQuestion` is Plan-mode-only in Codex. Interview skills include an
  auto-injected shim that halts and asks inline when the tool is unavailable
  instead of improvising answers.
- Autoload rules are consolidated into a slim `AGENTS.md` manifest (≤500
  lines); per-skill rule bodies live inline in each `SKILL.md`.

See the ADD repo's `runtimes/codex/README.md` and `specs/codex-native-skills.md`
for the full contract.
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
            f"({counts['skills']} skills, "
            f"{counts['sub_agents']} sub-agents, "
            f"{counts['hooks']} hooks, "
            f"AGENTS.md={counts['agents_md_lines']}L)"
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())

# ADD Core — Runtime-Agnostic Source of Truth

This directory contains ADD's methodology content independent of any agent runtime (Claude Code, Codex, future). Every artifact here is plain markdown, JSON, or YAML and carries no runtime-specific glue.

**Do not edit files under `plugins/add/` or `dist/` directly** — those are generated from `core/` + `runtimes/<name>/` by `scripts/compile.py`.

## Layout

```
core/
├── VERSION                    # Single source of truth for plugin version
├── skills/                    # Skill bodies (workflow content)
│   └── {name}/SKILL.md        # Contains Claude-extension frontmatter; compile strips for other runtimes
├── rules/                     # Auto-loaded behavioral rules
│   └── {name}.md              # autoload + maturity frontmatter are ADD conventions
├── templates/                 # Document scaffolding (PRD, spec, plan, retro, etc.)
├── knowledge/                 # Tier 1 curated best practices
│   └── global.md              # Universal ADD guidance
└── schemas/                   # JSON Schema files for SKILL/rule/config validation
```

## How Runtimes Consume Core

Each runtime adapter lives at `runtimes/<name>/`. The adapter declares:

1. **Tool name mapping** — `Read`/`Write`/`Bash` → runtime-native equivalents (Claude: identity; Codex: plain-text fallback)
2. **Path variable mapping** — `${CLAUDE_PLUGIN_ROOT}` → runtime-specific path resolution
3. **Frontmatter mapping** — which custom fields survive, which get stripped, which get rewritten
4. **Manifest template** — how to produce the runtime's plugin/config file (plugin.json, AGENTS.md, etc.)

The compile script walks `core/`, applies the adapter's substitutions, and writes to the runtime's output directory.

## Version Bump

Edit `core/VERSION` only. Running `scripts/compile.py` propagates to:

- `runtimes/claude/.claude-plugin/plugin.json` → `version`
- `plugins/add/.claude-plugin/plugin.json` → `version` (generated)
- `.claude-plugin/marketplace.json` → `plugins[].version` (if present)
- All SKILL.md `description` lines: `[ADD v{VERSION}]`
- All SKILL.md headings: `# ADD {Name} ... v{VERSION}`
- Dashboard reports and website footers
- `.add/config.json` of this repo (ADD dog-foods itself)

This replaces the pre-v0.7.0 8-location version-bump checklist.

## Rules for Editing Core

1. **No runtime-specific references** in `core/*` files. No `CLAUDE.md`, no Claude-only tool names in prose, no plugin.json schema specifics.
2. **Frontmatter in `core/skills/*/SKILL.md`** uses ADD conventions (`argument-hint`, `allowed-tools`, `[ADD vX]` prefix). The Claude adapter passes these through; the Codex adapter strips them.
3. **Cross-references** should use `{{path:...}}` placeholders when they must be resolved by the runtime. Otherwise write relative paths that work post-compile.
4. **Tests**: every change should produce a diff in `plugins/add/` after `scripts/compile.py` runs. CI verifies the generated output matches committed artifacts.

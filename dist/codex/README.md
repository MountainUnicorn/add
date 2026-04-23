# ADD for Codex CLI — v0.8.0

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

- `min_codex_version = "0.122.0"` — the oldest Codex CLI that
  supports every feature ADD emits (native Skills, sub-agents, hooks, plugin
  marketplace).
- `codex_cli_version = "0.122.0"` — the version ADD's CI
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

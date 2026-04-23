# ADD Codex hooks — Claude-trigger map

Codex CLI's hook surface is intentionally narrower than Claude Code's, and one
event (PreToolUse / PostToolUse) fires **only on Bash** — not on Write, Edit,
or MCP tool calls. ADD relies on Write/Edit post-hooks in Claude Code for
handoff capture and learnings filtering. This directory reattaches those
triggers to the nearest natural Codex boundary.

See spec `specs/codex-native-skills.md` § E.

## Mapping

| Claude Code trigger | Codex hook used | Script | Why |
|---------------------|-----------------|--------|-----|
| `PostToolUse` (Write/Edit) | `Stop` + `UserPromptSubmit` | `write-handoff.sh` / `handoff-detect.sh` | Codex PostToolUse is Bash-only; capture state at next natural boundary |
| `PostToolUse` (Bash) | `PostToolUse` (Bash) | n/a (future expansion) | 1:1 mapping available; ADD doesn't use this today |
| `SessionStart` | `SessionStart` | `load-handoff.sh` | 1:1 mapping |
| `Stop` | `Stop` | `write-handoff.sh` | 1:1 mapping |
| `UserPromptSubmit` | `UserPromptSubmit` | `handoff-detect.sh` | 1:1 mapping |

## Scripts

All scripts:

- Use `set -euo pipefail`
- No-op silently when `.add/` or the expected file is missing — safe in
  non-ADD-managed projects
- Are mode `0755` at emission time (enforced by `scripts/compile.py`; the
  build fails if any is non-executable)

### `load-handoff.sh` (SessionStart)

If `.add/handoff.md` exists, cats it to stdout with a `[ADD handoff]`
prefix. Codex surfaces stdout as session context.

### `write-handoff.sh` (Stop)

If `.add/handoff.md` exists, appends a session-stop timestamp marker so the
next SessionStart can surface "last touched at" context. If `.add/` exists
but `handoff.md` doesn't, appends a stop marker to
`.add/away-logs/codex-session-stops.md` instead of creating `handoff.md` out
of thin air.

### `handoff-detect.sh` (UserPromptSubmit)

Scans the incoming prompt for `handoff`, `back`, or `away` intent and nudges
the user toward the corresponding ADD skill. Safe to suppress — it writes a
one-line reminder, never blocks.

## Feature toggles

The emitted `.codex/config.toml` sets `[features] codex_hooks = true` so the
runtime is functional out of the box. A user who has globally overridden
`codex_hooks = false` will not see these hooks fire; handoff persistence
degrades to manual. Documented as a non-goal in the spec (§6).

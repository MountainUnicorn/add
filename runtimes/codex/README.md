# ADD — Codex CLI adapter

This directory is the **source** for ADD's Codex CLI runtime. `scripts/compile.py`
reads `adapter.yaml`, `skill-policy.yaml`, the hook scripts, sub-agent TOMLs,
and global `config.toml` here, then regenerates `dist/codex/` — the installable
Codex distribution.

Edit files **here**. Never edit `dist/codex/` directly; compile-drift CI will
reject it.

## Contents

| File | Purpose |
|------|---------|
| `adapter.yaml` | Declares emission targets, CLI version pins, and output shape |
| `skill-policy.yaml` | Per-skill `allow_implicit_invocation` + tool surface (AC-007, AC-009) |
| `templates/askuser-shim.md` | Shim preamble injected into interview skills (AC-026/027) |
| `hooks/*.sh` | SessionStart / Stop / UserPromptSubmit hook scripts |
| `hooks/README.md` | Claude-trigger-to-Codex-hook mapping |
| `agents/*.toml` | Sub-agent declarations (test-writer, implementer, reviewer, explorer) |
| `config.toml` | Global `[agents]` + `[features]` config |

## Native Skills layout (v0.9+)

The compiled `dist/codex/` ships in the Codex-native layout:

```
dist/codex/
├── AGENTS.md                                 # slim manifest, ≤500 lines
├── VERSION
├── README.md                                 # end-user install overview
├── plugin.toml                               # Codex plugin marketplace manifest
├── .agents/
│   └── skills/
│       └── add-<name>/
│           ├── SKILL.md                      # preserved frontmatter + body
│           └── agents/openai.yaml            # invocation policy
├── .codex/
│   ├── config.toml                           # [agents] + [features]
│   ├── hooks.json                            # hook registration
│   ├── hooks/*.sh                            # mode 0755
│   └── agents/*.toml                         # sub-agent definitions
└── templates/                                # shipped verbatim
```

The legacy `dist/codex/prompts/` directory is **no longer emitted** — users
who previously installed via the `prompts/`-based layout get a fresh install
from v0.9 onwards.

## Installation (native layout)

Users install via one of:

- **Plugin marketplace (recommended):** `codex plugin install https://github.com/MountainUnicorn/add`
- **Local clone:** `./scripts/install-codex.sh` from this repo
- **Manual:** rsync `dist/codex/.agents/`, `dist/codex/.codex/`, `dist/codex/AGENTS.md`
  into `~/.codex/` (or the project root for per-project install).

Skills then dispatch by description match (for skills with
`allow_implicit_invocation: true`) or explicitly as `/add-<name>` (all
skills). Sub-agents run under Codex's `collab = true` feature; hooks require
`codex_hooks = true`. Both are set in the emitted `config.toml`.

## Compile flow

```bash
python3 scripts/compile.py            # regenerates dist/codex/ + plugins/add/
python3 scripts/compile.py --check    # drift guard (CI uses this)
```

Compile-time guardrails:

- Every `core/skills/<name>/` must have a matching entry in `skill-policy.yaml`
  — missing entries fail the build (AC-009).
- `AGENTS.md` > 500 lines fails the build (AC-014).
- Any hook script without executable mode fails the build (AC-024).

## Spec

Full behavioral contract: [`specs/codex-native-skills.md`](../../specs/codex-native-skills.md).

## Differences from Claude adapter

- **No `PostToolUse` for Write/Edit/MCP** — Codex's `PostToolUse` fires only
  on Bash. ADD reattaches state-capture triggers to `UserPromptSubmit` and
  `Stop` (see `hooks/README.md`).
- **`ask_user_question` only in Plan mode** — the shim (`templates/askuser-shim.md`)
  is auto-injected into interview skills to handle Default mode gracefully by
  halting rather than improvising.
- **Skills use description-matched dispatch** — high-leak interview skills
  opt out via `allow_implicit_invocation: false` (`skill-policy.yaml`).

---
autoload: true
maturity: poc
---

# ADD Rule: Project Structure

Every ADD project follows a standard directory layout. Consistency across projects means agents know where things are without discovery.

## Standard Project Layout

`/add:init` creates this structure. Skills and rules assume it exists.

```
{project-root}/
│
├── .add/                           # ADD methodology state (COMMITTED TO GIT)
│   ├── config.json                 # Project configuration (stack, envs, quality, collab)
│   ├── learnings.md                # Project-specific agent knowledge base
│   ├── retros/                     # Retrospective archives
│   │   └── retro-{YYYY-MM-DD}.md  # Individual retro records
│   └── away-logs/                  # Away session archives
│       └── away-{YYYY-MM-DD}.md   # Individual away session logs
│
├── .claude/                        # Claude Code configuration (COMMITTED)
│   └── settings.json               # Permissions, model prefs, plugin config
│
├── docs/                           # Project documentation
│   ├── prd.md                      # Product Requirements Document (source of truth)
│   └── plans/                      # Implementation plans
│       └── {feature}-plan.md       # One plan per feature spec
│
├── specs/                          # Feature specifications
│   └── {feature}.md                # One spec per feature
│
├── tests/                          # Test artifacts and evidence
│   ├── screenshots/                # E2E visual verification
│   │   ├── {feature}/              # Organized by feature
│   │   │   └── step-{NN}-{desc}.png
│   │   └── errors/                 # Failure screenshots (auto-captured)
│   ├── e2e/                        # End-to-end test files
│   ├── unit/                       # Unit test files (if not colocated)
│   └── integration/                # Integration test files
│
├── CLAUDE.md                       # Project context for Claude
│
└── {source directories}            # Application code (stack-dependent)
```

## What Gets Committed

Everything in the project directory is committable EXCEPT:

```gitignore
# ADD to .gitignore during /add:init
.add/away-logs/          # Ephemeral, not worth tracking
tests/screenshots/errors/ # Failure screenshots are debugging artifacts
```

These MUST be committed (agents on other devices need them):

- `.add/config.json` — project configuration
- `.add/learnings.md` — agent knowledge (critical for device portability)
- `.add/retros/` — retrospective history
- `docs/prd.md` — product requirements
- `docs/plans/` — implementation plans
- `specs/` — feature specifications
- `tests/screenshots/{feature}/` — passing visual evidence
- `.claude/settings.json` — Claude Code permissions

## Plugin-Global Knowledge (Tier 1)

ADD ships with a `knowledge/` directory containing curated best practices:

```
${CLAUDE_PLUGIN_ROOT}/knowledge/
└── global.md          # Tier 1: Universal ADD best practices for all users
```

This directory is **read-only in consumer projects**. Only updated by ADD maintainers. Agents read `knowledge/global.md` as the first tier in the 3-tier knowledge cascade (see `learning.md` rule).

## Cross-Project Persistence

Knowledge that transcends any single project lives at the user level:

```
~/.claude/add/
├── profile.md                  # User preferences and tech defaults
├── library.md                  # Promoted learnings from all projects
└── projects/                   # Index of projects you've ADD-initialized
    └── {project-name}.json     # Config snapshot + key learnings summary
```

### Profile (`~/.claude/add/profile.md`)

Your developer DNA. Carries preferences across projects:
- Default tech stack (languages, frameworks, versions)
- Cloud and infrastructure preferences
- Process preferences (autonomy, quality, commits)
- Style preferences (naming, formatting, UX patterns)
- Cross-project lessons learned

Read by `/add:init` to pre-populate interview answers.
Updated during `/add:retro` when cross-project patterns are confirmed.

### Library (`~/.claude/add/library.md`)

Accumulated wisdom from all projects. Entries promoted from project-level
`.add/learnings.md` during retrospectives:
- Technical patterns that apply everywhere
- Architecture decision rationale that transfers
- Anti-patterns discovered in any project
- Performance insights across different stacks

Read by agents before starting work (alongside project-level learnings).

### Project Index (`~/.claude/add/projects/{name}.json`)

Lightweight snapshot created during `/add:init` and updated during `/add:retro`:

```json
{
  "name": "dossierfyi",
  "path": "/Users/abrooke/projects/dossierfyi",
  "initialized": "2026-01-15",
  "last_retro": "2026-02-07",
  "stack": ["python-3.11", "fastapi", "react-18", "seekdb"],
  "tier": 2,
  "key_learnings": [
    "pymysql is not thread-safe",
    "Keycloak needs KC_HOSTNAME_STRICT=false behind LB"
  ]
}
```

This lets `/add:init` on a new project say: "I see you worked on dossierfyi with FastAPI + React. Similar stack here?"

## Portability Between Devices

**Scenario:** You develop on your MacBook, then switch to a workstation.

**What ports via git (automatic):**
- `.add/config.json` — project knows its stack and settings
- `.add/learnings.md` — agent knowledge transfers with the repo
- `.add/retros/` — historical context
- `specs/`, `docs/plans/`, `docs/prd.md` — all specification artifacts

**What doesn't port (machine-local):**
- `~/.claude/add/profile.md` — your personal preferences
- `~/.claude/add/library.md` — cross-project knowledge

**Rebuilding machine-local state:**
Run `/add:init --import` on the new device. This reads `.add/config.json` and
`.add/learnings.md` from the committed project files and uses them to:
1. Recreate `~/.claude/add/profile.md` (asks for confirmation)
2. Recreate `~/.claude/add/projects/{name}.json`
3. Optionally import learnings into `~/.claude/add/library.md`

## Directory Creation Rules

- `/add:init` creates the full standard layout on first run
- Skills MUST NOT create directories ad-hoc — they use the established structure
- If a skill needs a directory that doesn't exist, it's a bug in `/add:init`
- The only exception: feature-specific subdirectories under `tests/screenshots/`
  are created by the test-writer when the first test for that feature is written

## Stack-Dependent Source Directories

The standard layout above covers ADD methodology directories. Application source
directories depend on the stack and are documented in CLAUDE.md during `/add:init`:

### Python Backend
```
backend/
├── app/
│   ├── routes/
│   ├── services/
│   ├── models/
│   └── config/
└── tests/           # Can use project-level tests/ or backend/tests/
```

### React Frontend
```
frontend/
├── src/
│   ├── components/
│   ├── hooks/
│   ├── pages/
│   └── api/
└── tests/           # Can use project-level tests/ or frontend/tests/
```

### Full-Stack (Python + React)
```
backend/             # Python backend
frontend/            # React frontend
tests/               # E2E and integration (project-level)
  ├── e2e/           # Playwright tests
  └── screenshots/   # Visual verification
```

### Simple SPA / Single-Language
```
src/                 # Application code
tests/               # All tests
```

The stack detection in `/add:init` determines which pattern to suggest.
The human can override during the interview.

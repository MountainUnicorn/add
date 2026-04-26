---
autoload: true
maturity: poc
---

# ADD Rule: Project Structure

Every ADD project follows a standard directory layout. `/add:init` creates this structure.

## Standard Layout

```
{project-root}/
├── .add/                    # ADD state (committed)
│   ├── config.json          # Project configuration
│   ├── learnings.json       # Project-specific knowledge (JSON primary)
│   ├── retros/              # Retrospective archives
│   └── away-logs/           # Away session logs (gitignored)
├── docs/
│   ├── prd.md               # Product Requirements Document
│   ├── plans/               # Implementation plans ({feature}-plan.md)
│   └── milestones/          # Milestone docs (M{N}-{name}.md)
├── specs/                   # Feature specifications ({feature}.md)
├── tests/                   # Test artifacts
│   ├── screenshots/         # E2E visual verification
│   ├── e2e/ | unit/ | integration/
├── CLAUDE.md                # Project context
└── {source directories}     # Stack-dependent (see below)
```

## Gitignore

Add during `/add:init`: `.add/away-logs/`, `tests/screenshots/errors/`

Must commit: `.add/config.json`, `.add/learnings.json`, `.add/retros/`, `docs/`, `specs/`, `tests/screenshots/{feature}/`, `.claude/settings.json`

## Cross-Project Persistence

```
~/.claude/add/
├── profile.md              # User preferences (read by /add:init)
├── library.json            # Tier 2: cross-project wisdom
└── projects/{name}.json    # Project index (stack, maturity, key learnings)
```

- **Profile:** Default tech stack, process prefs. Read by `/add:init`, updated by `/add:retro`.
- **Library:** Promoted learnings from all projects. Read by agents before work.
- **Project Index:** Snapshot for cross-project discovery. Updated by `/add:init` and `/add:retro`.
- **Portability:** Git-committed files port automatically. Machine-local state rebuilt via `/add:init --import`.

## Directory Rules

- `/add:init` creates the full layout. Skills must NOT create directories ad-hoc.
- Stack-dependent source directories (backend/, frontend/, src/) are determined during `/add:init` and documented in CLAUDE.md.

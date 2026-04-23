---
autoload: true
maturity: poc
---

# ADD Rule: Source Control Protocol

## Branching

Feature branches off `main` using kebab-case: `feature/{name}`, `fix/{desc}`, `refactor/{desc}`, `test/{desc}`.

## Commits

Conventional commits: `{type}: {description}` with optional spec/AC references.

Types: `feat`, `fix`, `test`, `refactor`, `docs`, `style`, `perf`, `chore`, `ops`

**TDD pattern:** 1-3 commits per cycle: `test:` (RED) → `feat:`/`fix:` (GREEN) → `refactor:` (REFACTOR)

**When:** After each TDD phase. NEVER with failing tests, lint errors, or mid-implementation.

## Pull Requests

PR includes: title (<70 chars), summary + spec reference + ACs covered, TDD checklist, quality gate checklist, screenshots (if UI).

**Human approval required for:** merges to main, production deploys, schema migrations, security changes, major dependency upgrades.

**Agents can:** commit to feature branches, create PRs, deploy to dev/staging, run quality gates, fix lint/type errors.

## Protected Branches

`main` is protected: no direct commits, CI must pass, at least one review, no force pushes.

## Git Hygiene

Rebase on main before PR. Delete branches after merge. Tag releases (`v1.2.3`). Never commit secrets.

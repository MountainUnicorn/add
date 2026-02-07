---
autoload: true
---

# ADD Rule: Source Control Protocol

Consistent git practices keep the project navigable and the history meaningful.

## Branching Strategy

Default: feature branches off `main`. Configured in `.add/config.json`.

```
main (production-ready, protected)
 ├── feature/{feature-name}   — new functionality
 ├── fix/{issue-description}  — bug fixes
 ├── refactor/{description}   — code improvement, no behavior change
 └── test/{description}       — test additions or improvements
```

Branch names use kebab-case: `feature/user-authentication`, `fix/login-redirect-loop`.

## Commit Conventions

Conventional commits with scope. Every commit message follows:

```
{type}: {description}

{optional body — what and why, not how}

Spec: specs/{feature}.md
AC: {acceptance criteria IDs covered}
```

### Types

- `feat:` — New feature or capability
- `fix:` — Bug fix
- `test:` — Adding or updating tests (RED phase)
- `refactor:` — Code restructuring, no behavior change (REFACTOR phase)
- `docs:` — Documentation only
- `style:` — Formatting, no logic change
- `perf:` — Performance improvement
- `chore:` — Build, tooling, dependency updates
- `ops:` — Infrastructure, deployment, CI/CD

### TDD Commit Pattern

Each TDD cycle produces 1-3 commits:

```
test: add failing tests for user login (RED)
Spec: specs/auth.md
AC: AC-001, AC-002

feat: implement user login endpoint (GREEN)
Spec: specs/auth.md
AC: AC-001, AC-002

refactor: extract password validation to utility (REFACTOR)
```

## When to Commit

- After each completed TDD phase (RED, GREEN, or REFACTOR)
- NEVER with failing tests on the branch
- NEVER with lint errors
- NEVER mid-implementation (half-written functions, incomplete features)

## Pull Request Flow

### Agent Creates PR With:

1. **Title:** `{type}: {concise description}` (< 70 characters)
2. **Body:**
   - Summary of changes (2-3 bullets)
   - Spec reference (`specs/{feature}.md`)
   - Acceptance criteria covered
   - Test results summary
   - Screenshots (if UI changes)
3. **TDD Checklist:**
   - [ ] Tests written before implementation (RED)
   - [ ] Implementation passes tests (GREEN)
   - [ ] Code refactored (REFACTOR)
   - [ ] Full test suite passes (VERIFY)
4. **Quality Gates:**
   - [ ] Linting clean
   - [ ] Type checking clean
   - [ ] Coverage meets threshold
   - [ ] Spec compliance verified

### What Requires Human Approval

- Merge to main/production branch
- Any deployment to production
- Schema migrations
- Security-sensitive changes (auth, permissions, secrets)
- Dependency major version upgrades

### What Agents Can Do Autonomously

- Commit to feature branches
- Create PRs (human reviews before merge)
- Deploy to dev/staging (if configured)
- Run quality gates and report results
- Fix lint/type errors on feature branches

## Protected Branches

`main` is always protected:

- No direct commits (all changes via PR)
- CI must pass before merge
- At least one review (human or agent reviewer)
- No force pushes
- No history rewrites

## Git Hygiene

- Rebase feature branches on main before PR (keep history linear)
- Squash commits only if the human requests it
- Delete feature branches after merge
- Tag releases with semantic versioning (`v1.2.3`)
- Never commit secrets, credentials, or API keys (use .gitignore and .env)

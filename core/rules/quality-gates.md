---
autoload: true
maturity: alpha
---

# ADD Rule: Quality Gates

Quality gates are checkpoints that code must pass before advancing.

## Gate Levels

### Gate 1: Pre-Commit (every commit)
- [ ] Linter passes (ruff/eslint)
- [ ] Formatter applied (ruff format/prettier)
- [ ] No merge conflicts
- [ ] No large files (> 1MB) staged
- [ ] No secrets or credentials staged
- [ ] No TODO/FIXME without issue or spec reference

### Gate 2: Pre-Push (every push)
- [ ] All unit tests pass
- [ ] Type checker passes (mypy/tsc)
- [ ] Coverage meets threshold (default 80%, configured in `.add/config.json`)

### Gate 3: CI Pipeline (every PR)
- [ ] Gate 1 + 2 pass
- [ ] Integration tests pass
- [ ] E2E tests pass (if UI changes)
- [ ] Screenshots captured (if E2E runs)

### Gate 4: Pre-Deploy
- [ ] Gate 3 passes
- [ ] No unresolved review comments
- [ ] Spec compliance: every AC has a passing test
- [ ] Human approval (for production)

### Gate 5: Post-Deploy
- [ ] Smoke tests pass (health, critical paths)
- [ ] No error spike in logs
- [ ] Key user flows accessible

## Commands

```
/add:verify          — Gate 1 + 2 (local)
/add:verify --ci     — Gate 1-3 (CI-level)
/add:verify --deploy — Gate 1-4 (pre-deploy)
/add:verify --smoke  — Gate 5 only (post-deploy)
```

## Spec Compliance

Every acceptance criterion must have at least one passing test. A feature is incomplete until all ACs are covered. See `spec-driven.md` for spec format and `tdd-enforcement.md` VERIFY phase for how TDD ensures coverage.

## Screenshot Protocol

For UI projects, capture screenshots at: page navigation, data load complete, user interaction results, modal open/close, error states, tab switches. Store at `tests/screenshots/{category}/step-{NN}-{description}.png`. Auto-capture on failure to `tests/screenshots/errors/`.

## Relaxed Mode

Configure in `.add/config.json` with `quality.mode: "spike"` for early prototypes (lower coverage threshold, type checking non-blocking). Gate 1 always applies.

## Maturity-Scaled Checks

Quality checks scale by maturity — lighter and advisory at Alpha, tighter and blocking at GA. The cascade matrix in `maturity-lifecycle.md` (rows 44-48) provides the overview. For detailed per-check enforcement tables (code quality thresholds, security checks, readability, performance, repo hygiene), see `${CLAUDE_PLUGIN_ROOT}/references/quality-checks-matrix.md`.

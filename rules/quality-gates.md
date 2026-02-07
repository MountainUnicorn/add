---
autoload: true
---

# ADD Rule: Quality Gates

Quality gates are checkpoints that code must pass before advancing. They are non-negotiable.

## Gate Levels

### Gate 1: Pre-Commit (every commit)

These run before or during commit. Failures block the commit.

- [ ] Linter passes (ruff/eslint — language-dependent)
- [ ] Formatter applied (ruff format/prettier — language-dependent)
- [ ] No merge conflicts
- [ ] No large files (> 1MB) accidentally staged
- [ ] No secrets or credentials in staged files
- [ ] No TODO/FIXME without an associated issue or spec reference

### Gate 2: Pre-Push (every push to remote)

These run before pushing. Failures block the push.

- [ ] All unit tests pass
- [ ] Type checker passes (mypy/tsc — language-dependent)
- [ ] Test coverage meets threshold (configured in `.add/config.json`, default 80%)
- [ ] No failing tests on the branch

### Gate 3: CI Pipeline (every PR)

These run in CI. Failures block merge.

- [ ] All Gate 1 and Gate 2 checks pass
- [ ] Integration tests pass
- [ ] Coverage report uploaded
- [ ] E2E tests pass (if UI changes, based on environment tier)
- [ ] Screenshots captured and attached (if E2E runs)

### Gate 4: Pre-Deploy (before any deployment)

These run before deployment. Failures block deploy.

- [ ] All Gate 3 checks pass
- [ ] No unresolved review comments
- [ ] Spec compliance verified (every acceptance criterion has a passing test)
- [ ] Human approval received (for production)

### Gate 5: Post-Deploy (after deployment)

These run after deployment. Failures trigger rollback discussion.

- [ ] Smoke tests pass (health endpoints, critical paths)
- [ ] No error spike in logs (if monitoring available)
- [ ] Key user flows accessible

## Quality Gate Commands

The `/verify` skill runs the appropriate gates based on context:

```
/verify          — Run Gate 1 + Gate 2 (local verification)
/verify --ci     — Run Gate 1 through Gate 3 (CI-level)
/verify --deploy — Run Gate 1 through Gate 4 (pre-deploy)
/verify --smoke  — Run Gate 5 only (post-deploy)
```

## Spec Compliance Verification

After implementation, verify every acceptance criterion:

```
SPEC COMPLIANCE REPORT — specs/auth.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AC-001: User can log in with valid credentials
  Status: COVERED
  Tests: test_ac001_login_success, TC-001 (e2e)

AC-002: Invalid password shows error message
  Status: COVERED
  Tests: test_ac002_invalid_password, TC-002 (e2e)

AC-003: Account locks after 5 failed attempts
  Status: NOT COVERED — no test exists
  Action: Write test before marking feature complete

RESULT: 2/3 criteria covered — INCOMPLETE
```

A feature is not complete until every acceptance criterion has at least one passing test.

## Screenshot Protocol

For projects with UI (configured in `.add/config.json`):

### When to Capture

- Page navigation or route change
- Data load complete (after loading state resolves)
- User interaction result (form submit, button click)
- Modal or dialog open/close
- Error states
- Tab or view switches

### Directory Structure

```
tests/screenshots/
  {test-category}/
    step-{NN}-{description}.png
```

### In E2E Tests

```typescript
await page.screenshot({
  path: `tests/screenshots/${category}/step-${step}-${description}.png`,
  fullPage: true
});
```

### On Failure

```typescript
test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status !== 'passed') {
    await page.screenshot({
      path: `tests/screenshots/errors/${testInfo.title}-${Date.now()}.png`,
      fullPage: true
    });
  }
});
```

## Relaxed Mode

For early spikes or prototypes, quality gates can be relaxed in `.add/config.json`:

```json
{
  "quality": {
    "mode": "spike",
    "coverage_threshold": 50,
    "type_check_blocking": false,
    "e2e_required": false
  }
}
```

Even in spike mode, Gate 1 (lint, format, no secrets) always applies. Tests must still be written before implementation — the coverage threshold is just lower.

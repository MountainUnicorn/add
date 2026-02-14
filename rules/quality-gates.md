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

The `/add:verify` skill runs the appropriate gates based on context:

```
/add:verify          — Run Gate 1 + Gate 2 (local verification)
/add:verify --ci     — Run Gate 1 through Gate 3 (CI-level)
/add:verify --deploy — Run Gate 1 through Gate 4 (pre-deploy)
/add:verify --smoke  — Run Gate 5 only (post-deploy)
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

## Maturity-Scaled Checks

In addition to the core gate checks above, these checks scale with project maturity. At lower maturity levels, checks are lighter and advisory. At higher maturity, they tighten and become blocking.

Read `.add/config.json` maturity field to determine which checks apply and their enforcement level.

### Check Categories

#### 1. Code Quality

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Lint errors | Blocking | Blocking | Blocking |
| Cyclomatic complexity | — | >15 advisory | >10 blocking |
| Code duplication | — | >10 lines advisory | >6 lines blocking |
| File length | — | >500 lines advisory | >300 lines blocking |
| Function length | — | >80 lines advisory | >50 lines blocking |

#### 2. Security & Vulnerability

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Secrets scan | Blocking | Blocking | Blocking |
| OWASP spot-check | Advisory | Full review advisory | Full review blocking |
| Dependency audit (known CVEs) | — | Advisory | Blocking |
| Auth pattern review | — | Advisory | Blocking |
| PII/data handling review | — | Advisory | Blocking |
| Rate limiting & secure headers | — | — | Required (blocking) |

#### 3. Readability & Documentation

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Naming consistency | Advisory | Advisory | Blocking |
| Nesting depth | — | <5 levels advisory | <4 levels blocking |
| Docstrings on exports | — | Advisory | Blocking |
| Complex logic comments | — | Advisory | Blocking |
| Magic number detection | — | Advisory | Blocking |
| Module READMEs | — | — | Blocking |
| Project glossary | — | — | Blocking |

#### 4. Performance

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| N+1 query detection | — | Advisory | Blocking |
| Blocking async detection | — | Advisory | Blocking |
| Bundle size check | — | Advisory | Blocking |
| Memory leak patterns | — | Advisory | Blocking |
| Performance tests | — | — | Required (blocking) |
| Response time baselines | — | — | Required (blocking) |

#### 5. Repo Hygiene

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Branch naming convention | Advisory | Advisory | Blocking |
| .gitignore exists | Advisory | Blocking | Blocking |
| LICENSE file | — | Advisory | Blocking |
| CHANGELOG maintained | — | Advisory | Blocking |
| Dependency freshness | — | Advisory | Blocking |
| README completeness | — | Advisory | Blocking (comprehensive) |
| PR template exists | — | Advisory | Blocking |
| Stale branches | — | Advisory | Blocking (14-day limit) |

### Gate Distribution

Checks are distributed across gates based on when they provide the most value:

**Gate 1 (Pre-Commit):** Code quality (lint, complexity, duplication, file/function length), secrets scan, readability (naming, nesting), branch naming convention

**Gate 2 (Pre-Push):** Dependency audit, OWASP review, docstrings on exports, N+1/blocking async detection, CHANGELOG/LICENSE check

**Gate 3 (CI):** Bundle size, PR template, README completeness, dependency freshness

**Gate 4 (Pre-Deploy):** Auth pattern review, PII/data handling, response time baselines, stale branch cleanup

**Gate 5 (Post-Deploy):** Response times vs baselines, secure headers verification

### Enforcement Levels

- **Blocking**: Check must pass or gate fails. Code cannot advance.
- **Advisory**: Check is reported in the gate output but does not block advancement. Findings appear in the report as warnings.
- **—**: Check is not performed at this maturity level.

### Configuration Overrides

Projects can override default thresholds in `.add/config.json`:

```json
{
  "qualityChecks": {
    "codeQuality": {
      "maxComplexity": 15,
      "maxDuplicationLines": 10,
      "maxFileLength": 500,
      "maxFunctionLength": 80
    },
    "security": {
      "dependencyAudit": true,
      "owaspLevel": "full"
    },
    "readability": {
      "maxNestingDepth": 5,
      "requireDocstrings": true
    },
    "performance": {
      "maxBundleSizeKb": 500,
      "responseTimeBaselineMs": 200
    },
    "repoHygiene": {
      "staleBranchDays": 14,
      "requireChangelog": true
    }
  }
}
```

When `qualityChecks` is not present, defaults from this rule apply. Per-category overrides merge with defaults — only specified fields are changed.

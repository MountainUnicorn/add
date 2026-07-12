# Verify Report Formats

Shared report formats for `/add-verify`. The skill defines each gate's checks
and pass/fail semantics; this template defines how results are presented.

## Per-Gate Report Format

Every gate reports in the same shape — a header naming the gate, the key
metrics for that gate, and a status line:

```
Gate {N}: {Gate Name}
- {metric}: {value}
- {metric}: {value} (threshold: {threshold}) ✓/✗
- Status: ✓ PASS | ✗ FAIL | ⚠ WARN | ⊘ SKIPPED

{Optional detail block: files checked, coverage gaps, findings, endpoints verified}
```

One worked example (Gate 3):

```
Gate 3: Unit Tests & Coverage
- Tests Run: 32
- Tests Passed: 32
- Tests Failed: 0
- Duration: 2.3s
- Line Coverage: 87% (threshold: 80%) ✓
- Branch Coverage: 82% (threshold: 80%) ✓
- Status: ✓ PASS

Coverage gaps (< 80%):
  - src/utils.ts: 73%
  - src/api.ts: 79%
```

On failure, replace the status line with `✗ FAIL`, list the specific errors or
findings, and end with a one-line remediation directive (e.g., "Rerun
`/add-tdd-cycle` from RED to regenerate snapshots.").

## Maturity-Scaled Checks (per-gate section)

Appended to each gate's report:

```
Maturity-Scaled Checks ({maturity level}):
  Code Quality: ✓ PASS (complexity max: 12, threshold: 15)
  Security: ✓ PASS (no secrets, OWASP clean)
  Readability: ⚠ ADVISORY (2 functions missing docstrings)
  Performance: ⊘ SKIPPED (not checked at alpha)
  Repo Hygiene: ✓ PASS (branch naming ok, .gitignore exists)

Advisory findings (non-blocking):
  - src/utils.ts:45 — function missing docstring on export
  - src/api.ts:12 — function missing docstring on export
```

## Overall Report Format

```
# Quality Gates Verification Report

## Execution Context
- Level: {level}
- Timestamp: {ISO timestamp}
- Feature: {feature-name}
- Branch: {git branch}
- Active Rules: {N} at {maturity} level

## Summary
Overall Status: ✓ ALL GATES PASSED [or ✗ GATES FAILED]

| Gate | Name | Status | Details |
|------|------|--------|---------|
| 1 | Lint & Formatting | ✓ PASS | 0 errors, 0 warnings |
| 2 | Type Checking | ✓ PASS | 0 type errors |
| 3 | Tests & Coverage | ✓ PASS | 32/32 tests, 87% coverage |
| 3.5 | Test Surface Integrity | ✓ PASS | 4 added, 0 removed, 1 renamed |
| 4 | Spec Compliance | ✓ PASS | 5/5 ACs tested |
| 4.6 | Staged-Secret Scan | ✓ PASS | 0 findings |
| 5 | Smoke Tests | ⊘ SKIPPED | Not applicable at this level |

## Gate {N}: {Gate Name}
{Per-gate report sections, one per gate that ran — see Per-Gate Report Format}

## Maturity-Scaled Checks Summary
Maturity Level: {level} (from .add/config.json)

| Category | Status | Blocking | Advisory | Details |
|----------|--------|----------|----------|---------|
| Code Quality | ✓ PASS | 0 | 0 | All metrics within thresholds |
| Security | ✓ PASS | 0 | 2 | OWASP spot-check: 2 minor findings |
| Readability | ⚠ WARN | 0 | 3 | 3 exports missing docstrings |
| Performance | ⊘ SKIP | — | — | Not checked at alpha maturity |
| Repo Hygiene | ✓ PASS | 0 | 0 | All hygiene checks pass |

Advisory Findings (non-blocking):
1. [{Category}] {file}:{line} — {finding}

---

## Recommendations

Ready to proceed: ✓ YES / ✗ NO
- {gate-level summary lines}

Next steps:
1. [If all gates pass] Run /add-deploy to commit and push
2. [If gates fail] Fix issues and re-run /add-verify

---

## Configuration Used
- test.framework: {framework}
- test.minCoverage: {threshold}%
- code.lint: {linter}
- ci.gates: {gates array}
```

## Configuration Example (`.add/config.json`)

```json
{
  "test": {
    "framework": "jest",
    "minCoverage": 80,
    "convention": "test_*.test.ts",
    "integrationConvention": "*.integration.test.ts"
  },
  "code": {
    "lint": "eslint",
    "types": "tsc --strict",
    "style": "prettier"
  },
  "ci": {
    "gates": ["lint", "types", "unit-tests", "spec-compliance", "integration-tests"],
    "smokeTestScript": "npm run test:smoke"
  }
}
```

---
description: "[ADD v0.2.0] Run quality gates — lint, types, tests, coverage, spec compliance"
argument-hint: "[--level local|ci|deploy|smoke] [--fix]"
allowed-tools: [Read, Glob, Grep, Bash, TodoWrite]
---

# ADD Verify Skill v0.2.0

Execute quality gates to verify code meets production standards. This skill runs automated checks and produces a structured pass/fail report.

## Overview

The Verify skill is the final checkpoint before deployment. It runs a sequence of quality gates determined by context and provides clear go/no-go status for each gate. Output is a structured report with pass/fail status and next steps.

The five-gate system ensures code quality at every stage:
1. **Gate 1 (Local)**: Lint & code formatting
2. **Gate 2 (Local)**: Type checking (if applicable)
3. **Gate 3 (CI)**: Unit tests & coverage
4. **Gate 4 (Deploy)**: Spec compliance & integration tests
5. **Gate 5 (Smoke)**: Post-deploy health checks

## Pre-Flight Checks

1. **Read .add/config.json**
   - Load gate definitions: which commands to run, thresholds
   - Load ci.gates array (ordered list of gates)
   - Load test.minCoverage threshold (default 80%)
   - Load code.lint configuration
   - Load code.types configuration
   - Load environment tier settings

2. **Determine execution level**
   - Use --level flag or infer from environment
   - If not specified, default to 'local'
   - Levels control which gates run:
     - **local**: Gates 1-2 (lint, types) for development
     - **ci**: Gates 1-3 (+ unit tests) for continuous integration
     - **deploy**: Gates 1-4 (+ spec compliance) for production deploy
     - **smoke**: Gate 5 only (post-deploy health check)

3. **Verify required files exist**
   - Test files exist (unless smoke level)
   - Implementation files exist
   - Config files exist (package.json, tsconfig.json, etc.)
   - CI/deployment scripts available

4. **Check environment**
   - Verify tools are installed (eslint, tsc, jest, pytest, etc.)
   - Check Node/Python version if applicable
   - Verify dependencies are installed

## Execution Steps

### Gate 1: Lint & Code Formatting

**Purpose**: Ensure code follows style conventions and has no obvious issues.

**Steps**:
1. **Detect linter(s)** from config or package.json
   - JavaScript/TypeScript: eslint, prettier, biome
   - Python: black, flake8, pylint
   - Go: gofmt, golangci-lint
   - etc.

2. **Run linter(s)**
   ```bash
   # JavaScript
   npx eslint --max-warnings 0 src/ tests/

   # Python
   python -m flake8 src/ tests/ --max-line-length 100

   # Go
   gofmt -w ./...
   golangci-lint run ./...
   ```

3. **Capture output**
   - Count errors and warnings
   - List problematic files
   - Save for report

4. **Handle --fix flag**
   - If --fix provided, auto-fix formatting issues
   - Re-run linter to verify fixes
   - Report what was fixed

5. **Pass/Fail**
   - PASS: 0 errors, 0 warnings (or configured threshold)
   - FAIL: Any errors or warnings
   - WARN: Warnings only (configurable as pass/fail)

**Report**:
```
Gate 1: Lint & Formatting
- Errors: 0
- Warnings: 0
- Status: ✓ PASS

Files checked: 12
Issues fixed (--fix): 0
```

### Gate 2: Type Checking

**Purpose**: Catch type errors and ensure type safety.

**Steps**:
1. **Detect type checker(s)**
   - TypeScript: `tsc --noEmit`
   - Flow: `flow`
   - MyPy (Python): `mypy src/`
   - etc.

2. **Run type checker**
   ```bash
   # TypeScript
   npx tsc --noEmit --strict

   # Python with MyPy
   python -m mypy src/ --strict
   ```

3. **Capture output**
   - Count type errors
   - List files with issues
   - Report error details

4. **Pass/Fail**
   - PASS: 0 type errors
   - FAIL: Any type errors
   - SKIP: Not applicable for untyped languages

**Report**:
```
Gate 2: Type Checking
- Errors: 0
- Status: ✓ PASS

Type checker: TypeScript (--strict)
Files checked: 12
```

### Gate 3: Unit Tests & Coverage

**Purpose**: Verify all tests pass and code coverage meets threshold.

**Steps**:
1. **Run test suite**
   ```bash
   # JavaScript
   npm test -- --coverage --silent

   # Python
   python -m pytest --cov=src --cov-report=term-summary tests/
   ```

2. **Parse test output**
   - Count tests run
   - Count tests passed
   - Count tests failed
   - Capture timing

3. **Parse coverage output**
   - Extract line coverage %
   - Extract branch coverage %
   - Extract function coverage %
   - Compare to minCoverage threshold

4. **Identify coverage gaps** (if below threshold)
   - Which files are below threshold?
   - Which lines are uncovered?
   - Which branches are untested?

5. **Pass/Fail criteria**
   - PASS: All tests pass AND coverage >= threshold
   - FAIL: Any test fails OR coverage < threshold
   - WARN: Tests pass but coverage marginally below (90% of threshold)

**Report**:
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

### Gate 4: Spec Compliance & Integration Tests

**Purpose**: Verify implementation meets spec and integration points work.

**Steps**:
1. **Read spec file** (specs/{feature}.md)
   - Extract all acceptance criteria
   - Load test mapping (tests/{feature}-mapping.md)

2. **Verify test coverage**
   - Every AC has at least one test
   - Every AC test is in the "passing" list
   - Every UT is covered by tests

3. **Run integration tests** (if separate suite)
   ```bash
   npm test -- --testMatch="**/*.integration.test.ts"
   # or
   python -m pytest tests/integration/ -v
   ```

4. **Spec compliance check**
   - Parse test mapping
   - Verify mapping completeness
   - Cross-check with spec requirements

5. **Pass/Fail**
   - PASS: All ACs tested and passing, all integration tests pass
   - FAIL: AC missing test, test failing, or integration test failing
   - WARN: AC has only happy-path test (no edge cases)

**Report**:
```
Gate 4: Spec Compliance & Integration Tests
- Spec: Feature X v1.0
- Acceptance Criteria: 5 total
  - AC-001: ✓ Tested and passing
  - AC-002: ✓ Tested and passing
  - AC-003: ✓ Tested and passing
  - AC-004: ✓ Tested and passing
  - AC-005: ✓ Tested and passing
- Integration Tests: 8 total
  - 8 passed, 0 failed
- Status: ✓ PASS

Test mapping file: tests/feature-mapping.md
All requirements traced and verified.
```

### Gate 5: Smoke Tests (Post-Deploy)

**Purpose**: Quick health check after deployment to catch obvious breakage.

**Steps**:
1. **Identify smoke test script**
   - From config: ci.smokeTestScript
   - Typical: `npm run test:smoke` or `./scripts/smoke-tests.sh`

2. **Run smoke tests against deployed environment**
   ```bash
   ENVIRONMENT=staging npm run test:smoke
   # or
   ./scripts/smoke-tests.sh production
   ```

3. **Capture output**
   - Tests run and result
   - Any errors or timeouts
   - Performance baseline check

4. **Pass/Fail**
   - PASS: All smoke tests pass within timeout
   - FAIL: Any test fails or timeout exceeded
   - SKIP: Not running (smoke level only)

**Report**:
```
Gate 5: Smoke Tests (Post-Deploy)
- Environment: staging
- Smoke tests run: 6
- Passed: 6
- Failed: 0
- Duration: 15s
- Status: ✓ PASS

Endpoints verified:
  ✓ GET /api/health
  ✓ GET /api/version
  ✓ POST /api/submit (with test data)
  ✓ GET /api/status
  ✓ Database connection
  ✓ Cache layer
```

## Execution by Level

### Level: local (development)
Runs Gates 1-2:
1. Lint & formatting
2. Type checking

Typical use: Before committing code locally

### Level: ci (continuous integration)
Runs Gates 1-3:
1. Lint & formatting
2. Type checking
3. Unit tests & coverage

Typical use: CI/CD pipeline on every push

### Level: deploy (production deploy)
Runs Gates 1-4:
1. Lint & formatting
2. Type checking
3. Unit tests & coverage
4. Spec compliance & integration tests

Typical use: Before deploying to production

### Level: smoke (post-deploy)
Runs Gate 5 only:
1. Smoke tests

Typical use: After deployment to verify health

## Overall Report Format

Generate a comprehensive verification report:

```
# Quality Gates Verification Report

## Execution Context
- Level: {level}
- Timestamp: {ISO timestamp}
- Feature: {feature-name}
- Branch: {git branch}

## Summary
Overall Status: ✓ ALL GATES PASSED [or ✗ GATES FAILED]

| Gate | Name | Status | Details |
|------|------|--------|---------|
| 1 | Lint & Formatting | ✓ PASS | 0 errors, 0 warnings |
| 2 | Type Checking | ✓ PASS | 0 type errors |
| 3 | Tests & Coverage | ✓ PASS | 32/32 tests, 87% coverage |
| 4 | Spec Compliance | ✓ PASS | 5/5 ACs tested |
| 5 | Smoke Tests | ⊘ SKIPPED | Not applicable at this level |

## Gate 1: Lint & Formatting
- Linter: eslint
- Status: ✓ PASS
- Errors: 0
- Warnings: 0
- Files checked: 12

## Gate 2: Type Checking
- Type checker: TypeScript (strict mode)
- Status: ✓ PASS
- Type errors: 0

## Gate 3: Unit Tests & Coverage
- Status: ✓ PASS
- Tests run: 32
- Passed: 32
- Failed: 0
- Duration: 2.3s
- Coverage:
  - Line: 87% (target: 80%) ✓
  - Branch: 82% (target: 80%) ✓
  - Function: 100% ✓

## Gate 4: Spec Compliance & Integration Tests
- Status: ✓ PASS
- ACs tested: 5/5
- Integration tests: 8 passed, 0 failed
- Spec: Feature X v1.0 (fully compliant)

## Gate 5: Smoke Tests
- Status: ⊘ SKIPPED (not applicable at 'deploy' level)

---

## Recommendations

Ready to proceed: ✓ YES
- All gates passed
- Code meets quality standards
- Safe to merge and deploy

Next steps:
1. [If all gates pass] Run /add:deploy to commit and push
2. [If gates fail] Fix issues and re-run /add:verify

Detailed gate results:
- No critical issues
- No warnings
- Coverage healthy

---

## Configuration Used
- test.framework: jest
- test.minCoverage: 80%
- code.lint: eslint with airbnb config
- ci.gates: [lint, types, tests, spec-compliance]
```

## Error Handling

**Gate fails**
- Report which gate failed and why
- List specific errors or failures
- Provide remediation guidance
- Exit with non-zero code

**Tools not installed**
- Report missing tool (eslint, tsc, jest, etc.)
- Provide installation command
- Suggest: `npm install` or `pip install`

**Coverage below threshold**
- Report current vs. target
- Identify which files are below threshold
- Suggest: add tests or check coverage report

**Tests timeout**
- Report which test timed out
- Suggest running individual test
- Suggest: `npm test -- --testNamePattern="test_name"`

**Environment issues**
- Smoke tests fail due to unavailable environment
- Report connectivity issues
- Suggest checking deployment status

## --fix Flag Behavior

When --fix is provided:
1. **Gate 1 (Lint)**: Auto-fix formatting issues
   - Run eslint --fix or prettier
   - Re-run linter to verify fixes applied
   - Report what was fixed

2. **Gate 2 (Types)**: Cannot auto-fix type errors
   - Report errors but don't halt
   - Suggest: review type errors manually

3. **Gate 3 (Tests)**: Cannot auto-fix test failures
   - Report failures
   - Suggest: check coverage, add missing tests

4. **Gate 4 (Spec)**: Cannot auto-fix spec mismatches
   - Report issues
   - Suggest: update tests or implementation

5. **Gate 5 (Smoke)**: Cannot auto-fix smoke test failures
   - Report failures
   - Suggest: check deployment

## Integration with Other Skills

- Used by /add:tdd-cycle during VERIFY phase
- Can be run standalone to check code quality
- Output informs /add:deploy decision
- Feeds back to /add:implementer or /add:reviewer if gates fail

## Configuration in .add/config.json

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

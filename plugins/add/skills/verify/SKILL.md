---
description: "[ADD v0.11.0] Run quality gates — lint, types, tests, coverage, spec compliance"
argument-hint: "[--level local|ci|deploy|smoke] [--fix]"
allowed-tools: [Read, Glob, Grep, Bash, TodoWrite]
references: ["learning-reference.md", "quality-checks-matrix.md", "secrets-gate.md", "skill-epilogue.md", "rules/telemetry.md"]
---

# ADD Verify Skill v0.11.0

Execute quality gates to verify code meets production standards. This skill runs automated checks and produces a structured pass/fail report.

<!-- cache-discipline: non-dispatching skill — no STABLE/VOLATILE markers required per rules/cache-discipline.md. Invoked AS a sub-agent by /add:tdd-cycle, which owns the cache-aware prompt layout. -->

## Overview

The Verify skill is the final checkpoint before deployment. It runs a sequence of quality gates determined by context and provides clear go/no-go status for each gate. Output is a structured report with pass/fail status and next steps.

The five-gate system ensures code quality at every stage:
1. **Gate 1 (Local)**: Lint & code formatting
2. **Gate 2 (Local)**: Type checking (if applicable)
3. **Gate 3 (CI)**: Unit tests & coverage
4. **Gate 4 (Deploy)**: Spec compliance & integration tests
5. **Gate 5 (Smoke)**: Post-deploy health checks

All gate results are reported using the shared formats in `${CLAUDE_PLUGIN_ROOT}/templates/verify-report.md` — one per-gate format, the maturity-scaled sections, and the overall report.

## Pre-Flight Checks

1. **Read .add/config.json**
   - Load gate definitions: which commands to run, thresholds
   - Load ci.gates array (ordered list of gates)
   - Load test.minCoverage threshold (default 80%)
   - Load code.lint configuration
   - Load code.types configuration
   - Load environment tier settings
   - A configuration example lives in `${CLAUDE_PLUGIN_ROOT}/templates/verify-report.md`

2. **Count active rules for maturity level**
   - Read maturity level from `.add/config.json` (default: alpha)
   - Scan all files in `rules/` directory
   - For each rule file, read the YAML frontmatter `maturity:` field
   - Count rules where the maturity field is at or below the current level
     - Maturity hierarchy: poc < alpha < beta < ga
     - A rule with `maturity: poc` is active at all levels
     - A rule with `maturity: beta` is active at beta and ga only
   - Include in report header: "{N} rules active at {maturity} level"

3. **Determine execution level**
   - Use --level flag or infer from environment
   - If not specified, default to 'local'
   - Levels control which gates run:
     - **local**: Gates 1-2 (lint, types) for development
     - **ci**: Gates 1-3 (+ unit tests) for continuous integration
     - **deploy**: Gates 1-4 (+ spec compliance) for production deploy
     - **smoke**: Gate 5 only (post-deploy health check)

4. **Verify required files exist**
   - Test files exist (unless smoke level)
   - Implementation files exist
   - Config files exist (package.json, tsconfig.json, etc.)
   - CI/deployment scripts available

5. **Check environment**
   - Verify tools are installed (eslint, tsc, jest, pytest, etc.)
   - Check Node/Python version if applicable
   - Verify dependencies are installed

6. **Check for session handoff** — per the Session-Handoff Preflight in `${CLAUDE_PLUGIN_ROOT}/references/skill-epilogue.md`

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

3. **Capture output** — count errors and warnings, list problematic files

4. **Handle --fix flag**
   - If --fix provided, auto-fix formatting issues
   - Re-run linter to verify fixes
   - Report what was fixed

5. **Pass/Fail**
   - PASS: 0 errors, 0 warnings (or configured threshold)
   - FAIL: Any errors or warnings
   - WARN: Warnings only (configurable as pass/fail)

### Gate 2: Type Checking

**Purpose**: Catch type errors and ensure type safety.

**Steps**:
1. **Detect type checker(s)** — TypeScript (`tsc --noEmit`), Flow, MyPy, etc.

2. **Run type checker**
   ```bash
   # TypeScript
   npx tsc --noEmit --strict

   # Python with MyPy
   python -m mypy src/ --strict
   ```

3. **Capture output** — count type errors, list files with issues

4. **Pass/Fail**
   - PASS: 0 type errors
   - FAIL: Any type errors
   - SKIP: Not applicable for untyped languages

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

2. **Parse test output** — tests run/passed/failed, timing

3. **Parse coverage output** — line, branch, and function coverage % vs. the minCoverage threshold

4. **Identify coverage gaps** (if below threshold) — which files, lines, and branches are uncovered

5. **Pass/Fail criteria**
   - PASS: All tests pass AND coverage >= threshold
   - FAIL: Any test fails OR coverage < threshold
   - WARN: Tests pass but coverage marginally below (90% of threshold)

### Gate 3.5: Test Surface Integrity (Test-Deletion Guardrail)

**Purpose**: Enforce the TDD anti-deletion invariant — tests added during RED must exist
(passing) at end of GREEN. Without this gate, Gate 3 passes even if the implementer
silently deleted failing tests to reach green.

**When it runs**: After Gate 3 (tests pass), before Gate 4 (spec compliance). Only
applicable when running within a TDD cycle context (i.e. `.add/cycles/cycle-{N}/`
snapshots exist). For standalone `/add:verify` runs, the gate is SKIPPED with an
advisory note.

**Steps**:

1. **Locate snapshots**
   - Determine the current cycle id (from `/add:cycle` context or the most recent
     `.add/cycles/cycle-*/` directory)
   - Determine the spec slug (from the cycle's spec argument)
   - Expected paths:
     - `.add/cycles/cycle-{N}/tdd-{slug}-red.json`
     - `.add/cycles/cycle-{N}/tdd-{slug}-green.json`

2. **Run the gate script**
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/../../scripts/check-test-count.py gate \
     --red .add/cycles/cycle-{N}/tdd-{slug}-red.json \
     --green .add/cycles/cycle-{N}/tdd-{slug}-green.json \
     --project-root .
   ```

   For standalone runs (no RED/GREEN snapshot), use the baseline form instead:
   ```bash
   python3 scripts/check-test-count.py --baseline origin/main
   ```

3. **Interpret exit code**
   - `0`: PASS. A structured JSON summary is emitted — capture it for the report.
   - `1`: FAIL. The script prints the removed tests, the override status, and a
     directive. Propagate the message verbatim.
   - `2`: Invocation error (bad args). Treat as gate failure.

4. **Capture the structured summary** (AC-017):
   ```
   tests_added: N, tests_removed: 0, tests_renamed: M, tests_replaced: 0, override: none
   ```

**Pass/Fail criteria**:
- PASS: `tests_removed == 0` AND `tests_replaced == 0` (or all removals/replacements
  are covered by an `overrides.json` record or a `[ADD-TEST-DELETE: ...]` commit trailer)
- FAIL: Any uncovered removal or replacement
- SKIP: No `.add/cycles/cycle-*/` dir (standalone verify outside a cycle)

**Error mode** (AC-015): if the GREEN snapshot is missing, FAIL with "GREEN snapshot
not found — cycle is incomplete or test-writer/implementer skipped snapshotting" and
remediation "Rerun `/add:tdd-cycle` from RED to regenerate snapshots."

See `core/rules/tdd-enforcement.md` "Test-Deletion Invariant" for the justification
marker formats and the full rationale.

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

### Gate 4.5: AGENTS.md Drift (Opt-In)

**Purpose**: Detect drift between the project's canonical ADD state and its published `AGENTS.md`.

**Opt-In**: This gate runs only when `.add/config.json` contains `"agentsMd": {"gateOnVerify": true}`. Default is `false` — AGENTS.md is advisory for projects that have not opted in.

**When enabled**:

1. Check that `AGENTS.md` exists at project root. If absent, warn and skip (not a fail — the project may not publish one).
2. Run `python3 scripts/generate-agents-md.py --check` from the project root.
   - Exit 0 → in sync, gate PASSES.
   - Exit 1 → drift detected, gate FAILS (advisory — does not block Gate 5).
3. Print the unified diff on failure for fast human review. Suggest `/add:agents-md --write` to remediate.

### Gate 4.6: Staged-Secret Scan

**Purpose**: Block commits that contain secrets before they reach the remote
git history. Closes F-014 (the v0.9.0 secrets gate was prose-only).

**When it runs**: At `--level deploy` (and any superset). Skipped at `--level
local|ci|smoke` because no commit is being prepared at those levels.

**How it runs**: Follow `${CLAUDE_PLUGIN_ROOT}/references/secrets-gate.md` —
scanner invocation, exit-code interpretation, redaction rules, and report
format all live there. NEVER paste a matched secret value into the report.

**Pass/Fail criteria**:
- PASS: Scanner exit code 0
- FAIL: Scanner exit code != 0 (findings, invocation error, or missing catalog — never silently disable enforcement)
- SKIP: `--level` is `local`, `ci`, or `smoke` (no staged commit context)

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

3. **Capture output** — tests run and result, errors or timeouts, performance baseline check

4. **Pass/Fail**
   - PASS: All smoke tests pass within timeout
   - FAIL: Any test fails or timeout exceeded
   - SKIP: Not running (smoke level only)

### Maturity-Scaled Checks (All Gates)

After each gate's core checks, run maturity-scaled checks from the quality-gates rule. These checks progressively tighten with project maturity.

**Execution Pattern** (repeat for each gate):

1. **Read maturity level** from `.add/config.json` (default: alpha)
2. **Load maturity-scaled checklist** from `${CLAUDE_PLUGIN_ROOT}/references/quality-checks-matrix.md` → Maturity-Scaled Checks section
3. **Filter checks for this gate** using the Gate Distribution mapping:
   - **Gate 1:** Code quality (complexity, duplication, file/function length), secrets scan, readability (naming, nesting), branch naming
   - **Gate 2:** Dependency audit, OWASP review, docstrings on exports, N+1/blocking async detection, CHANGELOG/LICENSE
   - **Gate 3:** Bundle size, PR template, README completeness, dependency freshness
   - **Gate 4:** Auth pattern review, PII/data handling, response time baselines, stale branch cleanup
   - **Gate 5:** Response times vs baselines, secure headers verification
4. **Execute checks** using agent tools:
   - Use Grep to scan for patterns (secrets, magic numbers, N+1 queries, blocking async calls)
   - Use Read to inspect files (function length, nesting depth, docstrings, README content)
   - Use Bash to run tools (dependency audit, bundle size, lint with complexity rules)
   - Use Glob to find files (LICENSE, CHANGELOG, PR template, .gitignore, stale branches)
5. **Classify findings** as blocking or advisory per maturity level
   - Load override thresholds from `.add/config.json` `qualityChecks` if present
   - Apply enforcement level: blocking findings fail the gate, advisory findings are warnings
6. **Include in gate report** — append maturity-scaled results to the gate's report section, and add the Maturity-Scaled Checks Summary to the overall report (formats in `${CLAUDE_PLUGIN_ROOT}/templates/verify-report.md`)

## Execution by Level

### Level: local (development)
Runs Gates 1-2:
1. Lint & formatting
2. Type checking

Typical use: Before committing code locally

### Level: ci (continuous integration)
Runs Gates 1-3 (Gate 3.5 runs if cycle snapshots present):
1. Lint & formatting
2. Type checking
3. Unit tests & coverage
3.5 Test Surface Integrity (only if `.add/cycles/cycle-*/` snapshots exist)

Typical use: CI/CD pipeline on every push

### Level: deploy (production deploy)
Runs Gates 1-4 (plus 3.5, 4.5 opt-in, 4.6):
1. Lint & formatting
2. Type checking
3. Unit tests & coverage
3.5 Test Surface Integrity (test-deletion guardrail)
4. Spec compliance & integration tests
4.5 AGENTS.md drift (opt-in via config)
4.6 Staged-secret scan (always)

Typical use: Before deploying to production

### Level: smoke (post-deploy)
Runs Gate 5 only:
1. Smoke tests

Typical use: After deployment to verify health

## Report Generation

Generate the comprehensive verification report using the formats in
`${CLAUDE_PLUGIN_ROOT}/templates/verify-report.md`:

- One per-gate section per gate that ran (per-gate format)
- The summary table with overall status
- The Maturity-Scaled Checks Summary
- Recommendations with explicit next steps: `/add:deploy` if all gates pass,
  fix and re-run `/add:verify` if any fail
- The Configuration Used footer

## Progress Tracking

**Tasks to create** (mechanics per `${CLAUDE_PLUGIN_ROOT}/references/skill-epilogue.md`):

| Phase | Subject | activeForm |
|-------|---------|------------|
| Pre-flight | Running pre-flight checks | Running pre-flight checks... |
| Gate 1 | Lint and formatting | Checking lint and formatting... |
| Gate 2 | Type checking | Running type checks... |
| Gate 3 | Tests and coverage | Running tests and checking coverage... |
| Gate 3.5 | Test surface integrity | Checking test-deletion guardrail... |
| Gate 4 | Spec compliance | Verifying spec compliance... |
| Gate 4.6 | Staged-secret scan | Scanning staged content for secrets... |
| Gate 5 | Smoke tests | Running smoke tests... |
| Maturity | Maturity-scaled checks | Running maturity-scaled checks... |
| Report | Generating verification report | Generating verification report... |

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
1. **Gate 1 (Lint)**: Auto-fix formatting issues — run eslint --fix or prettier, re-run linter to verify, report what was fixed
2. **Gate 2 (Types)**: Cannot auto-fix type errors — report errors, suggest manual review
3. **Gate 3 (Tests)**: Cannot auto-fix test failures — report failures, suggest checking coverage or adding tests
4. **Gate 4 (Spec)**: Cannot auto-fix spec mismatches — report issues, suggest updating tests or implementation
5. **Gate 5 (Smoke)**: Cannot auto-fix smoke test failures — report failures, suggest checking deployment

## Integration with Other Skills

- Used by /add:tdd-cycle during VERIFY phase
- Can be run standalone to check code quality
- Output informs /add:deploy decision
- Feeds back to /add:implementer or /add:reviewer if gates fail

End-of-skill epilogue: follow `${CLAUDE_PLUGIN_ROOT}/references/skill-epilogue.md` (observation + learning checkpoint + progress tracking). Learning checkpoint trigger: "After Verification".

---
description: "[ADD v0.3.0] Execute complete TDD cycle — RED → GREEN → REFACTOR → VERIFY against a spec"
argument-hint: "specs/{feature}.md [--ac AC-001,AC-002] [--parallel]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite]
---

# ADD TDD Cycle Skill v0.3.0

Execute a complete Test-Driven Development cycle for a feature from the specification through production-quality code.

## Overview

The TDD Cycle is the primary "do the work" skill in Agent Driven Development. It orchestrates the full lifecycle:

1. **RED** — Write failing tests from spec acceptance criteria
2. **GREEN** — Implement minimal code to pass those tests
3. **REFACTOR** — Improve code quality while keeping tests green
4. **VERIFY** — Run all quality gates to ensure production readiness

This skill coordinates sub-agents (test-writer, implementer, reviewer, verify) and maintains traceability between specs, tests, and implementation.

## Pre-Flight Checks

Before beginning, validate:
1. Spec file exists at path provided in argument
2. Read the spec frontmatter to extract:
   - Feature name
   - Acceptance criteria (ACs)
   - User test cases (UTs)
   - Status and version
3. Load .add/config.json to determine:
   - Test framework and conventions
   - Code style rules
   - Quality gate thresholds
   - Parallelization preference
4. Verify plan exists at docs/plans/{feature}-plan.md
   - If not, generate one using /add:plan skill before proceeding
5. Identify target implementation paths from the spec
6. **Check for session handoff**
   - Read `.add/handoff.md` if it exists
   - Note any in-progress work or decisions relevant to this operation
   - If handoff mentions blockers for this skill's scope, warn before proceeding

## Execution Phases

### Phase 1: RED — Test Writing

Invoke the /add:test-writer skill with the spec reference:
- Pass argument: `specs/{feature}.md [--ac AC-001,AC-002]`
- This generates failing tests covering all acceptance criteria
- Tests must be named using convention: `test_AC_NNN_description` for traceability
- Each test maps to one or more ACs from the spec
- Allow parallel test generation if --parallel flag is set

Verify tests actually fail:
- Run the test command: `npm test` or `python -m pytest` depending on config
- Confirm exit code is non-zero (tests fail)
- Log any compilation/import errors — halt if tests can't run

### Phase 2: GREEN — Implementation

Once RED phase is complete, invoke the /add:implementer skill:
- Pass argument: `specs/{feature}.md [--ac AC-001,AC-002]`
- Implementer writes minimal code to pass each test
- Target: Every test should pass with as little code as possible
- No over-engineering; defer non-essential features

After implementation:
- Run tests again: `npm test` or equivalent
- Verify all tests pass (exit code 0)
- Capture test output showing pass counts
- If any tests still fail, return to implementer with failure details

### Phase 3: REFACTOR — Code Quality

With all tests green, refactor for quality:
1. Run the /add:reviewer skill to identify issues:
   - Pass argument: `specs/{feature}.md --scope full`
   - Reviewer produces READ-ONLY report on code quality and spec compliance
2. Address reviewer findings:
   - Use /edit to improve variable names, reduce duplication, improve structure
   - Maintain test-green status after each refactoring change
   - Run tests after every significant refactor: `npm test`
3. Focus areas:
   - DRY principle (Don't Repeat Yourself)
   - Clear, descriptive names for functions and variables
   - Proper error handling and edge case coverage
   - Comment complex logic
   - Consistent formatting per .add/config.json

### Phase 4: VERIFY — Quality Gates

Run the full verification suite using /add:verify skill:
- Pass argument: `--level deploy` (all gates for production readiness)
- Verify produces a structured report:
  - Gate 1: Lint and formatting (must pass)
  - Gate 2: Type checking (must pass)
  - Gate 3: Unit test coverage >= configured threshold (default 80%)
  - Gate 4: Spec compliance (every AC has a passing test)
  - Gate 5: Integration tests if applicable

If any gate fails:
- Review the failure details
- Return to appropriate phase (GREEN for test failures, REFACTOR for style)
- Re-run verification

## Output Format

Upon successful completion, output:

```
# TDD Cycle Complete ✓

## Feature
{feature-name} v{spec-version}

## Summary
- Tests Written: {count}
- Tests Passing: {count}
- Code Coverage: {percentage}%
- Refactoring Issues Fixed: {count}
- Quality Gates: {pass/total}

## Acceptance Criteria Status
- AC-001: ✓ Passing
- AC-002: ✓ Passing
... (all ACs listed with status)

## Next Steps
1. Review code in {implementation-path}
2. Merge to main branch
3. Deploy to staging environment

## Artifacts
- Tests: {test-file-paths}
- Implementation: {code-file-paths}
- Plan: docs/plans/{feature}-plan.md
```

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner. Create tasks at the start of each major phase and mark them completed as they finish.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Pre-flight | Loading spec and config | Loading spec and config... |
| RED | Writing failing tests | Writing failing tests... |
| GREEN | Implementing code | Implementing code to pass tests... |
| REFACTOR | Refactoring for quality | Refactoring for code quality... |
| VERIFY | Running verification gates | Running verification gates... |

Mark each task `in_progress` when starting and `completed` when done. This gives the user real-time visibility into skill execution.

## Error Handling

**Tests won't compile/run**
- Check syntax errors in test-writer output
- Verify test framework is installed per config
- Check imports and paths are correct
- Run: `npm install` or equivalent dependency installation

**Tests still failing after GREEN phase**
- Implementer may have missed test requirements
- Run `/add:implementer` again with specific AC range
- Check test output for assertion details

**Quality gate failures**
- Lint errors: Run with `--fix` flag on /add:verify
- Coverage below threshold: Write additional tests or increase coverage in refactor phase
- Spec compliance: Verify every AC has a mapped test; update test mapping if needed

**Performance issues detected**
- Dispatch /add:optimize skill to identify bottlenecks
- Apply optimizations and re-run verify

## Integration with Other Skills

- **test-writer**: Invoked during RED phase; generates test files
- **implementer**: Invoked during GREEN phase; generates implementation
- **reviewer**: Invoked during REFACTOR phase; produces quality report (read-only)
- **verify**: Invoked during VERIFY phase; produces gate report and pass/fail
- **plan**: Called pre-cycle if plan doesn't exist; provides task breakdown

## Parallelization

If --parallel flag is set:
- Test writing (RED) can be parallelized by AC groups
- Implementation (GREEN) proceeds after all RED tests complete (serial dependency)
- Refactoring (REFACTOR) is typically serial (one logical flow)
- Verification (VERIFY) runs all gates in order (serial)

## Configuration

The skill respects these .add/config.json settings:
- `test.framework`: The test framework (jest, pytest, vitest, etc.)
- `test.minCoverage`: Minimum code coverage percentage
- `test.convention`: Test file naming convention
- `code.style`: Code style rules and linters
- `ci.gates`: Which gates to run and in what order

## Process Observation

After completing this skill, do BOTH:

### 1. Observation Line

Append one observation line to `.add/observations.md`:

```
{YYYY-MM-DD HH:MM} | tdd-cycle | {one-line summary of outcome} | {cost or benefit estimate}
```

If `.add/observations.md` does not exist, create it with a `# Process Observations` header first.

### 2. Learning Checkpoint

Write a structured JSON learning entry per the checkpoint trigger in `rules/learning.md` (section: "After TDD Cycle Completes"). Classify scope, write to the appropriate JSON file (`.add/learnings.json` or `~/.claude/add/library.json`), and regenerate the markdown view.

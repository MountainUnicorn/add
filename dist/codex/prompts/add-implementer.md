# ADD Implementer Skill v0.8.0

Write minimal production-quality code to make failing tests pass. This is the GREEN phase of TDD.

<!-- cache-discipline: non-dispatching skill — no STABLE/VOLATILE markers required per rules/cache-discipline.md. Invoked AS a sub-agent by /add:tdd-cycle, which owns the cache-aware prompt layout. -->

## Overview

The Implementer takes failing tests (from test-writer) and writes the smallest amount of code necessary to make them all pass. The goal is:
- Make tests green with minimal code
- No over-engineering or premature optimization
- Production-quality implementation (no shortcuts)
- Defer non-essential features for future work
- Maintain clean architecture and separation of concerns

## Pre-Flight Checks

1. **Verify test files exist and fail**
   - Read test file(s) from path provided by test-writer
   - Run tests to confirm they fail: `npm test` or `python -m pytest`
   - Capture baseline: count of failing tests
   - Halt if tests don't exist or already pass

1b. **Read the impact hint (v0.9.0 — AC-022)**
   - The tdd-cycle orchestrator emits a files-likely-affected block via
     `core/lib/impact-hint.sh`. Consume it as part of this skill's context:

     ```
     ## Files likely to need changes
       - app/auth.py
       - app/session.py

     ## Files to be careful around (recent anti-pattern learnings exist)
       - app/session.py  [L-042]
     ```

   - Use the first list as the starting set for Step 2 (Design Implementation)
   - Treat the second list as warnings: those paths have recent anti-pattern
     learnings — read the learning (by ID) before editing
   - If the hint reports *"No source files implied by RED diff"* (AC-024), fall
     back to the spec's acceptance criteria for implementation targets

2. **Read the feature spec**
   - Load spec file from argument
   - Extract feature name, acceptance criteria, requirements
   - Understand the "what" before implementing

3. **Load test mapping**
   - Read tests/{feature}-mapping.md (created by test-writer)
   - Understand which tests map to which ACs
   - Ensures implementation covers all required ACs

4. **Determine implementation structure**
   - Identify main entry point(s) from spec
   - Determine file naming and organization
   - Load any existing partial implementation (if resuming)

5. **Read .add/config.json**
   - Load code.style, code.language preferences
   - Load any build/transpilation settings
   - Load dependency management settings

6. **Check for session handoff**
   - Read `.add/handoff.md` if it exists
   - Note any in-progress work or decisions relevant to this operation
   - If handoff mentions blockers for this skill's scope, warn before proceeding

## Execution Steps

### Step 1: Analyze Test Requirements

For each failing test:
1. **Read the test code** to understand assertions
2. **Identify what it tests**:
   - Input values
   - Function/method being tested
   - Expected output
   - Edge cases or error conditions
3. **Note dependencies**:
   - What modules/classes need to exist
   - What functions need to be exported
   - What data structures are needed

Example analysis:
```typescript
// Test:
it('should return sum of two numbers', () => {
  expect(add(2, 3)).toBe(5);
});

// Requires:
// - Function named 'add'
// - Takes two number parameters
// - Returns number (sum)
```

### Step 2: Design Implementation

Create a plan without writing code:
1. **Identify modules to create**
   - Main feature module
   - Supporting utilities
   - Data structures
2. **List functions/classes needed**
   - Name, parameters, return type
   - Minimal behavior required
3. **Consider dependencies**
   - External libraries needed
   - Internal module interactions
4. **Plan error handling**
   - Required validation
   - Exception cases

### Step 3: Implement Core Functions

Start with simplest, most-dependent-upon functions first:

**For JavaScript/TypeScript:**
```typescript
// src/feature.ts - minimal implementation
export function add(a: number, b: number): number {
  return a + b;
}

export class Feature {
  constructor(private config: FeatureConfig) {}

  doSomething(input: string): string {
    return input.toUpperCase();
  }
}
```

**For Python:**
```python
# src/feature.py - minimal implementation
def add(a: int, b: int) -> int:
    return a + b

class Feature:
    def __init__(self, config):
        self.config = config

    def do_something(self, input_str: str) -> str:
        return input_str.upper()
```

### Step 4: Run Tests After Each Function

After implementing each logical unit:
1. **Run tests**: `npm test` or `python -m pytest`
2. **Check progress**: How many tests now pass?
3. **Debug failures**:
   - Read error message
   - Check if it's a logic error or missing functionality
   - Fix and re-run
4. **Only add code needed to pass tests**
   - Don't add validation that no test requires
   - Don't add error messages that no test checks
   - Keep it minimal

### Step 5: Implement Supporting Code

As tests progress to GREEN:
1. **Add necessary utilities** (helpers, formatters, etc.)
2. **Implement data structures** (models, interfaces)
3. **Add minimal error handling**:
   - Only validate what tests require
   - Only throw exceptions that tests expect
   - Use appropriate error types
4. **Wire up dependencies**:
   - Imports and exports
   - Constructor parameters
   - Module initialization

### Step 5b: NEVER delete tests to reach green (v0.9.0 — AC-028)

If a failing test seems wrong, it is NOT your decision to delete it. Stop, surface the
discrepancy to the human, and (if confirmed) rerun the cycle with `--allow-test-rewrite`.
Silent deletion fails Gate 3.5 and halts the cycle. The directive is:

*"Test deletion during a TDD cycle is forbidden. Fix the implementation, not the test."*

### Step 6: Achieve Full Green State

Run full test suite:
```bash
npm test
# or
python -m pytest
```

Verify:
- All tests pass (exit code 0)
- Test count matches expected
- No skipped or pending tests
- Coverage is captured

Example output:
```
PASS  tests/feature.test.ts
  Feature Name
    AC-001: requirement
      ✓ test_AC_001_behavior_a (15ms)
      ✓ test_AC_001_behavior_b (12ms)
    AC-002: requirement
      ✓ test_AC_002_behavior_c (8ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Coverage:    85%
```

### Step 7: Capture GREEN snapshot (v0.9.0 — AC-007)

Before returning control to the tdd-cycle orchestrator, capture the test surface
snapshot for Gate 3.5:

```bash
python3 ~/.codex/add/../../scripts/check-test-count.py snapshot \
  --phase green \
  --cycle-id {N} \
  --spec-slug {slug} \
  --base-sha {cycle-base-sha}
```

The snapshot lives at `.add/cycles/cycle-{N}/tdd-{slug}-green.json` and is compared
against the RED snapshot by `/add:verify` Gate 3.5. If `tests_removed > 0` without an
override, the cycle fails with a structured error naming each removed test.

## Code Quality Standards

Implementation code must:
1. **Be readable**
   - Clear variable and function names
   - Logical organization
   - Comments on complex logic
2. **Handle errors appropriately**
   - Validate required inputs
   - Return meaningful errors
   - Use try-catch sparingly
3. **Follow language conventions**
   - Per .add/config.json style guide
   - Consistent indentation, naming
   - Standard library patterns
4. **Be testable**
   - Pure functions where possible
   - Dependency injection
   - Avoid global state
5. **Be minimal**
   - No premature optimization
   - No unused code
   - No over-architecting

## Testing Verification Steps

After implementation reaches GREEN:
1. **Run tests multiple times** to ensure deterministic
2. **Check for test isolation issues**:
   - Tests should pass in any order
   - No shared state between tests
   - Run in random order: `npm test -- --shuffle`
3. **Verify test coverage**:
   - All ACs have passing tests
   - All user test cases pass
   - Edge cases covered
4. **Document implementation**:
   - Add comments explaining non-obvious logic
   - Document public API in docstrings
   - Note any design decisions

## Output Format

Upon successful GREEN phase completion, output:

```
# Implementation Complete (GREEN Phase) ✓

## Feature
{feature-name} v{spec-version}

## Test Results
- Tests Passing: {count}/{total}
- Tests Failing: 0/{total}
- Test Duration: {seconds}s

## Acceptance Criteria Implementation
- AC-001: ✓ Implemented and passing
- AC-002: ✓ Implemented and passing
... (all ACs listed)

## Code Coverage
- Line Coverage: {percentage}%
- Branch Coverage: {percentage}%
- Function Coverage: {percentage}%

## Implementation Files Created/Modified
- {file-path}: {N} functions, {N} classes
- {file-path}: {N} functions

## Next Steps
1. Run /add:reviewer to check code quality
2. Run /add:tdd-cycle REFACTOR phase to improve code
3. Merge implementation

## Notes
- All tests green as of {timestamp}
- Ready for code review and refactoring
- No over-engineering; minimal viable implementation
```

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner. Create tasks at the start of each major phase and mark them completed as they finish.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Read tests | Reading failing tests | Reading failing tests... |
| Analyze | Analyzing requirements | Analyzing requirements... |
| Implement | Writing implementation code | Writing implementation code... |
| Verify GREEN | Confirming all tests pass | Verifying tests pass (GREEN confirmed)... |

Mark each task `in_progress` when starting and `completed` when done. This gives the user real-time visibility into skill execution.

## Error Handling

**Tests still failing after implementation**
- Review the failing test output carefully
- Identify what's not implemented:
  - Missing function/class
  - Wrong return type
  - Incorrect logic
- Implement the missing piece
- Re-run tests

**Type errors or compilation failures**
- Check imports and exports
- Verify function signatures match test expectations
- Check for typos in function names
- Re-run tests after fixes

**Tests pass but coverage is low**
- Add implementation to cover untested branches
- Or add tests that exercise missing code paths
- Report coverage and ask user if acceptable

**Existing implementation conflicts with tests**
- If implementation exists but doesn't match tests:
  - Check if tests or implementation is correct per spec
  - Modify one or the other to align
  - Verify with user if unsure

**Performance issues**
- If tests pass but are slow:
  - Note the timing issue
  - Continue to REFACTOR phase for optimization
  - Don't optimize prematurely in GREEN

## Integration with TDD Cycle

- This skill is invoked during the GREEN phase of /add:tdd-cycle
- Input: Failing tests from /add:test-writer
- Output: Implementation that passes all tests
- Next: /add:reviewer for code quality check
- Finally: /refactor phase for improvements

## Code Style & Conventions

The implementer respects:
- Language conventions (.add/config.json)
- Project structure (determined by config)
- Import/export patterns
- Naming conventions
- Error handling patterns

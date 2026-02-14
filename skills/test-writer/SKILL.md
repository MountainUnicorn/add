---
description: "[ADD v0.2.0] Write failing tests from spec (TDD RED phase)"
argument-hint: "specs/{feature}.md [--ac AC-001,AC-002] [--type unit|integration|e2e]"
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# ADD Test Writer Skill v0.2.0

Generate comprehensive failing tests from a feature specification. This is the RED phase of TDD — write tests before implementation.

## Overview

Test Writer converts acceptance criteria and user test cases from a spec into failing, runnable tests. The output is test files that:
- Compile and execute but fail (RED state)
- Have clear, descriptive names mapped to ACs
- Cover all acceptance criteria and user test cases
- Follow the project's test conventions
- Are production-quality (good error messages, clear assertions)

## Pre-Flight Checks

1. **Verify spec file exists and is readable**
   - Read the spec at the provided path
   - Extract frontmatter: feature name, version, status

2. **Parse acceptance criteria**
   - Read the Acceptance Criteria section
   - Extract each AC with its ID (AC-001, AC-002, etc.)
   - Extract the criteria description and conditions

3. **Parse user test cases**
   - Read the User Test Cases section (if present)
   - Extract each UT with ID (UT-001, UT-002, etc.)
   - Note the setup, actions, and expected outcomes

4. **Load test framework configuration**
   - Read .add/config.json
   - Identify test.framework (jest, pytest, vitest, mocha, pytest, etc.)
   - Load test.convention (naming pattern, directory structure, imports)
   - Check test.type to determine default test type

5. **Identify test file location**
   - Determine target directory from config (typically `tests/` or `__tests__/`)
   - Determine file naming from convention
   - Check if test file already exists; if so, append new tests

## Execution Steps

### Step 1: Analyze Acceptance Criteria

For each acceptance criterion:
1. Extract the requirement statement
2. Break down into testable assertions
3. Identify input conditions, actions, and expected outputs
4. Note any data setup required
5. Consider both happy path and edge cases

Example AC:
```
AC-001: When user clicks the "Submit" button with valid form data,
        the form should POST to /api/submit and display a success message.
```

Maps to tests:
- `test_AC_001_submit_valid_data_posts_to_api`
- `test_AC_001_submit_valid_data_displays_success_message`
- `test_AC_001_submit_shows_error_on_network_failure` (edge case)

### Step 2: Design Test Structure

For each AC, determine:
1. **Test type** from --type flag or config default
   - `unit`: Test individual functions/components in isolation
   - `integration`: Test feature interactions with other modules
   - `e2e`: Test complete user workflows end-to-end
2. **Test scope**: What needs to be mocked vs. real
3. **Setup requirements**: Fixtures, test data, mocks
4. **Assertions**: What the test verifies

### Step 3: Generate Test Files

Create test file(s) following the framework conventions:

**For Jest/Vitest (JavaScript/TypeScript):**
- File: `tests/{feature}.test.ts` or `__tests__/{feature}.test.js`
- Import testing libraries and mocks
- Use `describe()` blocks for AC grouping
- Use `test()` or `it()` for individual test cases
- Include setup/teardown with `beforeEach()`, `afterEach()`

Example template:
```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
// imports for module under test

describe('Feature Name', () => {
  describe('AC-001: requirement statement', () => {
    beforeEach(() => {
      // Setup for this AC
    });

    it('should test specific behavior', () => {
      // Arrange
      const input = { /* test data */ };

      // Act
      const result = functionUnderTest(input);

      // Assert
      expect(result).toBe(expectedValue);
    });
  });
});
```

**For pytest (Python):**
- File: `tests/test_{feature}.py`
- Use `class Test{Feature}:` for grouping by AC
- Use `def test_ac_NNN_description(self):` for test methods
- Use `pytest.fixture` for setup
- Use `assert` statements

Example template:
```python
import pytest
# imports for module under test

class TestFeatureName:
    """Tests for Feature Name"""

    @pytest.fixture
    def setup(self):
        # Setup fixture
        yield
        # Teardown

    class TestAC001:
        """AC-001: requirement statement"""

        def test_specific_behavior(self, setup):
            # Arrange
            input_data = { /* test data */ }

            # Act
            result = function_under_test(input_data)

            # Assert
            assert result == expected_value
```

### Step 4: Ensure Tests Fail

After generating tests:
1. **Attempt to compile/run tests**
   ```bash
   npm test          # for JavaScript/TypeScript
   python -m pytest  # for Python
   ```

2. **Verify they fail with clear messages**
   - Every test must fail (exit code non-zero)
   - Error messages should indicate missing implementation
   - Examples:
     - "Cannot find module: './feature'" (module doesn't exist)
     - "NameError: name 'feature_function' is not defined"
     - "AssertionError: undefined !== 'expected value'"

3. **If tests don't fail**
   - Implementation may already exist (unexpected)
   - Or test is incorrectly written (syntax error)
   - Fix test syntax errors; if implementation exists, ask user to clarify

### Step 5: Document Test Mapping

Create a test mapping file: `tests/{feature}-mapping.md`

```markdown
# Test Mapping for {Feature Name}

## Acceptance Criteria Coverage

| AC ID | Description | Test File | Test Function | Status |
|-------|-------------|-----------|-----------------|--------|
| AC-001 | requirement | tests/{feature}.test.ts | test_AC_001_* | ✗ FAIL |
| AC-002 | requirement | tests/{feature}.test.ts | test_AC_002_* | ✗ FAIL |

## User Test Cases Coverage

| UT ID | Description | Test File | Test Function | Status |
|-------|-------------|-----------|-----------------|--------|
| UT-001 | scenario | tests/{feature}.test.ts | test_UT_001_* | ✗ FAIL |

## Notes
- All tests are currently in RED state (failing)
- Tests are ready for implementation in GREEN phase
- No implementation code exists yet
```

## Test Naming Convention

Tests must follow the convention for traceability:

```
test_AC_{id}_{description}_{condition}
```

Examples:
- `test_AC_001_user_can_submit_valid_form`
- `test_AC_001_submission_fails_with_empty_email`
- `test_AC_002_success_message_shows_user_name`

## Test Quality Standards

Each test must:
1. **Have a single responsibility** — test one behavior
2. **Be independent** — no dependencies on other tests
3. **Use clear names** — test name describes what's being tested
4. **Follow Arrange-Act-Assert pattern**
   - Arrange: Set up test data and mocks
   - Act: Call the function or trigger the behavior
   - Assert: Verify the outcome
5. **Include setup/teardown** for dependencies
6. **Have descriptive error messages** for assertions
7. **Be fast** — unit tests in milliseconds, integration in seconds

## Output Format

Upon completion, output:

```
# Test Writing Complete (RED Phase) ✓

## Feature
{feature-name} v{spec-version}

## Tests Generated
- Total Tests: {count}
- By Type:
  - Unit Tests: {count}
  - Integration Tests: {count}
  - E2E Tests: {count}
- All in RED state (failing as expected)

## Acceptance Criteria Coverage
- AC-001: ✓ Covered by {N} tests
- AC-002: ✓ Covered by {N} tests
... (all ACs listed)

## Test Files Created
- {test-file-path}
- {test-file-path}

## Coverage Status
- Mapping file: tests/{feature}-mapping.md
- Ready for GREEN phase (implementation)

## Next Steps
1. Run /add:implementer to write minimal code to pass tests
2. Verify all tests pass
3. Proceed to REFACTOR phase
```

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner. Create tasks at the start of each major phase and mark them completed as they finish.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Parse spec | Reading spec and acceptance criteria | Reading spec and acceptance criteria... |
| Analyze framework | Analyzing test framework configuration | Analyzing test framework configuration... |
| Write tests | Writing failing tests | Writing failing tests... |
| Verify RED | Confirming tests fail as expected | Verifying tests fail (RED confirmed)... |

Mark each task `in_progress` when starting and `completed` when done. This gives the user real-time visibility into skill execution.

## Error Handling

**Spec parsing fails**
- Verify spec YAML frontmatter is valid
- Check AC format matches `AC-###: description`
- Halt and ask user to fix spec format

**Test file already exists**
- Append new tests to existing file
- Don't overwrite; preserve existing tests
- Report which tests are new

**Tests don't fail when run**
- This indicates implementation may already exist
- Verify the module path is correct
- If implementation exists, ask user if they want to:
  - Proceed to GREEN/REFACTOR phases
  - Or start fresh with new test file

**Test framework not installed**
- Provide guidance: "Install jest with: npm install --save-dev jest"
- Don't halt; user will install and retry

**Syntax errors in generated tests**
- Review the generated code carefully
- Fix imports, quotes, formatting
- Re-run tests to verify they compile

## Integration with TDD Cycle

- This skill is invoked during the RED phase of /add:tdd-cycle
- Output becomes input to /add:implementer (GREEN phase)
- Test mapping is used by /add:reviewer to verify spec compliance

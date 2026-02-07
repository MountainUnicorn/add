---
autoload: true
---

# ADD Rule: Test-Driven Development

All implementation follows strict TDD. The cycle is RED → GREEN → REFACTOR → VERIFY.

## The Cycle

### RED Phase — Write Failing Tests

1. Read the spec's acceptance criteria and user test cases
2. Write test(s) that assert the expected behavior
3. Run the tests — they MUST fail
4. If tests pass before implementation, the tests are wrong (testing existing behavior, not new)

### GREEN Phase — Minimal Implementation

1. Write the MINIMUM code to make failing tests pass
2. No extra features, no "while I'm here" additions
3. No optimization — just make it work
4. Run tests — they MUST pass

### REFACTOR Phase — Improve Quality

1. Clean up code without changing behavior
2. Extract functions, rename variables, remove duplication
3. Run tests after EVERY refactor — they must still pass
4. Apply project naming conventions and patterns

### VERIFY Phase — Independent Confirmation

1. Run the FULL test suite, not just new tests
2. Run linter (ruff/eslint depending on language)
3. Run type checker (mypy/tsc depending on language)
4. Verify spec compliance — do the changes satisfy the acceptance criteria?
5. If any gate fails, fix before proceeding

## Mandatory Rules

- NEVER write implementation before tests exist and FAIL
- NEVER skip the RED phase — "I'll add tests later" is not allowed
- NEVER commit with failing tests on the branch
- When a sub-agent implements code, the orchestrator MUST run tests independently
- Each TDD cycle should be a single, atomic commit

## Test Naming

Tests must reference the spec:

```python
# Backend (pytest)
def test_ac001_user_can_login_with_valid_credentials():
def test_ac002_invalid_password_shows_error():
def test_tc001_login_success_flow():
```

```typescript
// Frontend (vitest/playwright)
describe('AC-001: User login', () => {
  it('should authenticate with valid credentials', ...);
});

describe('TC-001: Login success flow', () => {
  it('step 1: navigate to /login', ...);
  it('step 2: enter credentials and submit', ...);
  it('step 3: see dashboard with username', ...);
});
```

## Coverage Requirements

Coverage targets are set in `.add/config.json` during project init. Defaults:

- Unit tests: 80% line coverage
- Integration tests: Critical paths covered
- E2E tests: All user test cases from specs have corresponding tests

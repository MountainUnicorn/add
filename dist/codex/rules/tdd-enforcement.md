---
autoload: true
maturity: beta
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

## Test-Deletion Invariant (v0.9.0 / M3)

**Tests added during RED MUST exist (passing) at the end of GREEN.** Test deletion during
the cycle is forbidden without `--allow-test-rewrite` **and** explicit human approval.
Test renames are permitted (same normalized body, different function name); test
replacements (same name, rewritten body beyond the similarity threshold) require
approval.

This invariant is enforced at three points:

1. **End of RED** — `/add:test-writer` writes a snapshot at
   `.add/cycles/cycle-{N}/tdd-{slug}-red.json` capturing every test function's path,
   name, and normalized body hash. The snapshot is committed (`test(red): snapshot N
   tests for {slug}`). Failure mode: if RED produces zero new tests, the cycle halts —
   RED with no new tests is itself a TDD violation.
2. **End of GREEN** — `/add:implementer` re-runs discovery against the same files and
   writes `.add/cycles/cycle-{N}/tdd-{slug}-green.json` with identical schema.
3. **Gate 3.5 in `/add:verify`** — runs `scripts/check-test-count.py gate --red ... --green ...`.
   If `tests_removed > 0` without an override, or `tests_replaced > 0` without
   `--allow-test-rewrite`, the gate fails with a structured error listing each removed
   or replaced test. The cycle does not advance to Gate 4.

### Justification markers

A test deletion or replacement is authorized by **either**:

- A commit trailer in the range `base..HEAD` of the form
  `[ADD-TEST-DELETE: <AC-id or reason>]`. Used for out-of-cycle rewrites or small
  maintenance changes.
- A file at `.add/cycles/cycle-{N}/overrides.json` of shape:

  ```json
  {
    "kind": "test-rewrite",
    "approved_by": "human",
    "timestamp": "2026-04-22T14:32:00Z",
    "affected_tests": ["tests/path.py::function_name"]
  }
  ```

Either form is recorded in telemetry and surfaced in `/add:retro` for review.

### Rationale

The genie doesn't want to do TDD (Kent Beck, 2026) — the path of least resistance for a
coding agent is to remove the failing test rather than satisfy it. The TDAD paper
(arXiv 2603.17973) observed naive TDD-prompting *increased* regression rate to 9.94%
because agents silently deleted tests they couldn't satisfy. ADD's separation of concerns
(test-writer vs implementer) only matters if the tests written in RED survive GREEN.
This invariant enforces that.

### Why both markers are accepted

Some TDD-cycle runs are fully scripted (`--allow-test-rewrite` with an `overrides.json`
approval); others are ad-hoc developer work where a commit trailer is the lighter-weight
signal. Both land in the same telemetry channel so retros can review legitimacy.

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

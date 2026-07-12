# Commit Message Format

Full format specification and worked example for `/add:deploy` Step 2
(Prepare Commit Message).

## Format

```
{Type}: {Short description under 50 chars}

{Longer description explaining the change}

Acceptance Criteria:
- AC-001: ✓ Implemented and tested
- AC-002: ✓ Implemented and tested

Test Coverage:
- {N} tests passing
- {N}% code coverage

Quality Gates:
- ✓ Lint passing
- ✓ Types passing
- ✓ Tests passing
- ✓ Spec compliance verified

Closes: #{issue-number} (if applicable)
```

## Types

- feat: New feature
- fix: Bug fix
- refactor: Code refactoring
- test: Test additions
- docs: Documentation
- perf: Performance optimization
- ci: CI/CD changes
- chore: Build, deps, etc.

## Worked Example

```
feat: Add form submission with email validation

Implement user-facing form with client-side and server-side
validation. Integrates with existing email service for
verification. Handles network errors with retry logic.

Acceptance Criteria:
- AC-001: ✓ User can submit valid form data
- AC-002: ✓ Form shows validation errors
- AC-003: ✓ Network failures handled gracefully

Test Coverage:
- 8 tests passing
- 87% code coverage
- All ACs verified

Quality Gates:
- ✓ Lint: 0 errors
- ✓ Types: 0 errors (TypeScript strict)
- ✓ Tests: 32 passing
- ✓ Coverage: 87% (target: 80%)
- ✓ Spec compliance: 5/5 ACs tested

Closes: #1234
```

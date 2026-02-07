---
description: "Review code for spec compliance and quality — produces review report"
argument-hint: "specs/{feature}.md [--scope backend|frontend|full]"
allowed-tools: [Read, Glob, Grep, Bash]
---

# Reviewer Skill

Conduct a comprehensive code review focused on specification compliance, code quality, and ADD methodology adherence. This is a READ-ONLY skill that produces a detailed structured review report.

## Overview

The Reviewer analyzes implementation against the spec and quality standards without modifying code. It checks:
- **Spec Compliance**: Every acceptance criterion has a corresponding passing test
- **Code Quality**: Readability, maintainability, style adherence
- **Test Coverage**: Edge cases, error conditions, user scenarios
- **Architecture**: Separation of concerns, dependency management
- **Error Handling**: Validation, exception handling, error messages
- **Documentation**: Comments, docstrings, API clarity
- **ADD Adherence**: Test coverage, traceability, naming conventions

## Pre-Flight Checks

1. **Verify spec file exists**
   - Read spec at provided path
   - Extract feature name, acceptance criteria, user test cases
   - Identify scope (backend, frontend, or full system)

2. **Verify implementation exists**
   - Locate implementation files from spec or config
   - Verify code files are readable
   - Check for completeness (no placeholder files)

3. **Verify tests exist and pass**
   - Locate test files (tests/ or __tests__/)
   - Read test mapping file if available
   - Run tests to confirm all passing: `npm test` or `python -m pytest`
   - Halt if tests not passing (code not GREEN)

4. **Load configuration**
   - Read .add/config.json for:
     - Code style rules
     - Test coverage thresholds
     - Quality standards
     - Naming conventions

5. **Determine review scope**
   - Use --scope flag or infer from config
   - backend: Server, API, database code
   - frontend: UI, components, client code
   - full: Everything

## Execution Steps

### Step 1: Spec Compliance Check

For each acceptance criterion:
1. **Find corresponding test(s)**
   - Search test files for test_AC_NNN_* pattern
   - Verify test exists and has clear name mapping
   - Check test mapping file for complete AC coverage

2. **Verify test passes**
   - Run the specific test to confirm it passes
   - Check no tests are skipped or marked as pending

3. **Examine test quality**
   - Does it properly verify the AC requirement?
   - Are assertions clear and specific?
   - Does it test happy path AND error cases?

4. **Find implementation code**
   - Trace from test to code being tested
   - Verify implementation code exists and matches test expectations
   - Check function/class names match test imports

5. **Compare implementation to AC**
   - Does implementation fulfill the acceptance criterion?
   - All requirements met?
   - Behavior matches specification?

Document findings:
```
AC-001: User can submit form with valid data
  ✓ Test exists: test_AC_001_submit_valid_data
  ✓ Test passes
  ✓ Implementation found: submitForm() in src/form.ts
  ✓ Behavior matches specification
  Note: Good error message when validation fails
```

### Step 2: Code Quality Review

Examine code for quality across dimensions:

**Readability**
- Are variable/function names clear and descriptive?
- Is nesting depth reasonable (max 3-4 levels)?
- Are long functions broken into smaller ones?
- Is whitespace used effectively?
- Example findings:
  ```
  ✓ Function names are clear (submitForm, validateEmail)
  ✓ Variables well-named (userEmail, isValid)
  ⚠ Long function parseFormData (120 lines) could be split
  ```

**Maintainability**
- Is code DRY (Don't Repeat Yourself)?
- Are there magic numbers or strings (should be constants)?
- Is structure logical and easy to navigate?
- Can code be extended without rewriting?
- Example findings:
  ```
  ⚠ Email validation regex appears 3 times (use constant)
  ⚠ API endpoint "/api/submit" hard-coded in 2 places
  ✓ Class structure is clear
  ```

**Style Adherence**
- Does code follow .add/config.json conventions?
- Consistent indentation, naming case, spacing?
- Imports organized and sorted?
- Example findings:
  ```
  ✓ Follows camelCase naming convention
  ✓ Consistent 2-space indentation
  ⚠ Missing trailing semicolons (config requires them)
  ✓ Imports alphabetically sorted
  ```

**Error Handling**
- Are inputs validated?
- Are error messages helpful?
- Are exceptions appropriate?
- Is error recovery possible?
- Example findings:
  ```
  ✓ Email input validated before submission
  ⚠ Generic "Error" message instead of "Invalid email format"
  ✓ Network error handled with retry logic
  ```

**Comments & Documentation**
- Are complex sections commented?
- Do public APIs have docstrings?
- Are assumptions documented?
- Are gotchas explained?
- Example findings:
  ```
  ✓ Public functions have JSDoc comments
  ⚠ Complex validation logic lacks explanation
  ✓ Workaround for IE11 bug well-documented
  ```

### Step 3: Test Coverage Analysis

1. **Coverage metrics**
   - Check line coverage (default min 80%)
   - Check branch coverage
   - Check function coverage
   - Report any below-threshold areas

2. **AC-to-Test mapping**
   - Verify every AC has at least one test
   - Verify every UT is covered
   - Identify orphaned test cases

3. **Edge case coverage**
   - Are error conditions tested?
   - Are boundary values tested?
   - Are invalid inputs tested?
   - Example findings:
     ```
     ✓ Happy path tested
     ✓ Network timeout tested
     ⚠ Empty string input not tested
     ✓ Maximum form size tested
     ```

4. **Test quality**
   - Are tests independent (can run in any order)?
   - Do tests have clear assertions?
   - Are setup/teardown proper?
   - Do tests test behavior, not implementation?

### Step 4: Architecture & Design Review

1. **Separation of concerns**
   - Is business logic separated from UI/API?
   - Are cross-cutting concerns (logging, error handling) centralized?
   - Are modules focused and single-purpose?

2. **Dependency management**
   - Are dependencies injected or hard-coded?
   - Is module coupling loose?
   - Are circular dependencies avoided?

3. **Data structures**
   - Are types/interfaces used properly?
   - Is data validation centralized?
   - Are models well-designed?

4. **API design**
   - Are public interfaces clean and intuitive?
   - Are parameters well-named?
   - Are return types appropriate?

### Step 5: ADD Methodology Adherence

1. **Test naming**
   - Do tests follow `test_AC_NNN_description` pattern?
   - Are test names descriptive?
   - Can ACs be traced from test names?

2. **Implementation traceability**
   - Can tests be mapped to code?
   - Can code be mapped back to ACs?
   - Is traceability documented (mapping file)?

3. **Spec-Test-Code alignment**
   - Does code match spec requirements?
   - Do tests verify code against spec?
   - Is the chain unbroken?

4. **Minimal implementation**
   - Is code minimal (no over-engineering)?
   - Are there unused code paths?
   - Is there premature optimization?

## Review Report Format

Generate a comprehensive structured report:

```
# Code Review Report

## Feature
{feature-name} v{spec-version}

## Review Scope
Backend [or Frontend or Full System]

## Executive Summary
Overall quality: {Excellent / Good / Fair / Needs Work}
Spec compliance: {percentage}%
Test coverage: {percentage}%
Code quality score: {N}/10

---

## 1. SPEC COMPLIANCE ✓/{total}

### Acceptance Criteria Coverage
| AC ID | Description | Test | Status | Notes |
|-------|-------------|------|--------|-------|
| AC-001 | requirement | test_AC_001_* | ✓ Pass | Implementation aligns well |
| AC-002 | requirement | test_AC_002_* | ✓ Pass | Edge case handled properly |

### User Test Cases Coverage
| UT ID | Scenario | Test | Status | Notes |
|-------|----------|------|--------|-------|
| UT-001 | user scenario | test_UT_001_* | ✓ Pass | Clear test naming |

### Findings
- ✓ All acceptance criteria have passing tests
- ✓ All user test cases are covered
- ⚠ [If any issues] AC-003 missing edge case test for empty input

---

## 2. CODE QUALITY

### Readability
- ✓ Function names are clear and descriptive
- ✓ Variables use meaningful names
- ✓ Code structure is logical
- ⚠ [Issue] parseFormData() function is 120 lines, consider splitting
- ⚠ [Issue] Magic string "/api/submit" appears 3 times

### Maintainability
- ✓ DRY principle followed (no significant duplication)
- ✓ Classes are focused and single-purpose
- ⚠ [Issue] Email regex hard-coded in validator, should be constant

### Style Adherence
- ✓ Follows camelCase naming convention
- ✓ Consistent indentation (2 spaces)
- ✓ Imports alphabetically sorted
- ⚠ [Issue] Missing trailing semicolons (config requires them)

### Error Handling
- ✓ Input validation on all entry points
- ✓ Network errors handled with retry
- ⚠ [Issue] Error messages are generic ("Error") instead of specific
- ⚠ [Issue] Missing validation for email format

### Documentation
- ✓ Public functions have JSDoc comments
- ✓ Complex logic commented
- ⚠ [Issue] API endpoint contracts not documented
- ⚠ [Issue] Missing README for module

---

## 3. TEST COVERAGE

### Coverage Metrics
- Line Coverage: 87% (target: 80%) ✓
- Branch Coverage: 82% (target: 80%) ✓
- Function Coverage: 100% ✓

### Coverage Gaps
- [If any] Lines 45-52 in form.ts not covered (error path)
- [If any] Branch for IE11 workaround not tested

### Edge Cases
- ✓ Network timeout tested
- ✓ Invalid email tested
- ⚠ [Issue] Empty string input not tested
- ✓ Maximum form size tested
- ✓ Concurrent submissions tested

### Test Quality
- ✓ Tests are independent (pass in any order)
- ✓ Setup/teardown properly isolated
- ✓ Assertions are specific and clear
- ✓ Tests verify behavior, not implementation

---

## 4. ARCHITECTURE & DESIGN

### Separation of Concerns
- ✓ Business logic separated from UI
- ✓ API layer distinct from business logic
- ✓ Validation centralized in one module

### Dependency Management
- ✓ Dependencies injected via constructors
- ✓ No circular dependencies detected
- ✓ Coupling is loose and appropriate

### Data Structures
- ✓ TypeScript interfaces used effectively
- ✓ Models are well-defined
- ✓ Type safety enforced

### API Design
- ✓ Public API is clean and intuitive
- ✓ Parameters well-named and documented
- ✓ Return types are appropriate

---

## 5. ADD METHODOLOGY

### Test Naming & Traceability
- ✓ Tests follow AC naming pattern (test_AC_NNN_*)
- ✓ Test mapping file exists and is accurate
- ✓ Can trace test → code → spec

### Implementation Quality
- ✓ Minimal viable implementation (no over-engineering)
- ✓ No unused code paths
- ✓ No premature optimization

### Documentation
- ✓ Test mapping file present and complete
- ⚠ [If missing] No plan document (docs/plans/{feature}-plan.md)

---

## ISSUES & RECOMMENDATIONS

### Critical Issues (Must Fix)
1. [Issue description] - Severity: High
   - Location: {file}:{line}
   - Impact: {explanation}
   - Recommendation: {fix}

### Major Issues (Should Fix)
2. [Issue description] - Severity: Medium
   - Location: {file}:{line}
   - Recommendation: {fix}

### Minor Issues (Nice to Have)
3. [Issue description] - Severity: Low
   - Location: {file}:{line}
   - Recommendation: {fix}

---

## APPROVAL STATUS

- [✓] Spec Compliance: All ACs implemented and tested
- [✓] Test Coverage: Above minimum threshold
- [✓] Code Quality: Acceptable for production
- [⚠] Ready for Production: [Yes / Needs Fixes]

---

## Next Steps

1. [Fix critical issues if any]
2. Run /tdd-cycle REFACTOR phase to address findings
3. Re-review after fixes
4. Proceed to staging deployment
```

## Notes on Review Approach

1. **READ-ONLY**: This skill never modifies files
2. **Objective**: Focus on facts (tests pass/fail, code exists/missing)
3. **Constructive**: Frame issues as opportunities for improvement
4. **Actionable**: Provide specific recommendations
5. **Evidence-based**: Cite line numbers, file paths, test results

## Error Handling

**Tests are not passing**
- Halt review
- Report which tests fail
- Ask user to run /tdd-cycle GREEN phase first

**Spec file is incomplete**
- Halt review
- Report missing AC or UT definitions
- Ask user to complete spec

**Implementation files missing**
- Halt review
- Report which files are missing
- Ask user to generate implementation

**Code cannot be parsed**
- Report syntax error
- Provide file and line number
- Ask user to fix syntax

## Integration with TDD Cycle

- This skill is invoked during REFACTOR phase of /tdd-cycle
- Input: Implementation files and passing tests
- Output: Review report (conversation output only)
- No file modifications
- Report guides REFACTOR improvements

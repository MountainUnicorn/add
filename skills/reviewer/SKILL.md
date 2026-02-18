---
description: "[ADD v0.4.0] Review code for spec compliance and quality — produces review report"
argument-hint: "specs/{feature}.md [--scope backend|frontend|full]"
allowed-tools: [Read, Glob, Grep, Bash]
---

# ADD Reviewer Skill v0.4.0

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

6. **Check for session handoff**
   - Read `.add/handoff.md` if it exists
   - Note any in-progress work or decisions relevant to this operation
   - If handoff mentions blockers for this skill's scope, warn before proceeding

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

### Step 6: Security Review

Depth scales with maturity level (read from `.add/config.json`):
- **Alpha**: Spot-check — scan for obvious issues only
- **Beta**: Systematic — full review, findings are advisory
- **GA**: Comprehensive — full review, findings are blocking

**Checks:**

1. **Injection scanning**
   - Search for unsanitized user input in SQL queries, shell commands, template literals, HTML output
   - Use Grep to find patterns: `exec(`, `eval(`, raw SQL string concatenation, `innerHTML =`, `dangerouslySetInnerHTML`
   - Check for parameterized queries / prepared statements

2. **Auth pattern review** (Beta+)
   - Verify authentication checks on protected routes/endpoints
   - Check for constant-time password/token comparison
   - Verify session management (expiry, rotation, invalidation)
   - Check JWT validation (signature, expiry, audience)

3. **Data handling** (Beta+)
   - Scan for PII logged to console or files (emails, passwords, tokens, SSNs)
   - Verify sensitive data encrypted at rest and in transit
   - Check for hardcoded credentials, API keys, connection strings
   - Verify input validation on all external-facing boundaries

4. **Dependency review** (Beta+)
   - Check for known CVEs in dependencies (`npm audit` / `pip audit` / `cargo audit`)
   - Flag outdated packages with known security patches
   - Review new dependency additions for trustworthiness

5. **Infrastructure** (GA)
   - Verify rate limiting on public endpoints
   - Check for secure headers (CORS, CSP, HSTS, X-Frame-Options)
   - Verify HTTPS enforcement
   - Check error responses don't leak internal details

**Score**: X/10 based on findings count and severity

```
## 6. SECURITY REVIEW ({maturity} depth)

Score: 8/10

### Injection Scanning
- ✓ No raw SQL concatenation found
- ✓ All user input sanitized before template usage
- ⚠ src/api.ts:34 — input used in template literal without escaping

### Auth Patterns (Beta+)
- ✓ Protected routes have auth middleware
- ✓ JWT validated with signature + expiry check
- ⚠ src/auth.ts:89 — password comparison not constant-time

### Data Handling (Beta+)
- ✓ No PII in log statements
- ✓ No hardcoded credentials
- ✓ Input validation on all API endpoints

### Dependencies (Beta+)
- ✓ No known CVEs (npm audit clean)
- ✓ All dependencies on latest patch versions
```

### Step 7: Performance Review

Only executed at **Beta and above**. At Alpha, this step is skipped entirely.
- **Beta**: All checks advisory
- **GA**: All checks blocking, performance tests and response time baselines required

**Checks:**

1. **N+1 query detection**
   - Search for database queries inside loops (e.g., `for` / `forEach` / `map` containing query calls)
   - Use Grep to find patterns: ORM calls (`.find(`, `.query(`, `.get(`) inside loop bodies
   - Flag any query-per-iteration patterns

2. **Blocking async detection**
   - Search for synchronous I/O in async contexts (`readFileSync`, `execSync`, blocking HTTP calls)
   - Check for `await` inside loops where `Promise.all` could be used
   - Flag CPU-intensive operations on the main thread / event loop

3. **Memory patterns**
   - Check for unbounded caches or collections (growing arrays/maps without eviction)
   - Flag event listeners added without cleanup (missing `removeEventListener` / `unsubscribe`)
   - Check for closures holding large objects unnecessarily

4. **Bundle size** (if applicable)
   - Run `npm run build` or equivalent and check output size
   - Flag unusually large bundles or missing tree-shaking
   - Check for large dependencies that could be replaced with lighter alternatives

5. **Performance tests** (GA only)
   - Verify performance test suite exists
   - Check for response time baseline definitions
   - Verify benchmarks run and pass within thresholds

**Score**: X/10 based on findings count and severity

```
## 7. PERFORMANCE REVIEW (Beta+ only)

Score: 9/10

### N+1 Detection
- ✓ No queries inside loops found
- ✓ Batch loading used for related entities

### Async Patterns
- ✓ No synchronous I/O in async contexts
- ⚠ src/batch.ts:45 — sequential await in loop, consider Promise.all

### Memory Patterns
- ✓ Event listeners cleaned up in teardown
- ✓ No unbounded collections detected

### Bundle Size
- ✓ Build output: 142KB gzipped (threshold: 500KB)
- ✓ Tree-shaking active, no dead code detected
```

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
Security score: {N}/10
Performance score: {N}/10 (Beta+ only)

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

## 6. SECURITY REVIEW ({maturity} depth)

Score: {N}/10

### Injection Scanning
- {findings}

### Auth Patterns (Beta+)
- {findings}

### Data Handling (Beta+)
- {findings}

### Dependencies (Beta+)
- {findings}

---

## 7. PERFORMANCE REVIEW (Beta+ only)

Score: {N}/10

### N+1 Detection
- {findings}

### Async Patterns
- {findings}

### Memory Patterns
- {findings}

### Bundle Size
- {findings}

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
- [✓] Security Review: No blocking findings
- [✓] Performance Review: No blocking findings (Beta+ only)
- [⚠] Ready for Production: [Yes / Needs Fixes]

---

## Next Steps

1. [Fix critical issues if any]
2. Run /add:tdd-cycle REFACTOR phase to address findings
3. Re-review after fixes
4. Proceed to staging deployment
```

## Notes on Review Approach

1. **READ-ONLY**: This skill never modifies files
2. **Objective**: Focus on facts (tests pass/fail, code exists/missing)
3. **Constructive**: Frame issues as opportunities for improvement
4. **Actionable**: Provide specific recommendations
5. **Evidence-based**: Cite line numbers, file paths, test results

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner. Create tasks at the start of each major phase and mark them completed as they finish.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Load | Loading spec and config | Loading spec and config... |
| Spec compliance | Checking spec compliance | Checking spec compliance... |
| Code quality | Reviewing code quality | Reviewing code quality... |
| Test coverage | Analyzing test coverage | Analyzing test coverage... |
| Architecture | Reviewing architecture | Reviewing architecture... |
| Security | Running security review | Running security review... |
| Performance | Running performance review | Running performance review... |
| Report | Generating review report | Generating review report... |

Mark each task `in_progress` when starting and `completed` when done. This gives the user real-time visibility into skill execution.

## Error Handling

**Tests are not passing**
- Halt review
- Report which tests fail
- Ask user to run /add:tdd-cycle GREEN phase first

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

- This skill is invoked during REFACTOR phase of /add:tdd-cycle
- Input: Implementation files and passing tests
- Output: Review report (conversation output only)
- No file modifications
- Report guides REFACTOR improvements

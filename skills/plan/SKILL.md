---
description: "[ADD v0.4.0] Create implementation plan from a feature spec"
argument-hint: "specs/{feature}.md"
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# ADD Plan Skill v0.4.0

Create a detailed implementation plan from a feature specification. This skill analyzes acceptance criteria, breaks down work into manageable tasks, identifies parallelizable work, and estimates effort.

## Overview

The Plan skill transforms a specification into an actionable implementation roadmap. It produces a plan document (docs/plans/{feature}-plan.md) that guides development work and enables:
- Task breakdown and prioritization
- Effort estimation
- Dependency identification
- Parallelization opportunities
- Risk assessment
- Resource allocation

The plan bridges the gap between "what to build" (spec) and "how to build it" (implementation).

## Pre-Flight Checks

1. **Verify spec exists and is complete**
   - Read spec file from argument
   - Verify YAML frontmatter is valid
   - Extract feature name, version, status
   - Verify acceptance criteria are defined
   - Verify user test cases are defined (if applicable)

2. **Load project configuration**
   - Read .add/config.json
   - Load team size (solo, small, large)
   - Load tech stack
   - Load constraints (timeline, budget, etc.)
   - Load parallelization preferences

3. **Analyze dependencies**
   - Identify upstream work needed
   - Check for blockers
   - Identify integration points

4. **Check for existing plan**
   - Look for docs/plans/{feature}-plan.md
   - If exists, ask user: overwrite or update?
   - Preserve previous efforts if updating

5. **Check for session handoff**
   - Read `.add/handoff.md` if it exists
   - Note any in-progress work or decisions relevant to this operation
   - If handoff mentions blockers for this skill's scope, warn before proceeding

## Execution Steps

### Step 1: Analyze Acceptance Criteria

For each acceptance criterion:
1. **Understand the requirement**
   - Read AC text carefully
   - Identify what "done" means
   - Note any explicit constraints

2. **Decompose into tasks**
   - What code needs to be written?
   - What tests need to be written?
   - What configuration changes?
   - What documentation?
   - What other work (DB migrations, etc.)?

3. **Categorize by type**
   - Core feature code
   - Test code
   - Configuration
   - Documentation
   - Infrastructure

4. **Estimate complexity**
   - Simple: straightforward, no unknowns
   - Medium: some complexity, minor unknowns
   - Complex: significant work, unknowns

Example analysis:
```
AC-001: User can submit form with valid data

Tasks:
1. Design form component API (complexity: simple)
2. Write form component HTML/markup (complexity: simple)
3. Add form validation logic (complexity: medium)
4. Connect to API endpoint (complexity: medium)
5. Handle submission success/error (complexity: simple)
6. Write tests for validation (complexity: simple)
7. Write tests for API integration (complexity: medium)
8. Write tests for error handling (complexity: simple)
9. Document form API in README (complexity: simple)

Dependencies:
- Depends on API endpoint being ready
- Depends on design approval

Risks:
- API contract may change
- Validation rules may evolve
```

### Step 2: Create Task List

Organize tasks in logical sequence:

1. **Group by phase**
   - Phase 0: Preparation (setup, planning)
   - Phase 1: Core implementation (main code)
   - Phase 2: Testing (test code)
   - Phase 3: Integration (wire-up)
   - Phase 4: Polish (documentation, refactoring)

2. **Order by dependencies**
   - Tasks with no dependencies first
   - Tasks that depend on outputs of previous tasks
   - Identify blocking dependencies

3. **Assign IDs**
   - Use format: TASK-NNN
   - Link to ACs: TASK-001 (AC-001)
   - Track in plan

4. **Estimate effort**
   - Time estimate: 30min, 1h, 2h, 4h, 1d, etc.
   - Add contingency (10-20% for unknowns)
   - Total per phase

Example task breakdown:
```
Phase 1: Core Implementation
- TASK-001 (AC-001): Design form component API - 30min
  Dependencies: Design review

- TASK-002 (AC-001): Build form HTML/markup - 1h
  Dependencies: TASK-001

- TASK-003 (AC-001): Add validation logic - 2h
  Dependencies: TASK-001, specifications defined

- TASK-004 (AC-001): Integration with API - 2h
  Dependencies: TASK-001, API endpoint exists

Phase 2: Testing
- TASK-005 (AC-001): Tests for validation - 1h
  Dependencies: TASK-003

- TASK-006 (AC-001): Tests for API integration - 2h
  Dependencies: TASK-004, test infrastructure

- TASK-007 (AC-001): Tests for error handling - 1h
  Dependencies: TASK-004

Phase 3: Documentation
- TASK-008 (AC-001): Document form API - 30min
  Dependencies: TASK-001, TASK-004
```

### Step 3: Identify Parallelizable Work

Analyze which tasks can run in parallel:

1. **Find independent task chains**
   - Which tasks have no common dependencies?
   - Which can start while others are in progress?

2. **Group by parallelization**
   ```
   Sequential (must run in order):
   - TASK-001 → TASK-002 → TASK-003 → TASK-004

   Can parallelize:
   - TASK-005 (tests) can start after TASK-003
   - TASK-006 (API tests) can start after TASK-004
   - TASK-008 (docs) can start after TASK-001

   Optimal schedule for 2 developers:
   Dev 1: TASK-001 → TASK-002 → TASK-003 → TASK-005
   Dev 2: [wait] → [wait] → TASK-004 → TASK-006 → TASK-008
   ```

3. **Note team size constraints**
   - Solo: Sequential only
   - 2-3 people: Some parallelization
   - Larger team: More parallelization

### Step 4: Risk Assessment

Identify potential risks:

1. **Technical risks**
   - Unknown technologies
   - Complex integrations
   - Performance concerns
   - Browser/platform compatibility

2. **Dependency risks**
   - External system dependencies
   - Third-party API changes
   - Resource constraints

3. **Scope risks**
   - Requirements clarity
   - Feature creep potential
   - Scope boundary issues

4. **Timeline risks**
   - Optimistic estimates
   - Unknown unknowns
   - Rework potential

Example:
```
Risk: Form validation may have complex edge cases
- Probability: Medium (forms often have edge cases)
- Impact: High (affects user experience)
- Mitigation: Plan extra time for edge case testing, get spec clarity early

Risk: API endpoint not ready when form code is done
- Probability: Medium (API may slip)
- Impact: Medium (can mock API for testing)
- Mitigation: Start with mocked API, parallelize API development

Risk: Browser compatibility issues
- Probability: Low (using standard web APIs)
- Impact: Medium (affects supported browsers)
- Mitigation: Test on target browsers early
```

### Step 5: Create Plan Document

Write comprehensive plan to docs/plans/{feature}-plan.md:

```markdown
# Implementation Plan: {Feature Name}

**Spec Version**: {version}
**Created**: {date}
**Team Size**: Solo / 2-3 / {N}
**Estimated Duration**: {X days/weeks}

## Overview

{1-2 sentence summary of what will be built}

## Objectives

- [Objective 1]
- [Objective 2]
- [Objective 3]

## Success Criteria

- All acceptance criteria implemented and tested
- Code coverage >= 80%
- All quality gates passing
- Zero high-priority bugs
- Documentation complete

## Acceptance Criteria Analysis

### AC-001: {description}
- **Complexity**: Medium
- **Effort Estimate**: 5 hours
- **Tasks**:
  - TASK-001: Subtask A
  - TASK-002: Subtask B
  - TASK-003: Subtask C
- **Dependencies**: Design approval, API contract
- **Risks**: [any specific risks]
- **Testing Strategy**: Unit + integration tests

### AC-002: {description}
[... similar analysis]

## Implementation Phases

### Phase 0: Preparation (1 day)
Preparation work before main development starts.

| Task ID | Description | Effort | Dependencies | Owner |
|---------|-------------|--------|--------------|-------|
| TASK-001 | Review spec and get clarification | 2h | Spec complete | Dev 1 |
| TASK-002 | Set up development environment | 2h | - | Dev 1 |
| TASK-003 | Create test fixtures and mocks | 3h | TASK-001 | Dev 2 |

**Phase Duration**: 1 day
**Blockers**: None identified

### Phase 1: Core Implementation (2-3 days)
Main feature development.

| Task ID | Description | Effort | Dependencies | Owner |
|---------|-------------|--------|--------------|-------|
| TASK-004 | Form component structure | 2h | TASK-001 | Dev 1 |
| TASK-005 | Form validation logic | 4h | TASK-004 | Dev 1 |
| TASK-006 | API integration | 3h | TASK-001, API contract | Dev 2 |
| TASK-007 | Error handling | 2h | TASK-005, TASK-006 | Dev 2 |

**Phase Duration**: 3 days (with Dev 1 and Dev 2 parallelization)
**Blockers**: API contract must be finalized

### Phase 2: Testing (1-2 days)
Comprehensive test coverage.

| Task ID | Description | Effort | Dependencies | Owner |
|---------|-------------|--------|--------------|-------|
| TASK-008 | Unit tests for validation | 3h | TASK-005 | Dev 1 |
| TASK-009 | Unit tests for API integration | 3h | TASK-006 | Dev 2 |
| TASK-010 | Integration tests | 4h | TASK-005, TASK-006 | Dev 1 & 2 |
| TASK-011 | Edge case testing | 2h | TASK-010 | Dev 2 |

**Phase Duration**: 2 days
**Blockers**: Implementation must be complete

### Phase 3: Integration & Polish (1 day)
Final touches before merge.

| Task ID | Description | Effort | Dependencies | Owner |
|---------|-------------|--------|--------------|-------|
| TASK-012 | Code review & refactoring | 3h | Phase 2 complete | Dev 1 & 2 |
| TASK-013 | Documentation | 2h | Phase 1 complete | Dev 1 |
| TASK-014 | Final QA | 2h | Phase 3 in progress | Dev 2 |

**Phase Duration**: 1 day

## Effort Summary

| Phase | Estimated Hours | Days (1 dev) | Days (2 devs) |
|-------|-----------------|--------------|---------------|
| Phase 0 | 7 | 1 | 0.5 |
| Phase 1 | 11 | 2 | 1.5 |
| Phase 2 | 12 | 2 | 1.5 |
| Phase 3 | 7 | 1 | 0.5 |
| **Total** | **37** | **6** | **4** |

## Dependencies

### External Dependencies
- API endpoint must be ready by Phase 1
- Design approval by Phase 0

### Internal Dependencies
- No upstream work required
- No blocking existing issues

## Parallelization Strategy

With 2 developers:
```
Day 1:
  Dev 1: TASK-001, TASK-004
  Dev 2: TASK-002, TASK-003

Day 2:
  Dev 1: TASK-005, TASK-008
  Dev 2: TASK-006, TASK-007

Day 3:
  Dev 1: TASK-010 (collaborative)
  Dev 2: TASK-009, TASK-011

Day 4:
  Dev 1 & 2: TASK-012 (collaborative), TASK-013, TASK-014
```

Total estimated time with 2 devs: **4 days**

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| API contract changes | Medium | Medium | Mock API first, plan for changes |
| Edge case bugs | Medium | Medium | Allocate time for edge case testing |
| Rework due to requirements | Low | High | Get spec clarity upfront (TASK-001) |
| Team member unavailable | Low | High | Document decisions, pair program |

## Testing Strategy

1. **Unit Tests** (Phase 2)
   - Validation logic: 100% coverage target
   - API integration: 90% coverage target
   - Error handling: 100% coverage target

2. **Integration Tests** (Phase 2)
   - Form submission flow
   - API error handling
   - Success/error messaging

3. **Manual Testing** (Phase 3)
   - Cross-browser testing (Chrome, Firefox, Safari, Edge)
   - Mobile responsiveness
   - Accessibility checks

4. **Quality Gates** (Phase 3)
   - Coverage >= 80%
   - All tests passing
   - Lint/type checks passing
   - Spec compliance verified

## Deliverables

### Code
- Form component (src/components/Form.tsx)
- Validation module (src/validation.ts)
- API integration (src/api/submit.ts)

### Tests
- Unit tests (tests/validation.test.ts, tests/api.test.ts)
- Integration tests (tests/integration/form-submission.test.ts)

### Documentation
- Component API docs (README.md)
- Test coverage report
- Implementation notes

## Success Metrics

- [ ] All 5 acceptance criteria implemented
- [ ] 32+ tests written and passing
- [ ] Code coverage >= 80%
- [ ] Zero outstanding bugs
- [ ] All quality gates passing
- [ ] Deployment to staging successful
- [ ] All team members understand the code

## Next Steps

1. Get stakeholder approval of this plan
2. Brief team on schedule and dependencies
3. Begin Phase 0: Preparation
4. Track actual time against estimates
5. Adjust plan if blockers arise
6. Daily standup on progress and blockers

## Plan History

- 2025-02-07: Initial plan created
```

## Output Format

Upon completion, output:

```
# Plan Created Successfully ✓

## Feature
{feature-name} v{spec-version}

## Plan Summary
- Total Effort: {hours} hours
- Timeline: {days} days (1 dev) / {days} days (2 devs)
- Phases: 4
- Tasks: {count}
- Parallelizable Tasks: {count}

## Key Metrics
- Average Task Size: {hours}h
- Longest Critical Path: {hours}h
- Estimated Completion: {date}

## Risks Identified
- {risk-count} risks assessed
- Highest: {risk-name}
- Mitigation: [brief summary]

## Plan Location
docs/plans/{feature}-plan.md

## Next Steps
1. Review and approve plan
2. Assign team members to phases
3. Begin Phase 0: Preparation
4. Schedule daily standup
5. Run /add:tdd-cycle to execute plan
```

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner. Create tasks at the start of each major phase and mark them completed as they finish.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Read spec | Reading feature spec | Reading feature spec... |
| Architecture | Analyzing architecture | Analyzing architecture... |
| Tasks | Identifying and breaking down tasks | Identifying tasks... |
| Estimation | Estimating effort and timeline | Estimating effort... |
| Write plan | Writing plan document | Writing plan document... |

Mark each task `in_progress` when starting and `completed` when done. This gives the user real-time visibility into skill execution.

## Error Handling

**Spec is incomplete**
- Halt planning
- Report missing information
- Ask user to complete spec before planning

**Cannot parse acceptance criteria**
- Report which AC is unparseable
- Show the problematic text
- Ask user to reformat AC

**No configuration available**
- Use sensible defaults (team size: solo)
- Report defaults used
- Continue planning

## Integration with Other Skills

- Spec (input) comes from specs/{feature}.md
- Plan (output) guides /add:tdd-cycle execution
- Effort estimates inform scheduling
- Risk assessment informs quality gate thresholds
- Task breakdown guides parallel work dispatch

## Configuration in .add/config.json

```json
{
  "plan": {
    "effortMultiplier": 1.2,
    "contingency": 0.15,
    "teamSize": "solo",
    "phasesEnabled": ["prep", "impl", "test", "polish"]
  }
}
```

## Plan Review Checklist

Before finalizing plan, verify:
- [ ] All ACs are addressed by tasks
- [ ] All tasks have effort estimates
- [ ] Dependencies are clearly marked
- [ ] Parallelization is identified
- [ ] Risks are documented
- [ ] Testing strategy is clear
- [ ] Deliverables are listed
- [ ] Success criteria are measurable

---
autoload: true
---

# ADD Rule: Spec-Driven Development

Agent Driven Development requires specifications before code. This is non-negotiable.

## Document Hierarchy

Every project follows this chain. No link may be skipped.

```
PRD (docs/prd.md)
 → Feature Specs (specs/{feature}.md)
   → Implementation Plans (docs/plans/{feature}-plan.md)
     → User Test Cases (embedded in spec)
       → Automated Tests (RED phase)
         → Implementation (GREEN phase)
```

## PRD Requirements

Before any feature work begins, `docs/prd.md` must exist and contain:

1. **Problem Statement** — What problem are we solving and for whom
2. **Success Metrics** — How we know the project succeeded
3. **Scope** — What's in and what's explicitly out
4. **Technical Constraints** — Stack, environments, deployment targets
5. **Environment Strategy** — Which environments exist and their purpose

If no PRD exists when a feature spec is requested, stop and run the `/init` interview first.

## Spec Requirements

Before any implementation begins, a spec must exist in `specs/` and contain:

1. **Feature Description** — What it does in plain language
2. **User Story** — As [who], I want [what], so that [why]
3. **Acceptance Criteria** — Numbered, testable statements (AC-001, AC-002, etc.)
4. **User Test Cases** — Human-readable test scenarios (TC-001, TC-002, etc.)
5. **Data Model** — Entities, fields, types, relationships
6. **API Contract** — Endpoints, request/response schemas (if applicable)
7. **Edge Cases** — What happens when things go wrong
8. **Screenshot Checkpoints** — What to visually verify in E2E tests

## Plan Requirements

Before coding begins, a plan must exist in `docs/plans/` and contain:

1. **Task Breakdown** — Ordered list of implementation steps
2. **File Changes** — Which files are created, modified, or deleted
3. **Test Strategy** — What types of tests cover this feature
4. **Dependencies** — What must be done first
5. **Spec Traceability** — Each task maps to acceptance criteria

## Enforcement

- NEVER write implementation code without a spec in `specs/`
- NEVER write a spec without a PRD in `docs/prd.md`
- NEVER start coding without a plan in `docs/plans/`
- If asked to "just build it" — create the spec first, then build from it
- Specs ARE the source of truth. If code contradicts the spec, the code is wrong.

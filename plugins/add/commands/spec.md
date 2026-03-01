---
description: "[ADD v0.4.0] Create a feature specification through structured interview"
argument-hint: [feature-name] [--from-prd-section N]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# ADD Spec Command v0.4.0

Create a feature specification through a structured interview. The spec becomes the source of truth for implementation.

## Pre-Flight

1. Verify `docs/prd.md` exists. If not, tell the user to run `/add:init` first.
2. Read `docs/prd.md` to understand the project context
3. Read `.add/config.json` to understand environment and quality settings
4. If `--from-prd-section` is provided, pre-populate answers from that PRD section
5. If `feature-name` argument is provided, use it. Otherwise, ask.

## Phase 1: Feature Interview

Estimate questions upfront. Typical spec interview is 6-10 questions, ~5 minutes.

```
Let's define a specification for this feature.
This will take approximately {N} questions (~5 minutes).

The spec will include acceptance criteria, user test cases,
data models, and everything needed to start TDD.
```

### Core Questions (ask 1-by-1)

**Q1:** "Describe the feature in one or two sentences. What should it do?"
→ Captures: feature description, feature name/slug

**Q2:** "Who uses this feature, and what's their goal?"
→ Captures: user story (As a {role}, I want {what}, so that {why})

**Q3:** "What are the must-have behaviors? List the things that MUST work for this feature to be complete."
→ Captures: acceptance criteria (AC-001, AC-002, etc.)

**Q4:** "Walk me through the happy path — step by step, what does the user do and see?"
→ Captures: primary user test case (TC-001)

**Q5:** "What should happen when things go wrong? Think about invalid input, network errors, missing data."
→ Captures: error handling, edge cases, additional test cases

**Q6:** "What data does this feature need? Think entities, fields, relationships."
(Default: "I'll infer from the acceptance criteria")
→ Captures: data model

**Q7 (if applicable):** "Does this feature need API endpoints? If so, what operations?"
→ Captures: API contract

**Q8 (if UI):** "Describe the key UI states — loading, empty, error, success."
→ Captures: UI behavior, screenshot checkpoints

**Q9:** "Anything else I should know? Dependencies on other features, third-party services, specific libraries?"
(Default: "Nothing additional")
→ Captures: dependencies, notes

## Phase 2: Generate Spec

1. Read `${CLAUDE_PLUGIN_ROOT}/templates/spec.md.template`
2. Fill in ALL sections with substantive content from the interview
3. Generate acceptance criteria with IDs (AC-001 through AC-NNN)
4. Generate user test cases with IDs (TC-001 through TC-NNN)
   - Each test case must have: precondition, steps, expected result, screenshot checkpoint
   - Each test case must have a "Maps to" field (leave as TBD until tests are written)
5. Write to `specs/{feature-slug}.md`

## Phase 3: Verify and Present

Display the spec summary:

```
Spec created: specs/{feature-slug}.md

Acceptance Criteria: {N} ({must} must, {should} should, {nice} nice-to-have)
User Test Cases: {N}
Data Entities: {N}
API Endpoints: {N}

Next steps:
  1. Review the spec and refine if needed
  2. Run /add:plan specs/{feature-slug}.md to create an implementation plan
  3. Or jump straight into /add:tdd-cycle specs/{feature-slug}.md
```

---
autoload: true
description: "Master rule governing all ADD behavior based on project maturity level"
---

# Maturity Lifecycle: The Master Rule

This rule defines how ADD adapts to your project's stage of development. **It takes precedence over all other rules.** When maturity-lifecycle conflicts with another rule, maturity wins.

## Maturity Levels

### POC (Proof of Concept)
A project exploring viability. Time-boxed, high uncertainty, goal is to validate a core idea or remove a critical unknown. Success = learning, not completeness.

### Alpha
Early-stage, building toward an MVP. Core concept validated. Moving toward product-market fit. Scaling up safety incrementally. Success = surviving first real usage.

### Beta
Shipping to broader audiences. Feature-complete for 1.0. Reducing defect density and improving reliability. Focus on stabilization and quality. Success = reliable, predictable product.

### GA (General Availability)
Production-grade, long-term support expected. High stability demands. Change velocity slows. Deep safety protocols. Focus on sustainability and scale. Success = trusted, reliable infrastructure.

---

## Cascade Matrix: Maturity Controls Everything

| Dimension | POC | Alpha | Beta | GA |
|-----------|-----|-------|------|-----|
| **PRD Depth** | Paragraph (problem + hypothesis) | 1-pager (problem, solution, success metrics) | Full template (PRD: goals, specs, roadmap, audience, constraints) | Full template + detailed architecture, scalability model, migration path |
| **Specs Required** | No | Critical paths only (e.g., auth, core loops) | Yes (all user-facing features + acceptance criteria) | Yes + exhaustive acceptance criteria + user test scenarios |
| **TDD Enforced** | Optional (but recommended) | Critical paths mandatory | Yes, strict policy | Strict no exceptions (100% coverage of modified paths) |
| **Quality Gates Active** | Pre-commit lint only | Pre-commit + basic CI (lint, unit tests) | Pre-commit + full CI + pre-deploy QA | All 5 levels: pre-commit, CI, pre-deploy, deploy monitoring, SLA monitoring |
| **Commit Discipline** | Freeform (WIP, experiment ok) | Conventional commits (feat:/fix:/docs:) | Conventional + spec references (#spec-{id}) | Conventional + spec refs + PR mandatory + auto-linked tickets |
| **Reviewer Agent** | Skip (solo agent ok) | Optional (recommended for risky PRs) | Recommended (code review on all changes) | Mandatory (two reviewers, one from stability team) |
| **Environment Tier Ceiling** | Tier 1 (local, dev) | Tier 1-2 (dev, staging) | Tier 2 (staging only, no prod changes) | Tier 2-3 (staging + production, with deploy checks) |
| **Away Mode Autonomy** | Full autonomy (agent decides scope/pace) | High autonomy (agent plans, few checkpoints) | Balanced (plan reviewed, execute autonomous, verify with human) | Guided with checkpoints (human approval at cycle start + completion, daily standups) |
| **Interview Depth** | ~5 questions (fast exploration) | ~8 questions (clarify core assumptions) | ~12 questions (understand user stories deeply) | ~15 questions (exhaustive acceptance criteria validation) |
| **Milestone Docs Required** | No (PRD paragraph enough) | Lightweight (M{N} title, goal, 3 features) | Yes, full template (goal, appetite, hill chart, risks, cycles) | Yes, full template + hill chart tracked daily + risk reassessment per cycle |
| **Cycle Planning** | Informal (ad-hoc batching) | Brief cycle doc (work items + priorities) | Full cycle plan (features, dependencies, parallelism, validation) | Full plan + risk assessment + parallel agent coordination + WIP limits |
| **Features Per Cycle** | 1-2 (rapid iteration) | 2-4 (bounded scope) | 3-6 (balanced execution) | 3-6 with strict WIP limits (ensures quality focus) |
| **Parallel Agents** | 1 serial (one agent at a time) | 1-2 agents (minimal serialization) | 2-4 agents (worktree isolation, file reservations) | 3-5 agents (strict worktree isolation, merge coordination, merge sequence docs) |

---

## Work Hierarchy: Roadmap → Milestones → Cycles → Features → Tasks

The structure that governs all ADD work:

### Roadmap
**Location:** PRD, `## Roadmap` section  
**Framing:** Now / Next / Later (no fake dates, no hard commitments)

Each roadmap entry = milestone placeholder:
- **Name:** M{N} — {SHORT_NAME}
- **Goal:** 1-2 sentences of what "done" looks like
- **Success Criteria:** 3-5 checkboxes (not estimates, completion signals)
- **Target Maturity:** The maturity level this milestone advances toward
- **Effort Appetite:** How much runway we burn (e.g., "2 weeks" not "3 commits")

### Milestones
**Location:** `docs/milestones/M{N}-{name}.md`  
**Ownership:** Human (primary roadmap driver) + agents (execution)

Milestones are the container for related features. Each milestone:
- **Goal & Success Criteria:** Clear definition of done
- **Appetite:** Budget (not estimate) for completing the milestone
- **Hill Chart:** Visual progress map (see below for format)
- **Features:** Linked list with position tracking (SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE)
- **Dependencies:** What must come first from other milestones
- **Risks:** Known challenges with mitigation plans
- **Cycles:** Batches of work (see below)
- **Retrospective:** Filled in at completion — learnings to capture

### Hill Chart Positions
Features move through these positions as they progress:

1. **SHAPED** — Idea is roughed out, knows basic problem/solution, uncertain on scope/approach
2. **SPECCED** — Behavior fully specified, acceptance criteria written, design sketched
3. **PLANNED** — Assigned to a cycle, dependencies mapped, effort estimated
4. **IN_PROGRESS** — Active work, code/tests advancing, open PRs
5. **VERIFIED** — Code complete, tests pass, acceptance criteria checked, QA signed off
6. **DONE** — Merged to main, deployed to ceiling tier, milestone chart updated

**Hill Metaphor:** Uphill = figuring it out (SHAPED → SPECCED). Downhill = executing (PLANNED → DONE).

### Cycles
**Location:** `.add/cycles/cycle-{N}.md`  
**Ownership:** Agents (planning + execution)

A cycle is the next batch of work before human checkpoint. It picks features from the current milestone, assesses dependencies, plans parallelism, and defines validation criteria.

Each cycle:
- **Work Items:** Features + target positions + effort estimates
- **Dependency Graph:** Which items must serialize (blocked by what)
- **Parallel Strategy:** Which items can run simultaneously, file reservations, merge sequence
- **Validation Criteria:** Per-item acceptance, overall cycle success signals
- **Cycle Success Criteria:** What "done" means for this cycle (all items verified, QA passed, etc.)

**Cycle Length:** Varies by maturity:
- POC/Alpha: 1-2 days (rapid iteration, fast checkpoints)
- Beta: 3-5 days (balanced execution, mid-cycle review)
- GA: 5-7 days (deeper testing, slower deliberation)

### Features
**Location:** `specs/{feature}.md`  
**Ownership:** Agents (implementation) + human (acceptance)

Existing ADD concept. Specs define:
- **User Story:** Who, what, why
- **Acceptance Criteria:** Testable conditions (especially important in Beta/GA)
- **Edge Cases:** Known gotchas
- **Test Scenarios:** User test cases (Beta/GA only)

### Tasks
**Location:** TDD cycle execution (inside the feature's test suite)  
**Ownership:** Agents

Existing ADD concept. Tasks emerge from test-first cycles:
- Each failing test = a task to make it pass
- Red → Green → Refactor loop drives discovery

---

## Maturity Promotion: Leveling Up

Moving from one maturity level to the next is **intentional and deliberate.** It's not automatic.

### When to Promote
- **POC → Alpha:** Core idea validated, first users engaged, product is stable enough for feedback
- **Alpha → Beta:** MVP feature-complete, early adopters find it reliable, ready for broader use
- **Beta → GA:** Defect rate below threshold, 30+ days production stability, SLAs defined and met

### Promotion Process
1. Trigger: `/add:cycle --complete` suggests promotion, or `/add:retro` recommends it
2. **Gap Analysis:** Compare project state against target maturity checklist:
   - Are all required docs in place? (PRD, specs, milestones)
   - Are quality gates configured? (CI, pre-deploy, monitoring)
   - Is test coverage sufficient? (% coverage target by maturity)
   - Is team process aligned? (reviewer discipline, cycle discipline)
3. **Promotion Milestone:** Create a special milestone (M{N} — "Maturity → {TARGET}") that captures:
   - Missing pieces from the gap analysis
   - New practices to adopt (e.g., introducing 2-reviewer policy)
   - Runbook changes (escalation paths, on-call setup)
4. **Execution:** Complete the promotion milestone in 1-2 cycles
5. **Update Config:** Write `.add/config.json` maturity field to new level

### Precedent
Promotion milestones are treated like any other milestone: they advance the project toward GA stability.

---

## Reading the Room: Context Awareness

**Before any significant action, agents check `.add/config.json` maturity field.**

Example behavior shifts:

```json
{
  "maturity": "poc"
}
```
→ **Agent mindset:** Move fast, ask forgiveness not permission, skip reviews, TDD is "nice to have"

```json
{
  "maturity": "alpha"
}
```
→ **Agent mindset:** Plan ahead, flag blockers early, TDD on critical paths, expect async review

```json
{
  "maturity": "beta"
}
```
→ **Agent mindset:** Comprehensive specs, full TDD, all PRs reviewed, pre-deploy QA, parallel features OK

```json
{
  "maturity": "ga"
}
```
→ **Agent mindset:** Move deliberately, two reviewers, SLA monitoring, deployment planning, risk assessment per change

### Conflict Resolution
When another rule says one thing and maturity-lifecycle says another, **maturity wins.**

Examples:
- TDD rule says "always write tests first" but maturity is POC → TDD is optional
- Commit discipline rule says "conventional commits required" but maturity is POC → freeform OK
- Parallel agents rule suggests "run 4 agents in parallel" but maturity is Alpha → max 2, avoid serialization

---

## Using This Rule

### For Agents
Every action starts here:
1. Read `.add/config.json` and find maturity level
2. Cross-reference this rule's cascade matrix
3. Adjust behavior: relaxed for POC/Alpha, strict for Beta/GA
4. When in doubt, escalate to human

### For Humans
Every cycle, every milestone, ask:
1. "Are we still at {current maturity}?"
2. "Should we promote based on stability/completeness?"
3. "Should we demote based on new uncertainty/discovery?" (rare but possible)

### For Roadmap Planning
When sketching the roadmap, label each milestone with its target maturity. This clarifies:
- What "done" means (maturity governs completeness bar)
- When humans can step back (maturity governs autonomy)
- What safety protocols engage (maturity governs gates)

**Maturity lifecycle is the single most important rule in ADD.** Everything else cascades from it.

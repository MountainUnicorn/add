# Spec: Session Continuity & Self-Evolution

**Version:** 0.1.0
**Created:** 2026-02-16
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Release:** v0.3.0

## 1. Overview

Field assessment of ADD on a complex, mid-flight project revealed three systemic weaknesses: sessions lose context at boundaries, parallel agents lack a shared communication channel, and the learning system captures facts but doesn't evolve process. This spec addresses all three through async coordination files, maturity-gated rule loading, and a three-tier self-evolution model.

### Problem Statement

1. **Session amnesia** — When sessions end (context limit, crash, user switch), the next session starts cold. 10-20% of context is spent re-discovering what was in progress.
2. **Swarm silence** — Parallel agents working on the same project have no shared state beyond git. No claiming, no status, no handoff.
3. **Rules without enforcement** — 2,062 lines of rules loaded every session regardless of maturity level or operation. Rules that aren't enforced consume context without changing outcomes.
4. **Maturity mismatch** — Projects self-declare maturity aspirationally (beta) while operating at a lower level (alpha). ADD doesn't validate the claim.
5. **Learning captures facts, not process** — Learnings like "pymysql isn't thread-safe" are useful. But process failures (skipping verification, deploying untested code) repeat because they aren't captured as workflow mutations.
6. **Knowledge store drift** — CLAUDE.md, MEMORY.md, and `.add/learnings.md` overlap with no clear ownership, leading to redundancy and staleness.

### User Story

As a developer using ADD across multiple sessions and agents, I want context to survive session boundaries, agents to coordinate through written state, and the system to structurally improve its own workflows based on observed outcomes — so that every session and every cycle is measurably better than the last.

## 2. Acceptance Criteria

### A. Async Coordination Layer

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `.add/handoff.md` is written at session boundaries (context getting long, user departure, explicit handoff). Contains: in-progress work, decisions made, blockers, and next steps. | Must |
| AC-002 | Handoff is current-state (replaced each time), not append-only. One session's handoff replaces the previous. | Must |
| AC-003 | All ADD skills read `.add/handoff.md` at the start of execution if it exists, to pick up where the last session left off. | Must |
| AC-004 | `.add/swarm-state.md` tracks parallel agent coordination. Each agent writes a status block when claiming work (start) and when finishing (result). | Must |
| AC-005 | Swarm state entries include: agent role, timestamp, claimed scope, status (active/complete/blocked), result summary, and handoff notes. | Must |
| AC-006 | `.add/decisions.md` is an append-only log of architectural and process decisions with timestamps and rationale. One line per decision. | Should |
| AC-007 | `/add:back` reads handoff.md, swarm-state.md, and decisions.md to construct the briefing — not just the away log. | Must |
| AC-008 | Session handoff is triggered automatically when context usage exceeds 80%, not only on explicit user request. | Should |

### B. Maturity-Gated Rule Loading

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-009 | Rules declare their minimum maturity level via frontmatter: `maturity: alpha` (or poc/beta/ga). | Must |
| AC-010 | Only rules at or below the project's current maturity level load into the system prompt. Higher-maturity rules remain on disk but are dormant. | Must |
| AC-011 | At `poc` maturity: only `project-structure`, `learning`, and `source-control` rules load (~3 rules). | Must |
| AC-012 | At `alpha` maturity: add `spec-driven` (critical paths only), `quality-gates` (pre-commit only), `human-collaboration`. (~6 rules). | Must |
| AC-013 | At `beta` maturity: add `tdd-enforcement`, `agent-coordination`, `environment-awareness`, `maturity-lifecycle`. (~10 rules). | Must |
| AC-014 | At `ga` maturity: all rules load including `design-system` and full quality cascade. (all rules). | Must |
| AC-015 | Rule loading is documented so users can see which rules are active: `/add:verify` reports "N rules active at {maturity} level." | Should |

### C. Honest Maturity Assessment

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-016 | `/add:init --adopt` (existing project adoption) analyzes actual project behavior: commit patterns, test presence/coverage, branching strategy, spec existence, CI config. | Must |
| AC-017 | Maturity is set based on observed behavior, not aspiration. If there are no specs and no TDD, maturity is `poc` or `alpha` regardless of what the user requests. | Must |
| AC-018 | A maturity gap report is generated showing current state vs. next level requirements, with a concrete remediation path. | Should |
| AC-019 | Maturity promotion requires evidence: `/add:retro` or `/add:cycle --complete` checks promotion criteria against actual project state. | Must |

### D. Self-Evolution Model

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-020 | **Micro-observations:** After every `/add:verify`, `/add:deploy`, `/add:tdd-cycle`, and session handoff, the executing skill appends one structured line to `.add/observations.md`. | Must |
| AC-021 | Observation format: `{timestamp} | {operation} | {what happened} | {cost or benefit}` — one line, no deliberation. Written by the skill as its final step. | Must |
| AC-022 | **Pattern synthesis:** After every 10 observations, or during `/add:retro`, the agent reads observations and identifies recurring patterns (3+ similar observations = pattern). | Must |
| AC-023 | Synthesis produces proposed process mutations: concrete changes to skill execution sequences, not new rules to read. Format: "Proposed: {skill} now {does X} before {Y}. Evidence: {observations}." | Must |
| AC-024 | **Process mutation:** Proposed changes are presented to the human for approval before being applied to skill files or workflow sequences. | Must |
| AC-025 | Approved mutations are applied by modifying the relevant skill's SKILL.md execution steps — embedding the check as a forced sequence, not a standalone rule. | Must |
| AC-026 | Mutation history is tracked in `.add/mutations.md` — what changed, when, why, and what observations triggered it. | Should |
| AC-027 | `/add:retro` now includes a "process health" section that compares recent observations against previous mutations to assess whether changes improved outcomes. | Should |

### E. Agent-to-Agent Retros

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-028 | When a verifier agent detects issues in another agent's work, it writes a structured observation noting the gap — not just the fix, but the process failure. | Must |
| AC-029 | At the end of any multi-agent operation (TDD cycle, parallel work), the orchestrator runs a micro-retro: reads all agent observations from that operation and synthesizes one process insight. | Must |
| AC-030 | Agent-to-agent retro output goes to `.add/observations.md` (same stream as other observations) tagged with `[agent-retro]`. | Must |
| AC-031 | The orchestrator can propose skill-level mutations based on agent-to-agent retro patterns — subject to human approval (AC-024). | Should |

### F. Knowledge Store Consolidation

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-032 | Clear ownership per store: `.add/learnings.md` = domain facts only (framework quirks, API gotchas). `.add/observations.md` = process observations only. `.add/handoff.md` = current session state only. `CLAUDE.md` = project context and architecture only. | Must |
| AC-033 | `/add:retro` includes a dedup step: identify entries that appear in multiple stores and consolidate to the correct one. | Should |
| AC-034 | Stale entry pruning: observations older than 30 days that haven't influenced a synthesis are archived to `.add/archive/`. Learnings older than 90 days without a reference are flagged for review. | Nice |

## 3. User Test Cases

### TC-001: Session continuity across context reset

**Precondition:** Active project with work in progress, session approaching context limit.
**Steps:**
1. Session auto-writes `.add/handoff.md` at 80% context usage
2. User starts a new session
3. New session reads handoff.md and immediately knows: what was in progress, what decisions were made, what's next
**Expected:** Agent resumes work within 2 exchanges, no re-discovery needed.

### TC-002: Parallel agents coordinate via swarm state

**Precondition:** Beta+ maturity, TDD cycle dispatching test-writer and implementer.
**Steps:**
1. Test-writer claims `specs/auth.md` in `.add/swarm-state.md`
2. Test-writer completes, writes result and handoff
3. Implementer reads swarm-state, sees test-writer output, picks up
**Expected:** No conflicting edits, no duplicated work, clear handoff chain.

### TC-003: Self-evolution from observation to mutation

**Precondition:** 3 deployments where verification was skipped, each causing a production issue.
**Steps:**
1. Each deploy appends observation: `deploy | skipped smoke test | cost: Xhr debugging`
2. At retro or 10th observation, agent synthesizes pattern: "3/5 deploys skipped verification"
3. Agent proposes: `/add:deploy` now runs smoke test as blocking step before downstream operations
4. Human approves
5. `/add:deploy` SKILL.md is modified with the forced verification step
**Expected:** Next deploy executes verification automatically. Observation confirms improvement.

### TC-004: Honest maturity on existing project

**Precondition:** Existing project with no specs, no TDD, direct-to-main commits. User runs `/add:init --adopt`.
**Steps:**
1. ADD scans: no `specs/` files, no test framework, no branching, no CI
2. ADD recommends: `poc` or `alpha` maturity
3. User accepts or overrides with justification
4. Only 3-6 rules load based on actual maturity
**Expected:** No "beta with 90% coverage" when zero tests exist. Rules match reality.

### TC-005: Agent-to-agent retro catches process gap

**Precondition:** TDD cycle where implementer introduces a pattern the reviewer flags.
**Steps:**
1. Implementer writes code, records observation
2. Reviewer catches issue, writes observation tagged `[agent-retro]`: "implementer skipped error handling on external API calls"
3. Orchestrator synthesizes: pattern of missing error handling on API boundaries
4. Proposes mutation: implementer SKILL.md adds "verify error handling on all external calls" as checklist step
**Expected:** Future implementer runs include the check. Observations show reduction in reviewer catches.

## 4. Data Model

### `.add/handoff.md`

```markdown
# Session Handoff
**Written:** 2026-02-16 14:30
**Session context:** 78% used

## In Progress
- Implementing auth middleware (specs/auth.md, step 3 of 7)
- Tests written, 4/12 passing

## Decisions Made
- Chose JWT over session cookies (lighter, stateless)
- Using RS256 not HS256 (key rotation support)

## Blockers
- Keycloak JWKS endpoint returns stale keys (need cache-busting)

## Next Steps
1. Fix JWKS cache issue
2. Complete remaining 8 test cases
3. Run /add:verify
```

### `.add/swarm-state.md`

```markdown
# Swarm State

## test-writer (2026-02-16 14:00)
status: complete
claimed: specs/auth.md → tests/auth.test.ts
result: 12 tests written, all RED
handoff: ready for implementer

## implementer (2026-02-16 14:15)
status: active
claimed: tests/auth.test.ts → src/auth/
result: pending
depends-on: test-writer
```

### `.add/observations.md`

```markdown
# Process Observations

2026-02-14 10:30 | deploy | deployed cache code without production verification | cost: 2hr debugging
2026-02-14 16:00 | verify | caught type error pre-push via gate 2 | saved: ~30min
2026-02-15 09:00 | deploy | triggered 7 builds with known synthesis bug | cost: $147 API + 3hr
2026-02-15 14:00 | handoff | new session missing context, spent 15min re-reading code | cost: 15min
2026-02-16 10:00 | tdd-cycle | [agent-retro] implementer skipped error handling on API calls | cost: reviewer rework
```

### `.add/mutations.md`

```markdown
# Process Mutations

## M-001 (2026-02-16, approved)
**Trigger:** 3/5 deploys skipped verification (observations 2026-02-14, 2026-02-15)
**Change:** `/add:deploy` SKILL.md step 3 now requires smoke test pass before downstream operations
**Status:** Applied
**Outcome:** Next 2 deploys verified successfully (observed 2026-02-17, 2026-02-18)
```

## 5. Architecture Notes

### Rule Loading Mechanism

Rules currently auto-load from the `rules/` directory. Maturity-gating requires:
1. Each rule file gets a frontmatter block: `<!-- maturity: alpha -->` (or poc/beta/ga)
2. The plugin loading mechanism filters rules by comparing file maturity to `.add/config.json` maturity
3. If Claude Code's plugin system doesn't support conditional rule loading, alternative: a single `rules/_loader.md` rule that reads config and instructs the agent which rules to apply

### Observation → Synthesis Pipeline

- Observations are append-only, structured, one-line
- Synthesis is triggered by count (every 10) or by `/add:retro`
- Synthesis reads all observations since last synthesis, groups by operation type, identifies patterns (3+ similar = pattern)
- Patterns produce proposed mutations with evidence
- Mutations require human approval before skill files are modified
- Applied mutations are tracked with outcome observations to close the feedback loop

### Knowledge Store Boundaries

**Current stores (v0.3.0):**

| Store | Contents | Lifecycle | Owner |
|-------|----------|-----------|-------|
| `CLAUDE.md` | Project architecture, tech stack, key conventions | Stable, rarely changes | Human + agent during init |
| `.add/learnings.md` | Domain facts — framework quirks, API gotchas, tool-specific knowledge | Grows during development, pruned during retros | Auto-checkpoints + retros |
| `.add/observations.md` | Process data points — what happened, what it cost | Append-only, archived after synthesis | Skills (automatic, final step) |
| `.add/handoff.md` | Current session state — in progress, decisions, next steps | Replaced each session | Auto at 80% context or explicit |
| `.add/swarm-state.md` | Parallel agent claims and results | Active during multi-agent work, cleared between cycles | Agents (start + finish) |
| `.add/decisions.md` | Architectural and process choices with rationale | Append-only, long-lived | Agent at decision points |
| `.add/mutations.md` | Process evolution history — what changed and why | Append-only, permanent record | Retro synthesis + human approval |

### Knowledge Tier Roadmap (4-tier evolution)

The current 3-tier cascade (plugin-global → user-local → project) will expand to 4 tiers. v0.3.0 implements tiers 1-2. Tiers 3-4 are future.

| Tier | Scope | Location | Status |
|------|-------|----------|--------|
| **1. Project** | This project's facts, observations, mutations | `.add/learnings.md`, `.add/observations.md`, `.add/mutations.md` | v0.2.0 (exists) |
| **2. Install** | One user's cross-project wisdom | `~/.claude/add/library.md`, `~/.claude/add/profile.md` | v0.2.0 (exists) |
| **3. Collective** | Team, organization, or group shared learnings | `~/.claude/add/collective/{team-name}/` or remote git repo | Future — v1.0+ |
| **4. Community** | All ADD users — crowd-sourced patterns and process mutations | Curated submission to `knowledge/global.md` or community API | Future — v1.0+ |

**Tier 3 (Collective)** enables teams to share domain learnings, process mutations, and maturity benchmarks within an organization. A team that discovers "always use connection pooling with SeekDB" propagates it to all team projects — not just the one that found it.

**Tier 4 (Community)** enables the entire ADD user base to benefit from crowd-sourced process evolution. A process mutation that improves deploy reliability across 50 projects could be promoted to plugin-global knowledge. This requires curation infrastructure (submission, review, quality scoring) that doesn't exist yet.

Precedence flows downward: project overrides install overrides collective overrides community. More specific always wins.

## 6. Out of Scope

- CI/CD integration for rule enforcement (future — v1.0.0)
- Real-time agent communication (agents communicate via files, not sockets)
- Automated maturity promotion without human approval
- Tier 3 (Collective) and Tier 4 (Community) knowledge sharing (future — v1.0+)

## 7. Open Questions

1. **Can Claude Code plugins conditionally load rules?** If not, the maturity-gating mechanism needs a workaround (single loader rule that reads config).
2. **Context budget for handoff writing.** How many tokens should a handoff document cost? Propose a 50-line cap.
3. **Observation retention policy.** How long before un-synthesized observations are archived? Propose 30 days.
4. **Should mutations auto-revert if observations show regression?** Or is that too much autonomy?

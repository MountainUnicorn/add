# Spec: Telemetry — Per-Skill Reference Sweep (F-013)

**Version:** 0.1.0
**Created:** 2026-04-26
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Release:** v0.9.2
**Milestone:** none (standalone v0.9.x)
**Depends-on:** `specs/telemetry-jsonl.md` (parent contract)
**Coordinates-with:** PR #6 — `references:` frontmatter mechanism for skills

## 1. Overview

ADD v0.9.0 shipped `core/rules/telemetry.md` (auto-loaded) and the
companion JSONL contract in `specs/telemetry-jsonl.md`. The rule defines
the OpenTelemetry GenAI-aligned schema, file location, rotation, and the
**Pre-Flight / Post-Flight Contract** every skill must follow. The rule
is loaded into every session via `autoload: true`, so every skill *can*
read the contract.

What's missing — and what Swarm F deferred at M3 — is the **per-skill
acknowledgement** that participation is intentional. Today the rule
documents the contract but no `core/skills/*/SKILL.md` declares "this
skill emits telemetry per `core/rules/telemetry.md`". The rule's own
body says it plainly:

> Every ADD SKILL.md should reference this rule in its pre-flight block
> (implicit via autoload today; explicit `@reference core/rules/telemetry.md`
> sweep is a deferred post-M3 follow-up).

That deferred follow-up is this spec.

### Deferral Rationale (why now)

Swarm F deferred the per-skill sweep during M3 because every Wave-2 and
Wave-3 swarm was modifying SKILL.md files (cache-discipline audited four
skills, test-deletion-guardrail edited tdd-cycle/verify, agents-md-sync
touched init/spec/verify). A 27-file mass-append during M3 would have
collided with every parallel branch and produced a merge-conflict
storm. With M3 now merged, the file-set is quiet and a mechanical sweep
is safe.

### Cross-cutting nature

Touching all 27 SKILL.md files is a cross-cutting change. The design is
cheap (one frontmatter key or one prose line per file); the audit
discipline is the work — every skill must be inspected, status recorded,
and the change verified by a fixture test that fails when a future skill
ships without the reference.

### User Story

As an ADD methodology owner, I want every skill to declare its
participation in the telemetry contract, so that (a) the contract is
discoverable from any individual SKILL.md, (b) compile-time validation
can detect a future skill that ships without telemetry participation,
and (c) the dashboard's Cost & Velocity panel can trust that 100% of
skill invocations emit a JSONL line.

## 2. Design Choice — Reference Mechanism

Three options exist for declaring telemetry participation:

| Option | Mechanism | Pros | Cons |
|--------|-----------|------|------|
| (a) | `references: [rules/telemetry.md]` in SKILL.md frontmatter (PR #6 mechanism) | Structured, machine-readable, validated by frontmatter validator, no body churn | Hard dependency on PR #6 landing |
| (b) | Body-prose `@reference core/rules/telemetry.md` line in pre-flight | Zero dependency, works today, matches existing prose conventions | Not machine-validated beyond grep; cosmetic noise per file |
| (c) | Compile-time auto-injection (every skill auto-gets the line) | Zero per-file edit | Magic — invisible to skill authors, hides the contract, contradicts ADD's "source is canonical" ethos |

**Recommendation: (a) when PR #6 lands; (b) as a hard fallback if PR #6
slips beyond v0.9.2.** Option (c) is rejected — too magic for a
methodology plugin where every contract should be readable in the source
file an author edits. ADD's value proposition is that the markdown *is*
the system; auto-injection would erode that.

The acceptance criteria below mandate one path or the other; the
implementation plan picks the path live based on PR #6 status at start.

### Path-A criteria (PR #6 has merged)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001a | Every `core/skills/*/SKILL.md` adds `references: [rules/telemetry.md]` to its YAML frontmatter | Must |
| AC-002a | `scripts/validate-frontmatter.py` recognises the key (PR #6 contract) and validates the path resolves to an existing rule | Must |
| AC-003a | `references:` accepts a list — adding telemetry does not displace any future entries | Must |

### Path-B criteria (PR #6 has NOT merged by start of v0.9.2)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001b | Every `core/skills/*/SKILL.md` includes a single line `@reference core/rules/telemetry.md` inside its `## Pre-Flight` section (or the equivalent first-numbered-list pre-flight block) | Must |
| AC-002b | The line is the first or last bullet of the pre-flight list, consistently positioned across all skills | Must |
| AC-003b | A future migration to (a) is mechanical — when PR #6 lands, a follow-up commit replaces the prose line with the frontmatter key | Should |

## 3. Acceptance Criteria (path-independent)

### A. Coverage

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-010 | Every skill in `core/skills/*/SKILL.md` (all 27) declares the telemetry reference via the chosen mechanism | Must |
| AC-011 | Skills that already emit telemetry implicitly via autoload are still edited — there is no implicit-emission shortcut. Every skill is explicit. | Must |
| AC-012 | The audit checklist in spec § 7 enumerates all 27 skills with status: `swept`, `skipped (with reason)` | Must |
| AC-013 | No skill is skipped without a documented reason in the checklist | Must |

### B. Behaviour

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-014 | The declaration causes the skill's pre-flight to emit a JSONL line in the format defined by `core/rules/telemetry.md` | Must |
| AC-015 | No skill behavior changes beyond the telemetry emission — no AC reordering, no prose rewrites, no allowed-tools changes | Must |
| AC-016 | The reviewer (`/add:reviewer`) sub-agent receives the same telemetry contract via inheritance from the dispatching skill — emission is single, not double | Must |
| AC-017 | Nested skill invocations emit `gen_ai.operation.name = "skill_invocation.nested"` per the parent contract; double-emission of the outer skill is forbidden | Must |

### C. Verification

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-020 | New fixture test `tests/telemetry-sweep/test-skill-reference-coverage.sh` asserts every `core/skills/*/SKILL.md` has the chosen reference declaration | Must |
| AC-021 | Test fails (exit 1) if any new skill is added to `core/skills/` without the reference | Must |
| AC-022 | Test runs in under 2 seconds on a developer laptop (fixture-style, no model calls) | Should |
| AC-023 | `python3 scripts/compile.py --check` remains clean after the sweep — generated `plugins/add/` and `dist/codex/` regenerate deterministically | Must |
| AC-024 | `python3 scripts/validate-frontmatter.py` passes for all 27 SKILL.md files | Must |

### D. Opt-Out

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-030 | Project-level opt-out remains controlled by `.add/config.json:telemetry.enabled = false` (already defined by parent spec, AC-019) | Must |
| AC-031 | This sweep does not introduce a per-skill opt-out flag — telemetry participation is universal at the methodology level; project-level opt-out covers the use case | Must |
| AC-032 | When `telemetry.enabled = false`, the reference is still present in the SKILL.md (declarative correctness) but the runtime emits nothing — consistent with parent spec AC-019 | Must |

## 4. User Test Cases

### TC-001: Every skill asserts the reference

**Precondition:** Sweep has been applied to all 27 skills via the chosen path.
**Steps:**
1. Run `bash tests/telemetry-sweep/test-skill-reference-coverage.sh`
2. Test enumerates `core/skills/*/SKILL.md`
3. Test asserts the chosen declaration is present in each file
**Expected Result:** All 27 assertions pass. Exit code 0.
**Maps to:** TBD

### TC-002: Compile output reflects the reference

**Precondition:** Sweep applied. Repo state clean.
**Steps:**
1. `python3 scripts/compile.py`
2. `python3 scripts/compile.py --check`
3. Inspect a sample compiled output (`plugins/add/skills/spec/SKILL.md`) for the reference
**Expected Result:** `--check` returns 0 (no drift). Compiled SKILL.md includes the declaration verbatim (path-A: frontmatter key; path-B: prose line). Codex `dist/` mirrors.
**Maps to:** TBD

### TC-003: Running a skill emits a JSONL line

**Precondition:** A clean ADD-managed test project with `telemetry.enabled = true`. Today is 2026-MM-DD.
**Steps:**
1. Agent runs `/add:plan specs/example.md`
2. Skill completes (success or fail)
3. Inspect `.add/telemetry/2026-MM-DD.jsonl`
**Expected Result:** Exactly one line appended for this invocation. JSON parses. `skill: "plan"`. `outcome` ∈ {success, failed, aborted, partial}. The line is produced because the SKILL.md's reference declaration triggered pre-flight + post-flight emission per `core/rules/telemetry.md`.
**Maps to:** TBD

### TC-004: Sub-agent dispatch does not double-emit

**Precondition:** `/add:tdd-cycle specs/foo.md` dispatches `/add:reviewer` as a sub-agent.
**Steps:**
1. tdd-cycle starts; pre-flight captures state
2. tdd-cycle dispatches reviewer via Task tool
3. reviewer runs to completion
4. Reviewer post-flight emits one line with `gen_ai.operation.name = "skill_invocation.nested"` and the same `session_id`
5. tdd-cycle post-flight emits one line with `gen_ai.operation.name = "skill_invocation"`
6. Inspect today's JSONL file
**Expected Result:** Exactly two lines for this invocation pair: one outer, one nested. Same `session_id`. No third line. No skill double-emits its own outcome.
**Maps to:** TBD

### TC-005: Project-level opt-out

**Precondition:** Test project has `.add/config.json:telemetry.enabled = false`.
**Steps:**
1. Agent runs any swept skill
2. Skill completes
3. Inspect `.add/telemetry/`
**Expected Result:** Directory is not created. No JSONL written. Skill behavior is otherwise identical. Confirms AC-030, AC-032 — the reference declaration is still present in the SKILL.md (declarative), but runtime is silent because the rule honours the config.
**Maps to:** TBD

## 5. Data Model

None beyond what `specs/telemetry-jsonl.md` already defines. This sweep
adds **no new fields** to the JSONL schema and **no new config keys** to
`.add/config.json`. It is a methodology-level change that makes the
existing contract explicit at every skill site.

## 6. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Skill fails before reaching post-flight | Parent-spec AC-017 already requires emission with `outcome: "failed"`; the reference declaration carries that same contract |
| Skill aborted by user mid-flight | Emit `outcome: "aborted"`; same guarantee as above |
| Very-fast skill (e.g. `/add:back`, sub-100ms) | Still emits one line. `duration_ms` is small but accurate. No floor on emission |
| Reviewer sub-agent runs as a Task dispatch | Reviewer's own SKILL.md carries the reference; reviewer emits its own nested line. The dispatching skill emits its own outer line. Two lines total, same `session_id` |
| Skill that only documents (e.g. `/add:learnings show`) | Still swept — every skill gets the reference. Read-only skills emit a line with `tool_calls` reflecting only Read calls |
| Future skill added to `core/skills/` | Fixture test (AC-020) fails until the new skill carries the reference. CI gate prevents drift |
| Path-A chosen but PR #6's `references:` value list contains a non-existent path | PR #6's frontmatter validator already rejects this; not in scope here |
| Path-B chosen, then PR #6 lands later | Migration is mechanical: replace the body-prose line with the frontmatter key. No spec amendment needed; treat as a chore commit |
| Skill body has multiple `## Pre-Flight` sections (none today, but possible) | Place the reference in the first section. Validator confirms presence anywhere in the file when path-B; presence in frontmatter when path-A |
| Compile-drift CI flags newline differences after sweep | Run `python3 scripts/compile.py` after the SKILL.md edits, commit the regenerated `plugins/add/` and `dist/codex/` in the same change |

## 7. Skill Audit Checklist

Populated during implementation. Status values:

- `swept` — reference declaration added.
- `skipped (reason)` — explicitly excluded with documented rationale.

| # | Skill | Status | Notes |
|---|-------|--------|-------|
| 1 | agents-md | pending | |
| 2 | away | pending | |
| 3 | back | pending | |
| 4 | brand | pending | |
| 5 | brand-update | pending | |
| 6 | changelog | pending | |
| 7 | cycle | pending | |
| 8 | dashboard | pending | dashboard READS telemetry; still emits its own invocation line per parent AC-004 (telemetry never read INTO context — but the dashboard skill itself running is a skill invocation that emits) |
| 9 | deploy | pending | |
| 10 | docs | pending | |
| 11 | implementer | pending | sub-agent only; emits nested line |
| 12 | infographic | pending | |
| 13 | init | pending | bootstrap skill — runs in projects that do not yet have `.add/`; rule honours that case (no directory until first emission) |
| 14 | learnings | pending | `learnings archive` triggers retention pruning of telemetry per parent AC-028 — still emits its own line |
| 15 | milestone | pending | |
| 16 | optimize | pending | |
| 17 | plan | pending | |
| 18 | promote | pending | |
| 19 | retro | pending | |
| 20 | reviewer | pending | sub-agent only; emits nested line; AC-016 forbids double-emit by parent |
| 21 | roadmap | pending | |
| 22 | spec | pending | |
| 23 | tdd-cycle | pending | dispatches multiple sub-agents; outer line + N nested lines |
| 24 | test-writer | pending | sub-agent only; emits nested line |
| 25 | ux | pending | |
| 26 | verify | pending | sub-agent only when invoked from tdd-cycle; emits nested. Top-level `/add:verify` emits outer |
| 27 | version | pending | |

All 27 accounted for. None skipped at draft time.

## 8. Non-Goals

- Re-defining the JSONL schema. Schema lives in `specs/telemetry-jsonl.md`; this sweep is purely declarative.
- Adding new fields to the schema (e.g. no new "reference_source" field).
- Shipping a runtime emitter. The rule is the contract; skills follow it. No code is added.
- Modifying `core/rules/telemetry.md`. The rule already documents the deferred sweep — no rule edits needed beyond removing that "deferred" parenthetical once the sweep ships.
- Per-skill opt-out flags. Project-level `.add/config.json:telemetry.enabled` covers the use case.
- Touching `plugins/add/**` or `dist/codex/**` directly — generated.
- Backfilling historical telemetry. Sweep is forward-looking only.

## 9. Open Questions

| Question | Recommendation |
|----------|---------------|
| Final design choice (a/b/c) | (a) if PR #6 has merged at v0.9.2 cut; (b) as a hard fallback. (c) rejected as too magic. Resolved at implementation start. |
| Opt-out flag location | `.add/config.json:telemetry.enabled` already exists and already gates emission. No new opt-out is added. |
| Reviewer-emission semantics | Reviewer (and any sub-agent) emits exactly one nested line per invocation; the dispatching skill emits one outer line. Same `session_id`. AC-016 + AC-017 + parent AC-011 are the contract. |
| Should `core/rules/telemetry.md` be edited to remove the "deferred" parenthetical? | Yes — a one-line edit at the end of this sweep, in the same commit that closes the deferral. Strictly out-of-scope of "no rule edits" since it is removing dead-letter prose, not changing the contract. |
| Migration path A→B if PR #6 reverts post-merge | Mechanical reverse of the same sweep. Spec does not need re-issue; treat as a chore. |

## 10. Dependencies

- `specs/telemetry-jsonl.md` — parent contract; defines schema, rotation, opt-out, concurrent-write semantics.
- `specs/cache-discipline.md` — provides the precedent audit pattern (§ 4 audit checklist of all skills) this spec mimics.
- `core/rules/telemetry.md` — the rule whose reference is being declared. Authored in v0.9.0; no changes required beyond optional deferred-parenthetical cleanup.
- **Optional:** PR #6 (`references:` frontmatter mechanism) — preferred path-A enabler. If unmerged, fall back to path-B.
- `scripts/validate-frontmatter.py` — must accept the new key when path-A. PR #6 owns this.
- `scripts/compile.py` — must propagate the declaration verbatim into `plugins/add/` and `dist/codex/`. No changes expected — frontmatter and body prose pass through.

## 11. Infrastructure Prerequisites

| Category | Requirement |
|----------|-------------|
| Environment variables | N/A |
| Registry images | N/A |
| Cloud quotas | N/A |
| Network reachability | N/A |
| CI status | `compile.py --check`, `validate-frontmatter.py`, `tests/hooks/test-filter-learnings.sh`, and the new `tests/telemetry-sweep/test-skill-reference-coverage.sh` must all pass |
| External secrets | N/A |
| Database migrations | N/A |

**Verification before implementation:** Confirm PR #6 status. If merged,
proceed path-A. If not, proceed path-B and document the migration commit
that will follow PR #6 merger.

## 12. Sizing

**Small.** The design is the work; the edits are formulaic.

- 27 SKILL.md files × one-line edit each = ~27 lines of net change
- One new fixture test (~50 lines of bash)
- One audit-checklist update in this spec (~27 rows promoted from `pending` → `swept`)
- One regenerated `plugins/add/` + `dist/codex/` pair via compile

Estimate: 0.5–1 day. Bulk-editable via parallel sub-agent dispatch (3
agents × 9 skills each) or a single mechanical pass.

## 13. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-26 | 0.1.0 | abrooke + Claude | Initial spec — closes Swarm F's M3-deferred per-skill reference sweep; articulates path-A (PR #6) and path-B (fallback) |

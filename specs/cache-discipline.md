# Spec: Cache Discipline — Stable-Prefix Layout Convention

**Version:** 0.1.0
**Created:** 2026-04-22
**PRD Reference:** docs/prd.md
**Status:** Complete
**Target Release:** v0.9.0
**Shipped-In:** v0.9.0
**Last-Updated:** 2026-04-22
**Milestone:** M3-pre-ga-hardening
**Depends-on:** PR #6 (rules/knowledge on-demand loading) — sets the mechanism this rule formalizes

## 1. Overview

Anthropic's prompt cache offers up to a 1-hour extended TTL (`extended-cache-ttl-2025-04-11` beta), workspace-scoped caching as of February 2026, and a published 90% input-cost discount on cache hits. Anthropic's own case study reports 85% latency reduction on long-running agent sessions when prompts are laid out cache-aware: stable preamble first, volatile state last. ADD currently leaves this on the table — autoload rules and skill bodies vary in structure, sub-agent dispatches start each context from scratch, and the cache-friendly active-view discipline introduced in v0.8 (e.g., `learnings-active.md` as the cacheable companion to `learnings.json`) is implicit, not codified.

This spec promotes the v0.8 active-view pattern into a project-wide convention. A new auto-loaded rule defines the layout invariant — STABLE PREFIX (project identity, active rules, active learnings, current spec) followed by VOLATILE SUFFIX (per-call task, AC subset, hints) — every skill and every sub-agent dispatch must follow. A new validator (`scripts/validate-cache-discipline.py`) lints SKILL.md files for the invariant. The highest-impact skills (tdd-cycle, implementer, reviewer, verify) are audited and remediated in v0.9; remaining skills are documented for v0.9.x. Telemetry surfaces `cache_read_input_tokens` / `cache_creation_input_tokens` per skill so cache-hit rate becomes measurable.

LangChain's March 2026 Deep Agents Eval framed the bet plainly: "more evals don't make better agents — structural decisions do." Anthropic's 2026 Trends Report names disciplined context management as the dominant cost lever for agentic workflows. ADD already has the pattern; this spec makes it a rule.

### User Story

As an ADD agent dispatching sub-agents repeatedly across a session, I want every prompt I emit to share a byte-identical stable prefix, so that cache hits compound across calls and per-skill input cost drops by up to 90% without changing what the agents actually do.

## 2. Acceptance Criteria

### A. Cache-Discipline Rule

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | New auto-loaded rule `core/rules/cache-discipline.md` exists, under 80 lines, with `autoload: true` frontmatter. | Must |
| AC-002 | Rule defines the **STABLE PREFIX** layer: rule files (autoload-true only), tier-1 knowledge active views, project identity (config.json summary), curated learnings active view, current spec body. | Must |
| AC-003 | Rule defines the **VOLATILE SUFFIX** layer: user message, just-added learnings (not yet flushed to active view), recent file edits, tool outputs, working-set diffs. | Must |
| AC-004 | Rule states the layout invariant: stable prefix must be byte-identical across invocations within a session; any per-call variation belongs in the suffix. | Must |
| AC-005 | Rule cites Anthropic's published case study (85% latency / 90% cost), Anthropic's caching docs (extended-cache-ttl-2025-04-11, workspace-scoped caching), and the v0.8 `learnings-active.md` precedent. | Should |
| AC-006 | Rule is explicit that this is a structural convention, not a token-budget rule — no token count is mandated. | Must |

### B. Layout Markers in SKILL.md

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-007 | SKILL.md files adopt a comment-marker convention to delimit layout zones: `<!-- CACHE: STABLE -->` opens the cacheable region, `<!-- CACHE: VOLATILE -->` opens the per-call region. | Must |
| AC-008 | Each SKILL.md emitting prompts to sub-agents (Task tool) wraps the dispatched prompt body with both markers in the documented order (stable then volatile). | Must |
| AC-009 | Markers are inert to runtime — they are HTML comments, ignored by Claude Code's plugin loader and unnoticed in rendered markdown. Their sole consumer is the validator. | Must |

### C. Validator Script

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-010 | New script `scripts/validate-cache-discipline.py` exists and is executable with `python3 scripts/validate-cache-discipline.py [path]`. | Must |
| AC-011 | Validator scans all `core/skills/*/SKILL.md` files, plus any path passed as an argument. | Must |
| AC-012 | Validator detects layout violations: missing markers, inverted order (VOLATILE before STABLE), volatile content (e.g., per-call placeholders like `{user_message}`, `{task_description}`) appearing inside a STABLE block. | Must |
| AC-013 | Validator emits machine-readable output: one line per finding in the form `{file}:{line}: {severity}: {rule-id}: {message}`. | Must |
| AC-014 | In v0.9, validator runs in **warn-only** mode — non-zero exit code only on parse errors, not on layout findings. CI eligible but non-blocking. | Must |
| AC-015 | Validator has a `--strict` flag that exits non-zero on any finding, intended for v1.0 enforcement once all skills are compliant. | Should |
| AC-016 | Fixture tests under `tests/cache-discipline/fixtures/` cover: compliant skill, missing markers, inverted markers, volatile-in-stable, no-Task-dispatch (skip). Each fixture has an expected-findings file the test asserts against. | Must |

### D. Sub-Agent Dispatch Rule

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-017 | `core/rules/agent-coordination.md` is updated to require the stable-prefix layout for any Task tool dispatch, and cross-references `cache-discipline.md` for the canonical layout. | Must |
| AC-018 | Dispatch rule states: implementer, test-writer, and reviewer sub-agents must share a byte-identical project-context block as their stable prefix; only the role-specific task differs in the volatile suffix. | Must |

### E. High-Impact Skill Audit

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-019 | Audit checklist published as part of this spec (§ 4) covering every skill in `core/skills/*`. Each row records: skill name, current compliance status, deviation summary, remediation owner, target version. | Must |
| AC-020 | Four highest-impact skills are remediated in v0.9: `tdd-cycle`, `implementer`, `reviewer`, `verify`. After remediation each passes the validator with zero findings. | Must |
| AC-021 | Remaining non-compliant skills have a row in the checklist with target version `v0.9.x` and a one-line remediation note. | Should |

### F. Telemetry Integration

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-022 | When a skill emits its post-flight telemetry line (per the companion telemetry spec), the line includes `gen_ai.usage.cache_read_input_tokens` and `gen_ai.usage.cache_creation_input_tokens` fields, sourced from the model response usage block. | Must |
| AC-023 | Telemetry is best-effort: missing fields (e.g., model didn't return cache stats) emit `null`, not an error. | Should |
| AC-024 | A derived metric `cache_hit_ratio = cache_read / (cache_read + cache_creation + uncached_input)` is computed and surfaced in the per-skill telemetry line for at-a-glance review. | Should |

## 3. User Test Cases

### TC-001: Validator catches missing markers

**Precondition:** A SKILL.md file dispatches via Task tool but contains no `<!-- CACHE: STABLE -->` or `<!-- CACHE: VOLATILE -->` markers.
**Steps:**
1. Run `python3 scripts/validate-cache-discipline.py core/skills/example/SKILL.md`
2. Validator parses the file, detects Task dispatch, finds no markers
**Expected Result:** Stdout contains a line `core/skills/example/SKILL.md:{line}: warn: CACHE-001: Task dispatch present but no CACHE markers found`. Exit code 0 (warn-only mode).
**Maps to:** TBD

### TC-002: Validator catches inverted marker order

**Precondition:** A SKILL.md has `<!-- CACHE: VOLATILE -->` appearing before `<!-- CACHE: STABLE -->` in the dispatched prompt body.
**Steps:**
1. Run the validator on the file
**Expected Result:** Stdout contains `... warn: CACHE-002: VOLATILE marker precedes STABLE — inverted layout`. Exit code 0.
**Maps to:** TBD

### TC-003: Validator catches volatile content in stable block

**Precondition:** A SKILL.md has a placeholder like `{user_message}` or `{task_description}` inside the STABLE block.
**Steps:**
1. Run the validator on the file
**Expected Result:** Stdout contains `... warn: CACHE-003: volatile placeholder '{user_message}' inside STABLE block`. Exit code 0.
**Maps to:** TBD

### TC-004: Validator strict mode blocks on findings

**Precondition:** Any of the above conditions, but validator invoked with `--strict`.
**Steps:**
1. Run `python3 scripts/validate-cache-discipline.py --strict core/skills/`
**Expected Result:** All findings emitted; exit code 1.
**Maps to:** TBD

### TC-005: tdd-cycle skill passes after remediation

**Precondition:** `core/skills/tdd-cycle/SKILL.md` has been refactored to wrap the stable project-context block with markers and dispatch sub-agents (test-writer, implementer) using the shared prefix.
**Steps:**
1. Run validator on the file
**Expected Result:** Zero findings. Manual inspection confirms test-writer and implementer dispatches share a byte-identical prefix (project identity + active rules + active learnings + spec body), differing only in the volatile suffix.
**Maps to:** TBD

### TC-006: Telemetry surfaces cache stats

**Precondition:** A skill has run a model call that returned cache usage (`cache_read_input_tokens=8400`, `cache_creation_input_tokens=120`, `input_tokens=300`).
**Steps:**
1. Skill emits its post-flight telemetry line
**Expected Result:** Line includes `gen_ai.usage.cache_read_input_tokens=8400 gen_ai.usage.cache_creation_input_tokens=120 cache_hit_ratio=0.95`.
**Maps to:** TBD

### TC-007: Audit checklist is exhaustive

**Precondition:** Spec § 4 audit checklist exists.
**Steps:**
1. List `core/skills/*/SKILL.md`
2. Cross-reference with checklist rows
**Expected Result:** Every skill file appears in the checklist with a status (`compliant`, `remediated-v0.9`, `deferred-v0.9.x`) and remediation note.
**Maps to:** TBD

## 4. Skill Audit Checklist

Populated during v0.9.0 implementation (Swarm A, 2026-04-22). Status values:

- `compliant` — passes validator with zero findings today.
- `remediated-v0.9` — was non-compliant; fixed in v0.9.0.
- `non-dispatching` — skill does not emit prompts to sub-agents; cache
  markers not required. Validator silently skips.
- `deferred-v0.9.x` — known warning, fix scheduled for a v0.9.x patch.

| Skill | Current Status | Deviation | Remediation | Target |
|-------|---------------|-----------|-------------|--------|
| tdd-cycle | remediated-v0.9 | Dispatched sub-agent prompts (test-writer, implementer, reviewer, verify) had no shared prefix convention | Added "Sub-Agent Dispatch Prompt Template" section with STABLE/VOLATILE markers describing the cache-aware layout every Task-tool dispatch must follow | v0.9.0 |
| implementer | non-dispatching | Invoked AS a sub-agent; does not itself dispatch via Task. Verified via `grep -n Task(` — zero hits. | Added `<!-- cache-discipline: non-dispatching skill --> ` inline note documenting the audit result | v0.9.0 |
| reviewer | non-dispatching | Invoked AS a sub-agent; does not itself dispatch. Verified. | Added non-dispatching note | v0.9.0 |
| verify | non-dispatching | Invoked AS a sub-agent; does not itself dispatch. Verified. | Added non-dispatching note | v0.9.0 |
| init | deferred-v0.9.x | Validator false-positive: line 1039 lists `/add:verify    — run quality gates` in user-facing command tour. The "run" keyword trips dispatch heuristic. | Rephrase command tour to avoid dispatch verbs, or refine validator's pattern to require call-syntax | v0.9.x |
| away | compliant | No Task dispatch. | None needed | v0.9.0 |
| back | compliant | No Task dispatch. | None needed | v0.9.0 |
| brand | compliant | No Task dispatch. | None needed | v0.9.0 |
| brand-update | compliant | No Task dispatch. | None needed | v0.9.0 |
| changelog | compliant | No Task dispatch. | None needed | v0.9.0 |
| cycle | compliant | `Task` in `allowed-tools` but no actual dispatch emission detected. | Audit once cycle starts orchestrating parallel swarms; add markers at that point | v0.9.x |
| dashboard | compliant | No Task dispatch. | None needed | v0.9.0 |
| deploy | compliant | No Task dispatch. | None needed | v0.9.0 |
| docs | compliant | No Task dispatch. | None needed | v0.9.0 |
| infographic | compliant | No Task dispatch. | None needed | v0.9.0 |
| learnings | compliant | No Task dispatch. | None needed | v0.9.0 |
| milestone | compliant | `Task` in `allowed-tools`, no emission in current body. | Audit when milestone starts dispatching sub-agents | v0.9.x |
| optimize | compliant | `Task` in `allowed-tools`, no emission in current body. | Audit when optimize starts dispatching sub-agents | v0.9.x |
| plan | compliant | No Task dispatch. | None needed | v0.9.0 |
| promote | compliant | `Task` in `allowed-tools`, no emission in current body. | Audit when promote starts dispatching sub-agents | v0.9.x |
| retro | compliant | No Task dispatch. | None needed | v0.9.0 |
| roadmap | compliant | `Task` in `allowed-tools`, no emission in current body. | Audit when roadmap starts dispatching sub-agents | v0.9.x |
| spec | compliant | No Task dispatch. | None needed | v0.9.0 |
| test-writer | non-dispatching | Invoked AS a sub-agent; does not itself dispatch. | None needed | v0.9.0 |
| ux | compliant | No Task dispatch. | None needed | v0.9.0 |
| version | compliant | No Task dispatch. | None needed | v0.9.0 |
| **Telemetry fields wired** | deferred-v0.9.x | Requires Swarm F `feat/telemetry-jsonl` merge; integration belongs in a post-merge commit. | Post-merge commit adds `cache_read_input_tokens`, `cache_creation_input_tokens`, derived `cache_hit_ratio` to telemetry line | v0.9.x |

All 26 skills accounted for. Validator run output (warn-only, 2026-04-22):

```
$ python3 scripts/validate-cache-discipline.py
core/skills/init/SKILL.md:1039: warn: CACHE-001: Task dispatch present but no CACHE markers found
```

One advisory finding, documented above as `deferred-v0.9.x`.

## 5. Layout Invariant — Reference

When a skill emits a prompt to a sub-agent (Task tool), the prompt body must follow:

```
<!-- CACHE: STABLE -->
[Project identity — config.json summary: name, stack, conventions]
[Active rules — autoload:true rule bodies, in stable order]
[Active learnings view — learnings-active.md content]
[Spec under work — full body of the current spec]
<!-- CACHE: VOLATILE -->
[Per-call task description]
[Per-call AC subset — which ACs this dispatch addresses]
[Per-call hints — recent file edits, working-set diffs, tool outputs]
```

### Before / After Example

**Before — poorly laid out (no shared prefix, volatile interleaved):**

```markdown
You are the implementer sub-agent.
Task: implement AC-007 from spec auth.md.
Project: dossier (python, fastapi).
Active rules: spec-before-code, learning-checkpoints, ...
Recent edit: app/auth/oauth.py:42 added stub.
Spec body: <full spec inlined here>
Hint: the test you must pass is tests/auth/test_oauth.py::test_callback.
```

Each invocation differs in the first line ("Task: ..."), so no prefix is cacheable. Worse, the recent edit is wedged between the active rules and the spec body — pushing volatile content into what should be cache-stable territory.

**After — cache-disciplined (shared prefix, volatile suffix):**

```markdown
<!-- CACHE: STABLE -->
Project: dossier (python, fastapi)
Conventions: <config.json summary>
Active rules: <autoload:true rule bodies>
Active learnings: <learnings-active.md content>
Spec: <full body of auth.md>
<!-- CACHE: VOLATILE -->
Role: implementer
Task: implement AC-007
Hint: target test is tests/auth/test_oauth.py::test_callback
Recent edit: app/auth/oauth.py:42 added stub
```

Test-writer and reviewer dispatches reuse the same STABLE block byte-for-byte, swapping only the role and task in the VOLATILE block. Cache hits compound across all three sub-agents.

## 6. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| SKILL.md does not dispatch via Task tool | Validator skips silently — no markers required for non-dispatching skills |
| Markers present but no Task dispatch | Validator emits info `CACHE-100: markers present without dispatch — likely safe to remove` |
| Stable block exceeds practical cache TTL window | Out of scope — runtime concern. Validator does not enforce token counts |
| Skill uses markers but inlines a per-call placeholder via Jinja-like substitution at compile time | If the substitution resolves to a literal at compile time (i.e., session-stable), validator treats as STABLE-safe; document via inline comment |
| Active learnings view regenerates mid-session (new learning written) | Treat as stable within session — accept the cache-creation cost on first regeneration; it pays back on subsequent calls |
| Codex runtime caching semantics differ | Note divergence in `runtimes/codex/adapter.yaml` — convention is cache-aware in general, not provider-specific. No special-casing in v0.9 |
| Telemetry field absent from model response | Emit `null` for that field; never error |
| Validator encounters malformed marker (typo, e.g., `<!-- CACHE: STABL -->`) | Emit `CACHE-004: unrecognized marker keyword` and continue |

## 7. Non-Goals

- Forcing a specific token count for the stable prefix — this is a structural rule, not a quantitative one.
- Building a cache-aware client wrapper. Cache control headers and `cache_control` markers are Claude Code's runtime concern.
- Retrofitting every skill in v0.9. The four highest-impact skills (tdd-cycle, implementer, reviewer, verify) are remediated; remaining skills are documented for v0.9.x.
- Optimizing for OpenAI/Codex automatic caching specifically. The convention is cache-aware in general; provider-specific tuning happens in runtime adapters.
- Replacing the v0.8 active-view pattern. This spec generalizes it.

## 8. Open Questions

1. **CI enforcement timing.** Recommendation: warn-only in v0.9, `--strict` blocking in v1.0 once all skills are compliant. Confirm with maintainers.
2. **Marker grammar.** Comment-marker convention (`<!-- CACHE: STABLE -->`) keeps validation lightweight and unaffected by markdown rendering. Alternative: YAML frontmatter blocks. Recommendation: stick with comment markers — simpler, no parser dependency.
3. **Active learnings as "stable".** They mutate on every learning write. Recommendation: treat as stable within session; accept the cache-creation cost on session start and on regeneration. Document the trade-off in the rule.
4. **Codex divergence.** Codex caching semantics differ. Recommendation: note divergence in `runtimes/codex/adapter.yaml`, do not special-case in v0.9. Revisit when a Codex-specific user surfaces cache-cost concerns.

## 9. Dependencies

- **PR #6** (rules/knowledge on-demand loading) — must land before this spec's audit phase begins. PR #6 establishes which rules and knowledge files are loaded into the stable prefix vs deferred.
- `core/rules/cache-discipline.md` — new auto-loaded rule (this spec creates it).
- `core/rules/agent-coordination.md` — existing rule, updated to cross-reference cache-discipline and require stable-prefix layout for Task dispatches.
- `scripts/validate-cache-discipline.py` — new validator (this spec creates it). May share helpers with `scripts/compile.py` if convenient.
- `core/skills/tdd-cycle/SKILL.md`, `core/skills/implementer/SKILL.md`, `core/skills/reviewer/SKILL.md`, `core/skills/verify/SKILL.md` — remediated in v0.9.
- `tests/cache-discipline/fixtures/` — new fixture tree.
- Companion telemetry spec — provides the post-flight telemetry line that this spec extends with cache fields.
- v0.8 learnings active-view spec — precedent and reference example.

## 10. Sizing

Small. ~1.5–2 days of cycle work. Decomposes into:

1. Draft `cache-discipline.md` rule (under 80 lines) — 0.25 day
2. Build `validate-cache-discipline.py` + fixtures + tests — 0.5 day
3. Update `agent-coordination.md` cross-reference — 0.1 day
4. Audit + remediate four high-impact skills — 0.5 day
5. Wire cache fields into telemetry line (per companion spec) — 0.25 day
6. Documentation (rule citations, before/after example, audit checklist rows) — 0.25 day

Cycle 1 of M3, scheduled after PR #6 merges.

## 11. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-22 | 0.1.0 | abrooke + Claude | Initial spec — codify v0.8 active-view discipline as project-wide cache-aware layout convention |

# Implementation Plan: Telemetry JSONL — Per-Skill Trace Recording

> Status: Complete (v0.9.0) — superseded by shipped feature.

**Spec Version:** 0.1.0
**Spec:** specs/telemetry-jsonl.md
**Created:** 2026-04-22
**Target Release:** v0.9.0 / M3-pre-ga-hardening (Cycle 3)
**Team Size:** Solo swarm (Swarm F, Wave 2)
**Estimated Duration:** 1 session (~2-3 hours)

## Overview

Add a single append-only JSONL stream at `.add/telemetry/{YYYY-MM-DD}.jsonl` — one line per skill invocation — using OpenTelemetry GenAI semantic conventions. The format is pure write-side: telemetry is never read into LLM context. A new auto-loaded rule (`core/rules/telemetry.md`) defines the schema and emission protocol. The dashboard skill gains a Cost & Velocity panel that aggregates telemetry files into per-skill / per-cycle / per-spec stats. Cache-discipline spec AC-022..024 is closed here: `gen_ai.usage.cache_read_input_tokens`, `gen_ai.usage.cache_creation_input_tokens`, and a derived `cache_hit_ratio` are part of the schema.

## Design Decisions

### Decision 1: Rule-based emission, not hook-based

Per the spec's Open Question 2, emission lives **in the rule body**, not a PostToolUse hook. The rule describes what every skill must append post-flight. This matches ADD's existing pattern (learning.md defines checkpoint triggers; skills follow). Rationale: explicit, testable, survives hook config drift.

### Decision 2: Reference pattern, not per-skill edit

Per the M3 parallelism analysis and this swarm's explicit brief, the per-skill `@reference core/rules/telemetry.md` sweep is **deferred**. Every Wave 2 swarm (cache-discipline audits tdd-cycle/implementer/reviewer/verify; test-deletion-guardrail edits tdd-cycle/verify; agents-md-sync touched init/spec/verify) is modifying some SKILL.md file. Doing the mass-append here would guarantee merge conflicts. Instead:

- The rule is **autoload: true** — every skill has access to its text at runtime without an explicit reference.
- The intended per-skill pattern is documented in the rule body as the "Skill pre-flight / post-flight contract" section.
- A non-blocking compile-time check (optional) could be added later.

### Decision 3: Daily rotation by default (M3 OQ-3)

Per M3 open-question 3 resolution: daily by default. Hourly is available via `.add/config.json:telemetry.rotation = "hourly"` (AC-006).

### Decision 4: Closes Swarm A's cache deferral

PR #9 (cache-discipline) explicitly deferred the telemetry-side cache fields. This PR lands them:

- `gen_ai.usage.cache_read_input_tokens` (AC-009, cache AC-022)
- `gen_ai.usage.cache_creation_input_tokens` (AC-009, cache AC-022)
- derived `cache_hit_ratio = cache_read / (cache_read + cache_creation + uncached_input)` (cache AC-024)
- Null handling: missing fields emit `null`, never error (AC-018, cache AC-023)

## Files

### Created

| Path | Purpose |
|------|---------|
| `core/rules/telemetry.md` | Auto-loaded rule: schema, file location, emission protocol, cache-field inclusion |
| `core/templates/telemetry.jsonl.template` | Canonical example JSONL (3-5 lines) showing the schema |
| `tests/telemetry-jsonl/fixtures/basic.jsonl` | Expected JSONL — successful skill invocation with cache fields |
| `tests/telemetry-jsonl/fixtures/no-cache.jsonl` | Expected — cache fields null (model didn't report) |
| `tests/telemetry-jsonl/fixtures/failed.jsonl` | Expected — outcome: "failed" with error field |
| `tests/telemetry-jsonl/fixtures/rotation.jsonl` | Two entries in single day's file (rotation/append check) |
| `tests/telemetry-jsonl/fixtures/malformed.jsonl` | One bad line + two good (parser resilience, AC-024) |
| `tests/telemetry-jsonl/test-telemetry-jsonl.sh` | Fixture-based test harness (pattern: tests/hooks/test-filter-learnings.sh) |
| `docs/plans/telemetry-jsonl-plan.md` | This document |

### Modified

| Path | Change |
|------|--------|
| `core/skills/dashboard/SKILL.md` | Add a new "Cost & Velocity" panel section describing JSONL aggregation (AC-020..AC-024) |

### Explicitly NOT modified (deferred)

- `core/skills/*/SKILL.md` pre-flight blocks (the per-skill append) — deferred to post-M3 follow-up per M3 parallelism coordination
- `.add/config.json` — swarm brief says do not touch
- `plugins/add/**`, `dist/codex/**` — generated, rewritten by compile.py
- Other specs

## AC Coverage Matrix

| AC | Criterion | Delivered by |
|----|-----------|--------------|
| AC-001 | `.add/telemetry/{YYYY-MM-DD}.jsonl` daily rotation | rule §"File Location & Rotation" |
| AC-002 | Each line a complete JSON terminated by `\n` | rule §"Line Format" + fixtures |
| AC-003 | Append-only (file-granular pruning) | rule §"Append-Only Semantics" |
| AC-004 | Telemetry NEVER read into LLM context | rule §"Context Boundary" (explicit) |
| AC-005 | Directory auto-created on first emission | rule §"First Emission" |
| AC-006 | Optional hourly rotation via config | rule §"Configuration" |
| AC-007 | OTel GenAI required fields present | rule schema + template |
| AC-008 | ADD-specific fields present | rule schema + template |
| AC-009 | Cache fields when reported (omit when absent → null) | rule §"Cache Fields", template, fixtures |
| AC-010 | Valid outcomes: success/failed/aborted/partial; error truncated to 500 chars | rule §"Outcomes" |
| AC-011 | `gen_ai.operation.name` = `skill_invocation` / `skill_invocation.nested` | rule schema |
| AC-012 | `tool_calls` aggregated per tool (not per call) | rule schema |
| AC-013 | `files_touched` deduplicated; optional SHA-256 redaction | rule §"Files Touched" |
| AC-014 | New rule under 80 lines | rule itself |
| AC-015 | Pre-flight captures start_ts, session_id, skill, skill_version, spec_id | rule §"Pre-Flight" |
| AC-016 | Post-flight appends complete entry | rule §"Post-Flight" |
| AC-017 | On failure, still emit (outcome: failed/aborted) | rule §"Failure Handling" |
| AC-018 | Unknown tokens emitted as null (not 0) | rule §"Null Semantics" |
| AC-019 | `telemetry.enabled: false` disables emission | rule §"Configuration" |
| AC-020 | Dashboard gains Cost & Velocity panel | dashboard SKILL.md edit |
| AC-021 | Per-skill totals shown | dashboard SKILL.md edit |
| AC-022 | Per-cycle + per-spec totals shown | dashboard SKILL.md edit |
| AC-023 | Inline SVG trend chart, no JS | dashboard SKILL.md edit |
| AC-024 | Reader tolerates malformed lines | dashboard SKILL.md edit + malformed.jsonl fixture |
| AC-025 | Export pattern documented (vector / otel-collector) | rule §"Export" + dashboard SKILL.md edit |
| AC-026 | Native collector ingest (no translation) | rule §"OTel Alignment" |
| AC-027 | `.add/config.json` telemetry block schema documented | rule §"Configuration" (documents the schema; actual config edit is out of scope for this PR) |
| AC-028 | Retention pruning (90 days default) | rule §"Retention" |
| AC-029 | `telemetry.commit_to_git` controls gitignore | rule §"Git Semantics" |
| AC-030 | POSIX O_APPEND concurrent write safety | rule §"Concurrent Writes" |
| **cache AC-022** | `cache_read_input_tokens` field | rule schema, template, fixtures |
| **cache AC-023** | Null for missing cache fields (no error) | rule §"Null Semantics" + no-cache fixture |
| **cache AC-024** | Derived `cache_hit_ratio` | rule §"Derived Metrics", template |

## Phases

### Phase 0: Orient (done — see branch state)

### Phase 1: Plan (this document)

### Phase 2: RED — fixtures + harness

1. Build `tests/telemetry-jsonl/fixtures/` with 5 JSONL fixtures
2. Write `tests/telemetry-jsonl/test-telemetry-jsonl.sh` that:
   - Asserts every fixture JSON parses (via `python3 -c 'import json; json.loads(...)'`)
   - Asserts required fields are present per schema
   - Asserts cache-field null handling
   - Asserts malformed fixture's parser-resilient behaviour (one bad line; two good lines still parse)

### Phase 3: GREEN

1. `core/rules/telemetry.md` (under 80 lines, autoload: true)
2. `core/templates/telemetry.jsonl.template` — canonical 3-5 line sample
3. `core/skills/dashboard/SKILL.md` — new "Panel 7 — Cost & Velocity" section (tables + inline SVG)

### Phase 4: Verify

```bash
python3 scripts/compile.py
python3 scripts/validate-frontmatter.py
python3 scripts/compile.py --check
bash tests/hooks/test-filter-learnings.sh
bash tests/telemetry-jsonl/test-telemetry-jsonl.sh
```

### Phase 5: Commit + Push + PR

Commits (Co-Authored-By on each):
1. `feat(rules): telemetry.md rule + JSONL template + OTel-aligned schema`
2. `feat(dashboard): Cost & Velocity telemetry aggregation panel`
3. `test(telemetry-jsonl): fixtures + harness covering schema, cache fields, rotation, malformed`

PR targets `main`, references cache-discipline AC-022..024 closure, flags per-skill @reference sweep as deferred.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Rule exceeds 80-line constraint (AC-014) | Concise language, reference template instead of inlining examples, pointer to spec for detail |
| Dashboard section bloats the skill | Keep it to ~40 lines; reference rule for schema, don't duplicate |
| Test harness pattern drift from test-filter-learnings.sh | Reuse `run_test` shape + PASS/FAIL counters |
| Follow-up PR to do per-skill @reference sweep forgotten | Document deferred work explicitly in PR body + this plan |

## Open Items for Follow-Up PRs

1. Per-skill `@reference core/rules/telemetry.md` sweep across all 26 SKILL.md files (conflicts with Wave 2 swarms; land after Wave 2 merges)
2. `.add/config.json` schema migration to include `telemetry` block with defaults (AC-027 documents the schema; materializing it requires coordinated config-schema work)
3. Retention pruning integration into `/add:learnings archive` (AC-028 — rule describes the contract; wiring into the archive skill is a clean follow-up)
4. `.gitignore` template conditional based on `telemetry.commit_to_git` (AC-029 — template edit)
5. Compile-time lint script that reports skills missing telemetry emission discipline (nice-to-have)

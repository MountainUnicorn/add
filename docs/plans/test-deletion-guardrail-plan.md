# Implementation Plan: Test Deletion Guardrail

> Status: Complete (v0.9.0) — superseded by shipped feature.

**Spec:** `specs/test-deletion-guardrail.md`
**Target Release:** v0.9.0
**Milestone:** M3-pre-ga-hardening
**Cycle:** M3 Cycle 3 (methodology hardening)

## Summary

Hardens ADD's TDD claim with an anti-deletion guardrail. At end of RED, `/add:test-writer`
captures a snapshot of the test surface (files, function names, normalized body hashes). At
end of GREEN, `/add:implementer` re-captures the same surface. `/add:verify` gains **Gate 3.5
— Test Surface Integrity** which fails if tests were removed without an explicit override
(`--allow-test-rewrite` plus a recorded human-approved `overrides.json` entry). A pure-shell
`impact-hint.sh` helper gives the implementer a lightweight "files likely affected" list
sourced from `git diff --name-only`, regex-resolved imports, literal path mentions in the
spec, and anti-pattern learnings lookup in `.add/learnings.json`.

## Files Created

| Path | Purpose |
|------|---------|
| `core/knowledge/test-discovery-patterns.json` | Regex catalog per language (AC-003) |
| `core/lib/impact-hint.sh` | Shell helper: files-likely-affected computation (AC-023) |
| `core/lib/test-surface-snapshot.sh` | Shared helper: runs discovery + emits snapshot JSON |
| `core/lib/test-surface-compare.sh` | Shared helper: compares RED + GREEN snapshots |
| `scripts/check-test-count.py` | Dog-food gate invoked by verify Gate 3.5 (pure python for CI) |
| `tests/test-deletion-guardrail/test-test-deletion-guardrail.sh` | Fixture test runner |
| `tests/test-deletion-guardrail/fixtures/` | Fixture snapshots + expected outputs |
| `docs/plans/test-deletion-guardrail-plan.md` | This plan |

## Files Modified

| Path | Change |
|------|--------|
| `core/skills/tdd-cycle/SKILL.md` | New §Snapshot gates; document RED snapshot + GREEN snapshot + Gate 3.5 hooks; impact-hint trigger at GREEN start |
| `core/skills/test-writer/SKILL.md` | Step N: write + commit RED snapshot; fail if zero tests added |
| `core/skills/implementer/SKILL.md` | Pre-step: consume impact hint; post-step: write GREEN snapshot |
| `core/skills/verify/SKILL.md` | Insert Gate 3.5 "Test Surface Integrity" between Gate 3 and Gate 4 |
| `core/rules/tdd-enforcement.md` | Add "Test-deletion invariant" section (AC-028); document justification marker |
| `scripts/compile.py` | Copy `core/lib/` verbatim into compiled output (new source dir) |

## Acceptance Criteria Coverage

| AC | Covered by | Tested |
|----|-----------|--------|
| AC-001 RED snapshot fields | `core/lib/test-surface-snapshot.sh` + test-writer SKILL | fixture: snapshot-shape |
| AC-002 Language regex catalog | `core/knowledge/test-discovery-patterns.json` | fixture: discovery-python, discovery-ts |
| AC-003 Catalog in knowledge | Same file, in `core/knowledge/` | fixture: catalog-exists |
| AC-004 Snapshot records base_sha + phase_end_sha | `test-surface-snapshot.sh` captures `git rev-parse HEAD` | fixture: snapshot-shape |
| AC-005 test-writer commits RED snapshot | test-writer SKILL explicit instruction | asserted by skill text |
| AC-006 Fail when zero tests added | test-writer SKILL instruction | asserted by skill text |
| AC-007 GREEN re-snapshot | implementer SKILL instruction | asserted by skill text |
| AC-008 Comparison produces four counts | `test-surface-compare.sh` | fixture: compare-counts |
| AC-009 Tests removed fails cycle | `scripts/check-test-count.py` + compare.sh | fixture: count-decreased |
| AC-010 Renames detected via body-hash | `test-surface-compare.sh` | fixture: rename |
| AC-011 Replacements require approval | `check-test-count.py` checks `overrides.json` | fixture: replacement-without-approval, replacement-with-approval |
| AC-012 Normalized body hash | `test-surface-snapshot.sh` normalize function | fixture: rename |
| AC-013 Configurable similarity threshold | `check-test-count.py` reads `.add/config.json` | documented, not fixture-tested |
| AC-014 Gate 3.5 after Gate 3 | verify SKILL insertion | asserted by skill text |
| AC-015 Missing GREEN snapshot error | `check-test-count.py` | fixture: missing-green |
| AC-016 Gate 3.5 fails on removal w/o override | `check-test-count.py` exit 1 | fixture: count-decreased |
| AC-017 Structured summary | `check-test-count.py --format summary` | fixture: count-same |
| AC-018 git diff base..HEAD | `impact-hint.sh` | fixture: impact-hint-basic |
| AC-019 Regex-extract imports | `impact-hint.sh` | fixture: impact-hint-basic |
| AC-020 Literal path mentions in spec | `impact-hint.sh` | fixture: impact-hint-spec-paths |
| AC-021 Anti-pattern learnings | `impact-hint.sh` | fixture: impact-hint-antipattern |
| AC-022 Structured prompt to implementer | implementer SKILL consumes helper output | asserted by skill text |
| AC-023 Pure shell + jq + grep | `impact-hint.sh` implementation | structural |
| AC-024 Zero-source-file message | `impact-hint.sh` | fixture: impact-hint-empty |
| AC-025 Telemetry JSONL | Out of scope for this swarm — handled by companion telemetry spec | deferred |
| AC-026 Telemetry record fields | Deferred | deferred |
| AC-027 Telemetry write-fail warn | Deferred | deferred |
| AC-028 Rule strengthening | `core/rules/tdd-enforcement.md` new section | asserted by rule text |

**Deferred:** AC-025, AC-026, AC-027 (telemetry) belong to the companion `telemetry-jsonl`
spec and its swarm. This spec notes the integration contract but does not ship the JSONL
writer itself.

## Gate 3.5 Decision Flow

```
Gate 3 (tests pass) --> Gate 3.5 (surface integrity)
                                |
                                v
                 read .add/cycles/cycle-{N}/tdd-{slug}-red.json
                 read .add/cycles/cycle-{N}/tdd-{slug}-green.json
                 read .add/cycles/cycle-{N}/overrides.json (optional)
                                |
                                v
                 compare.sh --> {added, removed, renamed, replaced}
                                |
                 removed > 0?  --NO--> PASS (emit summary)
                                |
                                YES
                                |
                 override present for each removed test? --YES--> PASS
                                |
                                NO
                                |
                                v
                              FAIL (exit 1, structured error)
```

## Justification Marker Format

For commit-trailer-based overrides (used outside a formal cycle, e.g. hand-run refactors):

```
[ADD-TEST-DELETE: AC-042 — assertion was testing removed public API]
```

For cycle-scoped overrides (inside `/add:tdd-cycle --allow-test-rewrite`):

```json
// .add/cycles/cycle-{N}/overrides.json
{
  "kind": "test-rewrite",
  "approved_by": "human",
  "timestamp": "2026-04-22T14:32:00Z",
  "affected_tests": ["tests/test_auth.py::test_validation"]
}
```

`check-test-count.py` accepts either form.

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| False positives from body normalization | Medium | Low | Configurable threshold; renames always allowed |
| Multi-language projects miss tests | Medium | Medium | Catalog supports union of languages from config |
| Test moved across files reads as removal | Medium | Medium | Body-hash match across files is classified as move, not removal |
| `.add/cycles/cycle-{N}/` missing on fresh checkout | High | Low | Snapshot-missing error tells user to rerun RED (fail-safe) |
| Snapshot catalog extension churn | Low | Low | Catalog lives in `core/knowledge/` so users can PR additions |
| Users bypass by editing snapshot file | High | Medium | Out of scope — the guardrail is cooperative; social + git-blame defends |

## Test Fixture Plan

All fixtures live under `tests/test-deletion-guardrail/fixtures/`:

| Fixture | Shape | Expected |
|---------|-------|----------|
| `count-same` | RED + GREEN snapshots with identical function sets | PASS |
| `count-increased` | GREEN has strictly more tests than RED | PASS |
| `count-decreased` | GREEN missing one RED test, no override | FAIL |
| `count-decreased-with-approval` | Same as above + overrides.json | PASS |
| `empty-before` | Empty RED (first cycle, no prior tests) | PASS (bootstrap case — no existing tests to remove) |
| `missing-green` | RED present, GREEN absent | FAIL |
| `rename` | Same body hash, different function name | PASS (classified rename) |
| `replacement-without-approval` | Same name, body differs, no override | FAIL |
| `replacement-with-approval` | Same + override | PASS |

Additional fixtures for `impact-hint.sh`:

| Fixture | Shape | Expected |
|---------|-------|----------|
| `impact-hint-basic` | Diff adds `tests/test_foo.py` importing `from app.foo import bar` | Emits `app/foo.py` |
| `impact-hint-empty` | Diff test-only; no import resolution | Emits explanatory message |
| `impact-hint-antipattern` | Learnings has anti-pattern mentioning `app/session.py` | Flags `app/session.py` separately |

## Dog-Food Check

After implementation:

```bash
python3 scripts/check-test-count.py --baseline origin/main
```

Since this PR adds new tests (fixture runner, hint fixtures) and removes none, the gate
must pass against this PR itself.

## Rollback Strategy

All changes are additive except the three existing SKILL.md edits, which insert new
sections. If the guardrail proves too noisy in beta, rollback is:

1. Remove the Gate 3.5 section from `core/skills/verify/SKILL.md`
2. Remove the snapshot steps from test-writer / implementer / tdd-cycle
3. Keep `core/knowledge/test-discovery-patterns.json` and `core/lib/` (no harm done if unused)

## Open Questions Answered for This Implementation

- **AC-025/026/027 telemetry** — out of scope; stub references only
- **Partial-AC cycles** — treated as full-file snapshot (conservative; spec Open Q1)
- **0.85 similarity threshold** — shipped as default; configurable
- **Hint enrichment with `git log`** — deferred (spec Open Q4); keep prompt minimal
- **Override audit trail in `/add:retro`** — documented in rule; implementation deferred (spec Open Q5)

# Spec: Test Deletion Guardrail

**Version:** 0.1.0
**Created:** 2026-04-22
**PRD Reference:** docs/prd.md
**Status:** Complete
**Target Release:** v0.9.0
**Shipped-In:** v0.9.0
**Last-Updated:** 2026-04-22
**Milestone:** M3-pre-ga-hardening

## 1. Overview

ADD's signature differentiator is strict TDD enforced as a separation of concerns across sub-agents: the test-writer produces failing tests (RED), a separate implementer fixes the code (GREEN), then refactor and verify. The claim only holds if the failing tests survive the GREEN phase. Documented research and practitioner experience say they often don't:

- Kent Beck (2026): *"the genie doesn't want to do TDD"* — coding agents prefer the path of least resistance, which is removing the friction (the failing test) rather than satisfying it.
- TDAD paper (arXiv 2603.17973): naive TDD-prompting *increased* regression rate to 9.94% because agents silently deleted tests they couldn't satisfy.

`/add:tdd-cycle` currently has no detection mechanism for this. The verify phase passes if tests pass — regardless of whether the test count went down between RED and GREEN.

This spec hardens ADD's TDD claim with explicit anti-deletion guardrails: a test-surface snapshot at end of RED, a comparison snapshot at end of GREEN, and a Gate 3.5 in `/add:verify` that fails the cycle if tests disappeared without a sanctioned override. It also adds a TDAD-inspired *"files likely affected"* hint to the implementer — a lightweight impact-graph built from `git diff --name-only` plus regex over test imports, with no graph library and no language parser.

The story: ADD's TDD claim defends itself.

### User Story

As an ADD user running `/add:tdd-cycle`, I want the cycle to fail loudly if the implementer deleted or weakened the failing tests instead of satisfying them, so that the TDD discipline ADD advertises is actually enforced — not aspirational.

## 2. Acceptance Criteria

### A. RED Snapshot

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | At end of RED phase, `/add:test-writer` writes a snapshot to `.add/cycles/cycle-{N}/tdd-{spec-slug}-red.json` capturing: test files (paths), test function count per file, test function names per file, and the SHA-1 body hash of each test function. | Must |
| AC-002 | Test discovery uses regex heuristics dispatched by language (detected from `.add/config.json` `architecture.languages`): Python (`def test_\w+`, `async def test_\w+`), TypeScript/JavaScript (`it\(['"]`, `test\(['"]`, `describe\(['"]`), Go (`func Test\w+\(`, `func Benchmark\w+\(`), Ruby (`def test_\w+`, `it ['"]`), Rust (`#\[test\]`, `#\[tokio::test\]`). | Must |
| AC-003 | The regex catalog lives in `core/knowledge/test-discovery-patterns.json` so users can extend or override patterns per language without editing skill markdown. | Must |
| AC-004 | The snapshot also records the cycle's git base SHA (HEAD at cycle start) and the SHA at end of RED, so later comparison can run `git diff` between known points. | Must |
| AC-005 | `/add:test-writer` MUST commit the RED snapshot before exiting the RED phase — explicit instruction in `core/skills/test-writer/SKILL.md`. The commit message follows pattern `test(red): snapshot {N} tests for {spec-slug}`. | Must |
| AC-006 | If no test files were added during RED (test count delta is zero), test-writer fails with structured error — RED with no new tests is itself a TDD violation. | Must |

### B. GREEN Re-Snapshot and Comparison

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-007 | At end of GREEN phase, `/add:implementer` re-runs the discovery against the same files and writes `.add/cycles/cycle-{N}/tdd-{spec-slug}-green.json` with identical schema. | Must |
| AC-008 | Comparison logic produces three counts: `tests_added`, `tests_removed`, `tests_renamed`, plus a `tests_replaced` list (same name, different body hash). | Must |
| AC-009 | If `tests_removed > 0` without an explicit `--allow-test-rewrite` flag, the cycle fails with structured error listing each removed test (file, function name, removing commit SHA, RED-phase body excerpt) and a directive: *"Test deletion during a TDD cycle is forbidden. Fix the implementation, not the test."* | Must |
| AC-010 | Renames are detected via body-hash equality across different function names. Renames are allowed and logged but do not fail the cycle. | Must |
| AC-011 | Replacements (same name, body-hash differs by more than the rename threshold) require `--allow-test-rewrite` AND an explicit human approval prompt before the cycle continues. The approval is recorded in `.add/cycles/cycle-{N}/overrides.json`. | Must |
| AC-012 | Rename heuristic uses normalized body hashing: strip whitespace, comments, and the function name itself before hashing — so `def test_foo(): assert add(1,2)==3` and `def test_addition(): assert add(1,2)==3` collide. | Should |
| AC-013 | The replacement threshold is configurable in `.add/config.json` under `tdd.test_rewrite_similarity` (default `0.85` — fraction of normalized lines that must match to count as rename vs. rewrite). | Should |

### C. Gate 3.5 — Test Surface Integrity

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-014 | `/add:verify` adds Gate 3.5: "Test surface integrity check" — runs after Gate 3 (tests pass), before Gate 4 (spec compliance). Documented in `core/skills/verify/SKILL.md`. | Must |
| AC-015 | Gate 3.5 reads RED and GREEN snapshots from `.add/cycles/cycle-{N}/`. If GREEN snapshot is missing, gate fails with *"GREEN snapshot not found — cycle is incomplete or test-writer/implementer skipped snapshotting."* | Must |
| AC-016 | Gate 3.5 fails verify if comparison shows `tests_removed > 0` and no override is recorded in `overrides.json`. | Must |
| AC-017 | Gate 3.5 emits a structured summary even on success: `tests_added: N, tests_removed: 0, tests_renamed: M, tests_replaced: 0, override: none`. | Should |

### D. Files Likely Affected Hint

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-018 | At end of RED, the cycle computes `git diff --name-only {base-sha}..HEAD` to identify files changed during RED (which will be the new/modified test files). | Must |
| AC-019 | For each test file changed, regex-extract import statements (Python: `from X import`, `import X`; TS/JS: `from '...'`, `require('...')`; Go: `import "..."`) and resolve them to local source files in the repo. | Must |
| AC-020 | Cross-reference: union the import-resolved paths with file paths mentioned literally in the spec's acceptance criteria (regex: any token matching `[\w/]+\.(py|ts|js|go|rs|rb)`). | Must |
| AC-021 | Cross-reference: query `.add/learnings.json` for entries with `category: "anti-pattern"` whose `body` mentions any of the candidate file paths. Surface those file paths separately as *"files to be careful around."* | Must |
| AC-022 | At start of GREEN, `/add:implementer` is shown a structured prompt: `Files likely to need changes: [list]. Files to be careful around (recent anti-pattern learnings exist): [list-with-learning-ids].` | Must |
| AC-023 | The hint generator is pure shell + `jq` + `grep` — no graph library, no AST parser. Implementation lives in `core/lib/impact-hint.sh` and is invoked from the cycle skill. | Must |
| AC-024 | If the diff produces zero source files (test-only change) the hint says so explicitly rather than producing an empty list — *"No source files implied by RED diff. Check spec acceptance criteria for implementation targets."* | Should |

### E. Telemetry Integration

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-025 | Per-cycle counts (`tests_added`, `tests_removed`, `tests_renamed`, `tests_replaced`) are appended to the telemetry JSONL at `.add/telemetry/cycles.jsonl` (companion spec defines the JSONL schema). | Must |
| AC-026 | Each telemetry record includes: `cycle_id`, `spec_slug`, `red_sha`, `green_sha`, the four counts, `override_used` (boolean), and `timestamp`. | Must |
| AC-027 | If telemetry write fails (file locked, disk full), the cycle continues but logs a warning — telemetry is observability, not a gate. | Should |

### F. Rule Strengthening

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-028 | `core/rules/tdd-enforcement.md` adds an explicit invariant: *"Tests added during RED MUST exist (passing) at the end of GREEN. Test deletion during the cycle is forbidden without `--allow-test-rewrite` and explicit human approval. Test renames are permitted; test replacements require approval."* | Must |

## 3. User Test Cases

### TC-001: Snapshot captures Python test surface

**Precondition:** Project is Python. RED phase added 4 new `def test_*` functions across 2 files in `tests/`.
**Steps:**
1. `/add:tdd-cycle specs/auth.md` reaches end of RED
2. test-writer runs discovery using Python regex from `test-discovery-patterns.json`
3. Snapshot written to `.add/cycles/cycle-3/tdd-auth-red.json`
4. test-writer commits the snapshot
**Expected Result:** Snapshot contains 2 file entries, 4 total functions with names and body hashes. Commit `test(red): snapshot 4 tests for auth` exists.
**Maps to:** TBD

### TC-002: GREEN comparison detects deletion

**Precondition:** RED snapshot has 5 tests. Implementer deletes 1 test it couldn't satisfy.
**Steps:**
1. GREEN phase completes
2. implementer re-runs discovery → 4 tests
3. Comparison: `tests_removed: 1`
4. No `--allow-test-rewrite` flag passed
**Expected Result:** Cycle fails with structured error naming the removed test (file, function name, deleting commit SHA), the RED-phase body excerpt, and the directive to fix code not the test.
**Maps to:** TBD

### TC-003: Comparison allows rename

**Precondition:** RED has `def test_user_creation():` with body `assert User("a").name == "a"`. GREEN has `def test_user_constructs_with_name():` with the same normalized body.
**Steps:**
1. GREEN snapshot taken
2. Comparison computes body hashes — names differ, normalized bodies match
3. Classified as rename
**Expected Result:** Cycle continues. Telemetry records `tests_renamed: 1`. Log entry written. No override required.
**Maps to:** TBD

### TC-004: Comparison flags replacement

**Precondition:** RED has `def test_validation():` with assertion-rich body. GREEN has same name but body now reads `assert True`.
**Steps:**
1. GREEN snapshot taken
2. Comparison: same name, body hash differs by more than `tdd.test_rewrite_similarity` threshold
3. Classified as replacement
4. No `--allow-test-rewrite` flag
**Expected Result:** Cycle fails, requesting either the original test back or `--allow-test-rewrite` plus explicit approval.
**Maps to:** TBD

### TC-005: --allow-test-rewrite with approval

**Precondition:** Test was legitimately wrong (asserted incorrect behavior). User reruns with `/add:tdd-cycle --allow-test-rewrite specs/auth.md`.
**Steps:**
1. GREEN comparison flags replacement
2. Approval prompt shown to human with diff
3. Human confirms
4. Override recorded in `.add/cycles/cycle-3/overrides.json`
**Expected Result:** Cycle continues. Gate 3.5 reads override and passes. Telemetry has `override_used: true`.
**Maps to:** TBD

### TC-006: Gate 3.5 catches missing GREEN snapshot

**Precondition:** Implementer crashed before writing GREEN snapshot. Tests pass.
**Steps:**
1. `/add:verify` runs
2. Gate 3 (tests pass) passes
3. Gate 3.5 looks for `tdd-{spec-slug}-green.json` — missing
**Expected Result:** Gate 3.5 fails with *"GREEN snapshot not found — cycle is incomplete or test-writer/implementer skipped snapshotting."* Verify exits non-zero.
**Maps to:** TBD

### TC-007: Files-likely-affected hint at GREEN start

**Precondition:** RED added `tests/test_auth.py` which imports `from app.auth import login`. Spec acceptance criteria mention `app/auth.py` and `app/session.py`. Learnings has anti-pattern `L-042` mentioning `app/session.py`.
**Steps:**
1. End of RED triggers `core/lib/impact-hint.sh`
2. Diff yields `tests/test_auth.py`
3. Import resolution → `app/auth.py`
4. Spec scan → `app/auth.py`, `app/session.py`
5. Anti-pattern lookup → `app/session.py` flagged
**Expected Result:** Implementer prompt: *"Files likely to need changes: app/auth.py, app/session.py. Files to be careful around (recent anti-pattern learnings exist): app/session.py [L-042]."*
**Maps to:** TBD

### TC-008: Telemetry written per cycle

**Precondition:** Cycle 3 ran with 4 tests added, 0 removed, 1 renamed, 0 replaced.
**Steps:**
1. Cycle completes
2. Telemetry write triggered
**Expected Result:** `.add/telemetry/cycles.jsonl` gains a JSONL line with `cycle_id: 3`, `spec_slug: "auth"`, the four counts, `override_used: false`, ISO timestamp.
**Maps to:** TBD

### TC-009: Test-writer fails on empty RED

**Precondition:** test-writer exits RED having added zero new tests.
**Steps:**
1. test-writer runs discovery on RED snapshot vs base
2. Delta is zero
**Expected Result:** test-writer fails with *"RED phase produced no failing tests — TDD violation."* Cycle does not proceed to GREEN.
**Maps to:** TBD

## 4. Data Model

### TestSurfaceSnapshot (JSON)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `cycle_id` | integer | Yes | Cycle number from `/add:cycle` |
| `spec_slug` | string | Yes | Slug derived from spec filename |
| `phase` | enum | Yes | `red` \| `green` |
| `base_sha` | string | Yes | Git SHA at cycle start |
| `phase_end_sha` | string | Yes | Git SHA at end of phase |
| `language` | string | Yes | Primary language detected from config |
| `files` | object[] | Yes | One entry per test file (see TestFile) |
| `total_functions` | integer | Yes | Sum across all files |
| `timestamp` | string | Yes | ISO 8601 |

### TestFile

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | string | Yes | Repo-relative path |
| `function_count` | integer | Yes | Test functions in this file |
| `functions` | object[] | Yes | One entry per function (name + body_hash) |

### TestFunction

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Function/identifier name |
| `body_hash` | string | Yes | SHA-1 of normalized body (whitespace/comments/name stripped) |
| `line_start` | integer | No | Source line for diagnostics |

### ComparisonResult (JSON)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tests_added` | integer | Yes | Functions present in GREEN, absent in RED |
| `tests_removed` | integer | Yes | Functions present in RED, absent in GREEN |
| `tests_renamed` | integer | Yes | Body hash matches, name differs |
| `tests_replaced` | TestReplacement[] | Yes | Same name, body hash differs beyond threshold |
| `removed_details` | TestRemoval[] | Yes | One per removed test (path, name, removing commit SHA, body excerpt) |

### Override Record (`.add/cycles/cycle-{N}/overrides.json`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `kind` | enum | Yes | `test-rewrite` |
| `approved_by` | string | Yes | `human` (always — there is no agent self-approval) |
| `timestamp` | string | Yes | ISO 8601 |
| `affected_tests` | string[] | Yes | List of `path::function_name` |

### Telemetry Record (one JSONL line)

```json
{
  "cycle_id": 3,
  "spec_slug": "auth",
  "red_sha": "abc1234",
  "green_sha": "def5678",
  "tests_added": 4,
  "tests_removed": 0,
  "tests_renamed": 1,
  "tests_replaced": 0,
  "override_used": false,
  "timestamp": "2026-04-22T14:32:00Z"
}
```

## 5. API Contract

N/A — pure markdown/JSON plugin. All artifacts are files on disk read by ADD skills.

## 6. UI Behavior

N/A — CLI plugin. Failures print structured errors; successes emit Gate 3.5 summary.

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Multi-language project (e.g., Python backend + TS frontend) | Run discovery for each language present in config; merge results in single snapshot |
| Test file moved (path changed, content identical) | Detected as same body hashes under new path — classify as moved, allow without override |
| Test file deleted entirely | Treated as removal of all functions in that file — fails Gate 3.5 unless override |
| RED snapshot exists but cycle dir was manually deleted before GREEN | Gate 3.5 fails with snapshot-missing error; user must rerun the cycle |
| `--ac AC-001` partial cycle (only one acceptance criterion targeted) | Snapshot scope is still the full file; partial cycles must not delete tests for *other* ACs either |
| Snapshot file corrupted (invalid JSON) | Gate 3.5 fails with parse error; user must rerun RED |
| Concurrent cycles on different specs | Each cycle has its own `cycle-{N}/` dir — no contention |
| Test framework not in catalog (e.g., bun:test, vitest) | User extends `test-discovery-patterns.json`; until then, falls back to TS/JS catalog |
| Body normalization collapses two genuinely different tests to same hash | Acceptable false-positive for renames — log warning and let the cycle continue |
| Anti-pattern learning mentions a path that no longer exists | Skip silently — don't surface stale warnings |

## 8. Dependencies

- `core/skills/tdd-cycle/SKILL.md` — orchestrator; documents snapshot/compare flow
- `core/skills/test-writer/SKILL.md` — RED snapshot + commit instruction
- `core/skills/implementer/SKILL.md` — GREEN snapshot + receive files-likely-affected hint
- `core/skills/verify/SKILL.md` — Gate 3.5 integration
- `core/rules/tdd-enforcement.md` — invariant added
- `core/knowledge/test-discovery-patterns.json` — new regex catalog
- `core/lib/impact-hint.sh` — new shell helper for files-likely-affected
- `.add/learnings.json` — anti-pattern lookup for hint
- Companion telemetry spec — defines `.add/telemetry/cycles.jsonl` schema

## 9. Open Questions

- **Test-discovery patterns**: ship the catalog as-is for Python/TS/JS/Go/Ruby/Rust and rely on user extension for the long tail (bun, vitest variants, pytest plugins, JUnit), or include a broader default set?
- **Partial-AC cycles**: when `/add:tdd-cycle --ac AC-001` runs, must *all* tests for that AC exist at end of GREEN, or is partial coverage acceptable so long as no existing tests vanish?
- **Rename heuristic looseness**: is the 0.85 normalized-line threshold the right default, or do we want a body-AST-token similarity score? (The latter requires per-language tooling — out of scope unless heuristic proves too noisy.)
- **Hint enrichment**: should the files-likely-affected hint also include recent commits to those files (`git log -3 --oneline`) so the implementer sees recent context, or does that bloat the prompt?
- **Override audit trail**: should `--allow-test-rewrite` overrides surface in `/add:retro` automatically as items requiring review?

## 10. Non-Goals

- Static-analysis-grade impact graph — out of scope; the diff+grep heuristic is intentionally lightweight and lossy
- Detecting subtle test weakening (assertions removed but test count unchanged) — separate spec, future
- Cross-cycle test-count regression (this spec is per-cycle only; aggregate trends are telemetry-spec territory)
- Language-specific deep parsers — regex heuristics only; users extend the catalog
- Auto-restoring deleted tests — we fail loudly and direct the human, we do not silently revert

## 11. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-22 | 0.1.0 | abrooke + Claude | Initial spec — TDD anti-deletion guardrail + files-likely-affected hint, Cycle 3 of M3 |

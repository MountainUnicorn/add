# Implementation Plan: Telemetry — Per-Skill Reference Sweep (F-013)

> Status: Complete (v0.9.3) — superseded by shipped feature.

**Spec:** `specs/telemetry-skill-reference-sweep.md`
**Spec Version:** 0.1.0
**Created:** 2026-04-26
**Target Release:** v0.9.2 (standalone v0.9.x — no milestone binding)
**Branch:** `feat/telemetry-sweep` (or land directly on `main` for a small sweep at maintainer's discretion)
**Owner:** TBD — single swarm, half-day session
**Estimated Duration:** 0.5–1 day

## 1. Overview

Close Swarm F's M3 deferral by mechanically declaring telemetry-rule
participation in every `core/skills/*/SKILL.md`. Two paths exist:

- **Path A (preferred):** `references: [rules/telemetry.md]` in YAML frontmatter — requires PR #6's `references:` mechanism merged.
- **Path B (fallback):** body-prose `@reference core/rules/telemetry.md` line in each skill's `## Pre-Flight` block — works today.

Path is selected at implementation start based on PR #6 status. The spec
covers both paths' acceptance criteria; this plan execution-orders both.

## 2. Files

### Created

| Path | Purpose |
|------|---------|
| `tests/telemetry-sweep/test-skill-reference-coverage.sh` | Bash harness asserting every `core/skills/*/SKILL.md` carries the chosen reference declaration (AC-020..AC-022) |
| `tests/telemetry-sweep/fixtures/has-reference-path-a.md` | Fixture: SKILL.md with `references:` frontmatter — should pass under path-A |
| `tests/telemetry-sweep/fixtures/has-reference-path-b.md` | Fixture: SKILL.md with `@reference` prose line — should pass under path-B |
| `tests/telemetry-sweep/fixtures/missing-reference.md` | Fixture: bare SKILL.md — should fail under both paths |
| `docs/plans/telemetry-skill-reference-sweep-plan.md` | This document |

### Modified (sweep targets — all 27)

Every `core/skills/*/SKILL.md`:

- agents-md, away, back, brand, brand-update, changelog, cycle,
  dashboard, deploy, docs, implementer, infographic, init, learnings,
  milestone, optimize, plan, promote, retro, reviewer, roadmap, spec,
  tdd-cycle, test-writer, ux, verify, version.

Each skill receives **exactly one** declaration (path-A: one frontmatter
key; path-B: one prose line in `## Pre-Flight`).

### Modified (audit + housekeeping)

| Path | Change |
|------|--------|
| `specs/telemetry-skill-reference-sweep.md` | § 7 Skill Audit Checklist — flip every row from `pending` → `swept` (or document `skipped`) |
| `core/rules/telemetry.md` | One-line edit removing the "deferred post-M3 follow-up" parenthetical; replace with the v0.9.2 closure note. Strictly housekeeping; no contract change |

### Explicitly NOT modified

- `plugins/add/**`, `dist/codex/**` — generated. Will regenerate via `compile.py`; commit the regenerated output in the same PR.
- `.add/config.json` — out of scope per spec.
- Other specs / plans / skills.
- The JSONL schema — this is a methodology-level declarative change.

## 3. AC Coverage Matrix

| AC | Criterion | Delivered by |
|----|-----------|--------------|
| AC-001a | `references: [rules/telemetry.md]` in every SKILL.md frontmatter (path-A) | Sweep step 4a |
| AC-002a | Frontmatter validator accepts the key | PR #6 (external) |
| AC-003a | List form retained | Sweep step 4a |
| AC-001b | `@reference core/rules/telemetry.md` body line (path-B) | Sweep step 4b |
| AC-002b | Consistent positioning across skills | Sweep step 4b — first bullet of `## Pre-Flight` |
| AC-003b | Future migration to path-A is mechanical | Documented in plan § 6 |
| AC-010 | All 27 skills carry the declaration | Sweep step 4 + test-skill-reference-coverage.sh |
| AC-011 | No implicit-emission shortcut | Sweep is exhaustive — every skill swept |
| AC-012 | Audit checklist enumerates 27 skills | Spec § 7 update |
| AC-013 | No undocumented skips | Spec § 7 review gate |
| AC-014 | Declaration produces JSONL emission | Inherited from `core/rules/telemetry.md` Pre-Flight/Post-Flight contract — no plan work; verified by spot-running a skill |
| AC-015 | No skill behavior change | Single-line edit per skill; reviewed via diff |
| AC-016 | Reviewer sub-agent inherits, no double-emit | Inherited from rule's `gen_ai.operation.name = "skill_invocation.nested"` semantics — no plan work |
| AC-017 | Nested emits, outer not double-counted | Same as AC-016 |
| AC-020 | Coverage test exists | `tests/telemetry-sweep/test-skill-reference-coverage.sh` |
| AC-021 | New skills without ref fail the test | Test enumerates `core/skills/*/SKILL.md` dynamically |
| AC-022 | Test runs <2s | Pure bash + grep, no model calls |
| AC-023 | `compile.py --check` clean | Verified in Phase 5 |
| AC-024 | Frontmatter validator clean | Verified in Phase 5 |
| AC-030..032 | Project-level opt-out, no new flag | Inherited from parent spec; verified by spot-test with `telemetry.enabled = false` |

## 4. Phasing

### Phase 0: Decide path-A vs path-B (gate)

1. Inspect PR #6 status: `gh pr view 6` (or repo equivalent).
2. If merged → Path A.
3. If not merged and ETA > target release cut → Path B.
4. Document the choice in the implementation commit's body.

### Phase 1: RED — write the coverage test first

1. Create `tests/telemetry-sweep/` directory.
2. Write `test-skill-reference-coverage.sh`. Pseudocode:

   ```
   for skill in core/skills/*/SKILL.md; do
     if path == "A":
       grep -q "^references:.*rules/telemetry.md" frontmatter || FAIL
     else: # path B
       grep -q "@reference core/rules/telemetry.md" body || FAIL
   done
   ```

3. Add the three fixtures (has-reference-path-a, has-reference-path-b, missing-reference).
4. Run the test — it fails: 27 skills missing the reference. This is the RED bar.

### Phase 2: GREEN — sweep all 27 skills

**Path A:**

1. For each `core/skills/*/SKILL.md`, edit the frontmatter to include
   `references: [rules/telemetry.md]`. Preserve any existing keys.
2. Use 3 parallel sub-agents × 9 skills each, OR a single mechanical
   pass with a deterministic editor — both work.

**Path B:**

1. For each `core/skills/*/SKILL.md`, add `@reference core/rules/telemetry.md`
   as the first or last bullet of the `## Pre-Flight` numbered list.
2. Same parallelism options as path-A.

In either path:

3. Spot-check 3 random skills with `git diff` to verify the edit shape
   is uniform.

### Phase 3: Audit checklist update

1. In `specs/telemetry-skill-reference-sweep.md` § 7, flip every row
   `pending` → `swept`. Document any `skipped` with reason.

### Phase 4: Rule housekeeping

1. Edit `core/rules/telemetry.md` — remove the "deferred post-M3 follow-up"
   parenthetical at the end of the Pre-Flight / Post-Flight Contract
   section. Replace with: "Every ADD SKILL.md declares this rule via
   the `references:` frontmatter (or `@reference` body-prose) — see
   `specs/telemetry-skill-reference-sweep.md` § 2 for the chosen path."

### Phase 5: Verify

```bash
# 1. Coverage test (the new one)
bash tests/telemetry-sweep/test-skill-reference-coverage.sh

# 2. Frontmatter validation (passes under path-A and path-B)
python3 scripts/validate-frontmatter.py

# 3. Compile drift
python3 scripts/compile.py
python3 scripts/compile.py --check

# 4. Existing fixture suite (regression)
bash tests/hooks/test-filter-learnings.sh

# 5. Spot-check telemetry emission (manual)
#    Run /add:plan against a known spec; inspect .add/telemetry/{today}.jsonl
#    for one new line with skill: "plan", outcome: "success" or "failed".
```

All five must pass before commit.

### Phase 6: Commit + Push

Commits (each ends with `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`):

1. `test(telemetry-sweep): coverage test for per-skill telemetry reference`
2. `feat(skills): F-013 declare telemetry rule reference in all 27 skills (path-{A|B})`
3. `chore(rules): remove deferred-sweep parenthetical from telemetry.md`
4. `docs(spec): F-013 audit checklist — all 27 skills swept`
5. (auto) `chore(generated): regenerate plugins/add and dist/codex after sweep`

The first commit can land RED; subsequent commits walk to GREEN. Or
collapse 1+2 into one commit if maintainer prefers single-shot landing.

### Phase 7: Marketplace sync

```bash
./scripts/sync-marketplace.sh
```

Other Claude Code sessions need `/clear` or restart to pick up the
autoloaded rule changes (no body change to the rule though, just
housekeeping prose — likely no observable effect).

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| PR #6 dependency choice splits the spec into two paths | Certain (by design) | Low | Spec articulates both paths; this plan execution-orders both. Path-A→B fallback is mechanical |
| PR #6 merges *during* the sweep | Low | Low | If path-B was chosen and PR #6 lands mid-sweep, finish path-B; queue a follow-up chore commit migrating to path-A |
| Sweep introduces accidental behavior change in a skill | Low | Medium | Single-line edit per file; review via `git diff --stat` showing exactly +1 line per SKILL.md |
| Compile-drift CI trips because of trailing newlines or quoting | Medium | Low | Run `compile.py` and commit regenerated output in same PR; pre-flight `compile.py --check` |
| Coverage test produces false positive (matches "telemetry.md" in unrelated prose) | Low | Low | Anchor regex to frontmatter line under path-A; for path-B, anchor to literal `@reference core/rules/telemetry.md` |
| Reviewer/test-writer/implementer (sub-agent skills) get the reference but never run as top-level | None | None | Behavior is correct — they emit `skill_invocation.nested` lines. Same contract |
| Frontmatter validator under path-A rejects the new key because PR #6 schema differs from assumption | Low | Medium | Coordinate with PR #6 author on the exact key shape (`references: [<path>]` vs `references:\n  - <path>`); spec accepts either |
| Init skill ships in projects without `.add/` yet | None | None | Parent rule already handles directory creation on first emission; no special-casing |
| Path-B prose-line position drifts across skills | Low | Low | Style guide in plan § 4 Phase 2: first bullet of `## Pre-Flight`. Reviewer enforces |

## 6. Coordination Notes

- **Do not ship before PR #6's `references:` mechanism if path-A is chosen.** If PR #6 stalls, switch to path-B and document the future migration commit. Do not block v0.9.2 on PR #6.
- **Coordinate with future SKILL.md edits.** Any skill author landing changes to a SKILL.md after this sweep must preserve the reference declaration. The coverage test (AC-020) catches drift; CI gates the test.
- **Do not amend `core/rules/telemetry.md`'s contract.** The housekeeping edit (Phase 4) only removes a deferred-action parenthetical. No schema, no semantics, no behavior changes.
- **Order with `auto-changelog`** (if present): record the sweep under "v0.9.2 — Closures" with a one-liner.

## 7. Validation Commands

Final validation block (run before opening PR / committing to `main`):

```bash
# Working dir: repo root
bash tests/telemetry-sweep/test-skill-reference-coverage.sh    # AC-020..022
python3 scripts/validate-frontmatter.py                          # AC-024
python3 scripts/compile.py                                       # regenerate
python3 scripts/compile.py --check                               # AC-023
bash tests/hooks/test-filter-learnings.sh                        # regression

# Spot-check (manual, 30s):
#   In a clean test project with telemetry.enabled = true:
#   $ /add:plan specs/example.md
#   $ tail -1 .add/telemetry/$(date -u +%F).jsonl | jq .
#   Expect: skill="plan", outcome ∈ {success,failed}, valid JSON.
```

All must return exit 0 / clean diff before merge.

## 8. Non-Goals / Deferred

- **Per-skill opt-out.** Project-level `.add/config.json:telemetry.enabled` is the sole opt-out. No per-skill flag.
- **Schema additions.** No new JSONL fields. The sweep is purely declarative.
- **Runtime emitter code.** The rule is the contract. Skills follow it.
- **Backfill.** Forward-looking only.
- **Path-A→B reverse migration tooling.** If PR #6 reverts post-merge, treat as a chore commit; not worth scripting.
- **Windows concurrent-write fallback.** Inherited from parent spec's v0.9.x scope; not in this sweep.

## 9. Done When

- [ ] All 27 `core/skills/*/SKILL.md` carry the chosen reference declaration.
- [ ] `tests/telemetry-sweep/test-skill-reference-coverage.sh` exists and passes.
- [ ] `scripts/validate-frontmatter.py` passes.
- [ ] `scripts/compile.py --check` clean.
- [ ] Spot-test confirms a JSONL line is emitted on a swept skill's invocation.
- [ ] Spec § 7 audit checklist all-swept (or all explained).
- [ ] `core/rules/telemetry.md` housekeeping note removed.
- [ ] Two or more conventional commits pushed (test, sweep, optional housekeeping).
- [ ] Marketplace synced.

## 10. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-26 | 0.1.0 | abrooke + Claude | Initial plan — phasing for path-A and path-B; risk register; validation commands |

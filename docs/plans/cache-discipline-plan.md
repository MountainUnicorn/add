# Implementation Plan: cache-discipline

> Status: Complete (v0.9.0) — superseded by shipped feature.

**Spec:** `specs/cache-discipline.md`
**Target Release:** v0.9.0 (milestone M3-pre-ga-hardening)
**Branch:** `feat/cache-discipline`
**Owner:** Swarm A

## Goal

Codify the stable-prefix layout convention as an auto-loaded rule, ship a validator
that lints SKILL.md files, and remediate the four highest-impact skills so Task-dispatch
prompts share a byte-identical cacheable prefix.

## Files

### New

| Path | Purpose |
|------|---------|
| `core/rules/cache-discipline.md` | Auto-loaded rule defining STABLE/VOLATILE layout invariant (AC-001..006) |
| `scripts/validate-cache-discipline.py` | Python validator scanning SKILL.md files for layout violations (AC-010..015) |
| `tests/cache-discipline/test-cache-discipline.sh` | Fixture-driven bash test runner (AC-016) |
| `tests/cache-discipline/fixtures/compliant.md` | Skill with proper STABLE/VOLATILE markers around a Task dispatch |
| `tests/cache-discipline/fixtures/compliant.expected.txt` | Expected validator output (empty — no findings) |
| `tests/cache-discipline/fixtures/missing-markers.md` | Task dispatch without markers (→ CACHE-001) |
| `tests/cache-discipline/fixtures/missing-markers.expected.txt` | Expected CACHE-001 line |
| `tests/cache-discipline/fixtures/inverted.md` | VOLATILE before STABLE (→ CACHE-002) |
| `tests/cache-discipline/fixtures/inverted.expected.txt` | Expected CACHE-002 line |
| `tests/cache-discipline/fixtures/volatile-in-stable.md` | `{user_message}` placeholder inside STABLE block (→ CACHE-003) |
| `tests/cache-discipline/fixtures/volatile-in-stable.expected.txt` | Expected CACHE-003 line |
| `tests/cache-discipline/fixtures/no-dispatch.md` | Skill without Task dispatch (silent skip, no findings) |
| `tests/cache-discipline/fixtures/no-dispatch.expected.txt` | Empty file |
| `docs/plans/cache-discipline-plan.md` | This file |

### Modified

| Path | Change |
|------|--------|
| `core/rules/agent-coordination.md` | Cross-reference `cache-discipline.md`, require stable-prefix for Task dispatches (AC-017, AC-018) |
| `core/skills/tdd-cycle/SKILL.md` | Wrap sub-agent dispatch emission block with STABLE/VOLATILE markers (AC-008, AC-020) |
| `core/skills/implementer/SKILL.md` | Audit result: no Task dispatch → no markers needed; add CACHE convention comment (AC-020) |
| `core/skills/reviewer/SKILL.md` | Audit result: no Task dispatch → no markers needed; add CACHE convention comment (AC-020) |
| `core/skills/verify/SKILL.md` | Audit result: no Task dispatch → no markers needed; add CACHE convention comment (AC-020) |
| `specs/cache-discipline.md` | Populate § 4 audit checklist with concrete findings (AC-019, AC-021) |

## AC Coverage Matrix

| AC | Covered by |
|----|-----------|
| AC-001 | `core/rules/cache-discipline.md` (frontmatter + length check) |
| AC-002 | Rule § Stable Prefix |
| AC-003 | Rule § Volatile Suffix |
| AC-004 | Rule § Layout Invariant |
| AC-005 | Rule § References |
| AC-006 | Rule § Scope (no token budgets) |
| AC-007 | Rule § Markers + tdd-cycle remediation |
| AC-008 | tdd-cycle SKILL.md remediation |
| AC-009 | Rule § Markers are HTML comments |
| AC-010 | `scripts/validate-cache-discipline.py` + chmod +x |
| AC-011 | Validator walks `core/skills/*/SKILL.md` plus CLI args |
| AC-012 | Validator detects CACHE-001/002/003 |
| AC-013 | Validator output format `{file}:{line}: {sev}: {rule-id}: {msg}` |
| AC-014 | Warn-only default: exit 0 even with findings |
| AC-015 | `--strict` flag flips to exit 1 on any finding |
| AC-016 | Fixture suite + runner |
| AC-017 | `agent-coordination.md` new section cross-ref |
| AC-018 | Same section enumerates sub-agents requiring byte-identical prefix |
| AC-019 | Spec § 4 audit checklist populated for ALL 25 skills |
| AC-020 | tdd-cycle remediated; implementer/reviewer/verify documented non-dispatching |
| AC-021 | Remaining skills get rows with target v0.9.x |
| AC-022 | Deferred — noted in rule's Telemetry section + spec audit row (Swarm F) |
| AC-023 | Same deferral |
| AC-024 | Same deferral |

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Validator false-positive on prose references to "Task tool" | Medium | Low — warn-only in v0.9 | Document regex + allow targeted suppression via `<!-- cache-discipline: skip -->` if needed later |
| Compile-drift CI trips because STABLE/VOLATILE HTML comments propagate into `plugins/add/` | Low | Medium | Run `python3 scripts/compile.py` after edits; comments are preserved verbatim. Verify with `compile.py --check`. |
| Four-skill audit finds implementer/reviewer/verify actually need markers (i.e., they DO dispatch) | Low | Medium | Current grep shows only tdd-cycle has Task in allowed-tools. Documented in audit. |
| Frontmatter schema rejects new rule (missing required field) | Low | Low | Copy shape from `learning.md` / `tdd-enforcement.md`: `autoload: true`, `maturity: beta`. |
| Fixture runner diff output format differs between GNU/BSD `diff` | Low | Low | Use `diff -u` with clear output; exit code suffices. |
| Telemetry section of rule conflicts with Swarm F's `telemetry.md` rule | Low | Low | Rule only *references* telemetry fields; does not create shared files. |

## Execution Order

1. Branch: `feat/cache-discipline` (done).
2. RED: Write fixtures + `expected.txt` files + runner. Runner fails (validator does not exist).
3. GREEN: Write validator script. Runner passes.
4. Write rule `core/rules/cache-discipline.md` (≤ 80 lines).
5. Update `agent-coordination.md` cross-reference (minimal diff).
6. Audit + remediate tdd-cycle SKILL.md (wrap dispatch prompt emission with markers).
7. Add CACHE convention comment to implementer/reviewer/verify (AC-020 documentation even without markers).
8. Populate spec § 4 checklist with full 25-skill audit.
9. Compile: `python3 scripts/compile.py` → regenerate plugins/add/ + dist/codex/.
10. Verify: frontmatter validator, compile --check, test-filter-learnings, our new test suite, validator self-test.
11. Commit (2–4 conventional commits), push, open PR.

## Non-Goals / Deferred

- Telemetry field wiring (AC-022..024) — requires Swarm F's telemetry-jsonl rule/template to land first; post-merge follow-up commit.
- Strict-mode CI enforcement — deferred to v1.0 per spec § 8.
- Remediating all 25 skills — only 4 in v0.9, rest marked v0.9.x.

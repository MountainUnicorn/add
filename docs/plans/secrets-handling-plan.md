# Plan: Secrets Handling

> Status: Complete (v0.9.0) — superseded by shipped feature.

**Spec:** specs/secrets-handling.md
**Created:** 2026-04-22
**Estimated Effort:** Small (1-1.5 days)
**Status:** In Progress
**Milestone:** M3-pre-ga-hardening
**Target Release:** v0.9.0
**Swarm:** B (parallel with Swarm A cache-discipline, Swarm C agents-md-sync)

## 1. Overview

Ship ADD's accidental-disclosure defense: an auto-loaded rule forbidding reads of
well-known secret paths and writes of secret-shaped values into ADD storage, a
`.secretsignore` template, a pre-commit grep gate wired into `/add:deploy`, and
a shared regex catalog used by all three surfaces. The prompt-injection-defense
spec (Swarm D, later) shares `core/knowledge/threat-model.md`; since this spec
lands first in Cycle 1, Swarm B owns the scaffold for that file.

This plan covers the runtime-neutral source changes in `core/`. `scripts/compile.py`
regenerates `plugins/add/` and `dist/codex/` automatically — no edits to generated output.

## 2. Files Created

| Path | Purpose |
|------|---------|
| `core/rules/secrets-handling.md` | Auto-loaded rule — read-deny paths, write-redact, catalog pointer, boundary statement. Alpha+ maturity. |
| `core/knowledge/secret-patterns.md` | Single-source regex catalog consumed by the rule, the deploy gate, and the learning redactor (AC-008). |
| `core/knowledge/threat-model.md` | Scaffold — attack surface, threat categories, mitigations. Has a "Secrets Disclosure" section per AC-022. Prompt-injection-defense will extend it. |
| `core/templates/.secretsignore.template` | Gitignore-syntax pattern file installed by `/add:init` (AC-009, AC-010). |
| `tests/secrets-handling/test-secrets-handling.sh` | Fixture-based regex-catalog validation — positive samples per pattern, negatives on safe content (AC-023). |
| `tests/secrets-handling/fixtures/*` | Positive and negative fixture files. |
| `docs/plans/secrets-handling-plan.md` | This file. |

## 3. Files Modified

| Path | Change |
|------|--------|
| `core/skills/deploy/SKILL.md` | Add `## Pre-commit secrets gate` section before Step 2 (Prepare Commit Message) with scan invocation, abort rules, `--allow-secret` confirmation phrase, and `.secretsignore` handling. |

## 4. AC Coverage Matrix

| AC | Covered by |
|----|------------|
| AC-001 | `core/rules/secrets-handling.md` (autoload: true, maturity: alpha, <80 lines) |
| AC-002 | Rule § Read-deny paths |
| AC-003 | Rule § Write-redact invariant |
| AC-004 | Rule § Redact-on-ingest |
| AC-005 | Rule § Boundary (explicit citation of Claude Code permission system) |
| AC-006 | `core/knowledge/secret-patterns.md` § Catalog (all 8 patterns enumerated) |
| AC-007 | `core/knowledge/secret-patterns.md` § High-entropy heuristic (Shannon > 4.5 bits/char, len ≥ 32, safe-context suppression) |
| AC-008 | Single file `core/knowledge/secret-patterns.md`; rule, deploy gate, and redactor all reference it |
| AC-009 | `core/templates/.secretsignore.template` uses gitignore syntax |
| AC-010 | Template covers all enumerated paths |
| AC-011 | Rule documents `/add:init` contract (never overwrite); `/add:init` SKILL.md already loads from `core/templates/` |
| AC-012 | Rule documents the one-line notice wording |
| AC-013 | `core/skills/deploy/SKILL.md` § Pre-commit secrets gate — `git diff --cached` scan |
| AC-014 | Deploy gate section cites `core/knowledge/secret-patterns.md` |
| AC-015 | Deploy gate abort output format (path, line, pattern name, remediation) |
| AC-016 | `--allow-secret` flag + confirmation phrase "I have verified this is not a real secret" (case-sensitive, exact) |
| AC-017 | `.add/observations.md` append spec |
| AC-018 | `.secretsignore` honoring + "should not be committed" flag |
| AC-019 | Rule § Write-redact calls back to learning.md's existing PII heuristic — extends by referencing the shared catalog. (Full learning.md edit deferred to coordination with PR #6 per spec Dependencies; this PR documents the extension point but does not edit `learning.md` to avoid merge conflict with PR #6.) |
| AC-020 | Rule § Write-redact applies to handoff, retros, dashboard |
| AC-021 | Rule documents `.add/redaction-log.json` format |
| AC-022 | `core/knowledge/threat-model.md` has "Secrets Disclosure" section |
| AC-023 | `tests/secrets-handling/` fixture suite — positive per pattern, negative per safe type |
| AC-024 | Negative fixtures include lockfile-style SHA hashes |

## 5. Deliberate Deferrals

- **AC-019 code change in `core/rules/learning.md`**: The spec's Dependencies section notes "coordinate with PR #6 if it lands first." PR #6 is touching on-demand loading in a way that will likely conflict with in-place edits to `learning.md`. This PR documents the extension contract in the new secrets-handling rule and leaves the learning.md edit for a follow-up after PR #6 lands. The PII heuristic in `learning.md` already fires on most of the same patterns (AKIA, ghp_, JWT, PEM) — this is not a regression, just incomplete sharing of the single-source catalog.

## 6. Execution Order

1. Scaffold `core/knowledge/threat-model.md`
2. Write `core/knowledge/secret-patterns.md`
3. Write `core/rules/secrets-handling.md`
4. Write `core/templates/.secretsignore.template`
5. Create fixture tree under `tests/secrets-handling/`
6. Add `## Pre-commit secrets gate` section to `core/skills/deploy/SKILL.md`
7. Verify: `compile.py`, `validate-frontmatter.py`, `compile.py --check`, existing hook test, new fixture test
8. Commit (3 commits — see PR plan)
9. Push + PR

## 7. Verification Checklist

- [ ] `python3 scripts/compile.py` regenerates cleanly
- [ ] `python3 scripts/validate-frontmatter.py` passes
- [ ] `python3 scripts/compile.py --check` passes (no drift)
- [ ] `bash tests/hooks/test-filter-learnings.sh` passes (regression)
- [ ] `bash tests/secrets-handling/test-secrets-handling.sh` passes
- [ ] New rule < 80 lines (AC-001)
- [ ] All Must-priority ACs satisfied or explicitly deferred with rationale

# Plan: jq Dependency Declaration

> Status: Complete (v0.9.3) — superseded by shipped feature.

**Spec:** specs/jq-dependency-declaration.md
**Created:** 2026-04-26
**Estimated Effort:** Tiny (~half a day)
**Status:** Draft
**Milestone:** none
**Target Release:** v0.9.2
**Strategy:** A — declare jq as a documented runtime dependency (no hook code changes)

## 1. Overview

F-017 from the plugin-family release-hardening review surfaced that ADD's "zero runtime dependencies" claim is technically inaccurate: hook scripts shipped since v0.7 invoke `jq`. This plan executes Strategy A from the spec — qualify the claim across user-facing materials, document jq install paths and per-hook degradation in a new `docs/runtime-dependencies.md` page, and add a CI guard preventing regression of the bare phrase. No hook code changes.

This is a documentation-only change. `core/` is the source of truth, but no compile artifacts need to regenerate because the only `core/` touch is an optional one-line jq-presence hint in the init skill (AC-012, Should).

## 2. Files Created

| Path | Purpose |
|------|---------|
| `docs/runtime-dependencies.md` | New canonical doc — why jq, install commands per OS (macOS, Debian/Ubuntu, Fedora/RHEL, Arch, Alpine, Windows Chocolatey + scoop), audit table reproduced from spec §1, verification one-liner (AC-006). |
| `docs/plans/jq-dependency-declaration-plan.md` | This file. |

## 3. Files Modified

| Path | Change | AC |
|------|--------|----|
| `README.md` | Line 91 — replace "zero runtime dependencies" with qualified phrasing; add link to `docs/runtime-dependencies.md`. | AC-001, AC-007 |
| `CONTRIBUTING.md` | Line 3 — remove "zero dependencies"; mention `jq` requirement for fixture tests; link to install doc. | AC-002, AC-007 |
| `docs/prd.md` | Lines 74 and 508 — qualify each "no runtime dependencies" mention with "agent-side" scope and link to install doc. | AC-003, AC-004, AC-007 |
| `.claude-plugin/marketplace.json` | Line 13 description — remove the "zero dependencies" tail; reference the install doc path verbatim (not clickable, but discoverable). | AC-005, AC-007 |
| `.github/workflows/guardrails.yml` | Add a new "Dependency-claim guard" job/step that greps for unqualified `zero (runtime )?dependencies` in `README.md`, `CONTRIBUTING.md`, `docs/prd.md`, `.claude-plugin/marketplace.json`. Excludes `docs/milestones/`, `CHANGELOG.md`, `specs/`, `docs/plans/`. | AC-011 |
| `runtimes/claude/CLAUDE.md` (optional) | Mention jq dependency in install / quick-start area. | AC-012 |
| `core/skills/init/SKILL.md` (optional) | Add a `command -v jq` presence check during init; if missing, print a warning citing `docs/runtime-dependencies.md`. | AC-012 |

**Files deliberately untouched** (per AC-008, AC-009, AC-010):

- `docs/milestones/M1-core-plugin.md:75` — historical milestone record.
- `CHANGELOG.md` (entries prior to v0.9.2) — historical.
- `specs/plugin-installation-reliability.md:237` — historical context inside an existing spec.
- `plugins/add/**` and `dist/codex/**` — generated; `compile.py` regenerates if `core/skills/init/SKILL.md` is touched (AC-012 path).

## 4. AC Coverage Matrix

| AC | Priority | Covered by |
|----|----------|------------|
| AC-001 | Must | `README.md:91` rewrite + link |
| AC-002 | Must | `CONTRIBUTING.md:3` rewrite + link |
| AC-003 | Must | `docs/prd.md:74` qualifier |
| AC-004 | Must | `docs/prd.md:508` qualifier |
| AC-005 | Must | `.claude-plugin/marketplace.json:13` description update |
| AC-006 | Must | New `docs/runtime-dependencies.md` |
| AC-007 | Must | Each of the four claim-site edits links/references the new doc |
| AC-008 | Must | `docs/milestones/M1-core-plugin.md` left unchanged; verified via diff inspection |
| AC-009 | Must | `CHANGELOG.md` historical entries left unchanged |
| AC-010 | Must | `specs/plugin-installation-reliability.md:237` left unchanged |
| AC-011 | Should | New step in `.github/workflows/guardrails.yml` |
| AC-012 | Should | `runtimes/claude/CLAUDE.md` and/or `core/skills/init/SKILL.md` jq mention |

## 5. Audit Task List

One row per jq invocation site. Each row's "Action" is verified, not changed — the spec's Strategy A explicitly leaves hook code alone. The audit's purpose is to ensure the new `docs/runtime-dependencies.md` describes the current behavior accurately.

| # | Site | Lines | Current behavior when jq absent | Documented in `docs/runtime-dependencies.md`? |
|---|------|-------|----------------------------------|------------------------------------------------|
| 1 | `runtimes/claude/hooks/post-write.sh` | 14, 30 | Hard-fail at line 14; line 30 unreachable. | Yes — listed as "known sharp edge: install jq before use." |
| 2 | `runtimes/claude/hooks/filter-learnings.sh` | 17, 21, 33, 43, 53, 58, 59, 60 | Soft-fail by guard at line 17 — `learnings-active.md` not regenerated; agent reads `learnings.json` directly (v0.8 fallback chain). | Yes — listed as "soft fail; reduced functionality only." |
| 3 | `runtimes/claude/hooks/posttooluse-scan.sh` | 23, 30, 35, 49, 111, 124, 132, 142, 191, 209, 285 | Soft-fail by guard at line 23 — secrets/injection scanner no-ops. | Yes — listed as "soft fail; defense-in-depth scan disabled." |
| 4 | `core/lib/impact-hint.sh` | 133, 138 | Soft-fail by inline `command -v jq` check; falls through to generic impact message. | Yes — listed as "soft fail; learnings-aware impact hint downgraded to generic." |
| 5 | `runtimes/claude/hooks/hooks.json` | 54 (inline command) | Hard-fail — inline `CMD=$(jq -r ...)` with no guard; PreToolUse Bash hook errors when user runs `git push`. | Yes — listed as "known sharp edge; the changelog nudge fails noisily." |
| 6 | `runtimes/codex/hooks/*.sh` | n/a | No jq usage today (verified via `grep -l "jq" runtimes/codex/hooks/*.sh` returning empty). | Yes — explicitly noted: "Codex runtime hooks do not currently require jq." |

## 6. Execution Order

1. Read `README.md`, `CONTRIBUTING.md`, `docs/prd.md`, `.claude-plugin/marketplace.json` to confirm audit-table line numbers still match HEAD.
2. Re-run `grep -l "jq" runtimes/codex/hooks/*.sh` — expect empty.
3. Draft `docs/runtime-dependencies.md` (per-OS install matrix, audit table, verification one-liner).
4. Edit `README.md:91` — qualified prose + link.
5. Edit `CONTRIBUTING.md:3` — qualified prose + link.
6. Edit `docs/prd.md:74` and `:508` — qualified prose + link.
7. Edit `.claude-plugin/marketplace.json:13` — drop "zero dependencies" tail.
8. Add the dependency-claim CI guard step to `.github/workflows/guardrails.yml`.
9. (Optional, AC-012) Add jq mention to `runtimes/claude/CLAUDE.md` install section and a soft warning to `core/skills/init/SKILL.md`.
10. If step 9 was taken: `python3 scripts/compile.py` to regenerate Claude plugin output.
11. Run validation commands (see §7).
12. Commit (one commit; doc-only change, no spec/code split needed).
13. Push to `main`.
14. `./scripts/sync-marketplace.sh` so other Claude Code sessions pick up the init skill change (only if AC-012 was taken).

## 7. Validation Commands

```bash
# Confirm the bare claim is no longer present in any non-historical file
! grep -nE "zero (runtime )?dependencies" \
    README.md CONTRIBUTING.md docs/prd.md .claude-plugin/marketplace.json

# Confirm the new install doc exists and is reachable from each claim site
test -f docs/runtime-dependencies.md
grep -l "runtime-dependencies.md" \
  README.md CONTRIBUTING.md docs/prd.md .claude-plugin/marketplace.json

# Confirm historical text is preserved untouched
grep -n "zero runtime dependencies" docs/milestones/M1-core-plugin.md  # expect line 75
grep -n "zero dependencies"          specs/plugin-installation-reliability.md  # expect line 237

# CI guard local reproducer
bash -c '! grep -nE "zero (runtime )?dependencies" \
  README.md CONTRIBUTING.md docs/prd.md .claude-plugin/marketplace.json'

# Standard ADD validation chain (only required if AC-012 touched core/skills/init/)
python3 scripts/compile.py
python3 scripts/validate-frontmatter.py
python3 scripts/compile.py --check
bash tests/hooks/test-filter-learnings.sh
```

## 8. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Marketing-tone regression — qualified phrasing reads more cumbersome than the original "zero dependencies" tagline | Medium | Low | Spec emphasizes honesty over brevity; phrasing kept tight ("zero agent-side runtime dependencies; jq required for hooks"). Marketing site (`MountainUnicorn/getadd.dev`) is a separate repo and tracks this change in a follow-up. |
| Future contributor reverts the qualifier without realizing why | Medium | Medium | CI guard (AC-011) blocks the regression. |
| CI guard false-positives on legitimate use of "zero dependencies" in a new context | Low | Low | The guard scopes to four specific files; new contexts (e.g., a future spec) are exempt by path. |
| AC-012 (init-skill jq check) prints during `/add:init` even when the user has jq installed via a non-PATH method (e.g., a Nix flake) | Low | Low | Use `command -v jq`, not a hard-coded path. If the binary is reachable, no warning. |
| Historical text accidentally edited because line numbers shift after the qualifier insertion | Low | Low | Edits use `Edit` tool with explicit `old_string`/`new_string`; verification commands (§7) explicitly re-grep the historical files to confirm preservation. |
| `marketplace.json` becomes valid but ugly after dropping the trailing clause | Low | Cosmetic | Acceptable — the install doc is authoritative. Re-flow the description in a future tagline pass if needed. |

## 9. Deliberate Deferrals

- **Strategy B implementation.** Soft-fail wrappers around every jq call are deliberately out of scope. Captured in spec §10 (Non-Goals) and §11 (Open Questions).
- **Hardening the two hard-fail sites** (`post-write.sh:14`, `hooks.json:54`) into soft-fail. Documented as "known sharp edges" in `docs/runtime-dependencies.md`. If maintainer flips Strategy A → B later, this is the natural follow-up spec.
- **Marketing site (`getadd.dev`) prose update.** Separate repo (`MountainUnicorn/getadd.dev`); will be tracked there as a one-line follow-up after this spec lands.
- **Markdown link-checker CI.** Out of scope; TC-005 remains a manual check in v0.9.2.

## 10. Pull Request Plan

Single PR titled `docs(F-017): declare jq as a documented runtime dependency`.

Body summary:
- Resolves F-017 from the plugin-family release-hardening review.
- Strategy A (declare honestly) over B (universal soft-fail).
- New `docs/runtime-dependencies.md`; qualified prose in README, CONTRIBUTING, PRD, marketplace.json.
- CI guard prevents regression.
- Historical text preserved per AC-008/AC-009/AC-010.
- No hook code changed.

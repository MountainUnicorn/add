# Spec: jq Dependency Declaration

**Version:** 0.1.0
**Created:** 2026-04-26
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Release:** v0.9.2
**Milestone:** none
**Depends-on:** none

## 1. Overview

ADD's user-facing materials repeatedly claim "zero runtime dependencies" / "pure markdown and JSON, no build step." The plugin-family release-hardening review surfaced this as **F-017**: the claim is technically incorrect. Several runtime hook scripts shipped in v0.7+ shell out to `jq`, a tool not universally pre-installed. macOS and most Linux distributions require `brew install jq` or `apt install jq` before these hooks succeed; on a system without `jq`, the hooks either silently no-op (where guarded) or — on `post-write.sh` — fail and propagate noise into the agent transcript.

Sites where the unqualified claim currently appears:

- `README.md:91` — "ADD has **zero runtime dependencies** and **no build step** on the consumer side — it's pure markdown and JSON."
- `CONTRIBUTING.md:3` — "with zero dependencies. Contributions are welcome — no CLA required."
- `docs/prd.md:74` — "Pure markdown + JSON (no compiled code, no runtime dependencies)"
- `docs/prd.md:508` — "Code-free design: No compiled code, no runtime dependencies, pure markdown + JSON"
- `.claude-plugin/marketplace.json:13` — description ends with "Multi-runtime (Claude Code + Codex CLI), zero dependencies."

Audit of jq usage sites (current behavior when jq is absent):

| # | Path | Role | What jq does | Behavior when jq absent (today) |
|---|------|------|--------------|----------------------------------|
| 1 | `runtimes/claude/hooks/post-write.sh:14` | PostToolUse Write/Edit dispatcher | Parse `tool_input.file_path` from hook payload | **Hard fail** — `set -euo pipefail` causes the script to exit non-zero; the hook then emits a `command not found` error into the Claude transcript on every Write/Edit. |
| 2 | `runtimes/claude/hooks/post-write.sh:30` | Read `learnings.active_cap` from `.add/config.json` | Suppressed via `2>/dev/null \|\| true`; falls through to default `MAX=15` | Soft fail — if the script reaches this line. (It does not, because line 14 already failed.) |
| 3 | `runtimes/claude/hooks/filter-learnings.sh:17` | Active-learnings view generator | Guarded: `command -v jq >/dev/null 2>&1 \|\| exit 0` | Soft fail by design — hook exits 0; `learnings-active.md` is not regenerated; agent reads canonical `learnings.json` instead (documented v0.8 fallback chain). |
| 4 | `runtimes/claude/hooks/posttooluse-scan.sh:23` | Secrets / prompt-injection PostToolUse scanner | Guarded: `command -v jq >/dev/null 2>&1 \|\| exit 0` | Soft fail — scanner no-ops; agent loses defense-in-depth scan. |
| 5 | `core/lib/impact-hint.sh:133` | Test-deletion guardrail learnings lookup | Guarded inline: `command -v jq >/dev/null 2>&1` block is skipped when missing | Soft fail — generic impact message instead of specific learning citation. |
| 6 | `runtimes/claude/hooks/hooks.json:54` | Inline pre-push CHANGELOG nudge (PreToolUse Bash) | Parses `tool_input.command` from payload | **Hard fail** — inline `CMD=$(jq ...)` with no guard; hook errors when user invokes git push and jq is missing. |

Codex runtime hooks (`runtimes/codex/hooks/*.sh`) do not currently invoke `jq` — verified by grep. Codex consumers therefore have no jq requirement today, but parity with the Claude runtime is the long-run intent and any future Codex hook should be designed in the same posture.

This spec resolves F-017 by **picking Strategy A**: declare jq as a documented runtime dependency. The "zero runtime dependencies" framing is qualified across README, CONTRIBUTING, PRD, and marketplace metadata to read "zero runtime dependencies on the agent/LLM side; `jq` required for hook scripts." A new `docs/runtime-dependencies.md` page documents the install commands per OS and the degradation behavior of each hook when jq is absent. No hook code is changed.

### Strategy choice: A over B

**Strategy A — Declare jq honestly.** Update prose, document install paths. No code change. Honest. Single-source documentation for what the hooks actually need.

**Strategy B — Make every jq call soft-fail.** Wrap each hook's jq invocation in a guard that prints a warning and exits 0. README claim stays intact, but the agent's autonomous behavior silently degrades when jq is missing — `learnings-active.md` stops regenerating, the secrets scanner stops scanning, the changelog nudge stops nudging — and the user has no signal until a downstream symptom appears.

**Recommendation: A.** The "zero dependencies" claim was accurate in the v0.5 era when no hook invoked jq; it drifted in v0.7 when JSON-payload PostToolUse hooks landed and was never updated. Honesty over preserving an inaccurate marketing claim. Soft-fail (B) is strictly worse from a user trust standpoint — silent degradation surprises users; an explicit dependency in install docs sets correct expectations once. (B remains a valid alternative if the maintainer disagrees; this spec lists it under Open Questions.)

### User Story

As an ADD user installing the plugin on a fresh macOS or Linux machine, I want the README to tell me up front that `jq` is required for the hook scripts and how to install it, so that I do not silently lose hook functionality or get a confusing "command not found" error in my transcript on the first Write event.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `README.md:91` is rewritten to qualify the claim. The new wording explicitly states `jq` is required for hook scripts and includes install commands for macOS (`brew install jq`) and Debian/Ubuntu (`apt install jq`). | Must |
| AC-002 | `CONTRIBUTING.md:3` is rewritten to remove the unqualified "zero dependencies" claim. Replacement wording calls out the `jq` requirement for running fixture tests locally. | Must |
| AC-003 | `docs/prd.md:74` is qualified — replace "no runtime dependencies" with "no agent-side runtime dependencies; `jq` required for hook scripts (see `docs/runtime-dependencies.md`)." | Must |
| AC-004 | `docs/prd.md:508` is qualified with the same scope language as AC-003. | Must |
| AC-005 | `.claude-plugin/marketplace.json:13` description is updated. The phrase "zero dependencies" is removed; the description retains the "Multi-runtime (Claude Code + Codex CLI)" framing without the dependency claim. | Must |
| AC-006 | A new file `docs/runtime-dependencies.md` is created. It documents: (a) why jq is required, (b) install commands for macOS, Debian/Ubuntu, Fedora/RHEL, Arch, Alpine, Windows (Chocolatey + scoop), (c) the audit table from this spec's Overview section reproduced as the canonical "what degrades when jq is absent" reference, (d) a one-liner verification command (`command -v jq && jq --version`). | Must |
| AC-007 | Each user-facing site (README, CONTRIBUTING, PRD, marketplace.json) links to or references `docs/runtime-dependencies.md` so a reader can find install help in one click. | Must |
| AC-008 | Historical text in `docs/milestones/M1-core-plugin.md:75` ("zero runtime dependencies") is preserved unchanged — it is a historical milestone record, not a current claim. | Must |
| AC-009 | Historical text in past `CHANGELOG.md` entries (any release prior to v0.9.2) is preserved unchanged. | Must |
| AC-010 | The "zero dependencies, pure markdown/JSON" reference inside `specs/plugin-installation-reliability.md:237` is left alone — that spec captures the framing as it stood at authoring time, and that historical context has documentary value. | Must |
| AC-011 | A CI guard step is added to `.github/workflows/guardrails.yml` that fails the build if the unqualified phrase `zero (runtime )?dependencies` reappears in `README.md`, `CONTRIBUTING.md`, `docs/prd.md`, or `.claude-plugin/marketplace.json`. The guard explicitly excludes `docs/milestones/`, `CHANGELOG.md`, `specs/`, and `docs/plans/` to honor AC-008/AC-009/AC-010. | Should |
| AC-012 | `runtimes/claude/CLAUDE.md` and `core/skills/init/SKILL.md` (or equivalent install-time skill) mention the jq dependency at least once, so a fresh `/add:init` run surfaces the requirement. | Should |

## 3. User Test Cases

### TC-001: Reader finds the qualifier in README

**Precondition:** A new contributor lands on the GitHub README for the first time.
**Steps:**
1. Open `README.md` in browser.
2. Scroll to the "What ADD is" / "Quick start" area where the dependency claim sits (line ~91).
3. Read the dependency framing.
**Expected Result:** The reader sees the qualifier "zero agent-side runtime dependencies; `jq` required for hook scripts" with a link to `docs/runtime-dependencies.md`. No bare "zero runtime dependencies" string remains in the live (non-historical) prose.
**Maps to:** TBD (manual review during spec acceptance)

### TC-002: Install on a system without jq

**Precondition:** A fresh Ubuntu 24.04 container with `jq` deliberately uninstalled (`apt remove jq`). ADD plugin installed via `claude plugin install add@add-marketplace`.
**Steps:**
1. User opens a Claude Code session in a project directory.
2. User runs `/add:init` and answers the prompts.
3. User edits a file via Claude (triggers `post-write.sh`).
4. User checks the Claude Code transcript for any errors.
5. User reads `docs/runtime-dependencies.md` and runs `apt install -y jq`.
6. User repeats step 3.
**Expected Result:** Step 4 either shows a clear error pointing to `docs/runtime-dependencies.md` or — better — the user already saw the dependency notice during `/add:init` (per AC-012) and installed jq before reaching step 3. After step 6, the hook fires successfully. The user is never surprised.
**Maps to:** TBD (manual smoke test before v0.9.2 release)

### TC-003: CI catches a regression of the bare claim

**Precondition:** Branch `experiment/restore-old-readme` reintroduces the literal string "zero runtime dependencies" into `README.md` without a qualifier.
**Steps:**
1. Open a PR from the experiment branch to `main`.
2. CI runs `guardrails.yml`.
3. The new dependency-claim guard step executes.
**Expected Result:** The guard step fails with output indicating `README.md` contains an unqualified "zero runtime dependencies" string. PR is blocked from merging.
**Maps to:** `.github/workflows/guardrails.yml` → "Dependency-claim guard"

### TC-004: Historical text preserved

**Precondition:** v0.9.2 lands and ships the documentation update.
**Steps:**
1. Open `docs/milestones/M1-core-plugin.md` and search for "zero".
2. Open `CHANGELOG.md` and search for "zero".
3. Open `specs/plugin-installation-reliability.md` and search for "zero dependencies".
**Expected Result:** All three files retain their original wording. The CI guard does not flag them (paths are explicitly excluded). The git diff for v0.9.2 touches none of these files.
**Maps to:** `git log v0.9.1..v0.9.2 -- docs/milestones/ CHANGELOG.md specs/plugin-installation-reliability.md` returns empty.

### TC-005: `docs/runtime-dependencies.md` is reachable from every claim site

**Precondition:** v0.9.2 documentation is published.
**Steps:**
1. From `README.md:~91`, follow the link to `docs/runtime-dependencies.md`.
2. From `CONTRIBUTING.md:3`, follow the link.
3. From `docs/prd.md:~74` and `~508`, follow the link.
4. The marketplace.json description references the path verbatim (not a clickable link, but discoverable).
**Expected Result:** Every claim site reaches the new doc in one hop. The doc itself opens with the install commands and the audit table.
**Maps to:** TBD (manual link-check; could be folded into a future markdown-linkcheck CI job)

## 4. Data Model

N/A — pure documentation change.

## 5. API Contract

N/A — no programmatic surface.

## 6. UI Behavior

N/A — documentation only. The CI guard's failure output should be human-readable:

```
Dependency-claim guard failed.
Found unqualified "zero runtime dependencies" in:
  README.md:91
Run: scripts/check-dependency-claims.sh   # local reproducer
See: docs/runtime-dependencies.md         # what the qualified phrasing looks like
```

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Codex CLI hooks gain a jq invocation in the future | New hook MUST also be reflected in `docs/runtime-dependencies.md`; current Codex hooks have no jq requirement and the doc says so explicitly. |
| Windows users (no native `apt`/`brew`) | `docs/runtime-dependencies.md` documents `choco install jq` and `scoop install jq`. WSL users use the Linux path. |
| GitHub Actions runner | Already has `jq` pre-installed on `ubuntu-latest`; the existing `guardrails.yml` `Install jq` step (line 71) is belt-and-suspenders. No change needed. |
| `posttooluse-scan.sh` and `filter-learnings.sh` already soft-fail today | Documented in the audit table. The qualifier framing makes the partial soft-fail behavior explicit instead of hidden. |
| `post-write.sh` and `hooks.json` line 54 hard-fail today | Documented as known sharp edges in `docs/runtime-dependencies.md`. The fix for hard failure is "install jq," not "patch the hook." Patching to soft-fail is Strategy B and out of scope here. |
| User on minimal Alpine container without `apk add jq` | Doc lists `apk add jq`. If the user refuses to install, hooks degrade per the audit table; the agent itself still works (markdown/JSON skills do not need jq). |
| A future contributor edits prose and accidentally restores "zero runtime dependencies" | CI guard (AC-011) catches it on the PR. |
| The marketplace.json string is a single line — re-flowing it to mention dependencies feels clumsy | Acceptable to remove "zero dependencies" entirely from the description rather than replace it; the install doc is the authoritative source. |

## 8. Dependencies

None. Purely declarative documentation + a small CI grep. No runtime code changes, no spec depends on this, this depends on no spec.

## 9. Infrastructure Prerequisites

| Category | Requirement |
|----------|-------------|
| Environment variables | N/A |
| Registry images | N/A |
| Cloud quotas | N/A |
| Network reachability | N/A |
| CI status | `.github/workflows/guardrails.yml` must be runnable (already is) |
| External secrets | N/A |
| Database migrations | N/A |

**Verification before implementation:** Run `grep -n "zero" README.md CONTRIBUTING.md docs/prd.md .claude-plugin/marketplace.json` to confirm the audit table line numbers still match HEAD at implementation time. Reconfirm Codex hooks remain jq-free with `grep -l "jq" runtimes/codex/hooks/*.sh` (expect empty output).

## 10. Non-Goals

- **Do not** rewrite hook scripts to remove the jq dependency. Reimplementing JSON parsing in pure POSIX shell is brittle, ships its own bugs, and is out of scope for a documentation-correctness fix.
- **Do not** make jq optional via universal soft-fail wrappers. That is Strategy B, listed as an alternative in the Overview and the Open Questions, not the chosen path here.
- **Do not** ship a vendored mini-jq binary. Plugin must remain pure markdown/JSON on the agent side; vendoring a binary breaks that invariant and creates a much larger surface to maintain.
- **Do not** add automatic `jq` install logic to `/add:init`. Asking the consumer's shell to run `apt install` or `brew install` without explicit consent is overreach; documenting the dependency is enough.
- **Do not** rewrite historical text in milestones, past CHANGELOG entries, or other specs. AC-008/AC-009/AC-010 explicitly preserve them.
- **Do not** modify generated output in `plugins/add/**` or `dist/codex/**` directly — `compile.py` regenerates these.

## 11. Open Questions

- **Strategy A vs B confirmation.** This spec recommends A. If the maintainer prefers B (preserve the marketing claim, add soft-fail wrappers everywhere), this spec is reframed as the dependency-doc half and a sister spec covers the soft-fail wrappers. Decision needed before plan execution.
- **Should `/add:init` actively check for `jq` on PATH and warn?** Lightweight: one `command -v jq` invocation, one warning line. Pro: catches the issue at install time, before the user hits the post-write hard-fail. Con: scope creep on a doc fix. Lean: yes — it costs ~5 lines and pre-empts TC-002's worst path. Capture as AC-012 (Should).
- **Windows-native fallback?** Many Windows users already run WSL; the WSL path uses `apt install jq`. A Windows-native PowerShell fallback (avoiding jq entirely) would require a separate hook implementation. Out of scope for v0.9.2; revisit if Windows-native consumer demand surfaces.
- **Should the CI guard live in `guardrails.yml` (matrix) or its own workflow?** Lean: a single new step in `guardrails.yml` is enough; not worth a new workflow file.

## 12. Sizing

Tiny. ~Half a day. Roughly: 1 hour to draft `docs/runtime-dependencies.md`, 30 minutes to qualify the four prose sites, 30 minutes to add and tune the CI guard, 30 minutes for the optional `/add:init` hint, 1 hour for review + compile + sync-marketplace.

## 13. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-26 | 0.1.0 | abrooke + Claude | Initial spec — F-017 resolution; picks Strategy A; documents jq audit across 6 sites. |

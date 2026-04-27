# Spec: Post-Release Publication Skill

**Version:** 0.1.0
**Created:** 2026-04-27
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Release:** v0.10.0
**Milestone:** none (standalone v0.10 candidate; could roll into M4 if scoping allows)
**Depends-on:** `docs/release-materials.md` (canonical checklist source-of-truth)

## 1. Overview

`./scripts/release.sh vX.Y.Z` handles the cryptographic release boundary: tag, sign, push, GitHub release. Everything that happens AFTER — the README counts, the website blog post, the social-preview re-upload, the contributor acknowledgments, the worktree pruning — is currently manual, scattered across maintainer memory, and varies in completeness from release to release.

We've shipped four releases this week (v0.8.1, v0.9.0, v0.9.1, v0.9.2, v0.9.3, v0.9.4). At each one, post-release work was partial: stale counts were caught after-the-fact (v0.9.1 rule-parity drift, v0.9.3 social-preview cleanup), the migration manifest silently skipped five releases without notice (the v0.9.4 hotfix), the website blog cadence is uneven, and contributor acknowledgments are best-effort.

This spec turns post-release work from "what the maintainer remembers" into "a checklist file the project owns" plus "a skill that walks it." The skill is `/add:post-release`. The canonical checklist is `docs/release-materials.md` — that file already exists as part of this spec's deliverable; the skill consumes it.

### User Story

As an ADD maintainer who just tagged `vX.Y.Z`, I want to run `/add:post-release vX.Y.Z` and have the agent walk every applicable item from `docs/release-materials.md` — checking the auto-verifiable ones, prompting me through the manual ones, and producing a session log — so that no release ships with stale counts, missing blog posts, or unacknowledged contributors, and so that the time between tag and full publication shrinks from "drifts for days" to "complete in one focused pass."

## 2. Acceptance Criteria

### A. Canonical checklist file

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `docs/release-materials.md` exists, is committed to the repo, and uses the format conventions documented in its own header (markdown checkboxes `- [ ]`, four sections A/B/C/D, structured per-item bullets for Files / Automation / Why). | Must |
| AC-002 | Every item in the file has an explicit Automation marker: `auto`, `semi-auto`, or `manual`. The skill uses this to decide whether to act, prompt, or wait for the human. | Must |
| AC-003 | The file ends with a release-type matrix (Hotfix / Patch / Minor / Major / Community) telling readers which sections apply to which release shape. The skill reads this matrix to scope the run. | Must |
| AC-004 | Items can be added or modified without breaking the skill — the format is forgiving, not rigid. New checkboxes appear in the next run automatically. | Must |
| AC-005 | The file documents itself: a "Format conventions" section at the top tells future maintainers how to add new items. | Should |

### B. `/add:post-release` skill

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-010 | New skill at `core/skills/post-release/SKILL.md`. Frontmatter follows the existing skill convention (`description`, `argument-hint: "vX.Y.Z [--type hotfix|patch|minor|major|community]"`, `allowed-tools`, `references: [docs/release-materials.md, rules/telemetry.md]`). | Must |
| AC-011 | The skill takes one positional argument: the release tag (e.g., `v0.9.4`). It auto-detects the release type from the version delta against the previous tag (X.Y.Z+1 = patch, X.Y+1.0 = minor, etc.) but accepts `--type` to override. | Must |
| AC-012 | The skill reads `docs/release-materials.md`, parses the four sections A–D plus the matrix, filters items by release type, and walks them top-down. | Must |
| AC-013 | For `auto` items, the skill executes the documented command (e.g., `git tag --verify`, `gh run list`) and reports pass/fail without prompting. | Must |
| AC-014 | For `semi-auto` items, the skill executes the documented command after a one-line confirmation prompt (`run X? [Y/n]`). | Must |
| AC-015 | For `manual` items, the skill summarizes what's needed, identifies the file paths that need editing, and pauses for the maintainer to do the work; a `done` keyword resumes. | Must |
| AC-016 | The skill writes a session log at `.add/post-release-logs/release-vX.Y.Z.md` — one line per item with status (`done` / `skipped` / `deferred`) and timestamp. | Must |
| AC-017 | If an item fails (a script returns non-zero, a check finds drift), the skill does not auto-block the rest — it logs the failure and continues, then summarizes failures at the end. | Must |
| AC-018 | The skill is idempotent: running it twice in the same release reads the prior session log and shows "already done" for completed items, prompting only for the remainder. | Should |
| AC-019 | Cross-runtime: works on Claude Code (canonical) and via the Codex prompt path (`/add-post-release` per existing convention). | Must |
| AC-020 | The skill's pre-flight emits a telemetry JSONL line per `core/rules/telemetry.md`. | Should |

### C. Cycle integration

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-030 | The post-release work is recordable as a `.add/cycles/cycle-{N}.md` artifact via `/add:cycle`. The cycle name convention: `cycle-postrelease-vX.Y.Z`. | Should |
| AC-031 | Failed items in the session log become candidate carry-forward items for the next cycle. | Should |
| AC-032 | The skill optionally calls `/add:retro --release vX.Y.Z` at the end to capture any process learnings. | Could |

### D. Documentation + dog-fooding

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-040 | This spec ships with the v0.10.0 release that includes the skill itself. Spec status flips Draft → Implementing → Complete on each phase. | Must |
| AC-041 | `docs/release-materials.md` is dog-fooded on its own release: the post-release work for v0.10.0 IS this skill running against itself. | Should |
| AC-042 | The Version Bump Checklist in maintainer memory references this spec + the release-materials.md as the canonical post-release flow. | Must |
| AC-043 | An entry is added to `core/knowledge/global.md` (or equivalent Tier-1 knowledge) noting that "post-release work is gated by `docs/release-materials.md`." | Could |

## 3. User Test Cases

### TC-001: Skill walks an automated-only release cleanly

**Precondition:** `v0.9.5` was just tagged. `docs/release-materials.md` exists. `.add/post-release-logs/release-v0.9.5.md` does not yet exist.
**Steps:**
1. Run `/add:post-release v0.9.5`
2. Skill auto-detects release type (patch — Z bump only)
3. Skill walks Section A (GitHub & repo hygiene), Section B (README), and applicable D (contributors).
4. Auto items run; semi-auto items prompt; manual items pause + summarize.
5. The maintainer answers prompts until completion.
**Expected Result:** Session log written at `.add/post-release-logs/release-v0.9.5.md` with one line per attempted item. All Must items either `done` or `deferred` with reason. Skill exits 0.
**Maps to:** AC-012, AC-013, AC-014, AC-015, AC-016

### TC-002: Idempotent re-run

**Precondition:** TC-001 completed. Some items deferred.
**Steps:**
1. Run `/add:post-release v0.9.5` again
2. Skill reads the session log, identifies completed items, skips them
3. Resumes from the first deferred item
**Expected Result:** Skill runs only the deferred items; previously-done items are reported as "already done"; final session log shows updated statuses.
**Maps to:** AC-018

### TC-003: Release-type filtering

**Precondition:** v0.10.0 (minor) tagged. v0.9.5 (patch) also tagged.
**Steps:**
1. Run `/add:post-release v0.10.0` — auto-detects minor; runs all matrix-applicable items including blog post + social preview + infographic
2. Run `/add:post-release v0.9.5` — auto-detects patch; skips blog post + infographic + (most) social preview items
**Expected Result:** Each session log contains only the items the matrix says apply to that release type.
**Maps to:** AC-011, AC-012

### TC-004: Override release type

**Precondition:** v0.9.5 was tagged but actually contains a material new feature that warrants a blog post.
**Steps:**
1. Run `/add:post-release v0.9.5 --type minor`
2. Skill respects the override, runs all minor-applicable items
**Expected Result:** Session log scopes to minor-applicable items despite the version-delta auto-detection saying patch.
**Maps to:** AC-011

### TC-005: Failed item doesn't block rest

**Precondition:** A semi-auto item (e.g., `./scripts/sync-marketplace.sh`) returns non-zero because rsync isn't installed.
**Steps:**
1. Skill encounters the failure
2. Logs it as `failed: rsync not installed`
3. Continues to the next item
**Expected Result:** Session log shows the failure; subsequent items run; final summary lists failures separately.
**Maps to:** AC-017

### TC-006: Schema-friendly format additions

**Precondition:** A maintainer adds a new item to Section B (README & guides) — say, "Update LICENSE year if Jan 1 has passed."
**Steps:**
1. Add the item to `docs/release-materials.md` following the format
2. Run `/add:post-release v0.9.6`
**Expected Result:** New item appears in the walk without code changes.
**Maps to:** AC-004

### TC-007: Cross-runtime parity

**Precondition:** Codex CLI installed; `/add-post-release` available.
**Steps:**
1. Run `/add-post-release v0.9.5` from Codex
**Expected Result:** Same walk, same log location (within the user's repo, not in `~/.codex`), same outputs.
**Maps to:** AC-019

## 4. Data Model

### Session log schema

Each session log is a markdown file at `.add/post-release-logs/release-vX.Y.Z.md`. Format (skill-readable, human-readable):

```markdown
# Post-release log — vX.Y.Z

**Started:** 2026-04-27T14:32Z
**Completed:** 2026-04-27T15:18Z (or "in progress")
**Release type:** minor
**Skill version:** 0.10.0

## Section A — GitHub & repo hygiene

- [x] Tag is signed and verifiable. — done @ 2026-04-27T14:32Z
- [x] GitHub release is published with notes. — done @ 2026-04-27T14:32Z
- [ ] Open issues triaged. — deferred (3 issues need product judgment)
...

## Failures

- (none)

## Deferred carry-forward

- A.7 Open issues triaged — needs maintainer review of #21, #22, #23
```

Items map 1:1 to checkboxes in `docs/release-materials.md`. The session log is committed to the repo as part of release closure.

### Release-type detection

Given two tags `vX1.Y1.Z1` (previous) and `vX2.Y2.Z2` (current):

| Delta | Type |
|-------|------|
| `X2 > X1` | Major |
| `X2 == X1 && Y2 > Y1` | Minor |
| `X2 == X1 && Y2 == Y1 && Z2 > Z1` | Patch (or Hotfix — see below) |

A Patch is reclassified as Hotfix if `git log --grep='hotfix\|fix:' v_prev..v_current` returns ≥ 1 commit AND the diff is < 5 files. Otherwise it's a regular Patch.

Community is an additive type: detected if `git log v_prev..v_current` shows commits authored by someone other than the maintainer (`git config user.email`). Applied alongside Major / Minor / Patch / Hotfix.

`--type` flag overrides detection.

## 5. Edge Cases

| Case | Expected behavior |
|------|-------------------|
| Skill invoked before tag exists | Error: "tag vX.Y.Z not found locally; run `git fetch --tags` or run after `release.sh`." |
| Skill invoked with no prior session log AND `--resume` | Error: "no prior session at `.add/post-release-logs/release-vX.Y.Z.md`; nothing to resume." |
| `docs/release-materials.md` has malformed item (missing Files: line) | Skill warns once at top of run, treats item as `manual` with a "format-anomaly" tag, continues. |
| Skill run from a non-ADD project | Error: "no `.add/` directory; this skill applies only to projects that vendor ADD." Exit 2. |
| Skill run by an agent that's not the human (e.g., during `/add:away`) | Skill ABORTS with "post-release contains manual judgment items; human must run." | 
| GitHub Pages deploy is still running when Section C live-verification runs | Skill polls up to 60s; if still running, marks the item `deferred — pages deploy still in flight` and continues. |
| Two releases tagged same day | The session log file is per-tag, so they don't collide. The skill warns if a prior tag's log is incomplete. |

## 6. Non-Goals

- This skill does NOT handle the release boundary itself (`./scripts/release.sh` already does that and stays as-is).
- This skill does NOT enforce a release cadence — it runs after the maintainer chooses to release.
- This skill does NOT auto-merge community PRs — that's still a manual decision.
- This skill does NOT generate the blog post body (that's a separate `/add:announce` skill candidate).
- This skill does NOT push directly to the `MountainUnicorn/getadd.dev` repo without confirmation — site updates are too sensitive to be silent.
- This skill does NOT replace the version-bump checklist in maintainer memory — that runs BEFORE the release tag; this runs AFTER.

## 7. Open Questions

| ID | Question | Owner | Target |
|----|----------|-------|--------|
| Q-001 | Should `/add:post-release` automatically open a draft PR for the website blog post commits, or push to `main` directly? Memory shows direct-to-main has been the convention for the website repo so far; PR-based would slow the cadence. | Maintainer | v0.10 |
| Q-002 | Should the session log be auto-committed at the end of a successful run, or stay uncommitted until the maintainer reviews it? | Maintainer | v0.10 |
| Q-003 | How does the skill handle the website repo (`MountainUnicorn/getadd.dev`)? Run `git -C ~/projects/getadd.dev` operations from inside the plugin repo session? Path is hard-coded as `~/projects/getadd.dev` per current memory but should probably be discoverable via a config field. | Architecture | v0.10 |
| Q-004 | The "Open issues triaged" item is judgment-heavy. Should the skill open Linear-style "issue review" prompts in batches, or just defer it as a manual item every time? | Maintainer | v0.10 |
| Q-005 | Should social-preview PNG re-upload to GitHub Settings be deferred forever (no API for it) or scripted via the GitHub web automation API if it exists? | Maintainer | v0.10 |

## 8. Dependencies

- `docs/release-materials.md` — canonical checklist (this spec ships it as a sibling deliverable).
- `core/rules/telemetry.md` — emission contract; the new skill emits per the v0.9.0 telemetry contract.
- `core/skills/version/SKILL.md` — for tag verification helpers.
- `gh` CLI — every `gh pr`, `gh issue`, `gh release`, `gh run` invocation.
- `python3` — for the `release-materials.md` parser.
- Existing scripts: `scripts/release.sh` (runs BEFORE this skill), `scripts/sync-marketplace.sh`, `scripts/generate-agents-md.py`, `scripts/compile.py`, `scripts/validate-secret-patterns.py`.

## 9. Sizing

Medium. ~2-3 days of cycle work. Decomposes:

1. Fixture-based tests for the parser + a synthetic release-materials.md → 0.5 day
2. Skill body (markdown prose + the parser logic implemented as embedded shell + Python) → 1 day
3. Session log format + idempotent-resume logic → 0.5 day
4. Cross-runtime testing (Claude + Codex) → 0.5 day
5. Documentation, the audit checklist of all 27 skills' `references:` updates if applicable, README + CHANGELOG + memory updates → 0.5 day

The big known unknown is the website-repo handling (Q-003) — if the answer is "needs config + path resolver," add 0.5 day.

## 10. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-27 | 0.1.0 | abrooke + Claude | Initial spec — codifies post-release work as a checklist + a future skill that walks it |

# Spec: Auto-Changelog

**Version:** 0.1.0
**Created:** 2026-02-14
**PRD Reference:** docs/prd.md
**Status:** Draft

## 1. Overview

Automatic enterprise-class changelog generation that accumulates entries on push events via a hook and formalizes them into versioned releases during `/add:deploy`. Follows the Keep a Changelog standard. Parses conventional commit messages (which ADD already enforces) to categorize changes. Cross-references ADD specs for traceability.

### User Story

As a developer using ADD, I want a professional changelog maintained automatically from my commit history, so that users and stakeholders can see what changed in each release without manual documentation effort.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | Push hook automatically appends new commits to `[Unreleased]` section of `CHANGELOG.md` | Must |
| AC-002 | Conventional commit prefixes map to Keep a Changelog sections: feat→Added, fix→Fixed, docs→Documentation, refactor→Changed, perf→Changed, deprecate→Deprecated, remove→Removed, security→Security | Must |
| AC-003 | `chore:` commits are excluded from changelog (internal maintenance) | Must |
| AC-004 | Duplicate entries are not added (commit already in changelog is skipped) | Must |
| AC-005 | `/add:changelog` command manually triggers changelog generation/refresh from git history | Must |
| AC-006 | `/add:deploy` promotes `[Unreleased]` section to `[version] - date` when deploying a release | Must |
| AC-007 | Spec cross-references are included when commit messages reference spec slugs (e.g., "feat: add OAuth login (#auth-oauth)") | Should |
| AC-008 | `/add:init` scaffolds empty `CHANGELOG.md` from template with Keep a Changelog header | Must |
| AC-009 | Changelog follows Keep a Changelog format (keepachangelog.com) | Must |
| AC-010 | Push hook adds < 3 seconds to push operation | Must |
| AC-011 | `/add:changelog --from-scratch` regenerates entire changelog from git history for projects adopting ADD mid-life | Should |
| AC-012 | Entries are concise — commit subject line only, no body/footer (unless body contains spec reference) | Must |

## 3. User Test Cases

### TC-001: First push after init

**Precondition:** ADD initialized, `CHANGELOG.md` scaffolded with empty `[Unreleased]` section, 3 new commits: `feat: add user login`, `fix: correct redirect URL`, `chore: update dependencies`
**Steps:**
1. Run `git push`
2. Push hook fires
**Expected Result:** `CHANGELOG.md` updated:
```markdown
## [Unreleased]

### Added
- Add user login

### Fixed
- Correct redirect URL
```
Note: `chore:` commit excluded.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-002: Subsequent push with no duplicates

**Precondition:** CHANGELOG.md already has "Add user login" in Unreleased. New commit: `feat: add password reset`
**Steps:**
1. Run `git push`
2. Push hook fires
**Expected Result:** "Add password reset" added under `### Added`. "Add user login" NOT duplicated.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-003: Deploy promotes Unreleased to version

**Precondition:** CHANGELOG.md has several entries under `[Unreleased]`
**Steps:**
1. Run `/add:deploy` with version 0.2.0
**Expected Result:** CHANGELOG.md transformed:
```markdown
## [Unreleased]

## [0.2.0] - 2026-02-14

### Added
- Add user login
- Add password reset (#auth-oauth)

### Fixed
- Correct redirect URL
```
`[Unreleased]` section is now empty (reset for next cycle).
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-004: Spec cross-reference in commit

**Precondition:** Commit message: `feat: implement OAuth2 flow (#auth-oauth)`
**Steps:**
1. Run `git push`
**Expected Result:** Changelog entry: `- Implement OAuth2 flow (#auth-oauth)` — spec slug preserved as cross-reference
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-005: Manual changelog refresh

**Precondition:** ADD initialized, some commits made but push hook was not active (e.g., project adopted ADD mid-life)
**Steps:**
1. Run `/add:changelog`
**Expected Result:** Reads git log, generates `[Unreleased]` section from all unpublished commits. Categorizes by conventional prefix.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-006: Full regeneration from history

**Precondition:** Existing project with 200+ commits, no CHANGELOG.md
**Steps:**
1. Run `/add:changelog --from-scratch`
**Expected Result:** CHANGELOG.md created with all tagged releases as versioned sections. Untagged commits go in `[Unreleased]`. Each section categorized by conventional commit prefix.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-007: Init scaffolds empty changelog

**Precondition:** New project, no CHANGELOG.md
**Steps:**
1. Run `/add:init`
**Expected Result:** `CHANGELOG.md` created:
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]
```
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

## 4. Data Model

### CHANGELOG.md Structure

| Section | Type | Description |
|---------|------|-------------|
| Header | Static text | Title + format attribution |
| [Unreleased] | Dynamic | Accumulates entries between releases |
| [version] - date | Frozen | Promoted from Unreleased during deploy |

### Conventional Commit → Changelog Mapping

| Commit Prefix | Changelog Section |
|--------------|-------------------|
| feat: | Added |
| fix: | Fixed |
| docs: | Documentation |
| refactor: | Changed |
| perf: | Changed |
| deprecate: | Deprecated |
| remove: | Removed |
| security: | Security |
| chore: | (excluded) |
| test: | (excluded) |
| ci: | (excluded) |
| style: | (excluded) |
| build: | (excluded) |

### Entry Format

```
- {commit subject with prefix stripped, sentence case} [(#spec-slug)]
```

Example: `feat: add OAuth2 login flow (#auth-oauth)` → `- Add OAuth2 login flow (#auth-oauth)`

### Relationships

- Push hook reads git log to find new commits
- `/add:deploy` reads and modifies CHANGELOG.md during version promotion
- Spec slugs in parentheses link entries to `specs/{slug}.md`
- Changelog template lives at `templates/changelog.md.template`

## 5. API Contract (if applicable)

N/A — File-based output + git hook.

## 6. UI Behavior (if applicable)

N/A — Terminal CLI output for `/add:changelog`. File modification for push hook.

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Non-conventional commit messages (no prefix) | Categorize under "Changed" with full message as entry |
| Merge commits | Skip — they duplicate the merged commits' content |
| Squash commits with multi-line body | Use first line (subject) only for changelog entry |
| Empty push (no new commits) | Hook exits early, no changelog modification |
| CHANGELOG.md doesn't exist when hook fires | Create it from template, then append entries |
| Multiple pushes before deploy | Each push appends to [Unreleased]; no duplicates |
| Revert commits (`revert: ...`) | Add under "Removed" or "Fixed" depending on what was reverted |
| Breaking changes (feat!: or BREAKING CHANGE footer) | Add to top of section with "**BREAKING:** " prefix |
| Git tags but no `/add:deploy` | `/add:changelog` can detect tags and create versioned sections retroactively |
| Very long commit subject (>100 chars) | Truncate to 100 chars with "..." |

## 8. Dependencies

- **Conventional commits** — ADD's source-control rule already enforces these
- **`/add:deploy` skill** — must be updated to call changelog promotion
- **`/add:init` command** — must scaffold CHANGELOG.md
- **hooks/hooks.json** — must add PostToolUse hook for git push
- **Git** — reads git log for commit history

## 9. Implementation Notes

### Push Hook Design

Add to `hooks/hooks.json` a PostToolUse hook that fires when Bash is used with `git push`:

```json
{
  "event": "PostToolUse",
  "tool": "Bash",
  "pattern": "git push",
  "command": "changelog-update logic"
}
```

The hook should:
1. Read CHANGELOG.md to find last logged commit (or use a marker in `.add/config.json`)
2. Run `git log --oneline {last_commit}..HEAD` to get new commits
3. Parse conventional commit prefixes
4. Append to appropriate sections under `[Unreleased]`
5. Write updated CHANGELOG.md

### Tracking Last Processed Commit

Store in `.add/config.json`:
```json
"changelog": {
  "lastProcessedCommit": "abc123f",
  "lastVersionTag": "v0.1.0"
}
```

### Files to create/modify

- **New:** `templates/changelog.md.template` — empty changelog scaffold
- **New:** `skills/changelog/SKILL.md` or `commands/changelog.md` — `/add:changelog` command
- **Modify:** `hooks/hooks.json` — add push hook for changelog accumulation
- **Modify:** `skills/deploy/SKILL.md` — add changelog promotion step
- **Modify:** `commands/init.md` — scaffold CHANGELOG.md in Phase 2

## 10. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec conversation |

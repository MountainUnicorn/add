---
description: "[ADD v0.2.0] Generate or refresh CHANGELOG.md from conventional commits"
argument-hint: [--from-scratch]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
disable-model-invocation: true
---

# ADD Changelog Command v0.2.0

Generate or refresh the project's CHANGELOG.md from git history using conventional commit parsing. Follows the [Keep a Changelog](https://keepachangelog.com/) format.

## Pre-Flight Check

1. Check if `CHANGELOG.md` exists in the project root
2. If it does NOT exist, create it from `${CLAUDE_PLUGIN_ROOT}/templates/changelog.md.template`
3. Read `.add/config.json` for `changelog.lastProcessedCommit` (may be null)
4. Determine mode: `--from-scratch` flag means full regeneration; otherwise incremental

## Conventional Commit Mapping

Map conventional commit prefixes to Keep a Changelog sections:

| Commit Prefix | Changelog Section |
|---------------|-------------------|
| feat:         | Added             |
| fix:          | Fixed             |
| docs:         | Documentation     |
| refactor:     | Changed           |
| perf:         | Changed           |
| deprecate:    | Deprecated        |
| remove:       | Removed           |
| security:     | Security          |
| revert:       | Fixed             |

### Excluded Prefixes (not added to changelog)

These are internal/maintenance commits and should be silently skipped:

- `chore:`
- `test:`
- `ci:`
- `style:`
- `build:`

### Non-Conventional Commits

Commits that do not match any conventional prefix are categorized under **Changed** with the full message as the entry text.

### Merge Commits

Skip merge commits entirely — they duplicate the content of the merged commits.

## Phase 1: Gather Commits

### Incremental Mode (default)

1. Read `CHANGELOG.md` to understand current state
2. Read `.add/config.json` for `changelog.lastProcessedCommit`
3. If `lastProcessedCommit` is set:
   - Run `git log --oneline --no-merges {lastProcessedCommit}..HEAD` to get new commits
4. If `lastProcessedCommit` is null:
   - Run `git log --oneline --no-merges` to get all commits
5. If no new commits found, report "Changelog is up to date" and exit

### From-Scratch Mode (`--from-scratch`)

1. Run `git tag --sort=-version:refname` to get all version tags
2. Run `git log --oneline --no-merges` to get full commit history
3. Group commits by version tags:
   - Commits after the latest tag go in `[Unreleased]`
   - Commits between tags go in `[tag] - date` sections (use tag date)
   - Commits before the earliest tag go in the earliest version section
4. Regenerate `CHANGELOG.md` entirely (preserve the header from template)

## Phase 2: Parse Commits

For each commit message:

1. **Extract prefix**: Match against `^(feat|fix|docs|refactor|perf|deprecate|remove|security|revert|chore|test|ci|style|build)(\(.+\))?!?:\s*(.+)$`
2. **Check exclusion list**: If prefix is `chore`, `test`, `ci`, `style`, or `build`, skip this commit
3. **Strip prefix**: Remove the prefix and scope from the message, keeping only the description
4. **Sentence-case**: Capitalize the first letter of the description
5. **Detect spec cross-references**: Look for `(#spec-slug)` pattern in the message — preserve these as-is
6. **Detect breaking changes**: If `!` is present after the scope (e.g., `feat!:`) or commit body contains `BREAKING CHANGE:`, prefix the entry with `**BREAKING:** `
7. **Truncate long entries**: If the subject line exceeds 100 characters, truncate to 100 chars with "..."
8. **Map to section**: Use the mapping table above to determine which changelog section

### Entry Format

```
- {Sentence-cased description} [(#spec-slug)]
```

Examples:
- `feat: add OAuth2 login flow (#auth-oauth)` becomes `- Add OAuth2 login flow (#auth-oauth)` under **Added**
- `fix: correct redirect URL` becomes `- Correct redirect URL` under **Fixed**
- `feat!: redesign API response format` becomes `- **BREAKING:** Redesign API response format` under **Added**

## Phase 3: Deduplicate

Before adding any entry to the changelog:

1. Read the current `CHANGELOG.md` content
2. For each parsed entry, check if an entry with the same text already exists in ANY section of `[Unreleased]`
3. If a duplicate is found, skip that entry
4. Only add genuinely new entries

## Phase 4: Write Changelog

### Section Ordering

Within `[Unreleased]` (and each versioned section), order subsections as:

1. Added
2. Changed
3. Deprecated
4. Removed
5. Fixed
6. Security
7. Documentation

Only include subsections that have entries — do not write empty subsections.

### Writing Strategy

1. Read existing `CHANGELOG.md`
2. Find the `## [Unreleased]` line
3. Parse any existing entries under `[Unreleased]` to merge with new entries
4. Group all entries (existing + new) by section
5. Write the updated `[Unreleased]` block
6. Preserve all versioned sections below `[Unreleased]` unchanged

### Update Config

After writing, update `.add/config.json`:
- Set `changelog.lastProcessedCommit` to the current HEAD commit hash (run `git rev-parse HEAD`)

## Phase 5: Report

Display a summary of what was added:

```
Changelog updated.

NEW ENTRIES:
  Added: {N} entries
  Changed: {N} entries
  Fixed: {N} entries
  {other sections as applicable}

SKIPPED:
  Excluded (chore/test/ci/style/build): {N} commits
  Duplicates: {N} entries already present
  Merge commits: {N} skipped

Total: {N} new entries added to [Unreleased]
Last processed commit: {short hash}
```

## Edge Cases

| Case | Behavior |
|------|----------|
| No conventional prefix | Categorize under "Changed" with full message |
| Empty push (no new commits) | Exit early with "Changelog is up to date" |
| CHANGELOG.md missing | Create from template, then proceed |
| `.add/config.json` missing | Process all commits (no lastProcessedCommit) |
| Scoped commits (e.g., `feat(auth):`) | Strip scope along with prefix |
| Multiple spec references | Preserve all `(#slug)` references |
| Very long subject (>100 chars) | Truncate to 100 chars with "..." |

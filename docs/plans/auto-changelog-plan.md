# Implementation Plan: Auto-Changelog

**Spec Version**: 0.1.0
**Spec File**: specs/auto-changelog.md
**Created**: 2026-02-14
**Team Size**: Solo (2 parallel agents)
**Estimated Duration**: 3.5 hours
**Implementation Order**: 2 of 4 (independent — can run parallel with image gen detection)

## Overview

Automatic changelog generation that accumulates entries from conventional commits on push events and formalizes them into versioned releases during `/add:deploy`. Includes a push hook for auto-accumulation, a `/add:changelog` command for manual refresh, and integration with `/add:init` to scaffold the file.

## Objectives

- Auto-accumulate changelog entries on every push
- Parse conventional commits into Keep a Changelog sections
- Cross-reference ADD specs when commit messages include spec slugs
- Promote `[Unreleased]` to versioned releases during deploy
- Scaffold empty CHANGELOG.md during init

## Cross-Feature Dependencies

```
Auto-Changelog ──→ /add:deploy (promotion step)
Auto-Changelog ──→ /add:init (scaffolding)
Auto-Changelog ──→ source-control rule (conventional commits)
```

**Blocked by**: Nothing — fully independent of branding/image gen/infographic
**Can parallelize with**: Image Gen Detection

## Acceptance Criteria Analysis

### AC-001–004: Push hook + commit parsing + deduplication
- **Complexity**: Medium
- **Effort**: 1.5h
- **Tasks**: Hook definition in hooks.json, commit parsing logic, dedup check
- **Risk**: Hook must match `git push` pattern reliably. Dedup requires reading existing changelog.

### AC-005: /add:changelog command
- **Complexity**: Medium
- **Effort**: 1h
- **Tasks**: New command file with git log parsing, section categorization
- **Risk**: Low — similar logic to hook but triggered manually

### AC-006: Deploy promotion
- **Complexity**: Simple
- **Effort**: 30min
- **Tasks**: Update deploy skill to rename [Unreleased] → [version] - date
- **Risk**: Need to handle deploy skill's existing flow carefully

### AC-007–008: Spec cross-references + init scaffolding
- **Complexity**: Simple
- **Effort**: 30min
- **Tasks**: Regex for (#spec-slug) in commits, changelog template, init update
- **Risk**: None

### AC-009–012: Format compliance + performance + from-scratch + conciseness
- **Complexity**: Simple
- **Effort**: Covered by above tasks (format is structural, not separate work)

## Implementation Phases

### Phase 1: Template + Init Integration (30min)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-001 | Create `templates/changelog.md.template` — Keep a Changelog header + empty [Unreleased] section | 10min | None | AC-008, AC-009 |
| TASK-002 | Update `commands/init.md` — add CHANGELOG.md scaffolding to Phase 2 (Step 2.1 directory/file creation). Write from template. | 20min | TASK-001 | AC-008 |

### Phase 2: /add:changelog Command (1h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-003 | Create `commands/changelog.md` — manual changelog generation/refresh. Reads git log, parses conventional commit prefixes, categorizes into Keep a Changelog sections (Added, Fixed, Changed, etc.), writes to CHANGELOG.md [Unreleased] section. | 40min | TASK-001 | AC-005, AC-009 |
| TASK-004 | Add `--from-scratch` flag to changelog.md — regenerates entire changelog from git history. Detects version tags, creates versioned sections. Untagged commits go in [Unreleased]. | 20min | TASK-003 | AC-011 |

### Phase 3: Push Hook (1h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-005 | Define push hook entry in `hooks/hooks.json` — PostToolUse matcher for Bash tool with `git push` pattern. The hook command reads git log for new commits since last processed, parses, appends to [Unreleased]. | 30min | TASK-003 | AC-001, AC-010 |
| TASK-006 | Add `changelog` section to `templates/config.json.template` — tracks `lastProcessedCommit` and `lastVersionTag` for hook dedup | 10min | None | AC-004 |
| TASK-007 | Add spec cross-reference detection — regex for `(#slug)` in commit messages, preserved in changelog entries | 10min | TASK-003 | AC-007 |
| TASK-008 | Document commit prefix → changelog section mapping and exclusion rules (chore, test, ci, style, build are excluded) in command file | 10min | TASK-003 | AC-002, AC-003, AC-012 |

### Phase 4: Deploy Integration (30min)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-009 | Update `skills/deploy/SKILL.md` — add changelog promotion step. Before push/deploy: rename [Unreleased] → [version] - date, insert fresh empty [Unreleased] section. | 30min | TASK-003 | AC-006 |

## Effort Summary

| Phase | Estimated Hours |
|-------|----------------|
| Phase 1: Template + Init | 0.5h |
| Phase 2: /add:changelog Command | 1.0h |
| Phase 3: Push Hook | 1.0h |
| Phase 4: Deploy Integration | 0.5h |
| Contingency (15%) | 0.5h |
| **Total** | **3.5h** |

## Parallelization Strategy

Solo with 2 agents:
```
Agent 1: TASK-001 (template) → TASK-003 (command) → TASK-005 (hook) → TASK-009 (deploy)
Agent 2: TASK-002 (init update) → TASK-006 (config) → TASK-007 (spec xref) → TASK-008 (docs)
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Hook pattern doesn't match all push variants | Medium | Medium | Test with `git push`, `git push origin main`, `git push -u origin feature` |
| Dedup fails on amended commits | Low | Low | Track by commit hash, not message content |
| Non-conventional commits in existing projects | Medium | Low | Default to "Changed" section for unparseable commits |
| Deploy skill update conflicts | Low | Medium | Add changelog step as a discrete phase, don't restructure existing flow |

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `templates/changelog.md.template` | Keep a Changelog scaffold |
| Create | `commands/changelog.md` | `/add:changelog` command |
| Modify | `commands/init.md` | Add CHANGELOG.md to Phase 2 scaffolding |
| Modify | `hooks/hooks.json` | Add PostToolUse push hook |
| Modify | `templates/config.json.template` | Add `changelog` tracking section |
| Modify | `skills/deploy/SKILL.md` | Add changelog promotion step |

## Conventional Commit Mapping Reference

| Prefix | Changelog Section | Included |
|--------|-------------------|----------|
| feat: | Added | Yes |
| fix: | Fixed | Yes |
| docs: | Documentation | Yes |
| refactor: | Changed | Yes |
| perf: | Changed | Yes |
| deprecate: | Deprecated | Yes |
| remove: | Removed | Yes |
| security: | Security | Yes |
| revert: | Fixed | Yes |
| chore: | — | No |
| test: | — | No |
| ci: | — | No |
| style: | — | No |
| build: | — | No |

## Success Criteria

- [ ] All 12 acceptance criteria implemented
- [ ] Changelog template follows Keep a Changelog format
- [ ] Init scaffolds CHANGELOG.md
- [ ] /add:changelog parses conventional commits correctly
- [ ] --from-scratch regenerates from full git history
- [ ] Push hook auto-accumulates without duplicates
- [ ] Deploy promotes [Unreleased] to versioned section
- [ ] Spec cross-references preserved in entries
- [ ] Excluded prefixes (chore, test, etc.) are filtered out

## Next Steps

1. Approve this plan
2. Implement in parallel with image gen detection (Wave 2)
3. Test hook with real pushes on ADD repo itself (dogfood)
4. Sync to marketplace

## Plan History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial plan |

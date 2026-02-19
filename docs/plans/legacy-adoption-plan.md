# Implementation Plan: Legacy Adoption (Version Migration)

**Spec Version:** 0.1.0
**Created:** 2026-02-18
**Team Size:** Solo
**Estimated Duration:** 1 session

## Overview

Create an auto-loading rule and version manifest that detect stale ADD project files on session start and migrate them to current formats. Since ADD is a pure markdown/JSON plugin, "migration" is instructions in a rule file that agents follow.

## Objectives

- Automatic version detection and migration on session start
- Chained migrations for multi-version jumps
- Safe backups before any modification
- Clear reporting of what changed

## Implementation Phases

### Phase 1: Version Manifest

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-001 | Create `templates/migrations.json` with schema and migration entries for v0.1→v0.2, v0.2→v0.3, v0.3→v0.4 | AC-003, AC-004 | 30min |

Each migration entry defines: from version, to version, ordered steps with file paths, actions, and parameters.

### Phase 2: Migration Rule

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-002 | Create `rules/version-migration.md` — auto-loading rule with version detection, manifest reading, backup protocol, migration execution, reporting, and error handling | AC-001, AC-002, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010, AC-011, AC-012, AC-013, AC-014, AC-015, AC-016, AC-017, AC-018, AC-019, AC-020, AC-021, AC-022 | 1h |

This is the core deliverable. The rule instructs agents to:
1. Read `.add/config.json` version on session start
2. Compare against plugin version from plugin.json
3. If mismatch, read migrations.json for applicable steps
4. Chain migrations in order
5. For each step: backup → execute → verify → mark deprecated
6. Update version after all migrations succeed
7. Print migration report

### Phase 3: Integration

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-003 | Update CLAUDE.md to document the migration system | — | 15min |
| TASK-004 | Update M2 milestone — mark Legacy Adoption as DONE | — | 5min |
| TASK-005 | Update spec status to Complete | — | 5min |

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Rule too verbose, consumes too many context tokens | Medium | Medium | Keep concise, reference manifest for details |
| Edge cases in version parsing | Low | Low | Use simple string comparison, semver not needed for 0.x versions |

## Deliverables

- `templates/migrations.json` — version manifest
- `rules/version-migration.md` — auto-loading migration rule
- Updated CLAUDE.md, M2 milestone, spec status

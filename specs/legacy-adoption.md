# Spec: Legacy Adoption (Version Migration)

**Version:** 0.1.0
**Created:** 2026-02-18
**PRD Reference:** docs/prd.md
**Status:** Draft

## 1. Overview

Automatic migration of older ADD plugin artifacts to current formats when the plugin is updated. Detects stale `.add/` files from previous ADD versions, converts them to the current schema, archives originals, and reports results. Runs automatically on plugin initialization — no manual command required.

### User Story

As an ADD user upgrading to a newer plugin version, I want my existing project files (learnings, handoffs, specs, config) automatically migrated to the current format, so that I retain continuity and accumulated knowledge without manual conversion.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | On plugin initialization, detect the project's ADD version from `.add/config.json` `version` field | Must |
| AC-002 | Compare project version against current plugin version to determine if migration is needed | Must |
| AC-003 | Read a version manifest (`templates/migrations.json`) that maps version ranges to migration steps | Must |
| AC-004 | Chain migrations so a project at v0.1.0 can migrate to v0.4.0 in one pass (v0.1→v0.2→v0.3→v0.4) | Must |
| AC-005 | Before any migration, back up every file that will be modified to `{filename}.pre-migration.bak` | Must |
| AC-006 | Migrate `.add/learnings.md` (freeform markdown) to `.add/learnings.json` (structured JSON) for projects pre-v0.4.0 | Must |
| AC-007 | Migrate `~/.claude/add/library.md` (freeform markdown) to `~/.claude/add/library.json` (structured JSON) for users pre-v0.4.0 | Must |
| AC-008 | Regenerate markdown views (`.add/learnings.md`, `~/.claude/add/library.md`) from migrated JSON | Must |
| AC-009 | Migrate `.add/config.json` schema changes between versions (add new fields with defaults, remove deprecated fields) | Must |
| AC-010 | Rename original pre-migration files to `{filename}.deprecated` after successful conversion | Must |
| AC-011 | Update `.add/config.json` `version` field to current plugin version after all migrations complete | Must |
| AC-012 | Print a migration report summarizing: files migrated, files backed up, files that failed, version jumped from→to | Must |
| AC-013 | If a file cannot be parsed or converted, skip it, log the error, and continue with remaining files | Must |
| AC-014 | Never lose data — if migration fails partway, backups remain intact and the version is NOT updated | Must |
| AC-015 | Migrate spec frontmatter changes between versions (new required fields get sensible defaults) | Should |
| AC-016 | Migrate `.add/handoff.md` format changes (add missing sections with empty defaults) | Should |
| AC-017 | Detect and skip projects that are already at current version (no-op, no output) | Should |
| AC-018 | Migrate `.add/observations.md` format if schema changed between versions | Should |
| AC-019 | Migrate `.add/decisions.md` format if schema changed between versions | Should |
| AC-020 | Support dry-run mode that reports what WOULD be migrated without making changes | Nice |
| AC-021 | Log migration history to `.add/migration-log.md` with timestamps and version transitions | Nice |
| AC-022 | Detect orphaned `.bak` files from previous migrations and offer cleanup | Nice |

## 3. User Test Cases

### TC-001: Fresh upgrade from v0.1.0 to v0.4.0

**Precondition:** Project has `.add/config.json` with `version: "0.1.0"`, freeform `.add/learnings.md`, no JSON learnings file
**Steps:**
1. Update ADD plugin to v0.4.0
2. Open project in Claude Code (triggers plugin initialization)
3. Plugin detects version mismatch (0.1.0 → 0.4.0)
4. Migration runs automatically
**Expected Result:** Learnings converted to JSON, config updated with new fields, all originals backed up as `.pre-migration.bak`, deprecated files renamed, report printed showing 0.1.0 → 0.4.0 migration
**Screenshot Checkpoint:** N/A (CLI output)
**Maps to:** TBD

### TC-002: Already at current version (no-op)

**Precondition:** Project has `.add/config.json` with `version: "0.4.0"`, plugin is v0.4.0
**Steps:**
1. Open project in Claude Code
2. Plugin initialization runs
**Expected Result:** No migration triggered, no output, no file changes
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-003: Partially corrupt learnings file

**Precondition:** Project has `.add/learnings.md` with some unparseable entries mixed with valid ones
**Steps:**
1. Upgrade plugin and trigger migration
**Expected Result:** Valid entries migrated to JSON, unparseable entries logged as errors in report, backup preserved, migration continues for other files
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-004: Multi-version jump (v0.2.0 → v0.4.0)

**Precondition:** Project at v0.2.0 with branding config but no JSON learnings
**Steps:**
1. Upgrade plugin to v0.4.0
2. Migration chains: v0.2→v0.3 steps, then v0.3→v0.4 steps
**Expected Result:** All intermediate migrations applied in order, final state matches v0.4.0 schema, report shows chained migration path
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-005: Migration failure preserves backups

**Precondition:** Project at v0.1.0, `.add/config.json` has invalid JSON
**Steps:**
1. Upgrade plugin, trigger migration
2. Config migration fails due to parse error
**Expected Result:** Backup of config created before attempt, error reported, version NOT updated, other file migrations still attempted, all backups intact
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

## 4. Data Model

### Migration Manifest (`templates/migrations.json`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| schema_version | string | Yes | Manifest format version |
| migrations | array | Yes | Ordered list of migration entries |
| migrations[].from | string | Yes | Source version (semver) |
| migrations[].to | string | Yes | Target version (semver) |
| migrations[].steps | array | Yes | Ordered list of migration steps |
| migrations[].steps[].file | string | Yes | File path relative to project root (supports `~` for user-local) |
| migrations[].steps[].action | string | Yes | Migration action: `convert_md_to_json`, `add_fields`, `rename_fields`, `remove_fields`, `restructure` |
| migrations[].steps[].params | object | No | Action-specific parameters (field names, defaults, etc.) |
| migrations[].steps[].description | string | Yes | Human-readable description of what this step does |

### Migration Report

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| from_version | string | Yes | Version before migration |
| to_version | string | Yes | Version after migration |
| migration_path | array | Yes | Ordered version hops (e.g., ["0.1.0", "0.2.0", "0.3.0", "0.4.0"]) |
| files_migrated | number | Yes | Count of successfully migrated files |
| files_backed_up | number | Yes | Count of backup files created |
| files_failed | number | Yes | Count of files that could not be migrated |
| failures | array | No | List of {file, error} for failed migrations |
| timestamp | string | Yes | ISO 8601 timestamp |

## 5. API Contract

N/A — this feature is an internal plugin initialization hook, not a user-invoked command or API endpoint.

## 6. UI Behavior

N/A — CLI-only. Migration produces a text report to stdout:

```
ADD MIGRATION — v0.1.0 → v0.4.0
Path: v0.1.0 → v0.2.0 → v0.3.0 → v0.4.0

Backed up:
  .add/learnings.md → .add/learnings.md.pre-migration.bak
  .add/config.json → .add/config.json.pre-migration.bak

Migrated:
  ✓ .add/learnings.md → .add/learnings.json (28 entries converted)
  ✓ .add/config.json (3 new fields added, 1 deprecated field removed)
  ✓ .add/handoff.md (2 new sections added)

Deprecated:
  .add/learnings.md → .add/learnings.md.deprecated

Failed:
  (none)

Version updated: .add/config.json → 0.4.0
Migration complete.
```

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No `.add/config.json` exists | Not an ADD project — skip migration silently |
| Config exists but no `version` field | Assume v0.1.0 (earliest version) |
| Version is ahead of plugin version | Skip migration, warn: "Project version newer than plugin" |
| Backup file already exists from previous migration | Append timestamp to backup name to avoid overwrite |
| User-local library (`~/.claude/add/`) doesn't exist | Skip user-local migrations, no error |
| File is already in target format (e.g., learnings.json already exists) | Skip that migration step, note in report |
| Empty file (0 bytes) | Back up, create fresh file from template, note in report |
| Read-only file system | Report error, preserve backups, do not update version |

## 8. Dependencies

- `templates/migrations.json` — version manifest (new file, must be created)
- `templates/learnings.json.template` — target schema for learnings migration (exists)
- `templates/library.json.template` — target schema for library migration (exists)
- `rules/learning.md` — migration logic already documented in "Migration from Markdown" section

## 9. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-18 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec interview |

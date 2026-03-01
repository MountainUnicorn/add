---
autoload: true
maturity: poc
---

# ADD Rule: Version Migration

Automatically detect and migrate stale ADD project files when the plugin version is newer than the project version.

## When This Runs

On **every session start**, before any other work:

1. Read `.add/config.json` — extract the `version` field
2. Read the plugin's `.claude-plugin/plugin.json` — extract the `version` field
3. If they match → **stop silently** (no output, no action)
4. If project version is ahead of plugin → warn: "Project version ({project}) is newer than plugin ({plugin}). Skipping migration." → stop
5. If no `.add/config.json` exists → not an ADD project, stop silently
6. If config exists but has no `version` field → assume `0.1.0`

## Migration Process

### Step 1: Build Migration Path

Read `${CLAUDE_PLUGIN_ROOT}/templates/migrations.json` to get the manifest.

Chain migrations from the project version to the plugin version. Example: project at `0.1.0`, plugin at `0.4.0` → path is `0.1.0 → 0.2.0 → 0.3.0 → 0.4.0`.

If no migration entry exists for a hop in the chain, skip that hop and continue.

### Step 2: Back Up Files

Before modifying ANY file, create a backup:
- Copy `{file}` to `{file}.pre-migration.bak`
- If a `.pre-migration.bak` already exists, append a timestamp: `{file}.pre-migration-{YYYYMMDD-HHMMSS}.bak`

Track all backups created.

### Step 3: Execute Migration Steps

For each version hop in order, execute each step from the manifest:

#### Action: `add_fields`

Add new fields to a JSON file with default values. Uses dot-notation paths (e.g., `collaboration.autonomy_level` means `{"collaboration": {"autonomy_level": value}}`).

- Read the target JSON file
- For each field in `params.fields`: if the field doesn't already exist, add it with the specified default value
- If the field already exists, **leave it unchanged** (user may have customized it)
- Write the updated JSON

#### Action: `convert_md_to_json`

Convert a freeform markdown file to structured JSON.

- If the target JSON file already exists, **skip** — the conversion was already done
- Read the markdown source file
- Read the template from `params.template` for the target schema
- Parse entries from the markdown (checkpoint blocks, bullet points, sections)
- Classify each entry (scope, stack, category, severity) using the rules in `learning.md`
- Assign IDs with the prefix from `params.id_prefix`
- Write the JSON file
- If `params.regenerate_md` is true, regenerate the markdown view from JSON
- Rename the original markdown to `{file}.deprecated`

#### Action: `restructure`

Ensure a markdown file has required sections.

- Read the file
- For each section in `params.required_sections`: if the section heading doesn't exist, append it with empty content
- If `params.required_format` is specified, note the expected line format (informational — don't rewrite existing lines)
- If `params.header` is specified and the file lacks the expected header, prepend it
- Write the updated file

#### Action: `rename_fields`

Rename fields in a JSON file.

- Read the target JSON file
- For each old→new mapping in `params.fields`: move the value from the old key to the new key
- Delete the old key
- Write the updated JSON

#### Action: `remove_fields`

Remove deprecated fields from a JSON file.

- Read the target JSON file
- For each field in `params.fields`: delete it if it exists
- Write the updated JSON

### Step 4: Update Version

After ALL migration steps complete successfully:
- Update `.add/config.json` `version` field to the plugin version
- If any step failed, **do NOT update the version** — leave it at the last successfully completed hop

### Step 5: Print Report

Print a migration report:

```
ADD MIGRATION — v{from} → v{to}
Path: v{from} → v{hop1} → v{hop2} → v{to}

Backed up:
  {file} → {file}.pre-migration.bak
  ...

Migrated:
  ✓ {file} ({description})
  ...

Skipped (already current):
  - {file} ({reason})
  ...

Failed:
  ✗ {file} — {error message}
  ...

Version updated: .add/config.json → {to}
Migration complete.
```

If there were no failures, omit the Failed section. If there were no skips, omit the Skipped section.

## Error Handling

- If a file cannot be read or parsed, **log the error and skip that step** — continue with remaining steps
- If a backup cannot be created (read-only filesystem, etc.), **abort the entire migration** — never modify without backup
- All backups remain intact regardless of migration outcome
- If migration fails partway, the version stays at the last successful hop (not the original version)

## Dry-Run Mode

If the user asks for a dry-run migration, follow the same process but:
- Do NOT create backups
- Do NOT modify any files
- Do NOT update the version
- Print the report with "DRY RUN" prefix showing what WOULD happen

## Migration Log

After a successful migration, append to `.add/migration-log.md`:

```
## {YYYY-MM-DD HH:MM} — v{from} → v{to}
- Path: {migration path}
- Files migrated: {N}
- Files skipped: {N}
- Files failed: {N}
- Failures: {list or "none"}
```

Create the file if it doesn't exist.

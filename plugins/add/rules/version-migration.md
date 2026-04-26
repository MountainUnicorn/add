---
autoload: true
maturity: poc
---

# ADD Rule: Version Migration

Detect and migrate stale ADD project files when plugin version > project version.

## When This Runs

On **every session start**, before any other work:

1. Read `.add/config.json` `version` and plugin's `plugin.json` `version`
2. If they match → stop silently
3. If project > plugin → warn and stop
4. If no config → not an ADD project, stop silently
5. If config has no `version` → assume `0.1.0`

## Migration Process

1. **Build path:** Read `${CLAUDE_PLUGIN_ROOT}/templates/migrations.json`. Chain hops from project version to plugin version (skip missing hops).

2. **Back up:** Before modifying ANY file, copy to `{file}.pre-migration.bak`. If backup fails, abort entirely.

3. **Execute steps** from the manifest for each hop. Supported actions:
   - `add_fields` — add new JSON fields with defaults (skip existing)
   - `convert_md_to_json` — parse markdown to structured JSON (skip if JSON exists)
   - `restructure` — ensure markdown has required sections
   - `rename_fields` — move JSON fields to new keys
   - `remove_fields` — delete deprecated JSON fields

4. **Update version** in config after all steps succeed. On partial failure, stay at last successful hop.

5. **Print report:** Show backed-up files, migrated files, skipped files, failures, new version.

## Error Handling

- Unparseable files → log and skip, continue remaining steps
- Backup failure → abort entirely (never modify without backup)
- Partial failure → version stays at last successful hop

## Dry-Run & Logging

- Dry-run: same process, no modifications, "DRY RUN" prefix in report
- After success: append summary to `.add/migration-log.md`

---
description: "[ADD v0.7.3] Manage learnings — generate active views, archive old entries, show stats"
argument-hint: "[migrate|archive|stats] [--dry-run]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# ADD Learnings Skill v0.7.3

Manage the learnings knowledge base: generate optimized active views, archive stale entries, and report statistics.

## Overview

Learnings accumulate over time in `.add/learnings.json` and `~/.claude/add/library.json`. The full JSON files are expensive to load into agent context. This skill manages the lifecycle:

- **migrate** — Generate compact `-active.md` views from existing JSON (or migrate legacy `.md` to JSON first)
- **archive** — Mark old low-severity entries as archived to shrink the active set
- **stats** — Show learning counts, sizes, and context savings

Default subcommand (no argument): `migrate`.

## Pre-Flight Checks

1. Read `.add/config.json` to get project name
2. Locate learnings files:
   - `.add/learnings.json` (Tier 3 project learnings)
   - `.add/learnings.md` (legacy or generated view)
   - `.add/learnings-active.md` (optimized active view)
   - `~/.claude/add/library.json` (Tier 2 cross-project)
   - `~/.claude/add/library-active.md` (Tier 2 active view)

## Subcommand: migrate

Generate `-active.md` files from existing JSON. Handles three scenarios:

### Scenario A: JSON exists, active view missing or stale

This is the most common case — existing projects upgrading to the active view approach.

1. Run `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh` on `.add/learnings.json`
2. Run `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh` on `~/.claude/add/library.json` (if it exists)
3. Report what was generated and the context savings

### Scenario B: Only legacy `.md` exists (no JSON)

Pre-v0.4.0 projects that never migrated to structured JSON.

1. Announce: "Found legacy markdown learnings — migrating to JSON first."
2. Back up `.add/learnings.md` to `.add/learnings.md.pre-migration.bak`
3. Parse the markdown:
   - Each `- **[{severity}] {title}**` line is an entry
   - Extract body text from indented continuation lines
   - If no structured format, treat each `##` section + bullet as an entry
4. For each parsed entry, create a JSON learning object:
   - Assign ID: `L-001`, `L-002`, etc.
   - Infer `category` from section heading (Anti-Patterns → anti-pattern, Technical → technical, etc.)
   - Infer `severity` from `[critical]`, `[high]`, `[medium]`, `[low]` markers. Default: `medium`
   - Set `scope`: `project`
   - Set `stack`: `[]` (stack-agnostic, can be refined during retro)
   - Set `source`: project name from config
   - Set `date`: extract from entry if present, otherwise use file modification date
   - Set `classified_by`: `agent`
   - Set `checkpoint_type`: `retro` (migrated entries treated as retro-sourced)
5. Write `.add/learnings.json` with the standard wrapper
6. Run `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh` on the new JSON
7. Report: entries migrated, JSON created, active view generated

### Scenario C: Neither JSON nor MD exists

No learnings yet. Report: "No learnings files found. Learnings will be captured automatically during skill execution."

### Scenario: library.json

Apply the same logic to `~/.claude/add/library.json` / `~/.claude/add/library.md`. Use `WL-` prefix for IDs.

### Output Format

```
ADD LEARNINGS MIGRATION
=======================

Tier 3 (Project): .add/learnings.json
  Status: JSON exists (34 entries)
  Active view: Generated .add/learnings-active.md (15 of 34 entries)
  Context savings: 19,280 bytes → 5,494 bytes (72% reduction)

Tier 2 (Library): ~/.claude/add/library.json
  Status: JSON exists (4 entries)
  Active view: Generated ~/.claude/add/library-active.md (4 of 4 entries)
  Context savings: 1,820 bytes → 680 bytes (63% reduction)

Migration complete. Agents will now read -active.md files instead of full JSON.
```

### --dry-run flag

If `--dry-run` is passed:
- Do NOT create or modify any files
- Report what WOULD happen with "[DRY RUN]" prefix
- Show projected context savings

## Subcommand: archive

Review and archive stale learnings to keep the active set focused.

### Process

1. Read `.add/learnings.json`
2. Read from `.add/config.json`: `learnings.archival_days` (default: 90) and `learnings.archival_max_severity` (default: `"medium"`)
3. Identify archive candidates:
   - Entries older than `archival_days` with severity at or below `archival_max_severity`
   - Entries with duplicate/similar titles (keep the newer one)
3. Present candidates to the user:

```
ARCHIVE CANDIDATES (5 of 34 entries)

  L-011 [low] Hill chart concept maps perfectly to ADD (2026-02-07)
    → Reason: 66 days old, low severity

  L-012 [low] Now/Next/Later framing for milestones (2026-02-07)
    → Reason: 66 days old, low severity

  L-020 [low] v0.1.0 built in single session (2026-02-07)
    → Reason: 66 days old, low severity, historical note

Archive these entries? They remain in the JSON but are excluded from the active view.
  [a] Archive all candidates
  [s] Select individually
  [n] Skip archival
```

4. On confirmation, set `"archived": true` on selected entries
5. Write updated JSON
6. The PostToolUse hook regenerates the active view automatically
7. Report: entries archived, new active count

### --dry-run flag

List candidates without modifying anything.

### Never auto-archive

- Entries above `archival_max_severity` — always require explicit human selection
- Entries less than 30 days old regardless of severity

## Subcommand: stats

Show learning statistics without modifying anything.

### Output Format

```
ADD LEARNINGS STATISTICS
========================

Tier 3 (Project): .add/learnings.json
  Total entries: 34
  Active (non-archived): 34
  By severity: 1 critical, 9 high, 18 medium, 6 low
  By category: 8 technical, 7 architecture, 5 anti-pattern, 1 performance, 9 process, 4 collaboration
  Oldest: L-001 (2026-02-08)
  Newest: L-034 (2026-02-19)
  JSON size: 19,280 bytes
  Active view: 5,494 bytes (72% smaller)
  Active view exists: yes (generated 2026-04-14)

Tier 2 (Library): ~/.claude/add/library.json
  Total entries: 4
  Active view exists: no
  Recommendation: Run /add:learnings migrate to generate active view

Archive candidates (>archival_days, severity ≤ medium): 12 entries
  Recommendation: Run /add:learnings archive to review
```

## Error Handling

| Error | Action |
|-------|--------|
| `jq` not installed | Report: "jq is required for active view generation. Install: brew install jq (macOS) or apt install jq (Linux)" |
| JSON parse error | Report the error, suggest checking file manually. Do not modify. |
| Filter script missing | Report: "filter-learnings.sh not found at expected path. Plugin may need reinstallation." |
| Backup already exists | Append timestamp: `.pre-migration-{YYYYMMDD-HHMMSS}.bak` |
| Empty entries array | Generate empty active view, report "No entries to process" |

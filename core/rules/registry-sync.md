---
autoload: true
maturity: poc
---

# ADD Rule: Project Registry Sync

The cross-project registry at `~/.claude/add/projects/{name}.json` is how `/add:init` on new projects and `/add:retro` cross-project promotion find prior work. When it drifts from the project's ground truth, those workflows silently degrade.

## When This Runs

On every session start, AFTER `version-migration.md` has completed:

1. Read `.add/config.json` → extract project name
2. Locate registry: `~/.claude/add/projects/{name}.json`
3. If registry does not exist → skip silently (pre-init project or intentionally unregistered)
4. If registry exists → compare to ground truth

## Ground-Truth Comparison

| Registry Field | Ground Truth | Drift Threshold |
|---|---|---|
| `learnings_count` | `jq '.entries | length' .add/learnings.json` (or lines in `.add/learnings.md` starting with `-` if JSON absent) | Actual > 3× registry value OR actual − registry > 20 |
| `last_retro` | Newest filename in `.add/retros/retro-*.md` (extract date) | Registry is null but retro file exists, OR registry is > 14 days older than newest retro |
| `maturity` | `.add/config.json` maturity.level | Any mismatch |
| `tier` | `.add/config.json` environments.tier | Any mismatch |

## On Drift Detection

Emit ONE compact drift notice at session start. Do not re-emit during the session.

```
📋 Registry drift detected for {project}:
   • learnings_count: registry 5 vs actual 55
   • last_retro: registry null vs 2026-04-12
   Run /add:init --sync-registry to reconcile. (Safe: read-only comparison,
   no project files modified.)
```

Do not block. Do not auto-update the registry without user approval — the registry is machine-local state that the user may have intentionally customized.

## Sync Command

When the user runs `/add:init --sync-registry`:

1. Read ground truth (learnings count, latest retro, maturity, tier, stack)
2. Compute a diff against the current registry
3. Present the diff, ask for confirmation
4. Write the reconciled registry file
5. Report what changed

## Auto-Bump on Checkpoint

When any skill writes to `.add/learnings.json`, `.add/retros/retro-*.md`, or promotes the project's maturity level, also:

1. Read the current registry (`~/.claude/add/projects/{name}.json`)
2. If it exists, update the corresponding field:
   - After learning write → increment `learnings_count`
   - After retro write → set `last_retro` to today
   - After maturity promotion → update `maturity`
3. Write the registry back

If the registry does not exist, skip silently (no auto-creation — that's `/add:init`'s job).

## Why This Exists

Evidence from the agentVoice dog-food project:

- Registry `learnings_count: 5` vs actual 55 (11× drift)
- Registry `last_retro: null` vs actual 2026-04-12 (missed entirely)
- Result: `/add:init` on a sister project would have said "agentVoice has 5 learnings, alpha maturity" — wrong on both counts, reducing the value of cross-project memory to zero.

The registry should be a trusted, auto-maintained mirror of ground truth. This rule keeps it one.

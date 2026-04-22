# ADD Troubleshooting

Common issues and their fixes. If your problem isn't here, open an issue: https://github.com/MountainUnicorn/add/issues

## Install

### "Marketplace not found" after `claude plugin marketplace add MountainUnicorn/add`

**Cause:** Claude Code needs to be restarted after adding a marketplace.

```bash
# Exit any running Claude Code sessions, then:
claude plugin marketplace list   # confirm "add-marketplace" is listed
claude plugin install add@add-marketplace
```

### "Plugin install failed — stale cache"

Symptoms: install command exits silently, or `/add:init` reports "plugin not found" even after a successful install.

**Fix:** Clear the plugin cache and reinstall.

```bash
rm -rf ~/.claude/plugins/cache/add-marketplace
claude plugin marketplace add MountainUnicorn/add
claude plugin install add@add-marketplace
```

### "I see `/add:init` but running it does nothing"

**Cause:** The plugin installed but rules failed to auto-load. Verify:

```bash
# In your project, start Claude Code and run:
/add:init
```

If the interview doesn't start, check that `.add/config.json` exists in your project. If it does, and the interview still doesn't run, the plugin is likely installed but the skills directory wasn't parsed. Run:

```bash
claude plugin info add@add-marketplace
# Look for "skills: 26" or similar — confirms skills were picked up
```

If skills show 0 or the command returns nothing, reinstall (see stale cache fix above).

### "I want to try ADD without marketplace install"

Clone the repo and point Claude at it directly:

```bash
git clone https://github.com/MountainUnicorn/add
cd add
claude --plugin-dir ./plugins/add
```

This works for contributors and users who want to pin to a specific commit.

## First-Run

### `/add:init` seems too long

The default interview asks ~12 questions to capture maturity, stack, and collaboration preferences. For a faster start:

```bash
/add:init --quick          # 5 essential questions, ~2 minutes (greenfield projects)
/add:init --reconfigure    # re-run the full interview to change settings
```

`--quick` asks only: project name, stack, environment tier, maturity, and autonomy level. Everything else gets sensible defaults. You can always run `--reconfigure` later for the full interview.

### "I don't understand question N"

This is a supported case, not a failure. Type "I don't understand" or ask for clarification — the agent will re-ask via a structured prompt (see `rules/human-collaboration.md` > Confusion Protocol).

### "The agent is asking for a spec I don't have"

This is intended behavior. ADD refuses to write implementation code without a spec in `specs/`. Create one:

```bash
/add:spec "short feature name"
```

Or, if you're exploring, set maturity to `poc` in `.add/config.json` — POC projects don't require specs.

## Hooks Not Running

### Ruff / ESLint don't run after Write

**Check:** ADD's hooks require `jq` on the PATH (for stdin JSON extraction).

```bash
which jq     # should print a path
```

If `jq` is missing:
- macOS: `brew install jq`
- Debian/Ubuntu: `apt install jq`
- Nix/elsewhere: see https://stedolan.github.io/jq/download/

Also verify:
- `ruff` is on PATH for Python files (`pip install ruff`)
- `eslint` is available via `npx` for TS/TSX files (standard in Node projects)

Hooks fail silently by design — a broken lint pass shouldn't break your edit. Check the output above the Write result to see any hook stderr.

## Rules Not Applying

### "The agent commits without running tests"

**Check the maturity level.** TDD enforcement only activates at `beta` or `ga` maturity. `.add/config.json`:

```json
{
  "maturity": {
    "level": "beta"
  }
}
```

POC and alpha have relaxed rules. See `rules/maturity-lifecycle.md` for the full cascade.

### "Why is the agent asking 15 questions when I said 'just build it'?"

ADD's `human-collaboration` rule (interview protocol) is active from alpha onward. The rule explicitly says NEVER batch 5+ questions AND never generate a spec without a confirmation gate. This is working as designed.

If you want lower-ceremony interaction: `.add/config.json` `collaboration.autonomy_level: "autonomous"` reduces check-ins.

## Cross-Project Knowledge

### "My learnings from other projects don't show up"

ADD reads three knowledge tiers:

1. **Tier 1 (plugin-global):** `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md`
2. **Tier 2 (user-local):** `~/.claude/add/library.json`
3. **Tier 3 (project-specific):** `.add/learnings.json`

Tier 2 is machine-local. If you switched devices, run:

```bash
/add:init --import    # reconstructs ~/.claude/add/profile.md and projects/ index
```

Cross-project learnings accumulate via `/add:retro` — retros promote qualifying entries from project to workstation tier.

### "My `~/.claude/add/projects/{name}.json` says `learnings_count: 5` but I have 55"

Registry drift. v0.6.0 added `rules/registry-sync.md` which auto-bumps on checkpoint writes. For projects that pre-date v0.6.0, run:

```bash
# (coming in v0.7.1)
/add:init --sync-registry
```

Until then, you can manually edit the registry file.

## Version Issues

### "I installed ADD but it says v0.4.0 not v0.7.0"

Your marketplace cache is stale.

```bash
rm -rf ~/.claude/plugins/cache/add-marketplace
claude plugin marketplace add MountainUnicorn/add
claude plugin install add@add-marketplace
```

### "After upgrade, my project files look out of date"

ADD's `rules/version-migration.md` runs on every session start. If your `.add/config.json` version is older than the installed plugin, migration runs automatically. Check `.add/migration-log.md` for what changed.

If migration didn't run, verify:
- `.add/config.json` exists and has a `version` field
- The plugin is actually loaded (see "I see `/add:init`..." above)

## Codex (v0.7.0+)

### "I installed Codex prompts but ADD doesn't seem active"

Codex reads `AGENTS.md` at the project root. The install script places it there only if one doesn't already exist. If you already had an `AGENTS.md`, the installer skipped it to avoid overwriting your content.

Merge manually:

```bash
# The generated file is at:
cat ~/.codex/add/AGENTS.md

# Append its content into your existing AGENTS.md
```

### "Codex prompts don't autocomplete"

Codex custom prompts are loaded from `~/.codex/prompts/*.md`. Verify:

```bash
ls ~/.codex/prompts/add-*.md    # should list ~24 files
```

If missing, re-run the install script:

```bash
./scripts/install-codex.sh
```

## Still Stuck?

1. Search existing issues: https://github.com/MountainUnicorn/add/issues
2. Run `claude plugin info add@add-marketplace` and include the output
3. Open a new issue with: Claude Code version, OS, ADD version, and what you expected vs what happened

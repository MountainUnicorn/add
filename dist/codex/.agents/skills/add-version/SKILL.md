---
name: add-version
description: "[ADD v0.9.5] Show installed version, project version, and upgrade status"
argument-hint: "[--check]"
---

# ADD Version Command v0.9.5

Show the current ADD version, compare project config version to plugin version, and flag drift.

## Execution

1. **Read plugin version** from `~/.codex/add/` — try sources in order, first hit wins:
   1. `.claude-plugin/plugin.json` → `version` field (Claude runtime)
   2. `plugin.toml` → `version` field (Codex runtime)
   3. `VERSION` (plain-text, single line — fallback for both runtimes)

   On the Claude runtime, source 1 is authoritative and sources 2–3 are absent. On the Codex runtime (`~/.codex/add` resolves to `~/.codex/add`), source 1 is absent; read source 2 or 3. Never emit an error if source 1 is missing — fall through quietly.
2. **Read project version** from `.add/config.json` → `version` field (if file exists)
3. **Read core/VERSION** if accessible (development installs only)

### Output

```
ADD Version
  Plugin:  v{plugin_version}
  Project: v{project_version}    (from .add/config.json)
  Status:  {status}
```

**Status values:**

| Condition | Status | Action |
|---|---|---|
| project == plugin | `✓ Up to date` | None |
| project < plugin | `⚠ Project config is behind — migration will run on next skill invocation` | Suggest: "Run any /add: command to trigger auto-migration, or /add:init --reconfigure for a full refresh." |
| project > plugin | `⚠ Project config is ahead of plugin — you may be on an older plugin version` | Suggest: "Run: claude plugin update add@add-marketplace" |
| No .add/config.json | `○ Not an ADD project — run /add:init to get started` | — |

### --check flag

When invoked with `--check`, output a single machine-readable line and exit:

```
add:version plugin={plugin_version} project={project_version} status={up_to_date|behind|ahead|uninitialized}
```

This is for scripting and CI — e.g., a pre-commit hook that warns if the project version is stale.

### Changelog summary (when behind)

If project < plugin and a `CHANGELOG.md` exists at the plugin or repo root, extract the version sections between the project version and the plugin version and display:

```
ADD Version
  Plugin:  v0.8.0
  Project: v0.5.0    (from .add/config.json)
  Status:  ⚠ Project config is behind — migration will run on next skill invocation

  What changed since v0.5.0:
    v0.6.0 — Community release (3 new skills: docs, ux, milestone/roadmap/promote)
    v0.7.0 — Multi-runtime architecture (Claude + Codex), security hardening
    v0.7.1 — Deploy confirm-phrase gate, /add:init --quick, PII heuristic
    v0.7.2 — GPG signing infrastructure
    v0.7.3 — First GitHub-Verified signed release
    v0.8.0 — Pre-filtered active learning views (62-82% context reduction)
```

Extract the `## [X.Y.Z]` headings from CHANGELOG.md and show the first line of each section (the subtitle after the date/dash). Cap at 10 versions.

If no CHANGELOG.md is accessible, skip this section silently.

# Spec: Plugin Installation Reliability

**Version:** 0.1.0
**Created:** 2026-03-01
**PRD Reference:** docs/prd.md
**Status:** Superseded
**Target Release:** v0.5.0
**Superseded by:** v0.5.0 plugin isolation (`plugins/add/` restructure) and v0.7.0 source-of-truth split (`core/` + `runtimes/` + `scripts/compile.py`). Counts referenced in this spec body (10 commands, 9 skills, 13 rules) reflect repo state at drafting time on 2026-03-01; today's plugin has 26 skills and 15 rules. Retained as a historical record of the install-reliability investigation that drove the v0.5/v0.7 work.

## 1. Overview

ADD currently fails to install via `claude plugin install add`. Updates also fail. The only working path is cloning the repo manually and pointing Claude Code at it. This makes ADD effectively inaccessible to anyone who doesn't already know how to work around the problem.

This spec defines the structural changes needed to make ADD install, update, and uninstall cleanly through Claude Code's standard plugin system.

### Root Causes Identified

1. **ADD is not in any default marketplace.** `claude plugin install add` can't resolve because ADD isn't listed in `claude-plugins-official`. The submission from 2026-02-14 has gone unanswered.
2. **Dual identity conflict.** The repo has both `plugin.json` and `marketplace.json` in `.claude-plugin/`, making it simultaneously a marketplace and a plugin. Official plugins never do this.
3. **Self-referential source path.** `marketplace.json` declares `"source": "./"`, which copies the entire repo (including `website/`, `docs/`, `specs/`, dashboard prototypes, `.add/` project state) into the plugin cache. There is no `.pluginignore` mechanism in the plugin system.
4. **`rules/` is not a recognized plugin directory.** The official plugin spec supports `commands/`, `skills/`, `agents/`, `hooks/`. ADD's 13 rule files — core to its behavior — have no guaranteed auto-loading mechanism.
5. **`knowledge/` and `templates/` are non-standard.** Same issue as `rules/` — no recognized auto-loading path.
6. **Install instructions are wrong.** Docs say `claude plugin install add` but the correct two-step process is `claude plugin marketplace add MountainUnicorn/add` then `claude plugin install add@add-marketplace`.
7. **Version declared in two places.** Both `plugin.json` and `marketplace.json` declare version, which the docs warn against.

### Design Principles

1. **Match the official pattern.** Structure the repo exactly like `anthropics/claude-plugins-official`. Don't invent — follow.
2. **Separate marketplace from plugin.** The catalog and the plugin content live in distinct locations within the repo.
3. **Ship only plugin content.** Non-plugin files (website, docs, specs, project state) never reach the user's cache.
4. **Two distribution paths.** Self-hosted marketplace (works today) and official marketplace submission (works when accepted).
5. **Verify rules actually load.** Don't assume `rules/` works — test it and fix if needed.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | Repo restructured: plugin content lives in `plugins/add/` with its own `.claude-plugin/plugin.json` | Must |
| AC-002 | Root `.claude-plugin/marketplace.json` references plugin via `"source": "./plugins/add"` (not `"./"`) | Must |
| AC-003 | `plugins/add/` contains ONLY plugin-relevant directories: `commands/`, `skills/`, `rules/`, `hooks/`, `knowledge/`, `templates/`, `CLAUDE.md`, `README.md`, `LICENSE` | Must |
| AC-004 | Non-plugin content (`website/`, `docs/`, `specs/`, `reports/`, `tests/`, `.add/`, dashboard HTML files, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CONTRIBUTORS.md`) stays at repo root, is NOT inside `plugins/add/` | Must |
| AC-005 | `claude plugin marketplace add MountainUnicorn/add` succeeds without errors | Must |
| AC-006 | `claude plugin install add@add-marketplace` succeeds without errors | Must |
| AC-007 | After install, all 10 commands are available and functional (`/add:init`, `/add:spec`, `/add:plan`, `/add:away`, `/add:back`, `/add:retro`, `/add:cycle`, `/add:brand`, `/add:brand-update`, `/add:dashboard`) | Must |
| AC-008 | After install, all 9 skills are available and functional | Must |
| AC-009 | After install, all 13 rule files auto-load into Claude Code sessions | Must |
| AC-010 | If `rules/` does not auto-load from plugin directory, rules are delivered via an alternative mechanism (CLAUDE.md includes, settings.json, or equivalent) that achieves the same behavior | Must |
| AC-011 | `templates/` and `knowledge/` files are accessible to commands/skills after install (resolvable via `${CLAUDE_PLUGIN_ROOT}` or equivalent) | Must |
| AC-012 | Plugin cache size after install is under 500KB (current repo is 900KB+ with non-plugin content) | Should |
| AC-013 | `plugin.json` declares version; marketplace plugin entry does NOT duplicate version | Should |
| AC-014 | Remove `$schema` and `metadata` fields from `marketplace.json` to match official marketplace format | Should |
| AC-015 | File permissions on all plugin files are `644` (world-readable) | Should |
| AC-016 | Plugin updates work: incrementing version in `plugin.json` and pushing causes `claude plugin update` to pick up changes | Must |
| AC-017 | Plugin uninstall works cleanly: `claude plugin uninstall add@add-marketplace` removes all cached files | Should |
| AC-018 | README and website install instructions updated to show the two-step marketplace install process | Must |
| AC-019 | README includes a "Quick Install" section with copy-pasteable commands | Must |
| AC-020 | Website docs page updated with troubleshooting section for common install failures | Should |
| AC-021 | Official marketplace submission re-submitted with corrected structure and followed up on | Must |
| AC-022 | If accepted into official marketplace, install simplifies to `claude plugin install add` — docs updated accordingly | Nice |

## 3. Proposed Repo Structure

### Current (broken)
```
add/                              ← repo root = marketplace + plugin + project
  .claude-plugin/
    plugin.json                   ← plugin manifest
    marketplace.json              ← marketplace catalog (dual identity)
  commands/                       ← plugin content at repo root
  skills/
  rules/
  hooks/
  knowledge/
  templates/
  CLAUDE.md
  website/                        ← gets copied into install
  docs/                           ← gets copied into install
  specs/                          ← gets copied into install
  reports/                        ← gets copied into install
  .add/                           ← gets copied into install
  dashboard-prototype.html        ← gets copied into install
  dashboard-v2.html               ← gets copied into install
  ...
```

### Target (matches official pattern)
```
add/                              ← repo root = marketplace only
  .claude-plugin/
    marketplace.json              ← marketplace catalog (NO plugin.json here)
  plugins/
    add/                          ← plugin content isolated
      .claude-plugin/
        plugin.json               ← plugin manifest (only place version is declared)
      commands/
      skills/
      rules/
      hooks/
      knowledge/
      templates/
      CLAUDE.md
      README.md
      LICENSE
  CLAUDE.md                       ← project-level (for ADD development)
  README.md                       ← GitHub landing page
  website/                        ← stays at root, not shipped
  docs/                           ← stays at root, not shipped
  specs/                          ← stays at root, not shipped
  reports/                        ← stays at root, not shipped
  .add/                           ← stays at root, not shipped
  CONTRIBUTORS.md
  CONTRIBUTING.md
  CODE_OF_CONDUCT.md
  SECURITY.md
  LICENSE
```

## 4. Marketplace Manifest (Target)

```json
{
  "name": "add-marketplace",
  "description": "Agent Driven Development — AI-native SDLC methodology plugin for Claude Code",
  "owner": {
    "name": "MountainUnicorn",
    "email": "anthony@getadd.dev"
  },
  "plugins": [
    {
      "name": "add",
      "description": "Agent Driven Development (ADD) — Coordinated AI agent teams: test-writers, implementers, reviewers, deployers. Spec-driven TDD, trust-but-verify orchestration, maturity lifecycle, away mode, cross-project learning. 10 commands, 9 skills, 13 rules. Zero dependencies.",
      "author": {
        "name": "MountainUnicorn"
      },
      "source": "./plugins/add",
      "homepage": "https://getadd.dev",
      "repository": "https://github.com/MountainUnicorn/add",
      "license": "MIT",
      "category": "development",
      "keywords": [
        "agent-driven-development",
        "sdlc",
        "tdd",
        "methodology",
        "multi-agent",
        "orchestration",
        "spec-driven",
        "quality-gates"
      ]
    }
  ]
}
```

## 5. Plugin Manifest (Target)

```json
{
  "name": "add",
  "version": "0.5.0",
  "description": "Agent Driven Development (ADD) — Coordinated AI agent teams that ship verified software.",
  "author": {
    "name": "MountainUnicorn",
    "url": "https://github.com/MountainUnicorn"
  },
  "homepage": "https://getadd.dev",
  "repository": "https://github.com/MountainUnicorn/add"
}
```

## 6. Rules Loading Investigation

The `rules/` directory is critical to ADD but is not part of the official plugin directory spec. Before implementation, verify:

1. **Test A:** Install a plugin with a `rules/` directory. Do the `.md` files in `rules/` auto-load as system rules in Claude Code sessions? Check by looking for rule content in agent behavior.
2. **Test B:** If Test A fails, test whether rules can be delivered via a `CLAUDE.md` file that includes them (e.g., using file references or inlining).
3. **Test C:** If Test B fails, test whether `settings.json` in the plugin root can reference rule files.

**Fallback plan:** If `rules/` is not auto-loaded, consolidate all 13 rule files into the plugin's `CLAUDE.md` or split them across command/skill files that reference them. Document the chosen approach.

## 7. Install Instructions (Target)

### README Quick Install
```markdown
## Install

### From ADD Marketplace (recommended)
claude plugin marketplace add MountainUnicorn/add
claude plugin install add@add-marketplace

### Verify
/add:init

### Update
claude plugin update add@add-marketplace
```

### Website Docs — Troubleshooting Section
```markdown
## Troubleshooting

### "Plugin not found"
ADD is distributed through its own marketplace, not the default Claude Code
marketplace. Run the marketplace add command first:
claude plugin marketplace add MountainUnicorn/add

### "Marketplace already added"
If you've added the marketplace before but install still fails, clear the
cache and re-add:
claude plugin marketplace remove add-marketplace
claude plugin marketplace add MountainUnicorn/add
claude plugin install add@add-marketplace

### Install from source (development)
git clone https://github.com/MountainUnicorn/add.git
claude --plugin-dir ./add/plugins/add

### Verify installation
Run /add:init in any git repository. If the structured interview starts,
ADD is installed correctly.
```

## 8. Official Marketplace Submission

### Previous Submission
- Submitted: 2026-02-14
- Form: `clau.de/plugin-directory-submission`
- Status: No response as of 2026-03-01

### Re-submission Plan
1. Complete the repo restructure (AC-001 through AC-004)
2. Verify self-hosted install works end-to-end (AC-005 through AC-009)
3. Re-submit to `platform.claude.com/plugins/submit` with:
   - Updated repo structure matching official pattern
   - Link to getadd.dev
   - Brief description of the plugin's purpose and user base
   - Note that it's MIT licensed, zero dependencies, pure markdown/JSON
4. Follow up after 2 weeks if no response
5. Open a GitHub issue on `anthropics/claude-code` if submission process is unclear

## 9. User Test Cases

### TC-001: Fresh install from marketplace
**Precondition:** Claude Code installed, no ADD marketplace or plugin present.
**Steps:**
1. `claude plugin marketplace add MountainUnicorn/add`
2. `claude plugin install add@add-marketplace`
3. Open a new Claude Code session in a git repo
4. Run `/add:init`
**Expected:** Marketplace adds without error. Plugin installs without error. `/add:init` starts the structured interview.

### TC-002: Plugin update
**Precondition:** ADD installed at version 0.5.0. A new version 0.5.1 is pushed to GitHub.
**Steps:**
1. `claude plugin update add@add-marketplace`
2. Verify version changed
**Expected:** Update completes. New version is active.

### TC-003: Plugin uninstall and reinstall
**Precondition:** ADD installed.
**Steps:**
1. `claude plugin uninstall add@add-marketplace`
2. Verify `/add:init` no longer works
3. `claude plugin install add@add-marketplace`
4. Verify `/add:init` works again
**Expected:** Clean uninstall and reinstall cycle.

### TC-004: Rules load after install
**Precondition:** ADD installed via marketplace (not `--plugin-dir`).
**Steps:**
1. Open Claude Code in an ADD-managed project
2. Ask Claude to describe the TDD enforcement rules
3. Ask Claude to describe the human collaboration protocol
**Expected:** Claude exhibits behavior consistent with `rules/tdd-enforcement.md` and `rules/human-collaboration.md`. Rules are active, not ignored.

### TC-005: Cache size
**Precondition:** ADD installed via marketplace.
**Steps:**
1. Check `~/.claude/plugins/cache/add-marketplace/add/` size
**Expected:** Under 500KB. No `website/`, `docs/`, `specs/`, `reports/`, `.add/`, or dashboard HTML files present.

### TC-006: Install from source (fallback)
**Precondition:** Git installed, Claude Code installed, no marketplace added.
**Steps:**
1. `git clone https://github.com/MountainUnicorn/add.git`
2. `claude --plugin-dir ./add/plugins/add`
3. Run `/add:init`
**Expected:** Plugin loads from local directory. All commands and skills available.

## 10. Implementation Notes

- The restructure is a file move operation, not a rewrite. All plugin content moves into `plugins/add/` unchanged.
- The project-level `CLAUDE.md` (for ADD development) and the plugin-level `CLAUDE.md` (shipped to users) may need to be different files. The project one references specs, plans, and development workflow. The plugin one should only reference what users need.
- The `.pluginignore` file can be deleted — it was never parsed by the plugin system and the restructure makes it unnecessary.
- `dashboard-prototype.html` and `dashboard-v2.html` at the repo root are development artifacts and can be cleaned up or moved to `reports/`.
- Git history is preserved across the restructure since `git mv` tracks renames.

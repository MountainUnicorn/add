# Project Learnings — ADD

> **Tier 3: Project-Specific Knowledge**
> Generated from `.add/learnings.json` — do not edit directly.
> Agents read JSON for filtering; this file is for human review.

## Anti-Patterns

- **[critical] Bare command names in plugin files cause namespace drift** (L-016, 2026-02-08)
  Bare command names (/spec) in plugin files caused Claude to recommend /spec instead of /add:spec in consumer projects. Claude reads these files as instructions and reproduces the patterns it sees. Fix: namespace all references to /add:spec format.

- **[high] Away mode needs explicit autonomous operations grant** (L-017, 2026-02-08)
  Without explicit grant, agents fall back to 'ask the human' for routine commits/pushes during autonomous sessions. Fix: explicit 'autonomous operations' list (commit, push, create PRs) and 'boundaries' list (no production deploy, no merge to main).

- **[high] Claude Code enabledPlugins must be a record, not an array** (L-003, 2026-02-08)
  Claude Code enabledPlugins in .claude/settings.json must be a record ({"add": true}) not an array (["add"]). Array format causes 'Settings Error: Expected record, but received array' on startup and the entire settings file is skipped.

- **[high] Environment boundary is production, not staging** (L-019, 2026-02-08)
  Saying 'agents must NOT deploy to staging' is too blunt for Tier 2/3 projects. The real boundary is production. Fix: promotion ladder with autoPromote per-env config, automatic rollback on verification failure.

- **[medium] Away mode should default to 2 hours, don't ask** (L-018, 2026-02-08)
  Asking for duration when none provided is unnecessary friction when the human is trying to leave. Default to 2 hours.

## Technical

- **[high] Namespace fix: 205 bare references across 30 files** (L-026, 2026-02-08)
  Created README.md, SVG infographic, HTML overview report. Website built with raspberry palette. Critical: namespaced all 205 bare command references. Plugin files are Claude's instructions — whatever pattern is in the files, Claude reproduces it.

- **[medium] GitHub Pages deployment uses Actions workflow serving website/ directory** (L-001, 2026-02-08)
  GitHub Pages for this project uses Actions workflow at .github/workflows/pages.yml serving website/ directory — live at mountainunicorn.github.io/add/. Set build_type: workflow via gh api.

- **[medium] Local marketplace cache must be synced manually after changes** (L-002, 2026-02-08)
  Rsync from source to ~/.claude/plugins/cache/add-marketplace/add/0.1.0/ with excludes for project-specific state (.add/, .git/, reports/, website/, specs/, tests/, etc.).

- **[medium] GitHub README strips CSS/JS — SVG is only rich visual option** (L-028, 2026-02-08)
  GitHub README renders SVG inline but strips all CSS/JS. The SVG infographic is the only way to get rich visuals in a README. GitHub Pages is the solution for the full website experience.

## Architecture

- **[high] Environment promotion ladder with autoPromote per-env config** (L-008, 2026-02-08)
  Agents autonomously climb local → dev → staging when verification passes at each level, with automatic rollback on failure. Production always requires human. Ladder stops on first failure — no retries, log and move on.

- **[medium] Chose ~/.claude/add/ directory over single file for cross-project persistence** (L-004, 2026-02-07)
  Directory allows profile, library, and project index as separate concerns.

- **[medium] Project learnings committed to git, cross-project knowledge is machine-local** (L-005, 2026-02-07)
  Project-level learnings in .add/ are committed to git (device-portable). Cross-project knowledge in ~/.claude/add/ is machine-local (personal).

- **[medium] /add:init auto-detects existing projects for adoption mode** (L-006, 2026-02-07)
  No explicit --adopt flag needed (though supported). Existing project rules and skills are preserved, not replaced.

- **[medium] Chose 'cycle' over 'sprint' for work batching** (L-009, 2026-02-07)
  Sprints imply fixed calendar time; cycles are scope-boxed and end when validation criteria are met.

- **[medium] Maturity levels as single master dial in config.json** (L-010, 2026-02-07)
  Every rule checks maturity.level. Avoids having 14 separate toggles.

- **[medium] Swarm coordination: worktrees for beta/ga, file reservations for alpha** (L-013, 2026-02-07)
  2-5 parallel agents is practical; beyond that coordination overhead exceeds benefit.

- **[medium] WIP limits scale with maturity: poc=1, alpha=2, beta=4, ga=5** (L-014, 2026-02-07)
  Prevents coordination overhead from swamping execution.

- **[medium] Catch-up spike for non-greenfield adoption** (L-015, 2026-02-07)
  Gap analysis against maturity requirements, generates cycle-0-catchup.md with remediation items.

- **[low] Hill chart concept maps perfectly to ADD feature positions** (L-011, 2026-02-07)
  SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE.

- **[low] Now/Next/Later framing for milestones avoids fake date precision** (L-012, 2026-02-07)
  AI-agent work moves at unpredictable pace; fake dates create false precision.

## Performance

- **[medium] 10 autoloaded rules cost ~14K tokens (7% of 200K context)** (L-023, 2026-02-07)
  Heavy rules: agent-coordination (~3K), maturity-lifecycle (~2K). Consider conditional autoload. For now 14K is acceptable.

## Process

- **[high] Version bump checklist: 8 locations must be updated together** (L-024, 2026-02-14)
  plugin.json, marketplace.json, config.json, README.md, all commands, all skills, reports HTML, website footers.

- **[high] First retro: spec-before-code promoted to Tier 1** (L-025, 2026-02-17)
  4 specs were Draft despite having implementations — spec-after-code violation. Dog-food the methodology or lose credibility.

- **[medium] Dog-food trial on dossierFYI validated adoption mode** (L-022, 2026-02-07)
  Plugin installed successfully. Phase 0 Discovery worked end-to-end. Maturity detection matched human intuition.

- **[medium] Dog-fooding across multiple projects catches issues quickly** (L-007, 2026-02-08)
  Caught the namespace issue quickly. Enterprise plugin's phased execution informed the quality gate system.

- **[low] v0.1.0 built in single session: 36 files, ~6,300 lines** (L-020, 2026-02-07)
  All rules, commands, skills, and templates written in one session.

- **[low] Maturity + chunking + swarm added in one session** (L-021, 2026-02-07)
  Added maturity lifecycle rule, work hierarchy, /add:cycle, swarm coordination. Promoted ADD from POC to Alpha.

- **[low] First away session: 4 tasks completed in ~10 minutes** (L-027, 2026-02-08)
  45-minute window, all 4 tasks done in ~10 min. Parallel subagents for HTML report + SVG infographic.

---
*28 entries. Last updated: 2026-02-17. Source: .add/learnings.json*

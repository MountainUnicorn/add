# Project Learnings — ADD

> **Tier 3: Project-Specific Knowledge**
>
> This file is maintained automatically by ADD agents. Entries are added at checkpoints
> (after verify, TDD cycles, deployments, away sessions) and reviewed during retrospectives.
>
> Agents also read Tier 1 (knowledge/global.md) and Tier 2 (~/.claude/add/library.md).
>
> **Agents:** Read ALL three tiers before starting any task.
> **Humans:** Review with `/add:retro --agent-summary` or during full `/add:retro`.

## Technical Discoveries

> Universal plugin architecture and methodology entries promoted to Tier 1 (knowledge/global.md) on 2026-02-08.

- 2026-02-08: GitHub Pages deployment for this project uses Actions workflow at `.github/workflows/pages.yml` serving `website/` directory — live at `mountainunicorn.github.io/add/`. Set `build_type: workflow` via `gh api repos/{owner}/{repo}/pages -X POST -f build_type=workflow`.
- 2026-02-08: Local marketplace cache must be synced manually after changes: rsync from source to `~/.claude/plugins/cache/add-marketplace/add/0.1.0/` (with excludes for project-specific state).
- 2026-02-08: Claude Code `enabledPlugins` in `.claude/settings.json` must be a record (`{"add": true}`) not an array (`["add"]`). Array format causes "Settings Error: Expected record, but received array" on startup and the entire settings file is skipped.

## Architecture Decisions

- 2026-02-07: Chose `~/.claude/add/` (directory) over `~/.claude/add-profile.md` (single file) for cross-project persistence. Directory allows profile, library, and project index as separate concerns.
- 2026-02-07: Project-level learnings in `.add/learnings.md` are committed to git. Cross-project knowledge in `~/.claude/add/` is machine-local. This separates device-portable (git) from personal (local).
- 2026-02-07: Adopted the convention that /add:init auto-detects existing projects and switches to adoption mode. No explicit --adopt flag needed (though supported). Reduces friction for existing projects.
- 2026-02-07: Existing project rules and skills are preserved, not replaced. ADD adds alongside. Naming uses `add-` prefix only when there's a conflict.

## What Worked

> Universal methodology insights promoted to Tier 1 (knowledge/global.md) on 2026-02-08.

- The enterprise plugin's phased execution with audit (Phase 7) informed the quality gate system.
- 2026-02-08: Dog-fooding across multiple projects (dossierFYI, others) caught the namespace issue quickly in this project specifically.

## Architecture Decisions (continued)

- 2026-02-08: Environment promotion ladder — agents autonomously climb `local → dev → staging` when verification passes at each level, with automatic rollback on failure. Production always requires human. Per-environment `autoPromote` flag in config.json controls the ceiling. Solves the problem of agents blocking on "can I push to staging?" during away mode when e2e already passed in dev. Two rollback strategies: `revert-commit` (lighter, for dev) and `redeploy-previous-tag` (safer, for staging/production). The ladder stops on first failure — no retries, log and move on.
- 2026-02-07: Chose "cycle" over "sprint" for work batching. Sprints imply fixed calendar time; cycles are scope-boxed and end when validation criteria are met. Better fit for AI-agent pace.
- 2026-02-07: Maturity levels (poc/alpha/beta/ga) as a single `maturity.level` field in config.json. This is the master dial — every rule checks it. Avoids having 14 separate toggles.
- 2026-02-07: Hill chart concept from Shape Up (uphill = figuring out, downhill = executing) maps perfectly to ADD feature positions: SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE.
- 2026-02-07: Now/Next/Later framing for milestones instead of dates. AI-agent work moves at unpredictable pace; fake dates create false precision.
- 2026-02-07: Swarm coordination uses git worktrees for beta/ga (full isolation) and file reservations for alpha (lighter weight). Based on research showing 2-5 parallel agents is practical, beyond that coordination overhead exceeds benefit.
- 2026-02-07: WIP limits scale with maturity: poc=1, alpha=2, beta=4, ga=5. Prevents coordination overhead from swamping execution.
- 2026-02-07: Catch-up spike concept for non-greenfield adoption — gap analysis against maturity requirements, generates cycle-0-catchup.md with remediation items.

## What Didn't Work

- 2026-02-08: Bare command names (`/spec`) in plugin files caused Claude CLI to recommend `/spec` instead of `/add:spec` when the plugin was used in other projects. Every command, skill, rule, and template file contained bare references that Claude mimicked. Root cause: Claude reads these files as instructions and reproduces the patterns it sees. Fix: namespace all 205 references across 30 files to `/add:spec` format.
- 2026-02-08: Away mode was too restrictive — agents kept asking for permission to commit and push during autonomous sessions. The away command and human-collaboration rule didn't explicitly grant git autonomy, so agents fell back to default "ask the human" behavior for routine development tasks. Fix: added explicit "autonomous operations" list (commit, push, create PRs, fix quality gates) and "boundaries" list (no production deploy, no merging to main) to both files.
- 2026-02-08: Away mode asked for duration when none provided, which is an unnecessary question when the human is trying to leave. Fix: default to 2 hours.
- 2026-02-08: Multi-environment projects had agents stuck at environment boundaries during away mode. Original rule said "agents must NOT deploy to staging" — too blunt for Tier 2/3 projects where the whole point is verifying through environments. The real boundary is production, not staging. Fix: promotion ladder with `autoPromote` per-env config, automatic rollback on verification failure.

## Agent Checkpoints

### Checkpoint: Initial Build — 2026-02-07
- Built v0.1.0 in a single session: 36 files, ~6,300 lines
- All rules, commands, skills, and templates written
- Non-greenfield adoption flow designed from analysis of 9 real projects
- PRD written for the plugin itself (dog-fooding)

### Checkpoint: Maturity + Chunking + Swarm — 2026-02-07
- Added maturity lifecycle rule (master cascade for all ADD behavior)
- Added work hierarchy: Roadmap → Milestones → Cycles → Features → Tasks
- Added /add:cycle command for planning and tracking work batches
- Added swarm coordination protocol to agent-coordination rule
- Added milestone template with hill chart tracking
- Updated PRD with work hierarchy section (5.4), maturity lifecycle (6.6)
- Plugin now at: 6 commands, 8 skills, 10 rules, 10 templates = 44+ files
- Promoted ADD project itself from POC to Alpha maturity

### Checkpoint: Dog-Food Trial — dossierFYI Adoption — 2026-02-07
- Plugin installed successfully via `claude plugin marketplace add` + `claude plugin install add`
- Hooks format was WRONG: Claude Code expects `{hooks: {EventType: [{matcher, hooks}]}}` not `{hooks: [{type, tool, command}]}`. Fixed.
- Phase 0 Discovery worked end-to-end on dossierFYI: detected 4 rules, 12 skills, 4 specs, 27 plans, 2 CI/CD workflows, 5 Docker services
- Maturity detection assessed Alpha→Beta (5/5 alpha, 4.5/5 beta, 1/6 GA) — matches human intuition
- Catch-up spike identified 5 items to reach full Beta: coverage validation, milestone structure, remaining specs, code review enforcement, branch protection
- Estimated catch-up: 16-25 hours linear, 8-12 hours with 2 parallel agents
- No conflicts detected between existing dossierFYI rules/skills and ADD rules/skills
- The adoption mode output is comprehensive but long (~400 lines). Consider whether human users want a shorter summary with expand option.
- `specs/spike/` directory pattern (dossierFYI stores specs in a subdirectory) validates our decision to make specs_directory configurable in config.json
- Context window analysis: CLAUDE.md (111 lines, ~800 tokens) is fine. The real cost is 10 autoloaded rules at ~14K tokens (7% of 200K). Heavy rules: agent-coordination (~3K tokens with swarm), maturity-lifecycle (~2K tokens). For v0.2.0 consider: conditional autoload based on maturity level, progressive disclosure (core principle autoloaded + detail in linked file read on-demand), or YAML `paths` filtering so rules only activate for relevant file paths. For now, 14K is reasonable — optimize when dog-fooding reveals actual context pressure.

### Checkpoint: Version Consistency Audit — 2026-02-14
- After bumping to v0.2.0, found version references scattered across 20+ files in inconsistent states.
- **Version bump checklist** (all must be updated together):
  1. `.claude-plugin/plugin.json` — canonical version
  2. `.claude-plugin/marketplace.json` — marketplace metadata
  3. `.add/config.json` — project config `version` field
  4. `README.md` — badge
  5. All command files (`commands/*.md`) — `[ADD v{X}]` in description + `# ADD {Name} Command v{X}` heading
  6. All skill files (`skills/*/SKILL.md`) — `[ADD v{X}]` in description + `# ADD {Name} Skill v{X}` heading
  7. `reports/add-overview.html` — HTML comment, meta tag, and footer
  8. Website footer references (`website/**/*.html`)
- **Heading conventions** (enforce on new files):
  - Commands: `# ADD {Name} Command v{X}`
  - Skills: `# ADD {Name} Skill v{X}`
  - Rules: `# ADD Rule: {Name}` (no version — rules are structural, not versioned)
- **Grep audit command**: `grep -r 'v0\.\d\+\.\d\+' --include='*.md' --include='*.json' --include='*.html'` to find all version refs
- Historical/contextual references to past versions (PRD milestones, learnings, specs) should NOT be bumped — they refer to the version at time of writing.

## Profile Update Candidates

- 2026-02-07: Author consistently uses GitHub for git hosting across all projects. Promote to profile?
- 2026-02-07: Author prefers Python 3.11+ FastAPI + React 18 + TypeScript stack. Promote to profile?
- 2026-02-07: Author uses GCP (Cloud Run) for production deployment. Promote to profile?
- 2026-02-07: Author uses Docker Compose for local development on multi-service projects. Promote to profile?
- 2026-02-07: Author prefers conventional commits (feat:, fix:, docs:, etc.). Promote to profile?

### Checkpoint: Documentation & Namespace Fix — 2026-02-08
- Created comprehensive README.md, SVG infographic (docs/infographic.svg), and HTML overview report (reports/add-overview.html) following enterprise plugin's design system patterns
- Website (website/index.html) built as full SPA with raspberry palette (#b00149), dark/light toggle, agent swarm visualization, autonomy spectrum, work hierarchy with hill charts
- Initial SVG used wrong palette (purple #6366f1) and wrong messaging — had to rewrite to match website's raspberry theme and "Coordinated agent teams that ship verified software" headline
- GitHub Pages deployed via Actions workflow (.github/workflows/pages.yml) serving website/ directory — live at mountainunicorn.github.io/add/
- **Critical fix:** Namespaced all 205 bare command references across 30 files (`/spec` → `/add:spec`). This was causing Claude to recommend bare `/spec` in consumer projects instead of `/add:spec`. Plugin files are Claude's instructions — whatever naming pattern is in the files, Claude reproduces it.
- **Away mode improvements:** Default 2-hour duration (don't ask), explicit autonomous git operations (commit/push/PR without asking), PRD re-reading for alignment. Discovered during dog-fooding that agents blocked on routine commits during away sessions.
- Local marketplace cache must be synced manually after changes: rsync from source to `~/.claude/plugins/cache/add-marketplace/add/0.1.0/`
- GitHub README renders SVG inline but strips all CSS/JS — the SVG infographic is the only way to get rich visuals in a README. GitHub Pages is the solution for the full website experience.
- Distribution plan created (docs/distribution-plan.md) covering Phase 1-4 launch strategy: domain, GitHub, plugin registries, community announcements, awesome lists, AI directories, content series, SEO targets.
- **Environment promotion ladder:** Added `autoPromote` per-env config, automatic rollback on verification failure, `--promote` flag on deploy skill. Updated environment-awareness rule, away command, deploy skill, and human-collaboration rule. Key design choice: ladder stops on first failure (no retries) and rolls back to last known good — safer than letting agents debug deployment issues autonomously.

### Checkpoint: Away Session — 2026-02-08
- First real away mode session: 45-minute window, all 4 tasks completed in ~10 minutes.
- Parallel subagents for HTML report + SVG infographic edits — both completed concurrently while main agent tracked progress in away log.
- HTML overview report was significantly stale (bare command names, missing promotion ladder, old eyebrow). 10 edits brought it in sync with the website.
- SVG infographic expanded from 1800→2100px to accommodate promotion ladder visual. Section numbering and vertical offsets must be adjusted when adding sections mid-SVG — moved terminal and footer down 300px.
- CLAUDE.md was already up to date from the namespace fix session — no changes needed. Good signal that bulk-editing sessions are thorough.
- Away log + archive pattern works: `.add/away-log.md` as active log, archived to `.add/away-logs/away-{date}.md` on return. Gives clean history of autonomous sessions.
- All four documentation surfaces (website, HTML report, SVG infographic, CLAUDE.md) now consistent: namespaced commands, promotion ladder, raspberry palette.

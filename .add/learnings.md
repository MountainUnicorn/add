# Project Learnings — ADD

> This file is maintained automatically by ADD agents. Entries are added at checkpoints
> (after verify, TDD cycles, deployments, away sessions) and reviewed during retrospectives.
>
> **Agents:** Read this file before starting any task. Previous learnings may affect your approach.
> **Humans:** Review with `/retro --agent-summary` or during full `/retro`.

## Technical Discoveries

- 2026-02-07: macOS filesystems are case-insensitive. `add/` and `ADD/` are the same directory. Project directory names should use lowercase to avoid confusion.
- 2026-02-07: Claude Code plugin format uses `.claude-plugin/plugin.json` as the manifest. `marketplace.json` is a sibling for marketplace distribution.
- 2026-02-07: Rules with `autoload: true` in YAML frontmatter load automatically when Claude enters the project. This is the primary enforcement mechanism.
- 2026-02-07: Skills use `allowed-tools` in frontmatter to restrict what a skill can do. This enables agent isolation (test-writer can't deploy, reviewer can't edit).

## Architecture Decisions

- 2026-02-07: Chose `~/.claude/add/` (directory) over `~/.claude/add-profile.md` (single file) for cross-project persistence. Directory allows profile, library, and project index as separate concerns.
- 2026-02-07: Project-level learnings in `.add/learnings.md` are committed to git. Cross-project knowledge in `~/.claude/add/` is machine-local. This separates device-portable (git) from personal (local).
- 2026-02-07: Adopted the convention that /init auto-detects existing projects and switches to adoption mode. No explicit --adopt flag needed (though supported). Reduces friction for existing projects.
- 2026-02-07: Existing project rules and skills are preserved, not replaced. ADD adds alongside. Naming uses `add-` prefix only when there's a conflict.

## What Worked

- Deriving the ADD spec from a real, mature project (dossierFYI) ensured the methodology reflects actual practice, not theory.
- The 1-by-1 interview format with estimation ("~12 questions, ~10 minutes") was well-received during design. Prevents question fatigue.
- The enterprise plugin's phased execution with audit (Phase 7) informed the quality gate system.

## Architecture Decisions (continued)

- 2026-02-07: Chose "cycle" over "sprint" for work batching. Sprints imply fixed calendar time; cycles are scope-boxed and end when validation criteria are met. Better fit for AI-agent pace.
- 2026-02-07: Maturity levels (poc/alpha/beta/ga) as a single `maturity.level` field in config.json. This is the master dial — every rule checks it. Avoids having 14 separate toggles.
- 2026-02-07: Hill chart concept from Shape Up (uphill = figuring out, downhill = executing) maps perfectly to ADD feature positions: SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE.
- 2026-02-07: Now/Next/Later framing for milestones instead of dates. AI-agent work moves at unpredictable pace; fake dates create false precision.
- 2026-02-07: Swarm coordination uses git worktrees for beta/ga (full isolation) and file reservations for alpha (lighter weight). Based on research showing 2-5 parallel agents is practical, beyond that coordination overhead exceeds benefit.
- 2026-02-07: WIP limits scale with maturity: poc=1, alpha=2, beta=4, ga=5. Prevents coordination overhead from swamping execution.
- 2026-02-07: Catch-up spike concept for non-greenfield adoption — gap analysis against maturity requirements, generates cycle-0-catchup.md with remediation items.

## What Didn't Work

- (No entries yet — will populate during dog-fooding)

## Agent Checkpoints

### Checkpoint: Initial Build — 2026-02-07
- Built v0.1.0 in a single session: 36 files, ~6,300 lines
- All rules, commands, skills, and templates written
- Non-greenfield adoption flow designed from analysis of 9 real projects
- PRD written for the plugin itself (dog-fooding)

### Checkpoint: Maturity + Chunking + Swarm — 2026-02-07
- Added maturity lifecycle rule (master cascade for all ADD behavior)
- Added work hierarchy: Roadmap → Milestones → Cycles → Features → Tasks
- Added /cycle command for planning and tracking work batches
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

## Profile Update Candidates

- 2026-02-07: Author consistently uses GitHub for git hosting across all projects. Promote to profile?
- 2026-02-07: Author prefers Python 3.11+ FastAPI + React 18 + TypeScript stack. Promote to profile?
- 2026-02-07: Author uses GCP (Cloud Run) for production deployment. Promote to profile?
- 2026-02-07: Author uses Docker Compose for local development on multi-service projects. Promote to profile?
- 2026-02-07: Author prefers conventional commits (feat:, fix:, docs:, etc.). Promote to profile?

# Init Output Examples

Full-fidelity renderings for `/add:init` output panels. The skill keeps compact
summaries inline; render user-facing panels following these examples, filling
`{placeholders}` with real values and pruning lines that don't apply.

## Maturity Assessment Panel

Present the assessment authoritatively — do NOT ask the user to confirm or override the level:

```
MATURITY ASSESSMENT (evidence-based):
  Your project operates at: {ALPHA}

  Evidence detected:
    ✓ Tests exist (47% coverage)
    ✓ CI/CD configured (GitHub Actions)
    ✓ Conventional commits in use
    ✗ No feature specifications found
    ✗ No PR workflow detected (pushing directly to main)
    ✗ No environment separation
    ✗ No release tags
    ✗ No branch protection
    ✗ No TDD evidence
    ✗ No spec-driven evidence
    ✗ No quality gates configured

  Score: 3/12 evidence items → ALPHA

  GAP TO NEXT LEVEL (Beta):
    To promote from Alpha → Beta, you need:
    □ Feature specs for all user-facing features (create with /add:spec)
    □ Test coverage above 50% (currently 47%)
    □ PR workflow with code review
    □ At least 2 deployment environments
    □ TDD evidence (tests before implementation)

  This assessment is based on observed project behavior, not aspiration.
  Maturity can be promoted later via /add:retro or /add:cycle --complete
  when evidence supports the next level.
```

## Adoption Findings Panel

Shown after silent Phase 0 detection, before the adoption interview:

```
I've scanned your project and detected existing ADD-like methodology.
ADD is designed to complement what you have, not replace it.

EXISTING METHODOLOGY:
  CLAUDE.md: {✓ found | ✗ not found} {(lines, sections if found)}
  Rules: {N} existing rules in .claude/rules/
  Skills: {N} custom skills in .claude/skills/
  Specs: {N} existing specifications in {location}/
  Plans: {N} implementation plans in {location}/

EXISTING INFRASTRUCTURE:
  Stack: {detected languages, frameworks, versions}
  Git: {git_host} repository at {remote_url}
  CI/CD: {detected platform or "none"}
  Containers: {Docker / docker-compose or "none"}
  Environments: {Tier 1/2/3 detected or "unknown"}

WHAT ADD WOULD ADD (non-destructive):
  ✚ .add/config.json — centralized ADD configuration
  ✚ .add/learnings.md — agent knowledge base (auto-checkpoints)
  ✚ ADD-specific rules — human collaboration, source control, environment awareness
  ✚ Quality gate system — 5-level verification gates
  ✚ /add:retro command — retrospectives and learning promotion
  ✚ Cross-project persistence — ~/.claude/add/ for preferences and history

WHAT ADD WOULD PRESERVE (untouched):
  ✓ Your existing CLAUDE.md (ADD sections appended if you want them)
  ✓ Your existing rules in .claude/rules/ (untouched — ADD rules inject at session start)
  ✓ Your existing skills (ADD skills fill gaps only)
  ✓ Your existing specs and plans (preserved as-is)
  ✓ Your CI/CD pipelines and Docker configuration
  ✓ Your test structure and coverage thresholds
  ✓ All project history and git configuration

Proceed with adoption? This is entirely non-destructive — I'll add, not replace.
```

## Adoption Summary Panel

Shown at the end of adoption-mode init:

```
ADD adoption complete. Your project methodology is enhanced.

NEWLY CREATED:
  ✓ .add/config.json — ADD configuration (points to your existing specs, plans, etc.)
  ✓ .add/learnings.md — Seeded with project knowledge (from CLAUDE.md, git history)

ENHANCED:
  ✓ CLAUDE.md — ADD methodology section appended
  ✓ ADD rules — injected each session by the plugin (nothing copied; your .claude/rules/ unchanged)
  ✓ .claude/skills/ — {N} new ADD skills added (your existing skills unchanged)

PRESERVED EXACTLY AS-IS:
  ✓ {existing_specs_location} — {N} feature specs
  ✓ {existing_plans_location} — {N} implementation plans
  ✓ Your CI/CD pipelines
  ✓ Your Docker configuration
  ✓ Your test structure and framework
  ✓ All project history

Your project is now configured as:
  Stack: {languages, frameworks, versions}
  Tier: {N} ({description})
  Quality: {mode}
  Autonomy: {level}

Next steps:
  1. Review .add/config.json and adjust if needed
  2. Review .add/learnings.md and add any missing patterns
  3. Continue using your existing /commands and /skills
  4. Try /add:spec to create ADD-formatted specs alongside your existing ones
  5. Run /add:retro to checkpoint learnings and refine methodology
```

## Phase 5 Init Summary Panel

Shown at the end of greenfield/full init:

```
ADD initialized successfully.

PROJECT STRUCTURE:
  ✓ .add/config.json          — project configuration
  ✓ .add/learnings.md         — agent knowledge base (committed, auto-populates)
  ✓ .add/cycles/              — cycle plans and history
  ✓ docs/prd.md               — Product Requirements Document
  ✓ docs/milestones/          — milestone tracking (hill charts)
  ✓ .claude/settings.json     — Claude Code settings (status line: /ADD:enabled)
  ✓ specs/                    — feature specifications
  ✓ docs/plans/               — implementation plans
  ✓ tests/screenshots/        — visual verification
  ✓ tests/{e2e,unit,integration}/ — test directories
  ✓ CLAUDE.md                 — project context

RULES INSTALLED:
  {for each installed rule:}
  ✓ ADD rules — injected at session start (maturity-gated, auto-updating)
  {for each skipped rule:}
  ○ stale ADD copies removed from .claude/rules/: {list or none}
  {for each prefixed rule:}

CROSS-PROJECT:
  ✓ ~/.claude/add/profile.md          — your preferences (if created)
  ✓ ~/.claude/add/projects/{name}.json — project index entry
  ✓ ~/.claude/add/library.md          — cross-project knowledge

KNOWLEDGE SOURCES (3-tier cascade — agents read all before starting work):
  Tier 1: Plugin-global  — knowledge/global.md (ships with ADD, universal best practices)
  Tier 2: User-local     — ~/.claude/add/library.md (your cross-project wisdom)
  Tier 3: Project        — .add/learnings.md (this project's discoveries, auto-populates)

Your project is configured as:
  Stack: {languages, frameworks, versions}
  Infrastructure: {git_host} → {cicd} → {cloud_provider}
  Environment: Tier {N} ({description})
  Maturity: {level} ({description of what this means})
  Quality: {mode} (coverage threshold: {N}%)
  Autonomy: {level}
  Branching: {strategy}

WHAT'S COMMITTED (ports between devices via git):
  .add/config.json, .add/learnings.md, .add/retros/,
  specs/, docs/, tests/screenshots/{features}/

WHAT'S LOCAL (stays on this machine):
  ~/.claude/add/ (profile, library, project index)
  Run /add:init --import on a new device to rebuild from committed state.
```

## Persona-Aware Next Steps Blocks

Display exactly ONE of the following, chosen per the rules in the init skill.

**If maturity = poc:**

```
WHAT TO DO NEXT (prototype mode — lightweight):

  You're at POC maturity. Specs are optional. TDD is recommended but not enforced.
  The fastest path to your first working feature:

  1. /add:tdd-cycle — jump straight into coding with tests (~20 min for a small feature)
  2. /add:verify    — run quality gates to check your work (~2 min)

  Optional (when you want more structure):
  • /add:spec "feature name"  — define a feature before coding (~5 min)
  • /add:retro                — capture what you learned after a session

  Estimated time to first feature: ~25 minutes.
```

**If maturity = alpha or beta:**

```
WHAT TO DO NEXT:

  1. /add:spec "your first feature"   — define one feature through a short interview (~5 min)
     This produces specs/{feature}.md with acceptance criteria and test cases.

  2. /add:plan specs/{feature}.md     — break it into implementation tasks (~3 min)

  3. /add:tdd-cycle specs/{feature}.md — build it with tests: RED → GREEN → REFACTOR → VERIFY (~20 min)

  4. /add:verify                      — confirm all quality gates pass (~2 min)

  First feature end-to-end: ~30 minutes. Second feature: faster (patterns learned).

  Other useful commands:
  • /add:away      — hand off to the agent for autonomous work
  • /add:retro     — run a retrospective to capture learnings
  • /add:cycle     — plan a batch of features with milestone tracking
```

**If the user appears to be a PM / non-engineer:**

```
YOUR ROLE IN ADD:

  As a product person, you'll primarily use two commands:

  1. /add:spec "feature name"   — define what you want built (~5 min interview)
     ADD captures your requirements as acceptance criteria. Your dev team
     builds from these specs — no ambiguity, no telephone game.

  2. /add:verify                — check if a feature meets the spec you defined

  You don't need to run /add:plan, /add:tdd-cycle, or /add:deploy — those
  are for the engineering workflow. Your specs are the source of truth.

  Try it now: /add:spec "your most important feature"
```

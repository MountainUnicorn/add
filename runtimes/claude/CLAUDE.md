# ADD — Agent Driven Development

A methodology plugin for Claude Code where AI agents are first-class development team members.

## What ADD Is

ADD (Agent Driven Development) is a structured SDLC methodology — like TDD or BDD, but designed for the reality that AI agents do the development work while humans architect, interview, decide, and verify.

The core principles:
1. **Specs before code** — Everything flows from specifications
2. **Test before implementation** — Strict TDD (RED → GREEN → REFACTOR → VERIFY)
3. **Trust but verify** — Sub-agents work, orchestrators independently verify
4. **Structured collaboration** — Interviews, away mode, decision points, engagement modes
5. **Environment awareness** — Skills adapt to your deployment tier
6. **Continuous learning** — Agents accumulate knowledge through checkpoints, retrospectives propagate lessons

## Plugin Structure

```
add/
├── skills/            # All slash commands and workflow skills (/add:init, /add:spec, /add:tdd-cycle, etc.)
├── rules/             # Auto-loading behavioral rules (13 files)
├── hooks/             # PostToolUse automation
├── knowledge/         # Tier 1: Plugin-global curated best practices (read-only in consumer projects)
│   └── global.md      # Universal learnings that ship with ADD for all users
└── templates/         # Document scaffolding (PRD, spec, plan, config, learnings, retro, profile)
```

## Document Hierarchy

```
Roadmap (docs/prd.md milestones section)
 → Milestones (docs/milestones/M{N}-{name}.md)
   → Cycles (.add/cycles/cycle-{N}.md)
     → Feature Specs (specs/{feature}.md)
       → Implementation Plans (docs/plans/{feature}-plan.md)
         → User Test Cases (in spec)
           → Automated Tests (RED phase)
             → Implementation (GREEN phase)
```

## Getting Started

1. Install: `claude plugin marketplace add MountainUnicorn/add && claude plugin install add@add-marketplace`
2. Initialize: `/add:init` (runs structured interview)
3. Create specs: `/add:spec` (per feature)
4. Plan: `/add:plan specs/{feature}.md`
5. Build: `/add:tdd-cycle specs/{feature}.md`
6. Verify: `/add:verify`
7. Deploy: `/add:deploy`

## Key Skills

| Command | Purpose |
|---------|---------|
| `/add:init` | Bootstrap ADD in a new project (PRD interview) |
| `/add:spec` | Create a feature spec (feature interview) |
| `/add:plan` | Generate implementation plan from spec |
| `/add:tdd-cycle` | Execute full TDD cycle against spec |
| `/add:test-writer` | RED phase only — write failing tests |
| `/add:implementer` | GREEN phase only — make tests pass |
| `/add:reviewer` | Code review for spec compliance |
| `/add:verify` | Run quality gates |
| `/add:optimize` | Performance optimization pass |
| `/add:deploy` | Environment-aware deployment |
| `/add:brand` | View project branding, drift detection, image gen status |
| `/add:brand-update` | Update branding materials and audit artifacts |
| `/add:changelog` | Generate/update CHANGELOG.md from conventional commits |
| `/add:infographic` | Generate project infographic SVG from PRD + config |
| `/add:away` | Human stepping away — autonomous work plan |
| `/add:back` | Human returning — get briefing |
| `/add:retro` | Retrospective — human-initiated or agent summary |
| `/add:cycle` | Plan, track, and complete work cycles within milestones |
| `/add:roadmap` | View and manage roadmap — milestones, horizons, reordering |
| `/add:milestone` | Manage milestones — list, switch, split, rescope, create |
| `/add:promote` | Maturity promotion — gap analysis and level-up workflow |
| `/add:learnings` | Manage learnings — generate active views, archive, stats |
| `/add:dashboard` | Generate visual HTML project dashboard from .add/ project files |

## Rules

@rules/spec-driven.md
@rules/tdd-enforcement.md
@rules/human-collaboration.md
@rules/agent-coordination.md
@rules/source-control.md
@rules/environment-awareness.md
@rules/quality-gates.md
@rules/learning.md
@rules/version-migration.md
@rules/project-structure.md
@rules/maturity-lifecycle.md
@rules/maturity-loader.md
@rules/design-system.md
@rules/add-compliance.md
@rules/registry-sync.md

## Work Hierarchy

```
Maturity Level (poc → alpha → beta → ga) governs rigor at every level:

Roadmap (Now / Next / Later milestones)
 → Milestone (hill chart: features moving uphill → downhill)
   → Cycle (next batch of work, parallel strategy, validation)
     → Feature (spec → plan → TDD → verify)
```


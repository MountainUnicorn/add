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
├── commands/          # Slash commands (/add:init, /add:spec, /add:away, /add:back, /add:retro, /add:cycle)
├── skills/            # Workflow skills (/add:tdd-cycle, /add:verify, /add:plan, etc.)
├── rules/             # Auto-loading behavioral rules (10 files)
├── hooks/             # PostToolUse automation
├── knowledge/         # Tier 1: Plugin-global curated best practices (read-only in consumer projects)
│   └── global.md      # Universal learnings that ship with ADD for all users
└── templates/         # Document scaffolding (PRD, spec, plan, config, learnings, profile)
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

1. Install: `claude plugin install add`
2. Initialize: `/add:init` (runs structured interview)
3. Create specs: `/add:spec` (per feature)
4. Plan: `/add:plan specs/{feature}.md`
5. Build: `/add:tdd-cycle specs/{feature}.md`
6. Verify: `/add:verify`
7. Deploy: `/add:deploy`

## Key Commands

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
| `/add:away` | Human stepping away — autonomous work plan |
| `/add:back` | Human returning — get briefing |
| `/add:retro` | Retrospective — human-initiated or agent summary |
| `/add:cycle` | Plan, track, and complete work cycles within milestones |

## Rules (auto-loaded)

| Rule | Purpose |
|------|---------|
| spec-driven.md | Specs must exist before code |
| tdd-enforcement.md | Strict TDD cycle enforcement |
| human-collaboration.md | Interview protocol, away mode, engagement modes |
| agent-coordination.md | Trust-but-verify, sub-agent isolation, learning-on-verify |
| source-control.md | Git workflow, commits, PRs |
| environment-awareness.md | Test-per-environment matrix, deploy rules |
| quality-gates.md | 5-level quality gate system |
| learning.md | Continuous learning, checkpoints, knowledge persistence |
| project-structure.md | Standard directory layout, cross-project persistence |
| maturity-lifecycle.md | Master dial — governs all behavior per maturity level (poc/alpha/beta/ga) |

## Work Hierarchy

```
Maturity Level (poc → alpha → beta → ga) governs rigor at every level:

Roadmap (Now / Next / Later milestones)
 → Milestone (hill chart: features moving uphill → downhill)
   → Cycle (next batch of work, parallel strategy, validation)
     → Feature (spec → plan → TDD → verify)
```

## This Project Is ADD-Managed

ADD is dog-fooding its own methodology. Project state lives in `.add/`:
- `.add/config.json` — project configuration (Tier 1, Markdown/JSON, no CI/CD)
- `.add/learnings.md` — accumulated knowledge from this build session
- `docs/prd.md` — the plugin's own PRD

Cross-project persistence at `~/.claude/add/` (profile, library, project index).

## Learning System (3-Tier Knowledge Cascade)

Agents read all three knowledge tiers before starting any task:

| Tier | Location | Scope | Who Updates |
|------|----------|-------|-------------|
| **Tier 1: Plugin-Global** | `knowledge/global.md` | Universal ADD best practices for all users | ADD maintainers only |
| **Tier 2: User-Local** | `~/.claude/add/library.md` | Cross-project wisdom accumulated by this user | Promoted during `/add:retro` |
| **Tier 3: Project-Specific** | `.add/learnings.md` | Discoveries specific to this project | Auto-checkpoints + `/add:retro` |

Knowledge flows upward: project discoveries can be promoted to user library during retros, and universal insights can be promoted to plugin-global (only in the ADD dev project). Precedence flows downward: project-specific overrides user-local overrides plugin-global.

Checkpoint triggers (auto-populate Tier 3): after every `/add:verify`, TDD cycle, deployment, and away session.

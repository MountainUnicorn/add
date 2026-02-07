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
├── commands/          # Slash commands (/init, /spec, /away, /back, /retro, /cycle)
├── skills/            # Workflow skills (/tdd-cycle, /verify, /plan, etc.)
├── rules/             # Auto-loading behavioral rules (10 files)
├── hooks/             # PostToolUse automation
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
2. Initialize: `/init` (runs structured interview)
3. Create specs: `/spec` (per feature)
4. Plan: `/plan specs/{feature}.md`
5. Build: `/tdd-cycle specs/{feature}.md`
6. Verify: `/verify`
7. Deploy: `/deploy`

## Key Commands

| Command | Purpose |
|---------|---------|
| `/init` | Bootstrap ADD in a new project (PRD interview) |
| `/spec` | Create a feature spec (feature interview) |
| `/plan` | Generate implementation plan from spec |
| `/tdd-cycle` | Execute full TDD cycle against spec |
| `/test-writer` | RED phase only — write failing tests |
| `/implementer` | GREEN phase only — make tests pass |
| `/reviewer` | Code review for spec compliance |
| `/verify` | Run quality gates |
| `/optimize` | Performance optimization pass |
| `/deploy` | Environment-aware deployment |
| `/away` | Human stepping away — autonomous work plan |
| `/back` | Human returning — get briefing |
| `/retro` | Retrospective — human-initiated or agent summary |
| `/cycle` | Plan, track, and complete work cycles within milestones |

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

## Learning System

Agents accumulate knowledge automatically through checkpoint triggers:
- After every `/verify`, TDD cycle, deployment, and away session
- Stored in `.add/learnings.md` (project-level)
- Cross-project preferences in `~/.claude/add/profile.md` (user-level)
- Reviewed and promoted during `/retro`

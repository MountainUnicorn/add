<p align="center">
  <img src="docs/infographic.svg" alt="ADD — Agent Driven Development" width="100%">
</p>

<h1 align="center">ADD — Agent Driven Development</h1>

<p align="center">
  <strong>ADD something to your development.</strong>
  <br>
  Agent Driven Development (ADD) is a SDLC methodology where orchestrated agent swarms — test-writers, implementers, reviewers, deployers — collaborate as a coordinated enterprise class development team. Co-author and ship software that simply works. Your ADD teams will execute, verify, and self-learn with every project.
  <br>
  <br>
  <a href="https://getadd.dev">Website</a> · <a href="#install">Install</a> · <a href="#quick-start">Quick Start</a> · <a href="#coordinated-agent-teams">Agent Teams</a> · <a href="#human-in-the-loop">Human-in-the-Loop</a> · <a href="#work-hierarchy">Work Hierarchy</a> · <a href="#cross-project-learning">Learning</a>
  <br>
  <br>
  <a href="https://github.com/MountainUnicorn/add/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="#"><img src="https://img.shields.io/badge/version-0.2.0-brightgreen.svg" alt="Version"></a>
  <a href="#"><img src="https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg" alt="Claude Code Plugin"></a>
</p>

---

## What is Agent Driven Development?

**TDD** gave us tests before code. **BDD** gave us behavior before tests. **ADD** gives us *agents before everything*.

Agent Driven Development is a methodology for teams where AI agents do the development work — writing tests, implementing features, reviewing code, deploying — while humans architect, decide, and verify. It's not a tool. It's a way of working.

The problem it solves: AI code generation has changed how software gets built, but development practices haven't kept up. Developers and agents operate without structure, leading to specification drift, unpredictable quality, lost knowledge, and unclear handoffs. ADD brings discipline to AI-native development the same way TDD brought discipline to testing.

**The six principles:**

| # | Principle | What it means |
|---|-----------|--------------|
| 1 | **Specs before code** | Every feature starts as a specification. No spec, no code. |
| 2 | **Tests before implementation** | Strict TDD: RED (failing tests) → GREEN (make them pass) → REFACTOR → VERIFY |
| 3 | **Trust but verify** | Sub-agents work autonomously. Orchestrators independently verify their output. |
| 4 | **Structured collaboration** | Interviews, away mode, decision points — humans and agents have clear protocols. |
| 5 | **Environment awareness** | Skills adapt to where you're deploying: local, staging, or production. |
| 6 | **Continuous learning** | Agents accumulate knowledge. Retrospectives propagate lessons across projects. |

---

## Who is ADD for?

**Solo developers** using Claude Code for daily work who want structure without overhead. ADD scales down — a POC project gets lightweight specs and optional TDD. You get the benefits of methodology without the ceremony.

**Small teams (2-10 engineers)** looking to standardize how they work with AI agents. ADD gives your team a shared language: specs, plans, quality gates, and a maturity model that grows with your project.

**Larger teams and enterprises** scaling AI agents across multiple projects. ADD's cross-project learning system means agents get smarter over time. Patterns discovered on Project A automatically inform Project B. The maturity lifecycle gives leadership visibility into project rigor.

**Open source maintainers** who want contributors (human or AI) to follow consistent practices. ADD's spec-driven approach means every PR traces back to a specification.

---

## Install

```bash
claude plugin install add
```

That's it. No runtime dependencies. No build step. ADD is pure markdown and JSON — it runs entirely within Claude Code's plugin system.

---

## Quick Start

### 1. Initialize your project

```bash
/add:init
```

ADD interviews you about your project (product vision, tech stack, team size, deployment model) and scaffolds the project structure. Takes about 5 minutes.

**What gets created:**

```
your-project/
├── .add/
│   ├── config.json      # Project configuration
│   ├── learnings.md     # Agent knowledge base
│   └── cycles/          # Work cycle tracking
├── docs/
│   ├── prd.md           # Product Requirements Document
│   ├── plans/           # Implementation plans
│   └── milestones/      # Milestone tracking
├── specs/               # Feature specifications
└── CLAUDE.md            # Project context for Claude
```

### 2. Create a feature specification

```bash
/add:spec "user authentication"
```

ADD runs a structured interview (6-10 questions, ~5 min) and generates a complete feature specification with acceptance criteria, test cases, data models, and edge cases.

### 3. Plan the implementation

```bash
/add:plan specs/user-authentication.md
```

Transforms the spec into an actionable implementation plan with task breakdown, effort estimation, dependency mapping, and risk assessment.

### 4. Build with TDD

```bash
/add:tdd-cycle specs/user-authentication.md
```

Executes the full TDD cycle: writes failing tests from the spec (RED), implements minimal code to pass them (GREEN), refactors for quality, then independently verifies everything.

### 5. Verify quality gates

```bash
/add:verify
```

Runs up to 5 levels of quality checks: lint, type checking, unit tests, coverage, and spec compliance.

### 6. Deploy

```bash
/add:deploy
```

Environment-aware deployment with pre-deploy verification and post-deploy smoke tests.

---

## The ADD Workflow

```
                    ┌─────────────────────────────────────────┐
                    │           HUMAN DECISIONS                │
                    │  Architect · Interview · Approve · Verify│
                    └──────────────┬──────────────────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
   ┌───────────┐           ┌─────────────┐           ┌────────────┐
   │   /add:init   │           │   /add:spec     │           │  /add:cycle    │
   │ Interview │──────────▶│  Interview  │──────────▶│   Plan     │
   │ + Setup   │           │  + Spec     │           │  + Track   │
   └───────────┘           └──────┬──────┘           └─────┬──────┘
                                  │                        │
                                  ▼                        ▼
                           ┌─────────────┐          ┌────────────┐
                           │   /add:plan     │          │ /add:tdd-cycle │
                           │ Impl. Plan  │─────────▶│  RED       │
                           └─────────────┘          │  GREEN     │
                                                    │  REFACTOR  │
                                                    └─────┬──────┘
                                                          │
                                                          ▼
                                                   ┌────────────┐
                                                   │  /add:verify   │
                                                   │  5 Gates   │
                                                   └─────┬──────┘
                                                         │
                                                         ▼
                                                   ┌────────────┐
                                                   │  /add:deploy   │
                                                   │  Env-Aware │
                                                   └────────────┘
```

**Document hierarchy** — every artifact traces to a parent:

```
Roadmap (docs/prd.md)
 └── Milestones (docs/milestones/M1-core.md)
      └── Cycles (.add/cycles/cycle-1.md)
           └── Feature Specs (specs/user-auth.md)
                └── Implementation Plans (docs/plans/user-auth-plan.md)
                     └── Tests (RED phase)
                          └── Implementation (GREEN phase)
```

---

## Coordinated Agent Teams

ADD doesn't use a single agent. It dispatches **specialized sub-agents** — each with scoped tool permissions — then **independently verifies** their work. Trust but verify.

```
┌─────────────────────────────────────────────────────┐
│                   ORCHESTRATOR                       │
│  Reads spec · Builds plan · Dispatches sub-agents   │
│  Coordinates merge · Independently verifies results  │
└──────┬──────────┬──────────┬──────────┬─────────────┘
       │dispatch  │dispatch  │dispatch  │dispatch
  ┌────▼────┐ ┌───▼────┐ ┌───▼─────┐ ┌──▼──────┐
  │  Test   │ │ Imple- │ │ Review- │ │ Deploy- │
  │ Writer  │ │ menter │ │   er    │ │   er    │
  │─────────│ │────────│ │─────────│ │─────────│
  │ Write   │ │ Write  │ │ Read    │ │ Bash    │
  │ Read    │ │ Edit   │ │ Glob    │ │ Read    │
  │ Bash    │ │ Bash   │ │ Grep    │ │         │
  └────┬────┘ └───┬────┘ └───┬─────┘ └──┬──────┘
       │results   │results   │results   │results
  ┌────▼──────────▼──────────▼──────────▼───────┐
  │          INDEPENDENT VERIFICATION            │
  │  Different agent · Fresh context · No shared │
  │  state. If it disagrees, the cycle restarts. │
  └──────────────────────────────────────────────┘
```

Each sub-agent is **isolated** — test-writers can't deploy, reviewers can't edit code. At **Beta+ maturity**, agents work in parallel via git worktrees: 2-5 concurrent agents with WIP limits that scale with maturity (POC=1, Alpha=2, Beta=4, GA=5).

---

## Human in the Loop

ADD defines three engagement modes. You choose how much autonomy agents get.

| Mode | What Happens | Best For |
|------|-------------|----------|
| **Guided** | Human approves each step. Every file change reviewed before commit. Architecture decisions need sign-off. | POC maturity, unfamiliar codebases |
| **Balanced** _(default)_ | Agents execute TDD cycles freely within spec boundaries. Pause at ambiguity or architecture forks. Structured interviews for decisions. | Alpha/Beta, established patterns |
| **Autonomous** | Human defines scope and boundaries, then walks away. Agents execute full TDD cycles, commit, verify. Return to a full briefing. | GA maturity, well-specified features |

The `/add:away` and `/add:back` commands power autonomous mode:

```
Define scope ──▶ /add:away ──▶ Agent executes autonomously ──▶ /add:back ──▶ Full briefing
                 (work     (TDD cycles, commits, verify    (what shipped,
                  plan)     — all decisions logged)          what's blocked)
```

---

## Work Hierarchy

ADD organizes work in four nested levels. Each level adds detail.

```
ROADMAP  (Now / Next / Later — no fake dates)
 └── MILESTONE  (Hill chart: uphill figuring out → downhill executing)
      └── CYCLE  (Scope-boxed batch — ends when validation passes, not a timer)
           └── EXECUTION  (TDD: RED → GREEN → REFACTOR → VERIFY)
```

**No fake dates** — milestones use Now/Next/Later horizons that reflect actual priority. **No sprints** — cycles are scope-boxed and end when validation criteria are met. **Hill charts** show whether features are still being figured out (uphill: SHAPED → SPECCED → PLANNED) or being executed (downhill: IN_PROGRESS → VERIFIED → DONE).

---

## Key Features

### Spec-Driven Development

No code without a spec. ADD enforces a document hierarchy — PRD → Spec → Plan → Tests → Code — so every line of implementation traces back to an approved requirement. The `/add:spec` command interviews you about the feature and generates acceptance criteria, test cases, data models, API contracts, and edge cases.

### Strict TDD Enforcement

ADD enforces the TDD cycle at every level. The `/add:tdd-cycle` skill orchestrates sub-agents: one writes failing tests (RED), another writes minimal code to pass them (GREEN), a reviewer identifies refactoring opportunities, and a verifier independently confirms everything works. Commits follow the pattern: `test:` → `feat:` → `refactor:`.

### Human-AI Collaboration Protocol

ADD formalizes five engagement modes between humans and agents:

| Mode | When | Who leads |
|------|------|-----------|
| **Spec interview** | Creating PRDs and specs | Human leads, agent refines |
| **Quick check** | Clarifying a detail | Agent asks, human answers |
| **Decision point** | Architectural choices | Human decides, agent implements |
| **Review gate** | Approving artifacts | Human reviews, agent awaits |
| **Status pulse** | Progress check-ins | Agent reports, human adjusts |

Interviews follow a structured protocol: questions are estimated upfront ("I have 8 questions, about 5 minutes"), asked one at a time, and prioritized so the most critical questions come first.

### Away Mode

Going to lunch? Stepping into a meeting? Tell the agent:

```bash
/add:away "back in 2 hours"
```

ADD assesses available work, presents an autonomous work plan for your approval, and gets to work. When you return:

```bash
/add:back
```

You get a briefing: what was completed, what's in progress, what needs your decision. The agent won't deploy to staging/production or start features without specs while you're gone.

### The Maturity Dial

Every ADD project declares a maturity level that governs *all* process rigor. This is the master control:

| Level | PRD | Specs | TDD | Quality Gates | Parallel Agents | WIP Limit |
|-------|-----|-------|-----|---------------|-----------------|-----------|
| **POC** | A paragraph | Optional | Optional | Pre-commit only | 1 (serial) | 1 |
| **Alpha** | 1-pager | Critical paths | Critical paths | + CI | 1-2 | 2 |
| **Beta** | Full template | Required | Enforced | + Pre-deploy | 2-4 | 4 |
| **GA** | Full + architecture | + Acceptance criteria | Strict | All 5 levels | 3-5 (worktrees) | 5 |

A POC project gets almost no ceremony. A GA project gets exhaustive verification with multiple reviewers. Promotion happens deliberately — triggered by cycle completion or retrospectives when gap analysis shows readiness.

### Quality Gates

Five checkpoints catch issues progressively earlier:

| Gate | Trigger | Checks |
|------|---------|--------|
| **Level 1** Pre-commit | Before write | Lint + formatting |
| **Level 2** Pre-push | Before push | Type checking |
| **Level 3** CI | On push | Unit tests + coverage |
| **Level 4** Pre-deploy | Before deploy | Spec compliance + integration tests |
| **Level 5** Post-deploy | After deploy | Smoke tests + monitoring |

### Multi-Agent Coordination

At Beta/GA maturity, ADD coordinates multiple agents working in parallel:

- **Git worktrees** for full isolation between agents
- **File reservations** to prevent conflicts
- **Merge sequence** (infrastructure first, then features)
- **WIP limits** to prevent coordination overhead
- **Trust-but-verify** — orchestrators independently check sub-agent work

### Work Cycles

ADD uses cycles (not sprints) — scope-boxed batches of work that end when validation criteria are met, not when a timer expires.

```bash
/add:cycle --plan      # Plan the next batch of work
/add:cycle --status    # Check progress, update hill chart
/add:cycle --complete  # Close cycle, capture learnings
```

Features in a cycle progress through positions: SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE. Hill charts visualize whether work is still being figured out (uphill) or being executed (downhill).

---

## Cross-Project Learning

This is what makes ADD compound over time. Agents don't start from zero on each project.

### 3-Tier Knowledge Cascade

Agents read **all three tiers** before starting any task. More specific tiers take precedence:

| Tier | Location | Scope | Who Updates |
|------|----------|-------|-------------|
| **Tier 1: Plugin-Global** | `knowledge/global.md` | Universal ADD best practices | Ships with ADD (read-only) |
| **Tier 2: User-Local** | `~/.claude/add/library.md` | Your cross-project wisdom | Promoted during `/add:retro` |
| **Tier 3: Project-Specific** | `.add/learnings.md` | This project's discoveries | Auto-checkpoints |

**Tier 1** ships with ADD — curated best practices about agent coordination, away mode, and methodology. Every ADD user benefits immediately.

**Tier 2** follows *you* across projects (machine-local, not committed):

```
~/.claude/add/
├── profile.md    # Your preferences, conventions, working style
├── library.md    # Accumulated wisdom from all your projects
└── projects.json # Index of ADD-managed projects
```

**Tier 3** is committed to git — every team member (human or agent) benefits:

```
.add/learnings.md
├── Architecture decisions and rationale
├── What worked / what didn't
├── Patterns discovered during development
└── Tool and framework quirks
```

### Knowledge flows upward

```
Project A: discovers "UUID columns must be type uuid, not text"
  → Stored in .add/learnings.md (Tier 3: project-level)
  → Promoted to ~/.claude/add/library.md during /add:retro (Tier 2: cross-project)

Project B: agent reads library before implementing database schema
  → Finds UUID pattern, applies it automatically
  → No one repeats the mistake

ADD maintainers: universal methodology insights
  → Promoted to knowledge/global.md (Tier 1: plugin-global)
  → Every ADD user benefits on next install/update
```

### Checkpoint triggers

Knowledge is captured automatically — no human effort required:

- After every `/add:verify` — what passed, what failed, why
- After every TDD cycle — patterns in test writing and implementation
- After every deployment — environment-specific discoveries
- After every away session — what the agent learned working autonomously
- During `/add:retro` — human + agent reflect, promote learnings to cross-project library

### Retrospectives

```bash
/add:retro
```

Two modes:
- **Interactive**: Human and agent reflect together (~5 questions). Best insights come from this.
- **Agent summary**: Quick non-interactive pulse check. Good for solo developers.

Retrospectives update `.add/learnings.md`, promote patterns to `~/.claude/add/library.md`, archive the retro for future reference, and suggest process changes.

---

## Commands

| Command | Purpose | Output |
|---------|---------|--------|
| `/add:init` | Bootstrap ADD in your project via structured interview | `.add/` directory, config, PRD, CLAUDE.md |
| `/add:spec` | Create a feature specification through interview | `specs/{feature}.md` |
| `/add:cycle` | Plan, track, and complete work cycles | `.add/cycles/cycle-{N}.md` |
| `/add:brand` | View project branding — accent color, palette, drift detection | Branding config + audit report |
| `/add:brand-update` | Update branding materials and audit artifacts for consistency | Updated config + fix report |
| `/add:changelog` | Generate/update CHANGELOG.md from conventional commits | `CHANGELOG.md` |
| `/add:away` | Declare absence — get autonomous work plan | Away log + work plan |
| `/add:back` | Return from absence — get briefing | Status report + decision queue |
| `/add:retro` | Run a retrospective — capture and promote learnings | Updated learnings + archive |

## Skills

| Skill | Purpose | Phase |
|-------|---------|-------|
| `/add:tdd-cycle` | Complete RED → GREEN → REFACTOR → VERIFY cycle | Full TDD |
| `/add:test-writer` | Write failing tests from spec acceptance criteria | RED |
| `/add:implementer` | Write minimal code to pass tests | GREEN |
| `/add:reviewer` | Code review for spec compliance (read-only) | REFACTOR |
| `/add:verify` | Run quality gates (lint, types, tests, coverage, spec compliance) | VERIFY |
| `/add:plan` | Create implementation plan from spec | Planning |
| `/add:optimize` | Performance optimization pass | Optimization |
| `/add:deploy` | Environment-aware deployment with verification | Deployment |
| `/add:infographic` | Generate project infographic SVG from PRD + config | Documentation |

## Rules (Auto-loaded)

ADD ships with 11 behavioral rules that auto-load into every conversation:

| Rule | What it enforces |
|------|-----------------|
| `spec-driven` | No code without a spec. Implementations must reference spec sections. |
| `tdd-enforcement` | Strict RED → GREEN → REFACTOR → VERIFY cycle. |
| `human-collaboration` | Interview protocol, engagement modes, away/back workflow. |
| `agent-coordination` | Trust-but-verify, sub-agent isolation, parallel execution. |
| `source-control` | Feature branches, conventional commits, TDD commit pattern. |
| `environment-awareness` | Tier-based behavior (local / local+prod / full pipeline). |
| `quality-gates` | 5-level gate system from pre-commit to post-deploy. |
| `learning` | Automatic checkpoints, knowledge persistence, retro integration. |
| `project-structure` | Standard `.add/` layout, cross-project persistence paths. |
| `maturity-lifecycle` | **Master dial** — governs ALL ADD behavior per maturity level. |
| `design-system` | Silicon Valley Unicorn aesthetic for all generated visuals. |

---

## Non-Greenfield Adoption

ADD works on existing projects, not just new ones. When you run `/add:init` on an existing codebase:

1. **Discovery** — ADD scans your project structure, detects test frameworks, linters, and conventions
2. **Non-destructive setup** — Adds `.add/` alongside your existing structure, never replaces
3. **Maturity assessment** — Suggests a starting maturity level based on existing rigor
4. **Catch-up spike** — Identifies gaps and creates a remediation cycle
5. **Retroactive specs** — Seeds learnings from git history

Existing conventions are respected. ADD layers on top of what you already have.

---

## Environment Tiers

ADD adapts to your deployment reality:

| Tier | Scope | Example |
|------|-------|---------|
| **Tier 1** | Local development only | Personal projects, plugins, CLIs |
| **Tier 2** | Local + production | SaaS apps, APIs with a prod server |
| **Tier 3** | Full pipeline (dev → staging → prod) | Enterprise applications, team projects |

Quality gates, deployment skills, and test matrices all adjust based on your tier. A Tier 1 project doesn't waste time on staging smoke tests. A Tier 3 project doesn't skip them.

---

## Architecture

ADD is intentionally simple:

- **No runtime dependencies** — Pure markdown and JSON files
- **No build step** — Install and use immediately
- **No backend** — Everything lives in your git repo (`.add/`) or locally (`~/.claude/add/`)
- **No vendor lock-in** — Standard markdown specs and plans work with any tool
- **Plugin format** — Claude Code `.claude-plugin/plugin.json` manifest

The entire plugin is ~60 files of markdown, JSON, and templates. It runs entirely within Claude Code's plugin system using commands, skills, rules, hooks, knowledge, and templates.

---

## Project Structure Reference

After `/add:init`, your project gets this structure:

```
your-project/
├── .add/                           # ADD state (git-committed)
│   ├── config.json                 # Project config (maturity, stack, tier)
│   ├── learnings.md                # Agent knowledge base
│   └── cycles/                     # Work cycle tracking
├── .claude/
│   └── settings.json               # Claude Code permissions
├── CHANGELOG.md                     # Auto-generated changelog
├── docs/
│   ├── prd.md                      # Product Requirements Document
│   ├── infographic.svg              # Project infographic (generated)
│   ├── plans/                      # Implementation plans
│   └── milestones/                 # Milestone tracking with hill charts
├── specs/                          # Feature specifications
├── tests/
│   └── screenshots/                # Visual verification (UI projects)
└── CLAUDE.md                       # Project context for Claude
```

Cross-project persistence (machine-local, not committed):

```
~/.claude/add/
├── profile.md                      # Your preferences and working style
├── library.md                      # Accumulated wisdom across projects
└── projects.json                   # Index of all ADD-managed projects
```

---

## Roadmap

| Version | Status | Focus |
|---------|--------|-------|
| **v0.1.0** | Complete | Core infrastructure — 6 commands, 8 skills, 10 rules, 10 templates |
| **v0.2.0** | Complete | Branding system, image gen detection, auto-changelog, infographic generation |
| **v0.3.0** | Next | Adoption & polish — `/add:init --adopt`, enhanced interviews, cross-project sync |
| **v1.0.0** | Planned | Marketplace ready — CI/CD hooks, advanced learnings, team profiles |

---

## License

MIT

---

<p align="center">
  <strong>ADD something to your development.</strong>
  <br>
  Built with ADD, using ADD. Dog-fooded from day one.
  <br>
  <br>
  <a href="https://getadd.dev">getADD.dev</a> · <a href="https://github.com/MountainUnicorn/add">GitHub</a>
</p>

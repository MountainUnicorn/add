# ADD — Agent Driven Development

A Claude Code plugin that implements a structured SDLC methodology for AI-native software development.

## What is ADD?

Like **TDD** (Test Driven Development) and **BDD** (Behavior Driven Development), **ADD** (Agent Driven Development) is a development methodology. The difference: ADD is designed for teams where AI agents are first-class developers.

In ADD:
- **Humans** are architects, product owners, and decision makers
- **Agents** are the development team — they write tests, implement features, review code, and deploy
- **Specs** are the contract between human and agent
- **Trust-but-verify** ensures quality through independent verification

## Install

```bash
claude plugin install add
```

## Quick Start

```bash
# Initialize ADD in your project
/init

# Create a feature specification
/spec "user authentication"

# Create an implementation plan
/plan specs/user-authentication.md

# Execute TDD cycle
/tdd-cycle specs/user-authentication.md

# Verify quality gates
/verify

# Deploy
/deploy
```

## The ADD Workflow

```
Human interviews (/init)
  → PRD (docs/prd.md)
    → Feature interview (/spec)
      → Spec (specs/{feature}.md)
        → Plan (/plan)
          → Implementation plan (docs/plans/)
            → TDD Cycle (/tdd-cycle)
              → Tests (RED) → Code (GREEN) → Refactor → Verify
                → Deploy (/deploy)
```

## Human-AI Collaboration

ADD formalizes how humans and agents work together:

- **Interviews** — Structured 1-by-1 questions with upfront time estimates
- **Away mode** — Tell the agent you're stepping out, get a work plan, return to a briefing
- **Engagement modes** — Spec interviews, quick checks, decision points, review gates
- **Autonomy levels** — Guided, balanced, or autonomous (configured per project)

## Commands

| Command | Description |
|---------|-------------|
| `/init` | Bootstrap ADD — structured interview produces PRD + config |
| `/spec` | Create feature specification through interview |
| `/away` | Declare absence, get autonomous work plan |
| `/back` | Return briefing after absence |

## Skills

| Skill | Description |
|-------|-------------|
| `/tdd-cycle` | Complete RED → GREEN → REFACTOR → VERIFY cycle |
| `/test-writer` | Write failing tests from spec (RED phase) |
| `/implementer` | Minimal code to pass tests (GREEN phase) |
| `/reviewer` | Code review for spec compliance (read-only) |
| `/verify` | Run quality gates (lint, types, tests, coverage) |
| `/plan` | Create implementation plan from spec |
| `/optimize` | Performance optimization pass |
| `/deploy` | Environment-aware deployment |

## Project Structure (after /init)

```
your-project/
├── .add/
│   └── config.json              # Project configuration
├── .claude/
│   └── settings.json            # Claude Code permissions
├── docs/
│   ├── prd.md                   # Product Requirements Document
│   └── plans/                   # Implementation plans
├── specs/                       # Feature specifications
├── tests/
│   └── screenshots/             # Visual verification
└── CLAUDE.md                    # Project context for Claude
```

## License

MIT

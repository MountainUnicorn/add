---
autoload: true
maturity: beta
description: "Master rule governing all ADD behavior based on project maturity level"
---

# ADD Rule: Maturity Lifecycle

This rule defines how ADD adapts to your project's stage of development. **It takes precedence over all other rules.** When maturity-lifecycle conflicts with another rule, maturity wins.

## Maturity Levels

### POC (Proof of Concept)
A project exploring viability. Time-boxed, high uncertainty, goal is to validate a core idea or remove a critical unknown. Success = learning, not completeness.

### Alpha
Early-stage, building toward an MVP. Core concept validated. Moving toward product-market fit. Scaling up safety incrementally. Success = surviving first real usage.

### Beta
Shipping to broader audiences. Feature-complete for 1.0. Reducing defect density and improving reliability. Focus on stabilization and quality. Success = reliable, predictable product.

### GA (General Availability)
Production-grade, long-term support expected. High stability demands. Change velocity slows. Deep safety protocols. Focus on sustainability and scale. Success = trusted, reliable infrastructure.

---

## Cascade Matrix & Promotion

Maturity controls every dimension of ADD behavior — PRD depth, specs, TDD, quality gates, commit discipline, reviewers, environment ceiling, away-mode autonomy, planning depth, parallel agents, and per-check enforcement. The full per-dimension cascade matrix and the promotion process (when to promote, gap analysis, promotion milestones) live in `~/.codex/add/references/maturity-matrix.md` — load it when planning cycles, running promotion gap analysis, initializing a project, or configuring gates. Promotion is **intentional and deliberate** — never automatic.

## Work Hierarchy

Roadmap → Milestones → Cycles → Features → Tasks. For full hierarchy definitions (locations, ownership, formats), see `project-structure.md`.

Key maturity scaling for the hierarchy:

- **Cycle Length:** POC/Alpha: 1-2 days | Beta: 3-5 days | GA: 5-7 days
- **Hill Chart Positions:** SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE
- Documentation depth per level is governed by the cascade matrix rows: Milestone Docs, Cycle Planning, Features Per Cycle (see `references/maturity-matrix.md`)

---

## Agent Mindset by Maturity

Before any significant action, read `.add/config.json` maturity field and adopt the appropriate mindset:

- **POC:** Move fast, skip reviews, TDD optional, freeform commits
- **Alpha:** Plan ahead, flag blockers, TDD on critical paths, conventional commits
- **Beta:** Full specs, strict TDD, all PRs reviewed, pre-deploy QA
- **GA:** Move deliberately, two reviewers, SLA monitoring, risk assessment per change

### Conflict Resolution

When another rule conflicts with maturity-lifecycle, **maturity wins.** Examples: TDD rule says "always test first" but maturity is POC → TDD optional. Parallel agents suggests 4 agents but maturity is Alpha → max 2.

## Using This Rule

1. Read `.add/config.json` maturity level before every action
2. Cross-reference the cascade matrix in `~/.codex/add/references/maturity-matrix.md`
3. Adjust behavior: relaxed for POC/Alpha, strict for Beta/GA
4. When in doubt, escalate to human

**Maturity lifecycle is the single most important rule in ADD.** Everything else cascades from it.

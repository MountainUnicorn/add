# Maturity Cascade Matrix & Promotion Process

> Full cascade matrix and promotion process for the maturity lifecycle.
> Loaded on demand by `/add-promote`, `/add-cycle`, `/add-init`, and
> `/add-retro`. The behavioral rule — level definitions, agent mindset,
> conflict resolution — is `rules/maturity-lifecycle.md`.

## Cascade Matrix: Maturity Controls Everything

| Dimension | POC | Alpha | Beta | GA |
|-----------|-----|-------|------|-----|
| **PRD Depth** | Paragraph (problem + hypothesis) | 1-pager (problem, solution, success metrics) | Full template (PRD: goals, specs, roadmap, audience, constraints) | Full template + detailed architecture, scalability model, migration path |
| **Specs Required** | No | Critical paths only (e.g., auth, core loops) | Yes (all user-facing features + acceptance criteria) | Yes + exhaustive acceptance criteria + user test scenarios |
| **TDD Enforced** | Optional (but recommended) | Critical paths mandatory | Yes, strict policy | Strict no exceptions (100% coverage of modified paths) |
| **Quality Gates Active** | Pre-commit lint only | Pre-commit + basic CI (lint, unit tests) | Pre-commit + full CI + pre-deploy QA | All 5 levels: pre-commit, CI, pre-deploy, deploy monitoring, SLA monitoring |
| **Commit Discipline** | Freeform (WIP, experiment ok) | Conventional commits (feat:/fix:/docs:) | Conventional + spec references (#spec-{id}) | Conventional + spec refs + PR mandatory + auto-linked tickets |
| **Reviewer Agent** | Skip (solo agent ok) | Optional (recommended for risky PRs) | Recommended (code review on all changes) | Mandatory (two reviewers, one from stability team) |
| **Environment Tier Ceiling** | Tier 1 (local, dev) | Tier 1-2 (dev, staging) | Tier 2 (staging only, no prod changes) | Tier 2-3 (staging + production, with deploy checks) |
| **Away Mode Autonomy** | Full autonomy (agent decides scope/pace) | High autonomy (agent plans, few checkpoints) | Balanced (plan reviewed, execute autonomous, verify with human) | Guided with checkpoints (human approval at cycle start + completion, daily standups) |
| **Interview Depth** | ~5 questions (fast exploration) | ~8 questions (clarify core assumptions) | ~12 questions (understand user stories deeply) | ~15 questions (exhaustive acceptance criteria validation) |
| **Milestone Docs Required** | No (PRD paragraph enough) | Lightweight (M{N} title, goal, 3 features) | Yes, full template (goal, appetite, hill chart, risks, cycles) | Yes, full template + hill chart tracked daily + risk reassessment per cycle |
| **Cycle Planning** | Informal (ad-hoc batching) | Brief cycle doc (work items + priorities) | Full cycle plan (features, dependencies, parallelism, validation) | Full plan + risk assessment + parallel agent coordination + WIP limits |
| **Features Per Cycle** | 1-2 (rapid iteration) | 2-4 (bounded scope) | 3-6 (balanced execution) | 3-6 with strict WIP limits (ensures quality focus) |
| **Parallel Agents** | 1 serial (one agent at a time) | 1-2 agents (minimal serialization) | 2-4 agents (worktree isolation, file reservations) | 3-5 agents (strict worktree isolation, merge coordination, merge sequence docs) |
| **Code Quality Checks** | Lint only | Lint errors blocking | + complexity >15, duplication >10 lines, file >500, function >80 — advisory | Tighter thresholds (10/6/300/50), all blocking |
| **Security & Vulnerability** | Not checked | Secrets scan blocking, OWASP spot-check advisory | + dependency audit, full OWASP, auth patterns, PII handling — advisory | All blocking, CVEs blocking, rate limiting + secure headers required |
| **Readability & Documentation** | Not checked | Naming consistency advisory | + nesting <5, docstrings on exports, complex logic comments, magic numbers — advisory | All blocking, module READMEs, glossary, nesting <4 |
| **Performance Checks** | Not checked | Not checked | N+1 detection, blocking async, bundle size, memory patterns — advisory | All blocking, perf tests required, response time baselines |
| **Repo Hygiene** | Not checked | Branch naming advisory, .gitignore exists | + stale branches, LICENSE, CHANGELOG, dependency freshness, README, PR template — advisory | All blocking, 14-day stale limit, comprehensive README |

## Maturity Promotion: Leveling Up

Moving from one maturity level to the next is **intentional and deliberate.** It's not automatic.

### When to Promote

- **POC → Alpha:** Core idea validated, first users engaged, product is stable enough for feedback
- **Alpha → Beta:** MVP feature-complete, early adopters find it reliable, ready for broader use
- **Beta → GA:** Defect rate below threshold, 30+ days production stability, SLAs defined and met

### Promotion Process

1. Trigger: `/add-cycle --complete` suggests promotion, or `/add-retro` recommends it
2. **Gap Analysis:** Compare project state against target maturity checklist:
   - Are all required docs in place? (PRD, specs, milestones)
   - Are quality gates configured? (CI, pre-deploy, monitoring)
   - Is test coverage sufficient? (% coverage target by maturity)
   - Is team process aligned? (reviewer discipline, cycle discipline)
3. **Promotion Milestone:** Create a special milestone (M{N} — "Maturity → {TARGET}") that captures:
   - Missing pieces from the gap analysis
   - New practices to adopt (e.g., introducing 2-reviewer policy)
   - Runbook changes (escalation paths, on-call setup)
4. **Execution:** Complete the promotion milestone in 1-2 cycles
5. **Update Config:** Write `.add/config.json` maturity field to new level

### Precedent

Promotion milestones are treated like any other milestone: they advance the project toward GA stability.

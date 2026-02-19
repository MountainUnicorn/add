# Implementation Plan: Retro Template Automation

**Spec Version:** 0.1.0
**Created:** 2026-02-19
**Team Size:** Solo
**Estimated Duration:** 1 session

## Overview

Transform `/add:retro` from a blank-slate interview into a context-aware, data-driven review session with pre-populated tables, agent self-assessment scores, and rate-limited meta questions.

## Objectives

- Context-aware retro flow that adapts to session type (autonomous vs collaborative)
- Pre-populated tables of human directives and agent observations with scope classification
- Agent self-assessment of ADD methodology and swarm effectiveness (scored 0.0-9.0)
- Rate-limited meta questions (collab score, ADD feedback) capped at 1x/day
- Consistent retro archive format via template

## Implementation Phases

### Phase 1: Templates and Data Structures

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-001 | Create `templates/retro.md.template` — structured retro archive with all sections (context, metrics, 3 tables, refinement Q&A, scores, feedback) | AC-018, AC-019 | 20min |
| TASK-002 | Create `templates/retro-scores.json.template` — wrapper for score trend tracking with all 3 score types | AC-013, AC-023, AC-026, AC-027 | 10min |

### Phase 2: Retro Command Rewrite

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-003 | Rewrite `commands/retro.md` — implement the full context-aware retro flow: session context detection, auto-gather metrics, extract/classify human directives, present 3 tables, agent ADD methodology adherence self-assessment, agent self-scores with evidence, refinement Q&A, rate-limited meta questions, score storage, ADD feedback storage | AC-001 through AC-017, AC-020 through AC-029 | 1.5h |

This is the core deliverable. The command rewrite covers:
1. **Pre-Flight** — detect retro window, session context (away logs vs interactive), gather all data sources
2. **Phase 1: Context & Metrics** — present period summary adapted to session type
3. **Phase 2: Human Directives Table** — extract from handoff, learnings (human-classified), observations.md; classify by scope (project/workstation/org-stub/community-stub); skip if empty
4. **Phase 3: Agent Observations Tables** — project-scoped and workstation-scoped tables; include ADD methodology adherence self-assessment; skip empty tiers
5. **Phase 4: Refinement** — ask human to polish/modify learnings
6. **Phase 5: Targeted Questions** — what went well (skip if autonomous), what needs improvement, collab score (0.0-9.0, 1 decimal, 1x/day), ADD improvement suggestions (1x/day)
7. **Phase 6: Agent Self-Scores** — ADD effectiveness + swarm effectiveness (0.0-9.0, evidence-backed)
8. **Phase 7: Record** — write retro archive from template, append scores to retro-scores.json, append feedback to add-feedback.md
9. **Existing features preserved** — observation synthesis, mutation proposals, maturity assessment, deduplication, pruning remain intact

### Phase 3: Integration

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-004 | Update CLAUDE.md — note retro template automation, update template count | — | 10min |
| TASK-005 | Update M2 milestone — mark Retro Template Automation as DONE | — | 5min |
| TASK-006 | Update spec status to Complete | — | 5min |

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Retro command becomes too long, consuming excess context | Medium | Medium | Keep concise, reference templates for structure, use tables not prose |
| Agent self-scores lack calibration (no baseline) | Low | Low | Scores improve over time as trend data accumulates; first scores are best-effort |
| Rate-limit check misses edge cases (retro files from different timezones) | Low | Low | Use date from retro filename, not filesystem timestamps |

## Deliverables

- `templates/retro.md.template` — retro archive template
- `templates/retro-scores.json.template` — score trend file template
- `commands/retro.md` — rewritten retro command with context-aware flow
- Updated CLAUDE.md, M2 milestone, spec status

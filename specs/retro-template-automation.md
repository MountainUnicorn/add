# Spec: Retro Template Automation

**Version:** 0.1.0
**Created:** 2026-02-19
**PRD Reference:** docs/prd.md
**Status:** Complete

## 1. Overview

Transform `/add:retro` from a blank-slate interview into a context-aware, data-driven review session. The retro auto-gathers metrics, classifies human directives and agent observations into scoped tables, and presents pre-populated findings for the human to refine — not recall from scratch. Rate-limited meta questions (collaboration score, ADD methodology feedback) feed a future central hub.

### User Story

As an ADD user running a retrospective, I want the retro to already know what happened — my directives, the agent's observations, and session context — so that I spend time refining and deciding, not recalling and dictating.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | On retro start, detect session context: was the period mostly autonomous (`/add:away`), collaborative, or mixed — adapt tone and expectations accordingly | Must |
| AC-002 | Auto-gather metrics from git log, specs status, learnings checkpoints, observations.md, away logs, and handoff files for the retro window | Must |
| AC-003 | Extract human directives from: conversation history, handoff files, learnings entries with `classified_by: "human"`, and `.add/observations.md` | Must |
| AC-004 | Classify each human directive by scope: project, workstation, organization (stub), community (stub) | Must |
| AC-005 | Present **Table 1: Human Directives** with scope classification, asking user to confirm these are captured in learnings | Must |
| AC-006 | Present **Table 2: Agent Observations (Project)** — project-scoped learnings the agent recorded since last retro | Must |
| AC-007 | Present **Table 3: Agent Observations (Workstation)** — workstation-scoped learnings the agent recorded since last retro | Must |
| AC-008 | Agent observations must include self-assessment of ADD methodology adherence as a **table** (Rule / Status / Detail) — not inline checkmarks. Table format is easier to scan. | Must |
| AC-008a | If human identifies data gaps during refinement (missing checkpoints, incorrect entries), fix them in the background — do not block the retro flow while writing JSON or regenerating markdown | Must |
| AC-009 | After presenting tables, ask human to polish/modify: "Do you disagree or wish to modify any of these learnings?" | Must |
| AC-010 | Ask "What went well?" only after tables are presented and refined | Must |
| AC-011 | Ask "What needed improvement that was not included already in our learnings?" — scoped to gaps not already captured | Must |
| AC-012 | Ask collaboration score on a scale of 0.0 to 9.0 (1 decimal precision): "How well are we working together?" | Must |
| AC-013 | Store collaboration score in `.add/retros/retro-{date}.md` and append to a trend line in `.add/retro-scores.json` | Must |
| AC-014 | Ask "Any improvements for Agent Driven Development you would suggest?" — captures methodology-level feedback | Must |
| AC-015 | Store ADD improvement suggestions in `.add/add-feedback.md` (ready for future central hub streaming) | Must |
| AC-016 | Rate-limit: collaboration score and ADD improvement questions asked max 1x per calendar day, even across multiple retros | Must |
| AC-017 | To enforce rate-limit, check most recent `.add/retros/retro-{date}.md` — if one from today already has those fields, skip them | Must |
| AC-018 | Create `templates/retro.md.template` that structures the retro output document consistently | Must |
| AC-019 | Retro archive files (`.add/retros/retro-{date}.md`) use the template for consistent structure | Must |
| AC-020 | If session was mostly autonomous and human had minimal interaction, reduce question count — skip "what went well" if human has insufficient context to answer meaningfully | Should |
| AC-021 | Stub organization and community scope tiers in the directive classification (not functional yet, but the schema supports them) | Should |
| AC-022 | Existing retro features (observation synthesis, mutation proposals, maturity assessment, deduplication, pruning) remain intact — this spec layers on top | Should |
| AC-023 | Collaboration score trend in `.add/retro-scores.json` supports future visualization (array of `{date, score, retro_file}` entries) | Should |
| AC-024 | Agent provides a self-assessed ADD methodology effectiveness score (0.0-9.0, 1 decimal precision) — how well is the ADD process being followed and delivering value | Must |
| AC-025 | Agent provides a self-assessed swarm effectiveness score (0.0-9.0, 1 decimal precision) — how well are agents collectively building together | Must |
| AC-026 | Store agent self-scores in `.add/retros/retro-{date}.md` and append to `.add/retro-scores.json` alongside human collab score for trend plotting | Must |
| AC-027 | All three scores (human collab, agent ADD effectiveness, agent swarm effectiveness) tracked over time to visualize self-evolution — "getting better because of learnings" | Should |
| AC-028 | If no human directives were captured in the period, skip Table 1 and move directly to agent observations | Nice |
| AC-029 | If no agent observations exist for a scope tier, skip that table | Nice |

## 3. User Test Cases

### TC-001: Collaborative session retro

**Precondition:** Project has had active collaborative work since last retro. Human gave directives (e.g., "always auto-write handoffs"). Agent recorded 5 project learnings and 2 workstation learnings. No retro today yet.
**Steps:**
1. Run `/add:retro`
2. Retro detects collaborative session context
3. Presents Table 1 (human directives) with scope classification
4. Human confirms directives
5. Presents Table 2 (agent project observations) and Table 3 (agent workstation observations)
6. Agent observations include ADD methodology adherence self-assessment
7. Human polishes learnings
8. Asked: what went well, what needs improvement, collab score (0-9), ADD suggestions
**Expected Result:** Retro archive written with all tables, refined learnings, collaboration score stored in both retro file and `retro-scores.json`, ADD feedback stored in `add-feedback.md`
**Screenshot Checkpoint:** N/A (CLI output)
**Maps to:** TBD

### TC-002: Mostly autonomous session retro

**Precondition:** Human was in `/add:away` mode for most of the retro window. Minimal human interaction. Agent completed 3 tasks autonomously. 1 human directive captured from `/add:back` feedback.
**Steps:**
1. Run `/add:retro`
2. Retro detects autonomous context, adapts tone
3. Presents Table 1 (1 directive) with scope
4. Presents Tables 2 and 3 with agent observations including methodology adherence
5. Skips "what went well" (human has insufficient context)
6. Asks remaining questions
**Expected Result:** Shorter retro, adapted to low human context. Score and feedback captured if not already asked today.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-003: Second retro same day (rate-limiting)

**Precondition:** A retro was already run today with collaboration score and ADD feedback captured. New work has been done since.
**Steps:**
1. Run `/add:retro`
2. Retro proceeds with tables and refinement
3. Reaches collab score / ADD improvement questions
4. Detects today's retro already has these fields populated
**Expected Result:** Collab score and ADD improvement questions are skipped. All other retro steps proceed normally.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-004: No human directives in period

**Precondition:** Retro window has agent observations but no human directives (no conversation feedback, no human-classified learnings, no relevant observations.md entries).
**Steps:**
1. Run `/add:retro`
2. Retro skips Table 1
3. Proceeds directly to agent observation tables
**Expected Result:** No empty table shown, flow moves smoothly to agent observations and refinement questions.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-005: ADD methodology adherence self-assessment

**Precondition:** During the retro window, the agent skipped writing a spec before implementation on one feature, and missed an auto-handoff after a commit.
**Steps:**
1. Run `/add:retro`
2. Agent observation tables include methodology adherence section
**Expected Result:** Agent self-reports: "Spec-before-code: violated once (feature X implemented without spec). Auto-handoff: missed 1 trigger (post-commit on {hash})." These appear in the project observations table.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

## 4. Data Model

### Retro Scores Entry (`retro-scores.json`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| date | string | Yes | ISO 8601 date (YYYY-MM-DD) |
| collab_score | number | Yes | Human collaboration score 0.0-9.0 (1 decimal precision) |
| add_effectiveness | number | Yes | Agent self-assessed ADD methodology effectiveness 0.0-9.0 |
| swarm_effectiveness | number | Yes | Agent self-assessed collective building effectiveness 0.0-9.0 |
| retro_file | string | Yes | Path to the retro archive file |
| context | string | No | Brief note on session context (collaborative/autonomous/mixed) |

**File wrapper:**

```json
{
  "$schema": "https://github.com/MountainUnicorn/add/retro-scores.schema.json",
  "version": "1.0.0",
  "project": "{project-name}",
  "entries": []
}
```

**Score semantics:**

| Score Range | Meaning |
|-------------|---------|
| 0.0-2.0 | Poor — process not working, significant friction |
| 2.1-4.0 | Below average — notable gaps, frequent workarounds |
| 4.1-6.0 | Adequate — functional but room for improvement |
| 6.1-8.0 | Good — effective with minor issues |
| 8.1-9.0 | Excellent — highly effective, minimal friction |

### ADD Feedback Entry (`add-feedback.md`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| date | string | Yes | ISO 8601 date |
| suggestion | string | Yes | The human's improvement suggestion |
| retro_file | string | Yes | Path to the retro archive file |
| streamed | boolean | No | Whether this has been sent to central hub (future) |

**Format (markdown, append-only):**

```markdown
# ADD Methodology Feedback

## {YYYY-MM-DD}
- **Suggestion:** {text}
- **Retro:** {retro file path}
- **Streamed:** false
```

### Retro Template Sections

| Section | Source | Conditional |
|---------|--------|-------------|
| Session Context | away logs, handoff, git activity | Always |
| Metrics Summary | git log, specs, learnings, observations | Always |
| Table 1: Human Directives | conversation, handoff, learnings (human), observations | Skip if empty |
| Table 2: Agent Observations (Project) | learnings.json (project scope) | Skip if empty |
| Table 3: Agent Observations (Workstation) | library.json (workstation scope) | Skip if empty |
| ADD Methodology Adherence | agent self-assessment against rules | Always (in Tables 2/3) |
| Refinement Q&A | human input | Always |
| What Went Well | human input | Skip if autonomous context |
| What Needs Improvement | human input | Always |
| Collaboration Score | human input (0-9) | 1x/day max |
| ADD Improvement Suggestions | human input | 1x/day max |

### Directive Scope Classification

| Scope | Active | Description |
|-------|--------|-------------|
| project | Yes | Specific to this project's codebase, config, or workflow |
| workstation | Yes | Applies across projects on this user's machine |
| organization | Stub | Future: team/org shared directives |
| community | Stub | Future: all ADD users, crowd-sourced |

## 5. API Contract

N/A — this is an enhancement to the existing `/add:retro` command, not a new API endpoint.

## 6. UI Behavior

N/A — CLI-only. Retro produces structured text output and writes to `.add/retros/retro-{date}.md`.

Example flow output:

```
RETROSPECTIVE — ADD
Period: 2026-02-17 → 2026-02-19
Context: Collaborative (12 interactive exchanges, 1 away session)

During this period:
  Specs completed: 2 (legacy-adoption, retro-template-automation)
  Commits: 8
  Agent learnings recorded: 6 (4 project, 2 workstation)
  Human directives captured: 3

━━━ TABLE 1: YOUR DIRECTIVES ━━━
| # | Directive | Scope | Source |
|---|-----------|-------|--------|
| 1 | Handoffs must auto-write, never ask permission | workstation | session feedback |
| 2 | Use conventional commits consistently | project | handoff |
| 3 | Commit, push, sync as standard sequence | workstation | observations.md |

Are these captured correctly in learnings? Any to add, remove, or reclassify?

━━━ TABLE 2: AGENT OBSERVATIONS (PROJECT) ━━━
| # | Observation | Severity |
|---|-------------|----------|
| 1 | Version bumps touch 30+ files — automation needed | high |
| 2 | SVG editing requires careful Y-offset management | medium |

ADD Methodology Adherence:
  ✓ Spec-before-code: followed for all features
  ✓ Auto-handoffs: written after all commits
  ✗ Learning checkpoints: missed 1 post-verify checkpoint

━━━ TABLE 3: AGENT OBSERVATIONS (WORKSTATION) ━━━
| # | Observation | Severity |
|---|-------------|----------|
| 1 | Plugin namespace rule — all refs must use /add: prefix | critical |

Help me polish these. Do you disagree or wish to modify any?

> What went well?
> What needed improvement not already in our learnings?
> On a scale of 0.0 to 9.0, how well are we working together?
> Any improvements for Agent Driven Development you would suggest?

━━━ AGENT SELF-ASSESSMENT ━━━
ADD Methodology Effectiveness: 7.2 / 9.0
  Evidence: Spec-before-code followed 100%. Missed 1 auto-handoff.
  TDD not applicable (markdown plugin). Learning checkpoints: 5/6 triggered.

Swarm Effectiveness: 6.5 / 9.0
  Evidence: 3 parallel subagents used for version bump (efficient).
  1 agent duplicated work already done by another. Handoff between
  sessions lost some context due to compaction.
```

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No previous retro exists | Use project creation date as retro window start |
| No learnings, no observations, no directives | Skip all tables, ask open-ended questions only |
| `retro-scores.json` doesn't exist | Create it with empty entries array on first score entry |
| `add-feedback.md` doesn't exist | Create it with header on first suggestion |
| Multiple retros same day | Rate-limit collab score and ADD feedback; all other sections run normally |
| Human gives score outside 0.0-9.0 range | Ask again, clarify the scale |
| Agent self-scores seem inflated/deflated vs evidence | Agent must justify scores with specific evidence from the retro window |
| Retro window has only away sessions | Detect as autonomous context, adapt flow |
| Organization/community scope selected | Accept classification, store with scope tag, note as "future tier — not yet synced" |

## 8. Dependencies

- `commands/retro.md` — existing retro command (this spec enhances, not replaces)
- `rules/learning.md` — learning entry schema, scope classification rules
- `.add/learnings.json` — project learnings (Tier 3)
- `~/.claude/add/library.json` — workstation learnings (Tier 2)
- `.add/observations.md` — process observations
- `.add/handoff.md` — session state
- `.add/away-logs/` — away session archives

## 9. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-19 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec interview |

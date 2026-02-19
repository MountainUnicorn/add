---
description: "[ADD v0.4.0] Run a retrospective — context-aware, data-driven review with pre-populated tables"
argument-hint: "[--agent-summary] [--since YYYY-MM-DD] [--scope feature|sprint|session] [--dry-run]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite]
---

# ADD Retro Command v0.4.0

Context-aware retrospective that auto-gathers data, classifies human directives and agent observations into scoped tables, and presents pre-populated findings for the human to refine — not recall from scratch.

Two modes:
- **Interactive retro** (default) — Data-driven review with pre-populated tables
- **Agent summary** (`--agent-summary`) — Quick non-interactive observations review

## Pre-Flight

1. Read `.add/config.json` for project context (name, maturity, stack)
2. Read all 3 knowledge tiers:
   a. **Tier 1:** Read `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md`
   b. **Tier 2:** Read `~/.claude/add/library.json` (fall back to `library.md`)
   c. **Tier 3:** Read `.add/learnings.json` (fall back to `learnings.md`)
3. Read `~/.claude/add/profile.md` if it exists
4. Determine the retro window:
   - If `--since` provided, use that date
   - If previous retro exists in `.add/retros/`, use that date as start
   - Otherwise, use project creation date from config
5. Read `.add/handoff.md` — note in-progress work and decisions

---

## Mode 1: Interactive Retro (default)

### Phase 1: Detect Session Context

Determine how the human spent the retro window:

1. **Read `.add/away-logs/`** — count away sessions, total autonomous hours
2. **Read git log** — count commits, branches, PRs merged
3. **Read `.add/handoff.md`** — check for interactive session indicators
4. **Classify context:**
   - **Autonomous:** >70% of retro window was away-mode sessions
   - **Collaborative:** <30% away-mode, active interactive exchanges
   - **Mixed:** between 30-70% away-mode

The context classification affects the flow:
- **Autonomous:** Human has less context → skip "what went well", reduce questions
- **Collaborative/Mixed:** Full question set

### Phase 2: Auto-Gather Metrics

Collect data for the retro window from all sources:

- **Git log:** commit count, branches merged, PRs
- **Specs:** count completed (status: Complete) in `specs/`
- **Learnings:** count new entries in `.add/learnings.json` since last retro (by date field)
- **Workstation learnings:** count new entries in `~/.claude/add/library.json` since last retro
- **Observations:** read `.add/observations.md` entries since last retro
- **Away logs:** count sessions, total duration from `.add/away-logs/`
- **Handoff:** current state from `.add/handoff.md`

Present the summary:

```
RETROSPECTIVE — {PROJECT_NAME}
Period: {start_date} → {today}
Context: {Collaborative|Autonomous|Mixed} ({detail})

During this period:
  Specs completed: {N}
  Commits: {N}
  Agent learnings recorded: {N} ({N} project, {N} workstation)
  Human directives captured: {N}
  Away-mode sessions: {N}
```

### Phase 3: Human Directives (Table 1)

Extract directives the human gave during the retro window from:
- **Handoff files** — decisions, explicit instructions
- **Learnings entries** with `classified_by: "human"` — human-reclassified knowledge
- **`.add/observations.md`** — entries recording human feedback or directives
- **Conversation context** — explicit instructions from the current or recent sessions

For each directive, **classify scope:**

| Scope | Signal |
|-------|--------|
| project | References specific files, config, routes, schemas unique to this project |
| workstation | References tools, libraries, workflows that apply across projects |
| organization | References team, org, or company patterns (stub — accept but note "future tier") |
| community | References universal methodology insights (stub — accept but note "future tier") |

**If no directives found:** Skip Table 1 entirely, move to Phase 4. Do not show an empty table.

**If directives found:** Present:

```
In our recent sessions, you provided some key insights:

━━━ TABLE 1: YOUR DIRECTIVES ━━━
| # | Directive | Scope | Source |
|---|-----------|-------|--------|
| 1 | {directive text} | {scope} | {source} |
| 2 | {directive text} | {scope} | {source} |

Are these captured correctly in learnings? Any to add, remove, or reclassify?
```

Wait for human confirmation. Apply any changes to learnings JSON files.

### Phase 4: Agent Observations (Tables 2 & 3)

Read agent-generated entries since last retro:
- **Table 2 (Project):** Entries from `.add/learnings.json` where `classified_by: "agent"` and `date` within retro window
- **Table 3 (Workstation):** Entries from `~/.claude/add/library.json` where `classified_by: "agent"` and `date` within retro window

**Skip any table that has zero entries.** Do not show empty tables.

**ADD Methodology Adherence Self-Assessment:**

Include in the agent observations a self-assessment of how well ADD methodology was followed during the retro window. Check each rule:

| Rule | How to Assess |
|------|---------------|
| Spec-before-code | Were any features implemented without a spec? Check git log for implementation commits vs spec dates |
| TDD cycles | Were tests written before implementation? (N/A for markdown-only plugins) |
| Auto-handoffs | Were handoffs written after commits and major work? Check `.add/handoff.md` timestamps vs git log |
| Learning checkpoints | Were learnings recorded at trigger points (post-verify, post-tdd, post-deploy, post-away)? Count expected vs actual |
| Quality gates | Were `/add:verify` runs done? Did they pass first time? |
| Source control | Were conventional commits used? Check last N commits for pattern compliance |

Format:

```
━━━ TABLE 2: AGENT OBSERVATIONS (PROJECT) ━━━
| # | Observation | Severity |
|---|-------------|----------|
| 1 | {observation} | {severity} |

ADD Methodology Adherence:
  ✓ Spec-before-code: {assessment}
  ✓ Auto-handoffs: {assessment}
  ✗ Learning checkpoints: {assessment with specifics}
  ...

━━━ TABLE 3: AGENT OBSERVATIONS (WORKSTATION) ━━━
| # | Observation | Severity |
|---|-------------|----------|
| 1 | {observation} | {severity} |
```

Then ask:

```
Help me polish these. Do you disagree or wish to modify any of these learnings?
```

Wait for human input. Apply modifications to the relevant JSON files and regenerate markdown views.

### Phase 5: Targeted Questions

Ask one at a time. Adapt based on session context:

**Q1 (skip if Autonomous context):** "What went well?"
→ Only ask if the human had enough interactive context to answer meaningfully.

**Q2:** "What needed improvement that was not included already in our learnings?"
→ Scoped to gaps — the tables already surfaced known issues.

**Q3 (rate-limited — 1x per calendar day):** "On a scale of 0.0 to 9.0, how well are we working together?"
→ To check rate limit: read `.add/retros/` for any file matching `retro-{today's date}*.md` that already has a `Human Collaboration` score populated. If found, skip this question.

**Q4 (rate-limited — 1x per calendar day):** "Any improvements for Agent Driven Development you would suggest?"
→ Same rate-limit check as Q3. These two are always asked/skipped together.

### Phase 6: Agent Self-Assessment Scores

The agent provides two self-assessed scores with evidence. These are NOT asked of the human — the agent generates them from data.

**ADD Methodology Effectiveness (0.0-9.0):**
- Based on methodology adherence from Phase 4
- Consider: spec coverage, TDD compliance, handoff discipline, checkpoint completeness, quality gate usage
- Must cite specific evidence (not vague claims)

**Swarm Effectiveness (0.0-9.0):**
- How well did agents collectively build together?
- Consider: parallel subagent usage, context handoff quality between sessions, duplicate work avoided, session continuity
- Must cite specific evidence

Format:

```
━━━ AGENT SELF-ASSESSMENT ━━━
ADD Methodology Effectiveness: {X.X} / 9.0
  Evidence: {specific evidence from the retro window}

Swarm Effectiveness: {X.X} / 9.0
  Evidence: {specific evidence from the retro window}
```

Scores must be justified by evidence. If the agent detects its own score seems inflated relative to evidence, adjust downward. Honesty over optimism.

### Phase 7: Record and Update

1. **Write retro archive:**
   Use `${CLAUDE_PLUGIN_ROOT}/templates/retro.md.template` as structure.
   Write to `.add/retros/retro-{date}.md` (create directory if needed).
   Fill all sections with data from the retro.

2. **Store scores:**
   Read `.add/retro-scores.json` (create from `${CLAUDE_PLUGIN_ROOT}/templates/retro-scores.json.template` if doesn't exist).
   Append entry:
   ```json
   {
     "date": "{YYYY-MM-DD}",
     "collab_score": {X.X},
     "add_effectiveness": {X.X},
     "swarm_effectiveness": {X.X},
     "retro_file": ".add/retros/retro-{date}.md",
     "context": "{collaborative|autonomous|mixed}"
   }
   ```
   If collab score was rate-limited (skipped), use `null` for `collab_score`.

3. **Store ADD feedback:**
   If the human provided ADD improvement suggestions, append to `.add/add-feedback.md`:
   ```markdown
   ## {YYYY-MM-DD}
   - **Suggestion:** {text}
   - **Retro:** .add/retros/retro-{date}.md
   - **Streamed:** false
   ```
   Create the file with `# ADD Methodology Feedback` header if it doesn't exist.

4. **Update learnings:**
   Write new learning entries from the retro as structured JSON to the appropriate file (`.add/learnings.json` or `~/.claude/add/library.json`). Follow the checkpoint process in `rules/learning.md`:
   - Classify scope for each new learning
   - Write to the appropriate JSON file
   - Regenerate the corresponding markdown view

5. **Scope review and reclassification:**
   Review entries classified by agents since the last retro:
   ```
   SCOPE REVIEW — Agent-classified entries since last retro:
     L-{NNN}: "{title}" — classified as {scope} by agent
     WL-{NNN}: "{title}" — classified as {scope} by agent

   Any reclassifications needed?
   ```
   For each reclassification the human approves:
   - Move the entry between JSON files
   - Update `scope` field and `classified_by` to `"human"`
   - Assign new ID appropriate to target file
   - Regenerate both markdown views

6. **Update cross-project persistence:**
   a. **Profile updates** (`~/.claude/add/profile.md`): If retro reveals preferences that carry to other projects, ask: "Add to your ADD profile?"
   b. **Project index** (`~/.claude/add/projects/{name}.json`): Update `last_retro` date and `learnings_count`.

7. **Promote to plugin-global (ADD dev project only):**
   If running inside the ADD plugin project (detected by `knowledge/global.md` existing as a local file), present Tier 1 promotion candidates.

8. **Apply config/template changes:** If agreed changes affect the process, make edits now.

9. **Deduplicate knowledge stores:**
   Check all stores for duplicates or misplaced entries. Report: "{N} duplicates consolidated, {N} entries relocated."

10. **Prune stale entries:**
    - Observations >30 days old without `[synthesized M-{NNN}]` → archive
    - Learnings >90 days old without references → flag for human review (never auto-delete)

11. **Regenerate markdown views** after all JSON modifications.

### Phase 8: Observation Synthesis

Read `.add/observations.md` and synthesize:

1. Group observations by operation type
2. Identify patterns (3+ similar = a pattern)
3. For each pattern, propose a process mutation:
   ```
   ### Proposed Mutation: {title}
   **Skill:** /add:{skill-name}
   **Change:** {concrete change to the skill}
   **Evidence:** {observation timestamps and summaries}
   **Expected outcome:** {what should improve}
   ```
4. Present proposals to human for approval. Only apply approved mutations.

### Phase 9: Apply Approved Mutations

For each human-approved mutation:
1. Read the target skill's SKILL.md
2. Apply the change
3. Log in `.add/mutations.md`
4. Mark source observations as synthesized

### Phase 10: Process Health Assessment

Review `.add/mutations.md` for previously applied mutations:
1. Did the problem recur? → Strengthen mutation
2. Did the problem stop? → Note positive outcome
3. New side effects? → Adjust mutation
4. Report process health summary

### Phase 11: Maturity Promotion Assessment

If the retro surfaces a promotion request, run an evidence-based check. See maturity promotion criteria:

**POC → Alpha:** At least 3 evidence items (specs, tests, CI, commits, etc.) + core concept validated
**Alpha → Beta:** Feature specs exist, coverage >50%, CI/CD configured, PR workflow, 2+ environments, conventional commits, TDD evidence
**Beta → GA:** Coverage >80%, protected branches, release tags, 3+ environments, all gates blocking, 30+ days stability, SLAs defined

Do NOT promote without evidence. Promotion requires proof, not aspiration.

---

## Mode 2: Agent Summary (`--agent-summary`)

Quick, non-interactive mode. Present accumulated observations without a full retro.

1. Read `.add/learnings.json` and `~/.claude/add/library.json`
2. Filter entries since last retro
3. Present structured summary:

```
AGENT OBSERVATIONS — since {last_retro_date}

TECHNICAL DISCOVERIES ({N} entries):
  - {discovery with date}

ARCHITECTURE DECISIONS ({N} entries):
  - {decision with rationale}

ADD METHODOLOGY ADHERENCE:
  {self-assessment checklist}

WHAT WORKED:
  - {positive pattern}

WHAT DIDN'T:
  - {negative pattern}

SUGGESTED CHANGES:
  1. {suggestion with rationale}

These are observations only — no changes applied.
Run /add:retro for a full interactive retrospective.
```

---

## Retro Frequency Guidance

Display during the first retro:

```
RECOMMENDED RETRO CADENCE:
  - Agent auto-checkpoints: Continuous (after each verify, cycle, away session)
  - Agent summary (/add:retro --agent-summary): Weekly or before planning
  - Full interactive retro (/add:retro): After each feature/sprint completion,
    or every 2 weeks — whichever comes first
```

---

## Score Semantics

All scores use 0.0-9.0 scale with 1 decimal precision:

| Range | Meaning |
|-------|---------|
| 0.0-2.0 | Poor — process not working, significant friction |
| 2.1-4.0 | Below average — notable gaps, frequent workarounds |
| 4.1-6.0 | Adequate — functional but room for improvement |
| 6.1-8.0 | Good — effective with minor issues |
| 8.1-9.0 | Excellent — highly effective, minimal friction |

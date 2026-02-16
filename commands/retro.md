---
description: "[ADD v0.2.0] Run a retrospective — human-initiated or review agent learnings"
argument-hint: "[--agent-summary] [--since YYYY-MM-DD] [--scope feature|sprint|session]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite]
---

# ADD Retro Command v0.2.0

Retrospectives capture what worked, what didn't, and what to change. Two modes exist:

- **Interactive retro** (default) — Human and agent reflect together
- **Agent summary** (`--agent-summary`) — Agent presents its accumulated observations for human review

Both modes update `.add/learnings.md` and optionally `~/.claude/add/profile.md`.

## Pre-Flight

1. Read `.add/config.json` for project context
2. Read all 3 knowledge tiers:
   a. **Tier 1:** Read `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md` (plugin-global best practices)
   b. **Tier 2:** Read `~/.claude/add/library.md` if it exists (cross-project wisdom)
   c. **Tier 3:** Read `.add/learnings.md` if it exists (agent observations since last retro)
3. Read `~/.claude/add/profile.md` if it exists (cross-project preferences)
4. Determine the retro window:
   - If `--since` provided, use that date
   - If previous retro exists in `.add/retros/`, use that date as start
   - Otherwise, use project creation date from config
5. Gather data for the retro window:
   - Git log (commits, branches merged, PRs)
   - Specs completed (specs/ with status: Complete)
   - Plans executed (docs/plans/ with status: Complete)
   - Quality gate results from recent `/add:verify` runs
   - Away-mode sessions from `.add/away-logs/`
   - Agent checkpoint entries from `.add/learnings.md`

---

## Mode 1: Interactive Retro (default)

This is the full human-agent retrospective. The human brings strategic and experiential insight. The agent brings data and pattern observations.

### Phase 1: Set Context

Present a summary of the period under review:

```
RETROSPECTIVE — {PROJECT_NAME}
Period: {start_date} → {today}

During this period:
  Specs completed: {N} of {total}
  TDD cycles run: {N}
  Commits: {N} across {N} branches
  PRs merged: {N}
  Quality gate runs: {N} ({N} passed first time, {N} required fixes)
  Away-mode sessions: {N} (total: {hours}h autonomous work)
  Agent checkpoints recorded: {N} learnings

Shall we dive in? This will take about 5 questions (~5 minutes).
```

### Phase 2: Human Perspective (3-4 questions, 1-by-1)

**Q1:** "What went well during this period? What should we keep doing?"
→ Captures: strengths, effective patterns, what to preserve

**Q2:** "What was frustrating, slow, or felt like wasted effort?"
→ Captures: pain points, process friction, things to change

**Q3:** "Were there moments where you wished I had done something differently? Either asked too many questions, or not enough? Worked on the wrong thing? Missed something?"
→ Captures: collaboration quality, human-agent dynamic feedback

**Q4 (if applicable — skip for first retro):** "Last retro we agreed to {changes}. Did those changes help?"
→ Captures: follow-through assessment, whether past improvements stuck

### Phase 3: Agent Perspective

Present the agent's own observations. These come from automatic checkpoints (see Mode 2) plus analysis of the work data:

```
Here's what I observed from the agent side:

VELOCITY:
  - Average TDD cycle time: {N} min per acceptance criterion
  - Fastest: {AC-ID} ({N} min) — {why it was fast}
  - Slowest: {AC-ID} ({N} min) — {why it was slow}
  - Specs that caused the most rework: {list}

SPEC QUALITY:
  - {N} times implementation was blocked by ambiguous specs
  - {N} times tests revealed spec gaps (missing edge cases)
  - Specs that needed mid-implementation revision: {list}
  - Suggestion: {specific improvement to spec template or interview}

QUALITY GATES:
  - First-pass rate: {N}% (passed all gates on first verify)
  - Most common failures: {lint|types|tests|coverage}
  - Tests that were flaky: {list, if any}

COLLABORATION:
  - Questions asked: {N} (quick checks: {N}, decision points: {N})
  - Average human response time: {estimate}
  - Away-mode effectiveness: {N}% of planned work completed

PATTERNS NOTICED:
  - {pattern 1: e.g., "You consistently chose X over Y when given the option"}
  - {pattern 2: e.g., "Feature specs with UI mockup descriptions produced fewer rework cycles"}
  - {pattern 3: e.g., "Integration tests caught issues that unit tests missed in {areas}"}
```

### Phase 4: Agree on Changes

**Q5:** "Based on all of this, what 2-3 things should we change going forward?"

After the human answers, synthesize both perspectives:

```
AGREED CHANGES:
  1. {change from human input}
  2. {change from human input}
  3. {change from agent observation, if human agrees}

I'll apply these by:
  - Updating .add/learnings.md with new entries
  - Updating {specific config/template/rule if applicable}
  - Adding follow-up check to next retro

Shall I apply these changes now?
```

### Phase 5: Record and Update

1. **Archive the retro:**
   ```bash
   mkdir -p .add/retros
   ```
   Write `.add/retros/retro-{date}.md` with full retro content:
   - Period covered
   - Human responses (Q1-Q5)
   - Agent observations
   - Agreed changes
   - Action items

2. **Update project learnings:**
   Append new entries to `.add/learnings.md` under appropriate sections

3. **Update cross-project persistence (if patterns detected):**

   Three levels of promotion from project → personal:

   a. **Profile updates** (`~/.claude/add/profile.md`):
      If the retro reveals preferences that should carry to other projects
      (e.g., "always use Redis", "prefer toast notifications"), ask:
      "I noticed this seems like a general preference. Add to your ADD profile?"

   b. **Library entries** (`~/.claude/add/library.md`):
      If technical learnings are broadly applicable (not project-specific), ask:
      "This learning seems useful across projects. Add to your knowledge library?"

   c. **Project index update** (`~/.claude/add/projects/{name}.json`):
      Update the `last_retro` date and `key_learnings` list in the project snapshot.

4. **Promote to plugin-global (ADD dev project only):**
   If this retro is running inside the ADD plugin project itself (detected by checking
   if `knowledge/global.md` exists as a local file, not a plugin reference), present
   candidates for Tier 1 promotion:

   ```
   PLUGIN-GLOBAL PROMOTION CANDIDATES:
     These learnings could benefit ALL ADD users:
     - {learning 1 — from Tier 3 or Tier 2}
     - {learning 2}

   Promote to knowledge/global.md? (Only if universal — not stack/user/project-specific)
   ```

   Criteria for Tier 1 promotion:
   - Universal: applies regardless of stack, team size, or project type
   - Methodology: relates to ADD workflow, agent coordination, or collaboration
   - Validated: proven across multiple projects or sessions
   - NOT technology preferences, stack patterns, or user conventions

   If promoted, append to `knowledge/global.md` under the appropriate section.

5. **Apply config/template changes:**
   If agreed changes affect the process (e.g., "add edge case section to spec template"),
   make the edits now.

6. **Clear agent checkpoints:**
   Move processed checkpoint entries from `.add/learnings.md` into the retro archive.
   Fresh learnings start accumulating for the next period.
   Profile Update Candidates section is cleared after promotion decisions.

---

## Mode 2: Agent Summary (`--agent-summary`)

Quick, non-interactive mode. The agent presents its accumulated observations
without requiring a full interactive retro. Useful for:
- Checking what the agent has learned recently
- Mid-sprint pulse check
- Before a planning session

### Output

Read `.add/learnings.md` and present a structured summary:

```
AGENT OBSERVATIONS — since {last_retro_date}

TECHNICAL DISCOVERIES ({N} entries):
  - {discovery 1 with date}
  - {discovery 2 with date}

ARCHITECTURE DECISIONS ({N} entries):
  - {decision with rationale}

WHAT WORKED:
  - {positive pattern}

WHAT DIDN'T:
  - {negative pattern}

SUGGESTED CHANGES:
  1. {suggestion with rationale}
  2. {suggestion with rationale}

These are observations only — no changes applied.
Run /add:retro for a full interactive retrospective.
```

---

## Retro Frequency Guidance

Display this during the first retro to set expectations:

```
RECOMMENDED RETRO CADENCE:
  - Agent auto-checkpoints: Continuous (after each verify, spike, away session)
  - Agent summary (/add:retro --agent-summary): Weekly or before planning
  - Full interactive retro (/add:retro): After each feature/sprint completion,
    or every 2 weeks — whichever comes first
```

---

## Observation Synthesis

After the standard retrospective, read `.add/observations.md` and synthesize:

1. **Read** all observations since the last synthesis (or all if first time)
2. **Group** by operation type (verify, deploy, tdd-cycle, handoff)
3. **Identify patterns** — 3+ similar observations = a pattern
4. **For each pattern, propose a process mutation:**
   - What skill should change
   - What specific step to add, modify, or remove
   - Evidence: list the observations that triggered this
   - Expected outcome: what should improve

**Format proposals as:**
```
### Proposed Mutation: {title}
**Skill:** /add:{skill-name}
**Change:** {describe the concrete change to the skill's execution steps}
**Evidence:** {list observation timestamps and summaries}
**Expected outcome:** {what should improve}
```

Present all proposals to the human for approval. Only apply approved mutations.

---

## Apply Approved Mutations

For each human-approved mutation:

1. Read the target skill's SKILL.md
2. Apply the change — add the step, modify the sequence, embed the check
3. Log the mutation in `.add/mutations.md`:
```
## M-{NNN} ({date}, approved)
**Trigger:** {pattern description with observation evidence}
**Change:** {what was modified in which skill}
**Status:** Applied
**Outcome:** {to be filled in at next retro}
```
4. Mark the source observations as "synthesized" (append ` [synthesized M-{NNN}]` to each)

---

## Process Health Assessment

Review `.add/mutations.md` for previously applied mutations:

1. For each mutation applied before this retro, check recent observations:
   - Did the problem recur? → Mutation may need strengthening
   - Did the problem stop? → Mutation is working, note positive outcome
   - New side effects? → Mutation may need adjustment
2. Update the mutation's **Outcome** field with findings
3. Report process health summary:
   - Mutations working: {count}
   - Mutations needing adjustment: {count}
   - New patterns detected: {count}
   - Overall trend: {improving / stable / degrading}

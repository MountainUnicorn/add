---
description: "[ADD v0.1.0] Declare absence — get autonomous work plan for the duration"
argument-hint: [duration, e.g. '4 hours', '30 minutes', 'end of day']
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, TodoWrite]
---

# ADD Away Command v0.1.0

The human is stepping away. Establish what work can proceed autonomously and what must wait.

## Phase 1: Understand the Absence

Parse the duration from $ARGUMENTS. If not provided, ask:
"How long will you be away? (e.g., '2 hours', 'rest of the day', 'until tomorrow')"

## Phase 2: Assess Available Work

1. Read `.add/config.json` for autonomy level and environment tier
2. Scan `specs/` for specs with status "Approved" or "Implementing"
3. Scan `docs/plans/` for plans with status "Approved" or "In Progress"
4. Check current git status for in-progress work
5. Run TodoWrite to see current task list

### Categorize Work

**Autonomous (can do without human):**
- Tasks with clear specs and plans where requirements are unambiguous
- Writing tests for specced features (RED phase)
- Implementing against existing failing tests (GREEN phase)
- Refactoring with test coverage (REFACTOR phase)
- Running quality gates and fixing lint/type errors
- Writing documentation for completed features
- Code review of existing PRs

**Queued (needs human decision):**
- Any task where the spec is ambiguous or missing
- Architecture decisions with multiple valid approaches
- Deployment to staging or production
- New feature specs (need interview)
- Dependency upgrades with breaking changes
- Anything that would benefit from a Decision Point

## Phase 3: Present the Plan

```
Got it — you'll be away for approximately {DURATION}.

AUTONOMOUS WORK PLAN:
━━━━━━━━━━━━━━━━━━━
{numbered list of tasks, with spec references}

Estimated completion: {rough estimate}

QUEUED FOR YOUR RETURN:
━━━━━━━━━━━━━━━━━━━━━
{numbered list of decisions/tasks that need human input}

I'll maintain a work log and have a return briefing ready.
```

## Phase 4: Get Confirmation

Ask: "Does this plan look right? Anything you want me to prioritize or avoid while you're away?"

Wait for confirmation before starting autonomous work.

## Phase 5: Create Away Log

Write `.add/away-log.md` to track progress:

```markdown
# Away Mode Log

**Started:** {timestamp}
**Expected Return:** {timestamp}
**Duration:** {duration}

## Work Plan
{the agreed plan}

## Progress Log
| Time | Task | Status | Notes |
|------|------|--------|-------|
```

Update this log as work progresses.

## During Away Mode

Follow these rules strictly:
- ONLY work on tasks from the approved plan
- Log every completed task in `.add/away-log.md`
- If a blocker is hit, log it and move to the next task
- Do NOT deploy to staging or production
- Do NOT start new features without specs
- Do NOT make irreversible changes
- Send brief status pulses in the conversation at reasonable intervals

---
description: "[ADD v0.2.0] Declare absence — get autonomous work plan for the duration"
argument-hint: [duration, e.g. '4 hours', '30 minutes', 'end of day']
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, TodoWrite]
---

# ADD Away Command v0.2.0

The human is stepping away. Establish what work can proceed autonomously and what must wait.

## Phase 1: Understand the Absence

Parse the duration from $ARGUMENTS. If not provided, default to **2 hours**. Do not ask — just acknowledge the default:
"No duration specified — I'll plan for a 2-hour session. Say `/add:away 4 hours` next time to adjust."

## Phase 2: Assess Available Work

1. Read `.add/config.json` for autonomy level and environment tier
2. **Re-read `docs/prd.md`** to ground yourself in the project's objectives and scope — this keeps autonomous work aligned with the product vision
3. Scan `specs/` for specs with status "Approved" or "Implementing"
4. Scan `docs/plans/` for plans with status "Approved" or "In Progress"
5. Check current git status for in-progress work
6. Run TodoWrite to see current task list

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

Away mode grants **elevated autonomy**. The human is not available — do not wait for input on routine development tasks.

### Autonomous Operations (do NOT ask for permission)
- **Commit to feature branches** — follow conventional commit format, commit after each TDD phase
- **Push to feature branches** — push regularly so work is not lost
- **Create PRs** — open PRs when a feature branch is ready for review
- **Run and fix quality gates** — lint, types, formatting errors are fixed without asking
- **Read specs, plans, and PRD** — re-read `docs/prd.md` whenever you need to validate a decision against the product vision
- **Run tests** — execute test suites freely to verify your work
- **Install dev dependencies** — if tests or builds need a missing dev dependency, install it
- **Promote through environments** — follow the promotion ladder defined in the environment-awareness rule. If verification passes at one level and `autoPromote` is true for the next environment, deploy there and verify. Rollback automatically on failure (see environment-awareness rule for details).

### Boundaries (do NOT cross without human)
- Do NOT deploy to production or any environment where `autoPromote: false`
- Do NOT merge PRs to main/production branches
- Do NOT start new features that lack a spec — if you finish all planned work, write documentation, improve test coverage, or refactor within existing specs
- Do NOT make irreversible changes (drop tables, delete branches, force push)
- Do NOT make architecture decisions with multiple valid approaches — log the decision point and move on

### Staying Aligned
- Before starting each task, re-read the relevant spec and plan
- If a task feels ambiguous, check the PRD (`docs/prd.md`) for guidance
- If still ambiguous after reading the PRD, **log the question and skip to the next task** — do not guess on product direction

### Work Discipline
- ONLY work on tasks from the approved plan
- Log every completed task in `.add/away-log.md`
- If a blocker is hit, log it and move to the next task
- Send brief status pulses in the conversation at reasonable intervals

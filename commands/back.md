---
description: "[ADD v0.3.0] Return from absence — get briefing on autonomous work"
allowed-tools: [Read, Glob, Grep, Bash, TodoWrite]
disable-model-invocation: true
---

# ADD Back Command v0.3.0

The human has returned. Provide a concise briefing on what happened during their absence.

## Phase 1: Gather Status

1. Read `.add/away-log.md` for the work log
2. Read `.add/handoff.md` if it exists — note in-progress work, decisions, blockers, and next steps from the last session
3. Read `.add/swarm-state.md` if it exists — note any parallel agent work that was active, completed, or blocked
4. Read `.add/decisions.md` if it exists — note any architectural decisions made during absence
5. Check git log for commits made during the away period
6. Run test suite to get current status
7. Check for any pending quality gate issues
8. Read TodoWrite for current task state

## Phase 2: Compile Briefing

```
Welcome back. Here's what happened while you were away.

DURATION: {actual time elapsed}

COMPLETED:
━━━━━━━━━
{for each completed task:}
  ✓ {task description}
    Tests: {N passing} | Spec: {AC-IDs covered}
    Commits: {commit hashes}

IN PROGRESS:
━━━━━━━━━━
{any task that was started but not finished:}
  ◐ {task description}
    Status: {where it stands}
    Blocker: {if any}

NEEDS YOUR INPUT:
━━━━━━━━━━━━━━━
{numbered list of decisions queued during absence:}
  1. {decision description}
     Options: {A vs B vs C}
  2. {decision description}

COORDINATION STATE:
━━━━━━━━━━━━━━━━━
  Handoff: {summary of handoff.md — in-progress items and next steps, or "no handoff file"}
  Swarm: {summary of swarm-state.md — active/completed/blocked agents, or "no active swarm"}
  Decisions: {N new decisions logged, or "no new decisions"}

CURRENT PROJECT STATE:
━━━━━━━━━━━━━━━━━━━━
  Tests: {N passing}, {N failing}, {N skipped}
  Coverage: {N}%
  Lint: {clean/N issues}
  Types: {clean/N issues}
  Branch: {current branch}
  Uncommitted changes: {yes/no}
```

## Phase 3: Clean Up

1. Archive `.add/away-log.md` to `.add/away-logs/away-{timestamp}.md` (mkdir -p first)
2. Update TodoWrite with current state

## Phase 4: Re-Engage

Ask: "What would you like to focus on first?"

If there are pending decisions from the queued list, suggest addressing those first since they may unblock further work.

# Swarm Coordination Protocol Reference

> Full reference for parallel multi-agent work. Loaded by `/add:cycle` when
> dispatching parallel agents. Core agent coordination rules are in
> `rules/agent-coordination.md`.

## Conflict Assessment

Before dispatching parallel agents, assess file conflict risk:

1. Read specs for all parallel features
2. Identify implementation file paths from each spec
3. Build a conflict matrix — do any features touch the same files?
4. Classify each feature pair as:
   - **Independent** — no shared files → safe to parallelize
   - **Low conflict** — shared read-only files (imports, types) → parallelize with file reservations
   - **High conflict** — shared mutable files (same module, same DB migration) → serialize

## Git Worktree Strategy (Recommended for beta/ga maturity)

For parallel agents on independent features:

```
# Setup (orchestrator runs once)
git worktree add ../project-feature-auth feature/auth
git worktree add ../project-feature-billing feature/billing
git worktree add ../project-feature-onboarding feature/onboarding

# Each agent works in its own worktree
Agent A → ../project-feature-auth/
Agent B → ../project-feature-billing/
Agent C → ../project-feature-onboarding/

# Merge sequence (orchestrator manages)
1. Merge feature with most shared infrastructure first
2. Rebase remaining branches
3. Merge next feature
4. Repeat until all merged
```

## File Reservation Strategy (Simpler alternative for alpha maturity)

When worktrees are overkill (alpha maturity, 1-2 parallel agents):

```
RESERVATIONS:
  Agent A owns: src/auth/**, tests/auth/**
  Agent B owns: src/billing/**, tests/billing/**
  SHARED (serialize access): src/models/user.ts, src/db/migrations/**
```

Rules:
- Agents must not write to files outside their reservation
- Shared files require explicit handoff (Agent A finishes, then Agent B may modify)
- The orchestrator tracks reservations in the cycle plan

## WIP Limits

| Maturity | Max Parallel Agents | Max Features In-Progress | Max Cycle Items |
|----------|--------------------|--------------------------|-|
| poc | 1 | 1 | 2 |
| alpha | 2 | 2 | 4 |
| beta | 4 | 4 | 6 |
| ga | 5 | 5 | 6 |

If WIP limit is reached, new work must wait until an in-progress item is VERIFIED.

## Sub-Agent Brief Template

When dispatching a sub-agent for cycle work:

```
## Agent Brief: {feature-name}

CYCLE: cycle-{N}
MILESTONE: M{N} — {milestone-name}
MATURITY: {level}

TASK: {what to do — e.g., "Advance from SPECCED to VERIFIED"}
SPEC: specs/{feature}.md
PLAN: docs/plans/{feature}-plan.md

FILE RESERVATIONS:
  OWNED: {files this agent may write}
  READ-ONLY: {files this agent may read but not modify}
  FORBIDDEN: {files owned by other agents}

LEARNINGS TO APPLY:
  Tier 1 (plugin-global): {relevant entries from knowledge/global.md}
  Tier 2 (user-local): {relevant entries from ~/.claude/add/library.md}
  Tier 3 (project): {relevant entries from .add/learnings.md}

QUALITY GATES (per maturity):
  {which gates must pass for this maturity level}

VALIDATION CRITERIA:
  {from cycle plan — what "done" means for this item}

REPORT BACK:
  STATUS: success | partial | blocked
  FILES_CHANGED: {list}
  TEST_RESULTS: {pass/fail counts}
  BLOCKERS: {if any}
```

## Merge Coordination

After parallel agents complete:

1. **Identify merge order** — feature touching shared infrastructure merges first
2. **Run integration tests** after each merge (not just after all merges)
3. **If merge conflict**: orchestrator resolves, re-runs affected agent's tests
4. **Final verification**: run full quality gates on merged main branch
5. **Update cycle status**: mark items as VERIFIED or flag failures

## Swarm State Coordination

Coordinate via `.add/swarm-state.md`:

### Claiming Work
```
## {agent-role} ({timestamp})
status: active
claimed: {what this agent is working on — spec, files, scope}
depends-on: {other agent roles this work depends on, or "none"}
```

### Reporting Results
```
## {agent-role} ({timestamp})
status: complete
claimed: {scope}
result: {one-line summary of output}
blockers: {anything that prevented full completion, or "none"}
handoff: {what the next agent needs to know}
```

### Rules
- Check swarm-state BEFORE claiming work — if another agent has claimed overlapping scope, coordinate or wait
- Status values: `active`, `complete`, `blocked`, `abandoned`
- The orchestrator clears swarm-state at the start of each new multi-agent operation
- Swarm-state is working state, not permanent record — cleared between cycles

## Micro-Retro After Multi-Agent Operations

After ALL parallel agents complete and their work is merged:

1. **Collect observations** — Read `[agent-retro]` tagged entries from `.add/observations.md`
2. **Synthesize** — Identify the single most impactful process insight
3. **Record** — Append one synthesis entry to `.add/observations.md`
4. **Apply immediately** — If actionable for the current session, apply to remaining dispatches

## Anti-Patterns

- **Never** let two agents write to the same file simultaneously
- **Never** go deeper than 2 levels of agent hierarchy (orchestrator → worker)
- **Never** exceed WIP limits — coordination overhead grows exponentially
- **Never** dispatch sub-agents without reading all 3 knowledge tiers first
- **Never** merge without running integration tests after each merge
- **Avoid** parallel work at poc maturity — overhead exceeds benefit

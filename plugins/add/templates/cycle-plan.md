# Cycle {N} — {CYCLE_TITLE}

**Milestone:** M{X} — {Milestone Name}
**Maturity:** {poc|alpha|beta|ga}
**Status:** PLANNED
**Started:** TBD
**Completed:** TBD
**Duration Budget:** {e.g., "3 days", "1 week"}

## Work Items

| Feature | Current Pos | Target Pos | Assigned | Est. Effort | Validation |
|---------|-------------|-----------|----------|-------------|------------|
| {FEATURE_1} | SPECCED | IN_PROGRESS | Agent-1 | ~4 hours | All acceptance criteria passing in tests |
| {FEATURE_2} | SHAPED | SPECCED | Agent-2 | ~2 hours | Spec complete, 2 reviewers sign off |

## Dependencies & Serialization

{Visual and text description of what must run serially}

Example:

```
Auth Overhaul (Agent-1)
    ↓ (Session Refresh depends on Auth completion)
Session Refresh (Agent-1)

Mobile Logout (Agent-2) — parallel to above
```

## Parallel Strategy

{If maturity is Beta/GA}

### File Reservations
- **Agent-1:** src/auth/*, src/session/* (owns auth + session infrastructure)
- **Agent-2:** src/mobile/logout/* (owns logout UI)

### Merge Sequence
1. Auth Overhaul (infrastructure)
2. Session Refresh (depends on Auth)
3. Mobile Logout (independent, but benefits from stable Auth)

{If maturity is POC/Alpha: "Single-threaded execution. Features advance sequentially."}

## Validation Criteria

### Per-Item Validation
- {FEATURE_1}: {Acceptance criteria 1, 2, 3} + all tests passing
- {FEATURE_2}: {Acceptance criteria} + spec approved by human

### Cycle Success Criteria
- [ ] All features reach target position
- [ ] All acceptance criteria verified
- [ ] Code review completed (Alpha+)
- [ ] Pre-deploy QA passed (Beta+)
- [ ] No regressions in regression suite

## Agent Autonomy & Checkpoints

{Based on maturity + availability}

POC: Full autonomy. Agent executes cycle and updates status daily.

Alpha: High autonomy. Agent plans, executes, flags blockers async. Human checks in every 2 days.

Beta: Balanced. Human approves cycle plan at start, agent executes, human verifies results and signs off.

GA: Guided with checkpoints. Human approval at cycle start. Agent provides daily standup. Human approval before merge. Human approval before deploy.

## Notes

{Any other context: blockers, risks specific to this cycle, design decisions to confirm, etc.}

---
autoload: true
---

# ADD Rule: Continuous Learning

Agents accumulate knowledge through structured checkpoints. This knowledge persists in `.add/learnings.md` and is consumed by all agents before starting work.

## Read Before Work

Before starting ANY skill or command (except /add:init), check if `.add/learnings.md` exists.
If it does, read it. Previous learnings may affect how you approach the current task.

For example:
- If a learning says "pymysql is not thread-safe," avoid threading patterns in DB code
- If a learning says "spec X was ambiguous about error handling," be more specific in similar specs
- If a learning says "E2E tests flaky with parallel workers in CI," use workers: 1 in CI config

## Checkpoint Triggers

Agents automatically write checkpoint entries to `.add/learnings.md` at these moments.
No human involvement needed — this is the agent learning autonomously.

### After Verification (/add:verify completes)

If any quality gate failed and was fixed, record what went wrong:

```markdown
## Checkpoint: Post-Verify — {date}
- **Gate failure:** {which gate, which check}
- **Root cause:** {why it failed}
- **Fix applied:** {what was changed}
- **Prevention:** {how to avoid this in future}
```

If all gates passed first time, record that too (positive reinforcement):

```markdown
## Checkpoint: Post-Verify — {date}
- **Clean pass:** All gates passed on first run
- **Notable:** {anything worth remembering, or "routine"}
```

### After TDD Cycle Completes

Record velocity and quality observations:

```markdown
## Checkpoint: Post-TDD — {date} — {spec reference}
- **ACs covered:** {list}
- **Cycle time:** {duration}
- **RED phase:** {N} tests written, {any difficulties}
- **GREEN phase:** {clean or required iteration}
- **Blockers:** {none, or description}
- **Spec quality:** {clear | ambiguous in {areas} | missing {details}}
```

### After Away-Mode Session

When the human returns and `/add:back` runs:

```markdown
## Checkpoint: Post-Away — {date}
- **Duration:** {planned} → {actual}
- **Planned tasks:** {N}
- **Completed:** {N}
- **Blocked:** {N} — {reasons}
- **Decisions queued:** {N}
- **Autonomous effectiveness:** {percentage completed}
- **What would have helped:** {e.g., "clearer spec for feature X", "access to staging env"}
```

### After Spec Implementation Completes

When all acceptance criteria for a spec have passing tests and code:

```markdown
## Checkpoint: Feature Complete — {date} — specs/{feature}.md
- **Total ACs:** {N}
- **Total TDD cycles:** {N}
- **Total time:** {estimate}
- **Rework cycles:** {N} (times implementation had to be revised)
- **Spec revisions needed:** {N} (times spec was updated mid-implementation)
- **What went well:** {observation}
- **What to improve:** {observation}
- **Patterns discovered:** {any reusable code, architecture insight, or gotcha}
```

### After Deployment

When `/add:deploy` completes (any environment):

```markdown
## Checkpoint: Post-Deploy — {date} — {environment}
- **Environment:** {local|dev|staging|production}
- **Smoke tests:** {passed|failed — details}
- **Issues found:** {none, or description}
- **Deployment notes:** {anything notable about the deploy process}
```

### When Verification Catches Sub-Agent Error

This is the trust-but-verify learning moment:

```markdown
## Checkpoint: Verification Catch — {date}
- **Agent:** {test-writer|implementer|other}
- **Error:** {what the sub-agent did wrong}
- **Correct approach:** {what should have been done}
- **Pattern to avoid:** {generalized lesson}
```

## Learnings File Structure

`.add/learnings.md` has these sections. Append to the appropriate section:

```markdown
# Project Learnings — {PROJECT_NAME}

## Technical Discoveries
<!-- Things learned about the tech stack, libraries, APIs, infrastructure -->

## Architecture Decisions
<!-- Decisions made and their rationale -->

## What Worked
<!-- Patterns, approaches, tools that proved effective -->

## What Didn't Work
<!-- Patterns, approaches, tools that caused problems -->

## Agent Checkpoints
<!-- Automatic entries from triggers above — processed during /add:retro -->
```

## Checkpoint Format Rules

- Keep entries concise (3-5 lines max)
- Always include the date
- Always include a reference (spec, file, or feature name)
- Focus on ACTIONABLE insights, not just observations
- Don't duplicate — if the same lesson already exists, don't add it again
- Prefix new entries with the checkpoint type for easy scanning

## Profile Updates

Some learnings are project-specific. Others reveal cross-project preferences.

**Project-specific** (stays in `.add/learnings.md`):
- "SeekDB graph queries with > 3 hops are slow in this schema"
- "The news API rate-limits at 100 req/day"

**Cross-project** (should propagate to `~/.claude/add/profile.md`):
- "User always chooses Redis over in-memory caching"
- "User prefers toast notifications over alert dialogs"
- "User prefers Alpine-based Docker images"

Cross-project patterns should only be promoted to the profile during a `/add:retro`
with human confirmation. Agents flag candidates but don't auto-update the profile.

```markdown
## Profile Update Candidates
<!-- Flagged during checkpoints, promoted during /add:retro -->
- {date}: User chose Redis again (3rd time). Promote to profile?
```

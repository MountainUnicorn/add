---
autoload: true
---

# ADD Rule: Continuous Learning

Agents accumulate knowledge through structured checkpoints. Knowledge is organized in three tiers and consumed by all agents before starting work.

## Knowledge Tiers

ADD uses a 3-tier knowledge cascade. Agents read all three tiers before starting work, with more specific tiers taking precedence:

| Tier | Location | Scope | Who Updates |
|------|----------|-------|-------------|
| **Tier 1: Plugin-Global** | `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md` | Universal ADD best practices for all users | ADD maintainers only |
| **Tier 2: User-Local** | `~/.claude/add/library.md` | Cross-project wisdom accumulated by this user | Promoted during `/add:retro` |
| **Tier 3: Project-Specific** | `.add/learnings.md` | Discoveries specific to this project | Auto-checkpoints + `/add:retro` |

**Precedence:** Project-specific (Tier 3) > User-local (Tier 2) > Plugin-global (Tier 1). If a project learning contradicts a global learning, the project learning wins for that project.

## Read Before Work

Before starting ANY skill or command (except /add:init), read all available knowledge tiers:

1. **Tier 1:** Read `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md` (always exists — ships with ADD)
2. **Tier 2:** Check if `~/.claude/add/library.md` exists. If it does, read it.
3. **Tier 3:** Check if `.add/learnings.md` exists. If it does, read it.

Previous learnings from any tier may affect how you approach the current task. For example:
- Tier 1: "Trust-but-verify: always independently run tests after sub-agent work"
- Tier 2: "User always chooses Redis over in-memory caching" (from library)
- Tier 3: "pymysql is not thread-safe in this project's schema" (from project learnings)

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

## Knowledge Promotion

Learnings naturally flow upward through the tiers during retrospectives. Each tier has different promotion criteria.

### Tier 3 → Tier 2 (Project → User Library)

Cross-project patterns discovered in any project should be promoted to `~/.claude/add/library.md`:

**Promote when:**
- A pattern applies across projects (not tied to a specific codebase)
- A technical insight transfers to other stacks or contexts
- An anti-pattern would be harmful in any project

**Examples:**
- "User always chooses Redis over in-memory caching" → Profile (`~/.claude/add/profile.md`)
- "UUID columns must be type uuid, not text" → Library (`~/.claude/add/library.md`)

Cross-project patterns should only be promoted during `/add:retro` with human confirmation. Agents flag candidates but don't auto-update.

```markdown
## Profile Update Candidates
<!-- Flagged during checkpoints, promoted during /add:retro -->
- {date}: User chose Redis again (3rd time). Promote to profile?
```

### Tier 2/3 → Tier 1 (User/Project → Plugin-Global)

The highest bar. Plugin-global knowledge ships to ALL ADD users.

**Promote when:**
- The insight is universal — applies regardless of stack, team size, or project type
- It reflects an ADD methodology truth (not a tech stack preference)
- It has been validated across multiple projects or users
- It relates to agent coordination, collaboration, or ADD workflow patterns

**Do NOT promote:**
- Technology-specific preferences (Redis vs Memcached)
- Stack-specific patterns (React hooks, Python decorators)
- Project-specific constraints (API rate limits, schema quirks)
- User preferences (naming conventions, UI patterns)

**Process:** Only the ADD development project can write to `knowledge/global.md`. During `/add:retro` in the ADD project itself, the retro flow includes a "promote to plugin-global" step. In consumer projects, `knowledge/global.md` is read-only.

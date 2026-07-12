# Skill Epilogue — Shared End-of-Skill Contract

Every ADD skill starts and ends the same way. Skills point here instead of
restating this contract. The pointer line in each SKILL.md is:

> End-of-skill epilogue: follow `${CLAUDE_PLUGIN_ROOT}/references/skill-epilogue.md` (observation + learning checkpoint + progress tracking).

## Session-Handoff Preflight (start of skill)

Read `.add/handoff.md` if it exists before doing any work:

- Note any in-progress work or decisions relevant to this operation
- If the handoff mentions blockers for this skill's scope, warn before proceeding

## Progress Tracking (during skill)

Use TaskCreate and TaskUpdate to report progress through the CLI spinner:

- Create tasks at the start of each major phase, using the skill's "Tasks to
  create" table (Subject + activeForm) when it defines one; otherwise derive
  one task per phase heading
- Mark each task `in_progress` when starting and `completed` when done
- This gives the user real-time visibility into skill execution

## Process Observation (after skill completes)

Do BOTH of the following.

### 1. Observation Line

Append one observation line to `.add/observations.md`:

```
{YYYY-MM-DD HH:MM} | {skill-name} | {one-line summary of outcome} | {cost or benefit estimate}
```

If `.add/observations.md` does not exist, create it with a
`# Process Observations` header first.

### 2. Learning Checkpoint

Write a structured JSON learning entry per the matching checkpoint trigger in
`${CLAUDE_PLUGIN_ROOT}/references/learning-reference.md` (e.g., "After
Verification", "After TDD Cycle Completes", "After Deployment"):

1. Classify scope — project vs workstation
2. Write to the appropriate JSON file: `.add/learnings.json` or
   `~/.claude/add/library.json`
3. Regenerate the active markdown view — a PostToolUse hook regenerates
   `-active.md` automatically whenever a learnings JSON file is written; if it
   didn't fire, run `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh <path-to-json>`

JSON is canonical. Generated markdown views (`learnings.md`, `library.md`,
`-active.md`) are never edited directly.

---
autoload: true
---

# ADD Rule: Agent Coordination Protocol

When multiple agents work on a project, they follow the orchestrator pattern with trust-but-verify.

## Orchestrator Role

The orchestrator (primary Claude session) is responsible for:

1. Breaking work into bounded tasks for sub-agents
2. Assigning each task with clear inputs, scope, and success criteria
3. Independently verifying sub-agent output
4. Maintaining the overall project state and progress

## Sub-Agent Dispatching

When dispatching work to a sub-agent, always provide:

```
TASK: {what to do}
SCOPE: {which files, which feature, what boundaries}
SPEC REFERENCE: {specs/{feature}.md, acceptance criteria IDs}
SUCCESS CRITERIA:
  - {testable criterion 1}
  - {testable criterion 2}
INPUT FILES: {files the agent needs to read}
OUTPUT: {what the agent should produce — files, test results, summary}
RESTRICTIONS: {what the agent should NOT do}
```

## Trust-But-Verify

After any sub-agent completes work:

1. **Read the output** — Review files changed, tests written, code produced
2. **Run tests independently** — Do NOT trust the sub-agent's test output alone
3. **Check spec compliance** — Does the output satisfy the acceptance criteria?
4. **Run quality gates** — Lint, type check, coverage
5. **Only then** accept the work into the main branch

Never skip verification. A sub-agent reporting "all tests pass" is necessary but not sufficient.

## Agent Isolation

Sub-agents should have bounded scope to prevent unintended side effects:

### Test Writer Agent
- CAN: Read specs, read existing code, write test files
- CANNOT: Modify implementation code, run deploy commands, modify configuration

### Implementer Agent
- CAN: Read specs, read tests, write/edit implementation files
- CANNOT: Modify test files, deploy, change project configuration

### Reviewer Agent
- CAN: Read all files, run tests, run linters, produce review report
- CANNOT: Modify any files

### Deploy Agent
- CAN: Run build commands, run deployment scripts, verify endpoints
- CANNOT: Modify source code, modify tests

## Parallel Execution

When tasks are independent, dispatch them in parallel:

```
PARALLEL DISPATCH:
  Agent A: Write unit tests for user service (specs/auth.md AC-001 through AC-004)
  Agent B: Write unit tests for API routes (specs/auth.md AC-005 through AC-008)
  Agent C: Write E2E test scaffolding (specs/auth.md TC-001 through TC-003)

WAIT FOR ALL

SEQUENTIAL:
  Orchestrator: Run full test suite (verify all agents' tests coexist)
  Orchestrator: Verify no conflicts or duplicate coverage
```

## Context Management

- Each sub-agent starts with a clean context (no conversation history pollution)
- Pass only the files and spec sections relevant to the task
- Use `/clear` between major context switches in the orchestrator
- When context gets long, summarize state and start a fresh session

## Output Format

Sub-agents must return structured output:

```
STATUS: success | partial | blocked
FILES_CHANGED:
  - path/to/file.ts (created | modified | deleted)
TEST_RESULTS:
  passed: N
  failed: N
  skipped: N
SPEC_COMPLIANCE:
  - AC-001: covered by test_user_login
  - AC-002: covered by test_invalid_password
SUMMARY: {1-2 sentence description of what was done}
BLOCKERS: {any issues that prevented completion}
```

## Escalation

If a sub-agent encounters any of these, it must stop and report back:

- Spec is ambiguous or contradictory
- Required dependency or file doesn't exist
- Tests reveal a design issue that needs spec revision
- Task scope is larger than estimated (> 2x)
- Security concern discovered

The orchestrator then either resolves the issue or escalates to the human via a Decision Point.

## Learning-on-Verify

Verification is a learning opportunity. When the orchestrator verifies sub-agent work, it must record what happened — both successes and failures.

### When Verification Catches an Error

1. Fix the issue
2. Append a checkpoint to `.add/learnings.md`:
   ```markdown
   ## Checkpoint: Verification Catch — {date}
   - **Agent:** {test-writer|implementer|other}
   - **Error:** {what went wrong}
   - **Correct approach:** {what should have been done}
   - **Pattern to avoid:** {generalized lesson for future work}
   ```
3. If the error reveals a spec gap, flag it for the next retro

### When Verification Passes Clean

Still worth recording if something notable happened:
- A non-obvious approach that worked well
- A pattern that should be reused
- Unexpectedly fast or slow execution

### Before Dispatching Sub-Agents

The orchestrator MUST read all 3 knowledge tiers and include relevant lessons in the dispatch context:

1. **Tier 1:** `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md` — universal ADD best practices
2. **Tier 2:** `~/.claude/add/library.md` — user's cross-project wisdom (if exists)
3. **Tier 3:** `.add/learnings.md` — project-specific discoveries (if exists)

For example, if a Tier 3 checkpoint says "pymysql is not thread-safe," include that in the RESTRICTIONS when dispatching database-related work. If a Tier 1 entry says "always independently run tests after sub-agent work," ensure the verification step is in the dispatch plan.

This is how the team gets smarter over time — past mistakes from all tiers inform future dispatches.

## Agent Self-Retro Triggers

Agents should run mini-retrospectives (write checkpoints to `.add/learnings.md`) automatically at these moments — NO human involvement needed:

1. **After /add:verify completes** — Record pass/fail, what was fixed
2. **After a TDD cycle completes** — Record velocity, spec quality, blockers
3. **After /add:deploy completes** — Record environment, smoke test results
4. **After /add:back processes an away session** — Record autonomous effectiveness
5. **After a full spec implementation** — Record overall feature learnings
6. **When a sub-agent error is caught** — Record the error and correction

These checkpoints accumulate between human retrospectives. The human reviews them with `/add:retro --agent-summary` or during a full `/add:retro`.

## Swarm Coordination Protocol

When a cycle plan calls for parallel feature work, the orchestrator follows this protocol:

### Conflict Assessment
Before dispatching parallel agents, assess file conflict risk:

1. Read specs for all parallel features
2. Identify implementation file paths from each spec
3. Build a conflict matrix — do any features touch the same files?
4. Classify each feature pair as:
   - **Independent** — no shared files → safe to parallelize
   - **Low conflict** — shared read-only files (imports, types) → parallelize with file reservations
   - **High conflict** — shared mutable files (same module, same DB migration) → serialize

### Git Worktree Strategy (Recommended for beta/ga maturity)

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

### File Reservation Strategy (Simpler alternative for alpha maturity)

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

### WIP Limits

Work-in-progress limits prevent coordination overhead from exceeding parallelism benefit:

| Maturity | Max Parallel Agents | Max Features In-Progress | Max Cycle Items |
|----------|--------------------|--------------------------|-|
| poc | 1 | 1 | 2 |
| alpha | 2 | 2 | 4 |
| beta | 4 | 4 | 6 |
| ga | 5 | 5 | 6 |

If WIP limit is reached, new work must wait until an in-progress item is VERIFIED.

### Sub-Agent Brief Template

When dispatching a sub-agent for cycle work, provide this brief (keeps context focused):

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

### Merge Coordination

After parallel agents complete:

1. **Identify merge order** — feature touching shared infrastructure merges first
2. **Run integration tests** after each merge (not just after all merges)
3. **If merge conflict**: orchestrator resolves, re-runs affected agent's tests
4. **Final verification**: run full quality gates on merged main branch
5. **Update cycle status**: mark items as VERIFIED or flag failures

### Anti-Patterns

- **Never** let two agents write to the same file simultaneously
- **Never** go deeper than 2 levels of agent hierarchy (orchestrator → worker)
- **Never** exceed WIP limits — coordination overhead grows exponentially
- **Never** dispatch sub-agents without reading all 3 knowledge tiers first
- **Never** merge without running integration tests after each merge
- **Avoid** parallel work at poc maturity — overhead exceeds benefit

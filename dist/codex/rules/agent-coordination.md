---
autoload: true
maturity: beta
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

When dispatching work to a sub-agent, always provide: TASK, SCOPE, SPEC REFERENCE, SUCCESS CRITERIA, INPUT FILES, OUTPUT expectations, and RESTRICTIONS.

Before dispatching, read all 3 knowledge tiers and include relevant lessons in context.

### Cache-Aware Dispatch Layout

Every dispatched prompt body MUST follow the stable-prefix layout defined
in `rules/cache-discipline.md`. Wrap the emitted prompt with
`<!-- CACHE: STABLE -->` and `<!-- CACHE: VOLATILE -->` markers in that
order. The STABLE region (active autoload rules, tier-1 knowledge active
views, project identity, active learnings, current spec body) MUST be
byte-identical across every sub-agent dispatch within a session. Only the
VOLATILE suffix — role, per-call task, AC subset, hints — varies between
test-writer, implementer, and reviewer dispatches. This keeps Anthropic's
prompt cache warm and compounds hits across the TDD cycle (see
`specs/cache-discipline.md § 5` for before/after example).

## Trust-But-Verify

After any sub-agent completes work:

1. **Read the output** — Review files changed, tests written, code produced
2. **Run tests independently** — Do NOT trust the sub-agent's test output alone
3. **Check spec compliance** — Does the output satisfy the acceptance criteria?
4. **Run quality gates** — Lint, type check, coverage
5. **Only then** accept the work into the main branch

Never skip verification. A sub-agent reporting "all tests pass" is necessary but not sufficient.

## Agent Isolation

| Agent | CAN | CANNOT |
|-------|-----|--------|
| Test Writer | Read specs/code, write test files | Modify implementation, deploy, change config |
| Implementer | Read specs/tests, write implementation | Modify tests, deploy, change config |
| Reviewer | Read all files, run tests/linters, produce reports | Modify any files |
| Deploy | Run builds, deploy scripts, verify endpoints | Modify source code or tests |

## Parallel Execution

When tasks are independent, dispatch in parallel. After all complete, the orchestrator runs the full test suite to verify agents' work coexists without conflicts.

## Context Management

- Each sub-agent starts with a clean context
- Pass only relevant files and spec sections
- Use `/clear` between major context switches

## Sub-Agent Output Format

Sub-agents must return: STATUS (success/partial/blocked), FILES_CHANGED, TEST_RESULTS, SPEC_COMPLIANCE mapping, SUMMARY, and BLOCKERS.

## Escalation

Sub-agents stop and report back when: spec is ambiguous, dependency missing, tests reveal design issues, scope is >2x estimate, or security concern found.

## Learning-on-Verify

When verification catches an error: fix it, write a checkpoint to `.add/learnings.json`, flag spec gaps for retro, and append an `[agent-retro]` observation to `.add/observations.md`.

When verification passes clean, record notable patterns worth reusing.

## Swarm Coordination

For parallel multi-agent work (cycle plans with 2+ agents), see the full protocol at `${CLAUDE_PLUGIN_ROOT}/references/swarm-protocol.md`. Key points:

- Assess file conflict risk before dispatching (independent / low conflict / high conflict)
- Use git worktrees (beta/ga) or file reservations (alpha) for isolation
- WIP limits: poc=1, alpha=2, beta=4, ga=5 parallel agents
- Never let two agents write to the same file simultaneously
- Run integration tests after each merge, not just after all merges
- Write micro-retro to `.add/observations.md` after multi-agent operations complete

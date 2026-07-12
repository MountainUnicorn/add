# Swarm Coordination Protocol Reference

> ADD's **policy layer** for parallel multi-agent work. ADD owns the *policy* —
> concurrency limits, conflict assessment, role briefs, merge ordering,
> trust-but-verify gates, swarm-state. The *mechanism* — parallel dispatch,
> worktree isolation, step-output schemas, budgets — is delegated to the runtime
> when it provides one:
>
> - **Claude Code:** ADD's policy maps onto native **Dynamic Workflows**
>   (`parallel()`/`pipeline()`, schema-validated output, per-step budgets,
>   worktree isolation).
> - **Codex CLI:** maps onto native **TOML sub-agents**.
> - **No native orchestration:** the manual recipes in this file are the
>   fallback. Policy is identical in all three paths.
>
> **Litmus test:** if a paragraph describes *how* to run agents in parallel, it's
> mechanism (delegate it). If it describes *whether, how many, in what order, and
> whether to trust the result*, it's policy (ADD owns it). Loaded by `/add:cycle`.
> Core coordination rules are in `rules/agent-coordination.md`.

## Conflict Assessment

Before dispatching parallel agents, assess file conflict risk:

1. Read specs for all parallel features
2. Identify implementation file paths from each spec
3. Build a conflict matrix — do any features touch the same files?
4. Classify each feature pair as:
   - **Independent** — no shared files → safe to parallelize
   - **Low conflict** — shared read-only files (imports, types) → parallelize with file reservations
   - **High conflict** — shared mutable files (same module, same DB migration) → serialize

## Worktree Isolation — delegated to the runtime (manual recipe = fallback)

> **MECHANISM (runtime-owned).** ADD's *policy* is only: beta/ga ⇒ isolation
> REQUIRED; alpha ⇒ file reservations acceptable; poc ⇒ serial, no isolation.
> *How* isolation happens is the runtime's job — Claude Workflows create per-step
> worktrees (set isolation on the parallel group; ADD does not run `git worktree
> add` by hand), Codex provisions a worktree per sub-agent. The recipe below is
> the **manual fallback** for runtimes with no native orchestration.

Manual fallback — for parallel agents on independent features:

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

> **POLICY (ADD-owned) — the single most important swarm input.** These limits
> are invariant across native and manual paths. Where a runtime orchestrates,
> they become its concurrency config (Claude Workflow parallel-group concurrency
> / Codex sub-agent pool size); in the manual fallback they cap how many agents
> the orchestrator dispatches at once.

| Maturity | Max Parallel Agents | Max Features In-Progress | Max Cycle Items |
|----------|--------------------|--------------------------|-|
| poc | 1 | 1 | 2 |
| alpha | 2 | 2 | 4 |
| beta | 4 | 4 | 6 |
| ga | 5 | 5 | 6 |

If WIP limit is reached, new work must wait until an in-progress item is VERIFIED.

## Resource Budgets

> **POLICY (ADD-owned).** Like WIP limits, these are the numbers ADD supplies;
> the *mechanism* that enforces them — Workflow per-step budgets, model
> overrides on dispatch — belongs to the runtime. Frontier models are
> expensive: an orchestrator that runs every dispatch on the largest model with
> no token ceiling burns budget without buying quality. Scale spend with
> maturity, exactly as WIP limits scale concurrency.

| Maturity | Per-Cycle-Item Token Budget | Per-Sub-Agent Dispatch Cap | Notes |
|----------|-----------------------------|-----------------------------|-------|
| poc | ~30k tokens/item | 1 cheap dispatch | Minimal — single fast/editor-tier dispatch, no parallel spend |
| alpha | ~60k tokens/item | ~30k/dispatch | Editor-tier default; escalate only on verification failure |
| beta | ~120k tokens/item | ~60k/dispatch | Architect tier for review; editor tier for the bulk |
| ga | ~200k tokens/item | ~80k/dispatch | Includes adversarial verify pass on top of standard gates |

These are **guidance defaults**, overridable in `.add/config.json` →
`swarm.budgets`. Where a runtime orchestrates, they become its budget config
(Claude Workflow per-step budgets / model overrides); in the manual fallback
the orchestrator states them in each sub-agent brief and treats overrun as a
`blocked` report.

### Role → tier defaults

Tiers are the capability tiers from `rules/model-roles.md` — never hardcoded
model names:

- **test-writer** → editor
- **implementer** → editor
- **reviewer** → architect
- **verify** → editor
- **explorer** → fast
- **mechanical generation** (dashboards, SVG, docs rendering) → fast

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

MODEL: {fast | editor | architect — capability tier per rules/model-roles.md, not a model name}
BUDGET: {max tokens for this dispatch — from the Resource Budgets table, or .add/config.json → swarm.budgets}

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

### Format Contract

`.add/swarm-state.md` is a **machine-readable** coordination log so any consumer
— a human, the orchestrator, or a native Workflow's journaled state — can parse
it the same way. The contract:

- **Entry delimiter:** each claim/report is one Markdown `## ` (H2) block. The
  heading is exactly `## {agent-role} ({timestamp})`.
- **agent-role:** kebab-case, matches a defined role (`test-writer`,
  `implementer`, `reviewer`, `verify`, `explorer`, or `orchestrator`).
- **timestamp:** ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). The latest block per
  agent-role is authoritative.
- **fields:** one `key: value` per line within a block; unknown keys are
  ignored by parsers (forward-compatible).

| Field | Required when | Type | Notes |
|-------|---------------|------|-------|
| `status` | always | enum | `active` \| `complete` \| `blocked` \| `abandoned` |
| `claimed` | always | string | the scope (spec, files, or area) this agent owns |
| `depends-on` | claiming | string | other agent-roles, or `none` |
| `result` | `complete` | string | one-line output summary |
| `blockers` | `complete`/`blocked` | string | what prevented completion, or `none` |
| `handoff` | `complete` | string | what the next agent needs to know |

A parser reads the file, splits on `^## `, takes the last block per agent-role,
and reads `key: value` lines. This contract is stable: fields may be *added*
(consumers ignore unknown keys) but existing field names and the `status` enum
must not change meaning without a version bump to this section.

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
- **Never** re-implement parallel dispatch or worktree setup inline when the runtime provides native orchestration — delegate the mechanism, keep the policy
- **Never** let delegation skip trust-but-verify — a runtime reporting "success" is necessary but not sufficient; the orchestrator still independently verifies

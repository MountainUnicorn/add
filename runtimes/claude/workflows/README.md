# ADD Workflow Lifecycle Scripts (scaffold)

> **Status: scaffold only (v0.9.7).** This directory is intentionally inert — it
> documents the planned native-Workflow home and contract. No `.js` script is
> implemented or wired to a skill yet, and nothing here is compiled into
> `plugins/add/`. Full spec: [`specs/workflow-lifecycle-scripts.md`](../../../specs/workflow-lifecycle-scripts.md).

## Why this exists

Claude Code provides native **Dynamic Workflows** — deterministic JavaScript
orchestration (`parallel()`, `pipeline()`, `phase()`, schema-validated output,
token budgets, worktree isolation, resume). ADD's lifecycle skills currently
narrate a hand-rolled swarm. The direction (see the **A1** reframe) is to
delegate the *orchestration mechanism* to native Workflows and keep ADD's
*methodology* — maturity-aware WIP policy, role briefs, trust-but-verify gates —
as the policy layer on top. These scripts are the mechanism side.

## Planned scripts

| Script | Skill | Phases | Lands |
|--------|-------|--------|-------|
| `tdd-cycle.js` | `/add:tdd-cycle` | RED → GREEN → REFACTOR → VERIFY | v1.1 (pilot) |
| `cycle.js` | `/add:cycle` | spec → plan → implement → review | v1.2 |
| `review.js` | `/add:reviewer` + `/add:verify` | review → adversarial-verify | v1.2 |

## Policy → mechanism mapping (ADD's value-add)

| ADD methodology concept | Native Workflow mechanism |
|-------------------------|---------------------------|
| Maturity WIP limit (poc=1 … ga=5) | `parallel()` concurrency / batch size |
| Role brief (test-writer / implementer / reviewer / verify) | `agent()` prompt + `agentType` |
| Trust-but-verify merge gate | a verify `phase()` gating on structured output |
| Per-maturity token budget | Workflow `budget` |
| Swarm-state coordination | the workflow's journaled state (see swarm-protocol's swarm-state format contract) |

## Fallback contract

A skill MUST NOT hard-depend on Workflows. When the native Workflow runtime is
unavailable, the skill falls back to the existing in-conversation swarm pattern
described in `core/references/swarm-protocol.md`. Workflows are an acceleration,
not a requirement.

## Runtime neutrality

This directory is **Claude-specific** (Workflows are a Claude Code feature). The
Codex runtime expresses the same lifecycle through its native TOML sub-agents
(`runtimes/codex/agents/*.toml` — `test-writer`, `implementer`, `reviewer`,
`verify`, `explorer`). The shared, runtime-neutral layer is the *policy* in
`core/` — not the mechanism in either adapter.

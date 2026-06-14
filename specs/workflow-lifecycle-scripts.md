# Spec: Workflow Lifecycle Scripts (A2)

**Version:** 0.1.0
**Created:** 2026-06-14
**PRD Reference:** docs/v1.0-roadmap.md
**Status:** Draft
**Target Release:** v1.1 (pilot scaffolding in v0.9.7)
**Shipped-In:** —
**Last-Updated:** 2026-06-14
**Milestone:** v1.0-ga (scaffold) / M4 (full)

## 1. Overview

Claude Code now provides native **Dynamic Workflows** — a deterministic JavaScript orchestration runtime (`parallel()`, `pipeline()`, `phase()`, schema-validated structured output, token budgets, worktree isolation, resume/journaling). ADD's lifecycle skills (`/add:tdd-cycle`, `/add:cycle`) currently narrate a hand-rolled swarm. This spec proposes encoding those lifecycles as native Workflow scripts so ADD gets reproducible, resumable, budget-bounded execution for free, while keeping ADD's methodology (maturity-aware WIP policy, role briefs, trust-but-verify gates) as the policy layer on top.

This relationship is the implementation of the **A1** reframe (swarm-protocol as a layer over native Workflows); see that draft for the policy/mechanism split. **A2 is the mechanism side: the actual scripts.**

## 2. Scope of this spec

**v0.9.7 (scaffold only — zero behavior change):** establish `runtimes/claude/workflows/` as the home for Claude-specific Workflow scripts, with a README documenting the intended scripts and the policy→config mapping. No skill is wired to a Workflow yet; nothing is compiled into `plugins/add/`. This is deliberately inert so it can land in the credibility cycle without changing runtime behavior.

**v1.1 (pilot):** implement `tdd-cycle.js` (RED → GREEN → REFACTOR → VERIFY) as the first real Workflow, wired behind `/add:tdd-cycle` with a graceful fallback when Workflows are unavailable.

**v1.2 (full set):** `cycle.js` (spec → plan → implement → review) and `review.js`.

## 3. Planned scripts

| Script | ADD lifecycle | Phases | Notes |
|--------|---------------|--------|-------|
| `tdd-cycle.js` | `/add:tdd-cycle` | RED → GREEN → REFACTOR → VERIFY | Pilot. Per-phase role agents (test-writer, implementer, reviewer, verify). |
| `cycle.js` | `/add:cycle` | spec → plan → implement → review | Maturity WIP limits → `parallel()` concurrency; worktree isolation at beta/ga. |
| `review.js` | `/add:reviewer` + `/add:verify` | review → adversarial-verify | Dimension fan-out + verify-each pattern. |

## 4. Policy → Workflow config mapping (ADD's value-add)

| ADD methodology concept | Native Workflow mechanism |
|-------------------------|---------------------------|
| Maturity WIP limit (poc=1 … ga=5) | `parallel()` concurrency cap / batch size |
| Role brief (test-writer / implementer / reviewer / verify) | `agent()` prompt + `agentType` |
| Trust-but-verify merge gate | a verify `phase()` that gates on structured output |
| Token budget per maturity | Workflow `budget` |
| Swarm-state coordination | the workflow's own journaled state (see A3 format contract) |

## 5. Acceptance criteria (scaffold, v0.9.7)

- **AC-A2-001** `runtimes/claude/workflows/` exists with a `README.md` documenting the planned scripts and the policy→config mapping above.
- **AC-A2-002** No script is referenced by any skill or compiled into `plugins/add/` yet — `compile --check` and all guardrail suites remain green with zero behavior change.
- **AC-A2-003** The README names the fallback contract: when native Workflows are unavailable, the corresponding skill falls back to the existing in-conversation swarm pattern (no hard dependency).

## 6. Out of scope

- Implementing any `.js` Workflow (v1.1+).
- Wiring skills to Workflows (v1.1+).
- The Codex equivalent — Codex uses its TOML sub-agents (the `verify` agent landed in v0.9.6); a parallel spec covers Codex orchestration.

## 7. Open questions

- **Q-A2-1** Where do compiled Workflow scripts live in `plugins/add/` once wired — a `workflows/` dir the marketplace install ships? (Decide at v1.1, with `compile.py` support + a compile-drift-aware test.)
- **Q-A2-2** How is a Workflow invoked from a skill — does the skill emit a Workflow invocation, or does the runtime auto-detect? (Depends on the Workflow invocation API at v1.1.)

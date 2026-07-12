---
autoload: false
maturity: beta
description: "Architect vs Editor model-role guidance — match agent capability to task shape across `/add:cycle`, `/add:spec`, `/add:plan` and downstream sub-agent dispatches. Orchestration-only; loaded on demand by dispatching skills."
---

# ADD Rule: Architect vs Editor Model Roles

ADD's methodology splits agentic work into two role shapes: the **Architect** — planning, spec authoring, decision walkthroughs, parallelism analysis, retro synthesis — which benefits from a larger reasoning model (Opus / equivalent), e.g. drafting a new milestone doc that weighs D1–D7 trade-offs against six-release sequencing; and the **Editor** — mechanical edits, file rewrites, frontmatter sweeps, formatting, table reflows, generated-output regen — which is Sonnet/Haiku-shaped, e.g. flipping `Status: Draft` to `Status: Complete (v0.9.5)` across nine specs in parallel. This is **guidance, not enforcement**: ADD does not prescribe a model per skill, and any model can perform either role. But when a user dispatches `/add:cycle`, `/add:spec`, `/add:plan`, or a swarm of editor-style sub-agents, picking the role-appropriate model materially affects cost, latency, and output quality — and the swarm-orchestration pattern in `rules/agent-coordination.md` is most effective when an Architect orchestrator delegates Editor-shaped work to parallel Editor-tier sub-agents rather than running every dispatch on the largest available model.

## Capability tiers (current lineup)

Match the tier to the role shape, not a fixed model name — the lineup moves, the role shapes don't:

| Tier | Role shape | Claude | Codex |
|------|-----------|--------|-------|
| **Architect / reasoning** | Planning, spec authoring, decision walkthroughs, parallelism analysis, retro synthesis, orchestration | Opus 4.8 | gpt-5.5 |
| **Editor / execution** | Mechanical edits, file rewrites, frontmatter sweeps, generated-output regen, the bulk of parallel sub-agent work | Sonnet 4.6 | gpt-5.x-codex |
| **Fast / extraction** | High-volume classification, routing, short extractions where latency and cost dominate | Haiku 4.5 | gpt-5.x-codex-mini |

A capable Editor-tier model (Sonnet 4.6 / gpt-5.x-codex) handles most ADD sub-agent dispatches well; reserve the Architect tier for the orchestrator and genuinely reasoning-heavy work. Always prefer the latest model in each tier rather than pinning a version.

## Role → tier defaults

When a dispatching skill (`/add:cycle`, `/add:tdd-cycle`) fills in the MODEL field of a sub-agent brief, use these defaults — aligned with the Resource Budgets policy in `${CLAUDE_PLUGIN_ROOT}/references/swarm-protocol.md`:

| Role | Default tier |
|------|--------------|
| test-writer | editor |
| implementer | editor |
| reviewer | architect |
| verify | editor |
| explorer | fast |
| mechanical generation (dashboards, SVG, docs rendering) | fast |

## Token-budget escalation

Start mechanical roles on the cheaper tier and escalate only on evidence: if a fast- or editor-tier dispatch fails verification (tests still failing, gate rejected, output malformed), re-dispatch that item on the architect tier rather than starting everything there. The cheap attempt plus one escalation almost always costs less than defaulting every dispatch to the largest model — and the failure output makes the escalated dispatch better-targeted. As with the rest of this rule, this is guidance, not enforcement: ADD supplies the policy; the runtime's model overrides and per-step budgets are the mechanism.

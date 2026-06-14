# Draft D4 — Lead the README with the maturity ladder

> **STATUS: DRAFT for maintainer review (v0.9.7 positioning).** Nothing is
> applied. This proposes a restructure of `README.md`'s hero/top section.
> Existing ADD voice preserved; copy is illustrative and to be steered.

---

## The decision in one sentence

Make the **poc → alpha → beta → ga maturity ladder** the README's hero
differentiator, because it is the one moat host runtimes have **not** absorbed
and it maps directly to the 2026 "trust-gradient" theme the Anthropic Agentic
Coding Trends Report names as THE problem of the year (per
`docs/v1.0-roadmap.md` Part 6 moat #1, Insight 3, and the closing line).

Today the README leads with "AI agents write code fast / without structure they
ship chaos" and a six-principles list. The maturity dial — the actual moat — is
buried ~225 lines down under "The Maturity Dial." Move it up.

---

## Why the maturity ladder, specifically

From the roadmap synthesis:

- **It's the only durable moat.** Hooks, skill orchestration, AGENTS.md gen,
  sub-agent dispatch, swarm worktrees, multi-runtime adapters — all being
  absorbed by host runtimes or replicated by competitors (Insight 3 / Risk E1).
- **It's unique to ADD AND maps to the named 2026 problem** (trust gradient).
  No competitor (Spec Kit, BMAD, OpenSpec, Cursor/Cline skills) ships a maturity
  cascade that governs *all* process rigor from one dial.
- **It's already proven in the product** via `core/rules/maturity-lifecycle.md`
  (the "single most important rule," precedence over all others) and surfaced by
  `/add:promote --check`.

---

## CURRENT hero (README.md lines 1–39)

```
<h1 align="center">ADD — Agent Driven Development</h1>

<p align="center">
  <strong>AI agents write code fast. Without structure, they ship chaos.</strong>
  ...
  ADD is a methodology for AI-native software development — spec-driven,
  test-first, independently verified, human-validated — implemented as a
  Claude Code plugin (with a Codex CLI adapter) that coordinates specialized
  agent swarms.
</p>

## The Problem
AI code generation has changed how software gets built, but development
practices haven't kept up. ...

## What is Agent Driven Development?
TDD gave us tests before code. BDD gave us behavior before tests. ADD gives us
coordinated agent teams before everything.
... [six principles list] ...
```

**Problem with current:** the hero promise is "structure / coordinated agent
teams" — the exact framing that competitors and host runtimes can now also
claim. The unique, defensible idea (one dial that scales rigor with trust) is
invisible above the fold.

---

## PROPOSED hero (restructured)

```
<h1 align="center">ADD — Agent Driven Development</h1>

<p align="center">
  <strong>One dial scales the rigor. Trust your agents as much as your
  project has earned.</strong>
  <br>
  ADD is a methodology for AI-native software development built around a single
  control: the <strong>maturity ladder</strong> (poc → alpha → beta → ga). The
  ladder governs everything — how deep your specs go, whether TDD is enforced,
  how many agents run in parallel, which quality gates block. A throwaway
  prototype gets near-zero ceremony; production infrastructure gets exhaustive
  verification. You turn one dial; ADD cascades the rest.
  <br><br>
  Spec-driven, test-first, independently verified, human-validated — implemented
  as a Claude Code plugin (with a Codex CLI adapter).
  <br>
  ... [badges unchanged] ...
</p>

---

## The Maturity Ladder — one dial for the trust gradient

Autonomous agents need a trust gradient: how much you let them do should scale
with how much your project has earned. ADD makes that gradient the master
control. Every project declares a maturity level, and that level cascades to
**every** process decision — there are no per-rule debates, just one dial.

| Stage | What it means | What ADD does |
|-------|---------------|---------------|
| **POC**   | Validate an idea. Learning > completeness.       | Paragraph PRD. Optional specs/TDD. Pre-commit gate only. 1 agent, serial. |
| **Alpha** | Building toward MVP. Surviving first real usage. | 1-page PRD. Critical-path specs + TDD. Adds CI gate. Up to 2 agents. |
| **Beta**  | Broader audience. Stabilize, reduce defects.     | Full PRD. All specs required, strict TDD. Adds pre-deploy gate. 2–4 agents. |
| **GA**    | Production-grade, long-term support.             | Full PRD + architecture. Exhaustive ACs. All 5 gates blocking. 3–5 agents via worktrees. |

Promotion is **deliberate, not automatic** — `/add:promote --check` runs an
evidence-based gap analysis (specs, coverage, CI, branch protection, stability
window) and tells you exactly what's missing before you level up. You don't
graduate to GA by wishing; you graduate when the evidence says you're ready.

> This is the trust-gradient problem the 2026 Agentic Coding Trends Report names
> as the central challenge of agentic development — and ADD shipped an
> implementation of it in 2025.

---

## What is Agent Driven Development?
TDD gave us tests before code. BDD gave us behavior before tests. ADD gives us
**maturity-governed agent teams** — process rigor that scales with the trust
your project has earned.
... [six principles list — unchanged, but reordered so the maturity/cascade
    principle is #1; see below] ...
```

---

## Supporting changes (below the new hero)

1. **Demote, don't delete, the standalone "The Maturity Dial" section**
   (current lines 224–235). The hero now carries the headline; the deeper
   section becomes "How the cascade works in practice" with the fuller
   per-dimension detail (PRD depth, TDD, gates, parallel agents) pulled from
   `core/rules/maturity-lifecycle.md`'s cascade matrix. Avoid duplicating the
   table verbatim in two places — hero gets the 4-row summary, the lower
   section gets the full cascade.

2. **Reorder the six principles** so the maturity dial leads. CURRENT order
   starts with "Specs before code." PROPOSED: add/lead with **"Maturity governs
   everything — one dial scales all process rigor (poc → ga)"** as principle #1,
   keeping the existing five beneath it. (Or reframe principle #4 "Structured
   collaboration" — maintainer's call on whether to grow the list to seven or
   re-weight the existing six.)

3. **`/add:promote --check` surfacing.** The skill already prints a readiness %
   + cascade-changes table (`core/skills/promote/SKILL.md` Step 4). The hero's
   "you graduate when the evidence says you're ready" line should point readers
   at `/add:promote --check`. Optionally add a small rendered example of the
   readiness report under the lower cascade section so the moat is *shown*, not
   just told. (Roadmap Part 6 #1: "make the maturity cascade visible to users
   via `/add:promote --check` and a rendered cascade diagram.")

4. **Tagline candidates** (maintainer picks voice):
   - "One dial scales the rigor." *(recommended — concrete, ADD-voiced)*
   - "Trust your agents as much as your project has earned."
   - "The trust gradient, implemented."
   - Keep "AI agents write code fast. Without structure, they ship chaos." as a
     secondary line under the new lead if the maintainer wants to retain the
     problem framing.

---

## Voice check

ADD's README voice is: short declaratives, em-dashes, "no X / no Y" cadence
("No fake dates — no sprints"), and concrete-over-abstract. The proposed copy
keeps that:
- "You turn one dial; ADD cascades the rest."
- "A throwaway prototype gets near-zero ceremony; production infrastructure gets
  exhaustive verification."
- "You don't graduate to GA by wishing; you graduate when the evidence says
  you're ready."

No new jargon introduced except "trust gradient," which is deliberately tied to
the cited 2026 report and is the positioning hook.

---

## Cross-surface ripple (flag only — not in scope for this draft)

If this lands, keep the documentation surfaces in sync (per CLAUDE.md /
MEMORY.md "Documentation Surfaces"):
- `reports/add-overview.html` hero
- `docs/infographic.svg` lead panel
- `MountainUnicorn/getadd.dev:index.html` hero (separate repo)

These are downstream; the README is the source edit this draft proposes.

---

## Open questions for the maintainer

1. **Tagline:** which lead line (see candidates)? Retain the "chaos" line as
   secondary or retire it?
2. **Six vs seven principles:** add maturity as a 7th, or re-weight to lead with
   it?
3. **Show the readiness report?** Include a rendered `/add:promote --check`
   example in the README, or just link the command?
4. **Table depth in hero:** 4-row summary (proposed) vs a compact 4-column
   one-liner to keep the hero tighter?

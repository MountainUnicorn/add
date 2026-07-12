# Draft A1 — Reframe swarm-protocol as a policy layer over native Workflows

> **STATUS: APPLIED in v0.9.7 — retained for history only.** The proposed
> language landed (nearly verbatim) in `core/references/swarm-protocol.md` and
> `core/rules/agent-coordination.md`; v0.9.9 extended it with Resource Budgets
> and MODEL/BUDGET brief fields. Do not edit this draft; edit the live files. It proposes changes to `core/references/swarm-protocol.md`
> and `core/rules/agent-coordination.md`. Voice/scope to be steered before any
> edit lands.

---

## The decision in one sentence

ADD should stop *re-implementing* parallel sub-agent orchestration by hand and
instead **delegate the orchestration mechanism to native runtime primitives**
(Claude Code Dynamic Workflows; Codex TOML subagents), keeping only what is
uniquely ADD: **maturity-aware concurrency/WIP policy, role briefs, trust-but-verify
merge gates, and swarm-state coordination.**

Positioning shift: from *"ADD coordinates agent swarms"* to **"ADD is the
methodology/policy layer that configures native orchestration."** Mechanism is
borrowed; policy is the moat.

---

## Why now

- Claude Code now ships **Dynamic Workflows**: deterministic JS orchestration
  (`parallel()`, `pipeline()`), schema-validated step output, per-step budgets,
  and worktree isolation as a first-class primitive.
- Today `swarm-protocol.md` hand-describes worktree setup, merge sequencing, and
  parallel dispatch in prose. That prose now duplicates a mechanism the host
  does deterministically and observably — the exact "stop competing where hosts
  do better" call from `docs/v1.0-roadmap.md` Part 5 / Risk E1 / E8.
- The roadmap (Part 4) already lists "swarm worktree pattern + a NEW live status
  surface" as **IN ADD**. This draft refines that: the *pattern's policy* stays
  in ADD; the *worktree/dispatch mechanics* delegate to Workflows.

---

## The policy vs mechanism split

| Concern | Owner after reframe | Why |
|---|---|---|
| Max parallel agents per maturity (poc=1…ga=5) | **ADD policy** | Trust-gradient moat. Becomes Workflow `concurrency` config. |
| Conflict assessment (independent/low/high) | **ADD policy** | Methodology judgement; decides serialize vs parallelize. |
| Role briefs (test-writer/implementer/reviewer/verify) | **ADD policy** | Methodological scaffolding; maps to Workflow step definitions. |
| Trust-but-verify merge gates | **ADD policy** | Load-bearing trust mechanism; runs *after* the Workflow returns. |
| Swarm-state coordination (`.add/swarm-state.md`) | **ADD policy** | Cross-cutting working state; survives across Workflow runs and runtimes. |
| Worktree creation/teardown | **MECHANISM (delegate)** | Native Workflows do isolation deterministically. |
| Parallel dispatch / fan-out | **MECHANISM (delegate)** | `parallel()` replaces hand-rolled dispatch loop. |
| Step output schema validation | **MECHANISM (delegate)** | Native schema-validated output replaces "Sub-Agent Output Format" prose. |
| Per-agent budgets / timeouts | **MECHANISM (delegate)** | Workflow budgets replace "scope >2x estimate" heuristic enforcement. |
| Merge-conflict resolution loop | **MECHANISM + policy** | Workflow surfaces conflict; ADD policy decides merge order. |

**Litmus test for future edits:** if a paragraph describes *how to run agents in
parallel*, it is mechanism — push it to the adapter. If it describes *whether,
how many, in what order, and whether to trust the result*, it is policy — keep
it.

---

## Runtime-neutrality contract (non-negotiable)

ADD emits a **runtime-neutral swarm policy**; each adapter compiles it down:

```
ADD swarm policy (core/)              →  Claude adapter        →  Codex adapter
─────────────────────────────────────────────────────────────────────────────
concurrency = WIP-limit(maturity)     →  Workflow concurrency  →  TOML subagent pool size
conflict matrix → independent set     →  parallel() group      →  parallel subagent invocations
role brief (test-writer, …)           →  Workflow step + schema →  subagent prompt + role
verify gate                           →  post-Workflow step     →  post-run orchestrator check
swarm-state.md                        →  read/write file        →  read/write file (shared)
```

The policy file in `core/` must **name no runtime API**. Claude `parallel()`/
`pipeline()` and Codex TOML subagents are mentioned only in the adapter sections
of `runtimes/claude/` and `runtimes/codex/`, or behind an explicit
"per-runtime mechanism" callout. This keeps `core/` host-neutral (consistent
with the F-006 kernel direction, even though F-006 itself is deferred to v1.1).

---

## Detection & fallback

ADD must degrade cleanly when Workflows are unavailable (older Claude Code, Codex,
or a runtime with no orchestration primitive):

1. **Detect:** adapter advertises a `workflows` capability flag (Claude: Dynamic
   Workflows present; Codex: TOML subagents present; otherwise none).
2. **If present:** ADD generates the Workflow descriptor from its policy and hands
   off. ADD does NOT re-describe dispatch mechanics inline.
3. **If absent:** fall back to the **current** hand-orchestrated prose (the legacy
   sections below, retained as a "Manual fallback" appendix). The maturity WIP
   limits and trust-but-verify gates apply identically in both paths.

The WIP semantics (poc=1 … ga=5) are **invariant across both paths** — they are
policy, not mechanism, so they never change regardless of whether a native
Workflow runs.

---

## Concrete rewrite of `core/references/swarm-protocol.md`

### Section: header / intro

**CURRENT**
```
# Swarm Coordination Protocol Reference

> Full reference for parallel multi-agent work. Loaded by `/add:cycle` when
> dispatching parallel agents. Core agent coordination rules are in
> `rules/agent-coordination.md`.
```

**PROPOSED**
```
# Swarm Coordination Protocol Reference

> ADD's **policy layer** for parallel multi-agent work. ADD owns the policy
> (concurrency, conflict assessment, role briefs, merge gates, swarm-state);
> the runtime owns the mechanism (parallel dispatch, worktree isolation, step
> schemas, budgets). Loaded by `/add:cycle` when dispatching parallel agents.
>
> - **Claude Code:** ADD compiles this policy into a native Dynamic Workflow
>   (`parallel()`/`pipeline()`, schema-validated output, per-step budgets,
>   worktree isolation).
> - **Codex CLI:** ADD compiles into TOML subagent invocations.
> - **No native orchestration:** fall back to the Manual Orchestration appendix
>   (§ Manual fallback). Policy is identical in all three paths.
>
> Core agent coordination rules are in `rules/agent-coordination.md`.
```

### Section: Conflict Assessment — KEEP (policy), add framing line

**PROPOSED — prepend one line; body unchanged**
```
> POLICY (ADD-owned). The conflict matrix decides what may run concurrently;
> the runtime decides how. The "independent" set becomes a parallel group;
> "high conflict" pairs are serialized regardless of available concurrency.
```

### Section: Git Worktree Strategy — REFRAME from mechanism to delegation

**CURRENT** (lines 19–39) hand-writes `git worktree add …`, agent→worktree
mapping, and a manual merge sequence.

**PROPOSED**
```
## Worktree Isolation (delegated to the runtime)

> MECHANISM (runtime-owned). ADD declares *that* parallel agents must be
> isolated at beta/ga maturity; the runtime provides the isolation.

- **Claude Code:** Dynamic Workflows create per-step worktrees automatically.
  ADD sets isolation=worktree on the parallel group; it does not run
  `git worktree add` by hand.
- **Codex CLI:** the adapter provisions a worktree per subagent.
- **Manual fallback (no Workflows):** see § Manual Orchestration for the
  explicit `git worktree add` recipe (retained verbatim from prior versions).

ADD's only worktree *policy* is: beta/ga ⇒ isolation REQUIRED; alpha ⇒ file
reservations acceptable; poc ⇒ serial, no isolation needed.
```

### Section: File Reservation Strategy — KEEP (policy for alpha / fallback)

Unchanged. It is the documented alpha-maturity policy and the manual-fallback
isolation strategy. Add a one-line pointer that reservations are how ADD
expresses isolation when worktrees are overkill or unavailable.

### Section: WIP Limits — KEEP verbatim, re-label as the config source

**PROPOSED — prepend**
```
> POLICY (ADD-owned) — the single most important swarm input. These limits
> compile directly into runtime concurrency config:
>   Claude:  Workflow parallel-group concurrency = Max Parallel Agents
>   Codex:   subagent pool size = Max Parallel Agents
> The table is invariant across native and manual paths.
```
Table (poc=1, alpha=2, beta=4, ga=5) is unchanged.

### Section: Sub-Agent Brief Template — KEEP (policy), note it compiles to a step

**PROPOSED — prepend**
```
> POLICY (ADD-owned). Each brief compiles to one Workflow step (Claude) or one
> subagent invocation (Codex). FILE RESERVATIONS, QUALITY GATES, and
> VALIDATION CRITERIA are ADD's; REPORT BACK maps onto the runtime's
> schema-validated step output (so ADD no longer hand-parses free-text).
```
Template body unchanged.

### Section: Merge Coordination — KEEP (policy), clarify mechanism boundary

**PROPOSED — prepend**
```
> POLICY (ADD-owned) for ordering + trust; MECHANISM (runtime) surfaces the
> conflicts. The runtime reports which steps touched which files; ADD decides
> merge order (infrastructure first) and runs integration tests after each
> merge. Trust-but-verify is never delegated.
```
Steps 1–5 unchanged.

### Section: Swarm State Coordination — KEEP verbatim

This is cross-run, cross-runtime working state. It is pure ADD policy and must
not be delegated (a Workflow's internal state does not persist between cycles or
across runtimes). Add one line: "Swarm-state is runtime-agnostic and survives
across Workflow runs; the runtime's own step state does not replace it."

### Section: Sub-Agent Output Format (in agent-coordination.md) — SOFTEN

Where a native runtime provides schema-validated step output, ADD consumes that
schema instead of parsing free text. The STATUS/FILES_CHANGED/TEST_RESULTS/
SPEC_COMPLIANCE fields become the **schema ADD requests**, not a prose contract
the sub-agent is trusted to follow.

### Section: Anti-Patterns — KEEP, add two

**PROPOSED — append**
```
- **Never** re-implement parallel dispatch or worktree setup inline when the
  runtime provides Workflows — delegate the mechanism, keep the policy.
- **Never** let delegation skip trust-but-verify. A Workflow returning
  "success" is necessary but not sufficient; the orchestrator still verifies.
```

---

## Concrete rewrite of `core/rules/agent-coordination.md`

### Section: Parallel Execution (lines 60–61)

**CURRENT**
```
When tasks are independent, dispatch in parallel. After all complete, the
orchestrator runs the full test suite to verify agents' work coexists without
conflicts.
```

**PROPOSED**
```
When tasks are independent, ADD expresses them as a parallel group and lets the
runtime dispatch them (Claude Dynamic Workflows / Codex subagents; manual
fallback if neither is present). Concurrency is capped by the maturity WIP
limit. After the runtime returns, the orchestrator independently runs the full
test suite to verify the agents' work coexists — delegation never replaces
trust-but-verify.
```

### Section: Swarm Coordination (lines 83–92)

**PROPOSED — replace the bullet list intro**
```
For parallel multi-agent work, ADD owns the *policy* and delegates the
*mechanism* to the runtime. See the full policy at
`${CLAUDE_PLUGIN_ROOT}/references/swarm-protocol.md`. Key points:

- Concurrency = maturity WIP limit (poc=1, alpha=2, beta=4, ga=5) — compiles
  to Workflow concurrency (Claude) or subagent pool size (Codex).
- Assess file conflict risk before declaring the parallel group.
- Isolation (worktrees) is delegated to the runtime at beta/ga; file
  reservations are the alpha/fallback policy.
- Run integration tests after each merge; trust-but-verify is never delegated.
- Write micro-retro to `.add/observations.md` after the run completes.
```

The Cache-Aware Dispatch Layout section stays — but note that when a runtime
emits Workflow steps, the STABLE/VOLATILE prefix discipline maps onto the
Workflow's shared-context vs per-step inputs (a follow-up detail, not a v0.9.7
blocker).

---

## Market-positioning flags (every place this changes the story)

1. **README "Coordinated Agent Teams" + "Multi-Agent Coordination" sections**
   currently imply ADD *is* the orchestrator. After this reframe the honest
   line is **"ADD configures native orchestration with maturity-aware policy."**
   Flag for a matching README edit (could pair with Draft D4).
2. **`docs/infographic.svg` / `reports/add-overview.html`** show the
   orchestrator-dispatches-sub-agents diagram. The diagram stays valid as a
   *policy* picture but should gain a "runs on native Workflows / TOML subagents"
   caption so it doesn't claim ADD owns the mechanism.
3. **getadd.dev** (separate repo) — any "coordinates agent swarms" hero copy
   should shift to "methodology layer on top of native orchestration." Lives in
   `MountainUnicorn/getadd.dev`, not this repo.
4. **v1.0 narrative** — this directly supports roadmap Part 6 moat #2
   ("methodology, not the tool") and the E1/E8 mitigations ("be useful WITHIN
   those runtimes; methodology layer on top, never below").
5. **CHANGELOG** — frame as "swarm-protocol reframed: policy stays in ADD,
   orchestration mechanism delegated to native Workflows / TOML subagents
   (runtime-neutral, with manual fallback)." Mechanism-only; no behavior change
   to WIP semantics.

---

## What must NOT change (guardrails for the maintainer)

- Maturity WIP semantics: **poc=1, alpha=2, beta=4, ga=5** — invariant.
- Trust-but-verify merge gates remain ADD-owned and mandatory.
- `core/` stays runtime-neutral — no Claude/Codex API names in policy text.
- Manual orchestration recipe retained as a fallback appendix, not deleted —
  zero-dependency / no-Workflows runtimes still work.

---

## Open questions for the maintainer

1. **Appendix vs deletion:** keep the full manual worktree/merge prose as a
   "Manual Orchestration" appendix (recommended — preserves zero-dependency
   fallback), or trim it to a pointer once Workflows are the default?
2. **Capability flag location:** does the `workflows` detection flag live in the
   adapter YAML (`runtimes/*/adapter.yaml`) or get probed at runtime?
3. **Scope for v0.9.7:** land the *documentation/positioning* reframe now, and
   defer the actual Workflow-descriptor *emission* to when `/add:cycle` is
   refactored (likely M4 / `/add:parallel`)? Recommended: yes — reframe the docs
   in v0.9.7, emit descriptors later.

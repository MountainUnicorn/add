---
autoload: true
maturity: alpha
---

# ADD Rule: Compliance — Retro Cadence & SDLC Watchdog

ADD's checkpoint machinery (retros, learning migrations, handoffs) is only valuable if it runs. At sprint pace this rule is what prevents the machinery from being silently skipped.

This rule has two enforcement modes:

- **BLOCK** — halt the triggering command, surface the gap, require resolution or explicit override
- **FLAG** — report the gap in standard output, don't halt

## Retro Cadence Enforcement

Run the following check at the start of every `/add:away`, `/add:cycle --plan`, and `/add:back`:

### Compute Retro Debt

1. **Last retro date** — newest file in `.add/retros/retro-*.md`. If none exists, use project creation date from `.add/config.json`.
2. **Away sessions since last retro** — count files in `.add/away-logs/` with dates after the last retro.
3. **New learnings since last retro** — count entries in `.add/learnings.json` (or `.add/learnings.md` if still pre-migration) where `date` is after the last retro.
4. **Days since last retro** — today minus last retro date.

### Block Thresholds

Retro debt is exceeded when ANY of:

- Days since last retro > **7**
- Away sessions since last retro > **3**
- New learnings since last retro > **15**

### When Exceeded

BLOCK the triggering command with a message like:

```
Retro debt detected — {metric} exceeded threshold.

  Days since last retro: {N} (limit: 7)
  Away sessions since last retro: {N} (limit: 3)
  New learnings since last retro: {N} (limit: 15)

Run /add:retro before continuing, or use --force-no-retro to override
(the override will be logged to .add/learnings.json as a compliance-bypass entry).
```

### Override Semantics

If the user provides `--force-no-retro`, record the bypass in `.add/learnings.json`:

```json
{
  "id": "L-{NNN}",
  "title": "Retro cadence override",
  "body": "User bypassed retro cadence block during {command}. Debt at bypass: {days}d / {sessions} aways / {learnings} entries.",
  "scope": "project",
  "category": "process",
  "severity": "medium",
  "date": "{today}",
  "classified_by": "agent",
  "checkpoint_type": "compliance-bypass"
}
```

### Abuse Detection

The `--force-no-retro` override is for rare exceptions. Repeated use indicates a process breakdown that the retro is supposed to surface. Before accepting the override, count prior overrides:

1. Read `.add/learnings.json` and count entries where `checkpoint_type == "compliance-bypass"` AND `date` is within the last 30 calendar days.
2. Apply the threshold ladder:

| Override count (last 30d) | Behavior |
|---|---|
| 0 | Accept silently, record the bypass, proceed |
| 1 | Accept but WARN: "This is your 2nd retro bypass in 30 days. The cadence rule exists because skipped retros compound — consider running `/add:retro` now." |
| 2 | Accept but escalate: "⚠ 3rd retro bypass in 30 days. This pattern means the retro cadence rule is failing to serve you. Either (a) run `/add:retro` before continuing, or (b) if the rule itself is wrong for this project, open an issue to adjust the thresholds. Proceed? Re-run with `--force-no-retro --i-know-this-is-a-pattern` to acknowledge." |
| 3+ | REFUSE: "🛑 4th retro bypass in 30 days. ADD refuses to stack further overrides without a retro. Run `/add:retro` first. If thresholds don't fit this project, override the rule locally via `.claude/rules/add-compliance.md` — compounding bypasses without action isn't supported." |

The escalation ladder is deliberately density-based, not time-since-last-bypass. A project that hits the cap and then runs a retro resets the count at the next retro's date (since the count is over the last 30 days and a retro is part of the baseline behavior the rule expects).

The count is also surfaced in `/add:retro` Phase 7 scope review so the human sees the pattern during the retro itself — closing the loop between bypass accumulation and synthesis.

## SDLC Watchdog

At the start of every implementation-advancing command (`/add:tdd-cycle`, `/add:implementer`, `/add:deploy`), verify the SDLC chain:

### Chain Check

For the feature being worked on:

| Artifact | Location | Required At Maturity |
|---|---|---|
| PRD | `docs/prd.md` | alpha+ |
| Spec | `specs/{feature}.md` | alpha+ |
| Plan | `docs/plans/{feature}-plan.md` | beta+ |
| UX artifact | `specs/ux/{feature-slug}-ux.md` with `Status: APPROVED` | alpha+ (UI features only) |
| Failing test (pre-implementation) | test file referencing this feature's AC | beta+ |

If a required artifact is missing, FLAG in output. If the triggering command is `/add:implementer` or `/add:deploy` and the spec is missing, BLOCK.

### Handoff Freshness

After any commit burst (3+ commits since last handoff write), FLAG: "Handoff is stale — recommend writing `.add/handoff.md` before continuing."

No block — handoff is advisory.

## Learning Format Migration

If `.add/learnings.md` exists but `.add/learnings.json` does not, AND `config.json` version is >= 0.4.0:

FLAG on first load: "Project has legacy markdown learnings but no JSON. Migrate via `/add:init --migrate-learnings` to enable filtering and cross-project promotion."

Do not block — legacy projects should continue to work. But surface once per session.

## Micro-Retro Enforcement

After multi-agent operations (2+ parallel sub-agents complete and merge), require the orchestrator to write a micro-retro entry to `.add/observations.md` before advancing. This codifies the "should" in `agent-coordination.md` into a "MUST" at alpha+ maturity.

If the orchestrator returns from a multi-agent dispatch without writing an `[agent-retro]` tagged entry, BLOCK the next dispatch until one exists.

## Summary Table

| Check | When | Mode | Override |
|---|---|---|---|
| Retro debt | `/add:away`, `/add:cycle --plan`, `/add:back` start | BLOCK | `--force-no-retro` |
| Missing spec | `/add:implementer`, `/add:deploy` | BLOCK | None (write spec first) |
| Missing plan | `/add:tdd-cycle` at beta+ | FLAG | — |
| Missing UX artifact | `/add:cycle --plan` at alpha+ with UI features | BLOCK (per ux skill) | — |
| Missing pre-implementation test | `/add:implementer` at beta+ | FLAG | — |
| Stale handoff | After 3+ commits | FLAG | — |
| Legacy learnings format | First session load | FLAG (once) | Run migration |
| Missing micro-retro | After parallel dispatch | BLOCK next dispatch | Write micro-retro |

## Why This Exists

Evidence from the agentVoice dog-food project (40 days, 412 commits, 30 specs, 0 retros pre-04-12):

> *"SDLC discipline collapsed under multi-swarm parallelism."* — 2026-04-12 retro

ADD's continuous-improvement loop depends on retros running. Without enforcement, the fastest-moving projects skip the loop, lose cross-project learning, and leave cycle/milestone registries stale. This rule is the enforcement layer the checkpoint machinery always needed.

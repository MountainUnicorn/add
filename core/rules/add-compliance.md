---
autoload: true
maturity: alpha
---

# ADD Rule: Compliance — Retro Cadence & SDLC Watchdog

Enforcement modes: **BLOCK** (halt command, require resolution) or **FLAG** (report, don't halt).

## Retro Cadence Enforcement

Check at start of `/add:away`, `/add:cycle --plan`, `/add:back`:

**Block thresholds** (ANY triggers block):
- Days since last retro > **7**
- Away sessions since last retro > **3**
- New learnings since last retro > **15**

**Override:** `--force-no-retro` records a compliance-bypass entry in `.add/learnings.json`.

**Abuse detection:** Count compliance-bypass entries in last 30 days:
- 0: accept silently
- 1: warn ("2nd bypass in 30 days")
- 2: escalate (require `--i-know-this-is-a-pattern`)
- 3+: refuse (must run `/add:retro` first)

## SDLC Watchdog

Check at start of `/add:tdd-cycle`, `/add:implementer`, `/add:deploy`:

| Artifact | Required At | Missing = |
|---|---|---|
| PRD (`docs/prd.md`) | alpha+ | FLAG |
| Spec (`specs/{feature}.md`) | alpha+ | BLOCK for implementer/deploy |
| Plan (`docs/plans/{feature}-plan.md`) | beta+ | FLAG |
| UX artifact (approved) | alpha+ (UI features) | BLOCK |
| Failing test (pre-implementation) | beta+ | FLAG |

## Other Checks

- **Stale handoff:** FLAG after 3+ commits since last `.add/handoff.md` write
- **Legacy learnings:** FLAG once per session if `.add/learnings.md` exists without `.json`
- **Missing micro-retro:** BLOCK next multi-agent dispatch if orchestrator didn't write `[agent-retro]` observation after parallel work

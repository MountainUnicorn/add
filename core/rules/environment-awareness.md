---
autoload: true
maturity: beta
---

# ADD Rule: Environment Awareness

Every project has an environment strategy in `.add/config.json`. All skills must respect it.

## Environment Tiers

| Tier | Environments | Typical Use |
|------|-------------|-------------|
| **1** | local only | Prototypes, SPAs, CLI tools, libraries |
| **2** | local → production | Solo projects, startups, side projects |
| **3** | local → dev → staging → production | Teams, enterprise, regulated industries |

## Test-Per-Environment Matrix

| Test Type | Local | Dev/CI | Staging | Production |
|-----------|-------|--------|---------|------------|
| Unit | Yes | Yes | No | No |
| Integration | Yes | Yes | Yes | No |
| E2E | Optional | Optional | Yes | No |
| Smoke | No | No | Optional | Yes |
| Performance | No | No | Yes | No |

## Deployment Rules

- **Local:** Agents deploy freely
- **Dev/Staging:** Autonomous if `autoPromote: true` in config
- **Production:** ALWAYS requires human approval, no exceptions
- Post-deploy verification mandatory at every tier

## Promotion Ladder

```
local (verify) → dev (verify) → staging (verify) → production (HUMAN REQUIRED)
```

1. Verification must pass before promoting to next level
2. If verification fails: **auto-rollback** to last known good, stop the ladder
3. Production never auto-promotes — stops at staging and queues for human
4. Controlled by `autoPromote`, `verifyCommand`, and `rollbackStrategy` per environment in config

### Automatic Rollback

On failure: identify last good deployment → redeploy previous version → verify rollback → log everything → stop ladder → queue for human review.

## Away Mode Behavior

- Follow promotion ladder autonomously up to `autoPromote` ceiling
- Production is NEVER autonomous, even during extended away sessions
- On failure: rollback, log, move to next task — do not retry

## Active Collaboration

- Agent proposes deployments, human approves
- Production is always a Review Gate (summary + explicit approval)
- Human can override `autoPromote` at any time

## Secrets

- Never hardcode environment-specific values
- `.env` locally (never committed), secret managers in cloud
- `.env.example` documents required variables
- Agents may READ .env but never LOG or EXPOSE values

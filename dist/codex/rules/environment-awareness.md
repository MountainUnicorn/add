---
autoload: true
maturity: beta
---

# ADD Rule: Environment Awareness

Every project has an environment strategy defined during `/add:init`. All skills and commands must respect it.

## Environment Tiers

The project's tier is set in `.add/config.json`. Three tiers exist:

### Tier 1 — Local Only

Single environment. Typical for prototypes, SPAs, CLI tools, libraries.

```
local → done
```

- All tests run locally
- No deployment pipeline
- Quality gates: lint + type check + tests before commit
- E2E tests (if any) run against local dev server

### Tier 2 — Local + Production

Two environments. Typical for solo projects, startups, side projects.

```
local → main → production
```

- Unit and integration tests run locally and in CI
- E2E tests run locally against containers (or dev server)
- Push to main triggers CI → deploy pipeline
- Post-deploy smoke tests verify production
- Quality gates: pre-commit (lint, types) → CI (tests, coverage) → post-deploy (smoke)

### Tier 3 — Full Pipeline

Four environments. Typical for teams, enterprise, regulated industries.

```
local → dev → staging → production
```

- Unit tests: local + CI (all branches)
- Integration tests: dev environment
- E2E tests: staging environment (full infrastructure)
- Performance tests: staging
- User acceptance testing: staging
- Production: smoke tests + synthetic monitoring only
- Quality gates escalate at each stage

## Test-Per-Environment Matrix

Skills like `/add:verify` and `/add:deploy` must check which tests to run based on the current environment:

| Test Type | Local | Dev/CI | Staging | Production |
|-----------|-------|--------|---------|------------|
| Unit | Yes | Yes | No | No |
| Integration | Yes | Yes | Yes | No |
| E2E | Optional | Optional | Yes | No |
| Smoke | No | No | Optional | Yes |
| Performance | No | No | Yes | No |
| Screenshot | With E2E | With E2E | With E2E | No |

## Environment Configuration

Each environment's specifics are in `.add/config.json`:

```json
{
  "environments": {
    "tier": 2,
    "local": {
      "run": "docker-compose up",
      "test": "pytest && npm run test",
      "e2e": "npm run test:e2e",
      "url": "http://localhost:3000"
    },
    "production": {
      "deploy_trigger": "merge to main",
      "verify": ["smoke_tests"],
      "url": "https://example.com"
    }
  }
}
```

## Deployment Rules

- **Local:** Agents deploy freely (docker-compose up/down, dev servers)
- **Dev/Staging:** Agents deploy autonomously if configured to do so
- **Production:** ALWAYS requires human approval, no exceptions
- Post-deploy verification is mandatory at every tier
- If smoke tests fail after deploy, alert the human immediately

## Environment Promotion Ladder

Agents can autonomously promote through environments when verification passes at each level. This is governed by the `autoPromote` flag per environment in `.add/config.json`.

### The Ladder

```
local (verify) → dev (verify) → staging (verify) → production (HUMAN REQUIRED)
```

**Rules:**
1. Verification at the current level MUST pass before promoting to the next
2. Each level runs its own verification suite (see Test-Per-Environment Matrix)
3. If verification fails at any level, **automatically rollback that environment** to last known good and stop the ladder
4. Production promotion ALWAYS requires human approval — the ladder stops at staging
5. The `autoPromote` config flag controls whether an environment participates in the ladder

### Promotion Flow

```
1. Deploy to dev
2. Run dev verification (unit + integration tests)
3. IF PASS → check if dev.autoPromote is true
4.   IF true → deploy to staging
5.   Run staging verification (integration + e2e + performance)
6.   IF PASS → log success, queue production for human approval
7.   IF FAIL → rollback staging to previous version, log failure, stop
8. IF FAIL → rollback dev to previous version, log failure, stop
```

### Automatic Rollback

When verification fails after deployment to an environment:

1. **Identify rollback target** — the last successfully verified deployment tag or commit for that environment
2. **Execute rollback** — redeploy previous version to that environment
3. **Verify rollback** — run smoke tests to confirm the environment is healthy
4. **Log everything** — record what was attempted, what failed, what was rolled back, in `.add/away-log.md` (during away mode) or the conversation
5. **Stop the ladder** — do not promote further; queue the failure for human review

### Configuration

Each environment declares its promotion rules in `.add/config.json`:

```json
{
  "environments": {
    "dev": {
      "autoPromote": true,
      "verifyCommand": "npm run test:integration",
      "rollbackStrategy": "revert-commit"
    },
    "staging": {
      "autoPromote": true,
      "verifyCommand": "npm run test:e2e && npm run test:perf",
      "rollbackStrategy": "redeploy-previous-tag"
    },
    "production": {
      "autoPromote": false,
      "requireApproval": true,
      "verifyCommand": "npm run test:smoke",
      "rollbackStrategy": "redeploy-previous-tag"
    }
  }
}
```

- `autoPromote: true` — agent can deploy here autonomously if the previous environment verified successfully
- `autoPromote: false` — requires human approval (always the case for production)
- `verifyCommand` — what to run after deploying to this environment
- `rollbackStrategy` — `revert-commit` (git revert + redeploy) or `redeploy-previous-tag` (checkout last stable tag + redeploy)

## Environment-Specific Behavior

### During Away Mode
- Agents follow the promotion ladder autonomously up to the configured `autoPromote` ceiling
- Typically this means: local → dev → staging are autonomous (if `autoPromote: true`)
- Production is NEVER autonomous, even during extended away sessions
- If the ladder reaches a non-autoPromote environment, queue it for human return
- **On failure at any level:** rollback, log the failure, and move to the next planned task — do not retry the same deployment

### During Active Collaboration
- Agent proposes deployments, human approves
- Quick check: "E2E tests pass in dev. Promote to staging?"
- Production deploy is always a Review Gate (summary + explicit approval)
- Human can override `autoPromote` settings at any time: "go ahead and push through to staging without asking"

## Secrets and Configuration

- Never hardcode environment-specific values
- Use `.env` files locally (never committed)
- Use secret managers in cloud environments
- The `.env.example` file documents all required variables
- Agents may READ .env to understand configuration but never LOG or EXPOSE values

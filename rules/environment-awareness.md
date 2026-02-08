---
autoload: true
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

## Environment-Specific Behavior

### During Away Mode
- Agents may deploy to local and dev
- Agents must NOT deploy to staging or production
- If work requires a staging deployment to verify, queue it for human return

### During Active Collaboration
- Agent proposes deployments, human approves
- Quick check: "E2E tests pass locally. Ready to deploy to staging?"
- Production deploy is always a Review Gate (summary + explicit approval)

## Secrets and Configuration

- Never hardcode environment-specific values
- Use `.env` files locally (never committed)
- Use secret managers in cloud environments
- The `.env.example` file documents all required variables
- Agents may READ .env to understand configuration but never LOG or EXPOSE values

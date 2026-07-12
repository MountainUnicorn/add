# Deploy Reference

Sample output, configuration example, checklist, and rollback commands for
`/add:deploy`. Fill `{placeholders}` with real values.

## Sample "Deployment Complete" Report

```
# Deployment Complete ✓

## Deployment Summary
- Environment: {env}
- Feature: {feature-name}
- Commit: {short-hash}
- Branch: {branch-name}
- Timestamp: {ISO timestamp}
- Duration: {X minutes}

## Code Changes
- Files modified: {count}
- Lines added: {count}
- Lines removed: {count}
- Acceptance criteria: {N}/{N} verified

## Quality Gates (Pre-Deploy)
- Lint: ✓ PASS
- Types: ✓ PASS
- Tests: ✓ PASS (32/32)
- Coverage: ✓ PASS (87%)
- Spec compliance: ✓ PASS

## CI/CD Pipeline
- Status: ✓ ALL JOBS PASSED
- Lint: ✓ 2 minutes
- Type Check: ✓ 3 minutes
- Unit Tests: ✓ 4 minutes
- Integration Tests: ✓ 2 minutes

## Post-Deployment Verification
- Smoke Tests: ✓ PASS (6/6)
- Health Check: ✓ OK
- Error Rate: Normal
- Response Time: {Xms avg} (target: <100ms)

## Deployment Details
- Strategy: {direct|blue-green|canary}
- Rollback Plan: Revert commit {hash} and redeploy

## Deployed Files
- API endpoints: ✓ Updated and responding
- Database migrations: {N} applied
- Static assets: Served from CDN
- Service restart: ✓ Complete

## Notifications
- Slack notification sent ✓
- Email notification sent ✓
- Deployment log: logs/deploy-{date}-{id}.txt

## Next Steps
1. Monitor application for issues (next 1 hour)
2. Check user feedback and error tracking
3. Validate feature is used as expected
4. Consider follow-up optimizations
```

## Configuration Example (.add/config.json)

```json
{
  "git": {
    "defaultBranch": "main",
    "requirePR": false,
    "requireReviews": 2
  },
  "ci": {
    "enabled": true,
    "provider": "github",
    "timeout": 1800
  },
  "deployment": {
    "strategy": "direct",
    "rollbackEnabled": true,
    "smokeTestScript": "npm run test:smoke"
  },
  "environments": {
    "dev": {
      "branch": "develop",
      "requireApproval": false,
      "targetHost": "dev.example.com"
    },
    "staging": {
      "branch": "staging",
      "requireApproval": false,
      "targetHost": "staging.example.com"
    },
    "production": {
      "branch": "main",
      "requireApproval": true,
      "requireReviews": 2,
      "targetHost": "api.example.com"
    }
  }
}
```

## Pre-Production Deployment Checklist

Before deploying to production:
- [ ] All acceptance criteria implemented
- [ ] All tests passing
- [ ] Code coverage >= 80%
- [ ] Lint and type checks passing
- [ ] Code reviewed by 2+ team members
- [ ] Spec compliance verified
- [ ] Performance targets met
- [ ] Database migrations ready
- [ ] Documentation updated
- [ ] Release notes prepared
- [ ] Rollback plan documented
- [ ] Team notified
- [ ] Monitoring configured
- [ ] Smoke tests defined
- [ ] Post-deployment checklist ready

## Rollback Commands

If production deployment fails:

```bash
# Immediate rollback
git revert {problematic-commit}
git push origin main

# Or tag-based rollback
git checkout {previous-stable-tag}
git push origin main

# Deploy previous version
npm run deploy:production

# Verify health
npm run test:smoke -- --environment production
```

---
name: add-deploy
description: "[ADD v0.9.1] Environment-aware commit, push, and deploy workflow"
argument-hint: "[--env local|dev|staging|production] [--skip-verify]"
---

# ADD Deploy Skill v0.9.1

Execute environment-aware deployment: commit changes, push to remote, trigger CI/CD, and verify successful deployment.

## Overview

The Deploy skill orchestrates the final step of the development workflow:
1. **Commit** — Stage and commit code changes with traceability
2. **Push** — Push to remote repository and branch
3. **CI/CD** — Trigger or monitor CI pipeline
4. **Verify** — Confirm deployment success and run smoke tests

The skill is environment-aware: deployment to production is gated with additional safety checks and requires human approval.

Deployment flows:
- **Local**: Commit only (no push)
- **Dev**: Commit → Push → Optional CI
- **Staging**: Commit → Push → CI required → Verify
- **Production**: Commit → Push → CI required → Gated approval → Verify smoke tests

## Pre-Flight Checks

1. **Verify code quality**
   - Run /add:verify --level deploy (unless --skip-verify)
   - Halt if quality gates fail
   - Ensure all tests passing

2. **Load configuration**
   - Read .add/config.json
   - Extract deployment settings:
     - ci.enabled (true/false)
     - ci.provider (github, gitlab, circleci, etc.)
     - environments: dev, staging, production configs
     - deployment.strategy (direct, blue-green, canary)
   - Load credential/auth settings

3. **Verify git repository**
   - Confirm working directory is a git repo
   - Check git is configured (user.name, user.email)
   - Verify branch protection rules won't block merge

4. **Determine environment**
   - Use --env flag or prompt user
   - Default: staging (safe default)
   - Validate environment exists in config

5. **Check for uncommitted changes**
   - Run `git status`
   - Verify all relevant changes are staged
   - Halt if unintended changes exist
   - Ask user to review staged changes

6. **Verify feature branch**
   - Confirm on feature branch (not main/master)
   - For production, branch should be up-to-date with main
   - For dev, any branch acceptable

7. **Check for session handoff**
   - Read `.add/handoff.md` if it exists
   - Note any in-progress work or decisions relevant to this operation
   - If handoff mentions blockers for this skill's scope, warn before proceeding

## Execution Steps

### Step 1: Pre-Deployment Verification

Unless --skip-verify:

```bash
# Run full quality gates
npm test            # all tests pass
npm run lint        # no lint errors
npm run build       # builds successfully
# or Python equivalent
python -m pytest    # all tests pass
python -m flake8    # no lint errors
# or other language equivalents
```

Capture results:
- Exit code (0 = success)
- Test count and results
- Coverage percentage
- Build artifacts created

If any verification fails:
- Report which gate failed
- Do NOT proceed with deployment
- Ask user to fix issues and re-run

### Step 1.5: Pre-commit secrets gate

Before composing the commit message, scan the staged diff for secrets.

**Source of truth:** `~/.codex/add/knowledge/secret-patterns.md` (regex
catalog + high-entropy heuristic + path-prefix deny list). The gate MUST use
this catalog — do not duplicate the patterns inline.

**Invocation (Bash):**

```bash
# 1. Collect staged, non-binary, non-ignored files.
#    Respect .secretsignore: files matching those patterns should not be
#    staged at all — if they appear, flag them as "should not be committed."
staged=$(git diff --cached --name-only --diff-filter=ACM)

# 2. For each file: apply every regex from the catalog to the staged content
#    (git diff --cached -- "$file"). Suppress matches that fall under the
#    entropy heuristic's safe-context exceptions (lockfile path, commit SHA
#    in a git-log block, UUID, content-addressed hash marker, build/trace id).

# 3. On any match, emit:
#    {file}:{line} — {PATTERN_NAME} pattern
#    Do NOT echo the matched value itself; use the pattern name only.
```

**On match — abort the commit and print:**

```
SECRETS GATE — /add:deploy
Scanning {N} staged files...

  ✗ {file}:{line} — {PATTERN_NAME} pattern
  ✗ {file}:{line} — {PATTERN_NAME} pattern

Commit aborted. Two options:

  1. Remove the secrets:
       git restore --staged {file} {file}
       Add {file} to .secretsignore (or .gitignore)
       Rotate any real secrets immediately

  2. False positive (test fixture, example, etc.):
       /add:deploy --allow-secret
       (you will be asked to type a confirmation phrase)
```

No commit is created. Preserve staged changes so the user can fix and retry.

**`--allow-secret` flag (AC-016, AC-017):**

If the user invokes `/add:deploy --allow-secret`, present:

> "To override the secrets gate, type the following phrase EXACTLY
> (case-sensitive, full string — no quotes, no abbreviation):
>
>     I have verified this is not a real secret
>
> Any other response cancels the override."

Matching rules — implemented literally, not left to agent judgment:

- The response MUST equal the string `I have verified this is not a real secret`
  (no quotes, no leading/trailing whitespace other than a trailing newline).
- Case-sensitive. `i have verified this is not a real secret` does NOT pass.
- Must be the ENTIRE user response. Extra text, punctuation, or prefix/suffix
  does NOT pass.
- Must be the IMMEDIATELY NEXT message. Intervening clarifications reset the
  gate; re-ask.

On successful match, proceed to Step 2. Before proceeding, append a line to
`.add/observations.md`:

```
{YYYY-MM-DD HH:MM} | deploy | secrets-gate override: {file}:{line} {PATTERN_NAME} | reason: {user's stated reason}
```

Also append the override record to `.add/redaction-log.json` under
`{ "artifact": "deploy-gate-override", ... }` if the log exists.

On any failing match: halt with:

```
Secrets gate override CANCELLED. No changes made. Run /add:deploy again when
ready — the exact phrase is required to prevent automation or accidental
consent from pushing secrets.
```

**`.secretsignore` handling (AC-018):**

- Files matching `.secretsignore` patterns should not be in the staged set.
- If one appears (because the user staged it with `git add -f` or before the
  ignore file existed), flag separately:

```
  ✗ {file} — listed in .secretsignore; this file should not be committed at all
```

and treat it the same as a catalog match (abort unless `--allow-secret` with
the full phrase).

**Edge cases (from spec § 7):**

| Case | Behavior |
|------|----------|
| Binary file staged | Skip content scan; still flag if filename matches `.secretsignore` |
| Git not initialized | Skip gate silently; first-commit projects aren't blocked |
| File path contains `test`, `fixture`, `example`, or `mock` | Still flag, but downgrade severity in the message and suggest `--allow-secret` |
| `.env.example` with placeholder values | `.secretsignore` negation (`!.env.example`) allows it; content scan usually won't match because examples are placeholders |
| Pattern catalog updated in plugin upgrade | Gate reads the latest catalog from `~/.codex/add/knowledge/secret-patterns.md`; existing `.secretsignore` files untouched |

### Step 2: Prepare Commit Message

Compose a detailed commit message following conventions:

**Format**:
```
{Type}: {Short description under 50 chars}

{Longer description explaining the change}

Acceptance Criteria:
- AC-001: ✓ Implemented and tested
- AC-002: ✓ Implemented and tested

Test Coverage:
- {N} tests passing
- {N}% code coverage

Quality Gates:
- ✓ Lint passing
- ✓ Types passing
- ✓ Tests passing
- ✓ Spec compliance verified

Closes: #{issue-number} (if applicable)
```

**Types**:
- feat: New feature
- fix: Bug fix
- refactor: Code refactoring
- test: Test additions
- docs: Documentation
- perf: Performance optimization
- ci: CI/CD changes
- chore: Build, deps, etc.

**Example**:
```
feat: Add form submission with email validation

Implement user-facing form with client-side and server-side
validation. Integrates with existing email service for
verification. Handles network errors with retry logic.

Acceptance Criteria:
- AC-001: ✓ User can submit valid form data
- AC-002: ✓ Form shows validation errors
- AC-003: ✓ Network failures handled gracefully

Test Coverage:
- 8 tests passing
- 87% code coverage
- All ACs verified

Quality Gates:
- ✓ Lint: 0 errors
- ✓ Types: 0 errors (TypeScript strict)
- ✓ Tests: 32 passing
- ✓ Coverage: 87% (target: 80%)
- ✓ Spec compliance: 5/5 ACs tested

Closes: #1234
```

### Step 3: Stage and Commit Changes

Stage relevant files (not sensitive files):

```bash
# Stage implementation files
git add src/
git add tests/
git add docs/

# Verify staging
git status
git diff --cached

# Do NOT stage:
# - .env files
# - Secrets or credentials
# - node_modules/
# - Build artifacts (unless necessary)
# - .DS_Store, IDE files
```

Ask user to verify staged changes:
```
Staged files:
- src/form.ts
- src/api/submit.ts
- tests/form.test.ts
- tests/api.test.ts
- docs/performance.md

Proceed with commit? [yes/no]
```

Wait for explicit confirmation before committing.

Create commit:
```bash
git commit -m "$(cat <<'EOF'
feat: Add form submission with email validation

[full message as prepared in Step 2]
EOF
)"
```

Verify commit:
```bash
git log -1 --oneline
# Output: abc1234 feat: Add form submission with email validation
```

### Step 4: Push to Remote

**For Dev/Staging Environments**:

Determine target branch:
- Default: same name as feature branch
- Or specified via config

Push to remote:
```bash
git push origin {feature-branch}
# or
git push -u origin {feature-branch}
```

Verify push succeeded:
- Check exit code (0 = success)
- Confirm remote shows new commit

**For Production Environment**:

Production requires PR/merge request workflow:
1. Create PR/MR with:
   - Title from commit message
   - Description with AC list
   - Link to spec and plan
   - Risk assessment

2. Request reviews:
   - At least 2 approvals required (per config)
   - Assign to code owners
   - Wait for approval

3. Merge to main:
   ```bash
   # After PR approved and CI passes
   git checkout main
   git pull origin main
   git merge {feature-branch}
   # or use GitHub/GitLab merge button
   ```

4. Tag release:
   ```bash
   git tag -a v{version} -m "Release {feature-name} v{version}"
   git push origin v{version}
   ```

### Step 5: Trigger or Monitor CI/CD

**CI/CD Pipeline**:

Check if CI is enabled in config (ci.enabled):

If enabled:
1. **Trigger CI** (if not automatic)
   - GitHub: automatic on push/PR
   - GitLab: automatic on push/MR
   - CircleCI: may require manual trigger
   - Jenkins: may require webhook/API call

2. **Monitor pipeline progress**
   - Fetch build status from CI provider
   - Poll until complete (timeout: 30min)
   - Stream logs if available

3. **Check gate results**
   ```
   CI Pipeline Status: 🟡 In Progress

   Jobs:
   - Lint: ✓ PASSED (2 min)
   - Type Check: ✓ PASSED (3 min)
   - Unit Tests: 🟡 IN PROGRESS (4/32 tests)
   - Integration Tests: ⊘ PENDING
   - Deploy to Staging: ⊘ PENDING

   Elapsed: 5 minutes
   ETA: 8 minutes
   ```

4. **Wait for completion**
   - All jobs must pass
   - No failures allowed
   - Report if any job fails

If CI disabled:
- Document that CI is skipped
- Warn user: "CI verification skipped - consider enabling"
- Continue to deployment

### Step 6: Production Approval Gate — Confirm-Phrase (Production Only)

**This gate is a runtime check, not a behavioral rule.** The skill MUST NOT proceed to any production deployment action without capturing the exact confirmation phrase below. This applies regardless of `--promote`, away mode, or any other autonomy granting — production is the one boundary that remains human-gated at all maturities.

**Also required:** `.add/config.json` → `environments.production.autoPromote` must be `false`. If it is `true`, halt with: "`autoPromote: true` on production is not permitted — ADD refuses to proceed. Edit `.add/config.json` to set `autoPromote: false`."

#### 6.1 Present deployment plan

```
⚠️  PRODUCTION DEPLOYMENT

Feature: Form submission with email validation
Commit: abc1234
Branch: feature/form-submission
Target: main

Changes:
- 3 files modified
- 450 lines added, 20 lines removed

Testing:
- ✓ All 32 tests passing
- ✓ 87% code coverage
- ✓ Lint and type checks passing

Acceptance Criteria Verified:
- AC-001: ✓ User can submit valid form
- AC-002: ✓ Validation errors shown
- AC-003: ✓ Network errors handled

Risk Assessment:
- Integration Points: 1 (Email service)
- Database Changes: None
- Breaking Changes: None
- Rollback Plan: Revert commit + redeploy previous tag
```

#### 6.2 Require the confirm-phrase

Ask the user:

> "To proceed with production deployment, type **`DEPLOY TO PRODUCTION`** (all caps, exactly) and press enter. Any other response — including 'yes', 'y', 'ok', or silence — will cancel."

**Matching rules — implemented literally in the skill, not left to agent judgment:**

- The response MUST equal the string `DEPLOY TO PRODUCTION` (no quotes, no leading/trailing whitespace other than a trailing newline).
- Case-sensitive match. `deploy to production` does NOT pass. `Deploy to Production` does NOT pass.
- The match is on the ENTIRE user response. `DEPLOY TO PRODUCTION please` does NOT pass.
- The match must be the IMMEDIATELY NEXT user message. If the user sends any intervening message (clarification, question), the gate resets and must be re-asked.

If the match succeeds: proceed to Step 7.
If the match fails for any reason: halt and output:

```
Production deployment CANCELLED. No changes made.

Re-run /add:deploy --env production when ready to deploy.
The confirm-phrase gate exists to prevent automation, rushed approvals,
and ambiguous consent from deploying to production.
```

**Why this gate exists:** ADD's autonomous-execution model is powerful enough that "please approve" prompts during away mode get fuzzy. Requiring a specific literal string means no agent, no script, no accidental enter-key can trigger a production deploy without the human actively typing the phrase. This is a technical gate, not a behavioral rule.

#### 6.3 Record and proceed

- Timestamp the approval
- Record in `.add/deploy-log.md` with commit hash, branch, and confirm-phrase timestamp
- Include in the commit message body: `Approved via DEPLOY TO PRODUCTION phrase at {UTC timestamp}`
- Continue to Step 7

#### 6.4 Timeout and boundary behavior

- If the user does not respond within 15 minutes: halt and cancel (same as a non-matching response)
- During away mode: the gate still requires the phrase. If away mode is active and the user is unreachable, the production deploy MUST wait for the user's return. Log to `.add/away-log.md` and move to the next task.

### Step 7: Execute Deployment

**For Dev Environment**:
```bash
# Direct deploy (no CI required)
npm run deploy:dev
# or
./scripts/deploy-dev.sh
```

**For Staging Environment**:
```bash
# After CI passes
npm run deploy:staging
# or
./scripts/deploy-staging.sh
```

**For Production Environment**:
```bash
# After approval, merge to main, and CI passes
npm run deploy:production
# or
./scripts/deploy-production.sh

# This typically:
# - Pulls latest from main
# - Builds production bundle
# - Uploads to production servers
# - Runs database migrations if needed
# - Restarts services
# - Runs health checks
```

Monitor deployment:
- Watch deployment logs
- Check for errors or failures
- Verify services are coming online
- Confirm no data loss

### Step 8: Verify Deployment Success

After deployment completes:

1. **Run smoke tests**
   ```bash
   npm run test:smoke -- --environment production
   # or equivalent
   ```

   Smoke tests check:
   - API endpoints responding
   - Database connectivity
   - Cache working
   - Email service working
   - No obvious breakage

2. **Verify application health**
   ```bash
   curl https://api.example.com/health
   # Response should indicate health: 200 OK
   ```

3. **Check user-facing changes**
   - Navigate to deployed application
   - Test happy path for new feature
   - Verify no visual regressions
   - Check mobile responsiveness

4. **Monitor error logs**
   - Check application logs for errors
   - Check infrastructure logs
   - Alert on unexpected errors

5. **Verify metrics**
   - Response time within targets
   - Error rate normal
   - Resource usage normal
   - User activity patterns normal

**Success Criteria**:
- All smoke tests pass
- No critical errors in logs
- Metrics within normal ranges
- Feature working as designed

**Failure Response**:
- If any smoke test fails, escalate
- For production, implement rollback plan
- Document the failure
- Root cause analysis

## Output Format

Upon successful deployment, output:

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
- Deployment log: logs/deploy-2025-02-07-1234.txt

## Next Steps
1. Monitor application for issues (next 1 hour)
2. Check user feedback and error tracking
3. Validate feature is used as expected
4. Consider follow-up optimizations
```

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner. Create tasks at the start of each major phase and mark them completed as they finish.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Pre-deploy | Running pre-deploy checks | Running pre-deploy checks... |
| Prepare | Preparing deployment artifacts | Preparing deployment... |
| Deploy | Executing deployment | Executing deployment... |
| Smoke tests | Running post-deploy smoke tests | Running smoke tests... |

Mark each task `in_progress` when starting and `completed` when done. This gives the user real-time visibility into skill execution.

## Error Handling

**Quality gates fail (--skip-verify not set)**
- Report which gates fail
- Do NOT proceed with deployment
- Ask user to fix issues
- Run /add:verify to see detailed failures

**Uncommitted changes detected**
- List uncommitted changes
- Ask user: commit or discard?
- Halt until resolved

**Branch protection rules block push**
- Report which rule is blocking
- For production, this is expected (PR required)
- Guide user through PR process

**CI pipeline fails**
- Report which job failed
- Show job logs
- Do NOT proceed with deployment
- Ask user to fix and retry

**Smoke tests fail after deployment**
- Immediate escalation for production
- For prod, recommend rollback
- For staging, document and investigate
- Run root cause analysis

**Production deployment approval timeout**
- Halt after 15 minutes of no response
- Preserve staged changes for retry
- Notify user to re-run when ready

**Deployment script fails**
- Report error from deployment command
- Show relevant logs
- Suggest manual investigation
- For production, initiate rollback procedure

## Environment Promotion Ladder

When deploying to a multi-environment project (Tier 2+), the deploy skill supports automatic promotion through environments:

### Promotion Mode (`--promote`)

When invoked with `--promote` (or during away mode), the skill climbs the promotion ladder:

1. Deploy to current environment → run `verifyCommand` for that environment
2. If verification passes AND next environment has `autoPromote: true` → deploy to next environment
3. Repeat until ladder ends, verification fails, or `autoPromote: false` is reached
4. If verification fails at any level → **rollback that environment** to last known good, log failure, stop

```
/add:deploy --promote --env dev
  → deploys to dev
  → runs dev verifyCommand (integration tests)
  → PASS → auto-promotes to staging
  → runs staging verifyCommand (e2e + perf)
  → PASS → stops (production requires human approval)
  → logs: "Verified through staging. Production queued for human approval."
```

### Rollback on Failure

If verification fails after deploying to an environment:

1. Read `rollbackStrategy` from config for that environment:
   - `revert-commit`: `git revert {commit} && git push` → redeploy
   - `redeploy-previous-tag`: find last stable tag → checkout → redeploy
2. Run smoke test against the rolled-back environment to confirm it's healthy
3. Log the failure with: what was deployed, what failed, what was rolled back
4. Stop the ladder — do not promote further

### Away Mode Behavior

During away mode, the deploy skill automatically uses `--promote` behavior:
- Climb the ladder through all `autoPromote: true` environments
- Stop before any `autoPromote: false` environment (always production)
- On failure: rollback, log, move to next task in the away plan

## Integration with Other Skills

- Called after /add:tdd-cycle and /add:verify succeed
- Triggers /add:verify --level smoke after deployment
- Supports `--promote` for automatic environment ladder climbing
- Final step in development workflow
- Completes the cycle: Spec → Plan → Code → Deploy

## Configuration in .add/config.json

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

## Deployment Checklist

Before deploying to production:
- [ ] All acceptance criteria implemented
- [ ] All tests passing (32/32)
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

## Rollback Procedure

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

Document:
- What broke
- Why it broke
- How to prevent in future
- Timeline of incident

## Post-Deployment Monitoring

After production deployment:
- Monitor error rates for 1 hour
- Check user feedback channels
- Verify feature adoption
- Monitor performance metrics
- Be ready to rollback if issues arise

## Process Observation

After completing this skill, do BOTH:

### 1. Observation Line

Append one observation line to `.add/observations.md`:

```
{YYYY-MM-DD HH:MM} | deploy | {one-line summary of outcome} | {cost or benefit estimate}
```

If `.add/observations.md` does not exist, create it with a `# Process Observations` header first.

### 2. Learning Checkpoint

Write a structured JSON learning entry per the checkpoint trigger in `~/.codex/add/references/learning-reference.md` (section: "After Deployment"). Classify scope, write to the appropriate JSON file (`.add/learnings.json` or `~/.claude/add/library.json`), and regenerate the markdown view.

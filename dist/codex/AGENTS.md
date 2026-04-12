# ADD — Agent Driven Development (Codex adapter v0.7.1)

This file is auto-generated from `core/` by `scripts/compile.py`.
ADD is a methodology for agent-driven development — spec-driven, test-first,
learning-accumulating, maturity-aware. The rules below are enforced by
reading them at the start of every session.

## Global Knowledge

# ADD Global Knowledge — Tier 1

> **Tier 1: Plugin-Global** — Curated best practices that ship with ADD for all users.
> This file is read-only in consumer projects. Only updated by the ADD maintainers.
>
> Agents read this file as part of the 3-tier knowledge cascade:
> 1. **Plugin-global** (this file) — universal ADD best practices
> 2. **User-local** (`~/.claude/add/library.md`) — your cross-project wisdom
> 3. **Project-specific** (`.add/learnings.md`) — this project's discoveries

## Plugin Architecture

- Claude Code plugins namespace commands and skills automatically as `pluginname:commandname` (e.g., `add:spec`). But Claude reproduces whatever naming pattern it sees in file content — so all internal references in plugin files must use the full namespaced form (`/add:spec`, not `/spec`).
- Rules with `autoload: true` in YAML frontmatter load automatically when Claude enters the project. This is the primary enforcement mechanism for ADD behavior.
- Skills use `allowed-tools` in frontmatter to restrict what a skill can do. This enables agent isolation (test-writer can't deploy, reviewer can't edit).
- Claude Code plugin format uses `.claude-plugin/plugin.json` as the manifest. `marketplace.json` lives at the repo root in `.claude-plugin/` and points to the plugin via `source`.

## Agent Coordination

- Parallel subagents for bulk file edits — dispatching 3+ agents simultaneously for coordinated changes is significantly faster than sequential editing. Good pattern for any batch operation touching independent files.
- Never let two agents write to the same file simultaneously. Use file reservations or git worktrees for parallel work.
- Trust-but-verify: a sub-agent reporting "all tests pass" is necessary but not sufficient. The orchestrator must independently run tests.
- Separating "autonomous operations" from "boundaries" as explicit lists makes agent permissions unambiguous. Agents don't have to infer — they get a clear yes/no list.

## Away Mode

- Default to 2-hour duration when the human doesn't specify a time. Don't ask — they're trying to leave.
- Agents need explicit grant of git autonomy (commit, push, create PRs) during away sessions. Without it, they fall back to "ask the human" for routine development tasks.
- The real deployment boundary is production, not staging. Projects with CI/CD should let agents promote through `local → dev → staging` autonomously when verification passes. Production always requires human approval.

## Documentation & Distribution

- GitHub README strips all `<style>` and `<script>` tags. SVG is the only vehicle for rich visuals in a README.
- GitHub Pages can serve from any directory via Actions workflow with `actions/upload-pages-artifact`. Use `build_type: workflow` via the GitHub API.
- macOS filesystems are case-insensitive. `add/` and `ADD/` are the same directory. Use lowercase for project directory names.

## Methodology Insights

- Deriving methodology specs from real, mature projects ensures the methodology reflects actual practice, not theory.
- The 1-by-1 interview format with estimation ("~12 questions, ~10 minutes") prevents question fatigue and is well-received.
- "Cycle" is better than "sprint" for work batching. Sprints imply fixed calendar time; cycles are scope-boxed and end when validation criteria are met.
- Now/Next/Later framing for milestones avoids fake date precision. AI-agent work moves at unpredictable pace.
- Dog-fooding the plugin as a consumer catches issues that the developer perspective never would (e.g., namespace issues, missing permissions).
- Spec-before-code must be enforced on the methodology project itself. If specs are written after implementation, the project has no credibility prescribing spec-driven development to others. Retroactively marking specs "Complete" is a debt payment, not a workflow.

## Environment Promotion

- Environment promotion ladder: agents climb `local → dev → staging` autonomously when verification passes at each level, with automatic rollback on failure.
- Two rollback strategies: `revert-commit` (lighter, for dev) and `redeploy-previous-tag` (safer, for staging/production).
- The ladder stops on first failure — no retries, log and move on. Safer than letting agents debug deployment issues autonomously.

## Competing Swarm Pattern

When a problem has multiple valid approaches and the wrong choice is expensive to reverse, dispatch **2-3 sub-agents with deliberately different approaches in parallel**, then synthesize or pick a winner before implementation. This is different from ordinary parallel dispatch (which assumes independent, non-overlapping work).

**When to use:**
- Infrastructure problems with multiple architecturally valid solutions (e.g., cert-manager vs Google Managed Certs vs app-level ACME proxy)
- UX/design decisions where the cheapest information is a side-by-side comparison
- Security remediation where defense-in-depth from multiple angles is actively useful
- Research spikes where you want diversity of thought, not just throughput

**How to run one:**
1. Name the problem in one sentence.
2. Explicitly brief each sub-agent on *its* approach, and on the fact that other agents are working the same problem differently. This prevents them from converging.
3. Give each the same success criteria.
4. When they complete, review all outputs in one sitting.
5. **Pick a winner BEFORE implementation when approaches are mutually exclusive.** Two swarms independently building mutually-exclusive solutions creates merge conflicts and wasted work.
6. When approaches are *not* mutually exclusive, synthesize — the agentVoice HTTPS cert case shipped both solutions as belt-and-suspenders redundancy, which turned out to be the right call.
7. Record the pattern in `.add/observations.md` with `[swarm]` tag for retro fuel.

**Anti-patterns:**
- Running competing swarms on problems that are already well-understood (pure waste)
- Forgetting to brief agents that others are attempting the same goal (they'll converge to identical approaches)
- Letting both winners land in the codebase without coordinating — leads to conflicting abstractions

**Evidence:** Used successfully three times in the agentVoice project (HTTPS cert resolution, GKE CI/CD install, security Phases A/B/C). Each produced better outcomes than a single-approach dispatch would have. The one failure (cert-manager removal vs fix in parallel) reinforced the "pick a winner before implementation" rule.

## Infrastructure Prerequisites

- Before debugging a workflow YAML, verify the workflow is actually running. GitHub Actions can be disabled at the account level, and a disabled repo will show zero runs regardless of config correctness.
- Before debugging a deployment, verify the artifact exists. Check registry (GHCR, Artifact Registry, etc.) before checking container logs — an image that never built produces "pod never starts" symptoms identical to many other failures.
- Before issuing a TLS cert, verify the domain serves HTTP 200 at `/` with a healthy backend. Google Managed Certificates require 200 at root; a redirect or 404 fails validation silently and leaves the cert in a stuck `FAILED_NOT_VISIBLE` state.
- Multi-stage Docker builds only copy paths you explicitly name. Files created in a `deps` stage outside the standard install path will be missing from the `runtime` stage. Add explicit `COPY --from=deps` for every non-standard path.
- GitOps controllers with `selfHeal: true` (ArgoCD, Flux) revert `kubectl` edits immediately. In such environments, `kubectl` is a read-only tool — all mutations must flow through git.
- Cloud Build (native amd64) beats local ARM→amd64 QEMU emulation by 10-20x for GPU images. On an Apple Silicon developer machine, cross-build via the cloud is the default; local cross-build should be reserved for tiny images where the upload cost dominates.

## Quality Protocols

- E2E tests must be browser-only, human-like interactions. E2E tests must NEVER call APIs directly, check database state, use `skip()` to mask failures, or make programmatic decisions a real user wouldn't. Every action goes through the browser automation (click, fill, select, wait-for-visible). If a feature doesn't work, the test fails — it does not skip. Skipping on error defeats the entire purpose of E2E, which is catching the integration failures unit tests miss.


---

## Rule: add-compliance

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


---

## Rule: agent-coordination

# ADD Rule: Agent Coordination Protocol

When multiple agents work on a project, they follow the orchestrator pattern with trust-but-verify.

## Orchestrator Role

The orchestrator (primary Claude session) is responsible for:

1. Breaking work into bounded tasks for sub-agents
2. Assigning each task with clear inputs, scope, and success criteria
3. Independently verifying sub-agent output
4. Maintaining the overall project state and progress

## Sub-Agent Dispatching

When dispatching work to a sub-agent, always provide:

```
TASK: {what to do}
SCOPE: {which files, which feature, what boundaries}
SPEC REFERENCE: {specs/{feature}.md, acceptance criteria IDs}
SUCCESS CRITERIA:
  - {testable criterion 1}
  - {testable criterion 2}
INPUT FILES: {files the agent needs to read}
OUTPUT: {what the agent should produce — files, test results, summary}
RESTRICTIONS: {what the agent should NOT do}
```

## Trust-But-Verify

After any sub-agent completes work:

1. **Read the output** — Review files changed, tests written, code produced
2. **Run tests independently** — Do NOT trust the sub-agent's test output alone
3. **Check spec compliance** — Does the output satisfy the acceptance criteria?
4. **Run quality gates** — Lint, type check, coverage
5. **Only then** accept the work into the main branch

Never skip verification. A sub-agent reporting "all tests pass" is necessary but not sufficient.

## Agent Isolation

Sub-agents should have bounded scope to prevent unintended side effects:

### Test Writer Agent
- CAN: Read specs, read existing code, write test files
- CANNOT: Modify implementation code, run deploy commands, modify configuration

### Implementer Agent
- CAN: Read specs, read tests, write/edit implementation files
- CANNOT: Modify test files, deploy, change project configuration

### Reviewer Agent
- CAN: Read all files, run tests, run linters, produce review report
- CANNOT: Modify any files

### Deploy Agent
- CAN: Run build commands, run deployment scripts, verify endpoints
- CANNOT: Modify source code, modify tests

## Parallel Execution

When tasks are independent, dispatch them in parallel:

```
PARALLEL DISPATCH:
  Agent A: Write unit tests for user service (specs/auth.md AC-001 through AC-004)
  Agent B: Write unit tests for API routes (specs/auth.md AC-005 through AC-008)
  Agent C: Write E2E test scaffolding (specs/auth.md TC-001 through TC-003)

WAIT FOR ALL

SEQUENTIAL:
  Orchestrator: Run full test suite (verify all agents' tests coexist)
  Orchestrator: Verify no conflicts or duplicate coverage
```

## Context Management

- Each sub-agent starts with a clean context (no conversation history pollution)
- Pass only the files and spec sections relevant to the task
- Use `/clear` between major context switches in the orchestrator
- When context gets long, summarize state and start a fresh session

## Output Format

Sub-agents must return structured output:

```
STATUS: success | partial | blocked
FILES_CHANGED:
  - path/to/file.ts (created | modified | deleted)
TEST_RESULTS:
  passed: N
  failed: N
  skipped: N
SPEC_COMPLIANCE:
  - AC-001: covered by test_user_login
  - AC-002: covered by test_invalid_password
SUMMARY: {1-2 sentence description of what was done}
BLOCKERS: {any issues that prevented completion}
```

## Escalation

If a sub-agent encounters any of these, it must stop and report back:

- Spec is ambiguous or contradictory
- Required dependency or file doesn't exist
- Tests reveal a design issue that needs spec revision
- Task scope is larger than estimated (> 2x)
- Security concern discovered

The orchestrator then either resolves the issue or escalates to the human via a Decision Point.

## Learning-on-Verify

Verification is a learning opportunity. When the orchestrator verifies sub-agent work, it must record what happened — both successes and failures.

### When Verification Catches an Error

1. Fix the issue
2. Append a checkpoint to `.add/learnings.md`:
   ```markdown
   ## Checkpoint: Verification Catch — {date}
   - **Agent:** {test-writer|implementer|other}
   - **Error:** {what went wrong}
   - **Correct approach:** {what should have been done}
   - **Pattern to avoid:** {generalized lesson for future work}
   ```
3. If the error reveals a spec gap, flag it for the next retro
4. Append a structured observation to `.add/observations.md` tagged `[agent-retro]`:
   ```markdown
   {YYYY-MM-DD HH:MM} | [agent-retro] | verify-catch | {what the sub-agent got wrong} | {process gap: why this wasn't caught earlier}
   ```
   This observation feeds into orchestrator micro-retros and `/add:retro` synthesis.

### When Verification Passes Clean

Still worth recording if something notable happened:
- A non-obvious approach that worked well
- A pattern that should be reused
- Unexpectedly fast or slow execution

### Before Dispatching Sub-Agents

The orchestrator MUST read all 3 knowledge tiers and include relevant lessons in the dispatch context:

1. **Tier 1:** `~/.codex/add/knowledge/global.md` — universal ADD best practices
2. **Tier 2:** `~/.claude/add/library.md` — user's cross-project wisdom (if exists)
3. **Tier 3:** `.add/learnings.md` — project-specific discoveries (if exists)

For example, if a Tier 3 checkpoint says "pymysql is not thread-safe," include that in the RESTRICTIONS when dispatching database-related work. If a Tier 1 entry says "always independently run tests after sub-agent work," ensure the verification step is in the dispatch plan.

This is how the team gets smarter over time — past mistakes from all tiers inform future dispatches.

## Agent Self-Retro Triggers

Agents should run mini-retrospectives (write checkpoints to `.add/learnings.md`) automatically at these moments — NO human involvement needed:

1. **After /add:verify completes** — Record pass/fail, what was fixed
2. **After a TDD cycle completes** — Record velocity, spec quality, blockers
3. **After /add:deploy completes** — Record environment, smoke test results
4. **After /add:back processes an away session** — Record autonomous effectiveness
5. **After a full spec implementation** — Record overall feature learnings
6. **When a sub-agent error is caught** — Record the error and correction

These checkpoints accumulate between human retrospectives. The human reviews them with `/add:retro --agent-summary` or during a full `/add:retro`.

## Swarm Coordination Protocol

When a cycle plan calls for parallel feature work, the orchestrator follows this protocol:

### Conflict Assessment
Before dispatching parallel agents, assess file conflict risk:

1. Read specs for all parallel features
2. Identify implementation file paths from each spec
3. Build a conflict matrix — do any features touch the same files?
4. Classify each feature pair as:
   - **Independent** — no shared files → safe to parallelize
   - **Low conflict** — shared read-only files (imports, types) → parallelize with file reservations
   - **High conflict** — shared mutable files (same module, same DB migration) → serialize

### Git Worktree Strategy (Recommended for beta/ga maturity)

For parallel agents on independent features:

```
# Setup (orchestrator runs once)
git worktree add ../project-feature-auth feature/auth
git worktree add ../project-feature-billing feature/billing
git worktree add ../project-feature-onboarding feature/onboarding

# Each agent works in its own worktree
Agent A → ../project-feature-auth/
Agent B → ../project-feature-billing/
Agent C → ../project-feature-onboarding/

# Merge sequence (orchestrator manages)
1. Merge feature with most shared infrastructure first
2. Rebase remaining branches
3. Merge next feature
4. Repeat until all merged
```

### File Reservation Strategy (Simpler alternative for alpha maturity)

When worktrees are overkill (alpha maturity, 1-2 parallel agents):

```
RESERVATIONS:
  Agent A owns: src/auth/**, tests/auth/**
  Agent B owns: src/billing/**, tests/billing/**
  SHARED (serialize access): src/models/user.ts, src/db/migrations/**
```

Rules:
- Agents must not write to files outside their reservation
- Shared files require explicit handoff (Agent A finishes, then Agent B may modify)
- The orchestrator tracks reservations in the cycle plan

### WIP Limits

Work-in-progress limits prevent coordination overhead from exceeding parallelism benefit:

| Maturity | Max Parallel Agents | Max Features In-Progress | Max Cycle Items |
|----------|--------------------|--------------------------|-|
| poc | 1 | 1 | 2 |
| alpha | 2 | 2 | 4 |
| beta | 4 | 4 | 6 |
| ga | 5 | 5 | 6 |

If WIP limit is reached, new work must wait until an in-progress item is VERIFIED.

### Sub-Agent Brief Template

When dispatching a sub-agent for cycle work, provide this brief (keeps context focused):

```
## Agent Brief: {feature-name}

CYCLE: cycle-{N}
MILESTONE: M{N} — {milestone-name}
MATURITY: {level}

TASK: {what to do — e.g., "Advance from SPECCED to VERIFIED"}
SPEC: specs/{feature}.md
PLAN: docs/plans/{feature}-plan.md

FILE RESERVATIONS:
  OWNED: {files this agent may write}
  READ-ONLY: {files this agent may read but not modify}
  FORBIDDEN: {files owned by other agents}

LEARNINGS TO APPLY:
  Tier 1 (plugin-global): {relevant entries from knowledge/global.md}
  Tier 2 (user-local): {relevant entries from ~/.claude/add/library.md}
  Tier 3 (project): {relevant entries from .add/learnings.md}

QUALITY GATES (per maturity):
  {which gates must pass for this maturity level}

VALIDATION CRITERIA:
  {from cycle plan — what "done" means for this item}

REPORT BACK:
  STATUS: success | partial | blocked
  FILES_CHANGED: {list}
  TEST_RESULTS: {pass/fail counts}
  BLOCKERS: {if any}
```

### Merge Coordination

After parallel agents complete:

1. **Identify merge order** — feature touching shared infrastructure merges first
2. **Run integration tests** after each merge (not just after all merges)
3. **If merge conflict**: orchestrator resolves, re-runs affected agent's tests
4. **Final verification**: run full quality gates on merged main branch
5. **Update cycle status**: mark items as VERIFIED or flag failures

### Swarm State Coordination

When multiple agents work in parallel, coordinate via `.add/swarm-state.md`:

#### Claiming Work
Before starting, each agent writes a status block:
```
## {agent-role} ({timestamp})
status: active
claimed: {what this agent is working on — spec, files, scope}
depends-on: {other agent roles this work depends on, or "none"}
```

#### Reporting Results
After completing, the agent updates its block:
```
## {agent-role} ({timestamp})
status: complete
claimed: {scope}
result: {one-line summary of output}
blockers: {anything that prevented full completion, or "none"}
handoff: {what the next agent needs to know}
```

#### Rules
- Check swarm-state BEFORE claiming work — if another agent has claimed overlapping scope, coordinate or wait
- Status values: `active`, `complete`, `blocked`, `abandoned`
- The orchestrator clears swarm-state at the start of each new multi-agent operation
- Swarm-state is working state, not permanent record — cleared between cycles

#### Micro-Retro After Multi-Agent Operations

After ALL parallel agents complete and their work is merged, the orchestrator runs a micro-retro:

1. **Collect observations** — Read all `[agent-retro]` tagged entries from `.add/observations.md` written during this operation
2. **Synthesize** — Identify the single most impactful process insight from this batch of parallel work
3. **Record** — Append one synthesis entry to `.add/observations.md`:
   ```
   {YYYY-MM-DD HH:MM} | [agent-retro] | micro-retro | {operation name} | {synthesized process insight}
   ```
4. **Apply immediately** — If the insight is actionable for the current session (e.g., "Agent B's tests duplicated Agent A's — add file reservation check"), apply it to remaining dispatches

Micro-retros are lightweight — one observation, one insight. Full retrospectives happen during `/add:retro`.

### Anti-Patterns

- **Never** let two agents write to the same file simultaneously
- **Never** go deeper than 2 levels of agent hierarchy (orchestrator → worker)
- **Never** exceed WIP limits — coordination overhead grows exponentially
- **Never** dispatch sub-agents without reading all 3 knowledge tiers first
- **Never** merge without running integration tests after each merge
- **Avoid** parallel work at poc maturity — overhead exceeds benefit


---

## Rule: design-system

# ADD Rule: Design System

## Core Philosophy

**Value Over Features**
- Headlines describe outcomes, not capabilities
- "Ship Features in Hours" not "Fast Development Workflow"
- "Zero Production Incidents" not "Quality Gate System"
- Confident, aspirational language
- Premium visual design that signals quality

## Color Palette

### Dynamic Branding
Always read the accent color from `.add/config.json` → `branding.palette`:
```json
{
  "branding": {
    "palette": ["#b00149", "#d4326d", "#ff6b9d"]
  }
}
```

If no config exists, default to ADD's raspberry palette.

### Color System
- **Background Gradients**: #1a1a2e → #16213e → #0f0f23 (dark, sophisticated)
- **Accent Gradient**: Use branding palette array (3 stops: primary → mid → light)
  - Default (ADD raspberry): #b00149 → #d4326d → #ff6b9d
- **Success States**: #22c55e → #10b981
- **Text Primary**: #ffffff (pure white)
- **Text Secondary**: rgba(255,255,255,0.6) (60% white)
- **Text Muted**: rgba(255,255,255,0.3) (30% white)
- **Card Backgrounds**: rgba(255,255,255,0.08) → rgba(255,255,255,0.02)
- **Borders**: rgba(255,255,255,0.1)

## Typography

### Font Stacks
- **Body/UI**: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
- **Code**: "SF Mono", Monaco, "Cascadia Code", "Roboto Mono", monospace

### Type Scale
- **Hero Headlines**: 56px, weight 700, letter-spacing -2px
- **Section Headlines**: 36px, weight 700, letter-spacing -1px
- **Subheadlines**: 20px, weight 600
- **Body Text**: 14-16px, weight 400, line-height 1.6
- **Eyebrow Labels**: 14px, weight 600, letter-spacing 2px, uppercase
- **Metrics**: 28px, weight 700
- **Code**: 14px, monospace

### Text Rendering
- Use `dominant-baseline="middle"` for vertical centering
- Use `text-anchor="middle"` for horizontal centering
- Body text gets `text-anchor="start"`

## Glassmorphism

### Card Style
```svg
<rect rx="16"
      fill="url(#cardGradient)"
      stroke="rgba(255,255,255,0.08)"
      stroke-width="1"
      filter="url(#cardShadow)" />

<defs>
  <linearGradient id="cardGradient" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="rgba(255,255,255,0.08)" />
    <stop offset="100%" stop-color="rgba(255,255,255,0.02)" />
  </linearGradient>
  <filter id="cardShadow">
    <feDropShadow dx="0" dy="4" stdDeviation="4" flood-opacity="0.3" />
  </filter>
</defs>
```

### Visual Properties
- Corner radius: 16px (rx=16)
- Subtle gradient from 8% to 2% white
- 1px stroke at 8% white
- Drop shadow: 4px offset, 4px blur, 30% opacity
- Backdrop blur effect simulated via gradient

## Information Hierarchy

### Standard Layout Flow
1. **HERO** (y=0-200): Project name, tagline, key value prop
2. **METRICS** (y=240-400): 3-4 key numbers in horizontal row
3. **WORKFLOW** (y=440-700): Primary process diagram or timeline
4. **VALUE CARDS** (y=740-1100): 2-3 feature/benefit cards
5. **TERMINAL** (y=1140-1360): Code example or command preview
6. **FOOTER** (y=1400+): Powered by ADD, learn more link

### Spacing System
- Section gap: 40px minimum
- Card padding: 32px
- Metric spacing: 80px between items
- Text line-height: 1.6 for body, 1.2 for headlines

## SVG Rules

### GitHub Compatibility
- **Inline styles only** — GitHub strips `<style>` tags
- **System fonts** — No web fonts (GitHub blocks external resources)
- **No foreignObject** — Not reliably supported
- **viewBox standard**: 1200 width, height varies (typically 1400-1800)
- **Gradients/filters in defs** — Define once, reference via url(#id)

### SVG Structure
```svg
<svg viewBox="0 0 1200 1600" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- All gradients, filters, patterns here -->
  </defs>

  <!-- Background -->
  <rect width="1200" height="1600" fill="url(#bgGradient)" />

  <!-- Content sections (use <g> with transform for positioning) -->
  <g transform="translate(0, 0)"><!-- HERO --></g>
  <g transform="translate(0, 240)"><!-- METRICS --></g>
  <!-- etc -->
</svg>
```

### Text Handling
- Break long text into multiple `<tspan>` elements with dy offsets
- Use `<tspan x="600" dy="24">` for multi-line centered text
- Use `<tspan x="100" dy="24">` for left-aligned lists
- Reset x position on each new line

## Branding Integration

### Reading Config
Before generating any visual artifact, read `.add/config.json`:
```javascript
const config = JSON.parse(fs.readFileSync('.add/config.json'));
const palette = config.branding?.palette || ['#b00149', '#d4326d', '#ff6b9d'];
```

### Applying Accent Colors
```svg
<defs>
  <linearGradient id="accentGradient" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%" stop-color="${palette[0]}" />
    <stop offset="50%" stop-color="${palette[1]}" />
    <stop offset="100%" stop-color="${palette[2]}" />
  </linearGradient>
</defs>

<!-- Use on headlines, icons, key metrics -->
<text fill="url(#accentGradient)">Hero Headline</text>
```

### Branding Command
Generate infographics via `/add:infographic` (applies design system automatically).
Update branding via `/add:brand` (modifies config, regenerates artifacts).

## Maturity Awareness

### POC (Proof of Concept)
- Simpler infographic: HERO + METRICS + WORKFLOW only
- 2-3 metrics maximum
- Basic workflow diagram
- Total height ~900px
- Faster generation, less detail

### Alpha/Beta
- Standard full layout
- 3-4 metrics
- Full workflow + 2 value cards
- Terminal example
- Total height ~1400-1600px

### GA (General Availability)
- Premium treatment
- 4 metrics
- Detailed workflow
- 3 value cards with icons
- Terminal with syntax highlighting
- Footer with badges/links
- Total height ~1600-1800px

## HTML Reports

### Structure
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    /* Inline CSS — same color system as SVG */
    body { background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f0f23 100%); }
    .card { background: linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0.02)); }
  </style>
</head>
<body>
  <header><!-- Hero --></header>
  <section class="metrics"><!-- Key numbers --></section>
  <section class="details"><!-- Content cards --></section>
  <footer><!-- ADD branding --></footer>
</body>
</html>
```

### CSS System
- Use CSS custom properties for branding colors
- Responsive breakpoints: 768px, 1024px, 1440px
- Grid layout for metrics (repeat(auto-fit, minmax(200px, 1fr)))
- Flexbox for card internals
- Smooth transitions on hover (0.2s ease)

## Usage Examples

### Command Usage
```bash
# Generate infographic for project
/add:infographic

# Update branding colors
/add:brand

# Regenerate all visual artifacts after branding change
/add:infographic && npm run build:reports
```

### When to Apply
- **Automatically**: All generated SVG/HTML artifacts use this system
- **Manual review**: If user provides custom design, ask before overwriting
- **Consistency**: All visuals in one project should use same palette
- **Cross-project**: Each project's config controls its palette

## Quality Checklist

Before finalizing any visual artifact:
- [ ] Accent colors loaded from `.add/config.json`
- [ ] All gradients defined in `<defs>` block
- [ ] Text uses system fonts only
- [ ] No `<style>` tags (inline only for GitHub)
- [ ] viewBox dimensions match background rect
- [ ] Spacing follows 40px section gap rule
- [ ] Typography scale adhered to
- [ ] Glassmorphic cards use standard filter/gradient
- [ ] Maturity level appropriate complexity
- [ ] Passes GitHub rendering test (no stripped elements)

---

**Design Philosophy**: Confidence. Clarity. Premium quality. Every pixel reinforces that ADD is the methodology for serious teams shipping serious products.


---

## Rule: environment-awareness

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


---

## Rule: human-collaboration

# ADD Rule: Human-AI Collaboration Protocol

The human is the architect, product owner, and decision maker. Agents are the development team. This rule governs how they work together.

## Interview Protocol

When gathering requirements (during `/add:init`, `/add:spec`, or any discovery), follow the 1-by-1 interview format:

### Estimation First

Always state the scope before starting:

```
This will take approximately {N} questions (~{M} minutes).
```

Count your questions before asking the first one. Be honest — if it's 15 questions, say 15. The human decides if now is the right time.

### One at a Time

Ask ONE question, wait for the answer, then ask the next. Each question can build on previous answers, which produces far better specs than batched questionnaires.

```
Question 1 of ~8: Who is the primary user of this feature?
> [human answers]

Question 2 of ~8: Based on what you said about enterprise buyers,
what's their biggest pain point with existing tools?
> [human answers]
```

### Priority Ordering

Ask the most critical questions first. If the human says "that's enough, run with it" after question 5 of 10, you should have the essential information. Structure questions in this order:

1. **Who and Why** — User, problem, motivation (MUST have)
2. **What** — Core behavior, happy path (MUST have)
3. **Boundaries** — Scope limits, what's out (SHOULD have)
4. **Edge Cases** — Error handling, unusual scenarios (NICE to have)
5. **Polish** — Naming preferences, UX details (NICE to have)

### Defaults for Non-Critical Questions

For lower-priority questions, offer a sensible default:

```
Question 7 of ~8: What format should error messages take?
(Default: toast notifications that auto-dismiss after 5 seconds)
```

The human can just say "default" and move on.

### Question Complexity Check

Before asking each interview question, self-check:

1. **Count independent decisions** in the question. If the question asks the user to
   address 3 or more separate sub-decisions, split it into separate questions.
2. **One concept per question.** Each question should ask about ONE thing the user
   needs to decide. "What error types should we handle?" is one decision.
   "What error types should we handle, how should we detect paywalls, what about
   bot-blocking, and should multi-title statutes be linked?" is four decisions.
3. **When in doubt, split.** A question that takes 3+ sentences to explain is
   probably asking about multiple things. Split it.

**What splitting looks like:**

Bad (compressed):
```
Question 5 of 9: What should happen when things go wrong? Think about:
network timeouts, invalid API keys, rate limiting, malformed responses,
partial data, missing required fields, and concurrent edit conflicts.
```

Good (split):
```
Question 5 of 12: What should happen when an external API call fails
(timeout, 500 error, network unreachable)?

Question 6 of 12: Some APIs enforce rate limits. How should the
system handle throttling — retry, queue, or fail gracefully?

Question 7 of 12: What should happen when the API returns data
but required fields are missing or malformed?
```

A compressed question lets the agent choose defaults for sub-decisions the user
didn't explicitly address. Those defaults become spec requirements. A less
experienced PM may not realize they've implicitly agreed to simplifications.

### Confusion Protocol

When a user signals confusion during any interview question — "I don't understand",
"what do you mean?", "can you explain?", "I'm not sure", or any equivalent — follow
this exact sequence:

1. **Explain** the concept in plain language, without jargon. Translate technical
   implications to user impact ("what this means for you").
2. **Re-ask** the question using the `ask the user (use a clear, single-question prompt)` tool with simplified options
   that reflect the explanation. The structured popup forces a confirmed selection —
   the agent cannot proceed without the user clicking an answer.
3. **Wait** for the confirmed answer before moving to the next question.

**NEVER** do any of the following after a user signals confusion:
- Pick a default and say "unless you disagree" — that is not consent
- Proceed to the next question without a confirmed answer to this one
- Start generating output (spec, plan, code) with an unconfirmed answer
- Treat your own explanation as the user's agreement

Every answer in a spec interview becomes a binding requirement. An unconfirmed
answer means the spec — and everything built from it — rests on an assumption
the user never validated.

### Confirmation Gate

After the final interview question is answered — and BEFORE generating any output
(spec, PRD, plan) — present a summary of all captured answers for confirmation.

```
Here's what I captured from our interview:

1. Scope: {answer summary}
2. Users: {answer summary}
3. Happy path: {answer summary}
...
7. Output format: {answer summary} ← (agent-recommended default)

Any of these wrong? Reply "looks good" to proceed, or tell me
which number to change.
```

**Rules:**
- Mark any answer where the agent chose a default with a visible flag so the user
  can spot agent-chosen answers at a glance.
- Do NOT generate the spec/output until the user confirms the summary.
- If the user changes an answer, update the summary and re-confirm.

This is the last checkpoint before answers become spec requirements. It catches
misunderstandings, agent-assumed defaults, and anything the user's thinking has
evolved on since answering the original question.

### Cross-Spec Consistency Check

Before writing a new spec, scan all existing specs in `specs/` for:
- **Related ACs** — acceptance criteria that cover similar capabilities. Carry
  forward consistent patterns or flag intentional divergences.
- **Shared data model patterns** — entities or fields that overlap. Ensure naming
  and structure are consistent.
- **Conflicting requirements** — two specs that say contradictory things about the
  same behavior.

If conflicts or overlaps are found, present them to the user before generating
the spec. The user decides whether to align, diverge intentionally, or defer.

### Acknowledge Thoroughness

When the human invests time answering all questions:

```
Thanks for the thorough answers. This gives me enough
for a high-confidence spec — the acceptance criteria and
test cases will be much tighter because of it.
```

## Engagement Modes

Different situations call for different interaction patterns. Recognize which mode you're in.

### Spec Interview (Deep)
- **When:** Project init, new feature, major change
- **Duration:** 10-20 questions, ~10-15 minutes
- **Output:** PRD or feature spec
- **Human commitment:** Block 15 minutes, give full attention

### Quick Check (Lightweight)
- **When:** Mid-implementation clarification
- **Duration:** 1-2 questions
- **Output:** Decision to unblock work
- **Format:** "Should this return 404 or empty array for no results?"

### Decision Point (Structured)
- **When:** Multiple valid approaches, need human to choose
- **Duration:** 1 question with 2-3 options
- **Output:** Direction chosen
- **Format:** Present options with tradeoffs, not open-ended questions
  ```
  I see two approaches:
  A) Redis cache — faster but adds infrastructure dependency
  B) In-memory LRU — simpler but lost on restart
  Which direction?
  ```

### Review Gate (Approval)
- **When:** Work complete, needs human sign-off before merge/deploy
- **Duration:** Summary + yes/no
- **Output:** Approval to proceed
- **Format:** Show summary, not full diff. "Auth middleware complete: 14 tests, spec compliant, 3 new files. Ready to commit?"

### Status Pulse (Informational)
- **When:** Long-running work, especially during away mode
- **Duration:** No response needed
- **Format:** Brief progress update. "Hour 2 of 4: auth middleware done, starting user service. On track."

## Away Mode

When the human declares absence with `/add:away`:

### Receive the Handoff
- Acknowledge the duration
- Present a work plan: what you'll do autonomously vs. what you'll queue for their return
- Get confirmation before they leave

### During Absence

Away mode grants elevated autonomy. The human is unavailable — do not wait for input on routine development tasks.

**Autonomous (proceed without asking):**
- Commit and push to feature branches (conventional commit format)
- Create PRs (human reviews when they return)
- Run and fix quality gates (lint, types, formatting)
- Run test suites, install dev dependencies
- Read specs, plans, and PRD to stay aligned — re-read `docs/prd.md` whenever validating a decision
- Promote through environments following the promotion ladder (see environment-awareness rule) — if verification passes at one level and `autoPromote: true` for the next, deploy there. Rollback automatically on failure.

**Boundaries (queue for human return):**
- Do NOT deploy to production or any environment where `autoPromote: false`
- Do NOT merge to main
- Do NOT start features without specs
- Do NOT make irreversible changes or architecture decisions with multiple valid approaches
- If ambiguous after reading the PRD, log the question and skip to the next task

**Discipline:**
- ONLY work on tasks from the approved plan
- Maintain a running log of completed work and pending decisions
- Send status pulses at reasonable intervals (not every 5 minutes)

### Return Briefing (via `/add:back`)
- Summarize what was completed (with test results)
- List pending decisions that need human input
- Flag any issues or blockers discovered
- Suggest next priorities

## Autonomy Levels

The human's autonomy preference is set in `.add/config.json` during init. Three levels:

### Guided (default for new projects)
- Ask before starting each feature
- Confirm spec interpretation before coding
- Review gate before every commit

### Balanced (recommended for established projects)
- Work autonomously within a spec's scope
- Quick check only for ambiguous requirements
- Review gate before PR, not every commit

### Autonomous (for trusted, well-specced projects)
- Execute full TDD cycles without check-ins
- Only stop for true blockers or missing specs
- Review gate at PR level only

## Anti-Patterns

- NEVER batch 5+ questions in a single message
- NEVER ask questions you can answer from the spec or PRD
- NEVER ask "is this okay?" without showing what "this" is
- NEVER continue working after the human said they're stepping away without presenting the away-mode work plan first
- NEVER present technical implementation details to get product decisions — translate to user impact
- NEVER compress 3+ independent decisions into a single interview question (see Question Complexity Check)
- NEVER proceed after "I don't understand" without re-asking via `ask the user (use a clear, single-question prompt)` and getting a confirmed answer (see Confusion Protocol)
- NEVER say "unless you disagree" or "if that works for you" as a substitute for asking — soft opt-outs are not consent
- NEVER generate a spec without presenting the answer summary for confirmation (see Confirmation Gate)
- NEVER write a new spec without checking existing specs for related ACs, shared patterns, or conflicts (see Cross-Spec Consistency Check)


---

## Rule: learning

# ADD Rule: Continuous Learning

Agents accumulate knowledge through structured JSON checkpoints. Knowledge is organized in three tiers, filtered by relevance, and consumed by all agents before starting work.

## Knowledge Tiers

ADD uses a 3-tier knowledge cascade. Agents read all three tiers before starting work, with more specific tiers taking precedence:

| Tier | JSON (primary) | Markdown (generated view) | Scope | Who Updates |
|------|----------------|--------------------------|-------|-------------|
| **Tier 1: Plugin-Global** | — | `~/.codex/add/knowledge/global.md` | Universal ADD best practices for all users | ADD maintainers only |
| **Tier 2: User-Local** | `~/.claude/add/library.json` | `~/.claude/add/library.md` (generated) | Cross-project wisdom accumulated by this user | Auto-checkpoints + `/add:retro` |
| **Tier 3: Project-Specific** | `.add/learnings.json` | `.add/learnings.md` (generated) | Discoveries specific to this project | Auto-checkpoints + `/add:retro` |

**Precedence:** Project-specific (Tier 3) > User-local (Tier 2) > Plugin-global (Tier 1). If a project learning contradicts a global learning, the project learning wins for that project.

**Dual format:** JSON is the primary storage — skills read and write JSON. Markdown is a human-readable view regenerated from JSON after each write. If JSON doesn't exist but markdown does, treat as pre-migration state and suggest running migration (see Migration section).

## Read Before Work

Before starting ANY skill or command (except `/add:init`), read knowledge and filter for relevance:

1. **Tier 1:** Read `~/.codex/add/knowledge/global.md` (always exists — ships with ADD)
2. **Tier 2:** Read `~/.claude/add/library.json` if it exists. Filter entries by relevance (see Smart Filtering below). If only `library.md` exists, read it as fallback.
3. **Tier 3:** Read `.add/learnings.json` if it exists. Filter entries by relevance. If only `learnings.md` exists, read it as fallback.
4. **Handoff:** Read `.add/handoff.md` if it exists — note in-progress work relevant to this operation.

If JSON files don't exist or are empty (`{"entries":[]}`), proceed silently — no error, no message.

## Smart Filtering

When reading JSON learning files, don't surface everything. Filter by relevance to the current operation:

### Step 1: Stack Filter

Read `.add/config.json` to get the project's stack:
- `architecture.languages[].name` (lowercased)
- `architecture.backend.framework` (lowercased, if not null)
- `architecture.frontend.framework` (lowercased, if not null)

An entry passes the stack filter if:
- Its `stack` array has ANY overlap with the project's stack, OR
- Its `stack` array is empty (stack-agnostic — always passes)

### Step 2: Category Filter

Each skill/command maps to relevant learning categories:

| Skill/Command | Relevant Categories |
|---------------|-------------------|
| `/add:plan` | architecture, anti-pattern, collaboration |
| `/add:tdd-cycle` | technical, anti-pattern, performance |
| `/add:test-writer` | technical, anti-pattern |
| `/add:implementer` | technical, anti-pattern, architecture |
| `/add:deploy` | performance, technical, process |
| `/add:verify` | technical, process |
| `/add:optimize` | performance, technical |
| `/add:reviewer` | architecture, anti-pattern, process |
| `/add:cycle` | architecture, collaboration, process |
| `/add:retro` | process, collaboration |
| `/add:spec` | architecture, collaboration |
| (other/unknown) | all categories (no filter) |

An entry passes the category filter if its `category` matches any relevant category for the current operation.

### Step 3: Rank and Cap

1. **Rank** matching entries: `critical` > `high` > `medium` > `low`, then by date (newest first)
2. **Cap** at 10 entries maximum per skill invocation to prevent context bloat
3. If no entries match, proceed silently — no "no learnings found" message

### Step 4: Surface

Present the top entries to the agent as context. Format:

```
RELEVANT LEARNINGS ({N} entries):
  [{severity}] {title} (from {source}, {date})
    {body}
```

The agent should incorporate these learnings into its work — e.g., avoiding known anti-patterns, following proven architecture decisions.

## Learning Entry Schema

All learning entries (Tier 2 and Tier 3) use a structured JSON format:

```json
{
  "id": "L-001",
  "title": "Short summary (one line)",
  "body": "Full learning text with context and actionable detail.",
  "scope": "project",
  "stack": ["python", "fastapi"],
  "category": "technical",
  "severity": "medium",
  "source": "project-name",
  "date": "2026-02-17",
  "classified_by": "agent",
  "checkpoint_type": "post-verify"
}
```

**Required fields:**

| Field | Type | Values |
|-------|------|--------|
| `id` | string | `L-{NNN}` (project-scope) or `WL-{NNN}` (workstation-scope), auto-incrementing |
| `title` | string | Short summary, one line |
| `body` | string | Full learning text |
| `scope` | enum | `project` \| `workstation` \| `universal` |
| `stack` | string[] | Lowercase tech identifiers. Empty array = stack-agnostic |
| `category` | enum | `technical` \| `architecture` \| `anti-pattern` \| `performance` \| `collaboration` \| `process` |
| `severity` | enum | `critical` \| `high` \| `medium` \| `low` |
| `source` | string | Project name where the learning originated |
| `date` | string | ISO 8601 date (YYYY-MM-DD) |

**Optional fields:**

| Field | Type | Values |
|-------|------|--------|
| `classified_by` | string | `agent` (auto-classified) or `human` (reclassified during retro) |
| `checkpoint_type` | string | `post-verify` \| `post-tdd` \| `post-deploy` \| `post-away` \| `feature-complete` \| `verification-catch` \| `retro` |

**File wrapper:**

```json
{
  "$schema": "https://github.com/MountainUnicorn/add/learnings.schema.json",
  "version": "1.0.0",
  "project": "{project-name or _workstation}",
  "entries": [ ... ]
}
```

## Scope Classification

When writing a learning entry, the agent MUST classify its scope before choosing the target file.

### Classification Rules

| Signal in the learning text | Inferred Scope | Target File |
|-----------------------------|---------------|-------------|
| References specific files, tables, schemas, routes, or config unique to this project | `project` | `.add/learnings.json` |
| References a library, framework, or tool used across projects with the same stack | `workstation` | `~/.claude/add/library.json` |
| References methodology, process, or collaboration patterns independent of any stack | `universal` | `~/.claude/add/library.json` (flagged for future org/community promotion) |
| Unclear or ambiguous | `project` | `.add/learnings.json` (can be promoted during retro) |

### Classification Process

1. Read the learning text
2. Ask: "Does this reference anything specific to THIS project's codebase?" → If yes: `project`
3. Ask: "Does this reference a library/framework pattern useful in OTHER projects with the same stack?" → If yes: `workstation`
4. Ask: "Is this a process/methodology insight independent of tech stack?" → If yes: `universal`
5. Default: `project` (conservative — easier to promote later than to demote)

Set `classified_by` to `"agent"` for auto-classification. During `/add:retro`, the human can override scope and the field changes to `"human"`.

## Checkpoint Triggers

Agents automatically write structured JSON entries at these moments. No human involvement needed.

### How to Write a Checkpoint Entry

1. **Classify scope** using the rules above
2. **Read the target JSON file** (`.add/learnings.json` or `~/.claude/add/library.json`)
3. If the file doesn't exist, create it with the wrapper structure and an empty `entries` array
4. **Determine the next ID**: find the highest existing `L-{NNN}` or `WL-{NNN}`, increment by 1
5. **Append** the new entry to the `entries` array
6. **Write** the updated JSON file
7. **Regenerate** the corresponding markdown view (see Markdown View Generation)

### After Verification (`/add:verify` completes)

```json
{
  "id": "L-{NNN}",
  "title": "{gate passed cleanly | gate failure: {which gate}}",
  "body": "{Root cause and fix if failure, or 'routine clean pass' if success. Include prevention notes.}",
  "scope": "{classify}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "{critical if production-affecting, high if required fix, medium if minor, low if clean pass}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-verify"
}
```

### After TDD Cycle Completes

```json
{
  "id": "L-{NNN}",
  "title": "{spec name}: {summary of cycle outcome}",
  "body": "ACs covered: {list}. RED: {N} tests. GREEN: {pass details}. Blockers: {any}. Spec quality: {assessment}.",
  "scope": "{classify}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "{high if blockers or rework, medium if clean, low if routine}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-tdd"
}
```

### After Away-Mode Session

```json
{
  "id": "L-{NNN}",
  "title": "Away session: {N}/{N} tasks completed",
  "body": "Duration: {planned} → {actual}. Completed: {list}. Blocked: {list with reasons}. Effectiveness: {%}. Would have helped: {notes}.",
  "scope": "project",
  "stack": [],
  "category": "process",
  "severity": "{high if low effectiveness, medium otherwise}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-away"
}
```

### After Spec Implementation Completes

```json
{
  "id": "L-{NNN}",
  "title": "Feature complete: {feature name}",
  "body": "Total ACs: {N}. TDD cycles: {N}. Rework: {N}. Spec revisions: {N}. What went well: {text}. What to improve: {text}. Patterns: {text}.",
  "scope": "{classify}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "medium",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "feature-complete"
}
```

### After Deployment

```json
{
  "id": "L-{NNN}",
  "title": "Deploy to {environment}: {passed|issues found}",
  "body": "Smoke tests: {result}. Issues: {details or none}. Notes: {anything notable}.",
  "scope": "{classify — deployment issues are often workstation-level}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "{critical if prod issues, high if staging issues, medium if clean}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-deploy"
}
```

### When Verification Catches Sub-Agent Error

```json
{
  "id": "L-{NNN}",
  "title": "Verification catch: {agent} — {error summary}",
  "body": "Agent: {test-writer|implementer|other}. Error: {what went wrong}. Correct approach: {what should have been done}. Pattern to avoid: {generalized lesson}.",
  "scope": "{classify — often workstation-level since agent patterns repeat}",
  "stack": ["{from config}"],
  "category": "anti-pattern",
  "severity": "high",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "verification-catch"
}
```

## Checkpoint Format Rules

- Keep `body` concise (2-4 sentences max)
- Always include a reference to the spec, file, or feature
- Focus on ACTIONABLE insights, not observations
- Don't duplicate — if the same lesson already exists (check by title similarity), don't add it
- Infer `stack` from `.add/config.json` — don't hardcode or guess

## PII Heuristic — Pre-Write Check

Before writing ANY learning entry to `.add/learnings.json` or `~/.claude/add/library.json`, scan the candidate `title` and `body` for likely PII or secret patterns. If any match, halt the write and surface a warning.

### Patterns to detect

| Category | Regex | Example match |
|---|---|---|
| Email address | `\b[\w.+-]+@[\w-]+\.[\w.-]+\b` | `alice@example.com` |
| IPv4 (non-local) | `\b(?!10\.)(?!127\.)(?!192\.168\.)(?!172\.(?:1[6-9]\|2\d\|3[01])\.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b` | `34.117.88.9` (not `10.0.0.1`, `127.0.0.1`, or RFC1918) |
| Bearer / API-key-like | `\b(?:sk-\|pk-\|xoxb-\|xoxp-\|ghp_\|gho_\|ghs_\|glpat-\|AIza\|AKIA)[A-Za-z0-9_-]{16,}` | `sk-proj-abc123...`, `ghp_...`, `AKIA...`, `AIza...` |
| JWT-like token | `\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b` | `eyJhbGciOiJI...` |
| Private key header | `-----BEGIN (?:RSA\|EC\|OPENSSH\|PGP) PRIVATE KEY-----` | literal header |
| Password-like kv | `\b(?:password\|passwd\|secret\|token\|api[_-]?key)["':=\s]+['"]?[\w\-/.+=]{8,}` | `password="hunter2-long"` |
| Cloud resource ID | `\b(?:arn:aws:[\w:-]+:\d{12}:\|projects/[\w-]+/secrets/\|gs://[\w-]+/\|s3://[\w-]+/)` | `arn:aws:iam::123456789012:...` |

### Response to a match

**Halt the learning write.** Print:

```
⚠ PII HEURISTIC — potential sensitive data detected in learning entry

  Entry title: "{title}"
  Matched pattern: {category} — "{matched_substring}"

Learning checkpoints are committed to git. Once a secret is in history, it
is non-trivial to fully remove. Options:

  [r] Rewrite the entry without the sensitive value (recommended)
  [o] Override — write the entry as-is (logged as compliance-bypass)
  [s] Skip — don't write this learning at all

Response:
```

On `r`: present the entry with the matched substring replaced by `«REDACTED»` for the user to confirm before write.
On `o`: write as-is, AND add a second learning entry with `checkpoint_type: "compliance-bypass"` noting the bypass. Bypass entries count against the `--force-no-retro`-style abuse detection in `add-compliance.md`.
On `s`: do not write; continue.

### What's NOT checked (explicitly out of scope)

- **Prose that merely mentions concepts** like "rotate api keys quarterly" — the pattern requires a value-like match, not the keyword alone.
- **Internal code identifiers** (variable names, DB column names) — those are fine; only values with entropy/prefix patterns match.
- **Test fixtures** with obvious dummy values like `example.com`, `test@test.test`, `AKIAIOSFODNN7EXAMPLE` (AWS docs example) — the heuristic is best-effort, not a secrets scanner. Use `detect-secrets` or `gitleaks` for real secrets scanning.

This is an ergonomic guardrail against accidental leaks in learning-style writing, not a security control. Skills that process production data should still run proper secret-scanning in CI.

## Markdown View Generation

After writing any entry to a JSON learnings file, regenerate the corresponding markdown file:

**For `.add/learnings.json` → `.add/learnings.md`:**

```markdown
# Project Learnings — {project name}

> **Tier 3: Project-Specific Knowledge**
> Generated from `.add/learnings.json` — do not edit directly.
> Agents read JSON for filtering; this file is for human review.

## Anti-Patterns
{entries where category = "anti-pattern", sorted by date descending}
- **[{severity}] {title}** (L-{NNN}, {date})
  {body}

## Technical
{entries where category = "technical"}

## Architecture
{entries where category = "architecture"}

## Performance
{entries where category = "performance"}

## Process
{entries where category = "process"}

## Collaboration
{entries where category = "collaboration"}

---
*{N} entries. Last updated: {date}. Source: .add/learnings.json*
```

**For `~/.claude/add/library.json` → `~/.claude/add/library.md`:**

Same format but with header:

```markdown
# ADD Cross-Project Knowledge Library

> **Tier 2: User-Local Knowledge**
> Generated from `~/.claude/add/library.json` — do not edit directly.
> Entries are auto-classified by scope: workstation or universal.
```

Omit empty categories (don't show a heading with no entries).

## Migration from Markdown

For projects with existing freeform `.add/learnings.md` or `~/.claude/add/library.md` that haven't been migrated to JSON:

### Detection

If a skill reads a `.md` learnings file and no corresponding `.json` exists, suggest migration:
"Learnings are in legacy markdown format. Run migration to enable smart filtering and scope classification."

### Migration Steps

1. **Backup** the original markdown file (copy to `.add/learnings.md.bak` or `~/.claude/add/library.md.bak`)
2. **Parse** each entry from the markdown (checkpoint blocks, bullet points, sections)
3. **Classify** each entry — infer tags from the text:
   - `scope`: Use classification rules above. Default to `project` if unclear.
   - `stack`: Extract technology names mentioned. Default to empty array if unclear.
   - `category`: Match against category enum based on content. Default to `technical`.
   - `severity`: `critical` if mentions production failures/data loss, `high` if mentions bugs/rework, `medium` for general insights, `low` for routine observations.
   - `source`: Use the project name from config, or extract from "Source: {name}" if present.
4. **Assign IDs**: `L-001`, `L-002`, etc. for project-scope; `WL-001`, etc. for workstation-scope.
5. **Write** the JSON file with all entries
6. **Regenerate** the markdown view from JSON
7. **Verify** the regenerated markdown contains all original content (may be reorganized by category)

### Migration is Non-Destructive

- Original files are preserved as `.bak`
- If migration produces bad results, delete the JSON and rename `.bak` back
- Migration can be re-run after manual corrections

## Knowledge Promotion

Learnings flow upward through the tiers during retrospectives.

### Tier 3 → Tier 2 (Project → User Library)

During `/add:retro`, entries in `.add/learnings.json` with scope `workstation` or `universal` are candidates for promotion to `~/.claude/add/library.json`.

**Promote when:**
- A pattern applies across projects (not tied to a specific codebase)
- A technical insight transfers to other stacks or contexts
- An anti-pattern would be harmful in any project

**Process:** Agent flags candidates. Human confirms. On approval:
1. Copy entry to `~/.claude/add/library.json` with new `WL-{NNN}` ID
2. Remove from `.add/learnings.json`
3. Regenerate both markdown views

### Tier 2/3 → Tier 1 (User/Project → Plugin-Global)

The highest bar. Plugin-global knowledge ships to ALL ADD users.

**Promote when:**
- Universal — applies regardless of stack, team size, or project type
- Reflects an ADD methodology truth (not a tech stack preference)
- Validated across multiple projects or users

**Do NOT promote:** Technology preferences, stack patterns, project constraints, user preferences.

**Process:** Only the ADD development project can write to `knowledge/global.md`. During `/add:retro` in the ADD project itself, the retro flow includes a "promote to plugin-global" step. In consumer projects, `knowledge/global.md` is read-only.

## Session Handoff Protocol

Agents MUST write `.add/handoff.md` **automatically** — never wait for the human to ask. Handoffs are a background bookkeeping task, not a user-facing action.

### Auto-Write Triggers

Write/update the handoff silently after any of these events:

1. **After completing a major work item** — spec, plan, implementation, or feature marked done
2. **After a commit** — the commit represents a state change worth capturing
3. **When context is getting long** — 20+ tool calls, 10+ files read, 30+ turns
4. **When switching work streams** — pivoting to a different area of work
5. **When the user departs** — `/add:away` or explicit session end

The agent writes the handoff as a natural final step, the same way it would stage files for a commit. No announcement needed unless context is the trigger (in which case, briefly note: "Writing session handoff to `.add/handoff.md`.").

### Handoff Format

```
# Session Handoff
**Written:** {timestamp}

## In Progress
- {what was being worked on, with file paths and step progress}

## Completed This Session
- {what got done, with commit hashes if applicable}

## Decisions Made
- {choices made this session with brief rationale}

## Blockers
- {anything that's stuck or needs human input}

## Next Steps
1. {prioritized list of what should happen next}
```

### Rules

- Handoff replaces the previous one (current state, not append-only)
- Keep under 50 lines — this is a summary, not a transcript
- All ADD skills MUST read `.add/handoff.md` at the start of execution if it exists
- `/add:back` reads handoff as part of the return briefing
- **Never ask** the human "should I update the handoff?" — just do it

## Knowledge Store Boundaries

Each store has a single purpose. Do not cross-pollinate:

| Store | Format | Purpose | NOT for |
|-------|--------|---------|---------|
| `CLAUDE.md` | Markdown | Project architecture, tech stack, conventions | Session state, learnings, observations |
| `.add/learnings.json` | JSON | Domain facts — framework quirks, API gotchas (project-scope) | Process observations, session state |
| `.add/learnings.md` | Markdown | Generated human-readable view of learnings.json | Direct editing (regenerated from JSON) |
| `~/.claude/add/library.json` | JSON | Cross-project wisdom (workstation + universal scope) | Project-specific knowledge |
| `~/.claude/add/library.md` | Markdown | Generated human-readable view of library.json | Direct editing (regenerated from JSON) |
| `.add/observations.md` | Markdown | Process data — what happened, what it cost | Domain facts, architecture |
| `.add/handoff.md` | Markdown | Current session state — in progress, next steps | Permanent knowledge |
| `.add/decisions.md` | Markdown | Architectural choices with rationale | Transient session state |
| `.add/mutations.md` | Markdown | Process evolution — approved workflow changes | Domain facts |

During `/add:retro`, identify entries in the wrong store and relocate them.

**Knowledge tier roadmap:**
- **Tier 1: Plugin-Global** (`knowledge/global.md`) — universal ADD best practices (exists)
- **Tier 2: User-Local** (`~/.claude/add/library.json`) — cross-project user wisdom (exists)
- **Tier 3: Collective** — team/org shared learnings (future)
- **Tier 4: Community** — all ADD users, crowd-sourced (future)

Precedence: project > install > collective > community. More specific wins.


---

## Rule: maturity-lifecycle

# ADD Rule: Maturity Lifecycle

This rule defines how ADD adapts to your project's stage of development. **It takes precedence over all other rules.** When maturity-lifecycle conflicts with another rule, maturity wins.

## Maturity Levels

### POC (Proof of Concept)
A project exploring viability. Time-boxed, high uncertainty, goal is to validate a core idea or remove a critical unknown. Success = learning, not completeness.

### Alpha
Early-stage, building toward an MVP. Core concept validated. Moving toward product-market fit. Scaling up safety incrementally. Success = surviving first real usage.

### Beta
Shipping to broader audiences. Feature-complete for 1.0. Reducing defect density and improving reliability. Focus on stabilization and quality. Success = reliable, predictable product.

### GA (General Availability)
Production-grade, long-term support expected. High stability demands. Change velocity slows. Deep safety protocols. Focus on sustainability and scale. Success = trusted, reliable infrastructure.

---

## Cascade Matrix: Maturity Controls Everything

| Dimension | POC | Alpha | Beta | GA |
|-----------|-----|-------|------|-----|
| **PRD Depth** | Paragraph (problem + hypothesis) | 1-pager (problem, solution, success metrics) | Full template (PRD: goals, specs, roadmap, audience, constraints) | Full template + detailed architecture, scalability model, migration path |
| **Specs Required** | No | Critical paths only (e.g., auth, core loops) | Yes (all user-facing features + acceptance criteria) | Yes + exhaustive acceptance criteria + user test scenarios |
| **TDD Enforced** | Optional (but recommended) | Critical paths mandatory | Yes, strict policy | Strict no exceptions (100% coverage of modified paths) |
| **Quality Gates Active** | Pre-commit lint only | Pre-commit + basic CI (lint, unit tests) | Pre-commit + full CI + pre-deploy QA | All 5 levels: pre-commit, CI, pre-deploy, deploy monitoring, SLA monitoring |
| **Commit Discipline** | Freeform (WIP, experiment ok) | Conventional commits (feat:/fix:/docs:) | Conventional + spec references (#spec-{id}) | Conventional + spec refs + PR mandatory + auto-linked tickets |
| **Reviewer Agent** | Skip (solo agent ok) | Optional (recommended for risky PRs) | Recommended (code review on all changes) | Mandatory (two reviewers, one from stability team) |
| **Environment Tier Ceiling** | Tier 1 (local, dev) | Tier 1-2 (dev, staging) | Tier 2 (staging only, no prod changes) | Tier 2-3 (staging + production, with deploy checks) |
| **Away Mode Autonomy** | Full autonomy (agent decides scope/pace) | High autonomy (agent plans, few checkpoints) | Balanced (plan reviewed, execute autonomous, verify with human) | Guided with checkpoints (human approval at cycle start + completion, daily standups) |
| **Interview Depth** | ~5 questions (fast exploration) | ~8 questions (clarify core assumptions) | ~12 questions (understand user stories deeply) | ~15 questions (exhaustive acceptance criteria validation) |
| **Milestone Docs Required** | No (PRD paragraph enough) | Lightweight (M{N} title, goal, 3 features) | Yes, full template (goal, appetite, hill chart, risks, cycles) | Yes, full template + hill chart tracked daily + risk reassessment per cycle |
| **Cycle Planning** | Informal (ad-hoc batching) | Brief cycle doc (work items + priorities) | Full cycle plan (features, dependencies, parallelism, validation) | Full plan + risk assessment + parallel agent coordination + WIP limits |
| **Features Per Cycle** | 1-2 (rapid iteration) | 2-4 (bounded scope) | 3-6 (balanced execution) | 3-6 with strict WIP limits (ensures quality focus) |
| **Parallel Agents** | 1 serial (one agent at a time) | 1-2 agents (minimal serialization) | 2-4 agents (worktree isolation, file reservations) | 3-5 agents (strict worktree isolation, merge coordination, merge sequence docs) |
| **Code Quality Checks** | Lint only | Lint errors blocking | + complexity >15, duplication >10 lines, file >500, function >80 — advisory | Tighter thresholds (10/6/300/50), all blocking |
| **Security & Vulnerability** | Not checked | Secrets scan blocking, OWASP spot-check advisory | + dependency audit, full OWASP, auth patterns, PII handling — advisory | All blocking, CVEs blocking, rate limiting + secure headers required |
| **Readability & Documentation** | Not checked | Naming consistency advisory | + nesting <5, docstrings on exports, complex logic comments, magic numbers — advisory | All blocking, module READMEs, glossary, nesting <4 |
| **Performance Checks** | Not checked | Not checked | N+1 detection, blocking async, bundle size, memory patterns — advisory | All blocking, perf tests required, response time baselines |
| **Repo Hygiene** | Not checked | Branch naming advisory, .gitignore exists | + stale branches, LICENSE, CHANGELOG, dependency freshness, README, PR template — advisory | All blocking, 14-day stale limit, comprehensive README |

---

## Work Hierarchy: Roadmap → Milestones → Cycles → Features → Tasks

The structure that governs all ADD work:

### Roadmap
**Location:** PRD, `## Roadmap` section  
**Framing:** Now / Next / Later (no fake dates, no hard commitments)

Each roadmap entry = milestone placeholder:
- **Name:** M{N} — {SHORT_NAME}
- **Goal:** 1-2 sentences of what "done" looks like
- **Success Criteria:** 3-5 checkboxes (not estimates, completion signals)
- **Target Maturity:** The maturity level this milestone advances toward
- **Effort Appetite:** How much runway we burn (e.g., "2 weeks" not "3 commits")

### Milestones
**Location:** `docs/milestones/M{N}-{name}.md`  
**Ownership:** Human (primary roadmap driver) + agents (execution)

Milestones are the container for related features. Each milestone:
- **Goal & Success Criteria:** Clear definition of done
- **Appetite:** Budget (not estimate) for completing the milestone
- **Hill Chart:** Visual progress map (see below for format)
- **Features:** Linked list with position tracking (SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE)
- **Dependencies:** What must come first from other milestones
- **Risks:** Known challenges with mitigation plans
- **Cycles:** Batches of work (see below)
- **Retrospective:** Filled in at completion — learnings to capture

### Hill Chart Positions
Features move through these positions as they progress:

1. **SHAPED** — Idea is roughed out, knows basic problem/solution, uncertain on scope/approach
2. **SPECCED** — Behavior fully specified, acceptance criteria written, design sketched
3. **PLANNED** — Assigned to a cycle, dependencies mapped, effort estimated
4. **IN_PROGRESS** — Active work, code/tests advancing, open PRs
5. **VERIFIED** — Code complete, tests pass, acceptance criteria checked, QA signed off
6. **DONE** — Merged to main, deployed to ceiling tier, milestone chart updated

**Hill Metaphor:** Uphill = figuring it out (SHAPED → SPECCED). Downhill = executing (PLANNED → DONE).

### Cycles
**Location:** `.add/cycles/cycle-{N}.md`  
**Ownership:** Agents (planning + execution)

A cycle is the next batch of work before human checkpoint. It picks features from the current milestone, assesses dependencies, plans parallelism, and defines validation criteria.

Each cycle:
- **Work Items:** Features + target positions + effort estimates
- **Dependency Graph:** Which items must serialize (blocked by what)
- **Parallel Strategy:** Which items can run simultaneously, file reservations, merge sequence
- **Validation Criteria:** Per-item acceptance, overall cycle success signals
- **Cycle Success Criteria:** What "done" means for this cycle (all items verified, QA passed, etc.)

**Cycle Length:** Varies by maturity:
- POC/Alpha: 1-2 days (rapid iteration, fast checkpoints)
- Beta: 3-5 days (balanced execution, mid-cycle review)
- GA: 5-7 days (deeper testing, slower deliberation)

### Features
**Location:** `specs/{feature}.md`  
**Ownership:** Agents (implementation) + human (acceptance)

Existing ADD concept. Specs define:
- **User Story:** Who, what, why
- **Acceptance Criteria:** Testable conditions (especially important in Beta/GA)
- **Edge Cases:** Known gotchas
- **Test Scenarios:** User test cases (Beta/GA only)

### Tasks
**Location:** TDD cycle execution (inside the feature's test suite)  
**Ownership:** Agents

Existing ADD concept. Tasks emerge from test-first cycles:
- Each failing test = a task to make it pass
- Red → Green → Refactor loop drives discovery

---

## Maturity Promotion: Leveling Up

Moving from one maturity level to the next is **intentional and deliberate.** It's not automatic.

### When to Promote
- **POC → Alpha:** Core idea validated, first users engaged, product is stable enough for feedback
- **Alpha → Beta:** MVP feature-complete, early adopters find it reliable, ready for broader use
- **Beta → GA:** Defect rate below threshold, 30+ days production stability, SLAs defined and met

### Promotion Process
1. Trigger: `/add:cycle --complete` suggests promotion, or `/add:retro` recommends it
2. **Gap Analysis:** Compare project state against target maturity checklist:
   - Are all required docs in place? (PRD, specs, milestones)
   - Are quality gates configured? (CI, pre-deploy, monitoring)
   - Is test coverage sufficient? (% coverage target by maturity)
   - Is team process aligned? (reviewer discipline, cycle discipline)
3. **Promotion Milestone:** Create a special milestone (M{N} — "Maturity → {TARGET}") that captures:
   - Missing pieces from the gap analysis
   - New practices to adopt (e.g., introducing 2-reviewer policy)
   - Runbook changes (escalation paths, on-call setup)
4. **Execution:** Complete the promotion milestone in 1-2 cycles
5. **Update Config:** Write `.add/config.json` maturity field to new level

### Precedent
Promotion milestones are treated like any other milestone: they advance the project toward GA stability.

---

## Reading the Room: Context Awareness

**Before any significant action, agents check `.add/config.json` maturity field.**

Example behavior shifts:

```json
{
  "maturity": "poc"
}
```
→ **Agent mindset:** Move fast, ask forgiveness not permission, skip reviews, TDD is "nice to have"

```json
{
  "maturity": "alpha"
}
```
→ **Agent mindset:** Plan ahead, flag blockers early, TDD on critical paths, expect async review

```json
{
  "maturity": "beta"
}
```
→ **Agent mindset:** Comprehensive specs, full TDD, all PRs reviewed, pre-deploy QA, parallel features OK

```json
{
  "maturity": "ga"
}
```
→ **Agent mindset:** Move deliberately, two reviewers, SLA monitoring, deployment planning, risk assessment per change

### Conflict Resolution
When another rule says one thing and maturity-lifecycle says another, **maturity wins.**

Examples:
- TDD rule says "always write tests first" but maturity is POC → TDD is optional
- Commit discipline rule says "conventional commits required" but maturity is POC → freeform OK
- Parallel agents rule suggests "run 4 agents in parallel" but maturity is Alpha → max 2, avoid serialization

---

## Using This Rule

### For Agents
Every action starts here:
1. Read `.add/config.json` and find maturity level
2. Cross-reference this rule's cascade matrix
3. Adjust behavior: relaxed for POC/Alpha, strict for Beta/GA
4. When in doubt, escalate to human

### For Humans
Every cycle, every milestone, ask:
1. "Are we still at {current maturity}?"
2. "Should we promote based on stability/completeness?"
3. "Should we demote based on new uncertainty/discovery?" (rare but possible)

### For Roadmap Planning
When sketching the roadmap, label each milestone with its target maturity. This clarifies:
- What "done" means (maturity governs completeness bar)
- When humans can step back (maturity governs autonomy)
- What safety protocols engage (maturity governs gates)

**Maturity lifecycle is the single most important rule in ADD.** Everything else cascades from it.


---

## Rule: maturity-loader

# ADD Rule: Maturity-Aware Rule Loading

## Purpose

Not all rules apply to all projects. Each rule declares a minimum maturity level via `maturity:` frontmatter. This loader instructs agents to respect those boundaries.

## How It Works

1. Read `.add/config.json` and extract the `maturity` field (poc, alpha, beta, ga)
2. Each rule file in `rules/` has a `maturity:` frontmatter field
3. **Only follow rules at or below the project's maturity level.** Ignore rules above it.

## Maturity Hierarchy

```
poc < alpha < beta < ga
```

A project at `alpha` loads `poc` + `alpha` rules. A project at `beta` loads `poc` + `alpha` + `beta` rules. And so on.

## Rule Loading Matrix

| Rule | POC | Alpha | Beta | GA |
|------|-----|-------|------|-----|
| `project-structure` | **active** | active | active | active |
| `learning` | **active** | active | active | active |
| `source-control` | **active** | active | active | active |
| `maturity-loader` (this rule) | **active** | active | active | active |
| `version-migration` | **active** | active | active | active |
| `registry-sync` | **active** | active | active | active |
| `spec-driven` | dormant | **active** | active | active |
| `quality-gates` | dormant | **active** | active | active |
| `human-collaboration` | dormant | **active** | active | active |
| `add-compliance` | dormant | **active** | active | active |
| `tdd-enforcement` | dormant | dormant | **active** | active |
| `agent-coordination` | dormant | dormant | **active** | active |
| `environment-awareness` | dormant | dormant | **active** | active |
| `maturity-lifecycle` | dormant | dormant | **active** | active |
| `design-system` | dormant | dormant | dormant | **active** |

## Agent Instructions

**At the start of every task:**

1. Read `.add/config.json` to determine the project maturity level
2. If a rule's `maturity:` level is ABOVE the project's level, **treat that rule as non-existent** — do not follow its instructions, do not reference it, do not enforce it
3. If no `.add/config.json` exists, assume `alpha` maturity (reasonable default)

**Example:** A project at `alpha` maturity has 6 active rules (project-structure, learning, source-control, maturity-loader, spec-driven, quality-gates, human-collaboration). The agent should NOT enforce TDD cycles, agent coordination protocols, environment-awareness tiers, or design system rules — those are dormant until the project promotes to beta or ga.

## Why This Matters

Loading all rules for all projects wastes context on instructions that don't apply. A POC project doesn't need 5-level quality gates. An alpha project doesn't need multi-agent coordination. The maturity dial controls rigor — and that starts with which rules are even active.


---

## Rule: project-structure

# ADD Rule: Project Structure

Every ADD project follows a standard directory layout. Consistency across projects means agents know where things are without discovery.

## Standard Project Layout

`/add:init` creates this structure. Skills and rules assume it exists.

```
{project-root}/
│
├── .add/                           # ADD methodology state (COMMITTED TO GIT)
│   ├── config.json                 # Project configuration (stack, envs, quality, collab)
│   ├── learnings.md                # Project-specific agent knowledge base
│   ├── retros/                     # Retrospective archives
│   │   └── retro-{YYYY-MM-DD}.md  # Individual retro records
│   └── away-logs/                  # Away session archives
│       └── away-{YYYY-MM-DD}.md   # Individual away session logs
│
├── .claude/                        # Claude Code configuration (COMMITTED)
│   └── settings.json               # Permissions, model prefs, plugin config
│
├── docs/                           # Project documentation
│   ├── prd.md                      # Product Requirements Document (source of truth)
│   └── plans/                      # Implementation plans
│       └── {feature}-plan.md       # One plan per feature spec
│
├── specs/                          # Feature specifications
│   └── {feature}.md                # One spec per feature
│
├── tests/                          # Test artifacts and evidence
│   ├── screenshots/                # E2E visual verification
│   │   ├── {feature}/              # Organized by feature
│   │   │   └── step-{NN}-{desc}.png
│   │   └── errors/                 # Failure screenshots (auto-captured)
│   ├── e2e/                        # End-to-end test files
│   ├── unit/                       # Unit test files (if not colocated)
│   └── integration/                # Integration test files
│
├── CLAUDE.md                       # Project context for Claude
│
└── {source directories}            # Application code (stack-dependent)
```

## What Gets Committed

Everything in the project directory is committable EXCEPT:

```gitignore
# ADD to .gitignore during /add:init
.add/away-logs/          # Ephemeral, not worth tracking
tests/screenshots/errors/ # Failure screenshots are debugging artifacts
```

These MUST be committed (agents on other devices need them):

- `.add/config.json` — project configuration
- `.add/learnings.md` — agent knowledge (critical for device portability)
- `.add/retros/` — retrospective history
- `docs/prd.md` — product requirements
- `docs/plans/` — implementation plans
- `specs/` — feature specifications
- `tests/screenshots/{feature}/` — passing visual evidence
- `.claude/settings.json` — Claude Code permissions

## Plugin-Global Knowledge (Tier 1)

ADD ships with a `knowledge/` directory containing curated best practices:

```
~/.codex/add/knowledge/
└── global.md          # Tier 1: Universal ADD best practices for all users
```

This directory is **read-only in consumer projects**. Only updated by ADD maintainers. Agents read `knowledge/global.md` as the first tier in the 3-tier knowledge cascade (see `learning.md` rule).

## Cross-Project Persistence

Knowledge that transcends any single project lives at the user level:

```
~/.claude/add/
├── profile.md                  # User preferences and tech defaults
├── library.md                  # Promoted learnings from all projects
└── projects/                   # Index of projects you've ADD-initialized
    └── {project-name}.json     # Config snapshot + key learnings summary
```

### Profile (`~/.claude/add/profile.md`)

Your developer DNA. Carries preferences across projects:
- Default tech stack (languages, frameworks, versions)
- Cloud and infrastructure preferences
- Process preferences (autonomy, quality, commits)
- Style preferences (naming, formatting, UX patterns)
- Cross-project lessons learned

Read by `/add:init` to pre-populate interview answers.
Updated during `/add:retro` when cross-project patterns are confirmed.

### Library (`~/.claude/add/library.md`)

Accumulated wisdom from all projects. Entries promoted from project-level
`.add/learnings.md` during retrospectives:
- Technical patterns that apply everywhere
- Architecture decision rationale that transfers
- Anti-patterns discovered in any project
- Performance insights across different stacks

Read by agents before starting work (alongside project-level learnings).

### Project Index (`~/.claude/add/projects/{name}.json`)

Lightweight snapshot created during `/add:init` and updated during `/add:retro`:

```json
{
  "name": "dossierfyi",
  "path": "/Users/abrooke/projects/dossierfyi",
  "initialized": "2026-01-15",
  "last_retro": "2026-02-07",
  "stack": ["python-3.11", "fastapi", "react-18", "seekdb"],
  "tier": 2,
  "key_learnings": [
    "pymysql is not thread-safe",
    "Keycloak needs KC_HOSTNAME_STRICT=false behind LB"
  ]
}
```

This lets `/add:init` on a new project say: "I see you worked on dossierfyi with FastAPI + React. Similar stack here?"

## Portability Between Devices

**Scenario:** You develop on your MacBook, then switch to a workstation.

**What ports via git (automatic):**
- `.add/config.json` — project knows its stack and settings
- `.add/learnings.md` — agent knowledge transfers with the repo
- `.add/retros/` — historical context
- `specs/`, `docs/plans/`, `docs/prd.md` — all specification artifacts

**What doesn't port (machine-local):**
- `~/.claude/add/profile.md` — your personal preferences
- `~/.claude/add/library.md` — cross-project knowledge

**Rebuilding machine-local state:**
Run `/add:init --import` on the new device. This reads `.add/config.json` and
`.add/learnings.md` from the committed project files and uses them to:
1. Recreate `~/.claude/add/profile.md` (asks for confirmation)
2. Recreate `~/.claude/add/projects/{name}.json`
3. Optionally import learnings into `~/.claude/add/library.md`

## Directory Creation Rules

- `/add:init` creates the full standard layout on first run
- Skills MUST NOT create directories ad-hoc — they use the established structure
- If a skill needs a directory that doesn't exist, it's a bug in `/add:init`
- The only exception: feature-specific subdirectories under `tests/screenshots/`
  are created by the test-writer when the first test for that feature is written

## Stack-Dependent Source Directories

The standard layout above covers ADD methodology directories. Application source
directories depend on the stack and are documented in CLAUDE.md during `/add:init`:

### Python Backend
```
backend/
├── app/
│   ├── routes/
│   ├── services/
│   ├── models/
│   └── config/
└── tests/           # Can use project-level tests/ or backend/tests/
```

### React Frontend
```
frontend/
├── src/
│   ├── components/
│   ├── hooks/
│   ├── pages/
│   └── api/
└── tests/           # Can use project-level tests/ or frontend/tests/
```

### Full-Stack (Python + React)
```
backend/             # Python backend
frontend/            # React frontend
tests/               # E2E and integration (project-level)
  ├── e2e/           # Playwright tests
  └── screenshots/   # Visual verification
```

### Simple SPA / Single-Language
```
src/                 # Application code
tests/               # All tests
```

The stack detection in `/add:init` determines which pattern to suggest.
The human can override during the interview.


---

## Rule: quality-gates

# ADD Rule: Quality Gates

Quality gates are checkpoints that code must pass before advancing. They are non-negotiable.

## Gate Levels

### Gate 1: Pre-Commit (every commit)

These run before or during commit. Failures block the commit.

- [ ] Linter passes (ruff/eslint — language-dependent)
- [ ] Formatter applied (ruff format/prettier — language-dependent)
- [ ] No merge conflicts
- [ ] No large files (> 1MB) accidentally staged
- [ ] No secrets or credentials in staged files
- [ ] No TODO/FIXME without an associated issue or spec reference

### Gate 2: Pre-Push (every push to remote)

These run before pushing. Failures block the push.

- [ ] All unit tests pass
- [ ] Type checker passes (mypy/tsc — language-dependent)
- [ ] Test coverage meets threshold (configured in `.add/config.json`, default 80%)
- [ ] No failing tests on the branch

### Gate 3: CI Pipeline (every PR)

These run in CI. Failures block merge.

- [ ] All Gate 1 and Gate 2 checks pass
- [ ] Integration tests pass
- [ ] Coverage report uploaded
- [ ] E2E tests pass (if UI changes, based on environment tier)
- [ ] Screenshots captured and attached (if E2E runs)

### Gate 4: Pre-Deploy (before any deployment)

These run before deployment. Failures block deploy.

- [ ] All Gate 3 checks pass
- [ ] No unresolved review comments
- [ ] Spec compliance verified (every acceptance criterion has a passing test)
- [ ] Human approval received (for production)

### Gate 5: Post-Deploy (after deployment)

These run after deployment. Failures trigger rollback discussion.

- [ ] Smoke tests pass (health endpoints, critical paths)
- [ ] No error spike in logs (if monitoring available)
- [ ] Key user flows accessible

## Quality Gate Commands

The `/add:verify` skill runs the appropriate gates based on context:

```
/add:verify          — Run Gate 1 + Gate 2 (local verification)
/add:verify --ci     — Run Gate 1 through Gate 3 (CI-level)
/add:verify --deploy — Run Gate 1 through Gate 4 (pre-deploy)
/add:verify --smoke  — Run Gate 5 only (post-deploy)
```

## Spec Compliance Verification

After implementation, verify every acceptance criterion:

```
SPEC COMPLIANCE REPORT — specs/auth.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AC-001: User can log in with valid credentials
  Status: COVERED
  Tests: test_ac001_login_success, TC-001 (e2e)

AC-002: Invalid password shows error message
  Status: COVERED
  Tests: test_ac002_invalid_password, TC-002 (e2e)

AC-003: Account locks after 5 failed attempts
  Status: NOT COVERED — no test exists
  Action: Write test before marking feature complete

RESULT: 2/3 criteria covered — INCOMPLETE
```

A feature is not complete until every acceptance criterion has at least one passing test.

## Screenshot Protocol

For projects with UI (configured in `.add/config.json`):

### When to Capture

- Page navigation or route change
- Data load complete (after loading state resolves)
- User interaction result (form submit, button click)
- Modal or dialog open/close
- Error states
- Tab or view switches

### Directory Structure

```
tests/screenshots/
  {test-category}/
    step-{NN}-{description}.png
```

### In E2E Tests

```typescript
await page.screenshot({
  path: `tests/screenshots/${category}/step-${step}-${description}.png`,
  fullPage: true
});
```

### On Failure

```typescript
test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status !== 'passed') {
    await page.screenshot({
      path: `tests/screenshots/errors/${testInfo.title}-${Date.now()}.png`,
      fullPage: true
    });
  }
});
```

## Relaxed Mode

For early spikes or prototypes, quality gates can be relaxed in `.add/config.json`:

```json
{
  "quality": {
    "mode": "spike",
    "coverage_threshold": 50,
    "type_check_blocking": false,
    "e2e_required": false
  }
}
```

Even in spike mode, Gate 1 (lint, format, no secrets) always applies. Tests must still be written before implementation — the coverage threshold is just lower.

## Maturity-Scaled Checks

In addition to the core gate checks above, these checks scale with project maturity. At lower maturity levels, checks are lighter and advisory. At higher maturity, they tighten and become blocking.

Read `.add/config.json` maturity field to determine which checks apply and their enforcement level.

### Check Categories

#### 1. Code Quality

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Lint errors | Blocking | Blocking | Blocking |
| Cyclomatic complexity | — | >15 advisory | >10 blocking |
| Code duplication | — | >10 lines advisory | >6 lines blocking |
| File length | — | >500 lines advisory | >300 lines blocking |
| Function length | — | >80 lines advisory | >50 lines blocking |

#### 2. Security & Vulnerability

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Secrets scan | Blocking | Blocking | Blocking |
| OWASP spot-check | Advisory | Full review advisory | Full review blocking |
| Dependency audit (known CVEs) | — | Advisory | Blocking |
| Auth pattern review | — | Advisory | Blocking |
| PII/data handling review | — | Advisory | Blocking |
| Rate limiting & secure headers | — | — | Required (blocking) |

#### 3. Readability & Documentation

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Naming consistency | Advisory | Advisory | Blocking |
| Nesting depth | — | <5 levels advisory | <4 levels blocking |
| Docstrings on exports | — | Advisory | Blocking |
| Complex logic comments | — | Advisory | Blocking |
| Magic number detection | — | Advisory | Blocking |
| Module READMEs | — | — | Blocking |
| Project glossary | — | — | Blocking |

#### 4. Performance

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| N+1 query detection | — | Advisory | Blocking |
| Blocking async detection | — | Advisory | Blocking |
| Bundle size check | — | Advisory | Blocking |
| Memory leak patterns | — | Advisory | Blocking |
| Performance tests | — | — | Required (blocking) |
| Response time baselines | — | — | Required (blocking) |

#### 5. Repo Hygiene

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Branch naming convention | Advisory | Advisory | Blocking |
| .gitignore exists | Advisory | Blocking | Blocking |
| LICENSE file | — | Advisory | Blocking |
| CHANGELOG maintained | — | Advisory | Blocking |
| Dependency freshness | — | Advisory | Blocking |
| README completeness | — | Advisory | Blocking (comprehensive) |
| PR template exists | — | Advisory | Blocking |
| Stale branches | — | Advisory | Blocking (14-day limit) |

### Gate Distribution

Checks are distributed across gates based on when they provide the most value:

**Gate 1 (Pre-Commit):** Code quality (lint, complexity, duplication, file/function length), secrets scan, readability (naming, nesting), branch naming convention

**Gate 2 (Pre-Push):** Dependency audit, OWASP review, docstrings on exports, N+1/blocking async detection, CHANGELOG/LICENSE check

**Gate 3 (CI):** Bundle size, PR template, README completeness, dependency freshness

**Gate 4 (Pre-Deploy):** Auth pattern review, PII/data handling, response time baselines, stale branch cleanup

**Gate 5 (Post-Deploy):** Response times vs baselines, secure headers verification

### Enforcement Levels

- **Blocking**: Check must pass or gate fails. Code cannot advance.
- **Advisory**: Check is reported in the gate output but does not block advancement. Findings appear in the report as warnings.
- **—**: Check is not performed at this maturity level.

### Configuration Overrides

Projects can override default thresholds in `.add/config.json`:

```json
{
  "qualityChecks": {
    "codeQuality": {
      "maxComplexity": 15,
      "maxDuplicationLines": 10,
      "maxFileLength": 500,
      "maxFunctionLength": 80
    },
    "security": {
      "dependencyAudit": true,
      "owaspLevel": "full"
    },
    "readability": {
      "maxNestingDepth": 5,
      "requireDocstrings": true
    },
    "performance": {
      "maxBundleSizeKb": 500,
      "responseTimeBaselineMs": 200
    },
    "repoHygiene": {
      "staleBranchDays": 14,
      "requireChangelog": true
    }
  }
}
```

When `qualityChecks` is not present, defaults from this rule apply. Per-category overrides merge with defaults — only specified fields are changed.


---

## Rule: registry-sync

# ADD Rule: Project Registry Sync

The cross-project registry at `~/.claude/add/projects/{name}.json` is how `/add:init` on new projects and `/add:retro` cross-project promotion find prior work. When it drifts from the project's ground truth, those workflows silently degrade.

## When This Runs

On every session start, AFTER `version-migration.md` has completed:

1. Read `.add/config.json` → extract project name
2. Locate registry: `~/.claude/add/projects/{name}.json`
3. If registry does not exist → skip silently (pre-init project or intentionally unregistered)
4. If registry exists → compare to ground truth

## Ground-Truth Comparison

| Registry Field | Ground Truth | Drift Threshold |
|---|---|---|
| `learnings_count` | `jq '.entries | length' .add/learnings.json` (or lines in `.add/learnings.md` starting with `-` if JSON absent) | Actual > 3× registry value OR actual − registry > 20 |
| `last_retro` | Newest filename in `.add/retros/retro-*.md` (extract date) | Registry is null but retro file exists, OR registry is > 14 days older than newest retro |
| `maturity` | `.add/config.json` maturity.level | Any mismatch |
| `tier` | `.add/config.json` environments.tier | Any mismatch |

## On Drift Detection

Emit ONE compact drift notice at session start. Do not re-emit during the session.

```
📋 Registry drift detected for {project}:
   • learnings_count: registry 5 vs actual 55
   • last_retro: registry null vs 2026-04-12
   Run /add:init --sync-registry to reconcile. (Safe: read-only comparison,
   no project files modified.)
```

Do not block. Do not auto-update the registry without user approval — the registry is machine-local state that the user may have intentionally customized.

## Sync Command

When the user runs `/add:init --sync-registry`:

1. Read ground truth (learnings count, latest retro, maturity, tier, stack)
2. Compute a diff against the current registry
3. Present the diff, ask for confirmation
4. Write the reconciled registry file
5. Report what changed

## Auto-Bump on Checkpoint

When any skill writes to `.add/learnings.json`, `.add/retros/retro-*.md`, or promotes the project's maturity level, also:

1. Read the current registry (`~/.claude/add/projects/{name}.json`)
2. If it exists, update the corresponding field:
   - After learning write → increment `learnings_count`
   - After retro write → set `last_retro` to today
   - After maturity promotion → update `maturity`
3. Write the registry back

If the registry does not exist, skip silently (no auto-creation — that's `/add:init`'s job).

## Why This Exists

Evidence from the agentVoice dog-food project:

- Registry `learnings_count: 5` vs actual 55 (11× drift)
- Registry `last_retro: null` vs actual 2026-04-12 (missed entirely)
- Result: `/add:init` on a sister project would have said "agentVoice has 5 learnings, alpha maturity" — wrong on both counts, reducing the value of cross-project memory to zero.

The registry should be a trusted, auto-maintained mirror of ground truth. This rule keeps it one.


---

## Rule: source-control

# ADD Rule: Source Control Protocol

Consistent git practices keep the project navigable and the history meaningful.

## Branching Strategy

Default: feature branches off `main`. Configured in `.add/config.json`.

```
main (production-ready, protected)
 ├── feature/{feature-name}   — new functionality
 ├── fix/{issue-description}  — bug fixes
 ├── refactor/{description}   — code improvement, no behavior change
 └── test/{description}       — test additions or improvements
```

Branch names use kebab-case: `feature/user-authentication`, `fix/login-redirect-loop`.

## Commit Conventions

Conventional commits with scope. Every commit message follows:

```
{type}: {description}

{optional body — what and why, not how}

Spec: specs/{feature}.md
AC: {acceptance criteria IDs covered}
```

### Types

- `feat:` — New feature or capability
- `fix:` — Bug fix
- `test:` — Adding or updating tests (RED phase)
- `refactor:` — Code restructuring, no behavior change (REFACTOR phase)
- `docs:` — Documentation only
- `style:` — Formatting, no logic change
- `perf:` — Performance improvement
- `chore:` — Build, tooling, dependency updates
- `ops:` — Infrastructure, deployment, CI/CD

### TDD Commit Pattern

Each TDD cycle produces 1-3 commits:

```
test: add failing tests for user login (RED)
Spec: specs/auth.md
AC: AC-001, AC-002

feat: implement user login endpoint (GREEN)
Spec: specs/auth.md
AC: AC-001, AC-002

refactor: extract password validation to utility (REFACTOR)
```

## When to Commit

- After each completed TDD phase (RED, GREEN, or REFACTOR)
- NEVER with failing tests on the branch
- NEVER with lint errors
- NEVER mid-implementation (half-written functions, incomplete features)

## Pull Request Flow

### Agent Creates PR With:

1. **Title:** `{type}: {concise description}` (< 70 characters)
2. **Body:**
   - Summary of changes (2-3 bullets)
   - Spec reference (`specs/{feature}.md`)
   - Acceptance criteria covered
   - Test results summary
   - Screenshots (if UI changes)
3. **TDD Checklist:**
   - [ ] Tests written before implementation (RED)
   - [ ] Implementation passes tests (GREEN)
   - [ ] Code refactored (REFACTOR)
   - [ ] Full test suite passes (VERIFY)
4. **Quality Gates:**
   - [ ] Linting clean
   - [ ] Type checking clean
   - [ ] Coverage meets threshold
   - [ ] Spec compliance verified

### What Requires Human Approval

- Merge to main/production branch
- Any deployment to production
- Schema migrations
- Security-sensitive changes (auth, permissions, secrets)
- Dependency major version upgrades

### What Agents Can Do Autonomously

- Commit to feature branches
- Create PRs (human reviews before merge)
- Deploy to dev/staging (if configured)
- Run quality gates and report results
- Fix lint/type errors on feature branches

## Protected Branches

`main` is always protected:

- No direct commits (all changes via PR)
- CI must pass before merge
- At least one review (human or agent reviewer)
- No force pushes
- No history rewrites

## Git Hygiene

- Rebase feature branches on main before PR (keep history linear)
- Squash commits only if the human requests it
- Delete feature branches after merge
- Tag releases with semantic versioning (`v1.2.3`)
- Never commit secrets, credentials, or API keys (use .gitignore and .env)


---

## Rule: spec-driven

# ADD Rule: Spec-Driven Development

Agent Driven Development requires specifications before code. This is non-negotiable.

## Document Hierarchy

Every project follows this chain. No link may be skipped.

```
PRD (docs/prd.md)
 → Feature Specs (specs/{feature}.md)
   → Implementation Plans (docs/plans/{feature}-plan.md)
     → User Test Cases (embedded in spec)
       → Automated Tests (RED phase)
         → Implementation (GREEN phase)
```

## PRD Requirements

Before any feature work begins, `docs/prd.md` must exist and contain:

1. **Problem Statement** — What problem are we solving and for whom
2. **Success Metrics** — How we know the project succeeded
3. **Scope** — What's in and what's explicitly out
4. **Technical Constraints** — Stack, environments, deployment targets
5. **Environment Strategy** — Which environments exist and their purpose

If no PRD exists when a feature spec is requested, stop and run the `/add:init` interview first.

## Spec Requirements

Before any implementation begins, a spec must exist in `specs/` and contain:

1. **Feature Description** — What it does in plain language
2. **User Story** — As [who], I want [what], so that [why]
3. **Acceptance Criteria** — Numbered, testable statements (AC-001, AC-002, etc.)
4. **User Test Cases** — Human-readable test scenarios (TC-001, TC-002, etc.)
5. **Data Model** — Entities, fields, types, relationships
6. **API Contract** — Endpoints, request/response schemas (if applicable)
7. **Edge Cases** — What happens when things go wrong
8. **Screenshot Checkpoints** — What to visually verify in E2E tests

## Plan Requirements

Before coding begins, a plan must exist in `docs/plans/` and contain:

1. **Task Breakdown** — Ordered list of implementation steps
2. **File Changes** — Which files are created, modified, or deleted
3. **Test Strategy** — What types of tests cover this feature
4. **Dependencies** — What must be done first
5. **Spec Traceability** — Each task maps to acceptance criteria

## Enforcement

- NEVER write implementation code without a spec in `specs/`
- NEVER write a spec without a PRD in `docs/prd.md`
- NEVER start coding without a plan in `docs/plans/`
- If asked to "just build it" — create the spec first, then build from it
- Specs ARE the source of truth. If code contradicts the spec, the code is wrong.


---

## Rule: tdd-enforcement

# ADD Rule: Test-Driven Development

All implementation follows strict TDD. The cycle is RED → GREEN → REFACTOR → VERIFY.

## The Cycle

### RED Phase — Write Failing Tests

1. Read the spec's acceptance criteria and user test cases
2. Write test(s) that assert the expected behavior
3. Run the tests — they MUST fail
4. If tests pass before implementation, the tests are wrong (testing existing behavior, not new)

### GREEN Phase — Minimal Implementation

1. Write the MINIMUM code to make failing tests pass
2. No extra features, no "while I'm here" additions
3. No optimization — just make it work
4. Run tests — they MUST pass

### REFACTOR Phase — Improve Quality

1. Clean up code without changing behavior
2. Extract functions, rename variables, remove duplication
3. Run tests after EVERY refactor — they must still pass
4. Apply project naming conventions and patterns

### VERIFY Phase — Independent Confirmation

1. Run the FULL test suite, not just new tests
2. Run linter (ruff/eslint depending on language)
3. Run type checker (mypy/tsc depending on language)
4. Verify spec compliance — do the changes satisfy the acceptance criteria?
5. If any gate fails, fix before proceeding

## Mandatory Rules

- NEVER write implementation before tests exist and FAIL
- NEVER skip the RED phase — "I'll add tests later" is not allowed
- NEVER commit with failing tests on the branch
- When a sub-agent implements code, the orchestrator MUST run tests independently
- Each TDD cycle should be a single, atomic commit

## Test Naming

Tests must reference the spec:

```python
# Backend (pytest)
def test_ac001_user_can_login_with_valid_credentials():
def test_ac002_invalid_password_shows_error():
def test_tc001_login_success_flow():
```

```typescript
// Frontend (vitest/playwright)
describe('AC-001: User login', () => {
  it('should authenticate with valid credentials', ...);
});

describe('TC-001: Login success flow', () => {
  it('step 1: navigate to /login', ...);
  it('step 2: enter credentials and submit', ...);
  it('step 3: see dashboard with username', ...);
});
```

## Coverage Requirements

Coverage targets are set in `.add/config.json` during project init. Defaults:

- Unit tests: 80% line coverage
- Integration tests: Critical paths covered
- E2E tests: All user test cases from specs have corresponding tests


---

## Rule: version-migration

# ADD Rule: Version Migration

Automatically detect and migrate stale ADD project files when the plugin version is newer than the project version.

## When This Runs

On **every session start**, before any other work:

1. Read `.add/config.json` — extract the `version` field
2. Read the plugin's `.claude-plugin/plugin.json` — extract the `version` field
3. If they match → **stop silently** (no output, no action)
4. If project version is ahead of plugin → warn: "Project version ({project}) is newer than plugin ({plugin}). Skipping migration." → stop
5. If no `.add/config.json` exists → not an ADD project, stop silently
6. If config exists but has no `version` field → assume `0.1.0`

## Migration Process

### Step 1: Build Migration Path

Read `~/.codex/add/templates/migrations.json` to get the manifest.

Chain migrations from the project version to the plugin version. Example: project at `0.1.0`, plugin at `0.4.0` → path is `0.1.0 → 0.2.0 → 0.3.0 → 0.4.0`.

If no migration entry exists for a hop in the chain, skip that hop and continue.

### Step 2: Back Up Files

Before modifying ANY file, create a backup:
- Copy `{file}` to `{file}.pre-migration.bak`
- If a `.pre-migration.bak` already exists, append a timestamp: `{file}.pre-migration-{YYYYMMDD-HHMMSS}.bak`

Track all backups created.

### Step 3: Execute Migration Steps

For each version hop in order, execute each step from the manifest:

#### Action: `add_fields`

Add new fields to a JSON file with default values. Uses dot-notation paths (e.g., `collaboration.autonomy_level` means `{"collaboration": {"autonomy_level": value}}`).

- Read the target JSON file
- For each field in `params.fields`: if the field doesn't already exist, add it with the specified default value
- If the field already exists, **leave it unchanged** (user may have customized it)
- Write the updated JSON

#### Action: `convert_md_to_json`

Convert a freeform markdown file to structured JSON.

- If the target JSON file already exists, **skip** — the conversion was already done
- Read the markdown source file
- Read the template from `params.template` for the target schema
- Parse entries from the markdown (checkpoint blocks, bullet points, sections)
- Classify each entry (scope, stack, category, severity) using the rules in `learning.md`
- Assign IDs with the prefix from `params.id_prefix`
- Write the JSON file
- If `params.regenerate_md` is true, regenerate the markdown view from JSON
- Rename the original markdown to `{file}.deprecated`

#### Action: `restructure`

Ensure a markdown file has required sections.

- Read the file
- For each section in `params.required_sections`: if the section heading doesn't exist, append it with empty content
- If `params.required_format` is specified, note the expected line format (informational — don't rewrite existing lines)
- If `params.header` is specified and the file lacks the expected header, prepend it
- Write the updated file

#### Action: `rename_fields`

Rename fields in a JSON file.

- Read the target JSON file
- For each old→new mapping in `params.fields`: move the value from the old key to the new key
- Delete the old key
- Write the updated JSON

#### Action: `remove_fields`

Remove deprecated fields from a JSON file.

- Read the target JSON file
- For each field in `params.fields`: delete it if it exists
- Write the updated JSON

### Step 4: Update Version

After ALL migration steps complete successfully:
- Update `.add/config.json` `version` field to the plugin version
- If any step failed, **do NOT update the version** — leave it at the last successfully completed hop

### Step 5: Print Report

Print a migration report:

```
ADD MIGRATION — v{from} → v{to}
Path: v{from} → v{hop1} → v{hop2} → v{to}

Backed up:
  {file} → {file}.pre-migration.bak
  ...

Migrated:
  ✓ {file} ({description})
  ...

Skipped (already current):
  - {file} ({reason})
  ...

Failed:
  ✗ {file} — {error message}
  ...

Version updated: .add/config.json → {to}
Migration complete.
```

If there were no failures, omit the Failed section. If there were no skips, omit the Skipped section.

## Error Handling

- If a file cannot be read or parsed, **log the error and skip that step** — continue with remaining steps
- If a backup cannot be created (read-only filesystem, etc.), **abort the entire migration** — never modify without backup
- All backups remain intact regardless of migration outcome
- If migration fails partway, the version stays at the last successful hop (not the original version)

## Dry-Run Mode

If the user asks for a dry-run migration, follow the same process but:
- Do NOT create backups
- Do NOT modify any files
- Do NOT update the version
- Print the report with "DRY RUN" prefix showing what WOULD happen

## Migration Log

After a successful migration, append to `.add/migration-log.md`:

```
## {YYYY-MM-DD HH:MM} — v{from} → v{to}
- Path: {migration path}
- Files migrated: {N}
- Files skipped: {N}
- Files failed: {N}
- Failures: {list or "none"}
```

Create the file if it doesn't exist.

# Claude Code Workflows & Swarm Patterns Research Report
## v1.0 | June 2026 | Findings for ADD v1.0 Modernization

---

## Executive Summary

Claude Code's new **Dynamic Workflows** feature—introduced May 2026—introduces a paradigm shift in multi-agent orchestration. Native Workflows codify orchestration as **deterministic JavaScript**, freeing Claude's context from turn-by-turn agentic loop overhead. This directly overlaps with ADD's hand-rolled "swarm" pattern (parallel subagents + synthesis), but Workflows move the plan into executable code rather than conversation flow. 

**Key finding:** Native Workflows make hand-rolled swarms **redundant for orchestration**. A methodology plugin (like ADD) now adds value by wrapping Workflows with **methodology scaffolding** (TDD phases, specification capture, quality gates) rather than by spawning parallel subagents manually.

---

## 1. Dynamic Workflows: Primitives & Capabilities

### What It Is
A **JavaScript orchestration script** that:
- Claude Code writes for your task description
- Runs in a **background isolated runtime** (separate from your conversation)
- **Spawns subagents at scale** (16 concurrent, 1,000 total per run)
- Holds intermediate state in **script variables** instead of Claude's context
- **Deterministically repeatable**—save the script and rerun for the same task

**Canonical invocation:**
```bash
/deep-research What changed in Node.js v20→v22?
# Built-in workflow; fans out web searches, cross-checks sources, returns cited report
```

### Core Primitives & Patterns

| Primitive | What it does | Context cost |
|-----------|-------------|--------------|
| **Phases** | Sequential or parallel work stages; each can spawn multiple agents | Zero; orchestration is in script, not context |
| **Agents array** | Spawn up to 16 concurrent agents per phase; each gets independent context | Each agent uses own context window; aggregated tokens reported |
| **Schema-validated output** | JSON return from each agent; script can vote/filter/synthesize | Only final result reaches main conversation |
| **Budgets** | Token limits per agent, phase, or run; prevents runaway cost | Visible in `/workflows` progress view real-time |
| **Worktree isolation** | Agents can write to isolated git worktrees instead of main checkout | Cleanup automatic if no changes; prevents file conflicts |
| **Resume/journaling** | Pause run → resume later; cached agent results replay; full transcript logged | Transcript at `~/.claude/projects/{project}/{session}/workflows/` |

### Invocation Paths

**1. Bundled workflow** (ready-to-use):
```bash
/deep-research <question>
```

**2. Ask Claude to write a workflow** (natural language):
```
ultracode: audit every API endpoint under src/routes/ for missing auth checks
```
Claude writes the JS, you confirm the phases, then it runs.

**3. Ultracode effort level** (auto-decide when to workflow):
```bash
/effort ultracode  # Combines xhigh reasoning + automatic workflow orchestration
```
Claude decides each task: is it worth a workflow? If yes, write it; if no, stay in conversation.

**4. Save & reuse** (custom command):
After a run succeeds:
- Press `s` in `/workflows` view
- Save to `.claude/workflows/` (shared) or `~/.claude/workflows/` (personal)
- Becomes `/my-workflow-name` in future sessions

### Pass Input to Saved Workflows

```bash
claude  # starts session
> Run /triage-issues on issues 1024, 1025, and 1030
```

The `args` global in the JS receives structured data (not strings to parse).

### Execution Constraints & Limits

| Constraint | Value | Why |
|-----------|-------|-----|
| **Concurrent agents** | 16 (fewer on low-CPU machines) | Bounds local resource use |
| **Total agents per run** | 1,000 | Prevents runaway loops |
| **Mid-run user input** | Blocked; only permission prompts can pause | Keep orchestration deterministic |
| **Direct shell from script** | Blocked; agents do it, script coordinates | Agents handle I/O, script holds plan |

### Behavioral Guarantees

- **Resumable within session:** Paused run → resume → agents with completed work return cached results, unfinished ones run live
- **Session-bound:** Exit Claude Code while running → next session starts workflow fresh (not resumed)
- **Token tracking:** Real-time token usage per agent/phase visible in `/workflows` view
- **Stop gracefully:** `x` key stops single agent or whole run from progress view

---

## 2. Subagents & Agent Tool: Current State

### Built-in Subagent Types

| Type | Model | Tools | When used | Skip CLAUDE.md? |
|------|-------|-------|-----------|-----------------|
| **Explore** | Haiku | Read-only (Glob, Grep, Read) | Fast codebase search/analysis | Yes |
| **Plan** | Inherit | Read-only | Plan mode research phase | Yes |
| **general-purpose** | Inherit | All | Complex multi-step tasks | No |

Explore/Plan skip CLAUDE.md & git status to keep fast and cheap. Every other agent loads both.

### Custom Subagent Creation

Markdown file with YAML frontmatter:
```markdown
---
name: code-reviewer
description: Expert code review. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
memory: user
isolation: worktree
---

You are a code reviewer...
```

**Frontmatter fields** (supported):
- `name`, `description` (required)
- `tools`, `disallowedTools` (allowlist/denylist)
- `model` (sonnet, opus, haiku, fable, or inherit)
- `permissionMode` (default, acceptEdits, auto, dontAsk, bypassPermissions, plan)
- `maxTurns`, `skills` (preload skill content at startup)
- `mcpServers` (inline or reference existing)
- `hooks` (SubagentStart, SubagentStop, PreToolUse, PostToolUse events)
- `memory` (user/project/local scope for persistent learning)
- `background` (true = always run async)
- `isolation: worktree` (git worktree per agent to avoid file conflicts)
- `effort` (low–max; overrides session level)
- `color` (task list UI)
- `initialPrompt` (auto-submitted first turn)

### Subagent Scope & Priority

Where you store a subagent determines visibility & override precedence:

| Location | Scope | Priority | Example |
|----------|-------|----------|---------|
| Managed settings | Organization-wide | 1 (wins) | Deployed via `admin-settings` |
| `--agents` CLI flag | Session-only | 2 | `claude --agents '{...}'` |
| `.claude/agents/` | Project | 3 | Checked into repo |
| `~/.claude/agents/` | Personal (all projects) | 4 | Personal tools |
| Plugin `agents/` | Where plugin enabled | 5 (loses) | Scoped as `plugin:agent` |

### Spawning & Invocation

**Automatic delegation:** Claude matches task to subagent descriptions and spawns without you asking.

**Explicit invocation:**
```bash
@"code-reviewer (agent)" look at the auth changes
# or
/agents  # open UI, spawn from there
# or (session-wide)
claude --agent code-reviewer
```

**Parallel invocation:** Ask Claude to spawn multiple subagents for independent work; they run concurrently and report back.

### Nested Subagents (v2.1.172+)

A subagent can spawn its own subagents (depth limit: 5 for background agents, unlimited for foreground since they block parent). Only the top-level subagent's summary returns to you.

### Run in Foreground or Background

**Foreground (default for complex tasks):**
- Blocks main conversation until done
- Permission prompts surface to you
- Full tool call visibility

**Background (default for isolated work):**
- Runs concurrently; you keep working
- Auto-deny permission prompts (uses already-granted perms)
- Tool calls stay hidden; only final result returns

Trigger: `Ctrl+B` to background a running task, or ask Claude "run this in the background."

### Agent Tool & Agent SDK

From **Claude Agent SDK** (API-driven):
```python
from anthropic import Anthropic
from anthropic.types.beta import MessageCreateParamsNonStreaming

client = Anthropic()

# Spawn an agent session
session = client.beta.agent_sessions.create()

# Send a message (spawns subagents under the hood if needed)
response = client.beta.messages.create(
    model="claude-opus-4-8",
    max_tokens=4096,
    system="You are a helpful agent. Use subagents for research.",
    messages=[{"role": "user", "content": "Research Node.js v22 breaking changes"}]
)
```

The SDK abstracts subagent lifecycle. Claude decides when to spawn workers.

---

## 3. Other Recent Claude Code Features (Relevant to Methodology)

### Skills (Slash Commands)

**What:** Markdown files with YAML frontmatter → reusable instructions & workflows.

**Invocation:** `/skill-name` or auto-loaded by Claude based on description match.

**Key fields:**
- `description` (when to use)
- `disable-model-invocation: true` (only you can invoke)
- `context: fork` (run in isolated subagent instead of main conversation)
- `allowed-tools` (pre-approve tools for this skill)
- `paths` (only load when editing matching files)
- Dynamic context injection: `` !`git status` `` runs command, output replaces placeholder

**Where:**
- `~/.claude/skills/<name>/SKILL.md` (personal)
- `.claude/skills/<name>/SKILL.md` (project)
- Plugin: `<plugin>/skills/<name>/SKILL.md` → `/plugin:name`

**Context cost:** Description loads at session start (cheap); full content loads only when invoked. After compaction, first 5,000 tokens of each skill re-attached (25,000 token budget shared across all invoked skills).

### Hooks (Deterministic Automation)

Lifecycle events that trigger **deterministic shell commands** or **LLM-based decisions**:

**Event types:**
- `PreToolUse` (before tool execution; can block with exit code 2)
- `PostToolUse` (after tool execution; can transform output)
- `SessionStart`, `Stop` (session lifecycle)
- `SubagentStart`, `SubagentStop` (subagent spawning/completion)
- `Notification` (when Claude needs input)
- `TaskCreated`, `TaskCompleted` (agent team task list)
- `TeammateIdle` (agent team teammate waiting)

**Hook types:**
- **Command hook:** run shell script
- **Prompt hook:** ask LLM to evaluate condition
- **Agent hook:** spawn subagent to decide
- **HTTP hook:** POST to webhook

**Matcher syntax:** filter by tool name, agent type, file path patterns.

**Example:** Run ESLint after every file edit:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "npm run lint"}]
    }]
  }
}
```

### Plan Mode & Ultraplan

**Plan Mode** (`/permission-modes`):
- Claude reads your codebase in read-only mode
- Generates a plan (text, not code)
- You review and approve before implementation
- Good for exploring changes before committing

**Ultraplan** (web-based):
```bash
claude --ultraplan "refactor the auth module"
```
Launches browser UI; Claude drafts a detailed plan; you approve or iterate; plan executes locally.

### Ultracode (Automatic Workflow Orchestration)

```bash
/effort ultracode  # xhigh reasoning + auto-workflow decisions
```

For each substantive task, Claude decides: "Should this be a workflow?" If yes, write JS and run it. If no, stay in conversation. Lasts one session only.

### Scheduled Agents & Routines

```bash
/schedule "Daily code review" --cron "0 9 * * MON"
```

Cloud-hosted agent runs on a schedule; sends results via email or webhook. Separate from interactive sessions (no `/resume` or context carryover).

### `/loop` (Recurring Prompts)

```bash
/loop 5m /my-skill  # Run /my-skill every 5 minutes
```

Runs prompt on interval; auto-stops if returns empty or error after 3 retries. Used for monitoring, background jobs.

### Agent Teams (Experimental; Disabled by Default)

Multiple Claude Code **sessions** working together:
- **Lead agent** spawns teammates
- **Teammates** have own context windows, communicate via shared task list
- **SendMessage tool** enables teammate-to-teammate messaging
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to enable

**vs. Subagents:**
- Subagents: workers inside your session, report back to you
- Agent teams: independent sessions, talk to each other directly

**Use case:** Parallel code review (security reviewer, performance reviewer, tests reviewer all working at once, discussing findings).

### Plugins & Marketplaces

**Plugin:** Package of skills, hooks, MCP servers, subagents.
- Namespace commands: `/myplugin:skill-name`
- Install from marketplace (GitHub, local path, etc.)
- Versioning & auto-updates

**Marketplace:** Catalog of plugins (YAML manifest + Git repo).
```json
{
  "name": "my-marketplace",
  "plugins": [
    {
      "name": "add",
      "source": "github/MountainUnicorn/add"
    }
  ]
}
```

Users run `/plugin marketplace add <URL>` → plugins auto-discover & install.

### MCP Servers & Tool Discovery

Connect external services (Slack, databases, GitHub, browsers) via **Model Context Protocol (MCP)**.

**Tool search:** If you have many MCP tools, Claude Code can defer tool schema fetching until needed (doesn't load all tool descriptions into context upfront).

**Scope:** Local → project → user hierarchy. Subagents can have their own MCP server config (inline or reference).

---

## 4. Model Lineup & Reasoning Capabilities

As of June 2026:

| Model | Input/Output (per MTok) | Best for | Context | Special |
|-------|-------------------------|----------|---------|---------|
| **Claude Opus 4.8** | $5 / $25 | Premium reasoning; complex agentic tasks | 1M | Native extended thinking; best reliability |
| **Claude Sonnet 4.6** | $3 / $15 (40% cheaper than Opus) | Production inference; routine tool use | 1M | Good balance; default choice |
| **Claude Haiku 4.5** | $1 / $5 (5x cheaper) | Extraction, routing, fast tasks | 200K | Lowest cost; fast |
| **Fable 5** | $10 / $50 | Specialized reasoning | 200K | Domain-specific (research-only preview) |

**Effort levels:**
- `low`, `medium`, `high`, `xhigh`, `max` (available per model)
- `ultracode` = `xhigh` + auto-workflow orchestration

**Context window:** Opus & Sonnet = 1M; Haiku = 200K. All benefit from prompt caching (replay cheaply).

---

## 5. Where Workflows & Subagents Overlap (and Diverge)

### Comparison Matrix

| Aspect | Subagents | Workflows | Agent Teams |
|--------|-----------|-----------|-------------|
| **What holds the plan?** | Claude, turn-by-turn | JavaScript orchestration script | Lead agent + shared task list |
| **Worker isolation** | Own context; report to you | Own context; report to script | Own context; message each other |
| **Scaling** | A few per turn (automatic delegation) | Dozens to hundreds (deterministic) | 5–10 peers (coordination overhead) |
| **Intermediate state** | Lives in main context | Lives in script variables | Lives in shared task list |
| **Repeatability** | Worker def is repeatable | Script is repeatable | Team config is repeatable |
| **When to use** | Quick focused workers | Large parallel audits, migrations, research | Complex cross-team collab, competing hypotheses |
| **Cost model** | Lower (results summarized) | Higher (many agents, no summarization) | Highest (each teammate is full session) |
| **Interruption** | Restarts the turn | Resumable (cached agent results) | Teammates can pause independently |

### Key Trade-off: Context vs. Orchestration

**Subagent pattern (current ADD):**
```
Main conversation (with full context) →
  spawns Explore subagent →
  Explore returns search results →
  results land in main context →
  Claude reasons over them
```
**Pro:** Main context sees intermediate work; can steer on the fly.
**Con:** Multiple agent results flood context; context window fills fast.

**Workflow pattern (new native capability):**
```
JavaScript orchestration (outside context) →
  spawns Agent 1, Agent 2, Agent 3 in parallel →
  script collects results in variables →
  script votes/filters/synthesizes →
  only final answer enters conversation
```
**Pro:** No intermediate result context bloat; deterministic; repeatable.
**Con:** Can't steer mid-run; Claude doesn't see intermediate work.

---

## 6. The Key Question: Where Does ADD Still Add Value?

### Native Workflows Make Hand-Rolled Swarms Redundant

A "swarm" in ADD terms = spawning parallel subagents + synthesis. **Workflows do exactly this, but in code.**

**Before Workflows:**
```
User: "audit the codebase"
Claude (turn 1): "I'll audit security, performance, and tests in parallel"
Claude (turn 2): [spawns 3 subagents, waits for results]
Claude (turn 3): [reads results, synthesizes, reports]
```
This ties up Claude's context across multiple turns.

**After Workflows:**
```
User: "ultracode: audit the codebase"
Claude: [writes audit.js workflow]
JavaScript runtime: [spawns 3 agents, collects results, filters]
Claude: [reads final report, not intermediate steps]
```
No context bloat; repeatable; pauseable.

**Verdict:** ADD's manual subagent spawning becomes obsolete for parallelization. Recommend migrating to native Workflows or Ultracode.

### Where a Methodology Plugin Still Wins

Workflows are the **execution layer**. A methodology plugin wraps workflows with:

1. **Specification capture** (interview before implementation)
2. **TDD scaffolding** (RED → GREEN → REFACTOR phases)
3. **Quality gates** (lint, type, test, spec compliance verification)
4. **Structured documentation** (project state, learnings, handoff)
5. **Naming conventions** (skill/workflow/agent naming; namespace consistency)
6. **Domain patterns** (architectural decisions, deployment strategies)

### Proposed ADD v1.0 Approach

Migrate from manual subagent spawning to:

**Tier 1: Skills + Workflows**
- `/add:spec` → skill that interviews user, writes spec
- `/add:tdd-cycle` → skill that orchestrates a Workflow:
  - Phase 1: Workflow spawns test-writer agents (parallel)
  - Phase 2: Workflow spawns implementer agents (parallel)
  - Phase 3: Workflow spawns verifier agents (parallel)

**Tier 2: Methodology Scaffolding**
- Spec schema validation (JSON schema in `core/schemas/`)
- Quality gate hooks (eslint, type check, test coverage)
- Learnings capture (MEMORY.md, structured notes)
- Handoff docs (`.add/handoff.md` on task completion)

**Tier 3: Agent Definitions**
- Subagents for specialized roles: `reviewer`, `implementer`, `researcher`
- Preload domain-specific skills (e.g., test-writer gets `/add:testing-patterns`)
- Persistent memory across projects (`~/.claude/agent-memory/`)

**Tier 4: Plugin Distribution**
- Skills, workflows, hooks, subagent defs in `plugins/add/`
- Publish to Claude Code marketplace
- Versioning via `core/VERSION` → auto-bumped in compiled output

---

## 7. Recent Features Summary (Quick Reference)

| Feature | Released | Purpose | Relevance to ADD |
|---------|----------|---------|------------------|
| **Workflows (Dynamic)** | May 2026 | Deterministic JS orchestration of subagents at scale | **High.** Replaces manual swarm spawning. |
| **Ultracode** | 2026 | xhigh reasoning + auto-workflow orchestration | **High.** Add `ultracode` as effort option in spec phase. |
| **Subagent nested spawning** | v2.1.172 | Agents can spawn sub-subagents (depth limit 5 bg) | Medium. Enables hierarchical task decomposition. |
| **Agent teams (exp.)** | v2.1.32 | Multi-session coordination with SendMessage | Medium. Overkill for most ADD workflows; useful for large research. |
| **Plan mode + Ultraplan** | 2026 | Read-only exploration; cloud-based planning UX | **High.** `/add:plan` should leverage plan mode. |
| **Skills improvements** | 2026 | Dynamic context injection; supporting files | **High.** Skills as first-class packaging; workflows use skills heavily. |
| **Hooks enhancements** | 2026 | SubagentStart, TaskCreated, TeammateIdle | **High.** Enforce quality gates (POST-edit linting, pre-commit checks). |
| **Marketplace v1** | 2026 | Plugin distribution, versioning, auto-updates | **Critical.** ADD ships as plugin; versioning tracked in `core/VERSION`. |
| **Managed settings** | 2026 | Org-wide skill/agent/MCP deployment | Medium. Enterprise teams can mandate ADD setup org-wide. |
| **Extended thinking** | 2025 | Claude thinks before responding (Opus/Sonnet) | Medium. Use for `/add:spec` interviews; cost-prohibitive for 1M+ token workflows. |
| **Prompt caching** | 2025 | Cache CLAUDE.md, skills, MCP schemas | **High.** ADD's large CLAUDE.md files benefit; workflows + prompt cache = cheap reruns. |

---

## 8. Concrete Recommendations for ADD v1.0 GA

### 1. Modernize Skill Library
- Merge `/add:batch` into `/add:cycle` (batch is now redundant with workflows)
- Rewrite `/add:tdd-cycle` to orchestrate via Workflow (not manual subagent spawning)
- Add `/add:ultracode` mode trigger in `/add:spec` and `/add:plan`

### 2. Introduce Structured Workflow Definitions
- `core/workflows/` directory
- JavaScript templates for common patterns:
  - `audit.js` (security + performance + tests in parallel)
  - `migration.js` (find files → refactor in parallel → verify)
  - `research.js` (fan-out searches, cross-check, synthesize)

### 3. Enhance Quality Gates
- Move linting/type-check from hooks to `PostWorkflow` verification phase
- Add spec compliance checker (JSON schema validation of spec vs. implementation)
- Integrate `/add:verify` as a workflow phase (not a skill)

### 4. Persist Learnings Automatically
- Hooks that populate `.add/learnings.json` on skill invocation
- Agent memory for per-role knowledge (e.g., `~/.claude/agent-memory/code-reviewer/`)
- Handoff generator that summarizes milestones + decisions

### 5. Distribute via Marketplace
- Finalize plugin.json schema
- Lock versioning (`core/VERSION` → plugin.json automatic)
- Test auto-update flow (marketplace webhook → new Claude Code session picks up changes)

### 6. Document Methodology Explicitly
- `docs/workflows.md` — when to use each workflow (audit, migrate, research, test)
- `docs/agent-roles.md` — subagent definitions and when Claude delegates to each
- `docs/quality-gates.md` — which hooks run, what they enforce, how to customize

### 7. Namespace Consistency
- All commands: `/add:skill-name` (not `/skill-name`)
- All agents: `add:agent-name` in definitions
- All workflows: `audit.js`, `migrate.js` (lowercase, hyphenated; not `AuditWorkflow.js`)

---

## 9. Reference URLs

**Official Documentation:**
- [Workflows](https://code.claude.com/docs/en/workflows.md)
- [Subagents](https://code.claude.com/docs/en/sub-agents.md)
- [Skills](https://code.claude.com/docs/en/skills.md)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide.md)
- [Agent Teams](https://code.claude.com/docs/en/agent-teams.md)
- [Features Overview](https://code.claude.com/docs/en/features-overview.md)
- [Permission Modes](https://code.claude.com/docs/en/permission-modes.md)
- [Model Config](https://code.claude.com/docs/en/model-config.md)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces.md)

**Blog Announcements:**
- [Introducing Dynamic Workflows](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)
- [Anthropic Blog: Claude Opus 4.8](https://www.anthropic.com/news/claude-opus-4-8)

---

## Appendix: Workflow Anatomy (Example)

```javascript
// audit.js — auto-generated by Claude for "audit every endpoint for auth checks"
// Runs in isolated runtime; spawns 3 agents in parallel; filters results via vote

const { agents } = require("claude-code");

async function audit() {
  // Phase 1: Find endpoints
  const findAgent = await agents.spawn({
    description: "Find API endpoints",
    model: "haiku",
    tools: ["Read", "Glob", "Grep"],
  });
  const endpoints = await findAgent.run(`Find all API endpoints in src/routes/`);

  // Phase 2: Audit in parallel (security, auth, error handling)
  const [securityAudit, authAudit, errorAudit] = await Promise.all([
    agents
      .spawn({
        description: "Security audit",
        model: "sonnet",
      })
      .run(`Audit these endpoints for XSS, injection, CORS: ${endpoints}`),
    agents
      .spawn({
        description: "Auth audit",
        model: "sonnet",
      })
      .run(`Check these endpoints for auth: ${endpoints}`),
    agents
      .spawn({
        description: "Error handling audit",
        model: "sonnet",
      })
      .run(`Audit error handling in: ${endpoints}`),
  ]);

  // Phase 3: Synthesize (vote on findings)
  const synthesizer = await agents.spawn({
    description: "Synthesize findings",
    model: "opus",
  });
  const report = await synthesizer.run(
    `Synthesize these audits:\n${securityAudit}\n${authAudit}\n${errorAudit}`
  );

  return report;
}

module.exports = { audit };
```

When user runs: `ultracode: audit every endpoint in src/routes/ for missing auth`

1. Claude writes something like the above
2. User approves the phases (or edits script in editor)
3. Runtime spawns agents per phase
4. Results stay in script variables
5. Final `report` lands in conversation
6. User can save as `/my-audit` for future reuse


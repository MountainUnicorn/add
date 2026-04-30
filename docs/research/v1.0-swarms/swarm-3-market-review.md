# Swarm 3 — Market Review for v1.0 Roadmap

**Perspective:** Outside-in. Where are Claude Code (Anthropic), Codex CLI (OpenAI), and third-party agentic-coding tools delivering high-value capabilities that ADD does NOT capture today?

**Date:** 2026-04-30
**Author:** Swarm 3 (market review)
**Source basis:** ~40 web searches across vendor changelogs, analyst pieces, OSS repos, conference posts, and standards bodies (Dec 2025 → Apr 2026)

---

## Executive Summary

The agentic-coding ecosystem since ADD's v0.7 split has shifted in five major ways:

1. **Cloud / scheduled / event-driven agents are mainstream** — Claude Code Routines (Apr 14, 2026), Cursor 3 cloud agents (Apr 2, 2026), Replit Agent 3 (200-min autonomy), and Notion Custom Agents (24/7) all ship multi-trigger execution surfaces. ADD's `/add:cycle` and `/add:away` are local-laptop primitives by comparison.
2. **Multi-agent UX is now visual** — Cursor 3's Agents Window and Windsurf Wave 13's tiled multi-agent panes treat agent fleets as a first-class UI surface. ADD's swarm worktrees are real and powerful, but invisible — there's no ADD-native dashboard for live agent fleets.
3. **Spec-driven development is consolidating around named, branded SDKs** — GitHub Spec Kit (~79k stars), OpenSpec (delta specs + ADRs), Kiro (AWS-native, spec is source-of-truth), BMAD, SpecWeave. Andrew Ng's DeepLearning.AI course (Apr 15, 2026) with JetBrains anchors a canonical curriculum that does NOT mention ADD.
4. **Persistent memory is becoming a separable, benchmarked layer** — MemPalace (96.6% R@5 on LongMemEval, 29 MCP tools), Letta/MemGPT (3-tier memory), Zep/Graphiti (temporal knowledge graph, 63.8% on LongMemEval), Mem0. ADD's `library.json` is hand-rolled and unbenchmarked.
5. **Skills-as-supply-chain is now a security category** — Snyk's ToxicSkills audit (Feb 5, 2026) found 36% of 3,984 audited skills had security flaws including 76 confirmed malicious payloads. Tessl + Snyk now run task-evals AND security scoring on every registered skill. ADD has a scanner for prompt injection in PROJECT files but no story for skill-marketplace consumption.

The big strategic question: ADD has been built as a **methodology adapter on top of host runtimes**. The market is rapidly absorbing methodology pieces (Plan Mode, Tasks DAG, Skills, AGENTS.md) into those runtimes themselves. ADD's moat now lives in **opinionated maturity-aware orchestration** — not in any single feature it provides.

---

## A. Top capabilities ADD doesn't capture (ranked)

### A1. Cloud / scheduled / event-triggered agent execution — MUST

**What it is:** Run agent sessions on remote infrastructure on a schedule, via webhook, or on GitHub events. Laptop closed.

**Where delivered:**
- **Claude Code Routines** (Apr 14, 2026, research preview, Pro/Max/Team/Enterprise) — schedule, API, GitHub triggers; runs in Anthropic's cloud. ([Anthropic announce via 9to5Mac](https://9to5mac.com/2026/04/14/anthropic-adds-repeatable-routines-feature-to-claude-code-heres-how-it-works/), [Builder.io tutorial](https://www.builder.io/blog/claude-code-routines))
- **Cursor 3 cloud agents** (Apr 2, 2026) — local-cloud handoff; fleet visibility from sidebar; self-hosted option for enterprise. ([cursor.com/changelog/3-0](https://cursor.com/changelog/3-0), [InfoQ analysis](https://www.infoq.com/news/2026/04/cursor-first-interface/))
- **Notion Custom Agents** (Feb 24, 2026) — 24/7 across Slack/Gmail/Calendar/Linear/Figma; 21,000+ built in beta. ([Notion 3.3 release](https://www.notion.com/releases/2026-02-24))
- **Replit Agent 3** — 200-minute autonomous loops. ([Replit blog](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet))

**Adoption signal:** Claude Code Routines launched 16 days ago with rapid uptake; multiple "indie maker / cron replacement" articles appeared within days. Cursor 3 was a free upgrade to all subscribers (Cursor has >$500M ARR pace based on industry trackers).

**Why it matters for ADD users:** Maturity ladder + away mode + cycle planning are *exactly* the workloads that benefit from scheduled/triggered execution: nightly verify, weekly retro, on-PR-open spec compliance check, monthly milestone-snapshot dashboard regeneration.

**ADD implementation surface:**
- New skill `/add:routine` + new template that emits a routine descriptor
- Adapter layer: emit Claude Code Routine YAML *and* GitHub Actions workflow *and* cron expression so ADD remains runtime-neutral
- Hook into `.add/away.md` so an "away" declaration optionally creates a Routine

**Difficulty:** Medium (no model work — adapter + template work)

**Strategic priority:** **MUST**. Largest single capability gap; aligns directly with the away/cycle skills ADD already invented.

---

### A2. Multi-agent fleet visualization (live dashboard) — SHOULD

**What it is:** A UI surface that shows every running agent across local worktrees + cloud, their current task, last action, and cost.

**Where delivered:**
- **Cursor 3 Agents Window** — sidebar of all running agents; Agent Tabs (grid/side-by-side); Cursor 3.1 added tiled layout. ([Cursor 3.1 changelog](https://cursor.com/changelog/3-1))
- **Windsurf Wave 13** — up to 5 parallel agents in isolated worktrees, dockable Cascade panes, dedicated agent terminal. ([Wave 13 byteiota review](https://byteiota.com/windsurf-wave-13-free-swe-1-5-parallel-agents-escalate-ai-ide-war/))
- **Augment Code Intent** — standalone macOS workspace for multi-agent orchestration. ([SiliconAngle Feb 6, 2026](https://siliconangle.com/2026/02/06/augment-code-makes-semantic-coding-capability-available-ai-agent/))

**Adoption signal:** Cursor 3 was THE coding-agent news of April 2026 (InfoQ, Futurum, DataCamp coverage within 7 days of launch). The "Agents Window" has been reproduced as a first-class concept in Windsurf, Augment Intent, and Replit's Agent UI.

**Why it matters for ADD users:** ADD has invented swarm worktrees and used them repeatedly across the v0.9.x arc — but the user has no live view of swarm state outside `git worktree list` + tail of session logs. The dashboard skill exists for project state, not for live agent state.

**ADD implementation surface:**
- Extend `/add:dashboard` with a "live swarms" pane reading `.claude/worktrees/agent-*/`
- Or: new skill `/add:swarm-status` emitting a stable HTML page agents can refresh
- Crucially: ADD does *not* need to build an IDE — just structured artifacts that the host IDE / web view can consume

**Difficulty:** Small to Medium

**Strategic priority:** **SHOULD**. ADD already has the swarm pattern; not having a status surface means power-users build it themselves.

---

### A3. Skill task-evals + skill security scoring — MUST

**What it is:** Automated evaluation that a skill actually steers agent behavior in measurable ways, plus security scanning of skill bundles before consumption.

**Where delivered:**
- **Tessl Registry** — task evals as a built-in capability; submit skill, get score and improvements. ([Tessl Task Evals announcement](https://tessl.io/blog/introducing-task-evals-measure-whether-your-skills-actually-work/))
- **Snyk + Tessl partnership** — every skill in the registry gets a security score. ([Snyk-Tessl partnership announcement](https://snyk.io/blog/snyk-tessl-partnership/))
- **Snyk ToxicSkills audit** (Feb 5, 2026) — 3,984 skills audited, 36% had flaws, 1,467 vulnerable, 76 confirmed malicious payloads, 13.4% had critical issues. ([Snyk audit](https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/))
- Real-world Tessl impact: oauth skill 22% → 100%, fastify 48% → 100% after eval-driven improvement. ([Tessl Matteo Collina case study](https://tessl.io/blog/introducing-task-evals-measure-whether-your-skills-actually-work/))

**Adoption signal:** ToxicSkills coverage hit InfoQ, AICerts, Practical DevSecOps, NeuralTrust within 10 days. Daily skill submissions to public marketplaces went from <50 (mid-Jan) to >500 (early Feb), a 10x in weeks — and 36% are flawed.

**Why it matters for ADD users:** ADD has 27 skills as of v0.9.4. There's no objective measure that they steer behavior, no way to detect drift when the underlying model changes, and no defense if a community PR adds a skill with a smuggled instruction.

**ADD implementation surface:**
- New skill `/add:eval-skills` running task-evals against ADD's own skills (per LangChain's six categories: file ops, retrieval, tool use, memory, conversation, summarization)
- Extend the existing `executable scanner` (v0.9.3) to scan `core/skills/**/SKILL.md` for prompt-injection patterns
- Optional: publish ADD skills to Tessl Registry for external scoring

**Difficulty:** Medium (requires building eval harness; could borrow LangChain Deep Agents Eval)

**Strategic priority:** **MUST**. Aligns with EU AI Act August 2026 requirements (auditability, technical documentation) — not optional for enterprise adoption.

---

### A4. Persistent task DAG across sessions — SHOULD

**What it is:** Tasks (not todos) with dependencies, blocked-by relationships, and durable state across terminals/machines/sessions. The "hallucinated completion" defense.

**Where delivered:**
- **Claude Code Tasks** (Jan 2026, v2.1.16, with Opus 4.5) — DAG-based, stored at `~/.claude/tasks`, shareable across sessions via `CLAUDE_CODE_TASK_LIST_ID`. ([VentureBeat coverage](https://venturebeat.com/orchestration/claude-codes-tasks-update-lets-agents-work-longer-and-coordinate-across), [ClaudeArchitect guide](https://claudearchitect.com/docs/claude-code/claude-code-tasks-guide/))
- **TaskMaster** — companion to BMAD, separately popular for task management
- **Spec Kit** — `/specify → /plan → /tasks → /implement` is its own task primitive

**Adoption signal:** Claude Code Tasks was a v2.1.16 marquee feature; every Claude Code review since Jan covers it. BMAD + TaskMaster combo is the dominant agentic-Agile pattern.

**Why it matters for ADD users:** ADD's `/add:cycle` produces a plan; `/add:plan` produces a step list. But once execution begins there's no durable DAG — if an agent crashes mid-cycle, the next agent rebuilds the plan from spec rather than picking up where the last left off.

**ADD implementation surface:**
- ADD already has `.add/handoff.md` and milestone tracking; the gap is the **machine-readable DAG with blocked-by edges**
- New schema in `core/schemas/` for task graph; `/add:cycle` emits it; `/add:tdd-cycle` consumes it
- Bridge: emit Claude Code Tasks-format JSON when running on Claude runtime so the host engine sees the same DAG

**Difficulty:** Medium

**Strategic priority:** **SHOULD**. Not load-bearing for v1.0 but increasingly expected.

---

### A5. Built-in evaluation harness for the methodology itself — SHOULD

**What it is:** Run the agent loop against benchmark tasks, measure correctness/step-ratio/tool-call-ratio/latency-ratio/solve-rate, and use those metrics to gate releases of the methodology.

**Where delivered:**
- **LangChain Deep Agents Eval** (Mar 2026) — 6 capability categories, 5 core metrics, hand-crafted + dogfooded + benchmark-sourced (Terminal Bench 2.0, Berkeley BFCL). ([LangChain blog](https://blog.langchain.com/how-we-build-evals-for-deep-agents/))
- **Braintrust** — CI/CD merge-blocking on eval regressions, 1M free trace spans. ([Braintrust LLM tracing guide](https://www.braintrust.dev/articles/best-llm-tracing-tools-2026))
- **Tessl Task Evals** — per-skill evals
- **DeepEval** (Confident AI) — open-source LLM eval framework

**Adoption signal:** LangChain's "more evals don't make better agents" framing has become the canonical 2026 evals piece. Every serious agent product team now ships an eval suite.

**Why it matters for ADD users:** ADD ships a methodology. Right now the only validation is "does the test suite pass after CompileFlow runs." There's no measurement of whether `/add:spec` actually produces specs that survive `/add:plan` without rework, or whether `/add:tdd-cycle` actually closes specs vs. claiming to.

**ADD implementation surface:**
- New `evals/` directory in `core/` (parallel to `skills/`, `rules/`)
- Per-skill eval YAML: input fixture, expected behavioral signature, scoring rule
- New skill `/add:eval` running the harness; CI gate
- Tie into telemetry (v0.9.0+ already emits OTEL JSONL — feed that into eval scoring)

**Difficulty:** Large (genuine eval infrastructure)

**Strategic priority:** **SHOULD**. The methodology is now mature enough that "we shipped it" is no longer enough; "we measured it works" is the next bar.

---

### A6. Persistent semantic / temporal memory layer — COULD

**What it is:** A memory store that survives sessions, supports temporal queries ("what was the schema in Q3?"), and is benchmarkable.

**Where delivered:**
- **MemPalace** (Apr 8, 2026) — local-first, 29 MCP tools, 96.6% raw / 98.4% hybrid R@5 on LongMemEval, ChromaDB+SQLite, no cloud. ([MemPalace AI Memory System](https://recca0120.github.io/en/2026/04/08/mempalace-ai-memory-system/))
- **Zep / Graphiti** — temporal knowledge graph, 63.8% LongMemEval (GPT-4o), open-source Graphiti core. ([Zep Graphiti](https://www.getzep.com/product/open-source/))
- **Mem0** — dual-store (vector + graph), 49.0% LongMemEval, fastest path to production, broad ecosystem. ([Mem0 vs Zep](https://vectorize.io/articles/mem0-vs-zep))
- **Letta/MemGPT** — 3-tier memory (core/recall/archival) as runtime; Letta Code (memory-first coding agent). ([Letta blog](https://www.letta.com/blog/letta-code))

**Adoption signal:** MemPalace hit 43k stars/week (per ADD's own M3 milestone notes); "best AI memory frameworks 2026" pieces now standard. Letta is becoming infrastructure for agent runtimes.

**Why it matters for ADD users:** ADD's cross-project learning at `~/.claude/add/library.json` is a flat JSON list. No temporal validity, no semantic search, no benchmark.

**ADD implementation surface:**
- ADD should NOT build a memory engine. ADD should *integrate* with one (likely MCP-based) and provide the semantic layer on top: "what learnings apply to this maturity level / this stack / this milestone?"
- New skill `/add:memory-sync` with adapters for MemPalace MCP and Mem0 MCP
- Keep `library.json` as canonical local cache, sync to memory layer

**Difficulty:** Medium (integration, not engine work)

**Strategic priority:** **COULD**. ADD's library serves the basic case adequately today; this is a power-user upgrade path.

---

### A7. Computer use / visual feedback for spec verification — COULD

**What it is:** Agent takes screenshots, clicks buttons, reads UI state, and verifies that implemented features actually work in the running app.

**Where delivered:**
- **Claude Code Computer Use** (Q1 2026) — full screenshot+mouse+keyboard control loop. ([Claude Code computer-use docs](https://code.claude.com/docs/en/computer-use))
- **Cursor 3 Design Mode** — annotate UI elements directly in browser, give precise visual feedback. ([Cursor 3 design mode](https://www.digitalapplied.com/blog/cursor-3-agents-window-design-mode-complete-guide))
- **Replit Agent 3 self-healing loop** — opens browser, clicks every button, screenshots, verifies before reporting done. ([Replit Agent 3 review](https://leaveit2ai.com/ai-tools/code-development/replit-agent-v3))

**Adoption signal:** Computer use moved from beta curiosity to "every agent's verification loop" between Q4 2025 and Q1 2026. Replit's self-healing loop is the new bar for "agent says it's done."

**Why it matters for ADD users:** ADD's `/add:verify` runs lint+type+test+coverage. That's necessary but not sufficient — the spec might say "user can submit a form" and tests might pass while the form is broken.

**ADD implementation surface:**
- New maturity-aware behavior at beta+: `/add:verify` invokes computer use to walk acceptance criteria
- Conditional on environment having a runnable preview (web app, mobile app)
- Strict: only at beta+ to avoid heavy dependency burden on POCs

**Difficulty:** Medium

**Strategic priority:** **COULD**. Powerful but heavy; defer unless beta-ladder users specifically request.

---

### A8. AGENTS.md as canonical agent-instruction surface — SHOULD

**What it is:** Single file at repo root that any tool-agnostic coding agent reads for project-specific guidance. Now stewarded by Linux Foundation's Agentic AI Foundation.

**Where delivered:**
- **AGENTS.md** — adopted by 60,000+ open source projects per Linux Foundation; supported by Codex, Cursor, Devin, Factory, Gemini CLI, GitHub Copilot, Jules, VS Code. ([AAIF announcement](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation), [agents.md](https://agents.md/))

**Adoption signal:** Donated to Linux Foundation Agentic AI Foundation Dec 2025 alongside MCP and goose. 60k+ adopters as of early 2026; OpenAI's main repo alone has 88 AGENTS.md files.

**Why it matters for ADD users:** ADD already ships `/add:agents-md`. **This is captured.** But: ADD's generation is one-shot. Spec-kit and Kiro keep AGENTS.md *living* as specs evolve. Risk: ADD's static generation falls behind a moving spec.

**ADD implementation surface:**
- `/add:agents-md` should hook into spec lifecycle so updates to specs propagate
- Add post-spec-edit hook that regenerates AGENTS.md sections referencing that spec

**Difficulty:** Trivial to Small (extension of existing skill)

**Strategic priority:** **SHOULD**. Already in ADD; the gap is keeping it living, not having the feature.

---

### A9. Plan Mode as first-class read-only research phase — SHOULD

**What it is:** A mode where the agent ONLY explores and produces a plan; no edits possible. Activated by Shift+Tab Shift+Tab in Claude Code.

**Where delivered:**
- **Claude Code Plan Mode** (Dec 2025+, GA in Q1 2026) — read-only, structured 4-phase explore/plan/implement/commit. ([Plan Mode complete guide 2026](https://www.getaiperks.com/en/articles/claude-code-plan-mode), [Armin Ronacher's analysis](https://lucumr.pocoo.org/2025/12/17/what-is-plan-mode/))
- **Windsurf Plan Mode** (Wave 13) — alongside Code and Ask modes
- **Spec Kit** — `/specify → /plan → /tasks → /implement` is the same shape as a workflow

**Adoption signal:** Plan Mode is now the recommended Claude Code default workflow per Anthropic best practices.

**Why it matters for ADD users:** ADD's `/add:spec` and `/add:plan` are spec-driven equivalents — but they emit artifacts; they don't enforce read-only execution. An impatient agent can run `/add:plan` and `/add:tdd-cycle` in the same turn, skipping the plan-review checkpoint.

**ADD implementation surface:**
- ADD already has the artifacts; the gap is *enforcement*
- Add a hook: while a plan is in `pending-review` state, deny write tools
- Or: codify a "planning maturity" signal that rules check

**Difficulty:** Small

**Strategic priority:** **SHOULD**. Enforces what `/add:plan` already implies.

---

### A10. Tool-agnostic skill packaging — COULD

**What it is:** A skill bundle that runs identically on Claude Code, Codex CLI, Cursor, Continue, Cline, etc. without per-runtime adapter code.

**Where delivered:**
- **Anthropic SKILL.md spec** open-sourced Dec 2025; adopted by OpenAI for Codex CLI and ChatGPT.
- **agentskills.io** — open standard with reference validator (skills-ref). ([agentskills.io](https://agentskills.io/home))
- **SpecWeave** — 100+ skills working across Claude Code, Cursor, Copilot, Codex, Antigravity ([SpecWeave repo](https://github.com/anton-abyzov/specweave))
- **OpenSpec** — 30+ assistants supported via tool-agnostic spec deltas

**Adoption signal:** Tool-agnostic is now the default expectation. SKILL.md is the universal format.

**Why it matters for ADD users:** ADD is already runtime-neutral via `core/` + adapters. But the runtime adapters are *ADD-built*. Hosts now ship their own SKILL.md loaders, which means ADD's adapter layer is doing work the host now does natively.

**ADD implementation surface:**
- Audit `runtimes/claude` and `runtimes/codex` for what's still load-bearing vs. what was made redundant by Anthropic/OpenAI shipping SKILL.md natively
- Likely: simplify the Codex adapter; let the host handle SKILL.md loading; keep ADD's ADD-specific scaffolding

**Difficulty:** Medium (architectural review)

**Strategic priority:** **COULD**. Cleanup that reduces ADD's surface area.

---

### A11. (Bonus) Routine + GitHub event triggers — MUST (overlap with A1)

Already covered in A1 but worth flagging: GitHub event triggers (PR opened, release tagged) are now first-class for Claude Code Routines and Cursor cloud agents. ADD should treat the GitHub event surface as a deployment target.

---

### A12. (Bonus) Repo-map / PageRank-based context selection — COULD

Aider's repo-map (NetworkX PageRank over tree-sitter symbol graph, 130+ languages, dynamic token budget) is now widely copied. Cody, Augment, Sourcegraph all do variants. ADD's context selection is implicit — agent reads CLAUDE.md + browses files. ([Aider repo-map](https://aider.chat/docs/repomap.html))

**Implementation surface:** ADD doesn't index code. This is a host-runtime concern. ADD just has to ensure its rules don't fight whatever the host repo-map produces.

**Strategic priority:** **DEFER**. Host responsibility.

---

## B. Convergent themes — where the market is heading

### B1. Persistent task state across sessions

**Where market is going:** Every major agent now has DAG/task-graph primitives that survive process death. Claude Code Tasks (`~/.claude/tasks`), Cursor 3 (cloud handoff), Replit Agent 3 (200-min sessions), BMAD + TaskMaster.

**Where ADD aligns:** Specs + milestones + cycles are durable artifacts. `.add/handoff.md` is durable.

**Where ADD lags:** No machine-readable DAG with blocked-by edges. Recovery from crash mid-cycle requires re-planning.

---

### B2. Visual multi-agent orchestration UX

**Where market is going:** Cursor 3 / Windsurf Wave 13 / Augment Intent — agents-as-fleet is a UI metaphor, not just a process metaphor.

**Where ADD aligns:** Swarm worktrees demonstrably work; ADD has used them across the v0.9.x arc.

**Where ADD lags:** No live status surface. Power users tail logs and run `git worktree list`.

---

### B3. Spec-first as table stakes (with strong branding war)

**Where market is going:** Spec Kit (~79k stars), OpenSpec (delta + ADR), Kiro (AWS-native), BMAD (BMAD-METHOD), SpecWeave (100+ skills), Devin's spec-mode pattern, DeepLearning.AI course (Apr 15, 2026).

**Where ADD aligns:** ADD is genuinely spec-first. `/add:spec` predates most named SDD frameworks.

**Where ADD lags:** No brand recognition in spec-driven discourse. The Andrew Ng course doesn't mention ADD. ADD is invisible in "best SDD tools 2026" listicles. SpecWeave's marketing positions are sharper.

---

### B4. Built-in evaluation surfaces

**Where market is going:** Tessl per-skill evals, LangChain Deep Agents Eval (6 categories, 5 metrics), Braintrust CI-merge-blocking, DeepEval, every observability vendor (Helicone/Langfuse/Phoenix) shipping eval primitives.

**Where ADD aligns:** ADD emits OTEL GenAI JSONL (v0.9.0+).

**Where ADD lags:** Telemetry without an eval harness is data without judgment. ADD doesn't measure whether its own methodology works.

---

### B5. MCP as the integration substrate

**Where market is going:** 10,000+ public MCP servers, 97M+ monthly SDK downloads, donated to Linux Foundation alongside AGENTS.md. Every coding agent (Claude Code, Cursor, Windsurf, Cline, Continue, Codex, VS Code Copilot, Zed, Replit) speaks MCP.

**Where ADD aligns:** ADD doesn't fight MCP. Skills can invoke MCP tools.

**Where ADD lags:** ADD doesn't *expose itself* as an MCP server. A team using Cursor 3 can't pull in `/add:spec` without installing ADD as a plugin.

---

### B6. Routines / scheduled / event-driven execution

**Where market is going:** Claude Code Routines (Apr 14, 2026), Cursor cloud agents, Notion 24/7 custom agents, Replit Agent 3 200-min sessions, GitHub event triggers across the board.

**Where ADD aligns:** `/add:away` declares an absence. That's *adjacent* to a routine but not the same thing.

**Where ADD lags:** ADD has no concept of scheduled execution. The away-mode autonomous-work-list is local-laptop-only.

---

### B7. AGENTS.md as cross-tool standard

**Where market is going:** Linux Foundation stewardship; 60k+ projects; 100% adoption across major coding agents.

**Where ADD aligns:** `/add:agents-md` exists.

**Where ADD lags:** Static generation; no live-sync to specs.

---

### B8. Skill supply-chain security as a first-class category

**Where market is going:** Snyk ToxicSkills audit, Tessl + Snyk security scoring, SkillShield, OWASP Top 10 for Agentic Apps 2026, EU AI Act August 2026.

**Where ADD aligns:** v0.9.3 added executable scanner + prompt-injection-defense rule + threat model + GPG-signed releases.

**Where ADD lags:** Defense-in-depth at the *skill* level (rather than the project consuming skills). No registry score for ADD's own skills.

---

## C. Differentiators we should DOUBLE DOWN on

### C1. Maturity-aware behavior (poc → alpha → beta → ga)

**Why it's a moat:** No other tool ships a maturity ladder that governs rigor. Spec Kit is one-size. BMAD has phases but not maturity stages. Kiro's spec-driven approach assumes production from day one. The poc → ga ladder is genuinely ADD's invention.

**Why it aligns with the market:** The Anthropic 2026 Agentic Coding Trends Report explicitly calls out the gap between "60% of work delegated to AI" and "0–20% trusted without oversight" — i.e., the trust-gradient is THE 2026 problem. The maturity ladder *is* a trust-gradient framework.

**Recommendation:** Lean in. Make maturity a bigger pillar of v1.0 marketing. Maturity-cascading rules are uniquely ADD.

---

### C2. Methodology as canonical artifact (spec + plan + cycle + retro + milestone)

**Why it's a moat:** The full lifecycle is structured. Most competitors have *parts* — Spec Kit has spec+plan+tasks; OpenSpec has propose+apply+archive; BMAD has roles+phases — but none has the loop *from feature inception through retrospective with cross-project learning*.

**Why it aligns with the market:** "Living spec" is a 2026 buzzword. ADD's lifecycle is genuinely living.

**Recommendation:** Position ADD as "the methodology, not the tool." Skills happen to be the implementation; the methodology is the value.

---

### C3. Multi-runtime neutrality from `core/`

**Why it's a moat:** Cursor, Cline, Copilot — every other agent is bound to its host. ADD compiles from `core/` to multiple runtimes. The user's investment in spec/plan/cycle artifacts isn't held hostage by Anthropic shipping a breaking change.

**Why it aligns with the market:** SpecWeave, OpenSpec, BMAD also claim tool-agnostic. ADD has actually shipped a working multi-runtime build (Claude + Codex). This is rare.

**Recommendation:** Add Cursor and Cline as runtime adapters in v1.0. Don't pick a horse — the user picks the horse, ADD adapts.

---

### C4. TDD-deletion guardrail + test-count gate

**Why it's a moat:** This is unique. No other tool prevents the "agent silently deletes tests to make verify pass" failure mode. It's a small thing but it's load-bearing for trust.

**Why it aligns with the market:** OWASP Top 10 for Agentic Apps 2026 calls out "agent self-modifies to bypass guardrails" as a recursive-hijacking class. ADD's test-count gate is a concrete defense.

**Recommendation:** Document this prominently; package it as a standalone hook that can run alongside any methodology.

---

## D. Differentiators we should ABANDON

### D1. ADD's bespoke hook system (where it duplicates host hooks)

Both Claude Code (PostToolUse, PostToolUseFailure with `duration_ms`, etc.) and Codex CLI (now-stable hooks observing MCP tools and apply_patch) have shipped robust native hooks. ADD's hook system was load-bearing in v0.7-v0.8 when host support was thin. Now it's mostly redundant.

**Recommendation:** Audit which ADD hooks ship behavior the host doesn't. Keep those. Migrate the rest to a thin layer that delegates to host hooks. Don't pretend ADD's hook system is differentiated.

### D2. ADD-managed cross-project learning storage

`~/.claude/add/library.json` is hand-rolled. Mem0/Letta/MemPalace are professionally-built memory engines with benchmarks. ADD's library was useful in 2025 when no good option existed. In 2026 it's a maintenance liability.

**Recommendation:** Keep `library.json` as a *cache* (deterministic, version-controllable). Make the canonical store pluggable via an MCP memory adapter. Default to MemPalace local-first if present, else fall back to library.json.

### D3. Manual SVG infographic regeneration

Not a methodology gap, but: every major tool now has dynamic dashboards (Cursor sidebar, Honeycomb Canvas, Augment Intent). ADD's hand-drawn infographic in docs/ is impressive but is investment that doesn't scale. The dashboard skill should produce HTML; the infographic should be a snapshot from data, not a hand-tuned artifact.

**Recommendation:** Auto-generate SVG from a data file; stop hand-tuning offsets.

### D4. Rules as the ONLY behavioral surface

ADD has 19 auto-loading rules cascading by maturity. The market is moving toward Skills + Hooks + AGENTS.md + on-demand-loaded references (which ADD's PR #6 v0.9.2 already partially adopts). Rules-as-the-only-mechanism is brittle when host runtimes ship competing autoload mechanisms.

**Recommendation:** Position rules as one layer among (Skills, Rules, Hooks, AGENTS.md, References). Don't double-down on rules being THE mechanism.

---

## E. Risks to ADD's position

### E1. Anthropic native-shipping a feature ADD provides

**Concrete examples shipped 2026 already:**
- Claude Code Tasks (Jan 2026, v2.1.16) overlaps with `/add:cycle` task list
- Plan Mode (Q1 2026) overlaps with `/add:plan` enforcement
- Routines (Apr 14, 2026) overlaps with `/add:away` autonomous mode
- Skills + Sub-agents native overlaps with ADD's orchestration pattern
- Computer Use (Q1 2026) covers verification gap ADD doesn't cover

**Risk severity:** HIGH and ONGOING. Anthropic has shipped overlapping features in 4 of the last 4 quarters.

**Mitigation:** Lean into methodology + maturity; treat overlapping features as adapters to add to ADD's surface.

---

### E2. Codex changing schema again — v0.122 pin is brittle

Codex is at v0.140+ as of April 2026 per the changelog. ADD pins to v0.122. Codex has shipped: stable hooks, app-server unix socket, permission profiles round-tripping, AWS/Bedrock model-discovery, Codex exec --json reasoning tokens. ADD is ~18 versions behind on the Codex side.

**Risk severity:** HIGH. The pin will eventually break.

**Mitigation:** v1.0 should re-baseline the Codex adapter and either pin a recent stable version or move to "latest minor of Codex CLI tested in CI."

---

### E3. AGENTS.md spec ecosystem outpacing `/add:agents-md`

Linux Foundation stewardship + 60k adopters + tool-vendor support. The standard will evolve. `/add:agents-md` is currently a one-shot generator. If AGENTS.md adds extension points (skills section, MCP server section, eval section), ADD's generator may produce stale files.

**Risk severity:** MEDIUM.

**Mitigation:** Subscribe to AAIF; track AGENTS.md evolution; make `/add:agents-md` schema-driven so new sections can be added by editing a template, not the skill body.

---

### E4. Spec Kit + DeepLearning.AI course consolidating "spec-driven" canonical

GitHub backing + Andrew Ng's course + JetBrains partnership = the textbook canonical for spec-driven development. ADD is invisible in this curriculum.

**Risk severity:** MEDIUM-HIGH (brand risk).

**Mitigation:** ADD should ship a "compatibility layer" with Spec Kit's `/specify → /plan → /tasks → /implement` so users coming from the course can map onto ADD's flow without relearning. Or invest in producing comparable educational content.

---

### E5. MCP server explosion making methodology plugins less load-bearing

10,000+ MCP servers means agents can pull in capability without loading a methodology plugin. The "ADD" vs "20 random MCP servers" comparison may favor MCP for users who don't want opinionated structure.

**Risk severity:** MEDIUM.

**Mitigation:** Expose ADD as an MCP server. Don't compete with MCP — be a producer of it. `/add:spec`, `/add:plan`, `/add:cycle` as MCP tools means a Cursor/Windsurf user gets ADD without installing a plugin.

---

### E6. Skill marketplace security collapse

Per Snyk: 36% of public skills have flaws. As marketplaces grow, the signal-to-noise ratio drops. Users will bias toward "first-party only" or "registry-verified only."

**Risk severity:** MEDIUM.

**Mitigation:** Submit ADD's skills to Tessl Registry; pursue Snyk security scoring; publish task-eval scores. Be in the trusted corner from the start.

---

### E7. EU AI Act August 2026 requirements landing on agentic-coding tools

Article 12 logging, Article 14 oversight, Article 18 documentation, Article 19 6-month log retention. High-risk AI systems must allow automatic event recording over the system's lifetime. Multi-agent pipelines layer compliance — orchestrator obligations don't transfer to GPAI provider.

**Risk severity:** MEDIUM (depends on user base; HIGH for any enterprise pursuit).

**Mitigation:** ADD already emits OTEL JSONL — formalize that as the Article 12 log substrate. Document this in the security posture page.

---

### E8. Cursor 3's "agent execution runtime" framing absorbs the orchestration role

Per Futurum: Cursor 3.2 reframes the IDE as an agent execution runtime. The user's primary surface is the IDE, not the methodology. If Cursor (or VS Code/Copilot) ships first-class spec/plan/cycle phases, ADD's methodological role gets squeezed between IDE and host runtime.

**Risk severity:** MEDIUM-HIGH long term.

**Mitigation:** Be the methodology that runs on top of any execution runtime. Don't compete with IDEs; complement them.

---

## F. Capability-family direction

The user's stated goal: ADD evolves into "a family of loosely coupled capabilities that enhance agent driven development."

### F1. What should be IN the family (ADD core)

These align with ADD's moats and methodology:

1. **Spec / Plan / Cycle / Retro / Milestone** primitives — the methodology lifecycle artifacts. Unique to ADD.
2. **Maturity ladder** (poc → alpha → beta → ga) — unique to ADD; is the trust-gradient implementation.
3. **Maturity-aware rule cascade** — unique to ADD.
4. **Sub-agent orchestration roles** (test-writer / implementer / reviewer / verify) — useful methodological scaffolding.
5. **TDD-deletion guardrail / test-count gate** — load-bearing trust mechanism.
6. **Swarm worktree pattern** + a *new* live status surface (A2 above).
7. **AGENTS.md generation** that lives with specs (A8 above).
8. **Cross-project learnings library** (canonical schema, regardless of storage backend).

### F2. What should be SEPARATE (ADD integrates with)

Capabilities the market does better as standalone tools:

1. **Persistent memory engine** — Mem0 / MemPalace / Letta. ADD calls; doesn't build.
2. **Eval harness infrastructure** — LangChain Deep Agents Eval, Braintrust, Tessl Task Evals. ADD plugs in.
3. **Telemetry backend** — OTEL emission stays in ADD; storage/UI is Honeycomb/Langfuse/Helicone/Sentry. Don't build a backend.
4. **Skill registry** — Tessl. ADD publishes there; doesn't host.
5. **MCP tools (tool-call surface)** — ADD doesn't ship MCP servers for git/filesystem/etc. Use what's there.
6. **Computer use / visual feedback** — Anthropic's beta, Cursor's design mode. ADD calls when at beta+ maturity.
7. **Code search / repo-map** — Aider/Cody/Augment/Sourcegraph. Host responsibility.
8. **Cloud execution / scheduling** — Claude Code Routines / Cursor cloud / GitHub Actions. ADD emits descriptors.

### F3. Where the M4 "core / runtime adapters / overlays" architecture aligns

**Aligns with market:**
- Multi-runtime is the right bet. Cursor + Claude Code + Codex + Cline + Continue all want SKILL.md content.
- `core/` as canonical source-of-truth tracks how OpenSpec, SpecWeave, BMAD position themselves.
- Adapters as thin runtime-specific layers tracks the AGENTS.md pattern (one file per repo, agent picks it up).

**Doesn't yet align:**
- "Overlays" needs to be more concretely defined. Is it MCP integrations? Plugin extensions? Maturity-level rule packs? The market language is "skills + hooks + MCP + memory." ADD should pick mappings.
- `core/` needs an MCP server emission target alongside Claude/Codex adapters. M4's "runtime adapters" should explicitly include MCP-as-runtime.

**Recommendation:** Add to M4 architecture:
- **Runtime adapters:** Claude Code, Codex CLI, Cursor, Cline, MCP server, GitHub Actions (for Routines).
- **Overlays:** Maturity packs (poc/alpha/beta/ga), domain packs (web-app / cli / library), language packs (TypeScript / Python / Rust). All compile from `core/` with profile selection.

---

## G. Cross-cutting market observations

### G1. The "agent execution runtime" reframe

Cursor 3.2, Honeycomb's Canvas-as-AI-investigation-surface, Augment Intent — these all reframe the *IDE itself* as the substrate where agents execute. ADD has been aware of this (multi-runtime adapter). But as Cursor/Cline/Copilot continue absorbing methodology features, the IDE-as-runtime layer will compete for ADD's role.

**ADD's response:** Be useful WITHIN those runtimes. Be the methodology layer that runs across all of them, never below them.

### G2. Branding war on spec-driven

Spec Kit (~79k stars), OpenSpec (Thoughtworks Radar), Kiro (AWS-branded), BMAD (free, popular), SpecWeave (cross-tool). ADD has the deepest methodology but the weakest brand in this space. The DeepLearning.AI course alone could mainstream Spec Kit's vocabulary as canonical.

**ADD's response:** Decide if "ADD" is the brand to push, or if the methodology should be branded separately (the "Agent Driven Development methodology"), allowing ADD-the-plugin to be one of many implementations.

### G3. Memory is becoming a benchmarked layer

LongMemEval scores published; MemPalace, Zep, Mem0 all benchmark publicly. The conversation has shifted from "do agents have memory" to "how good is the memory."

**ADD's response:** Don't try to build a memory engine. Integrate with the benchmarked options; provide a methodology-aware semantic layer (filter learnings by maturity / by stack / by milestone).

### G4. Security-first messaging is now mandatory

ToxicSkills audit, OWASP Top 10 for Agentic Apps 2026, Snyk-Tessl partnership, EU AI Act enforcement. ADD's v0.9.3 work was prescient. v1.0 should make security posture front-and-center on the website and README, not buried.

**ADD's response:** Promote security messaging to top-level marketing. Add a `SECURITY.md` covering threat model, scanner output, GPG signing, OTEL audit trail, EU AI Act mapping.

### G5. Eval-driven release gating

LangChain's Deep Agents Eval framework + Braintrust merge-blocking + Tessl per-skill evals = "eval failures block CI" is the new normal. ADD's CI gates compile-drift but doesn't gate methodology-effectiveness.

**ADD's response:** Build a minimal eval harness in v1.0; gate on regression of skill effectiveness, not just compile parity.

---

## Capability ranking summary table

| # | Capability | Difficulty | Priority |
|---|---|---|---|
| A1 | Cloud / scheduled / event-triggered execution | Medium | **MUST** |
| A3 | Skill task-evals + security scoring | Medium | **MUST** |
| A2 | Multi-agent fleet visualization | Small-Medium | **SHOULD** |
| A4 | Persistent task DAG across sessions | Medium | **SHOULD** |
| A5 | Built-in eval harness for methodology | Large | **SHOULD** |
| A8 | AGENTS.md as living artifact | Trivial-Small | **SHOULD** |
| A9 | Plan Mode read-only enforcement | Small | **SHOULD** |
| A6 | Persistent semantic / temporal memory | Medium | **COULD** |
| A7 | Computer use for spec verification | Medium | **COULD** |
| A10 | Tool-agnostic skill packaging cleanup | Medium | **COULD** |
| A12 | Repo-map / PageRank context selection | Architectural | **DEFER** |

---

## Sources

### Anthropic / Claude Code
- [Claude Code Docs — Best Practices](https://code.claude.com/docs/en/best-practices)
- [Claude Code Docs — Plugins](https://code.claude.com/docs/en/plugins)
- [Claude Code Docs — Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Claude Code Docs — Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Docs — Computer Use](https://code.claude.com/docs/en/computer-use)
- [Claude Code Changelog (claudefa.st curated)](https://claudefa.st/blog/guide/changelog)
- [Anthropic — Claude Code Plugins blog](https://claude.com/blog/claude-code-plugins)
- [Anthropic — Donating MCP / AAIF](https://www.anthropic.com/news/donating-the-model-context-protocol-and-establishing-of-the-agentic-ai-foundation)
- [Anthropic — 2026 Agentic Coding Trends Report (PDF)](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)
- [Anthropic — Skills repo](https://github.com/anthropics/skills)
- [Anthropic — Agent Skills API docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Anthropic Claude Plugins Official directory](https://github.com/anthropics/claude-plugins-official)
- [Prompt caching docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [9to5Mac — Routines launch coverage](https://9to5mac.com/2026/04/14/anthropic-adds-repeatable-routines-feature-to-claude-code-heres-how-it-works/)
- [Builder.io — Routines tutorial](https://www.builder.io/blog/claude-code-routines)
- [Tessl blog — Routines deep dive](https://tessl.io/blog/anthropic-adds-routines-to-claude-code-for-scheduled-agent-tasks/)
- [DevOps.com — Routines analysis](https://devops.com/claude-code-routines-anthropics-answer-to-unattended-dev-automation/)
- [VentureBeat — Claude Code Tasks update](https://venturebeat.com/orchestration/claude-codes-tasks-update-lets-agents-work-longer-and-coordinate-across)
- [ClaudeArchitect — Tasks complete guide 2026](https://claudearchitect.com/docs/claude-code/claude-code-tasks-guide/)
- [Lucumr (Armin Ronacher) — What is Plan Mode](https://lucumr.pocoo.org/2025/12/17/what-is-plan-mode/)
- [Claude Code Plan Mode complete guide](https://www.getaiperks.com/en/articles/claude-code-plan-mode)
- [MindStudio — Claude Code Q1 2026 update roundup](https://www.mindstudio.ai/blog/claude-code-q1-2026-update-roundup)

### OpenAI / Codex CLI
- [Codex CLI docs](https://developers.openai.com/codex/cli)
- [Codex CLI changelog](https://developers.openai.com/codex/changelog)
- [Codex CLI features](https://developers.openai.com/codex/cli/features)
- [Codex Sub-agents](https://developers.openai.com/codex/subagents)
- [Codex Skills](https://developers.openai.com/codex/skills)
- [Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md)
- [Codex advanced config](https://developers.openai.com/codex/config-advanced)
- [OpenAI — AAIF announcement](https://openai.com/index/agentic-ai-foundation/)
- [Releasebot — Codex April 2026 release notes](https://releasebot.io/updates/openai/codex)
- [Daniel Vaughan — Codex parallel orchestration](https://codex.danielvaughan.com/2026/04/18/running-multiple-codex-agents-parallel-orchestration/)

### Cursor
- [Cursor 3.0 changelog](https://cursor.com/changelog/3-0)
- [Cursor 3.1 changelog](https://cursor.com/changelog/3-1)
- [Cursor 3 launch blog](https://cursor.com/blog/cursor-3)
- [Cursor — Self-hosted cloud agents](https://cursor.com/blog/self-hosted-cloud-agents)
- [InfoQ — Cursor 3 agent-first interface](https://www.infoq.com/news/2026/04/cursor-3-agent-first-interface/)
- [Futurum — Cursor 3.2 IDE-as-runtime](https://futurumgroup.com/insights/cursor-3-2-reframes-the-ide-as-an-agent-execution-runtime/)
- [DataCamp — What is Cursor 3](https://www.datacamp.com/blog/cursor-3)
- [Liran Baba — Cursor 3 parallel agents reality check](https://liranbaba.dev/blog/cursor-3-parallel-agents/)

### Other coding agents
- [Windsurf changelog](https://windsurf.com/changelog)
- [Windsurf Wave 13 — neowin coverage](https://www.neowin.net/news/windsurf-wave-13-introduces-the-new-swe-15-model-and-git-worktrees/)
- [Windsurf Wave 13 byteiota review](https://byteiota.com/windsurf-wave-13-free-swe-1-5-parallel-agents-escalate-ai-ide-war/)
- [Replit Agent 3 launch](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet)
- [Replit — 2025 in review](https://blog.replit.com/2025-replit-in-review)
- [Devin 2026 release notes](https://docs.devin.ai/release-notes/2026)
- [Cline](https://cline.bot/)
- [Aider repo-map docs](https://aider.chat/docs/repomap.html)
- [Sourcegraph — Agentic context fetching](https://sourcegraph.com/docs/cody/capabilities/agentic-context-fetching)
- [GitHub — Inline agent mode in JetBrains (Apr 24, 2026)](https://github.blog/changelog/2026-04-24-inline-agent-mode-in-preview-and-more-in-github-copilot-for-jetbrains-ides/)
- [GitHub Copilot Workspace agent mode press release](https://github.com/newsroom/press-releases/agent-mode)
- [Augment Code — Context Engine](https://www.augmentcode.com/context-engine)
- [Augment Code Intent (SiliconAngle Feb 2026)](https://siliconangle.com/2026/02/06/augment-code-makes-semantic-coding-capability-available-ai-agent/)

### Spec-driven ecosystem
- [GitHub Spec Kit](https://github.com/github/spec-kit)
- [OpenSpec](https://openspec.dev/)
- [OpenSpec on Thoughtworks Radar](https://www.thoughtworks.com/radar/tools/openspec)
- [Kiro](https://kiro.dev/)
- [Kiro AWS docs](https://aws.amazon.com/documentation-overview/kiro/)
- [SpecWeave](https://spec-weave.com/)
- [SpecWeave repo](https://github.com/anton-abyzov/specweave)
- [BMAD-METHOD repo](https://github.com/bmad-code-org/BMAD-METHOD)
- [BMAD docs](https://docs.bmad-method.org/)
- [DeepLearning.AI — Spec-Driven Development with Coding Agents course](https://www.deeplearning.ai/short-courses/spec-driven-development-with-coding-agents/)
- [Andrew Ng — course announcement (LinkedIn)](https://www.linkedin.com/posts/andrewyng_new-course-spec-driven-development-with-activity-7450215698410266625-W6bA)
- [DeepLearning.AI — course materials repo](https://github.com/https-deeplearning-ai/sc-spec-driven-development-files)
- [Augment — 6 best SDD tools 2026](https://www.augmentcode.com/tools/best-spec-driven-development-tools)
- [Spec Kit vs BMAD vs OpenSpec choosing in 2026](https://dev.to/willtorber/spec-kit-vs-bmad-vs-openspec-choosing-an-sdd-framework-in-2026-d3j)

### AGENTS.md / Linux Foundation
- [Linux Foundation AAIF announcement](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)
- [AAIF 2026 events program](https://www.linuxfoundation.org/press/agentic-ai-foundation-announces-global-2026-events-program-anchored-by-agntcon-mcpcon-north-america-and-europe)
- [agents.md](https://agents.md/)
- [AGENTS.md repo](https://github.com/agentsmd/agents.md)
- [TechCrunch — OpenAI/Anthropic/Block on Linux Foundation effort](https://techcrunch.com/2025/12/09/openai-anthropic-and-block-join-new-linux-foundation-effort-to-standardize-the-ai-agent-era/)

### Memory layer
- [MemPalace official guide](https://mempalaceofficial.com/guide/mcp-integration.html)
- [MemPalace MCP Hub](https://mempalace.in/)
- [MemPalace AI Memory System (recca0120)](https://recca0120.github.io/en/2026/04/08/mempalace-ai-memory-system/)
- [Best AI Memory Frameworks 2026 (MemPalace.tech)](https://www.mempalace.tech/blog/best-ai-memory-frameworks-2026)
- [Letta blog](https://www.letta.com/blog/agent-memory)
- [Letta repo](https://github.com/letta-ai/letta)
- [Letta — Letta Code launch](https://www.letta.com/blog/letta-code)
- [Mem0 vs Letta](https://vectorize.io/articles/mem0-vs-letta)
- [Mem0 vs Zep](https://vectorize.io/articles/mem0-vs-zep)
- [Graphiti repo](https://github.com/getzep/graphiti)
- [Graphiti / Zep Open Source](https://www.getzep.com/product/open-source/)
- [Mem0 — Graph memory blog](https://mem0.ai/blog/graph-memory-solutions-ai-agents)
- [Atlan — Best AI Memory Frameworks 2026](https://atlan.com/know/best-ai-agent-memory-frameworks-2026/)

### Eval / observability
- [LangChain — How we build evals for Deep Agents](https://blog.langchain.com/how-we-build-evals-for-deep-agents/)
- [LangChain — Evaluating Deep Agents learnings](https://blog.langchain.com/evaluating-deep-agents-our-learnings/)
- [LangChain — Evaluating Skills](https://blog.langchain.com/evaluating-skills/)
- [Braintrust — best LLM tracing tools 2026](https://www.braintrust.dev/articles/best-llm-tracing-tools-2026)
- [Braintrust — best AI agent debugging 2026](https://www.braintrust.dev/articles/best-ai-agent-debugging-tools-2026)
- [Honeycomb — fast AI feedback loops with OTEL](https://www.honeycomb.io/blog/fast-ai-feedback-loops-honeycomb-opentelemetry)
- [Honeycomb — built for agent era pt1](https://www.honeycomb.io/blog/honeycomb-is-built-for-the-agent-era-pt1)
- [Sentry — Seer GA](https://blog.sentry.io/seer-sentrys-ai-debugger-is-generally-available/)

### Security / compliance
- [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)
- [Aikido — OWASP Top 10 Agentic 2026 guide](https://www.aikido.dev/blog/owasp-top-10-agentic-applications)
- [NeuralTrust — OWASP Top 10 Agentic 2026 deep dive](https://neuraltrust.ai/blog/owasp-top-10-for-agentic-applications-2026)
- [Snyk — ToxicSkills audit](https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/)
- [Snyk — SKILL.md to shell access threat model](https://snyk.io/articles/skill-md-shell-access/)
- [Snyk-Tessl partnership](https://snyk.io/blog/snyk-tessl-partnership/)
- [Augment — EU AI Act 2026 guide](https://www.augmentcode.com/guides/eu-ai-act-2026)
- [Legal Nodes — EU AI Act 2026 updates](https://www.legalnodes.com/article/eu-ai-act-2026-updates-compliance-requirements-and-business-risks)
- [Pearl Cohen — EU AI Act new guidance](https://www.pearlcohen.com/new-guidance-under-the-eu-ai-act-ahead-of-its-next-enforcement-date/)

### MCP / skills ecosystem
- [Tessl Registry](https://tessl.io/registry)
- [Tessl Task Evals](https://tessl.io/blog/introducing-task-evals-measure-whether-your-skills-actually-work/)
- [Firecrawl — best MCP servers 2026](https://www.firecrawl.dev/blog/best-mcp-servers-for-developers)
- [Builder.io — best MCP servers 2026](https://www.builder.io/blog/best-mcp-servers-2026)
- [agentskills.io](https://agentskills.io/home)
- [awesome-claude-code-plugins](https://github.com/ccplugins/awesome-claude-code-plugins)
- [ComposioHQ awesome-claude-plugins](https://github.com/ComposioHQ/awesome-claude-plugins)

### Adjacent
- [Notion 3.3 release — Custom Agents Feb 24, 2026](https://www.notion.com/releases/2026-02-24)
- [Notion AI agents product](https://www.notion.com/product/agents)
- [Vercel/Railway agent deploy comparison](https://getathenic.com/blog/ai-agent-deployment-platforms-vercel-aws-railway)
- [Bolt.new alternatives 2026](https://www.superblocks.com/blog/bolt-new-alternative)
- [v0 vs Bolt vs Lovable 2026](https://blog.tooljet.com/lovable-vs-bolt-vs-v0/)
- [Pento — A year of MCP](https://www.pento.ai/blog/a-year-of-mcp-2025-review)

---

## Closing observation

ADD's biggest 2026 risk is not that it lacks capabilities — it's that the host runtimes are absorbing methodology features faster than ADD can ship them. ADD's biggest 2026 opportunity is that NO ONE else ships maturity-aware methodology with the same depth.

v1.0 should:
1. **Lean into the maturity ladder as the headline differentiator.**
2. **Stop competing where hosts now do better** (hooks, sub-agent dispatch, AGENTS.md generation as static one-shot).
3. **Pick MUST capabilities (Routines, skill evals + security)** and ship them as adapters / integrations rather than ground-up rebuilds.
4. **Position ADD as cross-runtime methodology**, not a Claude Code plugin that happens to also work on Codex.

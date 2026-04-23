# Spec: Codex-Native Skills, Sub-Agents, Hooks, and Plugin Manifest

**Version:** 0.1.0
**Created:** 2026-04-22
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Release:** v0.9.0
**Milestone:** M3-pre-ga-hardening

## 1. Overview

ADD's Codex adapter still emits to Codex CLI surfaces that the Codex team has either deprecated or superseded. Today `compile_codex` (in `scripts/compile.py`) writes flat prompt files at `dist/codex/prompts/add-{skill}.md` — Codex's legacy custom-prompts mechanism — and concatenates every rule, skill body, and template into a 3,101-line `AGENTS.md`. In the months since that adapter was written, Codex CLI shipped four substantive runtime features that ADD does not yet target:

1. **Native Skills system** (`developers.openai.com/codex/skills`) — `.agents/skills/{name}/SKILL.md` with `name` and `description` frontmatter that drives implicit, description-matched dispatch, mirroring Claude Code Skills. Per-skill `agents/openai.yaml` declares `allow_implicit_invocation` and required tools.
2. **Sub-agents** behind `[features] collab = true` — per-agent TOML files in `.codex/agents/`, with `[agents]` global config (`max_threads`, `max_depth`) and built-in roles (`default`, `worker`, `explorer`). Each agent gets its own `model_reasoning_effort` and `sandbox_mode`.
3. **Hooks** behind `[features] codex_hooks = true` — `SessionStart`, `PreToolUse`, `PostToolUse`, `PermissionRequest`, `UserPromptSubmit`, `Stop`. Critical asymmetry vs Claude Code: PreToolUse/PostToolUse fire **only on Bash**, not on Write or MCP.
4. **Plugin marketplace** (CLI 0.121-0.122, April 2026) — git-URL, local-path, and manifest-based installs, requiring a Codex-shaped plugin manifest at the runtime root.

Beyond emission gaps, the current adapter actively strips information Codex now consumes (frontmatter is dropped during the markdown concat) and silently no-ops the postToolUse hooks ADD relies on for handoff and learning capture. High-leak interview skills (`spec`, `brand-update`, `away`) call out for `ask_user_question`, but that tool is only available in Codex's Plan mode — Default mode swallows the request and the agent improvises an answer.

This spec retargets the Codex adapter so a `compile.py codex` produces a runtime that installs cleanly through the Codex plugin marketplace, registers each ADD skill as a native Codex skill, declares sub-agents for parallel TDD, wires hooks for handoff and learning persistence, and carries a documented compatibility shim for interview skills until Codex exposes `ask_user_question` outside Plan mode.

### User Story

As an ADD user installing the plugin into Codex CLI, I want each ADD skill, hook, and sub-agent to land in the Codex-native surface area — so that skills dispatch by description match, sub-agents parallelize TDD, hooks persist handoffs across sessions, and the plugin installs through the Codex marketplace without bespoke setup.

## 2. Acceptance Criteria

### A. Skills Emission (Native SKILL.md Format)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `compile_codex` emits each ADD skill to `dist/codex/.agents/skills/add-{skill}/SKILL.md` instead of `dist/codex/prompts/add-{skill}.md`. The legacy `prompts/` path is no longer populated. | Must |
| AC-002 | Each emitted `SKILL.md` preserves the source skill's `name` and `description` YAML frontmatter verbatim — these are the fields Codex's description-matching dispatcher reads. The skill body follows the frontmatter unchanged. | Must |
| AC-003 | The `name` field is namespaced (`add-spec`, `add-tdd-cycle`, etc.) to prevent collision with consumer-defined skills, matching the existing Claude Code namespace rule. | Must |
| AC-004 | Skill body retains all internal `/add:` references — these resolve identically under Codex's skill dispatcher because the namespaced `name` matches the reference. | Must |
| AC-005 | Skills that ship companion templates or knowledge files copy those into `dist/codex/.agents/skills/add-{skill}/` alongside `SKILL.md`, with relative path references in the body rewritten to match. | Must |

### B. Per-Skill Tool & Invocation Policy

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-006 | Each skill directory contains an `agents/openai.yaml` declaring `allow_implicit_invocation` and the skill's required tool surface (e.g., `bash`, `read`, `edit`, `write`, plus any MCP tools). | Must |
| AC-007 | High-leak interview skills set `allow_implicit_invocation: false`: `add-spec`, `add-brand-update`, `add-away`, `add-tdd-cycle`, `add-implementer`, `add-deploy`. These require explicit invocation to prevent the dispatcher from silently launching them mid-conversation. | Must |
| AC-008 | All other skills default to `allow_implicit_invocation: true` so description-matching dispatch works (e.g., `add-verify`, `add-docs`, `add-dashboard`). | Must |
| AC-009 | The required-tools list is sourced from a per-skill manifest in `runtimes/codex/skill-policy.yaml` (new file) — not inferred at compile time. Manifest is the source of truth; compile fails if a skill is missing a policy entry. | Must |
| AC-010 | Open question — see §10: whether `agents/openai.yaml` is one-file-per-skill (current plan) or one shared file referenced by skills. Resolution required before spec moves to Approved. | Must |

### C. Slim AGENTS.md Manifest

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-011 | `dist/codex/AGENTS.md` shrinks from ~3,101 lines to ≤350 lines. The slim manifest contains: project identity (name, version), ADD invariants (the rules currently marked `autoload: always`), a table of available skills with one-line descriptions and pointers to their `SKILL.md`, and nothing else. | Must |
| AC-012 | Rules with `autoload: conditional` or `autoload: never` are excluded from `AGENTS.md` and live only in their source skill's body, where Codex loads them on skill invocation. | Must |
| AC-013 | The skill index in `AGENTS.md` is generated, not hand-curated — `compile_codex` reads each `SKILL.md` frontmatter and writes the table. | Must |
| AC-014 | A compile-time check fails the build if `AGENTS.md` exceeds 500 lines, catching accidental regressions to the old concat behavior. | Should |

### D. Sub-Agent TOML Emission

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-015 | `compile_codex` emits four per-agent TOML files to `dist/codex/.codex/agents/`: `test-writer.toml`, `implementer.toml`, `reviewer.toml`, `explorer.toml`. | Must |
| AC-016 | `test-writer.toml` and `implementer.toml` use `model_reasoning_effort = "high"` (TDD requires careful test design and minimal-implementation discipline). `reviewer.toml` uses `"high"`. `explorer.toml` uses `"medium"` (broader, lower-stakes sweeps). | Must |
| AC-017 | Each agent TOML declares `sandbox_mode` appropriate to the role: `test-writer` and `implementer` get `workspace-write`; `reviewer` and `explorer` get `read-only`. | Must |
| AC-018 | A global `[agents]` section in `dist/codex/.codex/config.toml` sets `max_threads = 6` and `max_depth = 1` (matching Codex defaults; surfacing them so users see what ADD assumes). | Must |
| AC-019 | A `[features]` section in the same config sets `collab = true` and `codex_hooks = true` so the emitted runtime is functional out of the box (with onboarding noting these are runtime-feature toggles — see §non-goals). | Must |
| AC-020 | Each sub-agent TOML's prompt/instructions reference the corresponding ADD skill (`add-test-writer`, `add-implementer`, `add-reviewer`) as the behavioral source — no duplicated logic, single source of truth. | Must |

### E. Hooks Bundle

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-021 | `dist/codex/.codex/hooks.json` is emitted with at minimum: `SessionStart` → load-handoff script, `Stop` → write-handoff script, `UserPromptSubmit` → handoff-detection script. | Must |
| AC-022 | Because Codex `PreToolUse`/`PostToolUse` fire only on Bash, the handoff/learning-capture triggers that Claude Code attaches to Write/Edit are reattached to `UserPromptSubmit` and `Stop` — capturing the same state at the next natural boundary. | Must |
| AC-023 | Hook scripts live in `dist/codex/.codex/hooks/` as POSIX shell scripts with `set -euo pipefail`. Scripts are no-ops when the relevant ADD state files (`.add/handoff.md`, `.add/learnings.json`) don't exist — the hooks must not error out in non-ADD-managed projects. | Must |
| AC-024 | Hook scripts are mode `0755` in the emitted output. Compile fails if any hook script is not executable. | Should |
| AC-025 | A README at `dist/codex/.codex/hooks/README.md` documents which Claude Code triggers each Codex hook substitutes for, so users debugging missing handoffs have a map. | Should |

### F. AskUserQuestion Compatibility Shim

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-026 | Skills that depend on interactive question flows (`add-spec`, `add-brand-update`, `add-away`, `add-retro`) include a Codex-specific preamble injected by `compile_codex`: a Plan-mode prefix instructing the agent to call `ask_user_question` if available, plus a Default-mode fallback template that emits inline numbered questions and waits for the next user prompt. | Must |
| AC-027 | The shim template lives in `runtimes/codex/templates/askuser-shim.md` so the wording is editable in one place. | Must |
| AC-028 | The shim explicitly refuses to improvise answers — it fails closed by halting the skill and asking the user to respond inline, rather than fabricating user intent. This is a behavioral AC verified by a downstream Codex test (TC-004 below). | Must |

### G. Plugin Manifest

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-029 | `dist/codex/plugin.toml` (or whatever the Codex plugin manifest format is at the time of v0.9 release — see §10) is emitted with: plugin name (`add`), version (matching ADD version), description, list of registered skills, list of registered agents, list of registered hooks. | Must |
| AC-030 | The manifest is structurally valid against the published Codex plugin manifest schema as of the pinned CLI version. CI runs `codex plugin validate dist/codex/` (or equivalent) against a containerized Codex install. | Must |
| AC-031 | A `marketplace.json` companion at the repo root (or merged into the existing `.claude-plugin/marketplace.json`) declares the Codex install path so users can `codex plugin install <git-url>` and pick up `dist/codex/`. | Must |
| AC-032 | The manifest pins a minimum Codex CLI version (`min_codex_version`) below which the runtime should refuse to install — see §10 for version selection. | Should |

### H. Adapter & Compile Drift

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-033 | `runtimes/codex/adapter.yaml` is updated to declare all new emission targets (skills directory, agents directory, hooks directory, plugin manifest). The adapter is the single source of truth — `compile_codex` reads from it, no hard-coded paths in Python. | Must |
| AC-034 | The existing compile-drift CI job (which runs `compile.py` and asserts no diff against committed `dist/`) passes against the new emission layout. | Must |
| AC-035 | A new CI job runs the emitted runtime through a real Codex CLI install (pinned version, containerized) and verifies: plugin loads, skills register, sub-agents register, hooks register, one smoke skill invokes successfully. | Should |

## 3. User Test Cases

### TC-001: Codex install via marketplace surfaces ADD skills

**Precondition:** Fresh Codex CLI install (pinned version), no prior ADD plugin installed.
**Steps:**
1. User runs `codex plugin install https://github.com/MountainUnicorn/add`
2. Codex resolves the plugin manifest, copies `dist/codex/` into the plugin store
3. User starts a Codex session in any project
4. User types a prompt that semantically matches `add-verify` (e.g., "run quality gates on this code")
**Expected Result:** Codex's description-matching dispatcher invokes `add-verify`. The skill body is loaded from `.agents/skills/add-verify/SKILL.md`. The skill executes against the project.
**Maps to:** TBD (downstream Codex CLI integration test)

### TC-002: High-leak interview skill requires explicit invocation

**Precondition:** ADD plugin installed in Codex. User is mid-conversation about wanting to define a new feature.
**Steps:**
1. User says "let's spec out the auth feature"
2. Codex's dispatcher considers `add-spec` as a description match
3. Dispatcher reads `add-spec/agents/openai.yaml`, sees `allow_implicit_invocation: false`
4. Dispatcher does not auto-invoke; instead it offers the skill as a suggestion
**Expected Result:** `add-spec` only runs after the user explicitly types `/add:spec` or selects it from the suggestion. No silent improvisation of the interview.
**Maps to:** TBD

### TC-003: Sub-agents parallelize TDD cycle

**Precondition:** ADD plugin installed in Codex with `collab = true`. User runs `/add:tdd-cycle specs/auth.md`.
**Steps:**
1. `add-tdd-cycle` skill body invokes the test-writer sub-agent for RED phase
2. Test-writer sub-agent runs with `model_reasoning_effort = "high"` and `workspace-write` sandbox
3. Tests are written; control returns to the orchestrator
4. Implementer sub-agent runs for GREEN phase with same tier
5. Reviewer sub-agent runs in `read-only` sandbox for the final pass
**Expected Result:** Three distinct sub-agent invocations visible in the Codex session log, each scoped to its declared sandbox. TDD completes end to end.
**Maps to:** TBD

### TC-004: AskUserQuestion shim halts instead of improvising

**Precondition:** ADD plugin installed in Codex CLI version that exposes `ask_user_question` only in Plan mode. User is in Default mode and runs `/add:spec`.
**Steps:**
1. `add-spec` skill begins
2. Shim preamble detects Default mode (no `ask_user_question` available)
3. Shim emits inline numbered questions: "1. What problem does this feature solve? 2. Who is the user? ..."
4. Skill halts, awaits next user prompt
**Expected Result:** Spec interview proceeds question-by-question via inline prompts. No fabricated answers in the resulting spec document.
**Maps to:** TBD

### TC-005: Hooks persist handoff across sessions

**Precondition:** ADD plugin installed in Codex with `codex_hooks = true`. Project has prior `.add/handoff.md`.
**Steps:**
1. User starts a new Codex session
2. `SessionStart` hook fires, runs `load-handoff.sh`, surfaces handoff content as session context
3. User does work
4. User ends session
5. `Stop` hook fires, runs `write-handoff.sh`, persists current state to `.add/handoff.md`
**Expected Result:** Next session loads where the last session left off. Handoff content is updated with the most recent work summary.
**Maps to:** TBD

### TC-006: Compile produces no diff in CI

**Precondition:** Clean checkout of ADD repo at v0.9.0 candidate commit.
**Steps:**
1. CI runs `python scripts/compile.py codex`
2. CI runs `git diff --exit-code dist/codex/`
**Expected Result:** No diff. Emitted output matches committed `dist/codex/` exactly.
**Maps to:** existing compile-drift CI workflow

### TC-007: AGENTS.md size cap enforced

**Precondition:** A future change accidentally re-enables the legacy concat behavior.
**Steps:**
1. CI runs `compile.py codex`
2. CI checks `wc -l dist/codex/AGENTS.md`
**Expected Result:** Build fails with a clear message: `AGENTS.md exceeds 500-line cap (was: NNNN lines). Did the legacy concat regress?`
**Maps to:** TBD

## 4. Data Model

### Per-Skill Policy Entry (`runtimes/codex/skill-policy.yaml`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `skill` | string | Yes | Skill name without `add-` prefix (e.g., `spec`, `tdd-cycle`) |
| `allow_implicit_invocation` | boolean | Yes | Whether Codex's dispatcher may auto-invoke on description match |
| `tools` | string[] | Yes | Tool surface required: subset of `bash`, `read`, `edit`, `write`, `webfetch`, `mcp:*` |
| `requires_askuser_shim` | boolean | No | If true, the AskUserQuestion shim preamble is injected at compile time |

### Sub-Agent TOML Structure (`dist/codex/.codex/agents/{role}.toml`)

```toml
name = "test-writer"
model_reasoning_effort = "high"
sandbox_mode = "workspace-write"
prompt_skill = "add-test-writer"
description = "Writes failing tests from a spec (TDD RED phase)."
```

### Hooks Bundle (`dist/codex/.codex/hooks.json`)

```json
{
  "SessionStart": [{"command": ".codex/hooks/load-handoff.sh"}],
  "Stop": [{"command": ".codex/hooks/write-handoff.sh"}],
  "UserPromptSubmit": [{"command": ".codex/hooks/handoff-detect.sh"}]
}
```

### Plugin Manifest (`dist/codex/plugin.toml`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | `add` |
| `version` | string | Yes | Matches ADD version (e.g., `0.9.0`) |
| `description` | string | Yes | One-line plugin description |
| `min_codex_version` | string | Yes | Minimum Codex CLI version |
| `skills` | string[] | Yes | Paths to each `SKILL.md` |
| `agents` | string[] | Yes | Paths to each agent TOML |
| `hooks` | string | Yes | Path to `hooks.json` |

### Hook → Trigger Mapping

| Claude Code Trigger | Codex Equivalent | Reason |
|---------------------|------------------|--------|
| `PostToolUse` (Write/Edit) | `UserPromptSubmit` + `Stop` | Codex PostToolUse is Bash-only; capture state at next natural boundary |
| `PostToolUse` (Bash) | `PostToolUse` (Bash) | 1:1 mapping available |
| `SessionStart` | `SessionStart` | 1:1 mapping available |
| `Stop` | `Stop` | 1:1 mapping available |
| `UserPromptSubmit` | `UserPromptSubmit` | 1:1 mapping available |

## 5. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| User installs into a Codex CLI version older than `min_codex_version` | Plugin install refuses with a version-mismatch message |
| User runs Codex with `codex_hooks = false` | Hooks no-op silently; skills still work; handoff persistence degrades to manual |
| User runs Codex with `collab = false` | Sub-agents unavailable; `add-tdd-cycle` falls back to single-agent execution path (existing behavior) |
| Skill body references a sibling skill via `/add:foo` | Reference resolves via Codex's namespaced skill registry |
| `agents/openai.yaml` schema changes between CLI minor versions | Compile-drift CI catches the diff; spec issues an erratum patch |
| User has both Claude Code and Codex installed | Both runtimes coexist; each reads from its own `dist/` subdirectory; no shared state files contend |
| Hook script fails (non-zero exit) | Codex surfaces the error in the session log; ADD state files remain in last-known-good state (hooks are idempotent reads/writes, not destructive) |
| Slim AGENTS.md is missing a skill that exists in `.agents/skills/` | Codex can still dispatch to the skill (description match works without the manifest), but the index is stale — caught by AC-013 generation step |
| Codex deprecates `agents/openai.yaml` in favor of inline frontmatter | Adapter changes; compile-drift CI catches it; version bump issues a patch release |
| User installs via local-path source instead of git URL | Plugin manifest resolves identically; no special-casing needed |

## 6. Non-Goals

- **Onboarding for `[features] codex_hooks = true` and `collab = true`.** The emitted `config.toml` sets these, but if a user has overridden them globally to `false`, surfacing that mismatch is out of scope for this spec. Documentation note only.
- **PreToolUse/PostToolUse Bash-only workaround beyond docs.** Codex's hook surface for Write/MCP tools may expand in future CLI releases; until then, this spec's mitigation is the `UserPromptSubmit` + `Stop` reattachment plus the README map. No polling, no shim daemon.
- **Brownfield migration from the prior Codex adapter.** Users who previously installed the legacy `prompts/`-based runtime will get a fresh install via the existing version-migration mechanism (out of scope here). No in-place upgrade path is specified.
- **Parity with Claude Code's full hook surface.** Codex doesn't expose every Claude Code hook event; this spec ships what Codex supports and documents the gap.

## 7. Dependencies

- `runtimes/codex/adapter.yaml` — primary configuration surface; needs new emission targets
- `runtimes/codex/skill-policy.yaml` — new file; per-skill `allow_implicit_invocation` and tool policy
- `runtimes/codex/templates/askuser-shim.md` — new file; question-flow compatibility template
- `scripts/compile.py` `compile_codex` function — major rewrite to emit the new layout
- `dist/codex/` — entire emitted tree changes shape; CI compile-drift baseline must be regenerated
- Codex CLI pinned version — see open question §10 for selection
- Existing skill source files — unchanged; this spec is downstream of the source-of-truth skill bodies
- `.claude-plugin/marketplace.json` — extended with Codex install metadata (or new sibling file)

## 8. Infrastructure Prerequisites

| Category | Requirement |
|----------|-------------|
| Environment variables | N/A |
| Registry images | A pinned Codex CLI container for the verification CI job (AC-035) |
| Cloud quotas | N/A |
| Network reachability | CI must reach `codex plugin install` registry (or local manifest source) |
| CI status | Existing compile-drift workflow must remain green; new Codex-install verification job added |
| External secrets | None |
| Database migrations | N/A |

**Verification before implementation:** Confirm the target Codex CLI version's published plugin-manifest schema, hook event list, and sub-agent TOML schema by running `codex plugin schema` (or equivalent introspection) against the pinned container. Snapshot those schemas into `runtimes/codex/snapshots/` so future drift is detectable.

## 9. Sizing & Sequencing

Large item. Estimated 3-5 days of focused implementation plus 2 days of testing on real Codex CLI installs. Cycle 2 of the M3 milestone. Suggested sub-cycle order:

1. Adapter + `skill-policy.yaml` + native `SKILL.md` emission (AC-001 through AC-010)
2. Slim `AGENTS.md` (AC-011 through AC-014)
3. Sub-agent TOML + global config (AC-015 through AC-020)
4. Hooks bundle (AC-021 through AC-025)
5. AskUserQuestion shim (AC-026 through AC-028)
6. Plugin manifest + marketplace integration (AC-029 through AC-032)
7. CI verification job (AC-035)

## 10. Open Questions

| # | Question | Resolution Needed By |
|---|----------|---------------------|
| Q1 | Which Codex CLI version do we pin `min_codex_version` to? Codex's release pace is fast (minor every 4-10 days as of April 2026). Pinning too low loses access to required features (plugin marketplace landed in 0.121-0.122); pinning too high cuts off users who haven't upgraded recently. Proposed default: pin to the lowest version that has skills + sub-agents + hooks + plugin manifest all GA, currently 0.122. | Before implementation start |
| Q2 | Is `agents/openai.yaml` one-file-per-skill, or one shared file referenced by skills? Per-skill is more explicit and easier to override; shared is less duplication. Codex docs as of writing show per-skill examples but don't forbid the shared form. | Before AC-006 implementation |
| Q3 | The Codex plugin manifest format may shift between now and v0.9 release. Do we version-pin the manifest schema (snapshot it and break loudly on drift) or feature-detect at install time (try the new schema, fall back to the old)? Version-pin is simpler; feature-detect is more user-friendly. | Before AC-029 implementation |
| Q4 | Should sub-agent TOMLs include a `tools` allowlist mirroring Claude Code's per-agent tool policy, or rely on the global `sandbox_mode` for restriction? Tighter per-agent control would reduce blast radius but adds maintenance surface. | Before AC-015 implementation |
| Q5 | The AskUserQuestion shim's Default-mode fallback halts the skill. Should we instead emit a structured "question batch" the user can answer in one prompt, then resume? Halt is simpler; batch is faster for the user. | Before AC-026 implementation |

## 11. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-22 | 0.1.0 | abrooke + Claude (parallel spec batch) | Initial spec for v0.9.0 Codex runtime modernization |

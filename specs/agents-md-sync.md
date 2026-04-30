# Spec: AGENTS.md Sync

**Version:** 0.1.0
**Created:** 2026-04-22
**PRD Reference:** docs/prd.md
**Status:** Complete
**Target Release:** v0.9.0
**Shipped-In:** v0.9.0
**Last-Updated:** 2026-04-22
**Milestone:** M3-pre-ga-hardening

## 1. Overview

In 2026, [`AGENTS.md`](https://agents.md) became the cross-tool standard for project-level agent instructions, governed by the Linux Foundation's Agentic AI Foundation and adopted by Codex CLI, GitHub Copilot, Cursor, Windsurf, Sourcegraph Amp, Devin, and ~60k+ public projects. It is the one file every coding agent reads on session start, regardless of vendor.

ADD currently produces a `dist/codex/AGENTS.md` as part of its own internal Codex runtime adapter — but this is ADD's plumbing, not a project-level artifact a consuming developer would put in their own repo. There is no skill that helps an ADD-managed project produce a portable `AGENTS.md`. To mixed-toolchain teams, ADD looks parochial: it asks agents to read `.add/` and `CLAUDE.md`, but ignores the open standard everyone else has converged on.

This spec adds a new skill `/add:agents-md` that derives a portable `AGENTS.md` at project root from the project's `.add/` state — config, PRD, currently-active spec, active rules, maturity level. Verbosity scales with maturity (POC = bullet summary, Beta+ = full structured doc). The skill supports `--check` (drift detection, CI-friendly), `--write` (default), and `--merge` (interactive flow for projects that already have a hand-curated `AGENTS.md`). A PostToolUse hook marks `AGENTS.md` stale when its source files change — the human triggers regen, never the agent silently.

The story: **ADD respects open standards. ADD-managed projects benefit any agent in any tool — not just Claude Code or Codex CLI users running ADD.** This reinforces the competitive thesis that ADD is methodology, not chrome.

References: [agents.md spec](https://agents.md), [Augment "How to write AGENTS.md"](https://www.augmentcode.com/blog/agents-md), [Tessl "Building with AGENTS.md"](https://tessl.io/blog/agents-md).

### User Stories

**Story 1:** As a developer on a mixed-toolchain team (Claude Code + Cursor + Codex CLI), I want my ADD-managed project to publish a portable `AGENTS.md` so all my teammates' agents respect the spec-first discipline and project invariants — not just mine.

**Story 2:** As a project maintainer, I want `/add:agents-md --check` to detect when my published `AGENTS.md` has drifted from the source of truth in `.add/`, so I can regenerate it (or fail CI) before downstream agents read stale guidance.

**Story 3:** As a developer adopting ADD on a project that already has a hand-curated `AGENTS.md`, I want `/add:agents-md --merge` to walk me through merging — preserving my user-authored sections while letting ADD manage its own marker block.

## 2. Acceptance Criteria

### A. Skill Scaffolding

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | New skill at `core/skills/agents-md/SKILL.md` follows the standard ADD skill template (frontmatter, version banner, description, invocation patterns, examples). | Must |
| AC-002 | Skill is invocable as `/add:agents-md` and is listed in the plugin's commands manifest. | Must |
| AC-003 | Default action (no flags) is equivalent to `--write` — generate `AGENTS.md` at project root from current `.add/` state. | Must |
| AC-004 | `--check` flag detects drift between current on-disk `AGENTS.md` and what would be regenerated. Reports a unified diff. Does not write. | Must |
| AC-005 | `--check` exits with non-zero status when drift is detected, zero when in sync. CI-friendly. | Must |
| AC-006 | `--merge` flag detects an existing `AGENTS.md` lacking the ADD-managed marker and prompts the human: prepend ADD section / replace / skip. | Must |
| AC-007 | `--import` flag (one-time migration) absorbs an existing hand-curated `AGENTS.md` as user-authored sections, wraps the ADD-managed content in marker blocks, and writes the merged result. | Should |
| AC-008 | `--dry-run` works with all flags — shows what would happen without modifying disk. | Should |

### B. Template & Maturity-Aware Verbosity

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-009 | New template at `core/templates/AGENTS.md.template` defines the structure (sections + marker block syntax), not the content. | Must |
| AC-010 | Generated `AGENTS.md` includes an ADD-managed marker block (HTML comments: `<!-- ADD:MANAGED:START -->` … `<!-- ADD:MANAGED:END -->`) so future regenerations can locate and replace ADD-owned content without touching user-authored sections. | Must |
| AC-011 | POC maturity → bullet-point summary only. Project identity + 3–5 critical rules. Target <500 tokens. | Must |
| AC-012 | Alpha maturity → sectioned doc. Project identity, engagement protocol, spec-first invariants, pointers. Target <1K tokens. | Must |
| AC-013 | Beta maturity → full structured doc with section anchors, TDD discipline, maturity context, autonomy ceiling, currently-active spec pointer. Target <2K tokens. | Must |
| AC-014 | GA maturity → Beta structure plus team conventions, environment promotion ladder summary, links to runbooks. Target <2.5K tokens. | Should |
| AC-015 | Generated content includes pointers (relative paths) to `.add/config.json`, `docs/prd.md`, `specs/`, `core/rules/` so any agent that wants deeper context can fetch it. | Must |

### C. Source Derivation

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-016 | Project identity section is derived from `.add/config.json` (name, version, description, stack) and the first H1 + opening paragraph of `docs/prd.md`. | Must |
| AC-017 | Engagement protocol section is a one-paragraph summary of the active human-collaboration rule. | Must |
| AC-018 | TDD discipline section is a one-paragraph summary of the active `tdd-enforcement` rule. Omitted if TDD is not applicable for the project's stack (e.g., pure markdown plugin). | Must |
| AC-019 | Spec-first invariants section is a one-paragraph summary of the active `spec-driven` rule. | Must |
| AC-020 | Maturity + autonomy ceiling section reflects the current value from the maturity-loader rule and the per-environment `autoPromote` ceiling from `.add/config.json`. | Must |
| AC-021 | Currently-active spec pointer reflects whichever spec is "under work" per `.add/handoff.md` or the most recently mutated spec in `specs/`. Auto-updates on spec switch. | Must |

### D. Integration with Existing Skills

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-022 | `core/skills/init/SKILL.md` is updated to call `/add:agents-md` as part of the `/add:init` flow, writing the initial `AGENTS.md` before completion. | Must |
| AC-023 | `core/skills/spec/SKILL.md` is updated so that when a new spec becomes the "spec under work", the skill offers (yes/no prompt) to update the AGENTS.md "currently active spec" pointer. | Must |
| AC-024 | `runtimes/claude/CLAUDE.md` is updated to document that `AGENTS.md` is now an ADD output (not consumed as input). The Codex adapter equivalent is updated similarly. | Must |
| AC-025 | `/add:verify` does NOT auto-run `--check` by default. An opt-in config flag `agentsMd.gateOnVerify: true` in `.add/config.json` enables it as Gate 4.5. | Should |

### E. Hook & Staleness

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-026 | Optional PostToolUse hook entry in `runtimes/claude/hooks/hooks.json` triggers when `.add/config.json` or any `core/rules/*.md` changes. | Must |
| AC-027 | Hook does NOT auto-rewrite `AGENTS.md`. It touches a marker file `.add/agents-md.stale` containing the timestamp and the changed source path. | Must |
| AC-028 | When the marker is present, the next `/add:agents-md` invocation announces the stale state and the changed sources before regenerating. | Should |
| AC-029 | After a successful `--write`, the staleness marker is removed. | Must |

### F. Preservation & Safety

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-030 | Frontmatter (YAML, TOML, or `+++`) at the top of an existing `AGENTS.md` is preserved verbatim across regeneration. | Must |
| AC-031 | Content outside the ADD-managed marker block is never modified, deleted, or reordered. User-authored sections survive any number of regenerations. | Must |
| AC-032 | If an existing `AGENTS.md` lacks the marker block, default `--write` aborts with an error directing the user to `--merge` or `--import`. | Must |
| AC-033 | Generated `AGENTS.md` validates against the agents.md schema (see §4 Data Model) — required sections present, no broken relative links, no malformed frontmatter. | Must |

### G. Tests & Fixtures

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-034 | Fixture tests cover: POC render, Alpha render, Beta render, GA render. Each fixture has expected output stored under `tests/fixtures/agents-md/`. | Must |
| AC-035 | Drift test: mutate `.add/config.json` in fixture, run `--check`, assert non-zero exit and meaningful diff. | Must |
| AC-036 | Merge test: fixture with hand-curated `AGENTS.md`, run `--merge` (scripted answer), assert ADD section prepended + user content preserved. | Must |

## 3. User Test Cases

### TC-001: Initial AGENTS.md generation during /add:init

**Precondition:** Fresh project, no `AGENTS.md` exists. `/add:init` interview just completed; `.add/config.json` and `docs/prd.md` written.
**Steps:**
1. `/add:init` flow reaches the AGENTS.md generation step
2. Skill reads config (maturity: alpha), PRD, active rules
3. Skill renders Alpha-level template with marker block
4. Writes `AGENTS.md` to project root
**Expected Result:** `AGENTS.md` exists at root, contains ADD-managed marker block, includes project identity, engagement protocol, spec-first invariants, and pointers. Token count under 1K.
**Maps to:** TBD

### TC-002: Drift detection in CI

**Precondition:** Project has `AGENTS.md` generated yesterday. Today, maturity was promoted from alpha → beta via `/add:promote`. `AGENTS.md` not yet regenerated.
**Steps:**
1. CI runs `/add:agents-md --check`
2. Skill regenerates in-memory at Beta verbosity
3. Compares to on-disk Alpha-level content
4. Emits unified diff and exits 1
**Expected Result:** CI step fails. Diff shows new sections (TDD discipline, autonomy ceiling, currently-active spec pointer) that should be present at Beta. Developer runs `/add:agents-md --write` locally to fix.
**Maps to:** TBD

### TC-003: Merge with hand-curated AGENTS.md

**Precondition:** Project already has a 200-line hand-curated `AGENTS.md` from before adopting ADD. No marker block present.
**Steps:**
1. User runs `/add:agents-md --merge`
2. Skill detects no marker block, presents 3 options: prepend ADD section / replace / skip
3. User selects "prepend"
4. Skill wraps existing content in `<!-- USER:AUTHORED:START -->` … `<!-- USER:AUTHORED:END -->` and prepends ADD-managed block
**Expected Result:** Merged file has ADD marker block at top, original 200 lines preserved verbatim below. Future `--write` regenerations only touch the ADD block.
**Maps to:** TBD

### TC-004: Spec switch updates active spec pointer

**Precondition:** `AGENTS.md` currently points to `specs/legacy-adoption.md` as active spec. User starts `/add:spec` for a new feature.
**Steps:**
1. New spec `specs/agents-md-sync.md` is created and becomes the "spec under work"
2. `/add:spec` post-step prompts: "Update AGENTS.md active spec pointer? (Y/n)"
3. User confirms
4. Skill regenerates AGENTS.md with new pointer
**Expected Result:** ADD-managed block now points to `specs/agents-md-sync.md`. Rest of file (including any user-authored sections) untouched.
**Maps to:** TBD

### TC-005: Hook marks stale on rule change

**Precondition:** `AGENTS.md` is in sync. User edits `core/rules/tdd-enforcement.md` to add a new clause.
**Steps:**
1. PostToolUse hook fires on the rule file write
2. Hook touches `.add/agents-md.stale` with `{timestamp, changed: "core/rules/tdd-enforcement.md"}`
3. AGENTS.md is NOT modified
4. Next time user runs `/add:agents-md`, the staleness banner announces the change
**Expected Result:** Marker file present. AGENTS.md untouched until human triggers regen. Banner informs the user what changed.
**Maps to:** TBD

### TC-006: POC project minimal render

**Precondition:** Project at maturity `poc`. Config has 3 rules, no PRD beyond a one-liner.
**Steps:**
1. Run `/add:agents-md`
2. Skill detects POC level, selects minimal template branch
**Expected Result:** Generated `AGENTS.md` is under 500 tokens. Contains project identity, 3–5 critical rules as bullets, pointer to `.add/config.json` for deeper context. No TDD/maturity/autonomy sections.
**Maps to:** TBD

## 4. Data Model

### AGENTS.md Structure (Beta+)

| Section | Source | Required |
|---------|--------|----------|
| Frontmatter (optional) | Preserved if present | No |
| ADD-managed marker open | Skill | Yes |
| Project Identity | `.add/config.json` + `docs/prd.md` H1/intro | Yes |
| Engagement Protocol | `core/rules/human-collaboration.md` summary | Yes |
| Spec-First Invariants | `core/rules/spec-driven.md` summary | Yes |
| TDD Discipline | `core/rules/tdd-enforcement.md` summary | Conditional (skip for non-code projects) |
| Maturity & Autonomy Ceiling | maturity-loader + config `autoPromote` | Yes (Beta+) |
| Currently Active Spec | `.add/handoff.md` or latest mutated `specs/*.md` | Yes (Beta+) |
| Pointers | Relative paths to `.add/`, `docs/prd.md`, `specs/`, `core/rules/` | Yes |
| ADD-managed marker close | Skill | Yes |
| User-authored content | Preserved verbatim | No |

### Marker Block Syntax

```markdown
<!-- ADD:MANAGED:START version=0.9.0 maturity=beta generated=2026-04-22T14:32:01Z -->
... ADD-owned content ...
<!-- ADD:MANAGED:END -->
```

The opening marker carries metadata (skill version, maturity at render time, ISO timestamp) so drift detection can short-circuit on metadata mismatch before full diff.

### Staleness Marker (`.add/agents-md.stale`)

| Field | Type | Description |
|-------|------|-------------|
| timestamp | string | ISO 8601 — when the source change was detected |
| changed | string[] | Relative paths of source files that changed since last regen |
| current_marker_generated | string | The `generated=` value from the existing AGENTS.md marker |

### Maturity → Verbosity Mapping

| Maturity | Sections | Token Target |
|----------|----------|--------------|
| poc | Identity, Critical Rules (bullets), Pointers | <500 |
| alpha | Identity, Engagement, Spec-First, Pointers | <1K |
| beta | All Beta+ sections | <2K |
| ga | All Beta+ sections + team conventions + env promotion | <2.5K |

### Operation-to-Trigger Mapping

| Trigger | Action |
|---------|--------|
| `/add:init` completion | Generate initial `AGENTS.md` at project maturity level |
| `/add:spec` new active spec | Prompt to update active-spec pointer |
| `/add:promote` maturity bump | Recommend regen (don't auto-rewrite) |
| `.add/config.json` edit | Hook marks stale |
| `core/rules/*.md` edit | Hook marks stale |
| `/add:verify` (with `gateOnVerify: true`) | Run `--check`, fail gate on drift |

## 5. API Contract

N/A — pure markdown/JSON plugin. The "contract" is the agents.md spec schema, which the generated file must satisfy. See [agents.md](https://agents.md) for the canonical schema; key requirements:

- File at project root (or recognized location)
- Markdown format
- Sections discoverable by H1/H2 headings (no required ordering, but conventional sections expected)
- Relative links resolvable from project root

## 6. UI Behavior

N/A — CLI plugin. Skill output is structured text + diffs.

Example `--check` output on drift:

```
AGENTS.md drift detected (last regen: 2026-04-20T09:14:00Z)

Sources changed since last regen:
  - .add/config.json (maturity: alpha → beta)
  - core/rules/tdd-enforcement.md

Diff (current vs would-be):
  + ## TDD Discipline
  + Tests authored before implementation. RED → GREEN → REFACTOR enforced...
  + ## Maturity & Autonomy Ceiling
  + Project at beta. Local + dev auto-promotion enabled. Staging gated...

Run /add:agents-md --write to regenerate.
Exit code: 1
```

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No `AGENTS.md` exists | Default `--write` creates it; no merge prompt needed |
| `AGENTS.md` exists with marker block | Default `--write` regenerates ADD section, preserves user sections |
| `AGENTS.md` exists without marker block | Default `--write` aborts, suggests `--merge` or `--import` |
| Frontmatter present (YAML/TOML/+++) | Preserved verbatim, ADD block placed after frontmatter |
| Project has no PRD | Use `config.description` as project identity; warn that PRD pointer is omitted |
| Project at maturity `poc` with no rules active | Render minimal identity-only file; warn about empty rules |
| Multiple specs marked "under work" | Use most recently mutated; list others as "other active specs" |
| Marker block malformed or partially deleted | Treat as missing marker; require `--merge` to recover |
| User edits inside ADD-managed block manually | Next regen overwrites those edits; warning in `--check` output recommends moving custom content outside the markers |
| Hook fires during a long-running task | Marker file write is atomic; no race with concurrent reads |
| `.add/agents-md.stale` exists but `AGENTS.md` already in sync | Treat as stale anyway; regen is idempotent |
| Project has nested AGENTS.md files (subdirs) | Out of scope for v0.9.0 — see Non-Goals; warn if detected |

## 8. Dependencies

- `core/skills/init/SKILL.md` — calls the new skill at end of init flow
- `core/skills/spec/SKILL.md` — prompts for active-spec pointer update
- `core/skills/verify/SKILL.md` — optional `gateOnVerify` integration
- `core/rules/human-collaboration.md` — source for Engagement Protocol section
- `core/rules/spec-driven.md` — source for Spec-First Invariants section
- `core/rules/tdd-enforcement.md` — source for TDD Discipline section
- `core/rules/maturity-loader.md` — source for Maturity & Autonomy Ceiling section
- `runtimes/claude/hooks/hooks.json` — staleness hook registration
- `runtimes/claude/CLAUDE.md` + Codex adapter equivalent — documentation update
- `.add/config.json` — project identity, stack, autoPromote, optional `agentsMd.gateOnVerify`
- `docs/prd.md` — project identity narrative

## 9. Infrastructure Prerequisites

| Category | Requirement |
|----------|-------------|
| Environment variables | N/A |
| Registry images | N/A |
| Cloud quotas | N/A |
| Network reachability | N/A (file-based; agents.md spec link is documentation only) |
| CI status | If `gateOnVerify: true`, the project's CI must invoke `/add:verify` |
| External secrets | N/A |
| Database migrations | N/A |

**Verification before implementation:** Confirm fixtures directory exists at `tests/fixtures/agents-md/` and that the four maturity-level expected outputs are authored before fixture tests are wired up.

## 10. Open Questions

1. **Marker robustness:** HTML comments are the working choice (invisible in rendered markdown, durable across editors). Frontmatter field `add_managed: true` was considered but doesn't scope to a section. Keep HTML comments unless adoption surfaces issues.
2. **`--check` as Gate 4.5 in `/add:verify`:** Recommendation — opt-in via `agentsMd.gateOnVerify: true` in config, not enforced. Some projects will treat AGENTS.md as advisory and shouldn't fail builds on drift.
3. **Token budgets per maturity:** Beta target <2K is the working ceiling. If projects routinely overflow, consider section-level toggles (`agentsMd.sections.tdd: false`) before raising the budget.
4. **Migration path for existing AGENTS.md:** `--merge` is the default interactive flow. `--import` provides a one-time absorption that wraps existing content as user-authored. Both preserve original content; neither auto-promotes anything to the ADD-managed block.
5. **Cursor-specific `.cursor/rules/add.mdc`:** Out of scope for v0.9.0. agents.md is the standard and Cursor reads it. Revisit in v0.9.x if user demand surfaces.
6. **Nested per-subdirectory AGENTS.md:** Out of scope. Mono-AGENTS.md only for v0.9.0. Nested support is a v0.9.x consideration if monorepo demand emerges.

## 11. Non-Goals

- Replacing `CLAUDE.md` or `AGENTS.md` formats with ADD-specific markup. ADD uses the open standard.
- Auto-running `/add:agents-md` as a CI gate by default. Opt-in only.
- Generating per-subdirectory `AGENTS.md`. Mono-AGENTS.md only in v0.9.0.
- Bidirectional sync (AGENTS.md → ADD config). One-way only; ADD is source of truth.
- Bundling Cursor/Windsurf-specific rule files. agents.md is the standard; vendor-specific files come later if needed.

## 12. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-22 | 0.1.0 | abrooke + Claude | Initial spec — agents-md-sync for v0.9.0 (M3, Cycle 2) |

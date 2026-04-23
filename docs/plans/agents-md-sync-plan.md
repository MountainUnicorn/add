# Implementation Plan: AGENTS.md Sync

**Spec Version**: 0.1.0
**Spec File**: specs/agents-md-sync.md
**Created**: 2026-04-22
**Milestone**: M3-pre-ga-hardening
**Target Release**: v0.9.0
**Sizing**: Small
**Implementation Order**: 2 of 3 in Cycle 2 (parallel with prompt-injection-defense and codex-native-skills)

## Overview

Adds a new `/add:agents-md` skill that generates a tool-portable `AGENTS.md` at project root from the project's `.add/` state. The skill is the only way to generate/update AGENTS.md — a PostToolUse hook merely marks staleness when source inputs change. The generator is maturity-aware (POC → bullets, Alpha → sectioned, Beta → full, GA → full + team conventions).

For the v0.9.0 cut we deliver a pragmatic subset of the spec covering every Must-priority AC. Opt-in behavior (verify gate, import flow) are Should and deferred to v0.9.x if demand surfaces.

## Objectives

- Publish a portable `AGENTS.md` so any agent (Cursor, Codex CLI, Copilot, Windsurf, Amp, Devin, etc.) can read project invariants without needing the ADD plugin installed.
- Keep ADD-managed content scoped to a marker block so user-authored sections survive regenerations.
- Provide a script that both the skill and CI can invoke for deterministic drift detection.
- Dog-food: commit the generated `AGENTS.md` for the ADD repo itself.

## Cross-Feature Dependencies

```
agents-md-sync ──┬→ runtimes/claude/hooks/post-write.sh (staleness-mark case branch)
                 ├→ core/skills/init/SKILL.md (call at end of init flow)
                 ├→ core/skills/spec/SKILL.md (prompt to update active-spec pointer)
                 └→ runtimes/claude/CLAUDE.md (documentation update)
```

**Blocked by**: Nothing
**Can parallelize with**: prompt-injection-defense (shared `post-write.sh` — disjoint case branches), codex-native-skills, cache-discipline, secrets-handling

## Files Created

| Path | Purpose |
|------|---------|
| `core/skills/agents-md/SKILL.md` | New skill — describes generator workflow, flags (`--check`, `--write`, `--merge`, `--import`, `--dry-run`), maturity-aware verbosity, marker block convention |
| `core/templates/AGENTS.md.template` | Structure template (section skeleton, marker block syntax), not content |
| `scripts/generate-agents-md.py` | Python generator — reads `.add/config.json`, `docs/prd.md`, rules, specs and produces `AGENTS.md` with idempotent marker block |
| `tests/agents-md-sync/fixtures/poc-project/` | POC-level fixture: minimal `.add/config.json`, no PRD, no specs |
| `tests/agents-md-sync/fixtures/poc-project/expected-AGENTS.md` | Expected POC render |
| `tests/agents-md-sync/fixtures/alpha-project/` | Alpha-level fixture |
| `tests/agents-md-sync/fixtures/alpha-project/expected-AGENTS.md` | Expected Alpha render |
| `tests/agents-md-sync/fixtures/beta-project/` | Beta-level fixture with handoff + active spec + rules |
| `tests/agents-md-sync/fixtures/beta-project/expected-AGENTS.md` | Expected Beta render |
| `tests/agents-md-sync/fixtures/drift-project/` | Beta fixture with mutated config → drift |
| `tests/agents-md-sync/fixtures/drift-project/existing-AGENTS.md` | Pre-existing AGENTS.md that is now out-of-sync |
| `tests/agents-md-sync/fixtures/merge-project/` | Project with hand-curated AGENTS.md, no marker block |
| `tests/agents-md-sync/fixtures/merge-project/existing-AGENTS.md` | Pre-existing hand-curated content |
| `tests/agents-md-sync/fixtures/merge-project/expected-AGENTS.md` | Post-merge expected output |
| `tests/agents-md-sync/test-agents-md-sync.sh` | Fixture-based shell tests following `test-filter-learnings.sh` conventions |

## Files Modified

| Path | Change |
|------|--------|
| `runtimes/claude/hooks/post-write.sh` | Add case branch matching `*.add/config.json`, `core/rules/*.md`, `*core/skills/*/SKILL.md` → touch `.add/agents-md.stale` if `AGENTS.md` exists |
| `core/skills/init/SKILL.md` | Call `/add:agents-md` at end of init flow (one-line addition to integration section) |
| `core/skills/spec/SKILL.md` | After new spec is written, prompt: "Update AGENTS.md active-spec pointer? (Y/n)" |
| `core/skills/verify/SKILL.md` | If `agentsMd.gateOnVerify: true` in config, run `--check` as advisory Gate 4.5 |
| `runtimes/claude/CLAUDE.md` | Add skill to command table; note that AGENTS.md is an ADD output, not input |
| `runtimes/codex/adapter.yaml` | Parallel note — AGENTS.md is generated output |
| `CHANGELOG.md` | `[Unreleased]` → Added entry for `/add:agents-md` |
| `AGENTS.md` (root, new) | Dog-food the generator on this repo |

## AC Coverage Matrix

| AC | Priority | Mechanism |
|----|----------|-----------|
| AC-001 skill scaffolding | Must | `core/skills/agents-md/SKILL.md` with standard frontmatter |
| AC-002 listed in plugin manifest | Must | `scripts/compile.py` picks up new skill automatically |
| AC-003 default = `--write` | Must | SKILL instructs generator invocation; script default mode |
| AC-004 `--check` diff, no write | Must | `scripts/generate-agents-md.py --check` emits unified diff |
| AC-005 `--check` non-zero on drift | Must | Script exit 1 on diff; fixture test asserts exit code |
| AC-006 `--merge` prompts | Must | SKILL documents interactive flow; script has `--merge` non-interactive for tests (prepend mode) |
| AC-007 `--import` | Should | Script flag; SKILL documents — deferred test |
| AC-008 `--dry-run` | Should | Script flag; implemented |
| AC-009 template defines structure | Must | `core/templates/AGENTS.md.template` |
| AC-010 marker block | Must | `<!-- ADD:MANAGED:START version=X maturity=Y generated=Z -->` … `<!-- ADD:MANAGED:END -->` |
| AC-011 POC render | Must | `poc-project` fixture + branch in generator |
| AC-012 Alpha render | Must | `alpha-project` fixture + branch in generator |
| AC-013 Beta render | Must | `beta-project` fixture + branch in generator |
| AC-014 GA render | Should | Generator supports GA branch; no dedicated fixture (covered by Beta + config toggle) |
| AC-015 pointers | Must | All render branches include `## Pointers` section |
| AC-016 project identity from config + PRD | Must | Generator reads both |
| AC-017 engagement protocol summary | Must | Hand-written summary keyed by maturity (generator embeds) |
| AC-018 TDD summary (conditional) | Must | Omitted when `architecture.languages` contain only Markdown/JSON |
| AC-019 spec-first summary | Must | Embedded summary |
| AC-020 maturity + autonomy ceiling | Must | Reads `maturity.level` + `environments[*].autoPromote` |
| AC-021 active spec pointer | Must | Reads `.add/handoff.md` if present; else most recent `specs/*.md` by mtime |
| AC-022 `/add:init` integration | Must | SKILL edit |
| AC-023 `/add:spec` prompt | Must | SKILL edit |
| AC-024 CLAUDE.md update | Must | Edit |
| AC-025 verify gate opt-in | Should | SKILL edit + config flag documented |
| AC-026 PostToolUse hook | Must | `post-write.sh` case branch |
| AC-027 hook touches marker, not AGENTS.md | Must | Case branch writes `.add/agents-md.stale` |
| AC-028 next invocation announces stale | Should | SKILL documents; generator reads and clears after `--write` |
| AC-029 marker removed on write | Must | Generator unlinks on success |
| AC-030 frontmatter preserved | Must | Generator detects YAML/TOML/+++ prefix and passes through |
| AC-031 user content outside markers preserved | Must | Generator splits existing file on markers, rewrites only managed block |
| AC-032 missing marker aborts `--write` | Must | Generator exits 2 with directive |
| AC-033 validates schema | Must | Post-write check: required sections present, frontmatter well-formed |
| AC-034 fixture tests for 4 levels | Must | POC/Alpha/Beta covered; GA skipped (Should) |
| AC-035 drift test | Must | drift-project fixture + `--check` exit 1 |
| AC-036 merge test | Must | merge-project fixture + `--merge` |

## Deferred / Partial

- AC-014 GA render: generator branch implemented but no dedicated fixture test. Promote to Must in v0.9.x if a real GA-level project exists to dog-food against.
- AC-007 `--import` flag: script supports the flag but no dedicated fixture test. Documented in SKILL.
- AC-025 verify gate: implemented as documented instruction only. No automated integration test since `/add:verify` is a skill (markdown prompt), not a script.

## Phasing

### Phase 2 — RED
Build fixtures + test runner. Tests fail because generator doesn't exist yet.

### Phase 3 — GREEN
1. Write `scripts/generate-agents-md.py`.
2. Iterate until all fixture tests pass.
3. Add skill + template + hook branch + integrations.

### Phase 4 — Verify
Run compile + frontmatter + hook tests + new fixture tests. Run generator against this repo; commit resulting `AGENTS.md`.

### Phase 5 — Commit + PR
Three commits:
1. `feat(skills): agents-md skill + generator`
2. `feat(hooks): auto-mark AGENTS.md stale via post-write dispatcher`
3. `chore: dog-food — generated AGENTS.md`

## Risks

| Risk | Mitigation |
|------|------------|
| Marker format evolves and breaks older AGENTS.md | Keep marker HTML-comment based; version= field lets future renderers detect older blocks |
| Generator's maturity branches produce inconsistent output across OSes (line endings, timestamp) | Force `\n` line endings; emit timestamps only in marker meta (tested via deterministic `--generated=FIXED` override in fixtures) |
| Concurrent hook fires during test runs | Hook is idempotent (touch is atomic); tests don't fire hooks |

## Dog-food Decision

Run generator against ADD repo itself as a final sanity check. If output is clean, commit it as part of PR. If output exposes generator bugs, fix before committing; if fixes are out of scope for this PR, omit root AGENTS.md and note in PR body.

# Implementation Plan: Codex-Native Skills

> Status: Complete (v0.9.0) — superseded by shipped feature.

**Spec:** `specs/codex-native-skills.md`
**Target:** v0.9.0 (M3 pre-GA hardening)
**Status:** In progress
**Owner:** Swarm G (solo on `scripts/compile.py` during Wave 2)

## Scope

Retarget ADD's Codex adapter from the deprecated `~/.codex/prompts/` flat-file layout to the native Codex Skills format with:

1. Per-skill `.agents/skills/add-<skill>/SKILL.md` with preserved YAML frontmatter
2. Per-skill `agents/openai.yaml` policy file declaring `allow_implicit_invocation` + required tools
3. Slim `AGENTS.md` (≤500 lines) — manifest pointing at skills, not full-prompt concat
4. Sub-agent TOML files in `.codex/agents/` for the TDD roles
5. Hooks bundle in `.codex/hooks/` (SessionStart / Stop / UserPromptSubmit)
6. AskUserQuestion compatibility shim template
7. Plugin manifest (`plugin.toml`) for Codex marketplace installs
8. Pinned `min_codex_version` + `codex_cli_version` in `runtimes/codex/adapter.yaml`

## Deliverables

### Source-side (hand-written)

| File | Purpose |
|------|---------|
| `runtimes/codex/adapter.yaml` | Extended schema — pinned CLI version, native skills output, hooks/agents emission targets |
| `runtimes/codex/skill-policy.yaml` | Per-skill `allow_implicit_invocation` + `tools` policy (AC-009) |
| `runtimes/codex/templates/askuser-shim.md` | Shim preamble injected into interview skills (AC-027) |
| `runtimes/codex/hooks/load-handoff.sh` | SessionStart hook — surface `.add/handoff.md` content |
| `runtimes/codex/hooks/write-handoff.sh` | Stop hook — persist current state |
| `runtimes/codex/hooks/handoff-detect.sh` | UserPromptSubmit — detect handoff intent |
| `runtimes/codex/hooks/README.md` | Claude-trigger-to-Codex-hook map (AC-025) |
| `runtimes/codex/agents/test-writer.toml` | Sub-agent TOML source (copied into dist verbatim) |
| `runtimes/codex/agents/implementer.toml` | Sub-agent TOML source |
| `runtimes/codex/agents/reviewer.toml` | Sub-agent TOML source |
| `runtimes/codex/agents/explorer.toml` | Sub-agent TOML source |
| `runtimes/codex/config.toml` | Global `[agents]` + `[features]` config (source copy) |
| `runtimes/codex/README.md` | New — documents the native install layout |

### Generated (dist/codex/)

| Path | Purpose |
|------|---------|
| `dist/codex/.agents/skills/add-<name>/SKILL.md` | Per-skill native Codex skill (26 skills) |
| `dist/codex/.agents/skills/add-<name>/agents/openai.yaml` | Per-skill invocation policy |
| `dist/codex/.codex/agents/*.toml` | Sub-agent TOML files |
| `dist/codex/.codex/config.toml` | `[agents]` + `[features]` global config |
| `dist/codex/.codex/hooks.json` | Hook registration manifest |
| `dist/codex/.codex/hooks/*.sh` | Hook shell scripts, mode 0755 |
| `dist/codex/.codex/hooks/README.md` | Hook mapping docs |
| `dist/codex/AGENTS.md` | Slim manifest (skills index + invariant rules, ≤500 lines) |
| `dist/codex/plugin.toml` | Codex plugin manifest |
| `dist/codex/VERSION` | Version sentinel |
| `dist/codex/README.md` | Install overview |
| `dist/codex/templates/` | Templates (unchanged — still shipped verbatim) |

### Removed from dist/codex/

- `dist/codex/prompts/` — legacy flat-file path, superseded by `.agents/skills/`

## compile.py Changes

Add four new functions:

1. `load_skill_policy()` — reads `runtimes/codex/skill-policy.yaml`, returns dict keyed by skill name. Compile fails if any skill under `core/skills/` is missing a policy entry.
2. `emit_codex_native_skills(version, policy)` — for each `core/skills/<name>/`, writes:
   - `dist/codex/.agents/skills/add-<name>/SKILL.md` with version-substituted body + rewritten frontmatter (adds `name: add-<name>` if missing; keeps `description`)
   - `dist/codex/.agents/skills/add-<name>/agents/openai.yaml` from the policy entry
   - Applies AskUserQuestion shim preamble when `requires_askuser_shim: true`
3. `emit_codex_manifest_agents_md(version)` — writes a slim `AGENTS.md`:
   - Header + ADD invariants (rules with `autoload: always`)
   - Auto-generated skill table from `.agents/skills/*/SKILL.md` frontmatter
   - Hard-fails build if the output exceeds 500 lines (AC-014)
4. `emit_codex_agents_hooks_config(version)` — copies `runtimes/codex/agents/*.toml`, `config.toml`, `hooks/`, and writes `hooks.json`
5. `emit_codex_plugin_manifest(version)` — writes `plugin.toml` from adapter metadata + scanned skill list

Modifications to existing logic:

- `compile_codex` re-orchestrates: call the new emit functions in order, drop the old `prompts/` emission entirely.
- The slim AGENTS.md replaces the existing concat logic.
- `clean_output(output)` still runs first so the legacy `prompts/` directory disappears from the dist.

## Rule Autoload Classification

`AGENTS.md` only carries rules with `autoload: always`. Rules with `autoload: conditional` or `autoload: never` live inside skills that reference them (via the existing `@rules/...` mechanism in Claude, which in Codex translates to inline expansion within the skill body). This spec does not rewrite existing skill bodies — it just slims the top-level manifest.

## AC Coverage Matrix

| AC | Deliverable(s) |
|----|----------------|
| AC-001 | `emit_codex_native_skills` writes to `.agents/skills/add-*/SKILL.md`; legacy `prompts/` no longer emitted |
| AC-002 | Frontmatter preserved (adds `name:` if missing, keeps `description:` verbatim) |
| AC-003 | `add-<dirname>` namespace enforced in emit step |
| AC-004 | Skill bodies untouched — `/add:` references pass through |
| AC-005 | Companion templates: skills may reference `templates/` — handled by existing `templates/` verbatim copy (dist-level, not per-skill); spec AC allows per-skill colocation but existing layout suffices for v0.9 since no skill ships skill-local templates today |
| AC-006 | `agents/openai.yaml` emitted per skill |
| AC-007 | High-leak skills pinned in `skill-policy.yaml` with `allow_implicit_invocation: false` |
| AC-008 | Remaining skills default `true` |
| AC-009 | `skill-policy.yaml` is canonical; compile fails if skill lacks entry |
| AC-010 | Resolution: one-file-per-skill (spec open question Q2 resolved to per-skill form, which is the more explicit pattern) |
| AC-011 | Slim `AGENTS.md` ≤ 500 lines (target ≤350) |
| AC-012 | Only `autoload: always` rules included |
| AC-013 | Skill table generated by reading `SKILL.md` frontmatter |
| AC-014 | 500-line cap enforced — build fails loudly if exceeded |
| AC-015 | Four TOML files emitted |
| AC-016 | `model_reasoning_effort` per-role |
| AC-017 | `sandbox_mode` per-role |
| AC-018 | `.codex/config.toml` `[agents]` section |
| AC-019 | `.codex/config.toml` `[features]` section |
| AC-020 | Each TOML's `prompt_skill = "add-*"` — no prompt duplication |
| AC-021 | `hooks.json` declares SessionStart / Stop / UserPromptSubmit |
| AC-022 | Documented in `hooks/README.md` |
| AC-023 | Scripts use `set -euo pipefail` + no-op on missing `.add/` |
| AC-024 | Chmod 0755 at emit time; compile fails otherwise |
| AC-025 | `hooks/README.md` ships the trigger-map |
| AC-026 | Shim preamble auto-injected for interview skills |
| AC-027 | Shim template at `runtimes/codex/templates/askuser-shim.md` |
| AC-028 | Shim wording explicitly halts (spec language) |
| AC-029 | `plugin.toml` emitted with all required fields |
| AC-030 | Structural validity — regression guard via fixture tests (real CLI validation deferred to AC-035 integration job) |
| AC-031 | Marketplace.json extended with Codex entry |
| AC-032 | `min_codex_version` pinned to 0.122 (per spec open question Q1, spec's proposed default) |
| AC-033 | `adapter.yaml` extended with new emission targets |
| AC-034 | `compile.py --check` passes after commit |
| AC-035 | Deferred — requires pinned Codex CLI container, which is downstream infra |

## Open Questions — Resolution

- **Q1 — Pin version:** 0.122 (spec's proposed default).
- **Q2 — One-file-per-skill vs shared:** Per-skill, for explicitness + per-skill override surface.
- **Q3 — Version-pin manifest schema:** Version-pin. Simpler; drift caught by compile-drift CI + a snapshot of the expected manifest schema at `runtimes/codex/snapshots/plugin-manifest-0.122.toml` (deferred — snapshot file is a hand-entered prior art, not auto-synced).
- **Q4 — Sub-agent `tools` allowlist:** Rely on `sandbox_mode` only for v0.9. Tighter allowlist can come in v0.10+.
- **Q5 — Shim batch vs halt:** Halt. Fail-closed is the spec's behavioral AC (AC-028).

## Risk Register

| Risk | Mitigation |
|------|-----------|
| Compile-drift CI rejects the full-repo regeneration | Run `--check` locally before pushing; commit the regenerated output atomically with the compile.py changes. |
| Slim AGENTS.md accidentally drops content consumers relied on | Documented cutover in README + migration note in runtimes/codex/README.md. Legacy users get fresh install (spec non-goal §6). |
| Skill frontmatter has unexpected keys breaking YAML round-trip | Parser is line-based (string slice between `---` delimiters), so all keys pass through. `name:` is appended if missing. |
| Hook scripts break in non-ADD projects | All three scripts guarded with `[ -f .add/handoff.md ] || exit 0` style early returns. |
| 500-line AGENTS.md cap forces content loss | Measured the slim format: ~40 lines of invariants + 26-row skill table + preamble = ~180 lines. Headroom is generous. |

## Test Strategy (Phase 2 RED)

1. **Fixture test `tests/codex-native-skills/test-codex-native-skills.sh`**
   - Invokes `python3 scripts/compile.py --runtime codex`
   - Asserts: `.agents/skills/add-spec/SKILL.md` exists, starts with `---`, contains `name: add-spec`
   - Asserts: no `dist/codex/prompts/` directory
   - Asserts: `AGENTS.md` wc -l ≤ 500
   - Asserts: `dist/codex/.codex/agents/test-writer.toml` exists with `model_reasoning_effort = "high"`
   - Asserts: `dist/codex/.codex/hooks.json` exists with SessionStart key
   - Asserts: hook scripts are mode 0755
   - Asserts: `plugin.toml` exists with `min_codex_version` key
2. **Drift-check**: `python3 scripts/compile.py --check` must return 0 after commit.
3. **Frontmatter validation**: `python3 scripts/validate-frontmatter.py` must return 0.
4. **Legacy hook tests**: `bash tests/hooks/test-filter-learnings.sh` must pass (untouched).

## Sequencing

1. Write `skill-policy.yaml` + `askuser-shim.md` + hook scripts + agent TOMLs (source files).
2. Extend `adapter.yaml`.
3. Extend `scripts/compile.py` with the five new functions.
4. Write the fixture test.
5. Run the test → expect RED on first iteration.
6. Iterate compile.py until all asserts pass.
7. Run `compile.py` full repo, commit the regenerated dist.
8. Run `compile.py --check` → should be clean.
9. Update `runtimes/codex/README.md` + `install-codex.sh` for the new layout.
10. Commit, push, open PR.

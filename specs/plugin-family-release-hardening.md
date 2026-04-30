# Spec: ADD Plugin Family Release Hardening

**Version:** 0.1.0
**Created:** 2026-04-23
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Releases:** v0.8.1, v0.9.0, v1.0.0
**Milestone:** M3-pre-ga-hardening

## 1. Overview

ADD has moved from a single Claude Code plugin toward a family of loosely coupled runtime plugins backed by a shared methodology core. The latest review found that the direction is sound: `core/`, `runtimes/`, generated Codex-native skills, sub-agents, hooks, guardrail specs, and local fixture tests now exist. The risk is that several distribution, runtime, and proof contracts are still inconsistent after the refactor.

This spec converts the five-swarm review into release criteria for three versions:

- **v0.8.1:** hotfix the install/distribution breaks and the most urgent guardrail bypass.
- **v0.9.0:** make the plugin-family architecture coherent: host-neutral kernel, executable adapter contracts, generated docs/catalogs, schema/migration validation, and runtime-specific overlays.
- **v1.0.0:** prove the claims end to end with real Claude and Codex smoke tests, enforced CI gates, operational security controls, and release evidence.

### User Story

As an ADD maintainer shipping a plugin family for Claude Code and Codex, I want every runtime package to install, load, execute, and enforce ADD guardrails consistently, so users can trust ADD as a methodology rather than a collection of stale markdown instructions.

## 2. Swarm Aggregate Findings

The review used five perspectives: product/adoption, architecture/modularity, Codex-native support, Claude/distribution compatibility, and security/ops. Findings below are deduplicated and assigned to the earliest release that should address them.

| ID | Severity | Finding | Evidence | Target | Rationale |
|----|----------|---------|----------|--------|-----------|
| F-001 | P0 | Claude marketplace manifest is invalid. Root marketplace validation fails on top-level `description`. | `.claude-plugin/marketplace.json`; `claude plugin validate .` | v0.8.1 | |
| F-002 | P0 | Codex install paths do not match generated skill references. Skills reference `~/.codex/templates`, `~/.codex/knowledge`, `~/.codex/rules`, and `~/.codex/lib`; installer stages only some shared assets under `~/.codex/add`. | `scripts/install-codex.sh`, `scripts/compile.py`, `dist/codex/.agents/skills/*/SKILL.md` | v0.8.1 | |
| F-003 | P1 | Test rewrite guardrail can be bypassed with `--allow-test-rewrite` and no recorded human override. | `scripts/check-test-count.py` | v0.8.1 | |
| F-004 | P1 | Public Codex docs describe legacy prompts and wrong minimum version. | `README.md`, `docs/codex-install.md`, `dist/codex/plugin.toml` | v0.8.1 | |
| F-005 | P1 | CI does not run the new guardrail suites or post-install smoke tests. | `.github/workflows/*.yml`, `tests/*` | v0.8.1 then v1.0 | |
| F-006 | P1 | ADD core remains Claude-shaped: `CLAUDE.md`, `.claude`, `~/.claude/add`, and Claude command syntax appear in core skills and Codex output. | `core/skills/init/SKILL.md`, generated Codex skills | v1.1.0 | Architectural — deferred per D2 to post-GA v1.1.0. v0.9.7 ships Tier 1 substitution-only close (~80% of leak); full host-neutral kernel is M4 work. |
| F-007 | P1 | Runtime adapter YAML files are descriptive, not authoritative. Compile and installer scripts hard-code output contracts. | `runtimes/*/adapter.yaml`, `scripts/compile.py`, `scripts/install-codex.sh` | v1.1.0 | Architectural — deferred per D2 to post-GA v1.1.0. AC-010 may land conditionally in v0.10 if capacity allows; full close belongs to the M4 architectural cycle alongside Cursor/Cline adapters. |
| F-008 | P1 | Codex marketplace/package format is incomplete or speculative for the current CLI. | `dist/codex/plugin.toml`, missing `.codex-plugin/plugin.json`, missing `.agents/plugins/marketplace.json` | v0.9.0 | |
| F-009 | P1 | Codex skill policy metadata may not match local Codex conventions. | `dist/codex/.agents/skills/*/agents/openai.yaml` | v0.9.0 | |
| F-010 | P1 | Hooks and config are staged but not necessarily enabled; hook paths may miss depending on global vs plugin-relative install. | `scripts/install-codex.sh`, `dist/codex/.codex/hooks.json` | v0.9.0 | |
| F-011 | P1 | Claude rule distribution has drifted. `/add:init` and Claude runtime references include fewer rules than `core/rules/`. | `core/skills/init/SKILL.md`, `runtimes/claude/CLAUDE.md`, `core/rules/` | v0.8.1 | |
| F-012 | P1 | Prompt-injection hook warnings may be audited but not surfaced through the current Claude feedback path. | `runtimes/claude/hooks/posttooluse-scan.sh`, `runtimes/claude/hooks/hooks.json` | v0.8.1 | |
| F-013 | P1 | Telemetry is specified but not emitted by skills through a shared operational writer. | `core/rules/telemetry.md`, `core/skills/*` | v0.9.0 | |
| F-014 | P1 | Secrets gate remains mostly declarative; tests prove regex fixtures but not staged commit blocking behavior. | `core/skills/deploy/SKILL.md`, `tests/secrets-handling/` | v0.9.0 | |
| F-015 | P1 | Config schema and migration graph are under-specified. Template version and migration paths do not line up cleanly with current version. | `core/templates/config.json.template`, `core/templates/migrations.json`, `core/schemas/` | v0.9.0 | |
| F-016 | P2 | Installer ownership/collision story is weak. It deletes/replaces `add-*` skills and generic agents without an ownership manifest. | `scripts/install-codex.sh` | v0.9.0 | |
| F-017 | P2 | `jq` dependency contradicts zero-dependency messaging unless guarded or documented. | `runtimes/claude/hooks/*`, `README.md` | v0.8.1 | |
| F-018 | P2 | Cache-discipline strict mode is not yet enforceable across `core/skills`. | `scripts/validate-cache-discipline.py --strict core/skills` | v0.9.0 | |
| F-019 | P2 | Version and command catalog drift confuse users. Counts, names, and release markers disagree across README, marketplace, AGENTS, and dist. | `README.md`, `.claude-plugin/marketplace.json`, `AGENTS.md`, `dist/codex/AGENTS.md` | v0.9.0 | |
| F-020 | P2 | Website/report/infographic assets are stale or detached from the runtime catalog. | `reports/`, `docs/infographic.svg`, website repo pointer | v1.0.0 | |

## 3. Acceptance Criteria

### A. v0.8.1 Hotfix: Install Truth and Immediate Guardrails

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `claude plugin validate .` passes for the root marketplace and `claude plugin validate plugins/add` continues to pass. | Must |
| AC-002 | Codex generated skills reference one canonical installed ADD root. The installer copies every referenced shared asset into that root, including templates, knowledge, rules, lib helpers, security patterns, scripts needed by skills, plugin metadata, and version files. | Must |
| AC-003 | A temp-home Codex installer smoke test verifies that every generated absolute `~/.codex/...` reference in installed skills resolves to an installed file or an intentionally user-owned path. | Must |
| AC-004 | `--allow-test-rewrite` does not bypass approval. Same-name replacements require either a valid human-approved override record or a valid commit trailer, and tests assert the no-override case fails. | Must |
| AC-005 | README and Codex install docs state the current runtime shape: native Codex Skills, sub-agents, hooks, and `min_codex_version = 0.122.0` or the currently validated version. | Must |
| AC-006 | Claude rule distribution is generated or parity-checked so `/add:init`, Claude runtime context, and `core/rules/` cannot silently drift. | Must |
| AC-007 | Prompt-injection hook warnings use the documented Claude-visible feedback path or are explicitly downgraded in claims until surfaced. Tests assert visibility, not just stderr text. | Must |
| AC-008 | Hook scripts either guard optional `jq` usage or docs declare `jq` as a requirement. README no longer claims "zero dependencies" without qualification if runtime hooks require external tools. | Should |
| AC-009 | CI runs the existing local guardrail suites: compile drift, frontmatter, Codex-native shape, prompt-injection fixtures, secrets fixtures, cache fixtures, telemetry fixtures, AGENTS sync, hook filtering, and test-deletion guardrail. | Must |

### B. v0.9.0 Architecture: Runtime Contracts and Host-Neutral Kernel

| ID | Criterion | Priority | Target |
|----|-----------|----------|--------|
| AC-010 | `runtimes/*/adapter.yaml` becomes an executable contract for output roots, path variables, copied assets, manifest shape, hooks, skill policy schema, and runtime-specific substitutions. Compile/install scripts read this contract or drift tests fail when they disagree. | Must | v1.1.0 (D2 deferral; conditional Tier 2 land in v0.10 if capacity allows) |
| AC-011 | ADD introduces neutral path variables such as `${ADD_HOME}`, `${ADD_RUNTIME_ROOT}`, and `${ADD_USER_LIBRARY}`. Core skills stop using `${CLAUDE_PLUGIN_ROOT}` for host-neutral assets. | Must | v1.1.0 (D2 deferral; conditional Tier 2 land in v0.10 if capacity allows) |
| AC-012 | Core skill content is split into host-neutral methodology plus runtime overlays. Claude owns `CLAUDE.md`, `.claude`, `~/.claude/add`, `/add:skill`, Claude tool names, and Claude hook feedback. Codex owns `AGENTS.md`, `.codex`, `~/.codex/add`, `/add-skill`, Codex skill metadata, and Codex hook behavior. | Must | v1.1.0 (D2 Tier 3 — full host-neutral methodology + runtime overlay split is M4 work) |
| AC-013 | Codex plugin packaging matches the pinned Codex CLI's actual marketplace/plugin conventions, including manifest name, marketplace entry, skill paths, agent paths, hooks, and UI metadata. | Must | v0.9.0 |
| AC-014 | Codex `agents/openai.yaml` shape matches the pinned Codex convention and is validated in CI. High-leak skills remain explicit-only. | Must | v0.9.0 |
| AC-015 | Codex config and hooks are either installed plugin-relative and enabled by the plugin mechanism, or safely merged into global config with backup, detection, and clear user instructions. | Must | v0.9.0 |
| AC-016 | Installers maintain an ownership manifest, avoid clobbering non-ADD files, namespace agents where needed, support `--dry-run`, and uninstall only owned files. | Must | v0.9.0 |
| AC-017 | Config schema exists and validates `.add/config.json`. Migration graph tests prove every supported historical version can migrate to `core/VERSION`. | Must | v0.9.0 |
| AC-018 | Telemetry has a shared append helper or generated post-flight block, and skills emit success, failure, abort, and partial outcomes when telemetry is enabled. | Must | v0.9.0 |
| AC-019 | Secrets handling has an executable staged-content scanner that reads the shared catalog, respects `.secretsignore`, redacts matched values, and blocks deploy/verify when configured. | Must | v0.9.0 |
| AC-020 | Cache-discipline strict mode passes for intended dispatching skills or false positives are explicitly suppressed with documented markers. | Should | v0.9.0 |
| AC-021 | Command catalog is generated from the source of truth and renders Claude syntax, Codex syntax, implicit-dispatch policy, risk level, and skill count consistently across README, marketplace metadata, runtime AGENTS/CLAUDE docs, and website inputs. | Must | v0.9.0 |

### C. v1.0.0 Release Confidence: End-to-End Proof

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-022 | CI performs real Claude marketplace validation/install smoke and confirms key ADD commands/skills are discoverable after install. | Must |
| AC-023 | CI performs real Codex marketplace/plugin install smoke against the pinned CLI and confirms skill discovery, explicit-only blocking, agent registration, hook registration, and one dry ADD workflow. | Must |
| AC-024 | Guardrail tests are release-blocking: test deletion/rewrite, prompt-injection surfacing, secrets gate, telemetry emission, cache discipline, config migration, command catalog drift, and AGENTS sync. | Must |
| AC-025 | Release artifacts include generated evidence: supported runtime matrix, known limitations, install smoke outputs, command catalog, version map, and migration coverage. | Must |
| AC-026 | Public docs and site assets are regenerated from the runtime catalog and release evidence. Stale reports are archived or marked historical. | Must |
| AC-027 | Security claims are calibrated per runtime. If Codex lacks an equivalent feedback channel for a hook, docs state the limitation and offer the best available polling or audit-log path. | Must |
| AC-028 | Release process supports tag-pinned installs or checksum/signed-release verification for public install scripts. `curl main | bash` is not the recommended stable install path. | Should |

## 4. User Test Cases

### TC-001: Claude marketplace validates and installs

**Precondition:** Fresh machine or clean Claude plugin cache with Claude Code pinned to the supported version.

**Steps:**
1. Run `claude plugin validate .`.
2. Run `claude plugin marketplace add` against the ADD repo or local checkout.
3. Run `claude plugin install add@add-marketplace`.
4. Start a session and check that representative ADD skills are discoverable.

**Expected Result:** Marketplace validation and install succeed. `/add:init`, `/add:spec`, `/add:verify`, `/add:agents-md`, and `/add:version` are discoverable.

**Maps to:** AC-001, AC-022

### TC-002: Codex install resolves all generated skill paths

**Precondition:** Empty temp `CODEX_HOME`.

**Steps:**
1. Run `scripts/install-codex.sh` with `CODEX_HOME` pointing at the temp directory.
2. Scan installed ADD skills for generated `~/.codex/...` references.
3. Resolve each reference against the temp home.

**Expected Result:** All plugin-owned references resolve to installed files. User-owned paths are explicitly allowlisted.

**Maps to:** AC-002, AC-003

### TC-003: Test rewrite requires explicit approval

**Precondition:** RED and GREEN fixture snapshots contain the same test name with a weakened body and no override record.

**Steps:**
1. Run `check-test-count.py gate` without `--allow-test-rewrite`.
2. Run the same gate with `--allow-test-rewrite` but no override record.
3. Add a valid human-approved override record and rerun.

**Expected Result:** Steps 1 and 2 fail. Step 3 passes and reports `override_used: true`.

**Maps to:** AC-004

### TC-004: Runtime docs match emitted manifests

**Precondition:** Clean checkout after compile.

**Steps:**
1. Generate the command/runtime catalog.
2. Compare README, Codex install docs, marketplace metadata, `dist/codex/AGENTS.md`, and plugin manifests.

**Expected Result:** Version, skill count, command syntax, runtime minimums, and install shape match the generated catalog.

**Maps to:** AC-005, AC-021, AC-026

### TC-005: Adapter contract drives compile output

**Precondition:** Modify a runtime adapter output path in a fixture branch.

**Steps:**
1. Run the compiler.
2. Run adapter drift tests.

**Expected Result:** Either compile output follows the adapter contract or the drift test fails with a clear contract mismatch.

**Maps to:** AC-010

### TC-006: Host-neutral core does not emit Claude-specific text into Codex skills

**Precondition:** Codex runtime is compiled.

**Steps:**
1. Scan generated Codex skills for unapproved Claude-specific terms: `CLAUDE.md`, `.claude`, `~/.claude/add`, `/add:`, `Task`, and Claude plugin update instructions.
2. Apply allowlist for intentional interoperability notes.

**Expected Result:** No unapproved Claude-specific content appears in Codex runtime output.

**Maps to:** AC-011, AC-012, AC-021

### TC-007: Safety controls are operational, not only documented

**Precondition:** CI test project with staged secret fixture, prompt-injection fixture, telemetry-enabled config, and cache-discipline fixtures.

**Steps:**
1. Run verify/deploy secrets gate against staged diff.
2. Run prompt-injection hook fixture and assert runtime-visible feedback.
3. Run a telemetry-enabled skill smoke and check JSONL emission.
4. Run cache strict mode.

**Expected Result:** Secrets gate blocks, prompt-injection warning is visible, telemetry JSONL is emitted, and cache strict mode passes or reports intentional suppressions.

**Maps to:** AC-018, AC-019, AC-020, AC-024, AC-027

## 5. Data Model

### Runtime Adapter Contract

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `runtime` | string | Yes | Runtime id such as `claude` or `codex`. |
| `version_floor` | string | Yes | Minimum host runtime version validated by ADD. |
| `output_root` | string | Yes | Compile output path for the runtime package. |
| `install_root` | string | Yes | Canonical installed ADD root for plugin-owned shared assets. |
| `path_vars` | object | Yes | Runtime substitutions for `${ADD_HOME}`, `${ADD_USER_LIBRARY}`, and similar tokens. |
| `assets` | array | Yes | Source-to-destination copy rules for templates, knowledge, rules, lib, security, scripts, manifests. |
| `skills` | object | Yes | Skill source, output path, metadata schema, policy source, and runtime overlay rules. |
| `hooks` | object | No | Hook source, manifest shape, path mode, enablement strategy, and feedback semantics. |
| `agents` | object | No | Agent source, naming strategy, sandbox policy, and runtime enablement. |
| `docs` | object | No | Generated docs and command catalog outputs. |

### Installer Ownership Manifest

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `plugin` | string | Yes | `add`. |
| `version` | string | Yes | Installed ADD version. |
| `runtime` | string | Yes | `codex`, `claude`, or future runtime id. |
| `installed_at` | string | Yes | ISO timestamp. |
| `files` | string[] | Yes | Absolute installed file paths owned by ADD. |
| `backups` | object | No | Map of overwritten file to backup path. |
| `source` | string | Yes | Tag, commit, or local path used for install. |

### Command Catalog Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `skill` | string | Yes | Canonical skill id without runtime syntax. |
| `description` | string | Yes | One-line user-facing description. |
| `claude_command` | string | Yes | Example: `/add:verify`. |
| `codex_command` | string | Yes | Example: `/add-verify`. |
| `implicit_dispatch` | boolean | Yes | Whether runtime dispatcher may auto-invoke. |
| `risk` | string | Yes | `low`, `medium`, or `high-leak`. |
| `writes_files` | boolean | Yes | Whether skill can write/edit files. |
| `requires_interview` | boolean | Yes | Whether skill requires one-question-at-a-time human input. |

## 6. Non-Goals

- This spec does not rewrite every ADD skill body by hand in v0.8.1. Host-neutral extraction is a v0.9.0 goal.
- This spec does not require Codex and Claude to expose identical capabilities. Runtime differences must be documented and tested.
- This spec does not require adding a backend service or central registry. ADD remains repo-local and workstation-local.
- This spec does not require official marketplace acceptance before v1.0, only that self-hosted/package install paths are valid and tested.

## 7. Open Questions

| ID | Question | Owner | Target |
|----|----------|-------|--------|
| Q-001 | What is the exact Codex plugin marketplace manifest schema for the pinned CLI version, and should ADD use `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, `plugin.toml`, or a combination during transition? | Codex runtime owner | v0.9.0 |
| Q-002 | Should the user-local ADD library remain `~/.claude/add` for backward compatibility, or migrate to a neutral `~/.add` with runtime-specific symlinks/import? | Architecture owner | v0.9.0 |
| Q-003 | Which hook feedback channels are guaranteed visible in current Claude and Codex versions, and where must ADD downgrade claims? | Security owner | v0.8.1 |
| Q-004 | What minimum versions of Claude Code and Codex CLI will v1.0 support? | Release owner | v1.0.0 |

## 8. Dependencies

- Existing specs: `specs/codex-native-skills.md`, `specs/test-deletion-guardrail.md`, `specs/prompt-injection-defense.md`, `specs/secrets-handling.md`, `specs/telemetry-jsonl.md`, `specs/cache-discipline.md`, `specs/agents-md-sync.md`.
- Runtime sources: `runtimes/claude/`, `runtimes/codex/`.
- Build and validation scripts: `scripts/compile.py`, `scripts/install-codex.sh`, `scripts/check-test-count.py`, `scripts/validate-frontmatter.py`, `scripts/validate-cache-discipline.py`.
- Local guardrail suites under `tests/`.

## 9. Risks

| Risk | Mitigation |
|------|------------|
| Codex plugin schema changes while ADD is targeting it. | Pin CLI version in adapter contract and run smoke tests against that version. |
| Host-neutral extraction becomes too large for v0.9.0. | Keep v0.8.1 focused on install truth; in v0.9.0 migrate path variables and command catalog before deeper prose cleanup. |
| Runtime overlays diverge from core semantics. | Generate overlay diffs and require AC coverage traceability from neutral core to runtime output. |
| CI becomes slow with real runtime smoke tests. | Split fast structural tests from nightly/full release smoke, but make release smoke blocking before tags. |
| Public docs overpromise security parity. | Maintain a runtime capability matrix and require known limitations in release notes. |


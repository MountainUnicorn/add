# Changelog

All notable changes to ADD are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

For commit-level detail see `git log`.

## [0.8.1] — 2026-04-23

Hotfix. Fixes three findings from the plugin-family release-hardening review before v0.9.0 ships. The M3 feature set (agents-md, cache-discipline, secrets-handling, telemetry-jsonl, prompt-injection-defense, test-deletion-guardrail, codex-native-skills) has already merged to main; this release makes that merge actually installable and makes the test-deletion guardrail actually enforce.

### Fixed

- **Claude marketplace validation (F-001).** `.claude-plugin/marketplace.json` had `description` at the root, which the marketplace schema rejects. Moved into the `metadata` object per the validator's guidance. `claude plugin validate .` and `claude plugin validate plugins/add` both now pass. Removed the stale `"13 commands, 12 skills, 15 rules"` count string — counts drift; manifests aren't the right place for them.
- **Codex install path mismatch (F-002).** Generated Codex skills referenced `~/.codex/templates/`, `~/.codex/knowledge/`, `~/.codex/rules/`, `~/.codex/lib/`, `~/.codex/security/`, but `scripts/install-codex.sh` stages shared assets under the namespaced `~/.codex/add/` subdirectory. Every skill invocation on Codex would have failed to resolve its asset refs. Fixed by pointing the `${CLAUDE_PLUGIN_ROOT}` → Codex substitution at `~/.codex/add/` and adding a separate `${CLAUDE_PLUGIN_ROOT}/hooks` → `~/.codex/hooks` rule (hooks stay at the Codex-conventional root). `scripts/compile.py` now also ships `core/rules/` and `core/security/` into `dist/codex/`, and `scripts/install-codex.sh` stages `knowledge/`, `rules/`, `lib/`, `security/` under `$CODEX_HOME/add/` alongside the existing `templates/`. `filter-learnings.sh` is also now shipped into Codex's hooks dir as a cross-runtime utility.
- **Test-deletion guardrail bypass (F-003).** `scripts/check-test-count.py` treated `--allow-test-rewrite` as a full bypass of the same-name-replacement approval check instead of as an acknowledgment flag that still required a recorded override. The documented intent (flag **AND** override record) matched the error message but not the code. Fix: the replacement check now runs unconditionally; `--allow-test-rewrite` is required to acknowledge intent, AND either a recorded override in `.add/cycles/cycle-{N}/overrides.json` or an `[ADD-TEST-DELETE: <reason>]` commit trailer is required to pass. Regression fixture `replacement-with-flag-no-override` added — proves the flag alone is insufficient.

### Added

- **`tests/codex-install/test-install-paths.sh`** — F-002 regression smoke. Installs the Codex adapter into a temp `CODEX_HOME`, collects every `~/.codex/...` reference from installed skill bodies, and asserts each one resolves (or is explicitly allowlisted). Runs in seconds; no Codex CLI needed.

### Known limitations (tracked for v0.8.2)

- `/add:version` reads `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`, which has no Codex equivalent (the Codex version lives in `plugin.toml` or `VERSION`). Allowlisted in the new smoke test; cross-runtime fix deferred.
- Hotfix does not address F-004+ from the plugin-family review — adapter contracts, host-neutral kernel, runtime overlays, command catalog generator. Those remain M4 / v0.10+ scope, not v0.9.0 blockers.

## [Unreleased]

_(Nothing yet — tracking items go here between releases.)_

## [0.9.1] — 2026-04-23

Beta-polish release. Closes the four follow-ups that accumulated after v0.9.0 shipped: the last plugin-family-review leak, the time-boxed beta-promotion CI exemption, the Claude rule-parity drift, and the cache-discipline validator false-positive that Swarm A flagged at M3 merge.

### Fixed

- **`/add:version` cross-runtime path resolution.** The skill only documented reading `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`, which has no Codex equivalent. Added a three-source fallback (`plugin.json` → `plugin.toml` → `VERSION`) so the same skill body works on both runtimes — first hit wins, silent fall-through when a source is absent. Removes the last F-002 allowlist entry in `tests/codex-install/test-install-paths.sh`.
- **Claude rule-parity drift (F-011).** `runtimes/claude/CLAUDE.md` was importing 15 rules via `@rules/` — it's been stuck at that count since before M3. The four rules landed in v0.9.0 (`cache-discipline`, `injection-defense`, `secrets-handling`, `telemetry`) are now imported, and the "15 files" count in the Plugin Structure tree diagram is now "19 files". New regression test `tests/rule-parity/test-rule-parity.sh` prevents future drift: asserts every `core/rules/*.md` has a matching `@rules/` import and that the tree-diagram count matches reality.
- **Cache-discipline validator false-positive on `core/skills/init/SKILL.md:1039` (F-018).** `scripts/validate-cache-discipline.py` was matching `/add:verify — run quality gates` (prose in `/add:init`'s output-preview block) as a sub-agent dispatch because its verb list included `run` and `call`. Tightened the 4th `DISPATCH_PATTERN` to require dispatch-specific verbs (`invoke`, `dispatch`, `sub-agent`) and made the regex order-agnostic so "Invoke the /add:test-writer skill" (verb-first prose in `/add:tdd-cycle`) still matches. Validator now passes clean on the full core tree and strict-mode passes on the four remediated skills.

### Added

- **Guardrail CI workflow** (`.github/workflows/guardrails.yml`) — closes the F-005 exemption from the v0.9.0 beta promotion. Runs every local fixture-based suite (93 tests across 10 suites) in parallel on PRs and pushes to main, plus frontmatter validation, cache-discipline validation (default + strict), and Claude marketplace manifest validation (with a grep guard because `claude plugin validate` exits 0 even on schema failure — discovered during v0.8.1 F-001).
- **`tests/rule-parity/test-rule-parity.sh`** — drift guard for F-011. Three checks: every `core/rules/*.md` has a `@rules/` import in `runtimes/claude/CLAUDE.md`, every `@rules/` import points at a real file, and the tree-diagram count matches.

### Changed

- **Beta-promotion exemption cleared.** `.add/config.json` `maturity.exemptions` was holding `[F-005 guardrail CI wiring]` as a time-boxed promise from the v0.9.0 alpha→beta promotion. Now empty.

## [0.9.0] — 2026-04-23

**Pre-GA hardening.** Ships the full M3 milestone in a single coordinated release: seven feature specs built in parallel by agent swarms during a `/add:away` session, squash-merged sequentially with rebase resolutions, and promoted through the v0.8.1 hotfix after the plugin-family review surfaced three shipping bugs. **Maturity: alpha → beta.** ADD is now production-credible for the methodology it prescribes: TDD guardrails that bite, secrets handling that gates deploy, prompt-injection defense with a scan hook and threat model, Codex-native skill emission, OTel-aligned telemetry, stable-prefix cache discipline, tool-portable AGENTS.md generation, and a test-deletion guardrail that defends the signature TDD claim.

### Added

- **`/add:agents-md` skill** — generates a tool-portable `AGENTS.md` at project root from `.add/` state. Maturity-aware verbosity (POC bullets → Alpha sectioned → Beta full → GA full + team conventions). ADD-managed content wrapped in `<!-- ADD:MANAGED:START … -->` markers so user-authored sections survive regeneration. Modes: `--write` (default), `--check` (CI drift gate, exit 1 on drift), `--merge` / `--import` (absorb hand-curated files). Implemented as `scripts/generate-agents-md.py` plus `core/skills/agents-md/SKILL.md`; fixture tests cover POC/Alpha/Beta render, drift detection, merge flow, idempotency, and staleness-marker clearing. Integrated into `/add:init` (initial generation) and `/add:spec` (active-spec pointer update). Opt-in `agentsMd.gateOnVerify` in `.add/config.json` enables Gate 4.5 in `/add:verify`.
- **PostToolUse staleness hook for AGENTS.md** — `runtimes/claude/hooks/post-write.sh` now writes `.add/agents-md.stale` when `.add/config.json`, `core/rules/*.md`, or `core/skills/*/SKILL.md` changes and an `AGENTS.md` exists at root. The hook never auto-rewrites AGENTS.md — the human triggers regen.
- **Prompt-injection defense** (spec `prompt-injection-defense`, M3 Cycle 2) — three-layer GA security story. New auto-loaded rule `core/rules/injection-defense.md` teaches the agent to treat untrusted content (PR comments, web fetches, foreign repos, `node_modules`) as data, never as instructions. New PostToolUse scan hook `runtimes/claude/hooks/posttooluse-scan.sh` pattern-matches tool output (Read, WebFetch, WebSearch, Bash) against `core/security/patterns.json` — eight named patterns covering OWASP Top 10 Agentic 2026, Snyk ToxicSkills, and the January 2026 Comment-and-Control attack. Audit events append to `.add/security/injection-events.jsonl`. New Tier-1 knowledge file `core/knowledge/threat-model.md` documents trust boundaries, defended attacks (T1-T5), out-of-scope threats, and warn-only posture for v0.9. Users can extend without forking via `.add/security/patterns.json` (project) or `~/.claude/add/security/patterns.json` (workstation).
- **Test-deletion guardrail** ([`specs/test-deletion-guardrail.md`](specs/test-deletion-guardrail.md), M3 Cycle 3). Defends ADD's signature TDD claim against the Kent Beck / TDAD-paper failure mode ("the genie doesn't want to do TDD — it deletes the failing test"). New `scripts/check-test-count.py` snapshot/compare/gate CLI plus `core/lib/impact-hint.sh` files-likely-affected helper. New Gate 3.5 in `/add:verify` fails the cycle if `tests_removed > 0` without a recorded override. Renames (same body, new name) allowed; replacements (same name, rewritten body) require `--allow-test-rewrite` + human approval persisted in `.add/cycles/cycle-{N}/overrides.json`. Justification marker `[ADD-TEST-DELETE: <reason>]` also accepted as commit trailer. New `core/knowledge/test-discovery-patterns.json` catalog covers Python, TS/JS, Go, Ruby, Rust — extensible per project.

### Changed

- **Marketing site extracted to a separate repo** ([`MountainUnicorn/getadd.dev`](https://github.com/MountainUnicorn/getadd.dev)) so future commercial elements can land there without touching the open-source plugin. Full git history (38 commits) preserved via `git filter-repo`. Domain `getadd.dev` re-claimed on the new repo with the existing TLS cert. The plugin repo no longer contains `website/`, `.github/workflows/pages.yml`, or `scripts/deploy-website.sh`. The architecture SVG used by the README moved from `website/images/` to `docs/`.
- `CLAUDE.md` rewritten to reflect the v0.7+ source-of-truth flow (`core/` → `compile.py` → `plugins/add/` + `dist/codex/`) and the website-is-elsewhere reality.
- `CONTRIBUTING.md` testing-changes section: replaced the long ad-hoc rsync example with the canonical `compile.py` + `sync-marketplace.sh` workflow plus the three CI-gate validation commands.
- `scripts/sync-marketplace.sh`: dropped the now-unnecessary `--exclude='website/'`.
- `scripts/compile.py` now copies `core/security/` into `plugins/add/` and concatenates every `core/knowledge/*.md` file into the Codex `AGENTS.md` (previously only `global.md`).
- `runtimes/codex/adapter.yaml` updated to glob all knowledge files and document the Codex hook-stderr limitation that blocks automatic warning surfacing for injection events.
- **Maturity promoted alpha → beta** (2026-04-23). Readiness: ~92% against the cascade matrix (12/13 applicable requirements met, F-005 CI guardrail wiring held as a time-boxed exemption to v0.9.x). Rationale: M3 ships seven feature specs with 207 ACs, v0.8.1 hotfix closed three shipping bugs surfaced by plugin-family review, two community contributions merged, GPG-signed release pipeline live since v0.7.3, 5 signed releases, M1+M2+M3 milestones tracked to completion. Cascade changes now active: strict TDD enforcement, recommended-for-all-changes reviewer, balanced away-mode autonomy, ~12-question interview depth, parallel-agent ceiling raised to 3. Next promotion criteria (GA): guardrail suite running in CI and release-blocking, real Claude + Codex install smoke in CI, per-runtime capability matrix in release notes, 60-day stability at beta, marketplace submission approved, 20+ projects using ADD.

### M3 Pre-GA Hardening — Delivered

Seven feature specs planned together, built in parallel by worktree-isolated agent swarms during a `/add:away` session, and merged sequentially with rebase resolutions. Total: 207 acceptance criteria across 7 specs, plus the v0.8.1 plugin-family hotfix.

| Spec | Cycle | PR | Shipped |
|------|-------|----|---------|
| [`agents-md-sync`](specs/agents-md-sync.md) | 2 | [#8](https://github.com/MountainUnicorn/add/pull/8) | 36/36 ACs |
| [`cache-discipline`](specs/cache-discipline.md) | 1 | [#9](https://github.com/MountainUnicorn/add/pull/9) | 21/24 (3 telemetry ACs closed by #11) |
| [`secrets-handling`](specs/secrets-handling.md) | 1 | [#10](https://github.com/MountainUnicorn/add/pull/10) | 23/24 (AC-019 blocked on PR #6) |
| [`telemetry-jsonl`](specs/telemetry-jsonl.md) | 3 | [#11](https://github.com/MountainUnicorn/add/pull/11) | 30 ACs + closes cache deferral |
| [`codex-native-skills`](specs/codex-native-skills.md) | 2 | [#12](https://github.com/MountainUnicorn/add/pull/12) | 33/35 ACs, Codex CLI pinned 0.122.0 |
| [`test-deletion-guardrail`](specs/test-deletion-guardrail.md) | 3 | [#13](https://github.com/MountainUnicorn/add/pull/13) | 25 ACs; bypass closed via v0.8.1 F-003 fix |
| [`prompt-injection-defense`](specs/prompt-injection-defense.md) | 2 | [#14](https://github.com/MountainUnicorn/add/pull/14) | 30/30 ACs |

### Deferred to v0.9.x or v0.10

- `/add:parallel` worktree-based parallel cycle execution
- Routines/Loop integration adapter
- Capability-based `/add:eval` skill
- `/add:cycle` rename — defer to coincide with parallel-cycle redesign
- Brownfield delta-spec mode
- Architect/Editor model-role rule (v0.9.1 docs pass)
- Cross-tool memory schema for `~/.claude/add/`
- Governance maturity bands tied to autonomy ceilings

## [0.8.0] — 2026-04-22

Pre-filtered active learning views. Moves filtering work out of the LLM context window and into a `jq`-based hook, cutting autoload context cost by 62-82% as learnings accumulate. Community contribution from @tdmitruk via #7.

### Added

- **`hooks/filter-learnings.sh`** — generates a compact `learnings-active.md` companion file from `learnings.json`. Sorts by severity (`critical > high > medium > low`) then date, excludes archived entries, caps at the top N, and appends a one-line index of the rest so agents retain visibility. Mirrored at `~/.claude/add/library-active.md` for the Tier 2 library.
- **`hooks/post-write.sh`** — PostToolUse dispatcher that replaces the inline `case` block in `hooks.json`. Keeps ruff + eslint behavior, adds the learnings-filter dispatch, reads `active_cap` from `.add/config.json` with fallback `15`.
- **`/add:learnings` skill** — `migrate` (initial active-view generation, also handles legacy markdown → JSON), `archive` (interactive review of low/medium entries older than the configured threshold), and `stats` (counts, sizes, savings). All subcommands support `--dry-run`.
- **`archived` field on learning entries** — entries stay in the JSON for audit history but drop out of the active view. Never auto-archive `critical` or `high` severity.
- **Configurable thresholds** in `.add/config.json` `learnings` block: `active_cap` (15), `archival_days` (90), `archival_max_severity` (`medium`). Migration injects defaults for upgrading projects.
- **`run_hook` migration action type** — lets `migrations.json` invoke a plugin hook script during version migration with `script`, `args` (supports `{file}` placeholder), and `notify` parameters.
- **Migration chain completed** for projects on any prior version: `0.5.0 → 0.6.0`, `0.6.0 → 0.7.0`, `0.7.0 → 0.7.3`, and `0.7.0 → 0.8.0` hops added so installations from any historical release can reach 0.8.0.
- **`scripts/deploy-website.sh`** — Actions-free website deploy. Syncs `website/` into the `gh-pages` branch and triggers a build via GitHub's legacy Jekyll pipeline (runs on a separate pool from user Actions, so it works even when account-level Actions is restricted). Supports `--dry-run` and `--no-build`.
- **Fixture-based tests** under `tests/hooks/` for `filter-learnings.sh`: basic (sort + archive + group), overflow (forced index), large (15 top + 13 indexed + 2 archived), and empty inputs.

### Changed

- **`core/rules/learning.md`** — pre-flight reads `-active.md` instead of full JSON. The 60-line in-context "Smart Filtering" section is removed (replaced by the shell script). Adds an Archival section and a fallback chain (`active.md → run filter → read full JSON`).
- **`core/rules/project-structure.md`** — documents the new file layout (`learnings.json` + `learnings.md` + `learnings-active.md`) and gitignore additions.
- **PostToolUse hook glob** extended from `*learnings.json` to `*learnings.json|*library.json` so Tier 2 promotions during retro regenerate the library active view.

### Impact (token cost per session)

| Project size | Before (full JSON) | After (active view) | Reduction |
|---|---|---|---|
| 34 entries (this repo) | ~4,820 tokens | ~1,865 tokens | 62% |
| 200 entries (projected) | ~28,000 tokens | ~5,300 tokens | 82% |
| 500 entries (projected) | ~70,000 tokens | ~11,750 tokens | 83% |

### Safety

JSON is canonical and never modified by the filter. If the `-active.md` is missing or `jq` fails, agents fall back to running the script then reading the full JSON directly — no data loss possible. Compile-drift, frontmatter-validate, and rule-boundary CI gates all green; no NEVER markers were touched.

## [0.7.3] — 2026-04-12

First **fully GitHub-verified** signed release. v0.7.2 signed correctly but the commit author email didn't match a verified GitHub email, so GitHub showed `reason: no_user` and no green Verified badge. This release fixes the git identity so the author line matches the GPG UID and GitHub can cross-reference.

### Changed

- Global git config: `user.email = anthony.g.brooke@gmail.com`, `user.name = Anthony Brooke` — matches the GPG key UID `Anthony Brooke <anthony.g.brooke@gmail.com>`. Previously commits carried the hostname-derived email `abrooke@Anthonys-MacBook-Pro.local`, which GitHub could not map to a user account for verification.

### Known-unverified window

v0.7.2 cryptographic signature is valid and verifiable via `git tag --verify v0.7.2` after importing the key from `github.com/MountainUnicorn.gpg`. It is **not** shown as Verified on GitHub because the author email mismatch prevents GitHub from tying the signature to the maintainer's account. v0.7.3 and forward are properly Verified.

## [0.7.2] — 2026-04-12

First **cryptographically signed** release. Maintainer GPG key provisioned and published.

### Added

- **`scripts/release.sh`** — release helper that enforces clean tree, version/tag match, frontmatter validation, compile-drift check, signing-key presence, tag uniqueness, and CHANGELOG section presence before tagging. Extracts release notes from CHANGELOG. Supports `--dry-run` and `--draft`.
- **`docs/release-signing.md`** — maintainer runbook for first-time setup, cutting a release, multi-machine key sharing, rotation, expiration, and pinentry/GPG_TTY troubleshooting.

### Changed

- **`SECURITY.md`** now carries the real maintainer fingerprint: `040C 002A B5A0 E552 46B3 5D2F 8C4D 8020 9306 6794` — RSA 4096, identity `Anthony Brooke <anthony.g.brooke@gmail.com>`. Documents that v0.7.0 and v0.7.1 predate signing and will not be retroactively re-tagged (re-tagging a published release rewrites history users may have installed).
- Git config on the maintainer machine: `tag.gpgsign = true` (mandatory for releases); `commit.gpgsign = false` (opportunistic via `git commit -S`). Rationale: auto-signing commits blocks agent/CI sessions that can't interact with the GUI passphrase prompt. Tag signing is the verification anchor that matters per the threat model.

### Verification

```bash
curl -fsSL https://github.com/MountainUnicorn.gpg | gpg --import
git tag --verify v0.7.2
# Expected: Good signature from "Anthony Brooke <anthony.g.brooke@gmail.com>"
```

## [0.7.1] — 2026-04-12

Hardening release: ships the items deferred from v0.7.0, plus CHANGELOG + marketplace sync helper + self-retro archived.

### Added

- **`/add:deploy` production confirm-phrase gate** — runtime check requiring the exact string `DEPLOY TO PRODUCTION` (case-sensitive, whole-message, immediately-next-message). Closes the "behavioral, not technical" boundary gap flagged by the v0.7.0 security swarm. Halt-on-mismatch with no fuzzy matching.
- **`/add:init --quick`** — 5-question greenfield fast path (~2 min). Maps essential answers (name, stack, tier, maturity, autonomy) and defaults everything else. Skips adoption detection, profile-integration prompts, and Sections 3-7 of the full interview.
- **`/add:init --sync-registry`** — read-only reconciliation of `~/.claude/add/projects/{name}.json` against project ground truth. Previously the registry-sync rule could detect drift but had no command to fix it.
- **PII heuristic in `rules/learning.md`** — pre-write scan of learning-entry `title` + `body` for email/IP/API-key/JWT/private-key/password-like patterns. Halts with `[r]ewrite / [o]verride / [s]kip` prompt on match. Override records a `compliance-bypass` entry.
- **`--force-no-retro` abuse detection in `rules/add-compliance.md`** — escalation ladder based on bypass density in the last 30 days: 0 = silent, 1 = warn, 2 = require acknowledgment flag, 3+ = refuse until retro runs.
- **`CHANGELOG.md`** — full release history v0.1.0 → v0.7.1 at repo root
- **`scripts/sync-marketplace.sh`** — centralizes the rsync pattern previously documented only in memory; includes exclusion list + recompile-first

### Changed

- Infographic (`docs/infographic.svg`) version stamp bumped to v0.7.1; structural refresh to reflect multi-runtime messaging deferred to v0.8.0
- `/add:init` SKILL.md now documents all four modes (default, `--quick`, `--reconfigure`, `--sync-registry`) in a mode-selection table up top

### Dog-food checkpoint

- `.add/retros/retro-2026-04-12-v07.md` — full retro covering the v0.6 → v0.7 arc. Scores: ADD methodology 5.8/9 (spec-before-code violated on arch extraction), Swarm effectiveness 8.1/9 (5-agent competing-swarm review was high-value).

## [0.7.0] — 2026-04-12

Multi-runtime architecture release. Extracts methodology content from a Claude-specific plugin layout into a runtime-neutral `core/` source with per-runtime adapters. Claude Code install is byte-identical to v0.6.0. Codex CLI is now a first-class target.

### Added

- **`core/`** source of truth — skills, rules, templates, knowledge, schemas, VERSION
- **`runtimes/claude/`** adapter (.claude-plugin, hooks, CLAUDE.md, adapter.yaml)
- **`runtimes/codex/`** adapter (adapter.yaml, concat + flatten strategy)
- **`scripts/compile.py`** — generator producing `plugins/add/` (Claude) and `dist/codex/` (Codex)
- **`scripts/install-codex.sh`** — one-line Codex CLI installer; copies prompts to `~/.codex/prompts/add-*.md` and shared content to `~/.codex/add/`
- **`scripts/validate-frontmatter.py`** — JSON Schema validation for SKILL.md and rule frontmatter
- **`core/VERSION`** — single source of truth for version across every surface (replaces the 8-location bump checklist)
- **`SECURITY.md`** — threat model, disclosure process, GPG-signed releases from v0.7.0+
- **`TROUBLESHOOTING.md`** — install failures, rule-loading verification, Codex-specific recovery
- **`docs/codex-install.md`** — Codex install + usage + known differences
- `core/schemas/skill-frontmatter.schema.json` — JSON Schema for `description`, `argument-hint`, `allowed-tools`, `disable-model-invocation`
- `core/schemas/rule-frontmatter.schema.json` — JSON Schema for `autoload`, `maturity`, `description`, `globs`
- `.github/workflows/compile-drift.yml` — fails PRs where committed artifacts don't match compile output
- `.github/workflows/schema-check.yml` — fails PRs with invalid frontmatter
- `.github/workflows/rule-boundary-check.yml` — flags PRs that weaken `NEVER`/`Boundaries:`/`MUST NOT` markers
- Codex support pages on getadd.dev with side-by-side Claude + Codex install

### Changed

- `hooks/hooks.json` rewritten to use the Anthropic-documented `jq` + stdin pattern instead of non-standard `$TOOL_INPUT_*` env var references
- `plugin.json` now includes `license: MIT` and a `keywords` array for marketplace discoverability
- Root `README.md` install section: two-step marketplace flow explained, Codex install block added, skill count corrected (24 total across 4 categories)
- `plugins/add/README.md` documents `argument-hint`, `allowed-tools`, `autoload`, `maturity` as ADD-specific frontmatter extensions (clear labeling vs Anthropic spec)

### Removed

- Broken root `AGENTS.md` — was a sed-mangled copy of `CLAUDE.md` referencing non-existent `.Codex-plugin/` paths; replaced by the real generated Codex adapter at `dist/codex/AGENTS.md`

### Architecture decision

This release is shaped by a 5-agent competing-swarm review: Anthropic spec compliance, install reliability/UX, Codex portability, multi-runtime architecture, and security/trust. Swarm 3's strategic reframe ("ADD is a methodology with runtime adapters, not a Claude plugin") + Swarm 4's directory proposal (`core/` + `runtimes/`) + Swarm 5's CI-enforced security + Swarms 1/2's specific fixes = this release.

## [0.6.0] — 2026-04-12

Community release. Merged three PRs from external contributors as-submitted, with acknowledgment and release-note credit. Added the compliance machinery surfaced by the agentVoice dog-food retro.

### Added — Community contributions

- **`/add:docs`** — Project-type-agnostic documentation skill (architecture diagrams, API/interface docs, README drift detection). Archetype detection from config or codebase inference. Thanks to [Caleb Dunn (@finish06)](https://github.com/finish06) (#2).
- **`/add:roadmap`, `/add:milestone`, `/add:promote`** — Milestone and maturity management surface. Interactive horizon management, tactical milestone ops (list/switch/split/rescope), evidence-based maturity promotion with 14-category gap analysis. Thanks to [Piotr Pawluk (@piotrpawluk)](https://github.com/piotrpawluk) (#3).
- **`/add:ux`** — Design sign-off gate before implementation. POC = nudge, Alpha+ = hard gate. Prevents rework from late-breaking design changes. Thanks to [David Giambarresi (@dgiambarresi)](https://github.com/dgiambarresi) (#4).

### Added — Compliance machinery

Driven by the agentVoice 40-day / 412-commit / 0-retro dog-food gap:

- `rules/add-compliance.md` — Retro cadence enforcement (blocks `/add:away`, `/add:cycle --plan`, `/add:back` when retro debt exceeds 7d / 3 aways / 15 learnings)
- `rules/registry-sync.md` — Detects drift between project ground truth and `~/.claude/add/projects/{name}.json`; auto-bumps on checkpoints
- `/add:retro` Phase 7 — Auto-proposes workstation promotion candidates in a single batch
- Spec template Section 9 — Infrastructure Prerequisites (env vars, registry images, quotas, network, CI, secrets, migrations)
- `knowledge/global.md` — Competing swarm pattern, infrastructure prerequisites checklist, E2E quality protocol (browser-only, never skip)

### Changed

- `/add:cycle` pre-flight now includes milestone health check and `--milestone` flag (from community PR #3)
- `/add:spec` nudges toward `/add:ux` for UI features (from community PR #4)
- `rules/maturity-loader.md` matrix: `registry-sync` active at all maturities, `add-compliance` active at alpha+

## [0.5.0] — 2026-04

Plugin isolation + interview safety nets release.

### Added

- Interview safety nets (thanks to Nick Barger):
  - Question Complexity Check — split questions that bundle 3+ decisions
  - Confusion Protocol — re-ask via `AskUserQuestion` after user confusion
  - Confirmation Gate — summarize answers before generating spec
  - Cross-Spec Consistency Check — scan existing specs before writing new
- Isolated plugin to `plugins/add/` for reliable marketplace install
- `specs/plugin-installation-reliability.md`

### Changed

- `marketplace.json` source path now points at `./plugins/add` (was `./`)
- `commands/` merged into `skills/` for Claude Code plugin loader compatibility

## [0.4.0] — 2026-02

Learning system + legacy adoption release.

### Added

- Structured JSON learning schema (`learnings.json` replaces freeform `.md` when migrations run)
- Cross-project learning library (`~/.claude/add/library.json`) with smart filtering pipeline (stack → category → severity → cap at 10)
- Dual-format pattern: JSON primary, markdown generated view regenerated from JSON
- Scope classification (project / workstation / universal)
- Version migration rule (auto-migrates stale projects on session start via `templates/migrations.json`)
- Retro template automation — context-aware review with pre-populated tables
- 3 scores per retro: human collab, ADD effectiveness, swarm effectiveness (0.0–9.0)
- Rate-limited meta questions (1x/day)

## [0.3.0] — 2026-02

Branding + automation release.

### Added

- `branding.json` schema and preset palettes
- `/add:brand` and `/add:brand-update` skills
- Image generation detection + auto-nudge when capable tools appear
- `/add:changelog` skill — generates/updates from conventional commits
- `/add:infographic` — SVG generation from PRD + config
- Session continuity (handoff.md auto-write after significant work)

## [0.2.0] — 2026-02

Adoption release.

### Added

- `/add:init --adopt` with legacy project auto-detection
- Cross-project persistence at `~/.claude/add/`
- Profile system (user preferences carry across projects)
- Maturity levels (poc / alpha / beta / ga) as a single master dial

## [0.1.0] — 2026-02-07

Initial release. Pure markdown/JSON plugin built in one session (36 files, ~6,300 lines). Core infrastructure:

- 6 commands: `/add:init`, `/add:spec`, `/add:away`, `/add:back`, `/add:retro`, `/add:cycle`
- 8 skills: `tdd-cycle`, `test-writer`, `implementer`, `reviewer`, `verify`, `plan`, `optimize`, `deploy`
- 10 rules: spec-driven, tdd-enforcement, human-collaboration, agent-coordination, source-control, environment-awareness, quality-gates, learning, project-structure, maturity-lifecycle
- 10 templates, 1 hooks file, 2 manifests
- Non-greenfield adoption flow designed from analysis of 9 real projects
- PRD written for the plugin itself (dog-fooding)

---

[Unreleased]: https://github.com/MountainUnicorn/add/compare/v0.7.3...HEAD
[0.7.3]: https://github.com/MountainUnicorn/add/releases/tag/v0.7.3
[0.7.2]: https://github.com/MountainUnicorn/add/releases/tag/v0.7.2
[0.7.1]: https://github.com/MountainUnicorn/add/releases/tag/v0.7.1
[0.7.0]: https://github.com/MountainUnicorn/add/releases/tag/v0.7.0
[0.6.0]: https://github.com/MountainUnicorn/add/releases/tag/v0.6.0
[0.5.0]: https://github.com/MountainUnicorn/add/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/MountainUnicorn/add/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/MountainUnicorn/add/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/MountainUnicorn/add/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/MountainUnicorn/add/releases/tag/v0.1.0

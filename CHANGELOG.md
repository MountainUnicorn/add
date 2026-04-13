# Changelog

All notable changes to ADD are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

For commit-level detail see `git log`.

## [Unreleased]

### Added

- `scripts/deploy-website.sh` — Actions-free website deploy. Syncs `website/` into the `gh-pages` branch and triggers a build via GitHub's legacy Jekyll pipeline (runs on a separate pool from user Actions, so it works even when account-level Actions is restricted). Supports `--dry-run` and `--no-build`.

Pending for v0.8.0:

- Per-skill Codex overrides for high-leak skills (`away`, `tdd-cycle`, `implementer`, `agent-coordination`)
- Marketplace re-submission to the official Claude Code registry
- `/add:cycle` rename to `/add:arc` (or similar) — 3 consecutive release arcs bypassed the command; gap needs addressing

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

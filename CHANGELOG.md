# Changelog

All notable changes to ADD are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

For commit-level detail see `git log`.

## [Unreleased]

### Changed

- **Marketing site extracted to a separate repo** ([`MountainUnicorn/getadd.dev`](https://github.com/MountainUnicorn/getadd.dev)) so future commercial elements can land there without touching the open-source plugin. Full git history (38 commits) preserved via `git filter-repo`. Domain `getadd.dev` re-claimed on the new repo with the existing TLS cert. The plugin repo no longer contains `website/`, `.github/workflows/pages.yml`, or `scripts/deploy-website.sh`. The architecture SVG used by the README moved from `website/images/` to `docs/`.
- `CLAUDE.md` rewritten to reflect the v0.7+ source-of-truth flow (`core/` → `compile.py` → `plugins/add/` + `dist/codex/`) and the website-is-elsewhere reality.
- `CONTRIBUTING.md` testing-changes section: replaced the long ad-hoc rsync example with the canonical `compile.py` + `sync-marketplace.sh` workflow plus the three CI-gate validation commands.
- `scripts/sync-marketplace.sh`: dropped the now-unnecessary `--exclude='website/'`.

### Planned for v0.9.0 — Pre-GA Hardening (M3 milestone)

Five parallel research swarms (Anthropic direction, Codex/OpenAI direction, IDE competitive landscape, AI dev framework trends, production AI engineering) converged on the v0.9.0 scope. Seven specs drafted and entering parallel development under [`docs/milestones/M3-pre-ga-hardening.md`](docs/milestones/M3-pre-ga-hardening.md). Total: 207 acceptance criteria across 7 Draft specs.

| Spec | Sizing | Cycle | Driver |
|------|--------|-------|--------|
| [`codex-native-skills`](specs/codex-native-skills.md) | Large | 2 | Codex shipped Skills/sub-agents/hooks; ADD compiles to deprecated path |
| [`prompt-injection-defense`](specs/prompt-injection-defense.md) | Medium | 2 | OWASP A01 + Comment-and-Control attack — GA blocker |
| [`secrets-handling`](specs/secrets-handling.md) | Small | 1 | GitGuardian: AI-tooled repos 40% more likely to leak — GA blocker |
| [`telemetry-jsonl`](specs/telemetry-jsonl.md) | Medium | 3 | OTel GenAI semconv stabilizing; EU AI Act Aug 2026; audit/cost attribution |
| [`test-deletion-guardrail`](specs/test-deletion-guardrail.md) | Medium | 3 | Kent Beck + TDAD paper: agents delete failing tests; defends signature TDD claim |
| [`cache-discipline`](specs/cache-discipline.md) | Small | 1 | Anthropic's 90% cache discount needs structural discipline; depends on PR #6 |
| [`agents-md-sync`](specs/agents-md-sync.md) | Small | 2 | AGENTS.md is now the cross-tool standard (Linux Foundation, 60k+ projects) |

Other v0.9.0 work tracked in M3:

- PR #6 merge (rules/knowledge on-demand loading from @tdmitruk) — foundation for cache-discipline
- Marketplace re-submission to the official Claude Code registry (parallel external work)
- Maturity promotion alpha → beta executed against the v0.9 release

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

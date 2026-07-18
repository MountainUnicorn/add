# Changelog

All notable changes to ADD are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

For commit-level detail see `git log`.

## [0.9.11] — 2026-07-16

Closes the stale-rules gap reported by Tomasz Dmitruk ([@tdmitruk](https://github.com/tdmitruk)): `/add:init` used to copy 10 ADD rules into the consumer project's `.claude/rules/`, where they auto-loaded forever at the version they were copied — never updated by plugin upgrades, and (since v0.9.9) duplicating and eventually contradicting the fresh rules the SessionStart hook injects. Copies also bypassed maturity gating entirely.

### Changed

- **Rule copying is retired.** The SessionStart hook (`load-rules.sh`) is the sole rule-distribution mechanism — always current with the installed plugin, maturity-gated, zero drift. `/add:init` Phase 2.5 no longer writes to `.claude/rules/`; it now only detects leftovers from older inits and offers a batched removal. The adoption-mode "Handling Existing Rules" flow likewise stops copying — user-authored rules are analyzed for overlap but never replaced by file copies.

### Added

- **Stale-copy warning** — `load-rules.sh` flags files in `.claude/rules/` matching plugin rule names (incl. `add-` prefixed) every session until they're removed, so the conflict is visible instead of silent (+2 loader tests).
- **Migration hop 0.9.10 → 0.9.11** with a new `remove_stale_rule_copies` action (defined in `version-migration.md`): lists matches, requires one explicit user confirmation, backs up before deleting, never touches user-authored rules.

## [0.9.10] — 2026-07-12

Dedup + hygiene release closing the three-release token-audit arc (v0.9.8 correctness → v0.9.9 token architecture → v0.9.10 slimming). The five heaviest skills lose ~35–45% of their lines to extraction; security patterns lose their false-positive noise; the hooks and CI lose their soft spots.

### Changed

- **Heavy skills slimmed** — init 1,093→638 lines, deploy 874→557, verify 761→432, cycle 659→462, docs 582→352. Illustrative panels, interview banks, worked examples, and inline templates moved to `templates/` (`init-interview`, `init-output-examples`, `commit-message`, `deploy-reference`, `cycle-plan`, `verify-report`) and `references/` (`docs-archetypes`). Instructions stayed inline; renderings load on demand.
- **Shared skill epilogue** — the Process Observation / Learning Checkpoint / handoff-preflight / Progress Tracking boilerplate duplicated across ~10 skills is now one reference (`references/skill-epilogue.md`) + a one-line pointer per skill. The secrets gate duplicated across deploy + verify is now `references/secrets-gate.md`. `dashboard` no longer inlines the design-system CSS it already references.
- **Version literals can't drift anymore** — all 27 skills now carry `[ADD v{{VERSION}}]` / `v{{VERSION}}` in source (23 said v0.6.0 while shipping v0.9.x); compile substitutes the real version.
- **Namespace fixes** — bare `/cycle`, `/milestone`, `/infographic` → `/add:*` (the bare forms train consumer sessions to suggest commands that don't exist).
- **post-write auto-fix is now opt-in** (`hooks.autofix`, default false) — linters advise on stderr instead of silently rewriting files mid-session.
- **CHANGELOG reminder moved to PreToolUse** — it now fires *before* `git push` (it fired after, when the advice was moot), and the push-detection regex no longer matches `echo "git push"` or `--help`/`--dry-run`.

### Fixed / Security

- **Injection-pattern noise reduction** — `ignore-previous` requires the noun (no longer fires on "ignore previous versions") and a real false negative on the canonical multi-word injection phrase was closed; `base64-blob-suspicious` downgraded to info at 120+ chars (SRI hashes/data URIs no longer trip it); `system-heading` anchored (a README's `## Instructions` is not an attack). +5 fixtures.
- **Audit-log redaction unified with the secret-patterns catalog** — excerpts written to `injection-events.jsonl` now mask everything `scan-secrets.sh` knows (Stripe `sk_live_`, `sk-ant-`, …), not just 5 hardcoded prefixes.
- **`PASSWORD_KV` made case-insensitive** (previously missed `PASSWORD=` / `Password:`); `.secretsignore` negation lines now warn loudly (they were silently ignored) and were removed from the shipped template.
- **CI**: marketplace-validate fails loudly when the CLI install fails (was skip-green); `hooks-json`, `load-rules`, and `compile` suites added to the guardrails matrix; rule-boundary-check counts inline NEVER/MUST-NOT markers.

### Project hygiene

- `.add/away-logs/` gitignored + untracked (per ADD's own project-structure rule); legacy `learnings.md.bak` removed; 25 stale learnings archived to `learnings-archive.json` (49→24 active); wave3 A1 draft marked APPLIED-historical.
- Visual/community surfaces refreshed: infographic + HTML overview gained the token-economy story; CONTRIBUTING gained a Token Discipline section; issue templates + PR checklist updated.

## [0.9.9] — 2026-07-12

The token-architecture release. Frontier models are priced for judgment, not boilerplate — this release makes the maturity dial a *token* dial and gives ADD's dispatch machinery its missing cost policy.

### Added

- **Maturity-aware physical rule loading.** New SessionStart hook (`hooks/load-rules.sh`) reads `.add/config.json` → `maturity.level` and injects only rules whose `maturity:` gate is at/below the project level. Previously all 20 rules were statically `@`-imported (~17.8k tokens every session) and the maturity-loader could only suppress *behavior* — a POC project paid ~13k tokens for rules it was told to ignore. Now dormant rules cost zero tokens (POC sessions: ~70% rule-token reduction). Fail-open to the full set when `.add/config.json` is absent/unparseable (behavior parity). CLAUDE.md carries a names-only rule index + fallback protocol; `maturity-loader.md` rewritten (the hardcoded 19-row matrix is gone — rule frontmatter is the single source of truth). Fixture-tested at `tests/hooks/test-load-rules.sh`; `tests/rule-parity/` rewritten for the new mechanism.
- **MODEL + BUDGET cost policy for sub-agent dispatch.** `swarm-protocol.md` gains a maturity-scaled Resource Budgets table (poc ~30k tokens/item → ga ~200k + adversarial verify; overridable via `.add/config.json` → `swarm.budgets`), role→tier defaults (test-writer/implementer/verify = editor, reviewer = architect, explorer/mechanical generation = fast), and MODEL/BUDGET fields in the Sub-Agent Brief Template. `tdd-cycle` dispatch prompts carry per-role tiers; `dashboard`/`infographic`/`docs` note that bulk rendering belongs on the fast tier. `model-roles.md` adds token-budget escalation (start cheap, escalate on verification failure).
- **Size-capped learnings view.** `filter-learnings.sh` now enforces `learnings.active_char_budget` (default 6000 chars) with a 400-char per-entry cap; overflow entries demote to the one-line index. The active view is read before every skill — it can no longer grow unbounded.
- New on-demand references: `telemetry-reference.md`, `maturity-matrix.md` (cascade matrix + promotion process).

### Changed

- **`telemetry`, `cache-discipline`, `model-roles` rules flipped to `autoload: false`** (write-side/orchestration-only — loaded via skill `references:` when needed). `learning` trimmed 995→464 words and `maturity-lifecycle` 1202→463 (procedural content moved to references). Always-on rule surface: 17 rules, ~6k tokens lighter per session before maturity gating.
- **CLAUDE.md trimmed**: 27-row skills table replaced with the workflow chain (Claude Code already surfaces skill descriptions); Document + Work hierarchies merged into one diagram.
- **`count-tokens.py` de-drifted** — the autoload set is now derived from rule frontmatter (was a stale hardcoded 15-rule list that under-reported by ~5k tokens and misattributed knowledge files); knowledge/references/on-demand rules now report in a separate on-demand section.

## [0.9.8] — 2026-07-12

P0 correctness patch from a full token-sensitivity audit (four parallel deep-dives across rules, skills, the Codex runtime, and the operational machinery). Fixes cross-runtime divergence and fail-open security behavior; opens the three-release path to v1.0 (v0.9.9 token architecture, v0.9.10 dedup + hygiene).

### Fixed

- **Codex substitution leaks.** The compiler applied `codex_substitute` only to skill bodies and references — `rules/`, `knowledge/`, `templates/`, `security/`, `lib/` docs and agent TOMLs shipped with raw `${CLAUDE_PLUGIN_ROOT}` paths and **286 `/add:` Claude-namespace command references** (Codex commands are `/add-<name>`). `copy_tree` now takes a transform; a `/add:` → `/add-` substitution rule was added; `.template`/`.toml` files joined the substitution set; `handoff-detect.sh` messages corrected at source. `scan-secrets.sh` additionally resolves its catalog at `~/.codex/add/security/` when env/script-relative resolution misses.
- **Claude/Codex autoload divergence.** The Claude `@rules` list included a rule unless `autoload: false`; the Codex AGENTS.md invariants required `autoload: true` — `design-system.md` (no key) autoloaded on Claude but was missing from Codex invariants. Both runtimes now share one `rule_autoloads()` predicate, and **every rule must declare `autoload:` explicitly** (compile hard-fails otherwise).
- **Critical injection detector failed open.** Hex-escape patterns (incl. the `critical` `unicode-tag-block` invisible-injection detector) silently no-op'd when `python3` was absent. The scanner now emits an `ADD-SEC … action=skipped-no-python3` warning and a `skipped:"no-python3"` audit event.
- **`compile.py --check` could false-pass on a pre-drifted tree** (it compared before-vs-after `git status --porcelain` strings, identical either way). Now snapshots the output dirs and content-diffs after recompile — git-independent, works uncommitted.
- **Codex sessions never saw `knowledge/global.md`.** `adapter.yaml` claimed AGENTS.md was built from it, but the compiler never read it. The slim manifest now carries the read-before-work pointer to Tier-1 global learnings + `.add/learnings-active.md`.

### Changed

- **`adapter.yaml` truth-pass.** The `limitations` section previously described an injection-scan hook writing audit events on Codex — no such hook ships. It now states plainly: injection defense on Codex is **advisory-only** (no scanner hook, no audit events; parity targeted at v1.0), `filter-learnings.sh` ships but is not auto-registered, and hook stderr is not surfaced. `output_shape` now documents all real emit targets (`rules/`, `knowledge/`, `lib/`, `security/`); the false `rules.strip` frontmatter claim replaced with `preserve: true` (the maturity-loader reads rule `maturity:` keys at runtime).

## [0.9.7] — 2026-06-18

Methodology reframe + a security trust signal. Positions ADD as the policy layer over native orchestration, leads with the maturity-ladder moat, and dogfoods the injection defense.

### Changed

- **Swarm protocol reframed as policy over native Workflows.** `core/references/swarm-protocol.md` and `core/rules/agent-coordination.md` now draw a clear policy/mechanism line: ADD owns the *policy* (maturity-aware WIP/concurrency, conflict assessment, role briefs, merge ordering, trust-but-verify gates, swarm-state), and delegates the orchestration *mechanism* (parallel dispatch, worktree isolation, step schemas, budgets) to the runtime — native Claude Dynamic Workflows / Codex TOML sub-agents — with the manual recipes retained as the fallback. Positioning: "ADD configures native orchestration with maturity-aware policy," not "ADD re-implements orchestration." WIP semantics (poc=1…ga=5) and trust-but-verify are invariant; actual Workflow-descriptor emission is deferred to v1.1.
- **README leads with the maturity ladder.** The hero is now the poc→alpha→beta→ga trust-gradient dial ("One dial scales the rigor") — the moat host runtimes haven't absorbed — with the prior framing kept as a secondary line.

### Added

- **Skill self-scan (`scripts/self-scan-skills.py`).** Runs ADD's distributed injection patterns (`core/security/patterns.json`) against ADD's own shipped artifacts on every CI run (the `skill-self-scan` guardrail), using the same detection engine as the runtime hook. Fails the build on any un-waived `critical`/`high` match and surfaces malformed patterns loudly so a pattern can't silently stop gating. Documented as a trust signal in SECURITY.md; guarded by `tests/security/test-self-scan.sh` (mutation-verified).
- **Swarm-state format contract.** A machine-readable contract for `.add/swarm-state.md` (entry delimiter, field table, status enum, forward-compatible parsing) so humans, the orchestrator, and native-Workflow state all parse it the same way.
- **`runtimes/claude/workflows/` scaffold** + `specs/workflow-lifecycle-scripts.md` (Draft) — the planned home for native Workflow lifecycle scripts. Inert in v0.9.7 (zero behavior change); pilot lands in v1.1.

### Changed (project governance)

- **GA gate updated:** the arbitrary 60-day beta calendar floor is dropped; v1.0 now gates on Anthropic marketplace approval plus the substantive promotion criteria (roadmap D7 override). See `docs/v1.0-roadmap.md` and `docs/milestones/v1.0-ga.md`.

## [0.9.6] — 2026-06-14

CI/release hardening + truth-pass, opening the v1.0 credibility cycle. Turns a red `main` green, makes the release tool trustworthy, and fixes a real injection-defense bug surfaced during the pass.

### Fixed

- **CI unblocked (C1).** `core/rules/` holds 20 rules but the tree diagram hardcoded 19, failing the `rule-parity` guardrail on `main`. The count is now **compile-derived** — `runtimes/claude/CLAUDE.md` carries a `{{RULE_COUNT}}` placeholder that `scripts/compile.py` fills from the live autoload-rule set, so it can't drift by hand again. `rule-parity` was strengthened to read the compiled artifact and to assert the count in every prose surface (CLAUDE.md, README.md, CONTRIBUTING.md).
- **`release.sh` could publish nothing and still exit 0 (C2, closes #18).** The signed tag pushed but `gh release create` could be skipped silently. The script now builds its flags as an array and **verifies the release page exists** via `gh release view` after creating it, failing loudly with a recovery command. Same failure class as F-001 — a command that "succeeds" without doing the thing.
- **Injection-defense false positives (D3).** The `unicode-tag-block` pattern was a malformed byte character-class whose range matched almost any multibyte UTF-8 — em-dashes, arrows, box-drawing characters all tripped a `critical` event (~100% false-positive rate; 0 real attacks in the audit trail). Replaced with a precise pattern matching exactly U+E0000–U+E007F; verified the real tag-channel attack fixture still fires. The JSONL audit writer now emits compact single-line records (`jq -cn`) so concurrent hook runs can't corrupt the file.

### Changed

- **CI actions bumped to Node-24 runtimes (C3)** across all four workflows: `actions/checkout` v4→v5, `actions/setup-python` v5→v6, `actions/github-script` v7→v8.
- **`model-roles` rule (D1)** gained a capability-tier table mapping role shapes to the current lineup — Architect: Opus 4.8 / gpt-5.5; Editor: Sonnet 4.6 / gpt-5.x-codex; Fast: Haiku 4.5 / gpt-5.x-codex-mini — while keeping the guidance-not-enforcement framing.
- **CONTRIBUTING (C5)** now lists all four CI workflows (was "three checks") and documents the community-PR strategy (merge-as-is + co-authored refactor follow-up).
- **Audit-trail hygiene (D3).** `.add/security/` is now gitignored and untracked; the local-only injection audit trail is documented in SECURITY.md's threat model.

### Added

- **Codex `verify` sub-agent (B3).** ADD's 4th role was missing from the Codex adapter — added `runtimes/codex/agents/verify.toml` (workspace-write, high reasoning) and the two `compile.py` enumerations that omitted it. The Codex adapter now emits five sub-agents.
- **`tests/release-tooling/test-release-verify.sh`** — behavioral regression guard for #18 (mocks git/gh/python3, asserts the script exits non-zero when no release page exists), registered in the guardrail matrix.
- **`tests/security/fixtures/benign-multibyte.json`** — regression guard for the unicode-tag-block false-positive bug; asserts dense benign multibyte content does not fire (mutation-verified to go red against the old regex).

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

**Pending for v0.10.0 — "install path confirmed" GA release candidate** (spec: `specs/install-path-confirmation.md`; sequencing: smoke green → marketplace submission → v1.0.0 promotion tag on approval).

### Added

- **Real install smoke in CI (GA criterion #2).** `.github/workflows/install-smoke-claude.yml` — installs the checkout via the actual marketplace path (`claude plugin marketplace add` + `claude plugin install add@add-marketplace`), asserts skill discovery, and drives a headless `/add:init --quick` asserting `.add/config.json` (agent leg skips loudly without `ANTHROPIC_API_KEY`). `.github/workflows/install-smoke-codex.yml` + `tests/smoke/codex/` — Docker image with the Codex CLI pinned from `runtimes/codex/adapter.yaml` (single source of truth via build-arg), runs `scripts/install-codex.sh` for real, asserts 27/27 skills, hooks, shared assets, version parity, the F-002 path suite, and (with `OPENAI_API_KEY`) an agent-driven `/add-init`.
- **`docs/capability-matrix.md` (GA criterion #3 / AC-027).** Per-runtime enforced vs agent-followed vs advisory truth table, appended to every release's notes by `release.sh`; `SECURITY.md` now points at it before the threat model.
- **`scripts/release-evidence.sh` (GA criterion #4 / AC-025).** Assembles `reports/release-evidence/vX.Y.Z/` — version map, capability-matrix snapshot, command catalog, install-smoke run links, and a migration-graph reachability check; `--upload` attaches the bundle to the GitHub release.

### Changed

- **Codex CLI re-pinned 0.122.0 → 0.144.5** (`codex_cli_version`; `min_codex_version` stays 0.122.0). Install smoke verified green in Docker against the new pin (Q-001 re-baseline).
- **`release.sh` is now release-blocking (GA criterion #1).** Refuses to tag unless HEAD is on origin/main with all CI check-runs green; `--no-verify-ci` is the loud emergency override.

### Fixed

- **`migrations.json`: v0.7.3 users were stranded** — no outgoing hop existed from 0.7.3 (same class as the v0.8.1→v0.9.3 chain break). Caught by the new reachability check; fixed with a 0.7.3→0.8.0 hop carrying the standard 0.8.0 steps.

### Known limitations

- **Telemetry emission confirmed absent (Q-MS-003/D6).** `.add/telemetry/` never populates — the spec exists, no hook writes it. Recorded as a finding; implementation deferred past v0.10.0 (does not gate the six GA criteria).

## [0.9.5] — 2026-04-22

**Hygiene + truth pass.** Doc-only release. Removes the smokescreen between what the docs claim and what's actually shipped, so the v1.0 credibility cycle (v0.9.6 → v1.0.0) starts from honest ground. No consumer config or plugin-runtime changes.

### Changed

- **Spec/plan frontmatter sweep.** Ten specs flipped from `Draft`/`Implementing` to `Complete` with `Shipped-In: vX.Y.Z` recorded: `agents-md-sync`, `cache-discipline`, `prompt-injection-defense`, `secrets-handling`, `telemetry-jsonl`, `test-deletion-guardrail`, `codex-native-skills` (all v0.9.0); `jq-dependency-declaration`, `secrets-scanner-executable` (v0.9.3); `project-dashboard` (v0.3.0). Eighteen plan files in `docs/plans/` got `> Status: Complete (vX.Y.Z) — superseded by shipped feature.` close-out headers. `specs/timeline-events.md` marked `Superseded` (replaced by telemetry-jsonl + dashboard).
- **PRD refresh.** `docs/prd.md` header bumped to v0.9.5 / 2026-04-22. § 4 v1.0 reframed to point at `docs/milestones/v1.0-ga.md` (canonical) and `docs/v1.0-roadmap.md` (synthesis), with the 6 reworded GA criteria from `.add/config.json:next_promotion_criteria` listed inline. § 3 metrics qualified — telemetry-derived measurements depend on dog-food emission verification (v0.9.7 milestone).
- **Maturity cascade matrix.** `core/rules/maturity-loader.md` updated for the four v0.9.0-shipped rules: `secrets-handling` (alpha+ active), `cache-discipline`, `injection-defense`, `telemetry` (beta+ active).
- **README + CLAUDE.md counts.** README rules count corrected to 19 (was 11). CLAUDE.md, runtimes/claude/CLAUDE.md, CONTRIBUTING.md repository-structure blocks updated to include `core/lib/`, `core/security/`, `core/references/`, `core/schemas/` and current template/knowledge counts.
- **README intro.** Lead paragraph reframed methodology-first ("ADD is a methodology"); the Claude/Codex plugin is the canonical implementation. Seed for the D5 brand-split direction (methodology authoritative at `docs/methodology.md` mirror, plugin as one runtime).
- **Roadmap section.** README's stale "v0.4.0 — Next" historic block replaced with a one-line pointer to `docs/v1.0-roadmap.md` and `CHANGELOG.md`.

### Added

- **`core/rules/model-roles.md`** — Architect / Editor model-role guidance. One-paragraph rule distinguishing planning-shaped work (Opus, spec authoring, decision walkthroughs) from mechanical-shaped work (Sonnet/Haiku, file rewrites, frontmatter sweeps). Guidance, not enforcement; ties back to `agent-coordination.md` for swarm dispatch. M3 deferral closed.
- **`docs/milestones/v1.0-ga.md`** — Canonical v1.0 milestone document. Goal, driving context, the 6 reworded success criteria, 8–10 week appetite, hill chart, per-release feature detail (v0.9.5 → v1.0.0), parallelism analysis, risks register, out-of-scope list, open questions, validation gates per release.
- **`docs/v1.0-roadmap.md`** — Synthesis of three parallel v1.0 research swarms (current state, unimplemented inventory, market review). Six-release path, capability-family architecture, four moats, four abandon recommendations, eight risks, decisions D1–D7 locked.

### Retargeted

- **`specs/plugin-family-release-hardening.md`** — F-006 (host-neutral kernel) and F-007 (adapter contracts) target moved from `v1.0.0` to `v1.1.0`. Acceptance criteria AC-010/AC-011/AC-012 retagged to `v1.1.0` to match. Per D2 lock in `docs/v1.0-roadmap.md`: full architectural close is M4 work; v0.9.7 will ship Tier 1 substitution-only fix (~80% of leak) for v1.0 GA.

### Maturity criteria reworded

- `.add/config.json:next_promotion_criteria` updated per D1 lock. The 60-day calendar floor — generic, not project-shaped — is replaced by engineering evidence: ≥3 minor/patch releases past v0.9.0 with no post-tag rollback, ≥1 community PR merged during the beta cycle, AC-025 release-evidence bundle generated for the v1.0 candidate. Criterion 6 ("verified in active use") rewords the unmeasurable "20+ projects" claim to maintainer attestation via private signal — adopter naming only with explicit consent. See `docs/v1.0-roadmap.md` § D1 for rationale.

## [0.9.4] — 2026-04-27

**Hotfix.** Completes the migration chain from v0.8.0 onward. Surfaced when a project at v0.5.0 updated to v0.9.3 and Claude Code reported: _"Plugin manifest covers up to 0.8.0; plugin is now 0.9.3 … no 0.8 → 0.9 hop exists."_ The version field on the consumer's `.add/config.json` was bumping past 0.8.0 without any migration hop being traversed — a silent gap that's harmless today (v0.8 → v0.9.x had no required config-schema changes) but would silently skip future migrations that DO have steps.

### Fixed

- **`core/templates/migrations.json`** — manifest's `plugin_version` field advanced from 0.8.0 to 0.9.4. Six new hops added: `0.8.0 → 0.8.1`, `0.8.1 → 0.9.0`, `0.9.0 → 0.9.1`, `0.9.1 → 0.9.2`, `0.9.2 → 0.9.3`, `0.9.3 → 0.9.4` (sequential), plus a `0.8.0 → 0.9.3` skip hop so consumers on v0.8.0 jump straight to current. All hops are no-op (`steps: []`) since v0.8 → v0.9.x changes were plugin-internal — rules, skills, scripts, and hooks flow through `claude plugin update` automatically. The hops exist so the runner can traverse the chain without "no path found" gaps.

### Process learning

The version-bump checklist in maintainer memory now includes `core/templates/migrations.json` as a step. Across v0.8.1, v0.9.0, v0.9.1, v0.9.2, and v0.9.3 the manifest was not advanced; this release patches all five at once. Future releases must add a migration entry (even an empty one) when bumping `core/VERSION`.

## [0.9.3] — 2026-04-26

**v0.9.x polish bundle.** Closes the three plugin-family-review follow-ups that landed as drafts on 2026-04-26 (F-013, F-014, F-017) plus the lessons from a cross-OS portability bug caught in the secrets-scanner CI gate. All three features ship in one signed release rather than three back-to-back tags.

### Changed

- **`jq` declared as a documented runtime dependency (F-017).** The "zero runtime dependencies" claim in `README.md`, `CONTRIBUTING.md`, `docs/prd.md`, and `.claude-plugin/marketplace.json` was technically inaccurate — runtime hook scripts shipped since v0.7 invoke `jq`. Each of those four prose sites is now qualified ("zero agent-side runtime dependencies; `jq` required for hook scripts") and links to a new canonical reference doc. Hook code is unchanged — Strategy A from [`specs/jq-dependency-declaration.md`](specs/jq-dependency-declaration.md). Historical text in `docs/milestones/`, prior `CHANGELOG.md` entries, and earlier specs is preserved untouched.
- **Telemetry per-skill reference sweep (F-013).** Every `core/skills/*/SKILL.md` now declares `rules/telemetry.md` in its `references:` frontmatter array via the PR #6 mechanism (Path A). Closes Swarm F's M3-deferred sweep — the contract in `core/rules/telemetry.md` is now discoverable from any individual SKILL.md, and `tests/telemetry-sweep/test-skill-reference-coverage.sh` gates against future skills shipping without the reference. 17 skills got a fresh `references:` entry; 10 skills (cycle, verify, deploy, docs, retro, tdd-cycle, infographic, dashboard, brand-update, ux) had `rules/telemetry.md` appended to existing lists. No body changes; no behavior changes; no schema changes. Spec: `specs/telemetry-skill-reference-sweep.md`.

### Added

- **F-014 — executable secrets scanner.** Closes the v0.9.0 declarative-gate gap (`specs/secrets-scanner-executable.md`). Adds:
  - **`core/lib/scan-secrets.sh`** — POSIX-shell scanner. No `jq` in the hot path. Reads `git diff --cached` (or `--paths`/`--all`), respects `.secretsignore`, honors `[ADD-SECRET-OVERRIDE: SEC-NNN (reason)]` commit-message trailers, redacts every preview, exits non-zero on any unsuppressed match. Performance budget: < 2s on a 1k-file diff (1k clean files complete in ~4s on a 2024 laptop; the spec target is < 2s — sub-second on Linux CI).
  - **`core/security/secret-patterns.json`** — executable catalog. 8 patterns (AWS, GitHub, Stripe, OpenAI, Anthropic, JWT, password-KV, PEM private key). Mirror of `core/knowledge/secret-patterns.md` § 1; drift fails CI.
  - **`scripts/validate-secret-patterns.py`** — drift checker. Wired into `.github/workflows/guardrails.yml`.
  - **Gate 4.6 in `/add:verify`** — staged-secret scan. Always runs at `--level deploy`.
  - **Step 1.5 of `/add:deploy`** — rewrites the previously-prose secrets gate to invoke `scan-secrets.sh`. The interactive `--allow-secret` confirm-phrase wrapper is preserved.
  - **Advisory `PreToolUse` hook on `Bash` matching `git push`** — runs the scanner and emits findings to stderr without blocking. Hard-block deferred to v0.10 pending F-012 hook-feedback semantics.
  - **`tests/secrets-scanner-executable/`** — fixture suite with synth-at-runtime placeholders (mirrors v0.9.0's GitHub-Advanced-Security-safe pattern). 23 test cases covering exit codes, redaction integrity, override trailers, binary skipping, sorted output, perf budget.
- **`docs/runtime-dependencies.md`** — canonical reference for runtime dependencies. Documents `jq`'s role across the six hook invocation sites, install commands for macOS, Debian/Ubuntu, Fedora/RHEL, Arch, Alpine, openSUSE, Windows (Chocolatey + scoop + WSL), and Nix, the verification one-liner, and the per-site degradation behavior when `jq` is absent (2 hard-fail sites, 3 soft-fail sites).
- **`tests/jq-dependency/test-jq-claim-qualified.sh`** — fixture-based regression guard. Greps the four in-scope prose files for the bare claim, asserts `docs/runtime-dependencies.md` exists and is referenced from each claim site, and verifies historical text was preserved untouched.
- **`tests/telemetry-sweep/test-skill-reference-coverage.sh`** — gates against future skills shipping without the `rules/telemetry.md` reference.
- **Dependency-claim guard** in `.github/workflows/guardrails.yml` — runs the new test on every PR / `main` push so the bare phrasing cannot regress silently.

## [0.9.2] — 2026-04-26

**Community release.** Ships [@tdmitruk](https://github.com/tdmitruk)'s third merged contribution ([PR #6](https://github.com/MountainUnicorn/add/pull/6)) — the on-demand rule/knowledge loading mechanism that's been pending since 2026-04-14 across two rounds of review and two rebase cycles. Tomasz's third release.

### Added

- **On-demand rule/knowledge loading mechanism** ([PR #6](https://github.com/MountainUnicorn/add/pull/6)) — formalizes lazy-loading of rule and knowledge content as a compile-time mechanism, not just a documented convention. Three coordinated pieces:
  - **`autoload: false` rule frontmatter** — opts a rule out of Claude's `@rules/` autoload manifest. Schema enforced by `core/schemas/rule-frontmatter.schema.json`. Compile-time filter via `scripts/compile.py::autoload_rules_block` skips these rules from the substituted `{{AUTOLOAD_RULES}}` placeholder in `runtimes/claude/CLAUDE.md`. The rule still ships to `plugins/add/rules/` and `dist/codex/rules/`; it just doesn't autoload.
  - **`references: []` array in skill + rule frontmatter** — declarative way for a skill to point at on-demand content (typically rule files or knowledge files) that it Reads at runtime when needed. Schema validates the array shape.
  - **`core/references/` directory** — five canonical reference files extracted from previously-verbose autoload rules: `learning-reference.md` (JSON schemas + checkpoint templates + PII regex + migration protocol from `learning.md`), `design-system.md`, `image-gen-detection.md`, `quality-checks-matrix.md`, `swarm-protocol.md`. Skills Read these via `${CLAUDE_PLUGIN_ROOT}/references/...` (Claude) or `~/.codex/add/references/...` (Codex).
- **`{{AUTOLOAD_RULES}}` placeholder substitution** in `runtimes/claude/CLAUDE.md` — the literal `@rules/X.md` list is now generated by the build, not hand-maintained. Adding a new rule with `autoload: true` (the default) automatically appears in the manifest; flipping it to `autoload: false` automatically removes it.
- **Codex parity** — `runtimes/codex/adapter.yaml` gains a `references:` `output_shape` block; `core/references/` ships verbatim to `dist/codex/references/` with `${CLAUDE_PLUGIN_ROOT}` rewritten to `~/.codex/add` via `codex_substitute`. Token savings symmetric across runtimes.
- **`scripts/count-tokens.py`** — main-vs-working-tree diff of autoload manifest token cost. Built into the PR for post-rebase verification; ships in the release for users tracking their own context budgets.
- **10 skills declare `references:` frontmatter** — `cycle`, `verify`, `deploy`, `docs`, `retro`, `tdd-cycle`, `infographic`, `dashboard`, `brand-update`, `ux`. Each Reads the specific reference files it needs from `${CLAUDE_PLUGIN_ROOT}/references/...` instead of relying on always-autoloaded rule content.

### Changed

- **`runtimes/claude/CLAUDE.md`** — the literal `@rules/*.md` list replaced by a single `{{AUTOLOAD_RULES}}` placeholder. Documentation paragraph above the placeholder explains the on-demand mechanism for contributors. The `tests/rule-parity/test-rule-parity.sh` regression test (added in v0.9.1) was rewritten in this release to validate the placeholder mechanism: source uses placeholder ✓, compiled CLAUDE.md has `@rules/` for every `autoload: true` rule ✓, no `autoload: false` rules leak into the manifest ✓.
- **`core/rules/learning.md`** — condensed to the active-loop guidance the agent needs at session start; verbose JSON schemas, checkpoint templates, PII regex catalog, and migration protocol moved to `core/references/learning-reference.md` (loaded on demand by the skills that write learning entries).
- **`core/rules/human-collaboration.md`** — NEVER markers and Confusion Protocol sections restored after the prior condensation pass dropped them. Boundary strength preserved, body still condensed.
- **`scripts/compile.py`** — adds `parse_frontmatter` and `autoload_rules_block` helpers (line-based YAML to avoid a PyYAML dependency); rewrites `compile_claude` to apply `{{AUTOLOAD_RULES}}` substitution; adds `references` to the source-name tuple for both Claude and Codex outputs; adds step `6d.` shipping `core/references/` into `dist/codex/references/` with `codex_substitute` rewriting paths.
- **`scripts/install-codex.sh`** — `references` added to the shared-asset loop alongside `templates`/`knowledge`/`rules`/`lib`/`security`. Installer now stages all six trees under `$CODEX_HOME/add/`.
- **`runtimes/codex/adapter.yaml`** — `references:` `output_shape` block added; `agents_md` shape gains `filter: "autoload != false"` annotation for documentation parity (the slim-manifest strategy doesn't currently inline rules; the filter exists for future inline modes).

### Maintenance + safety

- **`tests/rule-parity/test-rule-parity.sh`** rewritten in v0.9.1 prior to this release; the new mechanism is covered by 5 assertions including the `autoload: false` leak check.
- **All 15 CI checks green** at the rebased SHA `e6a7b9f` (drift, validate, frontmatter, boundary, cache-discipline strict, all 9 fixture suites, marketplace manifest).
- **PR review process:** two rounds of structural review + two rebase cycles. The first review flagged six issues (wrong layer, missing on-demand mechanism, NEVER deletions, skill-side audit gaps, Codex parity, caching/latency notes); Tomasz's response split the work into seven traceable commits, one per review point, mapping each to a verifiable change. The second rebase merged across the v0.8.1 → v0.9.0 → v0.9.1 arc that landed on `main` while #6 was being reviewed.
- **Three community-driven releases in a row** — v0.7 (4 contributors), v0.8 (@tdmitruk's first), v0.9.2 (@tdmitruk's third).

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

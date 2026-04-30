# Swarm 1 — Current State Review for v1.0 Roadmap

**Perspective:** What does ADD ship today (v0.9.4 beta), where does it stand against PRD success metrics, and what's actually load-bearing missing for a credible v1.0 tag?
**Author:** Swarm 1 (current-state)
**Date:** 2026-04-22
**Companion swarms:** Swarm 2 (unimplemented specs / forward roadmap), Swarm 3 (market + competitive context)

---

## Executive Summary

ADD at v0.9.4 is a substantially more credible product than the PRD § 4 v1.0.0 description implies — but it ships against an outdated roadmap and a stale public surface, and several v0.9.x release-note claims are partially inert in real use. The methodology surface (27 skills, 19 rules, 23 templates, 5 references, two runtimes) is broad and internally coherent. The CI safety net (15 jobs, ~93 fixture tests across 11 suites, GPG-signed releases, compile-drift gating) is strong for a pure-markdown plugin. The maturity machinery dog-foods itself: ADD declared `beta` on 2026-04-23 with a documented 6-criterion next-promotion gate, of which only ~1.5 are met today.

The honesty audit is the most important finding. README says "11 auto-loaded behavioral rules" (actual: 18+1 unmarked = 19), the PRD's roadmap section names v0.4.0 as "Next" (we are at v0.9.4), `getadd.dev` footer says v0.9.1, and `core/rules/maturity-loader.md` cascade matrix omits four rules shipped in v0.9.0 (`cache-discipline`, `injection-defense`, `secrets-handling`, `telemetry`). Telemetry shipped a contract in v0.9.0 but the per-skill emission sweep only landed in v0.9.3; secrets-handling shipped declarative in v0.9.0 with the executable scanner only landing in v0.9.3 (F-014); marketplace install is plausible but has zero CI smoke. ADD is the most credible it's ever been, and also the most quietly drift-prone it's ever been. v1.0 needs a doc-truth pass before it needs new features.

---

## A. What We Ship Today (Factual Inventory)

Counts taken from the worktree at `/Users/abrooke/projects/add/.claude/worktrees/agent-a4c1690d/` against `core/VERSION = 0.9.4`.

### Source-of-truth (`core/`)

| Surface | Count | Notes |
|---|---|---|
| Skills (`core/skills/`) | **27** | All slash commands. CLAUDE.md tree diagram says 27 (correct); README "Commands & Skills" disclosure says "27 total (v0.9.1)" (count correct, version stale); README "Rules" disclosure header says "11 auto-loaded" (actual 18+1, see below). |
| Rules (`core/rules/`) | **19** | 18 explicitly `autoload: true`, 1 unmarked (`design-system.md`, defaults to true → effectively all 19 autoload at GA per matrix; gated by maturity-loader). CLAUDE.md tree says 19 (correct). |
| Templates (`core/templates/`) | **23** | CLAUDE.md says 21 (off by 2 — `decisions.md` and `presets.json`/`migrations.json`/`swarm-state.md` may not be counted in original tally). |
| Knowledge (`core/knowledge/`) | **5 files** | `global.md`, `image-gen-detection.md`, `secret-patterns.md`, `test-discovery-patterns.json`, `threat-model.md`. CLAUDE.md says "2 Tier-1 knowledge files" — stale (was 2 at v0.7, now 5). |
| Schemas (`core/schemas/`) | **2** | `rule-frontmatter.schema.json`, `skill-frontmatter.schema.json`. |
| References (`core/references/`) | **5** | New in v0.9.2 (PR #6 on-demand loading): `design-system.md`, `image-gen-detection.md`, `learning-reference.md`, `quality-checks-matrix.md`, `swarm-protocol.md`. CLAUDE.md tree diagram does not list this directory. |
| Lib (`core/lib/`) | **2** | `scan-secrets.sh` (v0.9.3 F-014), `impact-hint.sh` (v0.9.0 test-deletion-guardrail). CLAUDE.md tree does not list. |
| Security (`core/security/`) | **2** | `patterns.json` (injection-defense), `secret-patterns.json` (executable scanner mirror). |
| `core/VERSION` | `0.9.4` | Canonical. |

### Hooks

| Runtime | Location | Files |
|---|---|---|
| Claude | `runtimes/claude/hooks/` | `hooks.json`, `post-write.sh` (PostToolUse dispatcher: ruff/eslint/learnings-filter/agents-md-stale), `posttooluse-scan.sh` (injection scanner), `filter-learnings.sh`. **4 files**. |
| Codex | `runtimes/codex/hooks/` | `handoff-detect.sh`, `load-handoff.sh`, `write-handoff.sh`, `README.md`. **3 active scripts** + README. Note: Codex stderr does not surface to agent (documented limitation), so the injection scanner is Claude-only in practice. |

### Scripts

10 scripts under `scripts/`: `compile.py`, `release.sh`, `sync-marketplace.sh`, `install-codex.sh`, `validate-frontmatter.py`, `validate-cache-discipline.py`, `validate-secret-patterns.py`, `check-test-count.py`, `count-tokens.py`, `generate-agents-md.py`.

### Tests

15 test directories under `tests/`. The fixture-based suites that gate CI:

```
tests/
├── agents-md-sync/         (v0.9.0)
├── cache-discipline/        (v0.9.0)
├── codex-install/           (v0.8.1, F-002 regression smoke)
├── codex-native-skills/     (v0.9.0)
├── compile/                 (compile-drift)
├── hooks/                   (filter-learnings, v0.8.0)
├── jq-dependency/           (v0.9.3, F-017)
├── rule-parity/             (v0.9.1, F-011)
├── secrets-handling/        (v0.9.0 declarative)
├── secrets-scanner-executable/  (v0.9.3, F-014)
├── security/                (v0.9.0 prompt-injection)
├── telemetry-jsonl/         (v0.9.0)
├── telemetry-sweep/         (v0.9.3, F-013)
└── test-deletion-guardrail/ (v0.9.0; bypass closed v0.8.1 F-003)
```

CHANGELOG v0.9.1 cites "93 tests across 10 suites." That number plus the v0.9.3 additions (telemetry-sweep, secrets-scanner-executable adding 23 fixtures, jq-dependency) brings the count higher; exact total not recounted post-v0.9.3.

**Test fixture organization:** All test suites are bash shell scripts that take fixture inputs (`.json` payloads simulating Claude Code hook payloads, or `red.json`/`green.json` pairs simulating before/after states). No real Claude / Codex CLI invocation needed. Suites self-contained, run in parallel via the matrix. The pattern was established by `tests/hooks/test-filter-learnings.sh` in v0.8.0 and followed by every subsequent test suite. **Fixture-based testing is one of ADD's most effective design decisions** — it lets the project test hook scripts and validators without needing the Claude/Codex runtime. Worth highlighting as a v1.0 maturity differentiator.

**Test count caveat:** there is no central tally script. CHANGELOG v0.9.1 cited "93 tests across 10 suites"; v0.9.3 added 3 new suites with multiple test cases each (e.g., secrets-scanner-executable: 23 cases). Best estimate today: ~120-130 individual test cases across 14 suites. **A `scripts/count-tests.py` to produce a current canonical count would close a small honesty-audit drift surface.**

### CI Surface (4 workflows, ~15 jobs in `.github/workflows/`)

- **`compile-drift.yml`** — fails PRs where committed `plugins/add/` or `dist/codex/` doesn't match `scripts/compile.py` output. Source-of-truth invariant. v0.7.0 era. This is the single most load-bearing CI gate: it ensures `core/` ↔ generated artifacts can never diverge.
- **`schema-check.yml`** — frontmatter JSON Schema validation across all skills + rules. v0.7.0 era.
- **`rule-boundary-check.yml`** — flags PRs that weaken `NEVER`/`Boundaries:`/`MUST NOT` markers. v0.7.0 era. Defends against the well-documented LLM tendency to soften absolute markers when "improving" documentation.
- **`guardrails.yml`** (v0.9.1, the F-005 closure) — the broadest gate:
  - Static validators: frontmatter (with installed pyyaml + jsonschema), cache-discipline (default + strict-mode on 4 remediated skills), secret-patterns drift between `core/knowledge/secret-patterns.md` § 1 and `core/security/secret-patterns.json`.
  - Fixture-matrix (11 suites in parallel): hooks/filter-learnings, test-deletion-guardrail, codex-install (asset-ref smoke), cache-discipline, secrets-handling, secrets-scanner-executable, agents-md-sync, telemetry-jsonl, security/prompt-injection-defense, rule-parity, jq-dependency.
  - Claude marketplace manifest validation: runs `claude plugin validate .` and `claude plugin validate plugins/add` with **grep-guard** for the silent-exit-0 bug surfaced in v0.8.1 F-001 (the CLI reports "Validation failed" on stderr but exits 0). The grep guard catches this.

What CI does NOT gate today (relevant to v1.0):

- **No real `claude plugin install add@add-marketplace` smoke.** This is explicitly listed under `next_promotion_criteria` for GA. No fresh-machine reproduction lives in CI.
- **No real `codex` install smoke.** Same gap; the `tests/codex-install/test-install-paths.sh` test installs into a temp `CODEX_HOME` and asserts asset references resolve, but doesn't actually invoke Codex CLI.
- **No coverage measurement** — the project is markdown/JSON, so this is technically N/A, but the spec system promises "100% coverage of modified paths" at GA per the cascade matrix. ADD itself does not measure this for skill/rule edits (no notion of "spec coverage of skill body" in the toolchain).

### Documented Runtime Dependencies

- **`jq`** — required for hook scripts. Documented in `docs/runtime-dependencies.md` (v0.9.3 F-017) with per-OS install matrix (macOS, Debian/Ubuntu, Fedora/RHEL, Arch, Alpine, openSUSE, Windows Chocolatey/scoop/WSL, Nix), verification one-liner, per-site degradation behavior (2 hard-fail sites, 3 soft-fail sites). README, CONTRIBUTING.md, PRD § 7.3, and marketplace.json all qualify the "zero deps" claim with this. CI guard `tests/jq-dependency/test-jq-claim-qualified.sh` prevents regression of the bare phrasing.
- Optional: `npx eslint`, `ruff`, `git`, `gpg` (release-time only). All silently degrade.

### Multi-Runtime Status (Claude + Codex)

| Capability | Claude | Codex | Status |
|---|---|---|---|
| Skills emission | `plugins/add/skills/<name>/SKILL.md` (frontmatter preserved) | `dist/codex/.agents/skills/add-<name>/SKILL.md` (v0.9.0 native — was deprecated `~/.codex/prompts/` until M3) | **Parity** |
| Rules autoload | `runtimes/claude/CLAUDE.md` `@rules/` block, generated via `{{AUTOLOAD_RULES}}` placeholder | `dist/codex/AGENTS.md` slim manifest; Codex uses `agents.md` not autoload | **Different mechanism**, equivalent intent |
| Hook stderr → agent | Yes (Claude surfaces stderr next turn) | **No** (Codex stderr does not reach agent — documented limitation) | **Codex gap** for prompt-injection scanner UX |
| AGENTS.md generation | `/add:agents-md --write` works | Same skill ships to Codex | **Parity** |
| Telemetry emission | Per-skill pre-flight/post-flight contract (v0.9.0 + sweep v0.9.3) | Same skills ship to Codex; nothing Codex-specific blocks emission | **Parity** |
| Marketplace install | `claude plugin install add@add-marketplace` (manual; no CI smoke) | `curl ... install-codex.sh \| bash` | **Both manual; both untested** in CI |
| Version-source discovery | `plugin.json` → `plugin.toml` → `VERSION` (v0.9.1 fix) | Same fallback chain | **Parity** (v0.9.1 closed last F-002 allowlist) |

Codex CLI pinned to **0.122.0** per spec (release notes v0.9.0).

**Adapter-layer detail (`runtimes/{claude,codex}/adapter.yaml`):** these YAML files declare the substitutions and output shapes per runtime. `scripts/compile.py` reads them to drive the codegen. The adapter abstraction is real but currently **only two runtimes consume it**. The architecture supports a third (e.g., Cursor, Windsurf) but no third adapter has been authored. Every architectural review (M3 swarm reports, CHANGELOG v0.7.0 swarm rationale) emphasizes that ADD is "a methodology with runtime adapters, not a Claude plugin" — this framing is vital but currently undertested by virtue of having only two adapters.

**AGENTS.md interop:** `dist/codex/AGENTS.md` is the slim manifest the Codex adapter emits. The standalone `/add:agents-md` skill writes a tool-portable `AGENTS.md` to project root for any tool that follows the agents.md convention (Cursor, Codex, Copilot, Windsurf, Amp, Devin per CLAUDE.md). This means **ADD reaches consumers who don't have ADD installed** — the AGENTS.md output is a portable manifest of project state. As of v0.9.4, the dog-fooded AGENTS.md at repo root is at v0.9.1 (stale; § E).

### Maturity = `beta` with Specific Promotion Criteria

`.add/config.json`:

```json
"maturity": {
  "level": "beta",
  "promoted_from": "alpha",
  "promoted_date": "2026-04-23",
  "next_promotion_criteria": "Guardrail suite running in CI and release-blocking; real Claude + Codex install smoke in CI; per-runtime capability matrix in release notes; 60-day stability at beta; marketplace submission approved; 20+ projects using ADD.",
  "exemptions": []
}
```

Six explicit GA gates. Status today (best estimate):

1. Guardrail suite running in CI and release-blocking → **MET** (v0.9.1, `.github/workflows/guardrails.yml`).
2. Real Claude + Codex install smoke in CI → **NOT MET** (deferred, see § F).
3. Per-runtime capability matrix in release notes → **PARTIAL** — v0.9.0 release notes describe Codex parity narratively; no explicit matrix.
4. 60-day stability at beta → **NOT MET** — promoted 2026-04-23, today is 2026-04-22 in the model's clock context but the actual elapsed time at v0.9.4 (2026-04-27) is ~4 days. Hard timer.
5. Marketplace submission approved → **NOT MET** (no submission has happened; M3 Out-of-Scope says "parallel external work, no spec needed").
6. 20+ projects using ADD → **NOT MET / unmeasured** (only known adoption: ADD itself + dossierFYI dog-fooding mentioned historically + maybe agentVoice).

**~1.5 of 6 criteria met as of v0.9.4.**

---

## B. PRD Success Metrics Scoreboard

PRD § 3 lists 8 metrics. Current-state assessment per metric:

| Metric | Target | Today | Verdict |
|---|---|---|---|
| **GitHub stars (Y1)** | 100+ | Unknown from this worktree (not embedded in any local artifact). The repo is public at `MountainUnicorn/add`. | **Unmeasured locally**, externally observable. |
| **Plugin installs** | 500+ | Unmeasured. Marketplace metrics are not surfaced anywhere in `.add/`. The marketplace install path was non-existent until v0.5.0; reliable via `add@add-marketplace` from v0.7.0. | **Unmeasured.** |
| **Project coverage** | 20+ adoptions | **Confirmed adopters identifiable from artifacts:** ADD itself (dog-foods), references to `dossierFYI` (PRD § 6.1, Appendix A) and `agentVoice` (CHANGELOG v0.6.0 retro reference). Three known. | **3 / 20+. Far from target.** |
| **Marketplace rating** | ≥4.5/5 | Marketplace submission has not happened. | **N/A until submitted.** |
| **Time-to-first-value** | ≤5 min | `/add:init --quick` (v0.7.1) targets ~2 min for the 5-question greenfield path. Documented; no measurement of real users. | **Plausibly met** for the path that exists; **unverified** with real users. |
| **Quality gates efficacy** | 90%+ caught pre-deploy | Telemetry surface (v0.9.0) emits per-skill JSONL with `outcome` enum. Gate violations vs. caught violations are not currently aggregated anywhere. `core/skills/dashboard/SKILL.md` has a telemetry view section but no claim of efficacy %. | **Mechanism present; no measurement.** |
| **Knowledge persistence** | ≥70% reapplied cross-project | The 3-tier learnings cascade (Tier 1 plugin-global, Tier 2 user-local, Tier 3 project) is fully implemented. Reuse rate measurement does not exist. v0.8.0 measured token-cost reduction (62-82%) but not reuse %. | **Mechanism present; no measurement.** |
| **Adoption gradient (legacy)** | 50% on `--adopt` | `/add:init --adopt` ships (v0.2.0). Detection logic for test framework / linter / conventions is in the skill body. Adoption on legacy projects via `--adopt` is unmeasured. | **Mechanism present; no measurement.** |

**Scoreboard summary:** 0 of 8 metrics are in a "definitively met" state with measurement evidence. 3 metrics rely on external (GitHub) observability. 5 metrics depend on telemetry mechanisms ADD ships but no one is currently aggregating in this repo's `.add/`. The PRD success metrics are mostly **mechanism-implementable**, not **mechanism-implemented-and-measured**.

The telemetry contract in `core/rules/telemetry.md` is well-specified (OTel GenAI semantic conventions, `gen_ai.usage.input_tokens` and friends, `cache_hit_ratio`, `outcome` enum), and v0.9.3 closed the per-skill reference sweep so every skill body now references `rules/telemetry.md`. **Whether real consumers are emitting telemetry, and whether anyone is collecting it for the PRD metrics, are separate (unanswered) questions.**

### Local telemetry sanity check

Examining `.add/` in this worktree: `ls .add/` reveals `add-feedback.md`, `away-logs/`, `config.json`, `cycles/`, `handoff.md`, `learnings.json`, `learnings.md`, `learnings.md.bak`, `retro-scores.json`, `retros/`. **No `telemetry/` directory** — the dog-fooded ADD project itself does not emit telemetry into its own `.add/` directory at v0.9.4. Every skill invocation since the v0.9.3 reference sweep should be appending one JSONL line per the contract. Either:
- The dog-fooded sessions of this maintainer are not running through the skill system in a way that triggers pre-flight/post-flight emission, or
- The post-flight emission was specified but is not happening even on the maintainer's local sessions, or
- The directory is `.gitignored` and the file exists but isn't surfaced.

This is a **minor finding** — could indicate the telemetry rule is well-specified but not being enforced by skills in real Claude Code sessions. Worth a quick verification by the maintainer before v1.0 ships. **If even the maintainer's dog-fooded sessions don't emit telemetry, the PRD success metrics that depend on telemetry are even further from measurable than the headline scoreboard suggests.**

---

## C. Beta-Exit / GA-Entry Cascade Gap

`core/rules/maturity-lifecycle.md` cascade matrix, GA column. Each row that ADD currently fails or partially meets:

| Dimension | GA bar | ADD today (beta) | Gap |
|---|---|---|---|
| **PRD Depth** | Full template + detailed architecture, scalability model, migration path | Full template ✓; architecture in PRD § 5; scalability mentioned but not deeply argued; migration path described in `core/templates/migrations.json` | **Partial.** Migration path is mechanically present; scalability model isn't a separate doc. |
| **Specs Required** | Yes + exhaustive ACs + user test scenarios | All 7 M3 specs have ACs (207 total); v0.9.x F-013/F-014/F-017 specs followed same pattern | **Met for new work.** Older specs (`legacy-adoption.md`, etc.) less rigorous. |
| **TDD Enforced** | Strict no exceptions (100% coverage of modified paths) | "Strict" enforcement active per cascade row 3; but **no coverage measurement on plugin source itself** (it's markdown/JSON, no traditional coverage). Test-deletion guardrail (v0.9.0 + v0.8.1 fix) defends against the genie-deletes-test failure mode. | **Notion mismatch.** "Coverage of modified paths" doesn't translate to a markdown plugin. v1.0 needs to redefine the GA TDD bar for this project type. |
| **Quality Gates Active** | All 5 levels (pre-commit, CI, pre-deploy, deploy monitoring, SLA monitoring) | Pre-commit ✓ (`post-write.sh` ruff/eslint), CI ✓ (`guardrails.yml`, `compile-drift.yml`), pre-deploy ✓ (`/add:deploy` Step 1.5 secrets gate + `/add:verify --level deploy` Gate 4.6), **deploy monitoring partial** (no production deploy of the plugin itself; deploy-target is "users `claude plugin install`"), **SLA monitoring N/A** (open-source plugin, no SLA). | **3.5 of 5.** The two missing gates are project-shape mismatches, not deficiencies — but the cascade matrix promises them as a literal binary. |
| **Reviewer Agent** | Mandatory (two reviewers, one from stability team) | Beta cell says "Recommended" — and `/add:reviewer` is invoked by the maintainer at PR merge time; **no two-reviewer enforcement** anywhere in the toolchain. There is no "stability team." | **Not met.** Two-reviewer at GA needs either a corp-style reframe or the literal cascade bar lowered for solo/small-team projects. |
| **Environment Tier Ceiling** | Tier 2-3 (staging + production with deploy checks) | ADD is a Tier 1 project itself (per `.add/config.json`). The plugin enables Tier 1-3 *for consumers* but does not itself promote past Tier 1 (no staging URL, no production URL — the "production" surface is the marketplace). | **Cascade row mismatches project shape.** Plugin distribution ≠ deployment ladder. |
| **Away Mode Autonomy** | Guided with checkpoints (human approval at cycle start + completion, daily standups) | `/add:away` defaults to balanced autonomy (per `.add/config.json:collaboration.autonomy_level`). Cycle-start/completion approval flow exists in `/add:cycle`. **Daily standups not implemented.** | **Partial.** No daily-standup mechanism. |
| **Interview Depth** | ~15 questions (exhaustive AC validation) | `/add:init` default is ~12 questions (beta cell); `--quick` is 5; no separate ~15-question GA mode. | **Not met for GA-mode init.** |
| **Milestone Docs Required** | Full template + hill chart tracked daily + risk reassessment per cycle | M3 milestone (`docs/milestones/M3-pre-ga-hardening.md`) has hill chart + risks + cycle plan. Daily tracking happens via `/add:cycle --status` but isn't mandated. | **Mostly met** for current milestone; "daily" not enforced. |
| **Cycle Planning** | Full plan + risk assessment + parallel agent coordination + WIP limits | M3 cycles have all four. WIP limit `4` and `parallel_agents: 3` set in `.add/config.json:planning`. | **Met.** |
| **Features Per Cycle** | 3-6 with strict WIP limits | M3 Cycle 2 ran 3 specs in parallel, M3 Cycle 1 + 3 ran 2-3 each. WIP limit enforced. | **Met.** |
| **Parallel Agents** | 3-5 (strict worktree isolation, merge coordination, merge sequence docs) | `.add/config.json:planning.parallel_agents = 3`. Worktree isolation pattern dog-fooded (this report is being written from one). Merge sequence docs exist for M3 (CHANGELOG v0.9.0 explicitly lists merge order). | **Met at the floor (3 of 3-5).** |
| **Code Quality Checks** | Tighter thresholds (10/6/300/50), all blocking | ADD source is markdown/JSON; complexity/duplication/file-size checks don't directly apply. **Cache-discipline validator** (v0.9.1 F-018 fix) does enforce structural skill-body discipline strict-mode on 4 remediated skills. Frontmatter validation enforces schema. | **Mismatched bar.** v1.0 should redefine for plugin-source. |
| **Security & Vulnerability** | All blocking, CVEs blocking, rate limiting + secure headers required | **Secrets:** v0.9.3 F-014 executable scanner blocks at `/add:deploy` (interactive `--allow-secret` confirm-phrase) and at `/add:verify --level deploy`. **Injection-defense:** v0.9.0 hook is **warn-only** (CHANGELOG v0.9.3 says "hard-block deferred to v0.10 pending F-012 hook-feedback semantics"). **OWASP Top 10 Agentic 2026:** patterns catalog (`core/security/patterns.json`) covers it. **Dependency audit / CVEs / rate limiting / secure headers:** N/A for a plugin with no runtime deps. | **Most rows N/A; injection hard-block deferred to v0.10 by spec.** |
| **Readability & Documentation** | All blocking, module READMEs, glossary, nesting <4 | PRD § 9 + Appendix C glossary ✓. Module READMEs uneven (`runtimes/claude/`, `runtimes/codex/` have READMEs; `core/skills/`, `core/rules/` do not). | **Partial.** |
| **Performance Checks** | All blocking, perf tests required, response time baselines | `core/rules/cache-discipline.md` (v0.9.0) addresses cache-prefix discipline; `cache_hit_ratio` in telemetry. **No response-time baselines** for skill execution. | **Mostly N/A; observability baseline exists.** |
| **Repo Hygiene** | All blocking, 14-day stale limit, comprehensive README | LICENSE ✓, CHANGELOG ✓, README ✓, dependency freshness N/A, PR template (TBD), 14-day stale limit not enforced. | **Mostly met.** |

**Summary of GA-cascade gap:** Of the 17 cascade rows, ~6 are met cleanly, ~6 are met-with-mismatched-shape (rows that assume a deployed app with production environments, not a markdown plugin), ~3 are partial-met, and ~2 are explicitly deferred (injection hard-block → v0.10, two-reviewer requirement → no plan).

**The most important takeaway:** the `maturity-lifecycle.md` cascade matrix was authored generically and never tuned for ADD's own project shape. v1.0 either needs (a) a project-shape clarification ("ADD itself is a Tier-1 plugin; some GA-cascade rows are N/A and that's documented"), or (b) the cascade matrix gets a "plugin-source" mode that ADD declares.

### Subsidiary observation: PRD § 5 architecture vs reality

PRD § 5.2 infrastructure table predicts:

| Layer | Status (PRD) | Reality (v0.9.4) |
|---|---|---|
| Local (`.add/`) | v0.1.0 ✓ | ✓ in use |
| User (`~/.claude/add/`) | v0.2.0 | ✓ shipped v0.2.0 |
| GitHub | v0.1.0 ✓ | ✓ |
| Marketplace | v1.0.0 | manifest compliant; submission has not happened |
| CI/CD | v1.0.0 | shipped v0.7.0 + v0.9.1 broader; **ahead of PRD predictions** |

`core/` was **never described in PRD § 5** — the PRD predates the v0.7.0 source-of-truth restructure. The current architecture (core/ → compile.py → plugins/add/ + dist/codex/) is undocumented in the PRD. CLAUDE.md describes it for developers; the PRD does not.

### Subsidiary observation: § 5.3 environment strategy

PRD § 5.3 says ADD itself is Tier 1: "plugin itself has no backend/frontend—just markdown/JSON files in git." This is technically still true. But Tier 1 in the cascade matrix says "POC: Tier 1 (local, dev), GA: Tier 2-3" — and ADD's GA target (per `next_promotion_criteria`) does not move past Tier 1. The cascade matrix expects a deployment ladder ADD doesn't have; the PRD acknowledges this; the cascade matrix doesn't acknowledge the PRD. **v1.0 needs a single-paragraph reconciliation.**

---

## D. Promised but Undelivered (Cross-reference of v0.9.x release notes vs. real use)

Release-note claims that are partially or entirely inert in real use today.

### v0.9.0: Telemetry contract shipped, per-skill emission did not

- **Promise (v0.9.0 CHANGELOG):** "Structured JSONL telemetry — `.add/telemetry/{date}.jsonl` aligned with OTel GenAI semantic conventions, surfaced in `/add:dashboard`."
- **Delivered v0.9.0:** the contract (`core/rules/telemetry.md`), the template (`core/templates/telemetry.jsonl.template`), the dashboard view section, and a "one-line append in pre-flight" claim per spec.
- **Reality:** the per-skill reference sweep (so every skill body declared `references: rules/telemetry.md`) only landed in **v0.9.3 F-013** ("closes Swarm F's M3-deferred sweep — the contract … is now discoverable from any individual SKILL.md, and `tests/telemetry-sweep/test-skill-reference-coverage.sh` gates against future skills shipping without the reference"). 17 skills got a fresh `references:` entry; 10 had `rules/telemetry.md` appended.
- **What this means:** between v0.9.0 and v0.9.3, telemetry was a documented contract that every skill was supposed to honor — but agents reading individual SKILL.md bodies wouldn't find the rule reference unless they already had it autoloaded. This is now closed, but **it was inert for ~3 days of the v0.9.x line.** Whether agents are actually emitting telemetry in real consumer projects is unverified.

### v0.9.0: Prompt-injection scan hook — Codex doesn't surface it

- **Promise:** "Three-layer GA security story. New auto-loaded rule … new PostToolUse scan hook … pattern-matches tool output … Audit events append to `.add/security/injection-events.jsonl`."
- **Reality (Claude):** `runtimes/claude/hooks/posttooluse-scan.sh` writes findings to stderr. Claude Code surfaces stderr to the agent next turn — this works.
- **Reality (Codex):** `runtimes/codex/adapter.yaml` documents that "Codex stderr does not reach agent" (CHANGELOG v0.9.0). The scanner can still write to the JSONL audit log on Codex, but **the agent never sees the warning** — the F-012 hook-feedback semantics. This means Codex consumers get the audit trail but not the inline vigilance signal.
- **CHANGELOG v0.9.3** confirms: "Hard-block deferred to v0.10 pending F-012 hook-feedback semantics."
- **What this means:** "Three-layer security story" is **two-layer on Codex.** This is documented but easy to miss when reading the headline.

### v0.9.0: Secrets-handling — declarative gate vs. executable scanner

- **Promise (v0.9.0):** "Secrets handling — auto-loaded rule + `templates/.secretsignore` + pre-commit grep gate in `/add:deploy`."
- **Delivered v0.9.0:** the rule (`core/rules/secrets-handling.md`), the template, and prose-described gate.
- **Reality v0.9.0 → v0.9.3:** the gate was **declarative** — `/add:deploy` SKILL.md described what to check, but no executable validator existed. AC-019 of the secrets-handling spec was explicitly blocked on PR #6 per CHANGELOG v0.9.0.
- **Closed v0.9.3 F-014:** `core/lib/scan-secrets.sh` POSIX scanner, 8 patterns mirroring `core/knowledge/secret-patterns.md` § 1, drift-checked by `scripts/validate-secret-patterns.py`, wired into `guardrails.yml`. Gate 4.6 in `/add:verify`. `/add:deploy` Step 1.5 invokes the scanner. Advisory PreToolUse hook on `git push`.
- **What this means:** the v0.9.0 release-note phrasing made the secrets gate sound executable. It was prose-only for ~3 days. Now it's real, but **only blocking at deploy time.** Consumer's `git push` gets warnings only (advisory). Hard-block on push deferred to v0.10 (same F-012 dependency as injection-defense).

### v0.9.0: agents-md-sync staleness hook — fires but artifact not regenerated

- **Promise:** "PostToolUse staleness hook for AGENTS.md — `runtimes/claude/hooks/post-write.sh` now writes `.add/agents-md.stale` when `.add/config.json`, `core/rules/*.md`, or `core/skills/*/SKILL.md` changes and an `AGENTS.md` exists at root. The hook never auto-rewrites AGENTS.md — the human triggers regen."
- **Reality:** the hook fires correctly per code inspection of `runtimes/claude/hooks/post-write.sh:39-49`. **However:** ADD's own `AGENTS.md` at repo root says `<!-- ADD:MANAGED:START version=0.9.1 maturity=beta generated=2026-04-23T14:35:33Z -->`. The hook has fired plenty of times since v0.9.1 (every CHANGELOG edit, every `core/rules/*.md` change in v0.9.2 and v0.9.3 has changed the inputs). **The human did not regenerate** between v0.9.1 and v0.9.4. So the staleness signal works; the regen ritual is not in the version-bump checklist consistently. `docs/release-materials.md` § B does include "AGENTS.md regenerated" as a release-time step (semi-auto), but it was missed at v0.9.2/v0.9.3/v0.9.4.
- **What this means:** the hook is real and works. The post-release regen ritual is **inconsistently honored on the maintainer's own repo.** v1.0 should consider: either auto-regen on staleness with diff in PR, or make the staleness check a release-blocker.

### v0.9.x: Marketplace install — works in theory, unsmoked in CI

- **Promise (README):** `claude plugin marketplace add MountainUnicorn/add && claude plugin install add@add-marketplace`.
- **Reality:** Plugin-installation-reliability spec (`specs/plugin-installation-reliability.md`) was **Superseded** (per spec list inventory). v0.5.0 closed `plugins/add/` isolation. v0.7.0 reorganized the source-of-truth. v0.9.1 closed cross-runtime version path resolution. **No CI job actually runs `claude plugin install add@add-marketplace`** end-to-end on a fresh machine.
- The `guardrails.yml` `marketplace-validate` job runs `claude plugin validate .` and `claude plugin validate plugins/add` on the source tree, with the grep-guard from F-001. This is **manifest validation**, not install reproduction.
- `.add/config.json:next_promotion_criteria` lists "real Claude + Codex install smoke in CI" — explicitly identifying this as the GA gate.
- **What this means:** the install path is plausible based on artifact shape but unproven on a fresh machine. This is the single most load-bearing gap in the public claim surface.

### v0.9.0: Maturity bumped alpha→beta with one exemption — exemption now cleared (good)

CHANGELOG v0.9.1 says: "Beta-promotion exemption cleared. `.add/config.json` `maturity.exemptions` was holding `[F-005 guardrail CI wiring]` as a time-boxed promise from the v0.9.0 alpha→beta promotion. Now empty." Verified — `.add/config.json:maturity.exemptions = []`. **This one is delivered cleanly.**

### v0.9.0: Native Codex Skills emission — delivered, but Codex CLI version-pinned

- **Promise (M3 success criteria):** "Native Codex Skills — `dist/codex/.agents/skills/add-{skill}/SKILL.md` with preserved frontmatter; AGENTS.md slimmed to manifest; Codex install matches Claude install in capability."
- **Delivered v0.9.0:** the spec shipped 33/35 ACs per CHANGELOG; Codex CLI **pinned to 0.122.0** in `runtimes/codex/adapter.yaml` per the M3 risk mitigation ("pin to specific Codex CLI version; cite version in spec"). Generated skills now ship to `dist/codex/.agents/skills/add-{skill}/SKILL.md`, not the deprecated `~/.codex/prompts/`.
- **Reality:** v0.8.1 F-002 caught the install-path mismatch immediately after merge — generated Codex skills referenced `~/.codex/templates/`, `~/.codex/knowledge/`, etc., but the installer staged them under `~/.codex/add/`. Every skill invocation on Codex would have failed asset-ref resolution. Caught and fixed in v0.8.1. The regression smoke test (`tests/codex-install/test-install-paths.sh`) was added with the fix.
- **What this means:** the Codex parity claim is now **structurally correct** but it took a hotfix to actually function. The Codex CLI ships at a moving target — pinning to 0.122.0 means any newer Codex CLI is technically untested. **For v1.0:** either re-pin to current Codex stable or set up a Codex CLI version-matrix in CI.

### v0.9.2: On-demand rule/knowledge loading — delivered, with an architectural footnote

- **Promise (PR #6):** opts heavy rules out of autoload via `autoload: false`, declarative `references: []` array on skills, `core/references/` directory for extracted reference content.
- **Delivered v0.9.2:** mechanism shipped, schema enforced, 5 references extracted (`learning-reference.md`, `design-system.md`, `image-gen-detection.md`, `quality-checks-matrix.md`, `swarm-protocol.md`), 10 skills got `references:` frontmatter, count-tokens.py shipped for verification.
- **Reality:** as of v0.9.4, **zero rules are actually marked `autoload: false`.** The mechanism exists; it's not used yet for any rule. v0.9.3 used it for the per-skill `rules/telemetry.md` reference sweep — but that's a `references` declaration, not an `autoload: false` rule. The rule-extraction (e.g., taking `cache-discipline.md` off autoload and pulling it via `references`) hasn't happened.
- **What this means:** v0.9.2 shipped the **mechanism for cache-discipline-via-on-demand-loading** without doing the actual extraction. The autoload manifest at GA loads all 19 rules (gated by maturity). Token-cost reduction from PR #6 is currently 0 in practice; latent capability when rules grow.

### Summary table

| v0.9.x claim | Inert window | Closed at | Status today |
|---|---|---|---|
| Telemetry per-skill emission | v0.9.0 → v0.9.3 (~3 days) | v0.9.3 F-013 | ✓ Delivered (mechanism); consumer emission unverified |
| Secrets executable scanner | v0.9.0 → v0.9.3 (~3 days) | v0.9.3 F-014 | ✓ Delivered (deploy/CI); push hook advisory-only |
| Injection scanner agent-feedback (Codex) | v0.9.0 → present | Deferred to v0.10 (F-012) | ⚠ **Codex consumers get audit trail without inline warning** |
| AGENTS.md auto-regen on stale | n/a (always manual by design) | not closed | ⚠ **ADD's own AGENTS.md is at v0.9.1 marker, despite being v0.9.4** |
| Marketplace install smoke | v0.7.0 → present | not closed | ⚠ **GA gate; no CI reproduction** |
| jq dependency declared | v0.7.0 → v0.9.3 (~6 weeks) | v0.9.3 F-017 | ✓ Delivered |
| F-005 CI guardrails | v0.9.0 → v0.9.1 (~1 day) | v0.9.1 | ✓ Delivered |

Three open promises (rows 3, 4, 5) directly impede a credible v1.0 tag.

---

## E. Public-Surface Honesty Audit

Stale facts on user-facing surfaces, ordered by how visible they are.

### README.md

- **Line 13 badge:** `version-0.9.4` ✓ correct (v0.9.4 hotfix).
- **Line 452 disclosure header:** "Commands & Skills — 27 total (v0.9.1)" — count of 27 matches `core/skills/` count, but **the version annotation is stale (v0.9.1 → v0.9.4)**.
- **Line 501 disclosure header:** "Rules — 11 auto-loaded behavioral rules" — **STALE.** Actual count: 19 in `core/rules/`, of which 18 declare `autoload: true` and 1 (`design-system.md`) is unmarked (defaults to true). Even by maturity-loader gating, a beta project loads 13 rules and a GA project loads 14+. **README has not been updated since the new rules landed in v0.9.0 (cache-discipline, injection-defense, secrets-handling, telemetry).**
- **Line 555-560 Roadmap section:** "v0.4.0 — Next. Adoption & polish — `/add:init --adopt`…" — **CATASTROPHICALLY STALE.** v0.4.0 shipped in 2026-02 (CHANGELOG). v0.9.4 ships today. This roadmap reads like the project is still in February. v1.0 is listed as "Planned" with bullets that mostly already shipped.
- **Line 169:** infographic image src `docs/agent-architecture.svg` — file present.
- **Line 568:** infographic SVG link — file present.

### PRD (`docs/prd.md`)

- **Header:** "Last Updated: 2026-02-07" — **STALE by ~2.5 months.**
- **§ 4 Scope:** v1.0.0 entry says "Marketplace approval + 500+ installs in first month." Marketplace submission has not happened.
- **§ 4 v0.5.0:** describes interview safety nets shipped 2026-04 — accurate historical record.
- **§ 6.1 v0.1.0 surface:** correctly framed as historical baseline; Appendix B explicitly says "Historical record" and notes current v0.8.0 surface (now also stale — should reference v0.9.4).
- **§ 7.3 Maintainability:** qualifies the `jq` dependency correctly. ✓
- **§ 8 Open Questions:** several have shipped (multi-agent coordination, context window optimization). Marked accordingly in some rows but not all.

### CLAUDE.md (root)

- **Line 54:** "skills/ # 27 skills — all slash commands" ✓ matches `core/skills/`.
- **Line 55:** "rules/ # 19 auto-loading behavioral rules" ✓ matches.
- **Line 56:** "templates/ # 21 document templates" — **WRONG.** Actual `core/templates/` count: 23. Off by 2.
- **Line 57:** "knowledge/ # 2 Tier-1 knowledge files" — **WRONG.** Actual: 5 files (was 2 at v0.7, grew through v0.9.0 — `threat-model.md`, `secret-patterns.md`, `test-discovery-patterns.json` added; `image-gen-detection.md` was already there).
- **Line 65 onwards:** does not list `core/references/` or `core/lib/` or `core/security/` — these are real source-of-truth subdirs that ship to runtimes.

### `runtimes/claude/CLAUDE.md`

- **Line 24:** "rules/ # Auto-loading behavioral rules (19 files)" ✓ matches.
- **Skill table (lines 54-83):** lists all 25 user-facing skills correctly (test-writer + implementer + reviewer included on neighboring lines under "Key Skills"). Visually, the table shows 25 rows; the count "27 total" in CLAUDE.md elsewhere reflects 27 in `core/skills/` including agents-md and version. Consistent.

### `core/rules/maturity-loader.md` cascade matrix

- **Listed:** 15 rules.
- **Actual:** 19 rules in `core/rules/`.
- **Missing from matrix:** `cache-discipline`, `injection-defense`, `secrets-handling`, `telemetry` — the four new rules from v0.9.0.
- **Impact:** the matrix is the **mechanism** by which agents at any given maturity level decide which rules apply. A project at beta reading this matrix today does not see the four new security/cache/telemetry rules in the activation table. They probably autoload anyway via the `runtimes/claude/CLAUDE.md @rules/` block (rule-parity test enforces this), but the maturity-cascade gating logic for them is undocumented. **High-leverage doc fix.**

### `core/rules/maturity-lifecycle.md` cascade matrix vs PRD § 6.6

- PRD § 6.6 maturity table lists 7 dimensions (PRD, Specs, TDD, Quality Gates, Parallel Agents, Cycle Planning).
- `maturity-lifecycle.md` cascade matrix lists 17 dimensions.
- **The PRD is a strict subset of `maturity-lifecycle.md`.** Not a conflict, but the PRD presents an undersized view of the cascade. v1.0 should reconcile or explicitly link.

### `getadd.dev` (separate repo at `~/projects/getadd.dev/`)

Read-only inspection (NOT edited):

- Footer: "ADD v0.9.1 — Agent Driven Development | Free & open source" — **STALE by 3 hop releases (v0.9.2, v0.9.3, v0.9.4).** Per `docs/release-materials.md` § C, the footer should be bumped at every release.
- Hero pill links to `/blog/m3-pre-ga-hardening-v0.9` — accurate for v0.9.0 launch; nothing for v0.9.2/0.9.3/0.9.4.
- Skills disclosure: 27 ref-cards counted in `docs/skills.html` — **count matches `core/skills/`.** ✓
- No blog post for v0.9.2 (community release, the third tdmitruk merge), v0.9.3 (F-013/F-014/F-017 polish bundle), or v0.9.4 (migration chain hotfix).

### `marketplace.json`

- v0.8.1 F-001 fix correctly removed the stale "13 commands, 12 skills, 15 rules" count string and moved description into `metadata`. ✓
- Description string mentions multi-runtime ✓, jq qualification ✓, all current capabilities ✓.

### Marketplace.json plugin description

- Mentions: spec-driven TDD, trust-but-verify, maturity lifecycle, away mode, cross-project learning, multi-runtime.
- Missing: telemetry (could mention OTel alignment as a methodology differentiator), prompt-injection-defense, secrets handling, AGENTS.md interop.
- This is a minor copy-update opportunity for v1.0 marketing.

### Honesty audit summary

| Surface | Stale items | Severity |
|---|---|---|
| README "Rules — 11" disclosure | 8 rules off | **High** (front-page-of-repo) |
| README Roadmap section | ~5 versions behind | **High** |
| PRD header date + Roadmap | 2.5 months stale | **Medium** |
| CLAUDE.md template/knowledge counts | off by 2 / off by 3 | **Medium** |
| `maturity-loader.md` cascade matrix | 4 rules missing | **Medium** (mechanism) |
| AGENTS.md generated marker | 3 versions stale | **Medium** (dog-fooding signal) |
| getadd.dev footer | 3 versions stale | **Medium** (separate repo) |
| getadd.dev blog | no v0.9.2/0.9.3/0.9.4 | **Low** (cosmetic; release-materials.md acknowledges blog is optional for hotfixes) |
| Skills version annotation in README disclosure | v0.9.1 → v0.9.4 | **Low** |

**Total honesty findings: ~9 distinct stale items.** None are individual blockers; their **aggregate** is the v1.0 credibility issue.

### Why the drift happened — process diagnosis

`docs/release-materials.md` (drafted 2026-04-27 alongside v0.9.4) **explicitly identifies** every one of these surfaces as needing attention at release time, with `automation` columns marking which are auto / semi-auto / manual:

- README badge + counts: semi-auto (in version-bump checklist)
- Counts in tree diagrams: semi-auto (rule count tested via `tests/rule-parity/`; skills + templates manual)
- AGENTS.md regenerated: semi-auto (generator exists; invocation manual)
- Site footer bump: semi-auto (`sed -i ''` over file glob)

The release-materials.md document was **drafted v0.9.4** — meaning the maintainer noticed the post-release follow-up work was not happening systematically and authored a canonical checklist to fix it. **The checklist exists; v0.9.4 itself shipped without running it.** This is the v1.0 risk: the release-script automates tagging and signing well, but the post-release ritual is human-judgment-dependent and prone to skipping.

**The proposed `/add:post-release` skill** (spec at `specs/post-release-publication.md`, drafted alongside v0.9.4) is the structural fix — walk the checklist top-down, check automated items, prompt on manual items, mark checkboxes complete in a session log. Its absence means today's release flow expects the maintainer to remember 30+ post-release steps. **This is a v1.0 hardening candidate.**

---

## F. Risk Register — What Would Block a v1.0 Tag Tomorrow

Concrete failures, ordered by load-bearing weight.

### F.1 — Marketplace install path has zero CI smoke

- **Claim:** README, marketplace.json, and CLAUDE.md all promise `claude plugin install add@add-marketplace` works.
- **Failure mode:** If the plugin manifest, source path, or marketplace cache had a regression, no automated check would catch it. The v0.8.1 F-001 hotfix was found by **maintainer running `claude plugin validate` manually** post-merge — not by CI. We got lucky.
- **What v1.0 needs:** an end-to-end install reproduction in CI: spin up a clean container, `npm install -g @anthropic-ai/claude-code`, `claude plugin marketplace add MountainUnicorn/add` (against a temp marketplace pointing at the PR's tree, not main), `claude plugin install add@add-marketplace`, then `/add:init --quick` and verify `.add/config.json` exists.
- **Status in `.add/config.json:next_promotion_criteria`:** "real Claude + Codex install smoke in CI" — **explicitly named as a GA gate.**
- **M3 milestone "Out of Scope":** "Marketplace re-submission to official Claude Code registry (parallel external work, no spec needed)" — **the install reproduction is not the same as marketplace re-submission**, but the project hasn't disambiguated.

### F.2 — `next_promotion_criteria` not met (4 of 6)

Reproduced from § A:

1. ✓ Guardrail suite running in CI and release-blocking.
2. ✗ Real Claude + Codex install smoke in CI.
3. ◐ Per-runtime capability matrix in release notes (described narratively; no explicit matrix).
4. ✗ 60-day stability at beta (timer started 2026-04-23; v0.9.4 elapsed = ~4 days).
5. ✗ Marketplace submission approved.
6. ✗ 20+ projects using ADD (3 known).

**A v1.0 tag tomorrow violates the project's own published GA criteria.**

### F.3 — Injection-defense and secrets-handling are warn-only on push

- v0.9.3 CHANGELOG: "Hard-block deferred to v0.10 pending F-012 hook-feedback semantics."
- A v1.0 release that markets "GA security" against OWASP Top 10 Agentic 2026 while the actual `git push` hook is **advisory-only** is a credibility gap. Either v1.0 needs to land F-012 (Codex hook stderr surfacing — likely upstream Codex CLI work, not in ADD's control) or the marketing language needs to honestly say "warn-only, hard-block in v1.1."

### F.4 — Stale public surfaces (see § E)

Compounding: any prospective adopter reading the README right now sees:
- Stale rule count ("11" vs. 19)
- Stale roadmap (v0.4.0 as "Next")
- Footer on getadd.dev says v0.9.1
- AGENTS.md generated marker says v0.9.1

A v1.0 announcement that lands with these stale facts undermines the launch's credibility. **A doc-truth pass is a v1.0 prerequisite.**

### F.5 — `maturity-loader.md` cascade matrix omits 4 rules

The mechanism by which a beta project decides which rules to enforce literally does not list the four security/observability rules shipped in v0.9.0. Agents probably autoload them anyway via the rule-parity-tested `@rules/` block, but the maturity-aware gating semantics for them is undefined. **Specifically problematic for POC/Alpha consumers** who should not be enforcing telemetry pre-flights or strict cache-discipline yet.

### F.6 — Plugin self-hosts no telemetry; PRD success metrics unmeasurable

PRD § 3 lists 8 metrics; 5 of them depend on telemetry-style measurement. The telemetry mechanism shipped in v0.9.0/0.9.3 emits to **consumer projects**. ADD itself does not ingest telemetry from its own consumers (no opt-in pipeline, no aggregation). **A v1.0 tagged today has no measurement loop to validate the Y1 metrics it promises.**

This is a chicken-and-egg: ADD needs to ship v1.0 to get to 20+ projects to get to measurement. Document the chicken-and-egg honestly in the release notes; don't claim metrics that aren't measurable.

### F.7 — PRD describes a v1.0.0 surface that already shipped (mostly)

PRD § 4 v1.0.0 entry promises:
- Marketplace submission package (fully compliant) — **manifest is compliant per v0.8.1 F-001 fix; submission has not happened.**
- Multi-environment Tier 2/Tier 3 support — **shipped in v0.7.x and earlier; Tier 1-3 in environment-awareness rule.**
- Advanced learnings system: agent auto-checkpoints + human retros — **shipped in v0.4.0 (CHANGELOG).**
- CI/CD hooks: pre-commit lint, pre-push gate, test automation — **shipped in v0.7.0 + v0.9.1 guardrails.yml.**
- Quality gates dashboard — **`/add:dashboard` shipped in v0.6.0; telemetry view section added v0.9.0.**
- Template marketplace — **NOT SHIPPED.**
- Profile system — **shipped in v0.2.0 (CHANGELOG).**
- Enhanced verify skill: semantic testing, regression detection — **shipped progressively; v0.9.0 added test-deletion-guardrail Gate 3.5; v0.9.3 added Gate 4.6 secrets.**

**Of the 8 v1.0 PRD bullets, 6 have shipped, 1 is partial (marketplace-submission-package vs actual-submission), 1 is not shipped (template marketplace).** The PRD v1.0 description is essentially historic; the actual v1.0 needs new framing.

### F.8 — Test-deletion guardrail bypass was caught in v0.8.1 — could it happen again?

CHANGELOG v0.8.1 F-003 narrates: "`scripts/check-test-count.py` treated `--allow-test-rewrite` as a full bypass… Fix: the replacement check now runs unconditionally." The test fixture `replacement-with-flag-no-override` was added **after** the bug was caught.

**Lesson:** the v0.9.0 release described the test-deletion guardrail as bullet-proof; it had a bypass that escaped review. Confidence in v1.0 security claims should be tempered by: every v0.9.x release has had at least one F-NNN finding from the plugin-family review (F-001, F-002, F-003 in v0.8.1; F-005, F-011, F-018 in v0.9.1; F-013, F-014, F-017 in v0.9.3). **A v1.0 tag should expect one or two more F-NNN findings, even after a clean CI run.**

### F.9 — Migrations chain has gaps (closed v0.9.4) — but the closure pattern is reactive

v0.9.4 was a hotfix CHANGELOG: "`core/templates/migrations.json` — manifest's `plugin_version` field advanced from 0.8.0 to 0.9.4. Six new hops added… across v0.8.1, v0.9.0, v0.9.1, v0.9.2, and v0.9.3 the manifest was not advanced; this release patches all five at once."

**The lesson the maintainer captured:** "The version-bump checklist in maintainer memory now includes `core/templates/migrations.json` as a step. Future releases must add a migration entry (even an empty one) when bumping `core/VERSION`."

This is a memory-only fix. The compile-drift check does not enforce that `core/templates/migrations.json` advances with `core/VERSION`. **A 1-hour CI improvement** would catch this regression at PR time. v1.0 candidate.

### F.10 — `core/lib/` and `core/security/` are not in the canonical inventory documentation

CLAUDE.md describes the source-of-truth structure with skills/rules/templates/knowledge/schemas. **`core/lib/` (scan-secrets.sh, impact-hint.sh) and `core/security/` (patterns.json, secret-patterns.json) are real source-of-truth subdirs that ship to runtimes, but neither appears in the CLAUDE.md "Repository Structure" diagram.** Same for `core/references/` (added v0.9.2, listed in skill `references:` arrays). **3 source-of-truth subdirs invisible to the developer-facing structure documentation.** v1.0 doc fix.

### Risk-register summary

| ID | Title | Blocking for v1.0? |
|---|---|---|
| F.1 | Marketplace install no CI smoke | **YES** (named as GA gate) |
| F.2 | next_promotion_criteria 4-of-6 missed | **YES** (project's own definition of GA) |
| F.3 | Injection + secrets warn-only on push | **CONDITIONAL** (depends on v1.0 marketing language) |
| F.4 | Stale public surfaces | **YES** (launch credibility) |
| F.5 | maturity-loader cascade matrix gap | **MEDIUM** (mechanism doc fix) |
| F.6 | No telemetry self-hosting; metrics unmeasurable | **CONDITIONAL** (acknowledge in release; do not claim) |
| F.7 | PRD v1.0 description is historical | **YES** (need new v1.0 framing) |
| F.8 | F-NNN findings will continue | **NO** (lifecycle reality, not a blocker) |
| F.9 | migrations.json drift | **LOW** (1-hour CI fix would close) |
| F.10 | core/lib, core/security, core/references not in dev docs | **LOW** (doc fix) |

**4 hard blockers** (F.1, F.2, F.4, F.7) plus 2 conditional issues (F.3, F.6) plus 4 lower-severity doc/mechanism gaps (F.5, F.9, F.10, F.8 as lifecycle reality).

### Cross-reference to project's own M3 success criteria

Re-reading `docs/milestones/M3-pre-ga-hardening.md` § Success Criteria:

- [✓] **Native Codex Skills** — shipped v0.9.0; v0.8.1 F-002 fix made it actually work; pinned to Codex 0.122.0.
- [✓] **Prompt-injection defense** — auto-loaded rule, hook, threat model — all shipped v0.9.0; **Codex feedback gap noted (F.3 above).**
- [✓] **Secrets handling** — shipped v0.9.0 declarative + v0.9.3 F-014 executable; **push hook advisory only (F.3).**
- [✓] **Structured JSONL telemetry** — shipped v0.9.0 contract + v0.9.3 F-013 sweep; **dashboard view section exists.**
- [✓] **Test-deletion guardrail** — shipped v0.9.0 + v0.8.1 F-003 fix.
- [✓] **Cache-discipline rule** — shipped v0.9.0; **mechanism for on-demand-loading shipped v0.9.2 PR #6 but not yet used.**
- [✓] **AGENTS.md generation/sync** — shipped v0.9.0 + v0.9.1 fix; **dog-food regen ritual not honored (E above).**
- [✓] **PR #6 merged** — landed v0.9.2.
- [✓] **All seven specs approved and shipped Complete.**
- [✓] **Maturity promotion alpha → beta** — executed 2026-04-23.
- [✓] **CHANGELOG `[0.9.0]` published** — verified.

**M3 was delivered.** The success criteria are met. The risk register above describes **gaps between M3 delivery and v1.0 readiness**, not M3 failures. v1.0 is a different milestone than M3, and `next_promotion_criteria` in `.add/config.json` is the gate, not M3's bullets.

---

## G. What's Working — strengths inventory (so v1.0 doesn't break what's good)

Equally important to risks: the strengths the v1.0 process must preserve.

### G.1 — Source-of-truth invariant (compile-drift CI)

The `core/` → `compile.py` → `plugins/add/` + `dist/codex/` flow is **fully enforced by CI**. Every PR that touches generated artifacts without matching source changes (or vice versa) is rejected. **This is the architectural backbone of multi-runtime support.** Any v1.0 process change must preserve compile-drift as the canonical gate.

### G.2 — Frontmatter schema validation

Every skill and rule's YAML frontmatter is JSON-Schema-validated by `scripts/validate-frontmatter.py`. Invalid `description`, `argument-hint`, `allowed-tools`, `disable-model-invocation`, `autoload`, `maturity`, or `globs` values are rejected at PR time. This is dull infrastructure but it's the reason ADD can claim "schema-enforced" rule and skill metadata.

### G.3 — NEVER-marker boundary preservation

`rule-boundary-check.yml` flags PRs that weaken `NEVER`/`Boundaries:`/`MUST NOT` markers. v0.9.2 narrates: "**`core/rules/human-collaboration.md`** — NEVER markers and Confusion Protocol sections restored after the prior condensation pass dropped them. Boundary strength preserved, body still condensed." This catch-and-restore loop is exactly what the boundary check is for.

### G.4 — Fixture-based testing without Claude/Codex CLI dependency

Every guardrails.yml fixture suite runs in seconds without invoking the actual Claude or Codex runtime. This makes CI fast (parallel matrix) and tests deterministic. The trade-off: ADD does not currently test the **integration** between fixtures and real CLI behavior — that's the install-smoke gap (F.1).

### G.5 — GPG-signed releases since v0.7.2; verified-on-GitHub since v0.7.3

Maintainer fingerprint published in SECURITY.md, key on github.com/MountainUnicorn.gpg, `release.sh` enforces signing pre-tag, every tag verifiable via `git tag --verify`. **This is genuine supply-chain hardening that few markdown plugins bother with.**

### G.6 — Community contribution flow

Three community releases in a row (v0.7.0 had 4 contributors; v0.8.0 was @tdmitruk's first; v0.9.2 was @tdmitruk's third). The `community_pr_handling.md` memory note captures the pattern. **This is a meaningful adoption signal** — though not enough by itself to hit the 20+ adopter target.

### G.7 — Maturity-machinery dog-fooding

ADD's own project state lives in `.add/`, dog-foods every skill, and the `next_promotion_criteria` field is honest about what GA requires. **This level of dog-fooding is the strongest possible adoption signal**: the maintainer is the first user, the most honest critic, and the canonical reference implementation.

### G.8 — Migration chain (now closed v0.9.4)

Every prior version can hop to current. `core/templates/migrations.json` is the manifest; `version-migration.md` rule guides agents to apply migrations on session start. v0.9.4 closed the chain back to v0.5.0; older versions step through 0.5.0 → 0.6.0 → 0.7.0 → 0.7.3 → 0.8.0 → 0.9.3 (skip-hop) → 0.9.4. **No upgrading consumer is stranded.**

### G.9 — Telemetry contract is OTel-aligned

`core/rules/telemetry.md` follows OpenTelemetry GenAI semantic conventions (`gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, etc.). **A consumer who plumbs `.add/telemetry/*.jsonl` into an OTel collector gets industry-standard observability.** This is a credible enterprise differentiator.

### G.10 — Multi-runtime story is structurally real

`runtimes/{claude,codex}/adapter.yaml` + `scripts/compile.py` is not vaporware. `dist/codex/` ships native Codex Skills with frontmatter preserved. The architecture is ready for a third runtime (Cursor, Windsurf, etc.) the day someone authors an adapter — including community contribution.

## H. v1.0 Candidate List Synthesis (this swarm's view)

Distilled from § F (risks) and § G (strengths-to-preserve), the v1.0 work surfaces:

### Must-do (release blockers)

1. **Marketplace install smoke in CI** (F.1) — closes the most load-bearing GA gate.
2. **Truth pass on README + CLAUDE.md + getadd.dev + AGENTS.md regen** (F.4) — half a day of work, transforms launch credibility.
3. **`maturity-loader.md` cascade matrix completed** for the 4 v0.9.0 rules (F.5) — 30 minutes.
4. **PRD v1.0 reframe** (F.7) — the current PRD § 4 v1.0 description is historic; v1.0 needs new framing.
5. **migrations.json CI drift gate** (F.9) — 1 hour to add to compile-drift.
6. **`core/lib/`, `core/security/`, `core/references/` documented in CLAUDE.md** (F.10) — 15 minutes.

### Conditional (depends on v1.0 marketing language)

7. **F-012 hook-feedback semantics for Codex** OR honest "warn-only on push, hard-block in v1.1" framing (F.3).
8. **Telemetry self-hosting decision** OR honest "metrics measurable when consumers opt in" framing (F.6).

### Calendar gates (cannot accelerate)

9. **60-day stability at beta** — promoted 2026-04-23; earliest GA = 2026-06-22.
10. **Marketplace submission approved** — external dependency on Anthropic Claude Code marketplace review process.
11. **20+ projects using ADD** — community/marketing problem; Swarm 3 territory.

### Should-have (raises credibility)

12. **`/add:post-release` skill** (spec exists at `specs/post-release-publication.md`) — automates the 30+ post-release checklist items in `docs/release-materials.md`.
13. **`scripts/count-tests.py`** — canonical test count to plug the small CHANGELOG drift surface.
14. **Per-runtime capability matrix in v1.0 release notes** — already in `next_promotion_criteria`.
15. **`/add:agents-md` integrated into release pipeline** — auto-regen at version bump, fail release if stale.

### Nice-to-have (not v1.0-blocking)

16. **Third runtime adapter** (Cursor or Windsurf) to validate the multi-runtime architecture beyond the {Claude, Codex} pair.
17. **Telemetry collector reference implementation** — even a `scripts/collect-telemetry.py` that aggregates `.add/telemetry/*.jsonl` from a consumer report would seed the measurement loop.
18. **`autoload: false` actually used on a heavy rule** (e.g., extract `cache-discipline.md` to `references/`, mark autoload false). Currently the v0.9.2 mechanism is unexercised.

## Closing assessment

ADD at v0.9.4 is a strong beta. The methodology surface is broad, internally consistent, and runtime-portable. The CI safety net is real (guardrails.yml + compile-drift + frontmatter + rule-boundary). The release pipeline is GPG-signed and verifiable. Three community contributors have shipped through the process. Seven M3 specs landed in parallel via worktree-isolated agent swarms — the project's own machinery for shipping at beta velocity.

The path to v1.0 is **not** more features. It is:

1. **Truth pass on public surfaces** (README rule count, roadmap, PRD date, getadd.dev footers, AGENTS.md regen). Half a day of work.
2. **Marketplace install smoke in CI** (the most load-bearing GA gate per the project's own definition). 1-2 days.
3. **Codex hook-feedback reckoning** — either F-012 lands or the v1.0 security marketing honestly says "warn-only on push." Conversation with upstream Codex CLI maintainers required.
4. **maturity-loader.md cascade matrix completed** for the four v0.9.0 rules. 30 minutes.
5. **PRD v1.0 reframe** — the current § 4 v1.0.0 bullets are mostly historic. Author what v1.0 actually means now. Half a day.
6. **60-day beta timer.** This is a calendar gate. v1.0 cannot honestly tag until ~2026-06-22 against the current criterion, regardless of work done.
7. **Adoption.** 3 known projects → 20+ is a marketing/community problem, not an engineering one. Swarm 3 will speak to this.

If items 1-5 land cleanly, the project is technically credible for v1.0 well before the 60-day timer. The discipline question is whether to lower the bar (revise `next_promotion_criteria` honestly) or hold the line.

**End of Swarm 1 report.**

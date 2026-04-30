# Swarm 2 — Unimplemented Work Inventory

**Perspective:** Unimplemented work — what's been planned/specced but not yet built.
**Date:** 2026-04-22 (worktree session)
**Repo state:** main @ `448114e` ("docs: spec + plan post-release publication cycle")
**Current shipped version:** v0.9.4 (per `core/VERSION` & CHANGELOG)
**Maturity:** beta (promoted v0.9.0, exemptions empty since v0.9.1)

This report catalogues every spec, plan, and known follow-up item, classifies maturity (Draft / Approved / Implementing / Complete / Superseded), priority for GA, dependencies, and identifies promotion candidates and orphans for v1.0 synthesis.

---

## TL;DR — headline finding

Of **23 specs** in `specs/`, **9 are shipped Complete** (and one shipped-but-frontmatter-stale: 6 M3 features marked "Draft" in their files but recorded as fully delivered in `CHANGELOG [0.9.0]`). **2 specs are genuinely unshipped Draft** (`post-release-publication`, plus `agents-md-sync`-class frontmatter stragglers needing only a status flip). **1 spec is Superseded.** **1 is the meta plugin-family-review spec (F-001..F-020)** — 11 of its 20 findings shipped, **9 remain unshipped** and form the spine of the v0.9.x → v1.0 hardening backlog.

The strongest single bucket of GA-blocking work is **F-006 → F-016 + AC-022/AC-023/AC-024/AC-025/AC-026/AC-028** from `plugin-family-release-hardening.md`: host-neutral kernel, adapter contracts authoritative, Codex packaging schema, installer ownership manifest, config schema + migration graph validator, command catalog generator, real Claude+Codex install smoke in CI, signed-install URL. These are Approved-by-spec but not started.

The cleanest near-term promotion candidate is `/add:post-release` + the four `release-materials.md` open follow-ups — small surface area, dog-foodable on the next release.

The orphan to retire (or hard-supersede) is `specs/timeline-events.md` (Draft for v0.5.0, never implemented; dashboard now reads other sources).

---

## A. Specs by status

Enumerated from `specs/*.md` (23 files). Status normalized against frontmatter AND ground-truth CHANGELOG cross-check.

### A.1 Complete (shipped, behavior live in `core/`)

| Spec | Frontmatter status | Shipped in | Lines | Notes |
|------|--------------------|------------|------:|-------|
| `auto-changelog.md` | Complete | v0.3.0 | 251 | `/add:changelog` skill present in `core/skills/changelog/`. |
| `branding-system.md` | Complete | v0.3.0 | 183 | `branding.json` schema + `/add:brand`, `/add:brand-update`. |
| `image-gen-detection.md` | Complete | v0.3.0 | 182 | Point-of-use detection live; references file `references/image-gen-detection.md`. |
| `infographic-generation.md` | Complete | v0.3.0 | 249 | `/add:infographic` ships; `docs/infographic.svg` in repo. |
| `learning-library-search.md` | Complete | v0.4.0 | 267 | JSON learnings + 4-tier library; v0.8.0 added active-view filter on top. |
| `legacy-adoption.md` | Complete | v0.4.0 | 180 | `migrations.json` flow alive; v0.9.4 hotfix repaired the manifest chain. |
| `retro-template-automation.md` | Complete | v0.4.0 | 287 | `/add:retro` ships data-driven walk. |
| `session-continuity-and-self-evolution.md` | Complete | v0.3.0 | 272 | Handoff + maturity-gated rules + scopes shipped. |
| `telemetry-skill-reference-sweep.md` | Shipped (Path A) | v0.9.3 | 311 | F-013 — every skill declares `references: rules/telemetry.md` via PR #6 mechanism. |

### A.2 Implementing (shipping or shipped, frontmatter not updated)

| Spec | Frontmatter | Reality | Action |
|------|-------------|---------|--------|
| `project-dashboard.md` | Implementing | Skill `core/skills/dashboard/SKILL.md` exists and is the canonical dashboard; reports/dashboard.html generated. | Flip Status: Complete. |
| `agents-md-sync.md` | Draft | Shipped in v0.9.0 (36/36 ACs per CHANGELOG), `core/skills/agents-md/SKILL.md` live, `scripts/generate-agents-md.py` shipped. | Flip Status: Complete. |
| `cache-discipline.md` | Draft | Shipped in v0.9.0 (21/24 ACs; remaining 3 telemetry ACs closed by #11 per CHANGELOG). | Flip Status: Complete. |
| `prompt-injection-defense.md` | Draft | Shipped in v0.9.0 (30/30 ACs per CHANGELOG, hook + rule + threat model live). | Flip Status: Complete. |
| `secrets-handling.md` | Draft | Shipped in v0.9.0 (23/24 ACs; AC-019 originally blocked on PR #6, now unblocked since PR #6 merged in v0.9.2 — verify it landed). F-014 executable scanner shipped v0.9.3. | Flip Status: Complete (verify AC-019 closed). |
| `telemetry-jsonl.md` | Draft | Shipped in v0.9.0 (30 ACs per CHANGELOG); per-skill reference sweep added v0.9.3. | Flip Status: Complete. |
| `test-deletion-guardrail.md` | Draft | Shipped in v0.9.0 (25 ACs per CHANGELOG); F-003 bypass closed in v0.8.1. | Flip Status: Complete. |
| `codex-native-skills.md` | Draft | Shipped in v0.9.0 (33/35 ACs per CHANGELOG). 2 ACs deferred: AC-031 (marketplace.json companion / Codex install path) + AC-035 (containerized CI runtime smoke). | Flip Status: Implementing → Complete-with-deferrals; promote AC-031 + AC-035 into v1.0 (overlaps with F-008/F-023). |
| `jq-dependency-declaration.md` | Draft | Shipped in v0.9.3 (Strategy A — declared honestly + new `docs/runtime-dependencies.md`). | Flip Status: Complete. |
| `secrets-scanner-executable.md` | Draft | Shipped in v0.9.3 (PR #17 — `core/lib/scan-secrets.sh` + `core/security/secret-patterns.json` + Gate 4.6). Hard-block at `git push` deferred to v0.10 pending F-012. | Flip Status: Complete-with-deferral; promote hard-block to v1.0. |

**Hygiene note:** 9 specs are operationally Complete but carry frontmatter that says Draft / Implementing / Shipped(PathA). This is documentation drift — a single sweep flipping these to `Status: Complete` would clean the picture for v1.0.

### A.3 Approved (greenlit, not started)

| Spec | Target | Status notes |
|------|--------|--------------|
| `plugin-family-release-hardening.md` | v0.8.1 ✓ / v0.9.0 partial / **v1.0.0 unfilled** | Meta-spec aggregating F-001..F-020. v1.0.0 acceptance criteria AC-022 → AC-028 are unstarted. **This is the GA spine.** |

The plugin-family-release-hardening spec is *de facto* approved (every release since v0.8.1 has been driven against its findings) but its v1.0.0 section is the largest single block of unimplemented work in the repo — see § D.

### A.4 Draft (proposed, awaiting greenlight)

| Spec | Created | Target | Lines | One-liner |
|------|---------|--------|------:|-----------|
| `post-release-publication.md` | 2026-04-27 | v0.10.0 | 241 | `/add:post-release` skill walks `docs/release-materials.md` after a release tag; 32 ACs, plan exists at `docs/plans/post-release-publication-plan.md`. |
| `timeline-events.md` | 2026-02-21 | v0.5.0 | 271 | `.add/timeline.json` append-only event log for dashboard. **Stale ~9 weeks**; v0.5 shipped without it; dashboard sources data elsewhere. → orphan candidate (§ F). |

### A.5 Superseded

| Spec | Superseded by | Note |
|------|---------------|------|
| `plugin-installation-reliability.md` | v0.5.0 plugin isolation + v0.7.0 source-of-truth split | Frontmatter explicitly marks Superseded; counts inside body refer to repo state at drafting (10 cmds / 9 skills / 13 rules vs today's 27 skills / 19 rules). Retained as historical record per its own header. **Action:** keep — already correctly marked. |

### A.6 Roll-up

| Bucket | Count |
|------:|------|
| Complete (truly) | 9 |
| Implementing → Complete (frontmatter stale) | 9 |
| Approved (v1.0 spine) | 1 |
| Draft (real) | 2 |
| Superseded | 1 |
| **Total specs in `specs/`** | **22** + 1 hardening meta = **23** |

(Recount note: `specs/` actually has 23 .md files; the meta spec `plugin-family-release-hardening.md` is counted both as a spec and as the source of F-IDs in § D.)

---

## B. Plans by status

20 plans live under `docs/plans/`. Each pairs to a spec.

| Plan | Spec | Plan status | Spec shipped? | Plan still useful? |
|------|------|-------------|--------------:|--------------------|
| `agents-md-sync-plan.md` | agents-md-sync | (no status) | ✓ v0.9.0 | Stale — historical only |
| `auto-changelog-plan.md` | auto-changelog | (no status) | ✓ v0.3.0 | Stale — historical only |
| `branding-system-plan.md` | branding-system | (no status) | ✓ v0.3.0 | Stale — historical only |
| `cache-discipline-plan.md` | cache-discipline | (no status) | ✓ v0.9.0 | Stale — historical only |
| `codex-native-skills-plan.md` | codex-native-skills | **In progress** | ✓ v0.9.0 (33/35) | Update status; 2 deferred ACs still relevant |
| `image-gen-detection-plan.md` | image-gen-detection | (no status) | ✓ v0.3.0 | Stale |
| `infographic-generation-plan.md` | infographic-generation | (no status) | ✓ v0.3.0 | Stale |
| `jq-dependency-declaration-plan.md` | jq-dependency-declaration | Draft | ✓ v0.9.3 | Stale — close out |
| `learning-library-search-plan.md` | learning-library-search | (no status) | ✓ v0.4.0 | Stale |
| `legacy-adoption-plan.md` | legacy-adoption | (no status) | ✓ v0.4.0 | Stale |
| `plugin-family-release-hardening-plan.md` | plugin-family-release-hardening | **Draft** | partial (v0.8.1 + v0.9.0 partial) | **LIVE — v1.0.0 release section unfilled** |
| `post-release-publication-plan.md` | post-release-publication | **Draft** | not yet | **LIVE — promotion candidate** |
| `project-dashboard-plan.md` | project-dashboard | (no status) | ✓ shipped | Stale |
| `prompt-injection-defense-plan.md` | prompt-injection-defense | (no status) | ✓ v0.9.0 | Stale |
| `retro-template-automation-plan.md` | retro-template-automation | (no status) | ✓ v0.4.0 | Stale |
| `secrets-handling-plan.md` | secrets-handling | **In Progress** | ✓ v0.9.0 (23/24) | Update status — close out |
| `secrets-scanner-executable-plan.md` | secrets-scanner-executable | Draft | ✓ v0.9.3 | Stale — close out |
| `telemetry-jsonl-plan.md` | telemetry-jsonl | (no status) | ✓ v0.9.0 | Stale |
| `telemetry-skill-reference-sweep-plan.md` | telemetry-skill-reference-sweep | (no status) | ✓ v0.9.3 | Stale |
| `test-deletion-guardrail-plan.md` | test-deletion-guardrail | (no status) | ✓ v0.9.0 | Stale |

**Live plans (advance to v1.0 work):** `plugin-family-release-hardening-plan.md` (release 3 / v1.0.0), `post-release-publication-plan.md`.

**No plan exists for:** `timeline-events.md` (matches its orphan profile).

---

## C. M3 deferrals → M4 / v0.10 candidates

`docs/milestones/M3-pre-ga-hardening.md` § "Out of Scope" enumerated 8 deferred items. Status per item below.

| Item | Still deferred? | Spec? | Plan? | Sizing | Disposition |
|------|-----------------|-------|-------|--------|-------------|
| `/add:parallel` worktree-based parallel cycle execution | Yes | None | None | Large / Architectural | M4 candidate. No spec yet — needs shaping. |
| Routines/Loop integration adapter | Yes | None | None | Medium / external dep | Waiting for Anthropic Routines GA. M4. |
| Capability-based `/add:eval` skill | Yes | None | None | Medium | M4 candidate. Industry signal: capability evals trending. |
| `/add:cycle` rename (to `/add:arc`) | Yes | None | None | Small (rename) → coordinate with parallel-cycle redesign | M4 — defer until parallel work shapes. |
| Brownfield delta-spec mode | Yes | None | None | Small | v0.9.x or v0.10. Annotated as "low-cost addition." |
| Architect/Editor model-role rule | Yes | None | None | Tiny (one-paragraph) | v0.9.x docs pass — promotable now. |
| Cross-tool memory schema for `~/.claude/add/` | Yes | None | None | Medium / Architectural | v0.9 documentation, v0.10 implementation per milestone. |
| Governance maturity bands tied to autonomy ceilings | Yes | None | None | Medium / Architectural | M4 candidate — needs careful design. |
| Marketplace re-submission to official registry | External | None | None | External | Out of repo scope. |

**Observation:** none of the eight deferrals have shipped yet, and only one (Architect/Editor model-role rule) is small enough to ship without a spec. The others all need specs first.

---

## D. Plugin-family-review F-IDs not yet shipped

Cross-referenced against CHANGELOG and `git log`:

### D.1 Status table (all 20 findings)

| F-ID | Severity | Title | Target per spec | Shipped? | Where |
|-----:|---------:|-------|-----------------|----------|-------|
| F-001 | P0 | Marketplace manifest invalid (root `description`) | v0.8.1 | ✓ | v0.8.1 (`1b21842`) |
| F-002 | P0 | Codex install path mismatch | v0.8.1 | ✓ | v0.8.1 (`ef03c3d`) |
| F-003 | P1 | `--allow-test-rewrite` bypass | v0.8.1 | ✓ | v0.8.1 (`d079ee6`) |
| F-004 | P1 | Public Codex docs describe legacy prompts + wrong min version | v0.8.1 | ✓ | v0.9.0 (`ffafc6f`) |
| F-005 | P1 | Guardrail CI not wired | v0.8.1 → v1.0 | ✓ (CI), partial (release-blocking branch protection still pending) | v0.9.1 (`.github/workflows/guardrails.yml`); branch-protection enforcement still TBD per handoff |
| F-006 | P1 | ADD core remains Claude-shaped | v0.9.0 | ✗ | **Unshipped — M4 / v1.0** |
| F-007 | P1 | Adapter YAML is descriptive, not authoritative | v0.9.0 | ✗ | **Unshipped — M4 / v1.0** |
| F-008 | P1 | Codex marketplace/package format speculative | v0.9.0 | ✗ | **Unshipped — depends on Q-001** |
| F-009 | P1 | Codex skill policy metadata may not match local conventions | v0.9.0 | ✗ | **Unshipped — depends on Q-001 / pinned CLI** |
| F-010 | P1 | Hooks/config staged but not necessarily enabled | v0.9.0 | ✗ | **Unshipped — needs decision plugin-relative vs global merge** |
| F-011 | P1 | Claude rule distribution drift | v0.8.1 | ✓ | v0.9.1 (`tests/rule-parity/test-rule-parity.sh`) |
| F-012 | P1 | Hook feedback channel for prompt-injection warnings | v0.8.1 | ✗ | **Unshipped — currently downgraded ("warn-only" posture)** — gates secrets hard-block too |
| F-013 | P1 | Telemetry not emitted via shared writer; per-skill reference sweep | v0.9.0 | ✓ | v0.9.3 (`tests/telemetry-sweep/`) |
| F-014 | P1 | Secrets gate declarative-only | v0.9.0 | ✓ (executable scanner shipped); hard-block at `git push` deferred | v0.9.3 — partial (advisory only) |
| F-015 | P1 | Config schema + migration graph under-specified | v0.9.0 | ✗ | **Unshipped** — `core/schemas/config.schema.json` does not exist; migration graph patched ad-hoc in v0.9.4 |
| F-016 | P2 | Installer ownership manifest | v0.9.0 | ✗ | **Unshipped — installer still clobbers without manifest** |
| F-017 | P2 | `jq` dependency vs zero-dep claim | v0.8.1 | ✓ | v0.9.3 (Strategy A — `docs/runtime-dependencies.md`) |
| F-018 | P2 | Cache-discipline strict mode false-positive | v0.9.0 | ✓ | v0.9.1 (validator regex tightened) |
| F-019 | P2 | Version + command catalog drift | v0.9.0 | ✗ | **Unshipped** — generator does not exist; counts maintained by hand and rule-parity test |
| F-020 | P2 | Website/report/infographic stale | v1.0.0 | ✗ | **Unshipped** — partly addressed by extraction to `MountainUnicorn/getadd.dev`; site-metrics generator still pending |

### D.2 Unshipped F-IDs (the v1.0 hardening backlog)

**9 F-IDs unshipped** (one with partial coverage):

| F-ID | Severity | Sizing | Spec? | Has plan section? | GA priority |
|------|----------|--------|-------|-------------------|-------------|
| F-006 host-neutral kernel | P1 | **Architectural** | Yes (plugin-family § B) | Yes (plan TASK-103/104) | **Should** for v1.0 — methodology-credibility risk if Codex output keeps leaking Claude terms |
| F-007 adapter contract authoritative | P1 | **Large** | Yes (AC-010) | Yes (TASK-101/102) | **Should** for v1.0 — paired with F-006 |
| F-008 Codex packaging schema | P1 | Medium | Yes (AC-013, Q-001) | Yes (TASK-106) | **Must** for v1.0 — Codex install reliability |
| F-009 Codex policy metadata | P1 | Small | Yes (AC-014) | Yes (TASK-107) | **Must** for v1.0 |
| F-010 Codex hooks/config enablement | P1 | Medium | Yes (AC-015) | Yes (TASK-108) | **Must** for v1.0 — without this Codex hooks don't fire reliably |
| F-012 hook feedback channel | P1 | Medium | Yes (AC-007 v0.8.1) | Yes (TASK-010) | **Must** for v1.0 — gates secrets hard-block (F-014 follow-on) and prompt-injection escalation |
| F-015 config schema + migration graph | P1 | Medium | Yes (AC-017) | Yes (TASK-110) | **Must** for v1.0 — v0.9.4 migration gap is recurring evidence of need |
| F-016 installer ownership manifest | P2 | Medium | Yes (AC-016) | Yes (TASK-109) | **Should** for v1.0 — needed before official marketplace approval |
| F-019 version + command catalog drift | P2 | Medium | Yes (AC-021) | Yes (TASK-114) | **Should** for v1.0 — closely connected to release-materials open follow-ups |
| F-020 website/report/infographic stale | P2 | Small/Medium | Yes (AC-026) | (deferred to release 3) | **Could** for v1.0 — partially addressed by MountainUnicorn/getadd.dev split + post-release skill |

Plus the v1.0 release-confidence ACs that don't map 1:1 to F-IDs:

| AC | Title | Sizing | GA priority |
|----|-------|--------|-------------|
| AC-022 Real Claude install smoke in CI | Containerized | **Must** for v1.0 |
| AC-023 Real Codex install smoke in CI | Containerized | **Must** for v1.0 |
| AC-024 Guardrails release-blocking | Small (branch protection + workflow promotion) | **Must** for v1.0 |
| AC-025 Release evidence artifacts (matrix, smoke outputs, version map) | Small/Medium | **Should** for v1.0 |
| AC-026 Public docs regenerated from runtime catalog | Medium | **Could** for v1.0 — depends on F-019 |
| AC-027 Per-runtime security calibration in docs | Small | **Must** for v1.0 |
| AC-028 Tag-pinned/signed install URL (drop `curl main \| bash`) | Small | **Should** for v1.0 |

---

## E. Release-materials open follow-ups

`docs/release-materials.md` ends with four explicit candidate items, plus 2 surfaced in conversation arcs:

| Item | Spec? | Plan? | Owner | Sizing | Notes |
|------|-------|-------|-------|--------|-------|
| **Generate site metrics from `core/`** (`scripts/sync-site-metrics.py`) | None | None | Maintainer | Tiny | Touches `MountainUnicorn/getadd.dev/index.html` + `docs/skills.html` (in site repo). Closes F-019 partially. |
| **Generate skills page from `core/skills/`** | None | None | Maintainer | Small | Cousin of `/add:agents-md`. Closes F-019 + F-020 site portion. |
| **CHANGELOG → blog post draft (`/add:announce`)** | None | None | None | Small/Medium | Skill candidate. Closes the "blog cadence is uneven" gap in post-release-publication.md spec § 2. |
| **`/add:post-release` skill** | **YES** (`specs/post-release-publication.md`) | **YES** (`docs/plans/post-release-publication-plan.md`) | Maintainer | Medium (~2-3 days) | Already specced + planned; ripe for promotion. |
| **`scripts/install-claude.sh`** (surfaced 2026-04-30 per task brief) | None | None | None | Small | Public-user install path bypassing marketplace auth. Depends on `scripts/release.sh` (already shipped). Pairs with AC-028 (signed-install URL). |
| **GitHub social-preview API research / Playwright upload tool** (surfaced in v0.9.3 cleanup) | None | None | None | Small | Closes the only remaining `manual` item in `docs/release-materials.md` § A. Spec/research needed first to confirm API exists. |

---

## F. Orphans — proposed work that should be retired

### F.1 `specs/timeline-events.md` — RETIRE / SUPERSEDE

- **Status:** Draft, target v0.5.0 (already shipped without it)
- **Created:** 2026-02-21 — drafted ~9 weeks ago
- **Defines:** `.add/timeline.json` append-only event log
- **Reality:** dashboard skill (`core/skills/dashboard/SKILL.md`) sources timeline data from git history, milestone files, retros, and config; no `.add/timeline.json` exists or is needed. Telemetry JSONL (v0.9.0) covers the structured-events use case for cost/audit.
- **Recommendation:** flip Status to **Superseded**, body unchanged, add a one-line "Superseded by: telemetry-jsonl + dashboard skill's existing data sources." Mirror the `plugin-installation-reliability` retirement model.

### F.2 Stale plans for fully-shipped specs

20 plans, 17 of which point at fully-shipped specs and never had Status set or were left at "In Progress" / "Draft" after shipping:

- `agents-md-sync-plan.md`, `auto-changelog-plan.md`, `branding-system-plan.md`, `cache-discipline-plan.md`, `image-gen-detection-plan.md`, `infographic-generation-plan.md`, `jq-dependency-declaration-plan.md`, `learning-library-search-plan.md`, `legacy-adoption-plan.md`, `project-dashboard-plan.md`, `prompt-injection-defense-plan.md`, `retro-template-automation-plan.md`, `secrets-handling-plan.md`, `secrets-scanner-executable-plan.md`, `telemetry-jsonl-plan.md`, `telemetry-skill-reference-sweep-plan.md`, `test-deletion-guardrail-plan.md`

**Recommendation:** sweep — append `**Status:** Complete (shipped vX.Y.Z)` to each plan header. No deletion, since plans are useful historical record. ~17 single-line edits.

### F.3 No genuine orphan items in release-materials follow-ups

The four open follow-ups in `release-materials.md` all reflect current priorities (release publication is on the active table). None to retire.

---

## G. Dependency graph

```mermaid
graph TD
  rs[scripts/release.sh<br/>SHIPPED v0.7.2]
  rm[docs/release-materials.md<br/>SHIPPED v0.9.4]
  q1[Q-001 Codex marketplace schema<br/>OPEN]

  rs --> ic[scripts/install-claude.sh<br/>UNSHIPPED]
  rm --> pr[/add:post-release skill<br/>SPEC + PLAN]
  rm --> announce[/add:announce skill<br/>UNSPECCED]

  pr --> sm[site-metrics generator<br/>UNSPECCED]
  pr --> sg[skills-page generator<br/>UNSPECCED]

  q1 --> f8[F-008 Codex packaging schema]
  q1 --> f9[F-009 Codex policy metadata]
  q1 --> f10[F-010 Codex hooks enablement]
  q1 --> ac031[AC-031 Codex marketplace.json companion<br/>codex-native-skills deferral]

  f7[F-007 Adapter contract authoritative]
  f7 --> f6[F-006 Host-neutral kernel]
  f6 --> f19[F-019 Command catalog generator]
  f19 --> sg
  f19 --> sm

  f12[F-012 Hook feedback channel]
  f12 --> f14b[F-014 Secrets gate hard-block<br/>currently advisory]
  f12 --> piscale[Prompt-injection escalation<br/>warn-only → blocking]

  f15[F-015 Config schema + migration graph]
  f16[F-016 Installer ownership manifest]
  f16 --> uninstall[/add:uninstall flow]

  ac35[AC-035 Containerized Codex CI]
  ac22[AC-022 Real Claude install smoke]
  ac23[AC-023 Real Codex install smoke]
  ac35 --> ac23
  ac24[AC-024 Guardrails release-blocking]
  ac24 --> ac22
  ac24 --> ac23

  ac28[AC-028 Signed install URL]
  rs --> ac28
  ac28 --> ic
```

### Dependency table (text form)

| Unshipped item | Hard depends on | Soft depends on |
|----------------|-----------------|-----------------|
| `/add:post-release` | `release-materials.md` (✓ shipped) | `/add:announce` (parallel) |
| `/add:announce` | CHANGELOG (✓ exists) | none |
| Site metrics generator | `core/skills/`, `core/rules/`, `core/templates/` (✓ exist); MountainUnicorn/getadd.dev write access | F-019 catalog generator |
| Skills page generator | `core/skills/` (✓) | F-007 adapter contracts; F-019 catalog generator |
| `scripts/install-claude.sh` | `scripts/release.sh` (✓), AC-028 (signed install URL) | None |
| F-006 host-neutral kernel | F-007 adapter contracts authoritative | None |
| F-007 adapter contracts | None | F-019 catalog generator builds on it |
| F-008 Codex marketplace schema | Q-001 resolution (open) | F-009, F-010 |
| F-009 Codex policy metadata | Q-001, F-008 | None |
| F-010 Codex hooks/config | Q-001, F-008 | F-012 (feedback channel) |
| F-012 hook feedback channel | None | Gates secrets hard-block + injection blocking |
| F-014 secrets hard-block at push | F-012 | None |
| F-015 config schema + migration graph | None | F-007 contracts inform schema layout |
| F-016 installer ownership | None | Pairs with F-008 install-shape decisions |
| F-019 command catalog | F-007 (clean source) | Site generators build on top |
| F-020 site assets stale | F-019 | `/add:post-release` walks fix |
| AC-022/AC-023 install smoke | Containerized runners (infra), AC-024 | F-008/F-009/F-010 close enough to be smoke-testable |
| AC-024 guardrails release-blocking | branch protection on main (one-shot setup) | F-005 ✓ already wired |
| AC-028 signed install URL | `scripts/release.sh` ✓ | AC-022/AC-023 valuable to gate the install URL |
| AC-031 codex-native-skills marketplace.json | Q-001 | F-008 |
| AC-035 containerized Codex CI | AC-023 | F-010 |

---

## H. Promotion candidates — what should advance NOW

Filtered by: small/clean surface, AC already documented, blocks no other work or unblocks several things, has spec or plan or both.

### H.1 Tier 1 — Promote immediately to v0.10 / v1.0 candidate set

| # | Item | Source | Sizing | Why now |
|--:|------|--------|--------|---------|
| 1 | **`/add:post-release` skill** | `specs/post-release-publication.md` (Draft) + plan | Medium (~2-3d) | Spec + plan exist with 32 ACs and 5 open questions; fixture parser approach is straightforward; immediate ROI on every future release; dog-foodable on v0.10.0 itself (AC-041). |
| 2 | **Frontmatter sweep — flip Draft → Complete on 9 shipped specs** | this report § A.2 | Tiny (~30min) | Pure docs hygiene; clears confusion in `/add:roadmap`, dashboard, future contributors. |
| 3 | **Stale plans Status closeout** | this report § F.2 | Tiny (~30min) | Same hygiene pass — append "Status: Complete (vX.Y.Z)" to 17 plans. |
| 4 | **Retire `specs/timeline-events.md`** | this report § F.1 | Tiny | Either Supersede (recommended) or delete. Removes a draft that's accreted ~9 weeks of staleness. |
| 5 | **Architect/Editor model-role rule** | M3 deferral § C | Tiny (one paragraph in a rule) | Smallest M3 deferral; was explicitly tagged "v0.9.1 docs pass" and never caught up; un-blocks no other work but is a free win. |
| 6 | **`/add:announce` (CHANGELOG → blog post draft)** | release-materials open follow-up | Small/Medium | Closes the most-cited post-release pain (uneven blog cadence). Dependency-free. Spec needed first. |

### H.2 Tier 2 — Approve for next milestone (M4 / v0.9.x → v1.0)

| # | Item | Source | Sizing | Why next |
|--:|------|--------|--------|---------|
| 7 | **F-015 config schema + migration graph validator** | F-ID, AC-017 | Medium | v0.9.4 hotfix proved migrations drift silently; this is recurring pain, has clean spec, clean test surface. |
| 8 | **AC-024 guardrails release-blocking** (branch protection + release-script gate) | plugin-family AC | Small | One-shot setup; CI already passes 93/93 tests in `.github/workflows/guardrails.yml`. |
| 9 | **AC-028 signed-install URL + `scripts/install-claude.sh`** | plugin-family AC + conversation arc | Small | `scripts/release.sh` is shipped + signed; building a tag-pinned `curl ... \| bash` against signed tags is straightforward and closes the public-user install gap. |
| 10 | **Site-metrics generator + skills-page generator** | release-materials follow-ups + F-019 partial | Small (each) | Touches MountainUnicorn/getadd.dev only. Removes the most-cited site drift. Should land before any Major release. |

### H.3 Tier 3 — Architectural, needs spec/shaping before promotion

| # | Item | Why architectural |
|--:|------|--------------------|
| 11 | F-006 host-neutral kernel + F-007 adapter contracts | Touches every skill body + scripts/compile.py + adapter.yaml; needs careful staging or it will overrun any milestone. |
| 12 | F-008/F-009/F-010 Codex packaging coherence | Blocked on Q-001 (Codex marketplace schema). Needs research first. Needs a containerized Codex runner (AC-035) for proof. |
| 13 | F-012 hook feedback channel | Needs research per runtime; gates downstream blocking gates (F-014, prompt-injection escalation). |
| 14 | `/add:parallel` worktree-based parallel cycle | M4 candidate per M3 milestone; large surface; couples to `/add:cycle` rename. |
| 15 | Cross-tool memory schema for `~/.claude/add/` | Architectural. v0.9 = doc, v0.10 = implementation per M3 milestone. |
| 16 | Capability-based `/add:eval` | M4 candidate; industry signal exists; needs spec. |

---

## I. Cross-cuts and observations for synthesis

1. **The "Draft" frontmatter problem is documentation drift, not unimplemented work.** v0.9.0 shipped 7 features that are still marked Draft because the maintainer optimized for releasing-and-moving-on. A single hygiene PR closes it.

2. **The plugin-family-release-hardening spec is the v1.0 spine.** It already encodes the GA acceptance criteria (AC-022 → AC-028) and the v1.0 deliverables list. A v1.0 milestone document can be a re-arrangement of this spec rather than a from-scratch shaping exercise.

3. **The biggest GA-blocker by user-facing risk is Codex.** F-008/F-009/F-010 blocked on Q-001 + AC-023 containerized smoke means today's Codex install path is operational but not provably correct. That's the single largest credibility risk for "v1.0 is GA."

4. **F-012 hook feedback channel is a force multiplier.** Closing it unlocks F-014 hard-block (currently advisory), prompt-injection escalation from warn-only to blocking, and consistent guardrail UX across runtimes. Not visible in any single spec but appears as a gate in three places.

5. **Release-materials.md is the missing connective tissue.** Once `/add:post-release` ships, four other open follow-ups (site metrics, skills page, blog draft, social-preview upload) become walkable items in a single skill rather than separate specs.

6. **No spec exists for several deferred M3 items.** `/add:parallel`, `/add:eval`, `/add:cycle` rename, brownfield delta-spec mode, governance maturity bands, cross-tool memory schema — all need shaping before they can be promoted. This is shaping work the v1.0 synthesis should explicitly schedule, not just list.

7. **`timeline-events.md` is the only true orphan.** Every other Draft spec has a clear path forward; this one was never integrated and the dashboard works without it.

8. **Plan files are underused as artifacts.** 17 of 20 plans ship without a Status field or with a stale Status. A schema enforcement (or a hygiene rule in `/add:plan`) would prevent the next wave of stale plans.

---

## J. Recommended v1.0 milestone shape (input to synthesis)

If Swarm 3 confirms market urgency for GA inside the next two months, a viable milestone scope-cut:

**v1.0 GA — release-confidence focus (8–10 weeks)**

- v0.9.5 (hygiene, ~1 day): frontmatter sweep + plan closeout + retire timeline-events + Architect/Editor rule
- v0.9.6 (~1 week): `/add:post-release` ships; dog-foods on its own release
- v0.9.7 (~2 weeks): `/add:announce` + site-metrics generator + skills-page generator + AC-024 release-blocking + AC-028 install-claude.sh
- v0.10.0 (~3 weeks): F-015 config schema + migration validator; F-016 installer ownership manifest; F-012 hook feedback channel research + implementation
- v0.11.0 (~3 weeks): F-008/F-009/F-010 Codex packaging coherence (after Q-001 resolution); AC-035 containerized Codex smoke; AC-023 real Codex install smoke
- v1.0.0 GA (~1 week): AC-022 real Claude install smoke; AC-025 release evidence artifacts; AC-027 per-runtime security calibration; promote beta → GA

If the synthesis instead defers F-006/F-007 host-neutral kernel to v1.1 (Architectural, methodology-driven, post-GA), the v1.0 path is straightforward. If F-006/F-007 must land for v1.0, add 4-6 weeks for a dedicated architectural cycle and consider re-arranging `runtimes/*/adapter.yaml` to be authoritative before the install-smoke ACs lock in their assumptions.

---

## K. Per-finding deep-dives (unshipped F-IDs)

The table in § D.2 is the at-a-glance view; this section captures the AC numbers, exact files touched, and proven-shape evidence for each unshipped finding so the synthesis step can budget without re-reading the source spec.

### K.1 F-006 — host-neutral kernel

- **Spec ACs:** AC-011 (neutral path variables `${ADD_HOME}`, `${ADD_RUNTIME_ROOT}`, `${ADD_USER_LIBRARY}`), AC-012 (split host-neutral methodology vs runtime overlays)
- **Plan tasks:** TASK-103 (introduce path vars), TASK-104 (runtime overlays), TASK-105 (clean Codex output of unapproved Claude terms)
- **Evidence of need:** Codex-output `~/.claude/add/`, `/add:` command syntax, Claude tool names appear in generated `dist/codex/` skills today (see TC-006). Smoke test would scan `dist/codex/.agents/skills/*` for unapproved Claude tokens.
- **Sizing:** Architectural — touches every skill body (27), every rule (19), `scripts/compile.py`, both adapter YAMLs, plus runtime-specific overlay directories (currently don't exist).
- **Risk if unshipped:** mixed-toolchain teams reading Codex output see Claude-shaped instructions and lose trust ("ADD is parochial"). Direct contradiction of agents-md-sync narrative.
- **Recommended cut for v1.0:** path variable introduction (AC-011) is achievable as a mechanical compile-time substitution; full overlay split (AC-012) likely v1.1.

### K.2 F-007 — adapter contracts authoritative

- **Spec ACs:** AC-010 (compile + installer read adapter contract; drift tests fail when they disagree)
- **Plan tasks:** TASK-101 (define schema), TASK-102 (compiler consumes adapter contract)
- **Evidence of need:** `runtimes/*/adapter.yaml` files exist but `scripts/compile.py` hard-codes output paths and asset lists; modifying adapter.yaml has no compile-time effect.
- **Sizing:** Large.
- **Companion artifact:** `core/schemas/adapter.schema.json` (does not exist).
- **Recommended cut for v1.0:** stage as a pre-req for F-019 catalog generator. If catalog generator targets the adapter as input-of-truth, F-007 ships as natural infrastructure.

### K.3 F-008 — Codex marketplace/package format

- **Spec ACs:** AC-013 (Codex packaging matches pinned CLI's actual marketplace conventions)
- **Plan tasks:** TASK-106 (resolve Codex packaging format)
- **Open question:** Q-001 — `.codex-plugin/plugin.json` vs `.agents/plugins/marketplace.json` vs `plugin.toml` vs combination during transition. **Owner: Codex runtime owner. Target: v0.9.0** (already missed).
- **Current state:** `dist/codex/plugin.toml` ships but is speculative; no `.codex-plugin/plugin.json`; no `.agents/plugins/marketplace.json`. v0.9.0 codex-native-skills shipped 33/35 ACs because AC-031 (marketplace.json companion) was deferred for exactly this reason.
- **Dependency for:** F-009, F-010, AC-031, AC-023 (smoke), AC-035 (containerized CI).
- **Sizing:** Medium once Q-001 is resolved; Large if research takes time.

### K.4 F-009 — Codex skill policy metadata

- **Spec ACs:** AC-014 (`agents/openai.yaml` shape matches pinned Codex convention; high-leak skills explicit-only)
- **Plan tasks:** TASK-107 (validate Codex skill policy metadata + emit correct shape)
- **Current state:** `runtimes/codex/skill-policy.yaml` does not exist (referenced in spec § 4 data model but not yet introduced); `agents/openai.yaml` per-skill files emit but unvalidated.
- **Sizing:** Small once F-008 resolves the schema.

### K.5 F-010 — Codex hooks/config enablement

- **Spec ACs:** AC-015 (hooks installed plugin-relative + enabled OR safely merged into global config with backup + detection + clear messaging)
- **Plan tasks:** TASK-108 (decide plugin-relative vs safe global merge; test both paths)
- **Current state:** hook scripts staged at `dist/codex/.codex/hooks/`; `dist/codex/.codex/hooks.json` written; `[features] codex_hooks = true` in `dist/codex/.codex/config.toml` per AC-019. Whether they actually fire in a fresh Codex install is unproven.
- **Dependency:** Q-001 (plugin-relative path resolution differs by manifest format), F-012 (feedback channel).
- **Sizing:** Medium.

### K.6 F-012 — hook feedback channel

- **Spec ACs:** AC-007 (originally v0.8.1; downgraded — see CHANGELOG)
- **Current state:** `core/rules/injection-defense.md` and `runtimes/claude/hooks/posttooluse-scan.sh` ship; events go to `.add/security/injection-events.jsonl`. The "warn-only" posture in v0.9.0 explicitly noted this needs F-012 to escalate to blocking. Same constraint blocks v0.9.3's secrets advisory hook from becoming a blocking gate.
- **Open question per spec:** Q-003 — which hook feedback channels are guaranteed visible in current Claude + Codex versions.
- **Sizing:** Medium; research-heavy. Pure documentation if the answer is "both runtimes lack a reliable channel" + a calibrated docs claim per AC-027.
- **Why it matters disproportionately:** unlocks 2 downstream Must-have GA items (F-014 hard-block, prompt-injection blocking). Closing F-012 closes 3 specs' partial-state at once.

### K.7 F-014 (residual) — secrets gate hard-block at `git push`

- **Current state:** v0.9.3 shipped `core/lib/scan-secrets.sh` + `core/security/secret-patterns.json` + Gate 4.6 in `/add:verify` + Step 1.5 of `/add:deploy`. The `PreToolUse` hook on `Bash` matching `git push` runs the scanner but emits findings to stderr WITHOUT blocking — explicitly deferred to v0.10 pending F-012.
- **Sizing:** Small once F-012 resolves.

### K.8 F-015 — config schema + migration graph

- **Spec ACs:** AC-017 (schema validates `.add/config.json`; migration graph tests prove every supported version can migrate to `core/VERSION`)
- **Plan tasks:** TASK-110 (add `core/schemas/config.schema.json` + migration graph tests)
- **Evidence of need:** v0.9.4 hotfix patched 5 missing migration hops at once (`0.8.0 → 0.8.1`, `0.8.1 → 0.9.0`, `0.9.0 → 0.9.1`, `0.9.1 → 0.9.2`, `0.9.2 → 0.9.3`, `0.9.3 → 0.9.4`). The version-bump checklist in maintainer memory now lists `core/templates/migrations.json` as a required step — but a validator would catch the gap automatically.
- **Sizing:** Medium.
- **Adjacent value:** `core/schemas/` already has `skill-frontmatter.schema.json` and `rule-frontmatter.schema.json`; adding `config.schema.json` is consistent with prior shape.

### K.9 F-016 — installer ownership manifest

- **Spec ACs:** AC-016 (ownership manifest, no clobbering, namespace agents, `--dry-run`, uninstall only owned files)
- **Plan tasks:** TASK-109 (`scripts/install-codex.sh` writes `dist/codex/ownership.json`; backup overwritten files; `--dry-run`; uninstall only owned files)
- **Current state:** `scripts/install-codex.sh` deletes/replaces `add-*` skills and generic agents without an ownership manifest. No `--dry-run`, no uninstall.
- **Sizing:** Medium.
- **Why it's GA-relevant:** without uninstall + `--dry-run`, users can't safely test the install or back out. Required before any official marketplace approval.

### K.10 F-019 — version + command catalog drift

- **Spec ACs:** AC-021 (catalog generated from source-of-truth; renders Claude syntax, Codex syntax, implicit-dispatch policy, risk level, skill count consistently across README, marketplace metadata, runtime AGENTS/CLAUDE docs, website inputs)
- **Plan tasks:** TASK-114 (`scripts/generate-command-catalog.py` writes single source for counts, syntax, risk, dispatch, write behavior)
- **Current state:** counts maintained by hand. v0.9.1 `tests/rule-parity/test-rule-parity.sh` enforces rule count automatically; skills + templates counts are manual. Site metrics, skills page, README — all hand-edited. Recurring drift problem: see v0.9.1 stale-references commit (`59d39ea`), v0.9.3 social-preview drift, the entire `release-materials.md` § B "Counts in tree diagrams" item.
- **Sizing:** Medium.
- **Cousin:** `/add:agents-md` (shipped) — same generator-from-source pattern.

### K.11 F-020 — website/report/infographic stale

- **Spec ACs:** AC-026 (public docs + site assets regenerated from runtime catalog)
- **Plan section:** Release 3 / v1.0.0
- **Partial closure:** website extracted to `MountainUnicorn/getadd.dev` (v0.9.0 change); `docs/social-preview.svg` cleaner pill (v0.9.3, `2282670`); `docs/runtime-dependencies.md` introduced (v0.9.3).
- **Remaining:** `docs/skills.html` page generator (cited in spec § 4 + release-materials.md § C), site metrics bar generator (release-materials.md follow-up), infographic version refs auto-bump.
- **Sizing:** Small (each piece independently); collectively Medium.

### K.12 AC-022/AC-023 — real install smoke in CI

- **AC-022 (Claude):** marketplace validation/install smoke + key skill/command discoverability check post-install.
- **AC-023 (Codex):** marketplace/plugin install smoke against pinned CLI + skill discovery + explicit-only blocking + agent registration + hook registration + one dry workflow.
- **Current state:** `tests/codex-install/test-install-paths.sh` exists (F-002 regression smoke) but uses temp `CODEX_HOME` without Codex CLI; doesn't actually run Codex.
- **Infrastructure dependency:** containerized runner with each runtime CLI installed. Container infra does not exist in `.github/workflows/`.
- **Sizing:** Medium-Large depending on how hardened the container is.

### K.13 AC-024 — guardrails release-blocking

- **Current state:** `.github/workflows/guardrails.yml` runs 12 jobs / 93 tests on every PR + push to main (per v0.9.1 + handoff). Branch protection on `main` requiring those checks before merge is **not** known to be configured (per handoff: "should be branch-protected before GA").
- **Sizing:** Tiny — `gh repo edit` / repo settings change; release.sh can grow a `gh run list --branch main --limit 1 --json conclusion` precondition.

### K.14 AC-025 — release evidence artifacts

- **What it asks:** supported runtime matrix, known limitations, install smoke outputs, command catalog, version map, migration coverage shipped as release artifacts.
- **Current state:** none of these are generated; CHANGELOG narrates them in prose.
- **Dependency:** AC-021 catalog (F-019), AC-022/AC-023 smoke outputs.

### K.15 AC-027 — per-runtime security calibration

- **What it asks:** docs explicitly state per-runtime limitations (e.g., Codex hooks fire only on Bash; missing feedback channels degrade specific claims).
- **Current state:** `core/knowledge/threat-model.md` (v0.9.0) documents this in part; `dist/codex/.codex/hooks/README.md` per AC-025 of codex-native-skills documents Codex-vs-Claude hook substitution. A unified runtime-capability matrix in release notes does not exist.
- **Sizing:** Small (documentation pass).

### K.16 AC-028 — signed-install URL

- **What it asks:** tag-pinned installs OR checksum/signed-release verification for public install scripts; `curl main | bash` is not the recommended stable install path.
- **Current state:** the `claude plugin install add@add-marketplace` path goes through marketplace; `scripts/install-codex.sh` is a local install path; **no public `scripts/install-claude.sh` exists** for the curl-pipe pattern.
- **Pairs with:** the conversation-arc item "scripts/install-claude.sh" (surfaced 2026-04-30). Shipping the install script + tag-pinned URL closes both at once.

---

## L. v0.9.0 deferred ACs (codex-native-skills) cross-reference

`specs/codex-native-skills.md` was scored 33/35 in v0.9.0. The 2 deferrals:

| AC | Title | Reason deferred | Where it lives in v1.0 backlog |
|----|-------|------------------|-------------------------------|
| AC-031 | `marketplace.json` companion at repo root for Codex install | Codex marketplace schema unresolved (Q-001) | F-008 group |
| AC-035 | New CI job runs emitted runtime through real Codex CLI install (pinned, containerized) | Containerized CI infra not built | AC-023 group |

Both sit downstream of Q-001. Solving Q-001 unblocks both.

---

## M. Specs that don't exist but should (shaping debt)

The synthesis should distinguish "specced-but-unshipped" from "unspecced." This is the unspecced bucket:

| Item | Source | Notes |
|------|--------|-------|
| `/add:parallel` | M3 deferral | Worktree-based parallel cycle execution. M4 candidate per M3 milestone. **No spec.** |
| `/add:eval` | M3 deferral | Capability-based skill. M4 candidate. **No spec.** |
| `/add:cycle` rename | M3 deferral | Coupled to parallel-cycle redesign. **No spec.** |
| Brownfield delta-spec mode | M3 deferral | "Low-cost addition." **No spec.** |
| Architect/Editor model-role rule | M3 deferral | One-paragraph rule. **No spec needed.** |
| Cross-tool memory schema | M3 deferral | `~/.claude/add/` layout for Claude-vs-Codex sharing. **No spec.** |
| Governance maturity bands tied to autonomy ceilings | M3 deferral | M4 candidate. **No spec.** |
| Routines/Loop integration adapter | M3 deferral | Waiting for Anthropic Routines GA. **No spec — external dep.** |
| `/add:announce` | release-materials | CHANGELOG → blog post draft. **No spec.** |
| Site metrics generator | release-materials | `scripts/sync-site-metrics.py`. **No spec.** |
| Skills page generator | release-materials | `docs/skills.html` from `core/skills/`. **No spec.** |
| `scripts/install-claude.sh` | conversation arc 2026-04-30 | Public-user install bypassing marketplace auth. **No spec.** |
| GitHub social-preview API / Playwright | conversation arc | Closes the only fully-manual item in `release-materials.md` § A. **No spec — research first.** |

13 unspecced items. The synthesis should explicitly schedule shaping cycles for the items that cross the v1.0 threshold (most likely `/add:announce`, `scripts/install-claude.sh`, site/skills generators).

---

## N. Specs vs reality discrepancies (audit table)

For traceability — every place where the spec corpus contradicts the shipped reality:

| Spec | Frontmatter says | Reality | Severity |
|------|------------------|---------|----------|
| `agents-md-sync.md` | Draft | Shipped v0.9.0 (36/36 ACs) | Documentation drift |
| `cache-discipline.md` | Draft | Shipped v0.9.0 (24/24 incl. closes via #11) | Documentation drift |
| `codex-native-skills.md` | Draft | Shipped v0.9.0 (33/35 ACs) | Documentation drift + 2 deferrals to track |
| `prompt-injection-defense.md` | Draft | Shipped v0.9.0 (30/30 ACs) | Documentation drift |
| `secrets-handling.md` | Draft | Shipped v0.9.0 (23/24 ACs); AC-019 unblocked by PR #6 in v0.9.2 | Documentation drift; verify AC-019 |
| `telemetry-jsonl.md` | Draft | Shipped v0.9.0 (30 ACs) | Documentation drift |
| `test-deletion-guardrail.md` | Draft | Shipped v0.9.0 (25 ACs); F-003 closed v0.8.1 | Documentation drift |
| `jq-dependency-declaration.md` | Draft | Shipped v0.9.3 | Documentation drift |
| `secrets-scanner-executable.md` | Draft | Shipped v0.9.3; hard-block deferred to v0.10 (F-012 dependency) | Documentation drift + 1 deferral |
| `project-dashboard.md` | Implementing | Skill ships in `core/skills/dashboard/` — clearly Complete | Documentation drift |
| `telemetry-skill-reference-sweep.md` | Shipped (Path A) | Shipped v0.9.3 — should read "Complete" | Minor wording |
| `timeline-events.md` | Draft (v0.5.0) | Never implemented; dashboard works without it | **Orphan — Supersede** |

Single sweep PR resolves rows 1-11; row 12 needs the supersede note.

---

*End of Swarm 2 report. Compiled from `specs/*.md` (23 files), `docs/plans/*.md` (20 files), `docs/milestones/M3-pre-ga-hardening.md`, `docs/milestones/M3-marketplace-ready.md`, `docs/release-materials.md`, `CHANGELOG.md`, `.add/handoff.md`, and full `git log` since v0.7.0.*

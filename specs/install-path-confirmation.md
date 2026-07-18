# Spec: Install-Path Confirmation — v0.10.0 GA Release Candidate

**Version:** 0.1.0
**Created:** 2026-07-18
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Release:** v0.10.0
**Milestone:** docs/milestones/v1.0-ga.md (consolidates the planned v0.10.0 + v0.11.0 install-smoke scope into one RC)
**Depends-on:** `runtimes/codex/adapter.yaml` (Codex CLI pin), `scripts/release.sh`, `.github/workflows/` guardrail suite

## 1. Overview

v0.9.11's CI proves the artifact is internally consistent (compile-drift, schema, guardrails, rule-boundary) but never installs it. Every consumer-environment defect to date — the v0.9.11 stale-rules drift reported by @tdmitruk, the v0.8.x marketplace cache issues — was invisible to CI because CI only inspects the repo, not the install path.

v0.10.0 is the "install path confirmed" release candidate for GA. It closes GA promotion criteria #1–#4 from `docs/milestones/v1.0-ga.md` and produces the verified artifact that gets submitted to the marketplace (criterion #5). Sequencing decision (2026-07-18): **build and pass install smoke BEFORE marketplace submission**, so the one external, unaccelerable gate reviews an artifact whose install path is machine-verified — not after, as the original milestone plan bundled it with v1.0.0. On approval, v1.0.0 becomes the promotion tag (`/add:promote --execute --target ga`) with little to no new code.

Deliberately a hardening release: no new methodology surface, no new skills beyond what CI verification requires.

### User Story

As the ADD maintainer preparing GA, I want CI to install the plugin exactly the way a new user does — marketplace install on Claude Code, curl installer on a pinned Codex CLI — and drive it far enough to prove it works (`/add:init` produces `.add/config.json`, skills discoverable), so that the marketplace submission and the v1.0.0 GA claim rest on machine-verified evidence instead of the maintainer's warm environment.

## 2. Acceptance Criteria

### A. Claude install smoke (milestone AC-022, GA criterion #2)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | New workflow `.github/workflows/install-smoke-claude.yml` runs a containerized Claude Code runner (headless, `claude -p` or equivalent non-interactive mode). | Must |
| AC-002 | The job installs ADD via the real marketplace path (`claude plugin install add@add-marketplace` against the repo's marketplace source), not by copying `plugins/add/` into place. | Must |
| AC-003 | The job runs `/add:init --quick` in a scratch project and asserts `.add/config.json` exists and validates against `core/schemas/` (config schema). | Must |
| AC-004 | The job asserts skill discovery: the installed plugin exposes the expected 27 namespaced skills (count sourced from the compiled manifest, not hard-coded). | Must |
| AC-005 | The job asserts the SessionStart `load-rules.sh` hook fires and loads maturity-appropriate rules (regression guard for the v0.9.11 stale-rules class of defect). | Should |
| AC-006 | Smoke runs on every PR to `main` and on release tags; a red smoke blocks release. | Must |
| AC-007 | Auth strategy documented in the workflow header (API key via repo secret; job skips gracefully with a loud annotation when the secret is absent, e.g. fork PRs). | Must |

### B. Codex install smoke + containerized runner (milestone AC-023 + AC-035, GA criterion #2; open question Q-001)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-010 | Docker image (Dockerfile under `tests/smoke/codex/`) with a pinned Codex CLI version installed from the official distribution channel. | Must |
| AC-011 | **Re-baseline first (Q-001):** `runtimes/codex/adapter.yaml` `codex_cli_version` / `min_codex_version` updated from 0.122.0 to a current Codex CLI release; compile output re-verified against it. Any breakage is fixed or documented in the capability matrix before the smoke is marked green. | Must |
| AC-012 | New workflow `.github/workflows/install-smoke-codex.yml` runs the image, executes the public curl installer (the same command getadd.dev documents) into `~/.codex/skills/`, and asserts the `add-*` skills land. | Must |
| AC-013 | The job runs `/add-init` (Codex naming convention) and asserts `.add/config.json` is produced, plus skill discovery for the compiled skill set. | Must |
| AC-014 | The job asserts `dist/codex/AGENTS.md` content is picked up by the pinned CLI (smoke-level: session starts without error and ADD guidance is present). | Should |
| AC-015 | Same trigger/blocking semantics as AC-006. | Must |
| AC-016 | Image rebuild is pinned and reproducible (CLI version build-arg sourced from `adapter.yaml`, so the pin lives in one place). | Must |

### C. Release-blocking guardrails (GA criterion #1)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-020 | Branch protection on `main` requires compile-drift, schema-check, guardrails, rule-boundary-check, and both install smokes as passing status checks. | Must |
| AC-021 | `scripts/release.sh` refuses to tag when the head commit's required checks are not green (`gh api` check-runs query), closing the gap where a release could be cut from an unverified commit. | Must |
| AC-022 | The protection setup is documented in `docs/release-signing.md` (or a sibling runbook section) so it is reproducible, since branch-protection config lives outside the repo. | Should |

### D. Per-runtime capability matrix (milestone AC-027, GA criterion #3)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-030 | A capability matrix (Claude vs Codex: enforcement vs warn-only per feature — injection scanning, hooks, telemetry, stale-rules distribution) exists as a generated or maintained artifact under `docs/`, sourced from `adapter.yaml` truth where possible. | Must |
| AC-031 | The release-notes flow (release.sh or checklist) includes the matrix in every release from v0.10.0 onward. | Must |
| AC-032 | `SECURITY.md` reframed to reference the matrix for what is advisory-only on Codex (honest-docs fallback for F-012, per milestone D3). | Should |

### E. Release-evidence bundle (milestone AC-025, GA criterion #4)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-040 | A script (`scripts/release-evidence.sh` or python sibling) assembles: supported-runtime matrix, known limitations, install-smoke run links/outputs, command catalog snapshot, version map, migration-chain coverage check. | Must |
| AC-041 | The bundle is attached to (or linked from) the GitHub release for v0.10.0 and every release after. | Must |
| AC-042 | Migration-chain coverage check asserts `core/templates/migrations.json` has an unbroken hop chain from the earliest supported version to the release being cut (regression guard for the v0.8.1→v0.9.3 broken-chain incident). | Must |

### F. Verification tasks folded into this release

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-050 | D6 telemetry check (time-boxed 1 hr): confirm `.add/telemetry/{date}.jsonl` populates on dog-food; record result in the milestone doc. If broken, file a finding — fix is NOT in v0.10.0 scope unless trivial. | Must |
| AC-051 | Milestone doc updated: criteria #1–#4 checked off with evidence links; plan divergence (v0.10/v0.11 consolidation, submit-before-promote sequencing) recorded as a decision entry. | Must |

## 3. Sequencing & Exit

1. Ship v0.10.0 with all Must ACs green.
2. Submit v0.10.0's artifact to the official Claude Code marketplace registry (GA criterion #5 — external gate; latency not under our control).
3. Fixes surfaced by smoke or review land as v0.10.x patches; v1.0.0 is reserved for the promotion release.
4. On marketplace approval: v1.0.0 — `/add:promote --execute --target ga`, GA release notes per milestone lines 171-179.

## 4. Out of Scope (deferred, tracked elsewhere)

- Codex injection-scanner parity / F-012 hook-feedback adapter — AC-027 honest matrix is the GA answer (milestone D3 fallback); parity revisits in v1.1.
- `/add:post-release` skill (`specs/post-release-publication.md`) — the evidence bundle here is a script, not the full skill.
- `docs/methodology.md` (D5), catalog generator (F-019), host-neutral kernel (F-006/F-007), workflow lifecycle pilot — v1.1 / M4.
- Telemetry emission fixes beyond the AC-050 check.

## 5. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Codex re-pin (0.122 → current) breaks compiled output | Medium-High | Smoke red on first run | That is the point — fix or document in capability matrix before submission; time-box to 3 days before descoping Codex smoke to warn-only status in the matrix |
| Headless Claude Code marketplace install not cleanly scriptable in CI | Medium | AC-002 blocked | Fallback: install from the repo's marketplace definition via `--plugin-dir` equivalent, documented as a known deviation in the evidence bundle |
| Marketplace review latency exceeds patch cadence | High | GA date slips | Accepted: submission is external; v0.10.x continues under beta rules meanwhile |
| CI secrets (Anthropic API key) unavailable on fork PRs | High | Smoke skipped on community PRs | AC-007 graceful skip + required-check applies to `main` pushes and release tags |

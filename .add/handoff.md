# Handoff — v0.10.0 RELEASED (updated 2026-07-18, PM)

## v0.10.0 (2026-07-18) — RELEASED, signed, verified
https://github.com/MountainUnicorn/add/releases/tag/v0.10.0 — GA release
candidate. Signed tag verified; release notes carry the capability matrix;
release-evidence-v0.10.0.tar.gz attached (bundle also committed under
reports/release-evidence/v0.10.0/). Marketplace cache synced; getadd.dev
footers bumped to v0.10.0 (9 pages) and pushed. CI was fully green on the
tagged commit (both smokes + all guardrails) — the new release.sh guard
verified this before tagging.

## Live agent-leg results (2026-07-18, after secrets added)
- Both repo secrets set. **Claude smoke fully green end-to-end with a live
  agent** — marketplace install → /add:init → valid config.json proven in CI.
- First live runs found 3 real bugs (the smokes working as designed):
  * **#23** /add:init --quick still interviews → headless sessions exit
    without config. Workaround: inline answers in smoke prompts. --defaults
    path targets v0.10.1.
  * **#24** Codex ≥0.14x rejects ADD's sub-agent TOMLs (`prompt_skill`) and
    hooks.json schema (`SessionStart`) — sub-agents + hooks silently dead on
    modern Codex. Matrix updated to "Broken on ≥0.14x". Fix targets v0.10.1.
  * Codex 0.144 needs `codex login --with-api-key` (stdin) — bare env var
    gives 401. Fixed in run-smoke.sh.
- Codex agent leg now auths but fails on **"Quota exceeded" — the OpenAI
  project key has no credits**. Layout legs all green. Once billing is funded
  the leg should pass unchanged.

STILL OPEN: (1) OpenAI key needs quota/credits (billing console) → Codex smoke
agent leg green; (2) #23 + #24 fixes → v0.10.1; (3) marketplace submission
pending approval (criterion #5); (4) v1.0.0 promotion tag once approved.

## v0.10.0 implementation (2026-07-18, same-day follow-up to the spec)
All sections of specs/install-path-confirmation.md implemented in one pass:
- **Codex re-pin 0.122.0 → 0.144.5** (adapter.yaml; min stays 0.122.0). Smoke
  **passed locally in Docker** against the new pin — 27/27 skills, F-002 path
  suite, version parity. Q-001 retired.
- **Smoke workflows** install-smoke-claude.yml (marketplace install from
  checkout + headless /add:init, needs ANTHROPIC_API_KEY secret) and
  install-smoke-codex.yml (tests/smoke/codex/ Docker, pin via build-arg,
  needs OPENAI_API_KEY for agent leg; layout asserts gate regardless).
  **ACTION: add both secrets to repo settings** or agent legs skip w/ warning.
- **release.sh**: CI-green guard (refuses tag unless HEAD checks green;
  --no-verify-ci override) + appends capability matrix to release notes.
- **docs/capability-matrix.md** + SECURITY.md pointer (AC-027 done).
- **scripts/release-evidence.sh** (AC-025) — first run CAUGHT A REAL BUG:
  migrations.json had no hop out of 0.7.3 (stranded users). Fixed. Check is
  graph-reachability. Dogfood bundle at reports/release-evidence/v0.9.11/.
- **D6 answered: telemetry does NOT emit** (.add/telemetry/ absent). Finding
  recorded milestone+CHANGELOG; fix deferred.
- Milestone doc: D8 decision (v0.10/v0.11 consolidation, submit-before-promote),
  status updates. CHANGELOG [Unreleased] staged for v0.10.0.
- **Branch protection APPLIED** (23 required contexts = both smokes + all
  guardrails jobs; enforce_admins false so direct-push flow survives;
  path-filtered workflows deliberately excluded — release.sh guard covers
  them; re-apply command + maintenance note in docs/release-signing.md).
- **Both smokes GREEN in CI on first run** (caf7d90/dfa9689). My release.sh
  guard change initially broke the release-tooling fixture suite (mocks
  predated the new git/gh calls) — shims fixed + new red-checks-refusal case
  added (dfa9689), guardrails green again.

Remaining before cutting v0.10.0 (all human-gated):
1. Add ANTHROPIC_API_KEY + OPENAI_API_KEY repo Actions secrets → re-run smokes
   so the agent-driven /add:init legs execute (currently skip w/ warning).
2. Promote CHANGELOG [Unreleased] → [0.10.0], bump core/VERSION, release.
3. Run scripts/release-evidence.sh v0.10.0 --upload after the release.
4. Submit to marketplace (criterion #5); v1.0.0 = promotion tag on approval.

## GA review + v0.10.0 spec (2026-07-18)
Reviewed GA readiness against docs/milestones/v1.0-ga.md: criteria #6 met, #1/#4
near/partial, #2/#3/#5 open. Sequencing decision: build + pass install smoke
BEFORE marketplace submission (review the verified artifact), consolidating the
planned v0.10.0 + v0.11.0 scope into one RC; v1.0.0 reserved as the promotion
tag on approval. New spec: **specs/install-path-confirmation.md** (Draft, target
v0.10.0) — Claude marketplace-install smoke (AC-022), Codex containerized smoke
+ CLI re-pin off 0.122 (AC-023/AC-035/Q-001), release-blocking branch protection,
capability matrix (AC-027), release-evidence bundle (AC-025), D6 telemetry check.
Implementation not started. Note: site footers ARE at v0.9.11 (line below is
stale from last session).

## v0.9.11 (2026-07-16) — RELEASED
Stale-rules gap reported by Tomasz Dmitruk (@tdmitruk): init-copied rules in
.claude/rules/ never updated and conflicted with hook-injected rules. Fixed by
retiring rule copying entirely — /add:init Phase 2.5 now detect+cleanup only;
load-rules.sh warns on stale copies each session; migration hop 0.9.10→0.9.11
adds remove_stale_rule_copies (confirm-once, backup-first). Credited in
CONTRIBUTORS.md + CHANGELOG. No GitHub issue existed (private report).


## Shipped this session (all three RELEASED, signed, verified, marketplace synced, site footers bumped)

- **v0.9.8 — P0 correctness.** Codex substitution leaks fixed (copy_tree transform;
  `/add:` → `/add-` rule; .template/.toml in substitution set); Claude/Codex share one
  `rule_autoloads()` predicate (explicit `autoload:` key now REQUIRED on every rule);
  unicode-tag-block detector no longer fails open without python3 (audits the skip);
  `compile.py --check` snapshot+content-diff (catches pre-drifted trees); adapter.yaml
  truth-pass (Codex injection defense is advisory-only — stated plainly).
- **v0.9.9 — token architecture.** Physical maturity rule loading via SessionStart
  hook `load-rules.sh` (POC ~70% rule-token cut; fail-open to full set; 8 fixture
  tests; rule-parity test rewritten). telemetry/cache-discipline/model-roles →
  autoload:false; learning + maturity-lifecycle trimmed (new references:
  telemetry-reference, maturity-matrix). MODEL tier (fast/editor/architect) +
  maturity-scaled BUDGET on every dispatch (swarm-protocol tables, tdd-cycle roles).
  learnings-active char budget (6000 default). count-tokens.py de-drifted.
- **v0.9.10 — dedup + hygiene.** init/deploy/verify/cycle/docs slimmed 35–45%
  (6 new templates, 3 new references incl. skill-epilogue + secrets-gate); skill
  version literals → {{VERSION}}; namespace fixes; injection patterns de-noised
  (+1 real FN closed); redaction unified with secret catalog; CHANGELOG hook →
  PreToolUse; post-write autofix opt-in (`hooks.autofix`); marketplace-validate
  fails loudly; away-logs gitignored; 25 learnings archived; infographic/report/
  CONTRIBUTING/issue templates refreshed with the token-economy story.

## State
- main green: compile-drift ✓, schema ✓, guardrails ✓ (v0.9.9's guardrails run was
  transiently red on the telemetry autoload assertion — fixed in v0.9.10, ~16 min).
- getadd.dev footers at v0.9.10 (Pages deploys green).
- New consumer config keys (optional): `hooks.autofix`, `learnings.active_char_budget`,
  `swarm.budgets`.

## Next candidates (not started)
- Codex injection-scanner parity (adapter.yaml limitation, targeted v1.0).
- Codex-side stale-rules equivalent: AGENTS.md merged at init could also drift — worth an /add-version check (minor).
- Workflow-descriptor emission pilot (deferred to v1.1 per v0.9.7 decision).
- getadd.dev blog post covering the token-architecture arc (site copy beyond
  footers not yet written).
- v1.0 GA gate: marketplace submission + remaining promotion criteria.

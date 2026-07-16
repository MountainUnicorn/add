# Handoff — token-audit arc + stale-rules fix (updated 2026-07-16)

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

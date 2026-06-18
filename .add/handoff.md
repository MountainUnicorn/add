# Handoff — v1.0 GA wave execution (2026-06-14)

## Shipped this session
- **v0.9.6 RELEASED** (signed, verified, on the marketplace cache). Waves 0–2:
  CI unblocked (rule count compile-derived; Node-24 actions), release.sh #18
  fixed (verified live — "published and verified"), truth-pass, and a real
  injection-defense regex fix. PR #19 merged to `main`.
- **Wave 3 (v0.9.7) — done on branch `wave3-v097`, NOT yet pushed/released:**
  - A3 — swarm-state machine-readable format contract.
  - D3-P2 — skill self-scan CI gate (`scripts/self-scan-skills.py` + `skill-self-scan`
    guardrail + SECURITY.md trust signal). Verifier caught a real hole (a `(?m)`
    pattern was silently never gating); fixed + mutation-guarded
    (`tests/security/test-self-scan.sh`).
  - A2 — `runtimes/claude/workflows/` scaffold + `specs/workflow-lifecycle-scripts.md`
    (inert; zero behavior change).
  - A1 — swarm-protocol + agent-coordination reframed as policy-over-native-Workflows
    (manual fallback retained; WIP semantics invariant; emission deferred to v1.1).
  - D4 — README now leads with the maturity ladder ("One dial scales the rigor").
- **GA-gate decision (overrides roadmap D7):** the arbitrary 60-day beta floor is
  dropped; v1.0 gates on **Anthropic marketplace approval** + the substantive
  criteria. Recorded in v1.0-roadmap.md and milestones/v1.0-ga.md.

## State
- Every wave: independent verifier + agent-to-agent retro; learnings L-035…L-049.
- All 16 fixture suites green; `compile --check` clean; self-scan clean.
- `wave3-v097` is 6 commits ahead of `main`, local only.

## Open / next
1. **Wave 3 release:** push `wave3-v097`, open a PR, then version-bump to v0.9.7
   (VERSION, CHANGELOG, migrations hop, README badge) and cut the release — same
   flow as v0.9.6.
2. **C4 launch plan** is preserved as a tracked doc (`docs/wave3-drafts/C4-launch-plan.md`)
   but NOT applied — `/add:announce` skill not built yet; pending a decision on
   one-skill-with-`--target` vs two, and the brand strategy.
3. **A1/A2 emission** (actual Workflow descriptor scripts) deferred to v1.1.
4. **Waves 4–5** (v0.10/v0.11): B4 F-012 spike now consumes the fixed
   regex/writer; B1+B2 Codex re-baseline still needs the live Q-001 CLI spike.
5. **GA tag:** gated on marketplace approval (filed 2026-02-14) + install smoke +
   release-evidence bundle + ADD's own beta→ga self-promotion.

## Acceptance test reminder (release tooling)
Judge any release by the `published and verified` line + a manual `gh release
view`, never bare exit 0 (L-042). v0.9.6 passed this live.

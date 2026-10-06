# Handoff — RESTART: GA Phase 0 stalled since 2026-07-29 (updated 2026-10-06)

## Where we are
- Plugin repo untouched since 2026-07-29 (HEAD c48bc5c, clean, CI green on all
  three workflows). getadd.dev untouched since 2026-07-29. No new issues/PRs.
- Latest release v0.11.0 (2026-07-19), signed + verified. Local marketplace
  cache and ~/.codex both at 0.11.0 with add-* agents.
- GA status unchanged: criteria #1–#4+#6 met; #5 (marketplace approval) open;
  v1.0.0 = promotion tag on approval.
- GA rollout plan: docs/plans/ga-rollout-plan.md (Phase 0 never kicked off).

## Blockers / drift found at restart (2026-09-15 audit, re-confirmed 2026-10-06)
1. **[H] Phase 0.1 — audit the Feb-2026 marketplace submission.** Still the
   critical-path item and still not done. The plan's +60d escape hatch was
   anchored to *resubmission*, which never happened, so the Feb submission is
   now ~8 months old. Decision needed: resubmit now, or invoke the escape
   hatch (re-word criterion #5 via milestone amendment).
2. **Retro overdue.** Last retro 2026-04-22; 29 learnings since (L-026…L-054).
   Compliance rule BLOCKS /add:away, /add:cycle --plan, /add:back after 7 days.
   Run `/add:retro` before any cycle work.
3. **Codex CLI drift.** npm latest 0.154.0; adapter pins codex_cli_version
   0.144.5 (min 0.140.0). 0.144 previously broke schemas (#24), so re-run the
   Docker smoke against 0.154.x and re-pin if green. Claude Code is at 2.1.272.
4. **Fictional "Deployer" survivors in the plugin repo** (site copy was fixed,
   repo copy was not): `.claude-plugin/marketplace.json` description
   ("…reviewers, deployers"), `docs/agent-architecture.svg` line ~245 label,
   README.md:191 alt text. `specs/plugin-installation-reliability.md:131`
   quotes the old description (historical — leave).
5. **Agent-lane P0 deliverables not started** (never depended on the human
   audit): 0.2 marketplace.json / plugin.json metadata refresh (fixes #4),
   0.3 REVIEWERS.md package for Anthropic reviewers.

## Suggested restart order
1. `/add:retro` (unblocks cadence; covers v0.10.x/v0.11 cycle + GA-prep docs).
2. [A] Phase 0.2 + 0.3 + Deployer cleanup → one commit, compile/validate, push,
   sync marketplace. Patch release optional (v0.11.1) if metadata changes
   should ship to the marketplace.
3. [A] Codex 0.154 smoke in Docker; re-pin + capability-matrix update if green;
   file an issue if not.
4. [H] Phase 0.1 decision → unblocks Phase 1 (promotion runbook, v1.0.0
   staged notes/blog/site).

## Shipped history (condensed; see CHANGELOG + git log for detail)
- **2026-07-29** GA rollout plan authored (66d00f2): 5 phases, [A]/[H]/[3P]
  lanes, dependency spine; critical path resubmit → review → v1.0.0.
- **2026-07-19/20** All doc surfaces synced to v0.11 (README, infographic
  canvas 3180, overview report, CLAUDE.md, site, GA-prep blog post
  getadd.dev/blog/preparing-for-ga announcing companion-plugin direction —
  NEW public direction with no repo spec yet; carry into v1.1 planning).
  Branch cleanup: trunk-based on main only; releases = signed tags;
  release/vX.Y.Z only for cut-behind-HEAD patches, deleted after tagging.
- **2026-07-19** v0.10.2 (#23 --defaults, #25 doctor, #26 codex floor,
  #27 install manifest; branch-cut) + v0.11.0 (#28 add-* agent prefixing).
  Both signed, evidence uploaded, migration hops recorded. Gotchas:
  release.sh refuses on untracked files (evidence tarballs now gitignored);
  doctor-checks.sh is bash-only (zsh sourcing breaks sha detection, L-053);
  skill-policy.yaml entry required for new skills (L-052).
- **2026-07-18** v0.10.0 (smokes, release.sh CI-green guard, capability
  matrix, release-evidence.sh, branch protection) + v0.10.1 (#24 Codex ≥0.14x
  schema fix). Both live-agent smokes green in CI. Codex-in-Docker needs
  `codex login --with-api-key` (stdin) + `--dangerously-bypass-approvals-and-sandbox`.
  D6 finding: telemetry does NOT emit — fix deferred (v1.1 companion spec).
- **2026-07-16** v0.9.11 stale-rules fix (reported by @tdmitruk, credited).
- **Earlier** v0.9.8–v0.9.10 token architecture + dedup; see memory/CHANGELOG.

## Open candidates (not started, not blocking GA)
- Codex injection-scanner parity (adapter.yaml limitation, targeted v1.0).
- Codex-side stale AGENTS.md drift check in /add-version (minor).
- doctor zsh-guard, injection parity, GA-cycle retro → Phase 4 / v1.1.
- Workflow-descriptor emission pilot (deferred to v1.1).
- Blog post on the token-architecture arc.

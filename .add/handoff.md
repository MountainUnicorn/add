# Session Handoff
**Written:** 2026-04-23 (end of multi-release session)
**Arc:** /add:away M3 swarms → 7 PRs merged → plugin-family review pivot → v0.8.1 → v0.9.0 + alpha→beta promotion → v0.9.1 beta-polish → CI guardrails live and green

## Where We Are

**main is at `59e6005`.** Three signed releases tagged this session, maturity promoted, 93 tests running green in CI on every push and PR.

```
59e6005  fix(ci): install pyyaml+jsonschema for guardrails frontmatter job
465a2c6  chore: bump to v0.9.1 — beta-polish release      [tag: v0.9.1]
9d9a987  chore: bump to v0.9.0 + promote alpha → beta     [tag: v0.9.0]
0168af1  chore: handoff for v0.8.0 → v0.8.1 hotfix arc
dd102fc  chore: bump to v0.8.1 — plugin-family hotfix    [tag: v0.8.1]
```

## Session Summary

1. **10h `/add:away` session** shipped all 7 M3 specs as worktree-isolated agent swarms → 7 PRs (#8–#14) merged to main with rebase resolutions on #12/#13/#14.
2. **Plugin-family review** from another agent surfaced 20 findings. I verified the 3 shipping-blockers were real (F-001 marketplace schema, F-002 Codex install path mismatch, F-003 test-rewrite bypass), pushed back on architectural overreach (host-neutral kernel + adapter contracts sold as v0.9 Must — parked as M4).
3. **v0.8.1 hotfix** cut before v0.9.0 to close F-001/F-002/F-003. F-002 would have shipped broken Codex installs to every v0.9.0 user.
4. **v0.9.0 + alpha→beta promotion** bundled in one commit. Readiness ~92% (12/13 applicable cascade requirements), single exemption was the F-005 CI wiring.
5. **v0.9.1 beta-polish** closed the remaining plugin-family items that were small: F-011 Claude rule parity drift (15→19 rules), F-018 cache-discipline validator false-positive, /add:version cross-runtime path, and F-005 (the beta exemption). Exemptions list now empty.
6. **Guardrails workflow live and green in CI.** 12 jobs on every PR/push: 9 fixture suites, frontmatter + cache-discipline validators, and Claude marketplace manifest (with grep guard because `claude plugin validate` exits 0 on schema failure — lesson learned from v0.8.1 F-001).

## Releases Shipped

| Tag | Commit | Summary |
|---|---|---|
| v0.8.1 | dd102fc | Plugin-family hotfix: F-001 (marketplace), F-002 (Codex paths), F-003 (test-rewrite bypass) |
| v0.9.0 | 9d9a987 | M3 pre-GA hardening — 7 specs, 207 ACs, maturity alpha→beta |
| v0.9.1 | 465a2c6 | Beta-polish: /add:version cross-runtime, F-011 rule parity, F-018 validator false-positive, F-005 CI guardrails wired |

All three GPG-signed with key `040C002AB5A0E55246B35D2F8C4D802093066794`. Marketplace cache synced.

## Project State

- **Version:** 0.9.1
- **Maturity:** beta (promoted 2026-04-23, zero exemptions)
- **Rules:** 19 (was 15 pre-M3)
- **Skills:** 27 (agents-md added in M3)
- **Tests:** 93 passing across 10 suites, all running in CI
- **PRD/specs/milestones:** M1, M2, M3-pre-ga-hardening complete; M3-marketplace-ready still open
- **Open PRs:** only #6 (@tdmitruk community rebase)

## Next-Promotion Criteria (beta → GA)

Logged in `.add/config.json:maturity.next_promotion_criteria`:

- Guardrail suite running in CI and release-blocking ✓ (just done, but should be branch-protected before GA)
- Real Claude + Codex install smoke in CI (needs containerized runtimes)
- Per-runtime capability matrix in release notes
- 60-day stability at beta
- Marketplace submission approved
- 20+ projects using ADD

## Open Items / Next Cycle

### Still tracked from plugin-family review

- **F-014** executable secrets scanner — current gate is declarative markdown, regex fixtures match, but no pre-commit hook blocks staged leaks. v0.9.x candidate.
- **F-013** per-skill `@reference core/rules/telemetry.md` sweep — Swarm F's own deferral from v0.9.0. Cross-cutting SKILL.md edit, can now land without conflict since M3 merged.
- **F-017** `jq` dependency — either guard soft-fail or document requirement. Low priority.

### Deferred to M4 (architectural, explicitly out of v0.9 scope)

- **F-006/AC-011/AC-012** Host-neutral kernel + runtime overlays + `${ADD_HOME}`/`${ADD_USER_LIBRARY}` path variables
- **AC-010** adapter contract schema driving compile output
- **AC-016** installer ownership manifest with backup/uninstall
- **AC-017** config schema + migration graph validator
- **AC-021** command-catalog generator (single source → README, marketplace, AGENTS, runtime docs)

### Deferred to v1.0.0

- **AC-022/AC-023** real Claude + Codex install smoke in CI (containerized runtime infra)
- **AC-028** tag-pinned / signed install URL (drop `curl main | bash` as recommended path)

### External (unchanged)

- **PR #6** — community, rebase-paced

## Decisions Made (with rationale)

- **Pivoted v0.9.0 → v0.8.1 mid-ceremony** — F-002 was a shipping blocker; pushing v0.9.0 with it would have broken every Codex install. Right call despite arc disruption.
- **Three releases in one session, bundled intentionally** — v0.8.1 because hotfix; v0.9.0 + promotion because the release IS the promotion's evidence; v0.9.1 because batching four small items is cleaner than four tags.
- **Kept `~/.codex/add/` namespaced install path** over bare `~/.codex/` root. Avoids collision with other Codex plugins and with Codex's own directories. The bug was the compile-time substitution, not the install layout.
- **Hooks live at `$CODEX_HOME/hooks/`**, not `$CODEX_HOME/add/hooks/` — Codex CLI loads hooks from that exact path. Required separate `${CLAUDE_PLUGIN_ROOT}/hooks` substitution (longest-prefix-first ordering).
- **Rejected host-neutral kernel as v0.9 scope** — architectural rewrite dressed up as release criteria. Saved for M4.
- **`--allow-test-rewrite` is acknowledgment, not bypass** — flag alone now insufficient, override/trailer still required. Matches documented intent.
- **`claude plugin validate` exits 0 on schema failure** — worked around with grep for "Validation failed" in the CI job.
- **Frontmatter validator needs `pyyaml`+`jsonschema`** — caught by first CI run on v0.9.1, fixed in `59e6005`.

## Resume Command

If next session opens cold:

```bash
cat .add/handoff.md
git log --oneline -10
gh release list --repo MountainUnicorn/add --limit 5
gh pr list --repo MountainUnicorn/add
gh run list --repo MountainUnicorn/add --workflow guardrails.yml --limit 3
```

No immediate action needed — beta is clean, CI is green, three releases are out. Next work picks from the "Open Items" list above based on priority.

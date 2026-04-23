# Session Handoff
**Written:** 2026-04-23 (continuation — supersedes prior handoff from 03:10 UTC)
**Arc:** /add:away M3 swarms → 7 PRs merged → plugin-family review pivot → v0.8.1 hotfix shipped (tag pending)

## Where We Are

**main is at `dd102fc`** — 4 commits ahead of the v0.8.0 tag. v0.8.1 is fully staged (VERSION bumped, CHANGELOG written, 90 tests green). The only thing left is running `./scripts/release.sh v0.8.1` interactively to produce the GPG-signed tag + GitHub release — that step requires the pinentry passphrase prompt so Claude cannot automate it.

## What Happened This Session

1. **All 7 M3 PRs merged** (#8–#14, commits `6035c46..3819fc1`). Rebases required on #14, #13, #12 — CHANGELOG conflicts resolved by keep-both-sides; `scripts/compile.py` merged (src-name tuple `rules, skills, templates, knowledge, schemas, lib, security`); `dist/codex/` wipe-and-regenerate for #12; `skill-policy.yaml` needed a new `agents-md` entry because #12 predated #8.
2. **Plugin-family review dropped in** (`specs/plugin-family-release-hardening.md` + plan) — feedback from another agent with 20 findings. I verified the three most damaging (F-001, F-002, F-003 were ALL real) and pushed back on the architectural overreach (host-neutral kernel, runtime install smoke in CI). Review verdict: **3 hotfix-worthy bugs**, **~4 genuine follow-ups for v0.9.x**, **rest is M4/v0.10+ scope dressed up as release criteria**.
3. **v0.8.1 hotfix cut** before v0.9.0 ships — because F-002 alone means the v0.9.0 Codex install we were 30 seconds from releasing would have installed broken skills.

## v0.8.1 Hotfix — What's In It

| Commit | What | Why it matters |
|---|---|---|
| `1b21842` fix(marketplace) F-001 | Moved `description` into `metadata` block in `.claude-plugin/marketplace.json`, dropped stale counts | `claude plugin validate .` now passes; was failing with `root: Unrecognized key: "description"` |
| `d079ee6` fix(check-test-count) F-003 | `--allow-test-rewrite` no longer bypasses approval; flag + override are both required | Matches documented intent; regression fixture `replacement-with-flag-no-override` proves the bypass is closed |
| `ef03c3d` fix(codex) F-002 | Codex skills now reference `~/.codex/add/*` (namespaced); installer ships `knowledge/`, `rules/`, `lib/`, `security/` trees; `filter-learnings.sh` shipped as cross-runtime utility; new smoke test resolves every `~/.codex/...` ref against temp CODEX_HOME | Without this, every Codex skill invocation post-v0.8.0 would have failed to resolve its asset refs |
| `dd102fc` chore: bump to v0.8.1 | `core/VERSION`, `.add/config.json`, README badge, CHANGELOG `[0.8.1]` section. Compile regenerated `plugins/add/` + `dist/codex/` at the new version | Release-ready |

**90 tests passing** across 10 suites, including the new `tests/codex-install/test-install-paths.sh`.

## Immediate Next Action

```bash
./scripts/release.sh v0.8.1
```

Run it interactively (pinentry passphrase prompt). Creates the signed tag + GitHub release using `[0.8.1]` CHANGELOG content.

## After v0.8.1 Tags

**v0.9.0 release ceremony** — cleanly unblocked:
1. `echo "0.9.0" > core/VERSION`
2. Update `.add/config.json` version, README badge
3. CHANGELOG: promote `[Unreleased]` (currently describes the 7 M3 specs) → `[0.9.0] — 2026-04-23`
4. `python3 scripts/compile.py`
5. `/add:promote --check --target beta` (maturity gate — alpha → beta criteria should be met)
6. Commit, push, `./scripts/release.sh v0.9.0`
7. Sync marketplace + website (`MountainUnicorn/getadd.dev` blog post)

## Open Items / Next Cycle

### Tracked Follow-Ups (from plugin-family review — prioritized)

**v0.8.2 micro-fix** (task #22):
- `/add:version` reads `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (Claude-only path). Needs a cross-runtime fallback to `plugin.toml` / `VERSION`. Currently allowlisted in `tests/codex-install/test-install-paths.sh`.

**v0.9.x candidates** (real bugs, just not hotfix-scope):
- **F-014** executable secrets scanner — current gate is declarative markdown; regex fixtures prove patterns match but no hook blocks staged commits
- **F-011** Claude rule parity — `/add:init` may list fewer rules than `core/rules/` actually contains (we now have 19 rules)
- **F-005** CI running guardrail suites — all 10 test suites exist locally but aren't wired into `.github/workflows/`
- **F-013** telemetry per-skill `@reference` sweep — Swarm F's own deferral; now unblocked since M3 merged
- **F-018** cache-discipline validator false-positive on `core/skills/init/SKILL.md:1039` — Swarm A's own deferral
- `filter-learnings.sh` → move to `core/lib/` as source of truth (currently Claude-hook-dir with cross-runtime copy)

### Defer to new M4 milestone (NOT v0.9.0)

These are architectural, not release-hardening, despite the review framing them as v0.9.0 Must:
- **AC-010–012** adapter contract schema + host-neutral kernel + `${ADD_HOME}`/`${ADD_USER_LIBRARY}` path variables + Claude/Codex runtime overlays. Half-milestone of work.
- **AC-021** command catalog generator — single-source doc regeneration
- **AC-016** installer ownership manifest + backup/restore
- **AC-017** config schema + migration graph validator

### Defer to v1.0.0

- **AC-022–023** real Claude + Codex install smoke in CI (needs containerized runtime infrastructure — Swarm G's AC-035 was the first swing at this)
- **AC-028** tag-pinned / signed install paths (`curl main | bash` is not the stable install)

### External (unchanged)

- **PR #6** (@tdmitruk) — rules/knowledge on-demand loading; community-paced rebase

## Decisions Made (with rationale)

- **Pivoted v0.9.0 → v0.8.1 mid-ceremony.** F-002 was a shipping blocker; pushing v0.9.0 with it would have released broken Codex installs. Right call despite the arc disruption.
- **Rejected the "host-neutral kernel" architectural rewrite as v0.9.0 scope.** Would have delayed v0.9.0 by weeks for cosmetic gains. Saved as M4 milestone.
- **Kept `~/.codex/add/` namespaced install path over bare `~/.codex/` root.** The namespaced path is correct; the bug was the compile-time substitution, not the install layout. Avoids future collisions with other plugins.
- **Hooks live at `$CODEX_HOME/hooks/` (NOT under `add/`).** Codex CLI convention — the CLI loads hooks from that exact path. Required a separate `${CLAUDE_PLUGIN_ROOT}/hooks` substitution rule (longest-prefix-first).
- **`filter-learnings.sh` shipped as cross-runtime utility in Codex hooks dir.** Skills reference it imperatively (not as a lifecycle hook). Cleaner refactor is to move it to `core/lib/` — deferred to v0.9.x.
- **Three-state test-rewrite gate:** flag + override required. Flag alone is acknowledgment, not approval. Matches documented intent; code was out of sync.

## Arc Commits (v0.8.0 → v0.8.1)

```
dd102fc chore: bump to v0.8.1 — plugin-family hotfix
ef03c3d fix(codex): F-002 — align install paths with skill references
d079ee6 fix(check-test-count): F-003 — close test-rewrite bypass
1b21842 fix(marketplace): F-001 — move description into metadata block
3819fc1 feat(codex-native-skills): migrate Codex adapter to native Skills format (#12)
acac672 feat(test-deletion-guardrail): block unjustified test removal in tdd-cycle + verify (#13)
5270dd4 feat(cache-discipline): stable-prefix layout convention + validator + high-impact skill audit (#9)
5f56e29 feat(prompt-injection-defense): rule + scan hook + threat model (#14)
bdd5a64 feat(secrets-handling): auto-loaded rule + .secretsignore + deploy gate (#10)
de1b568 feat(telemetry-jsonl): OTel-aligned structured telemetry + dashboard integration (#11)
5f9ae74 chore: archive away-log from 10h M3 swarm session
6035c46 feat(agents-md-sync): /add:agents-md skill + auto-sync staleness hook (#8)
659d9fa chore: away-log + handoff for /add:away M3 session — 7 PRs opened
```

## Blockers

None internal. GPG passphrase for the v0.8.1 tag is the only human-interactive step.

## Resume Command

If next session opens cold:

```bash
cat .add/handoff.md
git log --oneline -10
gh release view v0.8.1 --repo MountainUnicorn/add 2>&1 | head -5  # has it been tagged?
gh pr list --repo MountainUnicorn/add
```

If `gh release view v0.8.1` errors, the tag hasn't been created — run `./scripts/release.sh v0.8.1` interactively.

If v0.8.1 is tagged, proceed straight to v0.9.0 release ceremony using the 7-step sequence in "After v0.8.1 Tags" above.

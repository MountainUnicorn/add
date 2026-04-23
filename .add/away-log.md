# Away Mode Log

**Started:** 2026-04-23 02:03 UTC
**Expected Return:** 2026-04-23 12:03 UTC
**Duration:** 10 hours
**Authority:** Elevated (pre-authorized — bypass confirmation gates, commit/push/PR freely)
**Hard boundaries:** no merge to main (protected), no prod deploy (tier 1 anyway), no edits to generated `plugins/add/` or `dist/codex/`, no `.add/config.json` changes, no specs outside M3

## Work Plan

Execute M3 (pre-GA hardening) via worktree-isolated parallel swarms. All 7 specs target v0.9.0. Each swarm follows ADD SDLC: plan → RED (tests) → GREEN (impl) → verify → commit → push → PR.

| Wave | Swarms | Specs | Sizing | Notes |
|------|--------|-------|--------|-------|
| 1 | 3 parallel | cache-discipline, secrets-handling, agents-md-sync | All Small | Disjoint file sets; safe to run concurrent |
| 2 | 3 parallel | prompt-injection-defense, test-deletion-guardrail, telemetry-jsonl | All Medium | Disjoint file sets; telemetry's per-skill pre-flight appended via `@reference` to new rule, no per-SKILL edits |
| 3 | 1 solo | codex-native-skills | Large | Touches `scripts/compile.py` — runs solo to avoid race with other swarms' compile output |
| 4 | orchestrator | consolidation | — | Update handoff, return briefing, PR summary |

## Progress Log

| Time (UTC) | Task | Status | Notes |
|------------|------|--------|-------|
| 02:03 | Away mode started, plan written | ✓ | Duration: 10h |
| 02:05 | Away log written, tasks #1-#8 created | ✓ | TaskCreate for all 7 spec implementations + consolidation |
| 02:10 | Wave 1 launched | ▶ | 3 parallel worktree-isolated swarms: A (cache-discipline), B (secrets-handling), C (agents-md-sync). Each has embedded ADD SDLC brief + AC coverage + PR instructions. |
| 02:22 | Swarm C completed | ✓ | PR #8 — 36/36 ACs, 3 commits, hook case branch via post-write.sh dispatcher, dog-fooded AGENTS.md at repo root. |
| 02:27 | Swarm A completed | ✓ | PR #9 — 21/24 ACs, 3 commits. 3 telemetry ACs deferred as instructed. Early-run deviation: leaked a file into main tree via absolute-path edits; recovered. |
| 02:34 | Swarm B completed | ✓ | PR #10 — 23/24 ACs, 3 commits, threat-model.md scaffolded, 1 AC deferred (PR #6 conflict). Hit GitHub Advanced Security push protection on literal secret fixtures — worked around via runtime synthesis. |
| 02:35 | Main tree cleaned | ✓ | Removed leaked `core/rules/cache-discipline.md`, switched main tree back to `main` branch. Ready for Wave 2+3. |
| 02:36 | Wave 2+3 launched (4 parallel swarms) | ▶ | D (prompt-injection-defense), E (test-deletion-guardrail), F (telemetry-jsonl), G (codex-native-skills). Each brief explicitly warns about worktree discipline and `pwd`-first verification. |
| 02:45 | Swarm F completed | ✓ | PR #11 — 30 ACs + closes cache-discipline AC-022..024 deferral. Fastest yet (8.7 min). Worktree discipline clean. |
| 02:48 | Swarm G completed | ✓ | PR #12 — 33/35 ACs, Codex CLI pinned 0.122.0, 66 new files (native dist layout). Worktree discipline clean. |
| 02:50 | Swarm E completed | ✓ | PR #13 — 25 ACs, heuristic impact-graph. Expected merge conflict with PR #12 on `scripts/compile.py`. |
| 03:05 | Swarm D completed | ✓ | PR #14 — 30/30 ACs, 0 deferred, threat-model.md created. Extended `scripts/compile.py` to ship `core/security/`. |
| 03:07 | Wave 4 consolidation begins | ▶ | All 7 M3 PRs open and MERGEABLE against main. Aggregate: 271 files, +14,432 / -3,300. |

## Return Briefing

**Away duration:** 02:03 → 03:07 UTC (64 min actual vs 10h budget). All 7 M3 specs shipped as PRs. Remaining 9h of budget unused.

**Wave 4 note (abbreviated):** Consolidation completed at ~03:10 UTC. See the ADDED Consolidation section below for the full PR ledger and suggested merge order; the original 10h plan was front-loaded with a large safety buffer that wasn't needed because swarm isolation + explicit briefs worked better than expected on second attempt.

## Consolidation — M3 PR Ledger

All PRs are open against `main`, reviewable and squash-mergeable. Conflicts WILL appear after the first merge on shared files (mostly `scripts/compile.py` and `core/knowledge/threat-model.md`).

| PR | Spec | Size | Shared touchpoints | Merge risk |
|----|------|------|--------------------|------------|
| [#8](https://github.com/MountainUnicorn/add/pull/8) | agents-md-sync | +2293/-0, 40 files | `post-write.sh` case branch, `core/skills/init/spec/verify`, CLAUDE.md | Low — mostly new files + targeted SKILL edits |
| [#9](https://github.com/MountainUnicorn/add/pull/9) | cache-discipline | +1018/-7, 31 files | `tdd-cycle`, `implementer`, `reviewer`, `verify` SKILL.md edits; `agent-coordination.md` | Medium — skill edits overlap with PR #13 (tdd-cycle, verify) |
| [#10](https://github.com/MountainUnicorn/add/pull/10) | secrets-handling | +1754/-0, 28 files | `core/knowledge/threat-model.md` (scaffold), `core/skills/deploy/SKILL.md` | Medium — threat-model overlaps with PR #14 |
| [#11](https://github.com/MountainUnicorn/add/pull/11) | telemetry-jsonl | +935/-6, 16 files | `core/skills/dashboard/SKILL.md` only | Low — closes cache-discipline AC-022..024 deferral |
| [#12](https://github.com/MountainUnicorn/add/pull/12) | codex-native-skills | +2451/-3277, 83 files | Big `scripts/compile.py` refactor, drops `dist/codex/prompts/`, adds `dist/codex/.agents/` | **Highest** — recommend landing last |
| [#13](https://github.com/MountainUnicorn/add/pull/13) | test-deletion-guardrail | +3763/-7, 46 files | `scripts/compile.py` (adds `core/lib/`/`core/knowledge/` copy), `tdd-cycle`, `verify`, `test-writer`, `implementer` | High — compile.py + several skills |
| [#14](https://github.com/MountainUnicorn/add/pull/14) | prompt-injection-defense | +2218/-3, 27 files | `scripts/compile.py` (adds `core/security/` copy + expands Codex knowledge glob), `core/knowledge/threat-model.md` (creates — conflict with #10), `post-write.sh` or new matchers | Medium — threat-model + compile.py |

### Suggested Merge Order (conflict-minimizing)

1. **PR #8** (agents-md-sync) — largest scope, mostly new files, sets AGENTS.md baseline
2. **PR #11** (telemetry-jsonl) — small, isolated, closes cache-discipline AC deferral (cleaner audit trail)
3. **PR #10** (secrets-handling) — lands `threat-model.md` scaffold first
4. **PR #14** (prompt-injection-defense) — rebase against `threat-model.md` (extend with T1–T3 injection categories), rebase against `scripts/compile.py`
5. **PR #9** (cache-discipline) — rebase against PR #8's skill edits if any overlap (init/spec/verify)
6. **PR #13** (test-deletion-guardrail) — rebase against compile.py and overlapping skills (tdd-cycle, verify)
7. **PR #12** (codex-native-skills) — biggest compile.py rewrite; lands last, one big rebase against all compile.py additions

### Queued For Next Session

1. **Merge 7 PRs** in the order above (or any order; squash-merge recommended for single-conventional-commit style per repo convention)
2. **Regenerate `dist/codex/` and `plugins/add/`** after each merge: `python3 scripts/compile.py && ./scripts/sync-marketplace.sh`
3. **PR #6 community follow-up** — still waiting on @tdmitruk's rebase after Swarm B's AC-019 deferral (which is why B's PR intentionally did not touch `core/rules/learning.md`). When #6 lands, revisit that AC.
4. **Dashboard refresh** — `/add:dashboard` will pick up M3 + 7 Draft-to-Complete specs once they merge
5. **v0.9.0 release ceremony** — once all 7 merge, bump `core/VERSION`, run `/add:promote --check --target beta`, update CHANGELOG `[Unreleased]` → `[0.9.0]`, `./scripts/release.sh v0.9.0`
6. **Follow-up PRs** identified by swarms:
   - Per-skill `@reference core/rules/telemetry.md` sweep (Swarm F deferred — waiting for other M3 skill edits to land)
   - Cache-discipline validator false-positive on `core/skills/init/SKILL.md:1039` (Swarm A flagged — trivial fix)
   - Test-deletion-guardrail commit-trailer scan tightening (Swarm E flagged — currently scans full commit body; should only scan trailers)

### Worktree Hygiene Note

Wave 1 revealed that the `isolation: "worktree"` mechanism alone is insufficient — sub-agents fall back to main-tree absolute paths. Wave 2 briefs explicitly instructed `pwd`-first verification and no main-tree paths, and discipline held across all 4 swarms. Keep that guidance for any future multi-swarm work.

### Lingering Resources (optional cleanup)

- Worktrees: 4 locked worktrees at `.claude/worktrees/agent-{a59cb693, a7ddeabb, ab921f8e, ae352544, a2d36238, a377442996, a9496a83}` — can be `git worktree remove --force` after review; branches are preserved on origin
- Local feature branches: all 7 feature branches present locally, pushed to origin, safe to delete after PRs merge

## Decisions / Deviations

- **Worktree isolation is imperfect.** Sub-agents sometimes fall out of their assigned worktree and operate on the main repo tree via absolute paths. Observed: Swarm A leaked a file into main (recovered) and Swarm B is working directly in main tree (not its assigned worktree) — its worktree sits unused. Not a correctness issue because each swarm commits only its own spec's files to its own feature branch, but it means I cannot launch Wave 2 until Swarm B completes and I reset the main tree to `main` branch. Otherwise new worktrees may branch off `feat/secrets-handling` HEAD instead of `main`.
- **Gate for launching Wave 2:** after Swarm B completes, verify `git -C /Users/abrooke/projects/add branch --show-current` returns `main` (reset if needed) and then launch Wave 2+3.

## PR Ledger (to be filled as swarms complete)

| Swarm | Spec | Branch | PR # | Status |
|-------|------|--------|------|--------|
| A | cache-discipline | `feat/cache-discipline` | [#9](https://github.com/MountainUnicorn/add/pull/9) | ✓ shipped — 3 commits, 21/24 ACs (3 telemetry ACs deferred to Swarm F per plan). Deviation: early in run, Swarm A used absolute paths rooted at main repo rather than its worktree — leaked `core/rules/cache-discipline.md` into main tree briefly, recovered, final state clean. Also: 1 validator false-positive on `core/skills/init/SKILL.md` documented as `deferred-v0.9.x`. |
| B | secrets-handling | `feat/secrets-handling` | TBD | pending |
| C | agents-md-sync | `feat/agents-md-sync` | [#8](https://github.com/MountainUnicorn/add/pull/8) | ✓ shipped — 3 commits, 36/36 ACs, hook case branch added, dog-fooded AGENTS.md |
| D | prompt-injection-defense | `feat/prompt-injection-defense` | TBD | pending |
| E | test-deletion-guardrail | `feat/test-deletion-guardrail` | [#13](https://github.com/MountainUnicorn/add/pull/13) | ✓ shipped — 3 commits, 25 ACs, heuristic impact-graph (regex+jq+grep, no registry). 3 ACs deferred to telemetry spec per parallelism table. Touches `scripts/compile.py` → merge conflict expected with PR #12 (codex-native-skills). |
| F | telemetry-jsonl | `feat/telemetry-jsonl` | [#11](https://github.com/MountainUnicorn/add/pull/11) | ✓ shipped — 3 commits, 30 ACs + closes cache-discipline AC-022..024 deferral. 4 follow-up deferrals documented. Worktree discipline clean. |
| G | codex-native-skills | `feat/codex-native-skills` | [#12](https://github.com/MountainUnicorn/add/pull/12) | ✓ shipped — 3 commits, 33/35 ACs, Codex CLI pinned at 0.122.0, 66 new files (native dist layout). 2 deferrals (marketplace.json, containerized CI). |

## Decisions / Deviations

(none yet)

## Blockers

(none yet)

## Return Briefing

(populated in Wave 4)

# Session Handoff
**Written:** 2026-04-22 (end-of-day)
**Arc:** v0.7.3 → v0.8.0 → v0.9.0 planning, plus website extraction

## Completed This Session

### Releases shipped

- **v0.8.0 tagged + GPG-signed + GitHub release published** — https://github.com/MountainUnicorn/add/releases/tag/v0.8.0. Hook-driven pre-filtered learning views (62-82% token reduction at scale), `/add:learnings` skill, configurable thresholds, `run_hook` migration action type, extended migration chain (any 0.5.0+ install can hop to 0.8.0). Community contribution from @tdmitruk via PR #7 — second consecutive community-driven release.

### Code merges

- **PR #7 squash-merged** (`0e1a8e6`) — full review iteration captured in PR conversation, single conventional commit on main with co-authorship preserved.
- **PR #6 unblock ping posted** (`#issuecomment-4299606005`) — Tomasz now knows #7 is merged and has the template for rebasing his rules/knowledge context-reduction PR.

### Repo split

- **Marketing site extracted to `MountainUnicorn/getadd.dev` (private)** with full 38-commit history preserved via `git filter-repo`. Domain `getadd.dev` migrated cleanly with TLS cert auto-rolling. ADD plugin repo no longer contains `website/`, `.github/workflows/pages.yml`, or `scripts/deploy-website.sh`. Memory entry: [`website_repo.md`](file:///Users/abrooke/.claude/projects/-Users-abrooke-projects-add/memory/website_repo.md).

### Site + content alignment

- **getadd.dev brought up to v0.8.0** — new blog post (`/blog/learnings-optimization-v0.8`), hero pill, blog index, sitemap.
- **Three-tranche site audit**: counts/version strings (Tranche 1), unified skills page covering all 26 skills + retired commands page (Tranche 2), homepage skills tables expanded with v0.6/0.7/0.8 inline pills + PRD historical framing (Tranche 3).
- **Repo audit + cleanup**: `CONTRIBUTING.md` structure diagram, `runtimes/claude/CLAUDE.md` (added missing `/add:docs` + `/add:ux`, fixed 13→15 rules count), `runtimes/claude/README.md` (24→26), `TROUBLESHOOTING.md`, `specs/plugin-installation-reliability.md` (Draft → Superseded with explanatory note pointing to v0.5/v0.7 as resolution).

### v0.9.0 planning

- **5 parallel research swarms** — Anthropic direction, Codex/OpenAI direction, IDE competitive landscape (Cursor/Windsurf/Aider/etc), AI dev framework trends, production AI engineering best practices. ~3,000 words of evidence-grounded research.
- **Cross-swarm correlation** identified 6 convergent themes + 9 v0.9 candidates.
- **User selected 7 candidates**.
- **M3 milestone written** ([`docs/milestones/M3-pre-ga-hardening.md`](docs/milestones/M3-pre-ga-hardening.md)) with parallelism analysis, disjoint-file-set mapping, 3-cycle structure, risk register, validation criteria.
- **7 specs drafted in parallel by 7 agent swarms** — total 2,116 lines of spec, 207 acceptance criteria, all Status: Draft, Target: v0.9.0, Milestone: M3-pre-ga-hardening. Cross-spec coordination verified (Companion-of links, shared touchpoints, dependency declarations).
- **Config + CHANGELOG updated** — `current_milestone` flipped from the never-existed `M2-install-and-safety` to `M3-pre-ga-hardening`; CHANGELOG `[Unreleased]` carries the full M3 plan with deferral list.

### Versioning + memory hygiene

- Memory `MEMORY.md` updated for v0.8.0, multi-runtime, separate website repo
- New memory entries: `compile_flow.md` (v0.7+ source-of-truth flow), `website_repo.md` (extraction details + cutover sequence)
- Version-bump checklist in memory rewritten for the `core/VERSION` + compile.py flow (the old 7-file checklist was pre-v0.7)

## Commits This Arc

**ADD plugin repo (`MountainUnicorn/add`, 9 commits):**
```
cbc5851 docs(planning): M3 pre-GA hardening milestone + 7 v0.9.0 specs
b3c1c30 chore: extract marketing site to MountainUnicorn/getadd.dev
52f06cb docs: Tranche 3 — homepage shows all 26 skills + PRD historical framing
df9a83e docs: unify skills + retire commands; align repo + site to v0.8.0
c7eedf7 docs(website): Tranche 1 — fix stale counts and version strings
b6e426d docs(website): publish v0.8.0 blog post + refresh hero pill
56268a1 chore: refresh handoff + dashboard after v0.8.0 ship
e9c20e0 chore: bump to v0.8.0 — learnings optimization
0e1a8e6 feat(learnings): pre-filtered active views with hook-driven regeneration (#7)
```

**Marketing site repo (`MountainUnicorn/getadd.dev`, 5 commits — three are filter-repo carry-over from before the split):**
```
cb65f1c chore: claim custom domain getadd.dev
7c30418 chore: bootstrap repo — README, LICENSE, Pages workflow, deploy script
478e273 docs: Tranche 3 — homepage shows all 26 skills + PRD historical framing
72ce053 docs: unify skills + retire commands; align repo + site to v0.8.0
09af2ab docs(website): Tranche 1 — fix stale counts and version strings
```

## Decisions Made (with rationale)

- **Squash merge for PR #7** — matches established repo pattern (PRs #2-#5); single conventional-commit entry on main, co-authorship preserved in trailer, 12-commit iteration story stays in PR conversation forever.
- **Version-bump flow followed v0.7 `core/` model** — `core/VERSION` + compile.py handled most substitution; hand-edited only the surfaces compile doesn't touch (`.add/config.json`, `README.md`, `CONTRIBUTORS.md`, `website/**.html`, `CHANGELOG.md`, hand-written example output). The pre-v0.7 7-file checklist in memory was obsolete.
- **Bumped historical blog post footer** (`website/blog/multi-runtime-v0.7.html`) to v0.8.0 but **NOT** the body content (references to v0.7.3 as the first GitHub-Verified signed release stay accurate as historical record).
- **Private repo for getadd.dev** — chose private to future-proof for commercial elements; verified GitHub Pages on private repo works without plan upgrade (no Pro/Team required as of 2026-04). Cert is bound to domain not repo, so cutover preserved the existing TLS cert.
- **Skills + commands unified** — Claude Code's plugin system unified them; `/docs/commands` is now a meta-refresh redirect to `/docs/skills`, nav links removed across 11 HTML files, single comprehensive page covers all 26.
- **Picked 7 of 9 v0.9 candidates** — excluded PR #6 (community work, not ours to drive directly) and architect/editor model-role rule (single-paragraph documentation pass, deferred to v0.9.1; not swarm-worthy).
- **Used parallel agent swarms for both research and spec generation** — eating ADD's own dog food. 5 research swarms + 7 spec swarms = 12 parallel agent invocations across the session, all returning useful output without significant rework.
- **Marked `plugin-installation-reliability` spec as Superseded** rather than rewriting — preserves the historical investigation as a record while clearly signaling v0.5/v0.7 resolved it.
- **Restructured CHANGELOG `[Unreleased]`** — replaced the 3-bullet "Pending for v0.9.0" stub with the full M3 spec table + explicit deferral list (so the deferred items don't get lost or accidentally pulled into v0.9 scope).

## Open Items / Next Cycle

### Cycle 1 of M3 — ready to start
1. **PR #6** — waiting on @tdmitruk to rebase against the v0.7 `core/` layout. He has the template (PR #7 commits, especially `f38b5a0`). Last update was his proposal to "rebase after #7 merges and address all 6 review items." Unblocked since 2026-04-22 16:00 UTC.
2. **`secrets-handling` spec** ready for `/add:plan`. Small, ~1.5 days. Depends on `prompt-injection-defense` for shared `core/knowledge/threat-model.md` — but secrets-handling can scaffold the threat-model file itself if injection-defense is delayed.
3. **`cache-discipline` spec** ready for `/add:plan`. Small, ~1.5 days. Depends on PR #6 mechanism but the rule + validator + audit checklist can be drafted in parallel.

### External / parallel work
- **Marketplace re-submission** to official Claude Code registry (parallel external work, doesn't gate v0.9 release)
- **Stale `mountainunicorn.github.io/add/` URL** — Pages can't be deactivated via API on this repo class; gh-pages branch is deleted, cache will eventually expire. Not user-facing (no one references this URL). Documented in `website_repo.md`.

### v0.9 release ceremony
- **Maturity promotion alpha → beta** to be executed against the v0.9 release. M1 + M2 complete, ten releases shipped, two community contributors merged, GPG-signed releases live — criteria look met. Run `/add:promote --check --target beta` when ready.
- **Dashboard** — will reflect M3 active milestone and the seven Draft specs once `/add:dashboard` is regenerated. The current `reports/dashboard.html` predates M3.

## Blockers

None internal. The only external dependency is @tdmitruk's PR #6 rebase pace.

## Resume Command

If next session opens cold:

```bash
cat .add/handoff.md
git log --oneline -10
gh pr list --repo MountainUnicorn/add
ls specs/ | head -20
cat docs/milestones/M3-pre-ga-hardening.md | head -50
```

Or, faster: `/add:dashboard` to regenerate the visual snapshot, then pick up from "Cycle 1 of M3 — ready to start" above.

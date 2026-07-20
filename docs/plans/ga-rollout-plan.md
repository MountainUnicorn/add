# Plan: Marketplace Submission & GA Rollout

**Status:** Active · **Created:** 2026-07-19 · **Owns GA criterion:** #5 (the last open one) → v1.0.0 promotion
**Related:** `docs/milestones/v1.0-ga.md` (criteria), `docs/distribution-plan.md` (channel inventory), `getadd.dev/blog/preparing-for-ga` (public commitments)

Every task is tagged with its executor lane:
**[A]** agent (autonomous, this repo's flow) · **[H]** human (Anthony — accounts, attestations, anything outward-facing that commits the project) · **[3P]** third party (Anthropic review, aggregators, community — we don't control timing).

---

## Phase 0 — Submission refresh (this week; unblocks everything)

The official-directory submission was filed **2026-02-14 and is still pending**. It predates the v0.7 core/runtime restructure, the smokes, signing, and 4 minor versions — whatever Anthropic eventually reviews should be the GA candidate, not a February artifact.

| # | Task | Lane | Depends on |
|---|------|------|-----------|
| 0.1 | Audit current submission state: what version/metadata the form captured, whether a submission ID / contact channel exists | [H] | — |
| 0.2 | Refresh listing metadata for v0.11.0: `marketplace.json` + `plugin.json` description, keywords, homepage; verify `claude plugin validate` passes both | [A] | — |
| 0.3 | Build a **reviewer package**: one-page REVIEWERS.md linking capability matrix, threat model, SECURITY.md, signed-tag verification steps, CI smoke runs, evidence bundle — make the reviewer's yes easy | [A] | 0.2 |
| 0.4 | Re-submit / update the pending submission against v0.11.0 with the reviewer package linked; note the pending Feb submission in the form to avoid a duplicate-entry rejection | [H] | 0.2, 0.3 |
| 0.5 | Establish a review contact path (form follow-up, support email, or Anthropic dev-relations) and log it in this plan | [H] | 0.4 |

**Exit:** Anthropic demonstrably reviewing the *current* artifact, with a channel for questions.

## Phase 1 — Pre-stage GA assets (parallel with review latency)

Everything approval-day needs, built and reviewed **now** so GA day is execution, not authoring. All output lands on main but stays un-referenced until Phase 2.

| # | Task | Lane | Depends on |
|---|------|------|-----------|
| 1.1 | v1.0.0 promotion runbook: exact command sequence (tag via release.sh, evidence bundle, marketplace sync) — dry-run everything dry-runnable | [A] | — |
| 1.2 | Migration hop 0.11.0 → 1.0.0 staged in a branch-free form (documented in runbook; hop is written on GA day since intermediate releases may intervene) | [A] | 1.1 |
| 1.3 | GA release notes + CHANGELOG `[1.0.0]` draft (promotion framing: "no behavior change; the bar was met") | [A] | — |
| 1.4 | GA blog post draft + site updates staged (hero badge, footers, blog card) in a getadd.dev branch — publish is one merge | [A] | 1.3 |
| 1.5 | Announcement drafts per `distribution-plan.md` Phase 2: Show HN, r/ClaudeAI, Product Hunt tagline+assets — **drafts only**, human posts | [A] | 1.3 |
| 1.6 | Review all Phase-1 drafts for accuracy/voice (same dual-review pattern as the GA-prep post) | [A] | 1.3–1.5 |
| 1.7 | Sign-off on drafts + runbook | [H] | 1.6 |
| 1.8 | Keep main releasable: any interim release re-runs evidence + updates the staged notes (standing rule until GA) | [A] | continuous |

**Exit:** GA day requires only: approval signal → run runbook → human posts announcements.

## Phase 2 — Approval day (trigger: [3P] Anthropic approves listing)

| # | Task | Lane | Depends on |
|---|------|------|-----------|
| 2.1 | Confirm the listing is live and installs from the official directory (`claude plugin install add` without our marketplace-add step); capture screenshots for evidence | [H] | [3P] approval |
| 2.2 | Add an official-directory leg to the Claude install smoke (install via directory listing, not just repo marketplace) | [A] | 2.1 |
| 2.3 | Execute promotion runbook: migrations hop, CHANGELOG promote, `release.sh v1.0.0` (CI-green guard), `release-evidence.sh v1.0.0 --upload` | [A] | 2.1, CI green |
| 2.4 | Maturity promotion in `.add/config.json` (beta → ga) via `/add:promote` flow — ADD dog-foods its own ladder on itself | [A] | 2.3 |
| 2.5 | Publish staged site/blog updates; sync marketplace cache; verify live | [A] | 2.3 |
| 2.6 | Final GA attestation: criterion #6 re-affirmed, milestone doc closed out | [H] | 2.3 |

**Rollback:** if anything post-tag fails, v1.0.0 is behavior-neutral by design — worst case is comms delay, never a code rollback. If the *listing* is approved-with-changes, loop to Phase 0.4 with the requested changes; do NOT tag v1.0.0 until the listing is actually live.

## Phase 3 — Launch week (starts within 72h of Phase 2)

| # | Task | Lane | Depends on |
|---|------|------|-----------|
| 3.1 | Post announcements (HN 12:01am PT, r/ClaudeAI, Product Hunt) from approved drafts | [H] | 2.5, 1.7 |
| 3.2 | Monitor and respond: issues triage within 24h, doctor-report bugs prioritized as patch candidates (v1.0.x) | [A]+[H] | 3.1 |
| 3.3 | Verify aggregator pickup (claude-plugins.dev, claudemarketplaces.com auto-index from official listing) — nudge only if absent after a week | [A] check, [H] nudge | [3P] |
| 3.4 | Refresh awesome-list entries (4 already merged per distribution-plan) to GA wording | [A] PRs, [3P] merges | 2.5 |

## Phase 4 — Post-GA (v1.1 planning)

| # | Task | Lane | Depends on |
|---|------|------|-----------|
| 4.1 | Companion-plugin spec(s) — the blog committed "specs land in the open before code"; first candidate: telemetry/analytics plugin (owns emission for the existing OTel-aligned format, closes D6) | [A] draft, [H] approve | 2.3 |
| 4.2 | Deferred hardening: doctor zsh-guard, Codex injection-scanner parity (v1.1 target per matrix), F-006/F-007 architectural items | [A] | v1.1 cycle |
| 4.3 | Retro on the GA cycle (`/add:retro`) — required before the v1.1 cycle starts per compliance cadence | [A]+[H] | 2.x complete |

## Dependency spine

```
0.2 ──► 0.3 ──► 0.4 [H] ──► 0.5 [H] ──► [3P] Anthropic review ──► 2.1 [H] ─┬─► 2.2
1.1 ──► 1.2 ─┐                                                              ├─► 2.3 ──► 2.4, 2.5 ──► 2.6 [H]
1.3 ──► 1.4, 1.5 ──► 1.6 ──► 1.7 [H] ──────────────────────────────────────┘        └─► 3.1 [H] ──► 3.2–3.4
                                                                                     └─► 4.1–4.3
```

Critical path: **0.4 → Anthropic review → 2.3**. Everything in Phase 1 is off-critical-path by design.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Review latency continues (already 5 months) | High | 0.4 re-submission resets the clock on a current artifact; 0.5 gives us a channel; Phase 1 makes the wait free. If >60 more days: [H] decision point — ship v1.0.0 anyway with criterion #5 re-worded to "submission current + channel established" (needs milestone-doc amendment, honest public note) |
| Approved-with-changes | Medium | Loop 0.4; Phase 1 assets are change-tolerant (version strings templated in runbook) |
| Interim releases drift the staged assets | Medium | 1.8 standing rule; release.sh already guards CI-green |
| Launch-week bug reports | Expected | doctor gives structured reports; 3.2 patch-candidate triage; trunk-based flow supports fast v1.0.x |

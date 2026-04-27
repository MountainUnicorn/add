# Release Materials Checklist

**Audience:** ADD maintainer running a release
**Status:** Canonical source-of-truth for post-release work
**Owner:** maintainer / future `/add:post-release` skill
**Last updated:** 2026-04-27 (drafted alongside the v0.9.4 hotfix)

This document is the single checklist for what happens AFTER `./scripts/release.sh vX.Y.Z` succeeds. The release script handles tagging, signing, pushing, and creating the GitHub release. Everything else lives here.

Two design intents:

1. **Human-runnable today.** Copy the relevant matrix into a `.add/cycles/cycle-{N}.md` and walk through.
2. **Skill-runnable tomorrow.** A planned `/add:post-release` skill (spec at [`specs/post-release-publication.md`](../specs/post-release-publication.md)) parses this file's checkboxes and walks the matrix automatically. Format conventions below are skill-friendly: `- [ ]` checkboxes, structured bullets, named sections.

Items are grouped by audience because each group runs at different cadence and in different repos. The release-type matrix at the end says which groups apply to which release shape.

## Format conventions (read first if you're maintaining this file)

Every checklist item follows:

```markdown
- [ ] **Short title** — what to do, in one line.
  - **Files:** `path/one`, `path/two` (or "N/A" if it's an external action like a GitHub Settings change)
  - **Automation:** `auto` (handled by an existing script) | `semi-auto` (script exists but invocation is manual) | `manual` (no automation today; future skill candidate)
  - **Why:** one sentence on consequence-of-skipping
```

Don't reorder items within a section without intent — a future skill walks them top-down.

## A. GitHub & repo hygiene

Run on `MountainUnicorn/add`. Most are quick verification steps after `release.sh` exits.

- [ ] **Tag is signed and verifiable.** `git tag --verify vX.Y.Z` returns "Good signature."
  - **Files:** N/A
  - **Automation:** auto (release.sh verifies before pushing)
  - **Why:** silent unsigned releases damage the supply-chain trust claim.

- [ ] **GitHub release is published with notes.** Visit `https://github.com/MountainUnicorn/add/releases/tag/vX.Y.Z`; confirm body matches the CHANGELOG section.
  - **Files:** N/A
  - **Automation:** auto (release.sh creates with `gh release create`)
  - **Why:** the release page is the canonical citation surface.

- [ ] **Marketplace cache synced.** `./scripts/sync-marketplace.sh`.
  - **Files:** writes to `~/.claude/plugins/cache/add-marketplace/add/`
  - **Automation:** semi-auto (script exists; invocation is manual)
  - **Why:** other Claude Code sessions on the maintainer machine pick up changes; without this they see stale rules.

- [ ] **All recent main CI runs are green.** `gh run list --workflow guardrails.yml --branch main --limit 3` — top three should be `completed/success`.
  - **Files:** N/A
  - **Automation:** auto (gh CLI)
  - **Why:** a red main is a release-readiness regression even if the tag itself was clean.

- [ ] **Open feature branches deleted.** Local: `git branch --merged main | grep -v main | xargs -n1 git branch -d`. Remote merged branches were already deleted by `gh pr merge --delete-branch`. Branches owned by external contributors' forks are untouched.
  - **Files:** N/A
  - **Automation:** semi-auto (one-liner; no skill yet)
  - **Why:** stale branches confuse contributors browsing the branch list.

- [ ] **Worktrees pruned.** `git worktree list | grep agent- | awk '{print $1}' | xargs -I{} git worktree remove --force {}`. Locked worktrees from agent swarms can pile up.
  - **Files:** removes `.claude/worktrees/agent-*` directories
  - **Automation:** semi-auto
  - **Why:** worktrees consume disk + show up in `git worktree list` confusion.

- [ ] **Open issues triaged.** `gh issue list --state open` — close resolved, label new, set milestone if applicable.
  - **Files:** N/A
  - **Automation:** manual (skill candidate: `/add:triage`)
  - **Why:** unresponded issues degrade maintainer reputation faster than slow features.

- [ ] **Stale draft PRs closed or moved forward.** `gh pr list --draft` — anything older than 30 days that isn't actively rebasing should be closed with a "stale, please reopen if still wanted" comment.
  - **Files:** N/A
  - **Automation:** manual
  - **Why:** abandoned drafts inflate the open-PR count and obscure live work.

- [ ] **GitHub repo Settings → Social preview re-uploaded.** If `docs/social-preview.png` changed, drag-and-drop the file into Settings → General → Social preview. The repo file alone doesn't auto-configure GitHub's social card.
  - **Files:** `docs/social-preview.png`
  - **Automation:** manual (no GitHub API for this; upload-only)
  - **Why:** social card unfurl on Twitter/LinkedIn/Slack uses the uploaded image, not the repo file.

- [ ] **Repo description + topics current.** `gh repo edit` — verify description matches the marketplace.json plugin description; topics list reflects current keywords.
  - **Files:** GitHub repo metadata only
  - **Automation:** semi-auto (`gh repo edit`)
  - **Why:** GitHub's repo discoverability surface relies on these.

## B. README & guides (this repo)

Most of these are caught by the version-bump checklist in maintainer memory, but post-release is the verification pass.

- [ ] **README badge version matches `core/VERSION`.** Line 13 in README.md should say `version-X.Y.Z-brightgreen`.
  - **Files:** `README.md`
  - **Automation:** semi-auto (in version-bump checklist; verify here)
  - **Why:** badge on the GitHub homepage is the most-glanced-at version indicator.

- [ ] **Counts in tree diagrams match `core/`.** Skills, rules, templates counts in `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `runtimes/claude/CLAUDE.md`. `tests/rule-parity/test-rule-parity.sh` enforces the rule count automatically; skills + templates are manual.
  - **Files:** `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `runtimes/claude/CLAUDE.md`
  - **Automation:** semi-auto (rule count tested; others manual)
  - **Why:** stale counts erode trust in the rest of the docs.

- [ ] **AGENTS.md regenerated.** `python3 scripts/generate-agents-md.py --write`. The PostToolUse staleness hook writes `.add/agents-md.stale` when source inputs change; manually regen at release time.
  - **Files:** `AGENTS.md`
  - **Automation:** semi-auto (generator exists; invocation manual)
  - **Why:** the dog-fooded AGENTS.md is the most-visible runtime artifact users see when cloning the repo.

- [ ] **TROUBLESHOOTING.md updated for any new error paths discovered post-release.** If users hit a regression that's already fixed in the new release, add a "Was this you?" entry.
  - **Files:** `TROUBLESHOOTING.md`
  - **Automation:** manual (judgment call per release)
  - **Why:** users hitting a fixed bug should find the fix without filing a new issue.

- [ ] **`docs/codex-install.md` version refs current.** Spot-check for hardcoded version strings.
  - **Files:** `docs/codex-install.md`
  - **Automation:** manual
  - **Why:** install docs that reference an older Codex CLI minimum mislead users.

- [ ] **`docs/release-signing.md` fingerprint unchanged.** If the GPG key rotated, update; otherwise verify nothing crept in.
  - **Files:** `docs/release-signing.md`
  - **Automation:** manual
  - **Why:** users following the verification doc must succeed against the current key.

- [ ] **`docs/runtime-dependencies.md` current.** Any new hook script that shells out to `jq` (or new tool) must be added to the per-site degradation matrix.
  - **Files:** `docs/runtime-dependencies.md`
  - **Automation:** semi-auto (the F-017 CI guard catches the `zero deps` claim regression but doesn't catch new deps being added to hooks)
  - **Why:** the F-017 honesty contract degrades silently if new deps are added without doc updates.

- [ ] **`docs/infographic.svg` version refs.** Header comment, top-right version badge, footer tagline.
  - **Files:** `docs/infographic.svg`
  - **Automation:** semi-auto (in version-bump checklist; verify here)
  - **Why:** README references the SVG; stale version badge appears on the GitHub README.

- [ ] **CHANGELOG `[Unreleased]` is empty or labeled "Pending for vX+1."** No orphan entries that should have shipped.
  - **Files:** `CHANGELOG.md`
  - **Automation:** manual
  - **Why:** orphaned `[Unreleased]` entries miss release notes.

- [ ] **`SECURITY.md` reflects current threat model.** If the release added security posture changes (new injection patterns, secret-scanner, etc.), the threat model and disclosure instructions should match.
  - **Files:** `SECURITY.md`, optionally `core/knowledge/threat-model.md`
  - **Automation:** manual
  - **Why:** GA-credibility depends on `SECURITY.md` matching reality.

## C. getadd.dev (separate repo: `MountainUnicorn/getadd.dev`)

Marketing site lives at https://getadd.dev/. Auto-deploys via GitHub Pages on push to main.

- [ ] **Hero pill: version + relevant link.** `index.html:107-109` — version pill text, link target. For material releases, link the new blog post; for hotfixes, link the previous post.
  - **Files:** `index.html`
  - **Automation:** manual
  - **Why:** the homepage hero is the call-to-attention surface for new content.

- [ ] **Metrics bar (Skills / Rules / Templates / Dependencies) match `core/`.** `index.html:118, 122, ...`.
  - **Files:** `index.html`
  - **Automation:** manual
  - **Why:** stale numbers on the homepage are the most embarrassing kind of drift.

- [ ] **Section description "N skills... M rules" current.** `index.html:782` (or wherever the Reference section sits).
  - **Files:** `index.html`
  - **Automation:** manual
  - **Why:** prose that contradicts the metrics bar above it loses credibility immediately.

- [ ] **Skills page: meta + heading + summary table.** `docs/skills.html` — `<meta name="description"`, `<h2 id="summary-table">`, the actual table rows. New skills need a `<div class="ref-card">` block plus a row in the summary table.
  - **Files:** `docs/skills.html`
  - **Automation:** manual (skill candidate: generate from `core/skills/`)
  - **Why:** the skills reference is the most-deep-linked technical doc.

- [ ] **Footer version bumped across ALL HTML pages.** `index.html`, `blog/index.html`, every `blog/*.html`, `docs/*.html`, `guides/*.html`, `404.html`, `privacy.html`, `terms.html`. Search `ADD v[0-9]\.[0-9]\.[0-9]` to find every site.
  - **Files:** `**/*.html`
  - **Automation:** semi-auto (`sed -i ''` one-liner over the file glob)
  - **Why:** mismatched footers across pages signal "this site is unmaintained."

- [ ] **New blog post drafted for material releases.** Skip for hotfixes and pure-cosmetic patches. Format matches `blog/multi-runtime-v0.7.html` and `blog/learnings-optimization-v0.8.html`.
  - **Files:** `blog/<topic>-v<X.Y>.html` (new)
  - **Automation:** manual (skill candidate: generate from CHANGELOG)
  - **Why:** the blog is the only narrative surface for users; without posts, the release page is the only story.

- [ ] **Blog index entry added.** `blog/index.html` — new `<article class="blog-card">` at the top.
  - **Files:** `blog/index.html`
  - **Automation:** manual
  - **Why:** blog index is what visitors browse; without an entry, the post is unfindable.

- [ ] **Sitemap.xml updated.** Add new blog post URL with `<lastmod>` of release date; bump `<lastmod>` on `index.html`, `docs/`, `docs/skills`, `blog/` if their content changed.
  - **Files:** `sitemap.xml`
  - **Automation:** manual
  - **Why:** search engines re-index based on lastmod hints.

- [ ] **Social preview SVG/PNG regenerated.** Edit version pill in `docs/social-preview.svg` (the upstream plugin repo); re-render with `rsvg-convert -w 1280 -h 640 docs/social-preview.svg -o docs/social-preview.png`. **Then re-upload the PNG to GitHub Settings → Social preview** (manual step in GitHub UI; the repo file alone doesn't update the social card).
  - **Files:** `docs/social-preview.svg`, `docs/social-preview.png` (in `MountainUnicorn/add`, NOT in the website repo)
  - **Automation:** semi-auto (rsvg-convert exists; upload step is manual)
  - **Why:** social card on Twitter/LinkedIn/Slack/Bluesky is the highest-leverage promotion surface.

- [ ] **Infographic SVG version refs.** `docs/infographic.svg` (in upstream plugin repo) — header comment, top-right badge, footer tagline.
  - **Files:** `docs/infographic.svg`
  - **Automation:** manual
  - **Why:** README's primary visual is this SVG; stale version badge propagates to every clone.

- [ ] **GitHub Pages deploy is green.** `gh run list --repo MountainUnicorn/getadd.dev --workflow "Deploy to GitHub Pages" --limit 1` should show `completed/success`.
  - **Files:** N/A
  - **Automation:** auto (gh CLI)
  - **Why:** a failed Pages deploy means the site is stale despite the commit landing.

- [ ] **Live verification.** `curl -sI https://getadd.dev/` returns 200; visit the homepage in a private window; verify metrics bar values match expected; visit the new blog post URL.
  - **Files:** N/A
  - **Automation:** semi-auto (curl + visual)
  - **Why:** Pages deploy can succeed but content can be wrong (cache, bad URL, etc.).

- [ ] **Social card unfurl test.** Paste the new blog post URL into a card debugger (e.g., Slack message preview, Twitter card validator, LinkedIn post preview).
  - **Files:** N/A
  - **Automation:** manual
  - **Why:** OG metadata mistakes only surface in the unfurl, not the rendered page.

## D. Contributors

If the release includes community contributions, this section is mandatory. For pure-maintainer releases, the steps marked `community-only` skip.

- [ ] **`CONTRIBUTORS.md` updated.** Flip `pending` → `vX.Y.Z` for any merged community PR. Add new first-time contributors with their handle + brief role.
  - **Files:** `CONTRIBUTORS.md`
  - **Automation:** manual
  - **Why:** contributor visibility is part of the methodology — ADD treats agents AND humans as team members.

- [ ] **Release notes thank contributors by handle.** When `release.sh` ran, the body came from CHANGELOG. If the CHANGELOG entry already cites the contributor, the GitHub release inherits it. Verify the cite exists.
  - **Files:** GitHub release body (already published; can be edited)
  - **Automation:** semi-auto
  - **Why:** named credit is the contributor's payment.

- [ ] **First-time contributor call-out.** If anyone shipped their first ADD contribution this release, add a "Welcome" line to the release notes and (if material) a sentence in the blog post.
  - **Files:** GitHub release body, blog post (if exists)
  - **Automation:** manual
  - **Why:** first-time contributor moments compound — visible recognition recruits the next first-timer.

- [ ] **Memory's `community_pr_handling.md` updated if process evolved.** If the release surfaced a new pattern in how community PRs were handled (e.g., the v0.9.2 maintainer-edits-on-fork rebase), capture it.
  - **Files:** `~/.claude/projects/-Users-abrooke-projects-add/memory/community_pr_handling.md`
  - **Automation:** manual
  - **Why:** every cycle of community work makes the process slightly better; capture the delta.

- [ ] **Reach out for confirmation.** If the contributor wanted to be the one announcing it (Twitter/LinkedIn/personal blog), give them the GitHub release URL and tag artifact + offer a quote.
  - **Files:** N/A (external comms)
  - **Automation:** manual
  - **Why:** narrative ownership matters; the contributor's networks may dwarf the project's.

## Release-type matrix

Not every release runs every item. Use this matrix to scope the cycle.

| Item | Hotfix | Patch | Minor | Major | Community |
|------|--------|-------|-------|-------|-----------|
| All A. GitHub & repo hygiene | ✓ | ✓ | ✓ | ✓ | ✓ |
| README badge + counts | ✓ | ✓ | ✓ | ✓ | ✓ |
| AGENTS.md regen | only if rules/skills changed | only if rules/skills changed | ✓ | ✓ | ✓ |
| TROUBLESHOOTING.md update | only if new error paths | optional | ✓ | ✓ | optional |
| Site footer bump | ✓ | ✓ | ✓ | ✓ | ✓ |
| Site metrics bar | only if changed | only if changed | ✓ | ✓ | ✓ |
| New blog post | optional | optional | ✓ | ✓ | ✓ |
| Blog index + sitemap | only if blog post | only if blog post | ✓ | ✓ | ✓ |
| Social preview update | only if visual changed | only if visual changed | usually | ✓ | only if visual changed |
| Infographic SVG | no | no | ✓ | ✓ | no |
| Contributor acknowledgment | N/A | N/A | applies | applies | ✓ (mandatory) |

**Definitions:**

- **Hotfix** — patch release fixing a shipping bug. v0.8.1, v0.9.4 fit.
- **Patch** — point release with cosmetic / non-feature changes. v0.7.1, v0.7.2 fit.
- **Minor** — new features, no breaking changes. v0.8.0, v0.9.0, v0.9.3 fit.
- **Major** — breaking changes. v1.0.0 will be the first.
- **Community** — at least one merged contribution from a non-maintainer. v0.7.0, v0.8.0, v0.9.2 fit.

A release can be multiple types simultaneously (e.g., v0.9.2 was Minor + Community). Run the union of items.

## Open follow-ups (carry forward to the v0.9.x → v1.0 arc)

These accumulate as the canonical checklist matures. Each is a candidate item for promotion into a section above when stable.

- [ ] **Generate site metrics from `core/`.** Currently the website's metrics bar and skills count are hand-edited. A small script that reads `core/skills/`, `core/rules/`, `core/templates/` and rewrites the corresponding HTML strings would close this gap. (Touches: `scripts/sync-site-metrics.py`, `MountainUnicorn/getadd.dev/index.html`, `docs/skills.html`.)
- [ ] **Generate skills page from `core/skills/`.** The biggest manual maintenance burden — every new skill needs a `<div class="ref-card">` written by hand plus a summary-table row. A generator is in scope for the M4 architectural milestone (it's the cousin of `/add:agents-md`).
- [ ] **CHANGELOG → blog post draft.** A reasonable first cut of the post can be drafted from the CHANGELOG section. Skill candidate: `/add:announce vX.Y.Z` produces `blog/<slug>-v<X.Y>.html` scaffold.
- [ ] **`/add:post-release` skill.** Walks this checklist top-down, checking automated items, prompting on manual items, marking checkboxes complete in a session log. Spec at [`specs/post-release-publication.md`](../specs/post-release-publication.md).

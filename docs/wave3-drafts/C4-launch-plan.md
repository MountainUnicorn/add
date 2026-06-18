# Draft C4 — GA launch plan + `/add:announce` sketch

> **STATUS: DRAFT for maintainer review (v0.9.7 positioning).** A
> checklist/strategy doc — NOT code, NOT applied to canonical files. Sequenced
> against the v1.0 timeline in `docs/v1.0-roadmap.md`.

---

## Scope of this doc

1. Plugin-directory submission checklist (third-party catalogs).
2. GitHub Discussions announcement seed.
3. The "ADD" / "Agent Driven Development" name-collision + SEO situation, and
   how to differentiate via the **getadd.dev** brand.
4. A sketch of what an `/add:announce` skill would generate.
5. What lives in **this** repo vs the separate `MountainUnicorn/getadd.dev` repo.
6. Sequencing against the v1.0 release arc.

> **Naming note up front:** `docs/v1.0-roadmap.md` already defines a v0.9.7
> `/add:announce` skill scoped as **CHANGELOG → blog-post draft**. This draft
> proposes a *broader* `/add:announce` that also emits launch/announcement
> copy (directory blurbs, Discussions seed, social). The maintainer must
> decide: **one skill with `--target` modes** (blog / directory / discussion /
> social) or **two skills** (`/add:announce` for blog, `/add:launch` for the GA
> push). Recommended: one skill, multiple targets — see § 4.

---

## 1. Plugin-directory submissions

Third-party Claude Code plugin catalogs. These are **external** submissions, not
the official Anthropic marketplace registry (that submission is tracked as a
v1.0.0 GA item / GA criterion in the roadmap, separate from these).

| Directory | What it wants | Owner | Pre-reqs |
|---|---|---|---|
| **claude-plugins.dev** | Repo URL, plugin manifest, description, category, install command | maintainer | Verify listing format; confirm `plugin.json` metadata is current |
| **claudepluginhub** | Similar; often a PR to a registry repo or a submission form | maintainer | Screenshot/infographic asset; one-line + long description |
| **claudex.directory** | Listing entry; tags | maintainer | Canonical description; getadd.dev link |

**Per-directory checklist (do once each):**
- [ ] Confirm exact submission mechanism (form vs PR vs issue) — *verify live; these change.*
- [ ] Canonical one-liner: "ADD — the maturity-governed methodology layer for AI-native development (Claude Code + Codex)."
- [ ] Long description sourced from README hero (post-D4 if D4 lands).
- [ ] Category: methodology / workflow / SDLC (NOT "code generation").
- [ ] Install command: `claude plugin marketplace add MountainUnicorn/add` + `claude plugin install add@add-marketplace`.
- [ ] Asset: `docs/infographic.svg` or a directory-sized PNG.
- [ ] Link: https://getadd.dev (brand anchor — see § 3).
- [ ] Record the submission + URL in `docs/release-materials.md` so it's tracked.

**Sequencing:** submit to third-party directories at the **v0.9.7–v0.10 window**,
NOT at v1.0. Rationale: directories drive early adopters who file the regressions
the 60-day beta gate needs (roadmap GA criterion: "20+ projects" is currently 3).
Reserve the **official Anthropic marketplace submission** for the v1.0.0 cycle
(it's a published GA criterion and a heavier review).

---

## 2. GitHub Discussions announcement seed

Post in `MountainUnicorn/add` → Discussions → Announcements. Draft seed below
(maintainer edits voice):

```
# ADD v1.0 — the maturity-governed methodology for AI-native development

ADD (Agent Driven Development) is a methodology + Claude Code plugin (with a
Codex CLI adapter) built around one idea: **a maturity dial that scales all
process rigor.** poc → alpha → beta → ga. A throwaway prototype gets near-zero
ceremony; production infrastructure gets exhaustive verification. One dial,
the rest cascades.

What's in v1.0:
- The maturity ladder + cascade (the trust-gradient, implemented)
- Spec → plan → cycle → retro → milestone methodology lifecycle
- Trust-but-verify sub-agent roles (test-writer / implementer / reviewer / verify)
- Multi-runtime: one source of truth in core/, compiled to Claude + Codex
- Cross-project learnings that compound across projects

Honest about limits: hook-based enforcement is full on Claude, warn-only on
Codex (see SECURITY.md). We say so on purpose.

Install: `claude plugin marketplace add MountainUnicorn/add`
Docs: https://getadd.dev

Tell us what maturity level your project is at — and what the cascade got wrong
for your stack. That feedback is what moves us off beta.
```

Notes:
- Lead with the moat (maturity), not the feature list (roadmap Part 6).
- The "honest about limits" paragraph is deliberate — matches AC-027 / the
  honesty-audit posture (roadmap Part 1). Builds credibility, pre-empts the
  "GA security against OWASP" critique.
- End with a feedback ask tied to the beta-stability window.

---

## 3. Name-collision + SEO situation

**The problem.** "ADD" and "Agent Driven Development" are not uniquely ours:
- **agentdriven.dev** appears to occupy the literal "Agent Driven Development"
  domain/term.
- A **dev.to article** ranks for "agent driven development" and may define the
  term differently.
- "ADD" is also a heavily overloaded acronym (the medical one dominates search).

*Verify live before launch:* current SERP for "agent driven development",
who owns agentdriven.dev, and the dev.to article's framing. Don't assume the
landscape is static.

**The strategy — differentiate via the getadd.dev brand, not the generic term.**

1. **Brand on "getADD.dev," not "ADD."** The product brand is the *site*:
   getadd.dev. In copy, prefer "ADD (getadd.dev)" or "the ADD methodology" over
   bare "ADD." This is the controllable, ownable surface.
2. **Own a specific phrase, not the generic one.** Don't fight for "agent driven
   development" head-on (contested + ambiguous). Own **"maturity-governed agent
   development"** / **"the trust-gradient methodology"** / **"the maturity dial
   for AI agents."** These are uncontested and they *are* the moat.
3. **Disambiguation copy** on getadd.dev: a one-liner distinguishing ADD-the-
   methodology from the dev.to/agentdriven.dev usage — "ADD is the maturity-
   governed methodology implemented as a Claude Code plugin," with the cascade
   ladder front and center. Turns the collision into a positioning contrast.
4. **SEO mechanics (getadd.dev repo):** title tags + meta descriptions anchored
   on the ownable phrases; structured data (SoftwareApplication); a canonical
   "What is ADD?" page; backlinks from the GitHub repo, directory listings, and
   the Discussions post. This is a **getadd.dev** workstream.
5. **Brand split decision (roadmap D5).** The maintainer's deferred call —
   ADD-the-plugin vs ADD-the-methodology + ADD-the-plugin. The launch can
   proceed under single-brand; revisit two-brand post-v1.0. Flagged, not blocking.

---

## 4. `/add:announce` skill — sketch

> A *sketch* of intended behavior, for the maintainer to react to. Not a spec,
> not code. Reconciles with the roadmap's CHANGELOG→blog `/add:announce`.

**Proposal: one skill, multiple targets.**

```
/add:announce [--target blog|directory|discussion|social|all]
              [--version X.Y.Z] [--dry-run]
```

| Target | Input | Output (draft only — maintainer edits before publishing) |
|---|---|---|
| `blog` *(roadmap default)* | CHANGELOG `[X.Y.Z]` section | `blog/<slug>-v<X.Y>.html` scaffold in the getadd.dev repo |
| `directory` | README hero + command catalog | One-liner + long description + category + install block per directory (§ 1) |
| `discussion` | CHANGELOG + moats | GitHub Discussions announcement markdown (§ 2 shape) |
| `social` | CHANGELOG headline + moat | Short post variants (X/LinkedIn/Mastodon), maturity-led |
| `all` | above | A `docs/announce/<version>/` bundle of all of the above |

**Behavior:**
- Reads `core/VERSION` + `CHANGELOG.md` `[X.Y.Z]` + README hero as sources.
- **Maturity-led copy by default** — every output leads with the maturity ladder
  moat, not the feature list (enforces Part 6 positioning automatically).
- **Honest-limits insert** — pulls the Codex warn-only caveat from SECURITY.md so
  announcements don't overclaim (AC-027 alignment).
- **Draft-only + idempotent** — writes to a drafts location, never publishes;
  re-runs overwrite the draft. Mirrors `/add:post-release` and `/add:promote`
  patterns (gap-analysis → present → human acts).
- **Dry-run** prints to stdout without writing.
- **Allowed-tools:** Read, Write, Glob, Bash (read git/changelog) — no network,
  no publish. Publishing stays human + lives in getadd.dev.

**Where it overlaps `/add:post-release`:** post-release runs the *ritual*
(directory submission tracking, checklist); `/add:announce` *generates the copy*
the ritual then uses. Keep announce = content generator, post-release =
orchestration/checklist. (Maintainer: confirm this division.)

---

## 5. This repo vs getadd.dev repo

| Artifact | Repo |
|---|---|
| `/add:announce` skill (`core/skills/announce/`) | **this** (`MountainUnicorn/add`) |
| GitHub Discussions post | **this** (Discussions tab) |
| Directory submission tracking in `docs/release-materials.md` | **this** |
| Blog post HTML (`blog/<slug>.html`) | **getadd.dev** (separate, private) |
| Hero/disambiguation/SEO copy, meta tags, structured data | **getadd.dev** |
| Footer version bumps | **getadd.dev** (per MEMORY.md version-bump step 9) |
| Site metrics / skills-page generators (roadmap v0.9.7 F-019) | inputs from **this** repo's `core/`; rendered into **getadd.dev** |

The open-source plugin stays clean; all commercial/marketing surface stays in
getadd.dev (the reason it was extracted 2026-04-22).

---

## 6. Sequencing against the v1.0 arc

| Release | Date target | Launch actions |
|---|---|---|
| **v0.9.7** | ~2026-05-23 | Ship `/add:announce` (roadmap already schedules it here — propose broadening to multi-target). Draft directory blurbs. Draft Discussions seed. getadd.dev: disambiguation page + SEO meta + maturity-led hero (pairs with Draft D4). |
| **v0.10** | ~2026-06-13 | Submit to third-party directories (claude-plugins.dev, claudepluginhub, claudex.directory) — drive early adopters toward the "20+ projects" GA criterion. Track in `release-materials.md`. |
| **v0.11** | ~2026-07-04 | Codex-coherence cycle; ensure directory listings reflect honest per-runtime matrix. |
| **v1.0.0 GA** | ~2026-06-25–07-11 | Official Anthropic marketplace submission (published GA criterion). Final Discussions GA announcement. Blog launch post (getadd.dev). Social push. All copy via `/add:announce --target all`. |

**Calendar gate** (roadmap D7): 60-day beta stability, earliest honest v1.0 =
2026-06-22. Directory launches at v0.9.7–v0.10 are *deliberately before* GA so
real usage accrues during the beta window. The GA announcement is the
amplification, not the first contact.

---

## Open questions for the maintainer

1. **One skill or two?** `/add:announce` with `--target` modes (recommended) vs
   separate `/add:announce` (blog) + `/add:launch` (GA push)?
2. **announce vs post-release boundary:** announce = content generator,
   post-release = checklist/orchestration — confirm?
3. **Brand strategy (roadmap D5):** launch single-brand now, revisit two-brand
   post-v1.0 — agree?
4. **Ownable phrase:** "maturity-governed agent development" vs "the trust-
   gradient methodology" vs "the maturity dial for AI agents" — which to anchor
   SEO on?
5. **Directory timing:** confirm third-party directories at v0.9.7–v0.10
   (pre-GA) vs holding all launch to v1.0.
6. **Verify-live items before launch:** exact submission mechanisms per
   directory; current SERP + agentdriven.dev / dev.to ownership for the
   collision strategy.

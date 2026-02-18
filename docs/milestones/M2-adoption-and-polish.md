# Milestone: M2 — Adoption & Polish

**Target Maturity:** alpha
**Status:** IN_PROGRESS
**Started:** 2026-02-10
**Completed:** TBD

## Goal

Make ADD easy to adopt on existing projects, refine based on dogfooding feedback, and add the branding, infographic, and session continuity capabilities that emerged from real usage.

## Success Criteria

- [ ] `/add:init --adopt` command with legacy project detection
- [x] Enhanced spec interview workflow
- [x] Better away/back mode context preservation (session continuity)
- [x] Integration with dossierFYI dogfooding project
- [ ] Comprehensive user documentation + video walkthrough
- [ ] Retro template automation
- [x] Learning library cross-project search
- [x] Branding system (`/add:brand`, `/add:brand-update`)
- [x] Image gen detection for branded visuals
- [x] Auto-changelog from conventional commits
- [x] Infographic generation skill
- [x] Session continuity & self-evolution (handoff, swarm state, observations, mutations)

## Appetite

Ongoing refinement across multiple cycles. Features are scope-boxed individually.

## Features

### Hill Chart

```
Branding System               ████████████████████████████████████  DONE
Image Gen Detection            ████████████████████████████████████  DONE
Auto-Changelog                 ████████████████████████████████████  DONE
Infographic Generation         ████████████████████████████████████  DONE
Session Continuity & Evolution ████████████████████████████████████  DONE
Legacy Adoption (/add:init)    ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — shaped, needs spec
Learning Library Search         ████████████████████████████████████  DONE
User Documentation             ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not started
Retro Template Automation      ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not started
```

### Feature Detail

| Feature | Spec | Position | Status | Cycle |
|---------|------|----------|--------|-------|
| Branding System | specs/branding-system.md | DONE | /add:brand + /add:brand-update shipped | — |
| Image Gen Detection | specs/image-gen-detection.md | DONE | Auto-detects imagen availability | — |
| Auto-Changelog | specs/auto-changelog.md | DONE | /add:changelog from conventional commits | — |
| Infographic Generation | specs/infographic-generation.md | DONE | /add:infographic SVG from PRD + config | — |
| Session Continuity & Evolution | specs/session-continuity-and-self-evolution.md | DONE | 34/34 ACs — handoff, swarm, observations, mutations, maturity assessment | — |
| Legacy Adoption | — | SHAPED | /add:init --adopt with project detection | — |
| Learning Library Search | specs/learning-library-search.md | DONE | JSON storage, smart filtering, scope classification, migration | — |
| User Documentation | — | SHAPED | Docs + video walkthrough | — |
| Retro Template Automation | — | SHAPED | Extract lessons automatically | — |

## Dependencies

None — M2 is self-contained. dossierFYI dogfooding provides feedback but isn't a blocker.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Legacy adoption scope too broad (monorepos, multilang) | MED | MED | Start with single-language projects; expand detection gradually |
| Learning library search perf at scale (1000+ entries) | LOW | LOW | JSON scan benchmarked <2s; optimize only if needed |
| Plugin namespace drift in new commands | MED | HIGH | Enforced via namespace-fix pattern; all refs use /add: prefix |

## Cycles

| Cycle | Features Advanced | Status | Outcome |
|-------|-------------------|--------|---------|
| (pre-cycle) | Branding, Image Gen, Changelog, Infographic | COMPLETE | v0.2.0 shipped |
| (pre-cycle) | Session Continuity & Evolution | COMPLETE | 34/34 ACs, v0.3.0 shipped |
| next | Learning Library Search, Milestone Files | PLANNED | Spec-first for library search; milestone files from PRD |

## Retrospective Notes

### First Retro (2026-02-17)
- All 5 specs marked Complete
- "Spec-before-code" promoted to Tier 1 knowledge (non-negotiable going forward)
- dossierFYI dogfooding feedback drove v0.2 → v0.3 feature set
- Version bumps touch 30 files — consider automation

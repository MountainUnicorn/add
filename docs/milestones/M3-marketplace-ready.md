# Milestone: M3 — Marketplace Ready

**Target Maturity:** beta
**Status:** NOT_STARTED
**Started:** TBD
**Completed:** TBD

## Goal

Production-grade plugin ready for broad distribution — marketplace approval, multi-environment support, CI/CD hooks, and community-contributed templates.

## Success Criteria

- [ ] Marketplace submission package fully compliant
- [ ] Multi-environment Tier 2/Tier 3 support (prod deployment workflows)
- [ ] Advanced learnings system: agent auto-checkpoints + human retros
- [ ] CI/CD hooks: pre-commit lint, pre-push gate, test automation
- [ ] Quality gates dashboard (status per project + org-wide metrics)
- [ ] Template marketplace (community-contributed templates)
- [ ] Profile system: team conventions auto-loaded on project init
- [ ] Enhanced verify skill: semantic testing, regression detection

## Appetite

Full development cycle — Q2 2026 target. Scope to be refined after M2 completes.

## Features

### Hill Chart

```
Marketplace Submission         ████████░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — submitted, awaiting review
Multi-Environment Support      ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not started
CI/CD Hooks                    ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not started
Quality Gates Dashboard        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not shaped
Template Marketplace           ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not shaped
Profile System                 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not shaped
Enhanced Verify                ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  uphill — not shaped
```

### Feature Detail

| Feature | Spec | Position | Status | Cycle |
|---------|------|----------|--------|-------|
| Marketplace Submission | — | SHAPED | Submitted via clau.de/plugin-directory-submission; Anthropic reviews at HEAD | — |
| Multi-Environment Support | — | SHAPED | Tier 2/3 configs, prod deployment workflows | — |
| CI/CD Hooks | — | SHAPED | GitHub Actions integration for gates | — |
| Quality Gates Dashboard | — | NOT_SHAPED | Org-wide metrics and per-project status | — |
| Template Marketplace | — | NOT_SHAPED | Community-contributed templates | — |
| Profile System | — | NOT_SHAPED | Team conventions auto-loaded on init | — |
| Enhanced Verify | — | NOT_SHAPED | Semantic testing, regression detection | — |

## Dependencies

- M2 must complete — learning library search and legacy adoption inform marketplace readiness
- Marketplace approval from Anthropic (external dependency)
- Community feedback from early adopters

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Marketplace format changes before approval | LOW | HIGH | Track Claude Code plugin spec; stay in contact with Anthropic |
| CI/CD integration complexity varies by host (GitHub, GitLab, etc.) | MED | MED | Start with GitHub Actions only; expand based on demand |
| Template marketplace curation overhead | MED | MED | Start with curated set; add community submissions with review gate |
| Multi-env testing requires real infrastructure | MED | HIGH | Use dossierFYI as Tier 2 testbed before generalizing |

## Cycles

No cycles planned yet — M2 completion will inform cycle planning.

## Retrospective Notes

*To be filled when milestone completes.*

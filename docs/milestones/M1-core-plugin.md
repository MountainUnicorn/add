# Milestone: M1 — Core Plugin

**Target Maturity:** alpha
**Status:** COMPLETE
**Started:** 2026-02-07
**Completed:** 2026-02-10

## Goal

Ship a working ADD plugin with spec-driven development, TDD enforcement, human-AI collaboration, and environment awareness — proving the methodology works by dogfooding it on itself.

## Success Criteria

- [x] 6 commands implemented and working
- [x] 8 skills implemented and composable
- [x] 10 rules enforcing ADD principles
- [x] 10 templates available for all core artifacts
- [x] 1 hooks file (auto-lint on Write/Edit)
- [x] 2 manifests (plugin.json, marketplace.json) valid for Claude Code
- [x] Dogfooding on dossierFYI project
- [x] PRD published and approved

## Appetite

Initial build sprint — exploratory until proof of concept validated.

## Features

### Hill Chart

```
Spec-Driven Development      ████████████████████████████████████  DONE
TDD Enforcement               ████████████████████████████████████  DONE
Human-AI Collaboration         ████████████████████████████████████  DONE
Environment Awareness          ████████████████████████████████████  DONE
Project Initialization         ████████████████████████████████████  DONE
Learning System                ████████████████████████████████████  DONE
Quality Gates                  ████████████████████████████████████  DONE
Maturity Lifecycle             ████████████████████████████████████  DONE
```

### Feature Detail

| Feature | Spec | Position | Status | Cycle |
|---------|------|----------|--------|-------|
| Spec-Driven Development | — (core) | DONE | 6 commands, spec template, spec-driven rule | — |
| TDD Enforcement | — (core) | DONE | tdd-cycle, test-writer, implementer skills + rule | — |
| Human-AI Collaboration | — (core) | DONE | away/back commands, engagement modes, collaboration rule | — |
| Environment Awareness | — (core) | DONE | Tiered config, deploy skill, environment rule | — |
| Project Initialization | — (core) | DONE | /add:init command, config/settings templates | — |
| Learning System | — (core) | DONE | Checkpoints, learnings template, library | — |
| Quality Gates | — (core) | DONE | 5-gate system, verify skill, hooks | — |
| Maturity Lifecycle | — (core) | DONE | poc/alpha/beta/ga cascade, maturity rule | — |

## Dependencies

None — M1 was self-contained (pure markdown/JSON, no external deps).

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Plugin format changes before marketplace launch | LOW | MED | Track Claude Code plugin spec; markdown/JSON is stable |
| Too many autoloaded rules consume context | MED | MED | Measured at ~14K tokens (7%); acceptable for now, optimize in M2 |

## Cycles

| Cycle | Features Advanced | Status | Outcome |
|-------|-------------------|--------|---------|
| (pre-cycle) | All 8 features | COMPLETE | Full v0.1.0 shipped, dogfooded on dossierFYI |

## Retrospective Notes

### What Went Well
- Pure markdown/JSON approach validated — zero runtime dependencies, instant setup
- Dogfooding on dossierFYI proved the methodology works on real projects
- Plugin format cleanly maps to Claude Code ecosystem

### What Was Harder
- 10 autoloaded rules consume ~14K tokens — context budget concern at scale
- Away/back mode needed better context preservation (addressed in M2)

### Learnings
- Spec-before-code discipline prevents wasted implementation effort
- Maturity lifecycle cascade keeps rigor appropriate to project stage
- Plugin namespace must always be explicit (`/add:spec` not `/spec`)

### Maturity Readiness
- M1 completion validated alpha maturity for the ADD project itself

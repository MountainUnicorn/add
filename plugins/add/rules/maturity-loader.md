---
autoload: true
maturity: poc
description: "Maturity-aware rule loader — controls which rules are active based on project maturity level"
---

# ADD Rule: Maturity-Aware Rule Loading

## Purpose

Not all rules apply to all projects. Each rule declares a minimum maturity level via `maturity:` frontmatter. This loader instructs agents to respect those boundaries.

## How It Works

1. Read `.add/config.json` and extract the `maturity` field (poc, alpha, beta, ga)
2. Each rule file in `rules/` has a `maturity:` frontmatter field
3. **Only follow rules at or below the project's maturity level.** Ignore rules above it.

## Maturity Hierarchy

```
poc < alpha < beta < ga
```

A project at `alpha` loads `poc` + `alpha` rules. A project at `beta` loads `poc` + `alpha` + `beta` rules. And so on.

## Rule Loading Matrix

| Rule | POC | Alpha | Beta | GA |
|------|-----|-------|------|-----|
| `project-structure` | **active** | active | active | active |
| `learning` | **active** | active | active | active |
| `source-control` | **active** | active | active | active |
| `maturity-loader` (this rule) | **active** | active | active | active |
| `version-migration` | **active** | active | active | active |
| `spec-driven` | dormant | **active** | active | active |
| `quality-gates` | dormant | **active** | active | active |
| `human-collaboration` | dormant | **active** | active | active |
| `tdd-enforcement` | dormant | dormant | **active** | active |
| `agent-coordination` | dormant | dormant | **active** | active |
| `environment-awareness` | dormant | dormant | **active** | active |
| `maturity-lifecycle` | dormant | dormant | **active** | active |
| `design-system` | dormant | dormant | dormant | **active** |

## Agent Instructions

**At the start of every task:**

1. Read `.add/config.json` to determine the project maturity level
2. If a rule's `maturity:` level is ABOVE the project's level, **treat that rule as non-existent** — do not follow its instructions, do not reference it, do not enforce it
3. If no `.add/config.json` exists, assume `alpha` maturity (reasonable default)

**Example:** A project at `alpha` maturity has 6 active rules (project-structure, learning, source-control, maturity-loader, spec-driven, quality-gates, human-collaboration). The agent should NOT enforce TDD cycles, agent coordination protocols, environment-awareness tiers, or design system rules — those are dormant until the project promotes to beta or ga.

## Why This Matters

Loading all rules for all projects wastes context on instructions that don't apply. A POC project doesn't need 5-level quality gates. An alpha project doesn't need multi-agent coordination. The maturity dial controls rigor — and that starts with which rules are even active.

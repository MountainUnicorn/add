---
autoload: true
maturity: poc
description: "Maturity-aware rule loader — controls which rules are active based on project maturity level"
---

# ADD Rule: Maturity-Aware Rule Loading

## Purpose

Not all rules apply to all projects. Each rule declares a minimum maturity level via `maturity:` frontmatter; only rules at or below the project's level are active. Since v0.9.9 this gating is **physical**: the SessionStart hook (`hooks/load-rules.sh`) reads `.add/config.json` → `maturity.level` and injects only the active rules into context — dormant rules cost zero tokens, not just zero obedience.

## Maturity Hierarchy

```
poc < alpha < beta < ga
```

A project at `alpha` loads `poc` + `alpha` rules. A project at `beta` loads `poc` + `alpha` + `beta` rules. And so on. Each rule's gate is its `maturity:` frontmatter key — the frontmatter is the single source of truth (there is no separate matrix to drift).

## How Loading Works

1. **Hook path (normal):** at SessionStart, `load-rules.sh` injects a `# ADD Rules (project maturity: <level>)` block containing every active rule body, plus a one-line list of dormant and on-demand rules. If that block is in your context, the gating already happened — follow what was loaded, and treat listed dormant rules as non-existent.
2. **Fallback path (hooks disabled or failed):** if no `# ADD Rules` block appears in context, Read `.add/config.json` for `maturity.level`, then Read each file in `${CLAUDE_PLUGIN_ROOT}/rules/` whose `maturity:` gate is at or below that level (skip `autoload: false` rules — those load on demand via skill `references:`).
3. **No `.add/config.json`:** the full rule set loads (fail-open — the project hasn't declared a maturity yet; `/add:init` establishes one).

## Agent Instructions

- **Treat dormant rules as non-existent** — do not follow, reference, or enforce a rule whose gate is above the project level. They activate automatically after `/add:promote`.
- Do not re-read `rules/` mid-session to "check" dormant rules; the dial moves only via `/add:promote`, which tells you when it does.

## Why This Matters

Loading all rules for all projects wastes context on instructions that don't apply. A POC project doesn't need 5-level quality gates or multi-agent coordination protocols — and with physical loading it no longer pays ~13k tokens per session for them. The maturity dial controls rigor, starting with which rules even enter context.

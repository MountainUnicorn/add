# ADD — Agent Driven Development

A methodology plugin for Claude Code where AI agents are first-class development team members.

## Install

**Marketplace (recommended):**

```bash
claude plugin marketplace add MountainUnicorn/add
claude plugin install add@add-marketplace
```

**Source install:**

```bash
claude plugin install --source https://github.com/MountainUnicorn/add
```

**Verify installation:**

```
/add:init
```

## Quick Start

1. `/add:init` — Bootstrap ADD in your project (structured interview)
2. `/add:spec "feature name"` — Create a feature specification
3. `/add:plan specs/feature.md` — Generate implementation plan
4. `/add:tdd-cycle specs/feature.md` — Full TDD cycle (RED → GREEN → REFACTOR → VERIFY)
5. `/add:verify` — Run quality gates
6. `/add:deploy` — Environment-aware deployment

## Documentation

- [Full docs](https://getadd.dev/docs/) — Getting started, configuration, knowledge system
- [Plugin internals](./CLAUDE.md) — Commands, skills, rules reference

## SKILL.md Frontmatter — ADD Extensions

ADD extends the Claude Code SKILL.md format with three plugin-specific frontmatter fields. These are **ADD conventions, not part of the Anthropic Claude Code plugin spec.** They're enforced by ADD's own schema validation (see `schemas/skill-frontmatter.schema.json`), not by Claude Code itself.

```yaml
---
description: "[ADD v0.9.1] One-line purpose — the [ADD v{X}] prefix is an ADD convention"
argument-hint: "<spec-file> [--ac AC-001,AC-002]"       # ADD extension
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]    # ADD extension
---
```

| Field | Purpose | Why it's ADD-specific |
|-------|---------|----------------------|
| `argument-hint` | Human-readable description of expected arguments (displayed in `/add:help` and autocomplete) | Not standardized by Anthropic. ADD uses it consistently across all 26 skills. |
| `allowed-tools` | Array of Claude Code tool names this skill is permitted to invoke. Provides a second-layer permission boundary independent of Claude Code's approval system. | Not part of the public plugin spec. ADD treats it as a security invariant — skills must not request tools they don't use, and PR reviewers check for scope creep. |
| `[ADD vX.Y.Z]` prefix on description | Makes the plugin version visible in every autocomplete suggestion — helps users spot stale installs. | ADD convention; keeps the version bump checklist actionable. |

## ADD Rule Frontmatter

Rules in `rules/*.md` use two custom frontmatter fields:

```yaml
---
autoload: true          # ADD extension — rule is loaded automatically
maturity: alpha         # ADD extension — minimum maturity level for this rule to activate
---
```

The `maturity-loader.md` rule reads the project's maturity from `.add/config.json` and filters which rules apply. Rules above the project's level are treated as non-existent.

## License

MIT

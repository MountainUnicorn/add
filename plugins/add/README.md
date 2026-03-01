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

## License

MIT

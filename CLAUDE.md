# ADD Development Guide

This repository contains the ADD (Agent Driven Development) plugin and its surrounding ecosystem (website, docs, specs).

## Plugin

The installable plugin lives in `plugins/add/`. See `plugins/add/CLAUDE.md` for full plugin documentation (commands, skills, rules, templates).

## Project State

- `.add/` — ADD's own project config (dog-fooding itself)
- `docs/` — PRD, milestones, plans, infographic
- `specs/` — Feature specifications
- `reports/` — Dashboard prototypes and HTML reports

## Development Workflow

Test the plugin locally without installing:

```bash
claude --plugin-dir ./plugins/add
```

This loads commands, skills, rules, hooks, knowledge, and templates from the local checkout.

## Repository Structure

```
.claude-plugin/        # Marketplace manifest (marketplace.json)
plugins/add/           # The installable plugin
  .claude-plugin/      #   Plugin manifest (plugin.json)
  skills/              #   All slash commands and workflow skills
  rules/               #   Auto-loading behavioral rules
  hooks/               #   PostToolUse automation
  knowledge/           #   Tier 1 curated best practices
  templates/           #   Document scaffolding
docs/                  # Development documentation
specs/                 # Feature specifications
website/               # getadd.dev source
reports/               # Dashboard prototypes
```

## This Project Is ADD-Managed

ADD dog-foods its own methodology. Project state lives in `.add/`:
- `.add/config.json` — project configuration
- `.add/learnings.json` — structured learning entries
- `docs/prd.md` — the plugin's own PRD

Cross-project persistence at `~/.claude/add/`.

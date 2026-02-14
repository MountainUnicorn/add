# Contributing to ADD

ADD (Agent Driven Development) is a pure markdown/JSON Claude Code plugin with zero dependencies. Contributions are welcome — no CLA required.

## Local Development Setup

```bash
git clone https://github.com/MountainUnicorn/add.git
cd add
```

That's it. There's nothing to build or install. The plugin is entirely markdown and JSON files.

## Plugin Structure

```
add/
├── commands/      # Slash commands (/add:init, /add:spec, /add:away, etc.)
├── skills/        # Workflow skills (/add:tdd-cycle, /add:verify, /add:plan, etc.)
├── rules/         # Auto-loading behavioral rules
├── hooks/         # PostToolUse automation
├── knowledge/     # Plugin-global curated best practices
├── templates/     # Document scaffolding (PRD, spec, plan, config, etc.)
```

## Namespace Rule

**ALL command references in plugin files MUST use the namespaced form.** Write `/add:spec`, never `/spec`. Claude reproduces whatever naming pattern it sees — bare names cause Claude to suggest `/spec` instead of `/add:spec` in consumer projects.

## Testing Changes

Sync your working copy to the local marketplace cache, then restart any open Claude Code sessions:

```bash
rsync -av --delete \
  --exclude='.add/' --exclude='.git/' --exclude='.github/' \
  --exclude='.DS_Store' --exclude='reports/' --exclude='website/' \
  --exclude='docs/prd.md' --exclude='docs/distribution-plan.md' \
  --exclude='docs/milestones/' --exclude='docs/plans/' \
  --exclude='docs/infographic.svg' --exclude='specs/' --exclude='tests/' \
  /path/to/your/add/ \
  ~/.claude/plugins/cache/add-marketplace/add/0.1.0/
```

Open a new Claude Code session and exercise the command or skill you changed.

## Commit Convention

We use [conventional commits](https://www.conventionalcommits.org/):

- `feat:` — new feature or command
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — maintenance, refactoring, tooling

## Pull Requests

- One feature or fix per PR.
- Reference an issue if one exists (e.g., `Closes #12`).
- Make sure the namespace rule is followed in any new or modified files.
- Use a conventional commit message for the PR title.

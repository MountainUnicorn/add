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
core/                   # Source of truth (v0.7+ restructure)
├── skills/             # 26 skills — all slash commands (/add:init, /add:spec, /add:tdd-cycle, ...)
├── rules/              # 15 auto-loading behavioral rules
├── templates/          # 21 document templates (PRD, spec, plan, config, etc.)
├── knowledge/          # 2 Tier-1 knowledge files (global, image-gen-detection)
├── schemas/            # 2 JSON Schema validators (rule + skill frontmatter)
└── VERSION             # Canonical version string

runtimes/claude/        # Claude Code adapter (PostToolUse hooks, plugin manifest)
runtimes/codex/         # Codex CLI adapter (rules concatenated into AGENTS.md)

scripts/compile.py regenerates plugins/add/ (Claude) and dist/codex/
(Codex) from core/ on every release. Edit core/, never the generated
output — the compile-drift CI gate will reject PRs that disagree.
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

# Contributing to ADD

ADD (Agent Driven Development) is a pure markdown/JSON Claude Code plugin with no agent-side runtime dependencies. The hook scripts and the local fixture test suites under `tests/` shell out to `jq`, so a contributor will need `jq` on `PATH` to run the test suites locally — `brew install jq` on macOS, `apt install jq` on Debian/Ubuntu, or see [docs/runtime-dependencies.md](docs/runtime-dependencies.md) for the full per-OS install matrix. Contributions are welcome — no CLA required.

## Local Development Setup

```bash
git clone https://github.com/MountainUnicorn/add.git
cd add
```

That's it. There's nothing to build or install. The plugin is entirely markdown and JSON files.

## Plugin Structure

```
core/                   # Source of truth (v0.7+ restructure)
├── skills/             # 27 skills — all slash commands (/add:init, /add:spec, /add:tdd-cycle, ...)
├── rules/              # 19 auto-loading behavioral rules
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

After editing `core/`, regenerate the runtime adapters and sync the marketplace cache:

```bash
python3 scripts/compile.py            # regenerates plugins/add/ + dist/codex/
./scripts/sync-marketplace.sh         # rsync to ~/.claude/plugins/cache/...
```

Then open a new Claude Code session (or `/clear` an existing one) and exercise the skill you changed. Validation gates before opening a PR:

```bash
python3 scripts/validate-frontmatter.py
python3 scripts/compile.py --check
bash tests/hooks/test-filter-learnings.sh
```

All three CI checks (compile-drift, frontmatter-validate, rule-boundary) must pass before merge.

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

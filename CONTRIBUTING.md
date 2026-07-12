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
├── rules/              # 17 auto-loaded behavioral rules (+3 on-demand)
├── references/         # Non-autoloaded reference rules (loaded on-demand)
├── templates/          # 23 document templates (PRD, spec, plan, config, etc.)
├── knowledge/          # 4 Tier-1 knowledge files (global, image-gen-detection, secret-patterns, threat-model)
├── lib/                # Shared library functions used by hooks/skills
├── security/           # Security-related artifacts (threat model, redaction)
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

## Token Discipline

Everything that autoloads is paid for in every consumer session, so treat context like a budget:

- **Autoloaded rules must declare their gates.** A new rule in `core/rules/` needs explicit autoload and maturity frontmatter — the SessionStart loader only ships the rules a project's maturity level needs, and an ungated rule defeats that.
- **Illustrative content lives in `templates/` or `references/`,** not in `SKILL.md` bodies. Skills carry instructions; worked examples and long samples belong in files that load on demand.
- **State the context cost.** Any PR that adds or grows a rule or skill should note the approximate token cost (or delta) in its description so reviewers can weigh benefit against budget.

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

All four CI workflows must pass before merge: **compile-drift** (committed `plugins/add/` + `dist/codex/` match `compile.py`), **schema-check** (frontmatter validation), **rule-boundary-check** (no weakening of NEVER/MUST NOT markers), and the **guardrail suite** (every fixture-based test under `tests/`, plus the marketplace-manifest and secret-pattern validators).

## Pull Requests

We welcome community PRs. To keep momentum, maintainers may **merge a sound contribution as-is and refactor it in a follow-up commit**, crediting you as co-author (`Co-Authored-By:`) on that follow-up — so your change lands quickly without a long review back-and-forth. If you'd prefer to iterate the PR to completion yourself instead, just say so in the PR description. Either way, the four CI workflows above must be green before merge.

## Commit Convention

We use [conventional commits](https://www.conventionalcommits.org/):

- `feat:` — new feature or command
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — maintenance, refactoring, tooling

## Pull Request Guidelines

- One feature or fix per PR.
- Reference an issue if one exists (e.g., `Closes #12`).
- Make sure the namespace rule is followed in any new or modified files.
- Use a conventional commit message for the PR title.

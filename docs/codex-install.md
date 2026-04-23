# ADD on Codex CLI

ADD ships a Codex adapter alongside its Claude Code plugin. The adapter is generated from the same `core/` source of truth, translated via `runtimes/codex/adapter.yaml`.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/MountainUnicorn/add/main/scripts/install-codex.sh | bash
```

This script:

1. Clones the ADD repo to a temp directory
2. Copies 24 custom prompts to `~/.codex/prompts/add-*.md`
3. Installs shared content (AGENTS.md, templates) to `~/.codex/add/`
4. Prints instructions for wiring ADD into your project's `AGENTS.md`

### Manual install

If you'd rather clone and install yourself:

```bash
git clone https://github.com/MountainUnicorn/add
cd add
./scripts/install-codex.sh
```

## Wire Into Your Project

ADD's rules live in `~/.codex/add/AGENTS.md`. Codex reads the `AGENTS.md` at your project root on every session start.

**If your project has no AGENTS.md yet:**

```bash
cp ~/.codex/add/AGENTS.md /path/to/your/project/AGENTS.md
```

**If your project already has an AGENTS.md**, append the ADD reference at the top:

```markdown
@~/.codex/add/AGENTS.md

# My Project

...your existing content...
```

Codex resolves `@-references` at session start, merging ADD's rules into the loaded context.

## What You Get

| Category | Command |
|---|---|
| **Core workflow** | `/add-init`, `/add-spec`, `/add-plan`, `/add-tdd-cycle`, `/add-test-writer`, `/add-implementer`, `/add-reviewer`, `/add-verify`, `/add-optimize`, `/add-deploy` |
| **Planning** | `/add-cycle`, `/add-milestone`, `/add-roadmap`, `/add-promote` |
| **Design & docs** | `/add-ux`, `/add-docs`, `/add-infographic`, `/add-brand`, `/add-brand-update`, `/add-dashboard` |
| **Process** | `/add-away`, `/add-back`, `/add-retro`, `/add-changelog` |

Same methodology, same spec/plan/TDD/verify flow. The only differences from the Claude Code experience:

1. **No hooks.** Codex has no `PostToolUse` API. Lint/format must be invoked manually (`/add-verify` runs them).
2. **Free-text confirmations.** Codex has no structured `AskUserQuestion` equivalent, so the Confusion Protocol and Confirmation Gate use plain prompts instead of clickable popups. Read the rule in `~/.codex/add/AGENTS.md` > "Confirmation Gate" if you want the same discipline.
3. **Un-namespaced prompts.** Claude Code uses `/add:spec`; Codex uses `/add-spec`. The prompts are invoked via Codex's custom-prompt mechanism.
4. **Flat autoload.** Claude Code selectively loads rules by maturity. Codex concatenates all rules into one `AGENTS.md`. The `maturity-loader.md` rule is preserved so the agent still filters behaviorally — it just loads the full text.
5. **On-demand references** (v0.9.0+). Both runtimes ship `references/*.md` files — full learning-system reference, swarm protocol, design system, quality-checks matrix, image-gen detection — that are *not* autoloaded. Skills that need them read the file at runtime. On Codex, `AGENTS.md` omits any rule marked `autoload: false`, and prompts invoke e.g. `cat ~/.codex/add/references/learning-reference.md` when they need the full template set. Token savings from on-demand loading are preserved symmetrically across both runtimes.

## Staying In Sync

ADD's Codex adapter ships with each release. To upgrade:

```bash
./scripts/install-codex.sh
```

The installer is idempotent. It backs up any existing prompt with `.pre-add.bak` if you had a file of the same name.

## Uninstall

```bash
rm -rf ~/.codex/add ~/.codex/prompts/add-*.md
```

If you merged ADD's AGENTS.md content into a project's AGENTS.md, edit that file manually to remove the ADD sections.

## Limitations Relative to Claude Code

Known gaps:

- **`/add:deploy` production gate** — the Claude version (v0.7.1+) will ask for a confirm-phrase. The Codex version currently relies on the rule text alone. Be explicit about approval in away mode.
- **Hooks-driven lint** — the Claude adapter runs lint after every Write/Edit. Run `/add-verify` manually on Codex, or wire your own pre-commit hook.
- **Sub-agent dispatch** — the Claude adapter uses `Task` tool for parallel sub-agents. Codex's equivalent depends on the version you're running; check `AGENTS.md > Rule: agent-coordination` for the serial-fallback behavior.

## Reporting Issues

- Codex-specific: tag your issue `[codex]` — https://github.com/MountainUnicorn/add/issues
- Runtime bugs: issues in Codex itself should go to https://github.com/openai/codex

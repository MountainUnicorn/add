## What

<!-- One-sentence summary of the change. -->

## Why

<!-- What problem does this solve or what feature does it add? Reference an issue if one exists: Closes #N -->

## How to Test

<!-- Steps to verify the change works. -->

1. `./scripts/sync-marketplace.sh`
2. Restart (or `/clear`) a Claude Code session
3. Run `/add:...`

## Checklist

- [ ] Edited `core/` only — no manual edits to generated `plugins/add/` or `dist/codex/`
- [ ] Ran `python3 scripts/compile.py` and committed the regenerated output
- [ ] `python3 scripts/validate-frontmatter.py` and `python3 scripts/compile.py --check` pass
- [ ] Tests pass (`bash tests/hooks/test-filter-learnings.sh` plus any suites you touched)
- [ ] `CHANGELOG.md` updated under the correct version heading (usually `[Unreleased]`)
- [ ] Conventional commit message used in PR title
- [ ] All command references use namespaced form (`/add:spec` not `/spec`)
- [ ] If this changes an autoloaded surface (rules, hooks, knowledge): token cost noted in the description

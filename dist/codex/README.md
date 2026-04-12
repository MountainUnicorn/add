# ADD for Codex CLI — v0.7.3

This directory is the Codex adapter for ADD. Install with:

```bash
./scripts/install-codex.sh
```

That script copies `prompts/add-*.md` into `~/.codex/prompts/` and places
`AGENTS.md` at the root of your project (or merges if one exists).

**Differences from the Claude adapter:**
- No `PostToolUse` hooks (Codex has no hooks API — lint must be run manually).
- `AskUserQuestion` tool calls are rendered as plain-text prompts; answers are
  free-form rather than structured.
- Autoload rules are concatenated into a single `AGENTS.md` rather than loaded
  individually — the whole file is read on session start.
- Slash command namespacing (`/add:spec`) is approximated by prompt filename
  (`add-spec.md`); invoke with Codex's custom-prompt mechanism.

See [Codex install docs](../../docs/codex-install.md) for details.

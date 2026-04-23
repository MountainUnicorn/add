#!/usr/bin/env bash
# ADD Codex CLI installer (v0.9+ native Skills layout)
#
# Installs ADD's Codex adapter in the native format:
#   - .agents/skills/add-*/    → ~/.codex/skills/add-*/   (native Codex Skills)
#   - .codex/agents/*.toml     → ~/.codex/agents/         (sub-agent definitions)
#   - .codex/hooks/            → ~/.codex/hooks/          (shell hook scripts, mode 0755)
#   - .codex/hooks.json        → ~/.codex/hooks.json      (hook registration — merged if present)
#   - .codex/config.toml       → staged at ~/.codex/add/config.toml (merge guidance printed)
#   - AGENTS.md                → ~/.codex/add/AGENTS.md   (referenced from project AGENTS.md)
#   - templates/               → ~/.codex/add/templates/  (referenced by skills)
#   - plugin.toml              → ~/.codex/add/plugin.toml (plugin manifest)
#
# Required Codex CLI: see min_codex_version in dist/codex/plugin.toml.
#
# Usage:
#   # From a clone of the repo:
#   ./scripts/install-codex.sh
#
#   # Or remote install (copy into ~/.codex/):
#   curl -fsSL https://raw.githubusercontent.com/MountainUnicorn/add/main/scripts/install-codex.sh | bash

set -euo pipefail

# Resolve script location; works whether run locally or via curl|bash
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(dirname "$SCRIPT_DIR")"
  DIST_DIR="$REPO_ROOT/dist/codex"
else
  # Remote install path: clone the repo to a temp dir
  echo "==> Remote install detected; cloning repo..."
  TMP=$(mktemp -d)
  git clone --depth 1 https://github.com/MountainUnicorn/add "$TMP/add" >/dev/null 2>&1
  DIST_DIR="$TMP/add/dist/codex"
fi

if [ ! -d "$DIST_DIR" ]; then
  echo "ERROR: Codex dist not found at $DIST_DIR" >&2
  echo "       If you're in the repo, run: python3 scripts/compile.py" >&2
  exit 1
fi

if [ ! -d "$DIST_DIR/.agents/skills" ]; then
  echo "ERROR: Codex dist at $DIST_DIR uses the legacy prompts/ layout." >&2
  echo "       This installer requires the native Skills layout (v0.9+)." >&2
  echo "       Run: python3 scripts/compile.py" >&2
  exit 1
fi

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
ADD_HOME="$CODEX_HOME/add"
SKILLS_DIR="$CODEX_HOME/skills"
AGENTS_DIR="$CODEX_HOME/agents"
HOOKS_DIR="$CODEX_HOME/hooks"

VERSION=$(cat "$DIST_DIR/VERSION" 2>/dev/null || echo "unknown")

echo "==> Installing ADD v$VERSION for Codex CLI (native Skills layout)"
echo "    Skills    → $SKILLS_DIR/"
echo "    Agents    → $AGENTS_DIR/"
echo "    Hooks     → $HOOKS_DIR/"
echo "    Shared    → $ADD_HOME/"
echo ""

mkdir -p "$SKILLS_DIR" "$AGENTS_DIR" "$HOOKS_DIR" "$ADD_HOME"

# --- Skills: one directory per skill -------------------------------------
skill_count=0
for src in "$DIST_DIR"/.agents/skills/add-*; do
  [ -d "$src" ] || continue
  name=$(basename "$src")
  dst="$SKILLS_DIR/$name"
  rm -rf "$dst"
  cp -r "$src" "$dst"
  skill_count=$((skill_count + 1))
done
echo "    ✓ $skill_count native skills installed"

# --- Sub-agent TOMLs ------------------------------------------------------
agent_count=0
for src in "$DIST_DIR"/.codex/agents/*.toml; do
  [ -f "$src" ] || continue
  cp "$src" "$AGENTS_DIR/$(basename "$src")"
  agent_count=$((agent_count + 1))
done
echo "    ✓ $agent_count sub-agent TOMLs installed"

# --- Hook scripts + manifest ---------------------------------------------
hook_count=0
for src in "$DIST_DIR"/.codex/hooks/*.sh; do
  [ -f "$src" ] || continue
  cp "$src" "$HOOKS_DIR/$(basename "$src")"
  chmod 0755 "$HOOKS_DIR/$(basename "$src")"
  hook_count=$((hook_count + 1))
done
cp "$DIST_DIR/.codex/hooks/README.md" "$HOOKS_DIR/README.md"
# hooks.json is merged by hand if one already exists — warn the user.
if [ -f "$CODEX_HOME/hooks.json" ]; then
  cp "$DIST_DIR/.codex/hooks.json" "$ADD_HOME/hooks.json"
  HOOKS_MERGE_NOTE="A prior ~/.codex/hooks.json exists; ADD's manifest staged at $ADD_HOME/hooks.json — merge manually."
else
  cp "$DIST_DIR/.codex/hooks.json" "$CODEX_HOME/hooks.json"
  HOOKS_MERGE_NOTE="~/.codex/hooks.json installed fresh."
fi
echo "    ✓ $hook_count hook scripts installed"

# --- Global config.toml (staged for manual merge) ------------------------
cp "$DIST_DIR/.codex/config.toml" "$ADD_HOME/config.toml"

# --- Shared content: AGENTS.md, templates, plugin.toml, VERSION ---------
cp "$DIST_DIR/AGENTS.md" "$ADD_HOME/AGENTS.md"
cp "$DIST_DIR/plugin.toml" "$ADD_HOME/plugin.toml"
cp "$DIST_DIR/VERSION" "$ADD_HOME/VERSION"
if [ -d "$DIST_DIR/templates" ]; then
  rm -rf "$ADD_HOME/templates"
  cp -r "$DIST_DIR/templates" "$ADD_HOME/templates"
fi
echo "    ✓ AGENTS.md, templates, and plugin.toml staged at $ADD_HOME/"

# Guide the user on wiring AGENTS.md into their project
cat <<EOF

Install complete.

Next steps:

1. Wire ADD into your project's AGENTS.md:
     Fresh project (no AGENTS.md yet):
       cp $ADD_HOME/AGENTS.md /path/to/your/project/AGENTS.md

     Existing AGENTS.md — add this line near the top to include ADD's manifest:
       @${ADD_HOME/$HOME/~}/AGENTS.md

2. Enable Codex runtime features (required for sub-agents and hooks):
     In your ~/.codex/config.toml ensure:

       [features]
       collab = true
       codex_hooks = true

       [agents]
       max_threads = 6
       max_depth = 1

     A reference block is at: $ADD_HOME/config.toml

3. Hooks:
     $HOOKS_MERGE_NOTE

Skills dispatch by description match (e.g., "run quality gates" → add-verify)
or explicitly (e.g., /add-verify). High-leak interview skills (/add-spec,
/add-brand-update, /add-away, /add-tdd-cycle, /add-implementer, /add-deploy)
require explicit invocation.

Uninstall:
  rm -rf $ADD_HOME $SKILLS_DIR/add-* $AGENTS_DIR/{test-writer,implementer,reviewer,explorer}.toml
  # Restore your own ~/.codex/hooks.json if you backed it up.

Troubleshooting: https://github.com/MountainUnicorn/add/blob/main/TROUBLESHOOTING.md
EOF

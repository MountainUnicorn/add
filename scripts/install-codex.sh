#!/usr/bin/env bash
# ADD Codex CLI installer
#
# Installs ADD's Codex adapter:
#   - Copies prompts/*.md into ~/.codex/prompts/ (preserves existing files)
#   - Places AGENTS.md at ~/.codex/add/AGENTS.md (referenced from project AGENTS.md)
#   - Templates to ~/.codex/add/templates/ for prompts to reference
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

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
ADD_HOME="$CODEX_HOME/add"
PROMPTS_DIR="$CODEX_HOME/prompts"

VERSION=$(cat "$DIST_DIR/VERSION" 2>/dev/null || echo "unknown")

echo "==> Installing ADD v$VERSION for Codex CLI"
echo "    Prompts → $PROMPTS_DIR/"
echo "    Shared  → $ADD_HOME/"
echo ""

# Ensure Codex home exists
mkdir -p "$PROMPTS_DIR" "$ADD_HOME"

# Copy prompts — each is a custom-prompt file invoked as /add-spec, /add-tdd-cycle, etc.
# We prefix all ADD prompts with 'add-' to avoid colliding with user prompts.
count=0
conflicts=0
for src in "$DIST_DIR"/prompts/add-*.md; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  dst="$PROMPTS_DIR/$name"
  if [ -f "$dst" ]; then
    # If existing file differs, back it up
    if ! cmp -s "$src" "$dst"; then
      mv "$dst" "$dst.pre-add.bak"
      cp "$src" "$dst"
      conflicts=$((conflicts + 1))
    fi
  else
    cp "$src" "$dst"
  fi
  count=$((count + 1))
done
echo "    ✓ $count prompts installed (${conflicts} backups created at *.pre-add.bak)"

# Copy shared AGENTS.md source + templates
cp "$DIST_DIR/AGENTS.md" "$ADD_HOME/AGENTS.md"
if [ -d "$DIST_DIR/templates" ]; then
  rm -rf "$ADD_HOME/templates"
  cp -r "$DIST_DIR/templates" "$ADD_HOME/templates"
fi
cp "$DIST_DIR/VERSION" "$ADD_HOME/VERSION"
echo "    ✓ AGENTS.md and templates installed"

# Guide the user on wiring AGENTS.md into their project
cat <<EOF

Install complete.

Next step — wire ADD into your project's AGENTS.md:

  Option A (fresh project, no existing AGENTS.md):
    cp $ADD_HOME/AGENTS.md /path/to/your/project/AGENTS.md

  Option B (existing AGENTS.md — merge):
    Add this line to the top of your project's AGENTS.md:

      @${ADD_HOME/$HOME/~}/AGENTS.md

    Codex resolves @-references at session start, pulling ADD's rules in.

Prompts are now available in any Codex session. Try:
  /add-init        — Bootstrap ADD in your project
  /add-spec        — Create a feature specification
  /add-tdd-cycle   — Run the full TDD loop

Uninstall:
  rm -rf $ADD_HOME $PROMPTS_DIR/add-*.md

Troubleshooting: https://github.com/MountainUnicorn/add/blob/main/TROUBLESHOOTING.md
EOF

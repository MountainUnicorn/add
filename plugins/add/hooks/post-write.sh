#!/usr/bin/env bash
# post-write.sh — PostToolUse dispatcher for Write/Edit events
#
# Called by hooks.json after every Write or Edit tool use.
# Reads the tool_input JSON from stdin-style jq and dispatches
# to the appropriate handler based on the file path.
#
# Usage (from hooks.json): post-write.sh
# Expects $CLAUDE_TOOL_INPUT to be available, or reads from the
# hook environment where jq can parse the tool input.

set -euo pipefail

FILE=$(jq -r '.tool_input.file_path // empty')
[ -n "$FILE" ] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$FILE" in
  *.py)
    ruff check --fix "$FILE" 2>/dev/null || true
    ;;
  *.ts|*.tsx)
    npx --no-install eslint --fix "$FILE" 2>/dev/null || true
    ;;
  *learnings.json|*library.json)
    # Read active_cap from project config; fall back to 15
    MAX=15
    if [ -f .add/config.json ]; then
      CFG_MAX=$(jq -r '.learnings.active_cap // empty' .add/config.json 2>/dev/null) || true
      [ -n "$CFG_MAX" ] && MAX="$CFG_MAX"
    fi
    "$SCRIPT_DIR/filter-learnings.sh" "$FILE" "$MAX" 2>/dev/null || true
    ;;
esac

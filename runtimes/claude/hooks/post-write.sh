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

FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[ -n "$FILE" ] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-fix is OPT-IN: .add/config.json → hooks.autofix (boolean, default false).
# When false, linters run in check-only mode and print a one-line advisory —
# they never rewrite files under the agent silently.
AUTOFIX=false
if [ -f .add/config.json ]; then
  CFG_AUTOFIX=$(jq -r '.hooks.autofix // false' .add/config.json 2>/dev/null || true)
  if [ "$CFG_AUTOFIX" = "true" ]; then AUTOFIX=true; fi
fi

# run_linter <check-cmd...> — helper shared by the language cases below.
# In autofix mode the caller runs the fix variant and reports mutations.
lint_check_or_fix() { # $1 = label, $2 = check cmd, $3 = fix cmd (both take $FILE appended)
  local label="$1" check_cmd="$2" fix_cmd="$3"
  if [ "$AUTOFIX" = "true" ]; then
    local before after
    before=$(cksum "$FILE" 2>/dev/null || true)
    eval "$fix_cmd \"\$FILE\"" >/dev/null 2>&1 || true
    after=$(cksum "$FILE" 2>/dev/null || true)
    if [ "$before" != "$after" ]; then
      echo "[ADD] $label auto-fix modified $FILE (hooks.autofix=true in .add/config.json)" >&2
    fi
  else
    if ! eval "$check_cmd \"\$FILE\"" >/dev/null 2>&1; then
      echo "[ADD] $label found issues in $FILE — file left untouched (enable hooks.autofix in .add/config.json to auto-fix)" >&2
    fi
  fi
}

case "$FILE" in
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      lint_check_or_fix "ruff" "ruff check" "ruff check --fix"
    fi
    ;;
  *.ts|*.tsx)
    if npx --no-install eslint --version >/dev/null 2>&1; then
      lint_check_or_fix "eslint" "npx --no-install eslint" "npx --no-install eslint --fix"
    fi
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

# agents-md-sync: mark AGENTS.md stale when source inputs change.
# Silent no-op when the project has no AGENTS.md (not every consumer opts in).
case "$FILE" in
  *.add/config.json|*core/rules/*.md|*core/skills/*/SKILL.md)
    if [ -f AGENTS.md ] && [ -d .add ]; then
      REL="${FILE#"$PWD/"}"
      TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      # Atomic write — touch is idempotent; concurrent fires are safe.
      printf '{"timestamp":"%s","changed":["%s"]}\n' "$TS" "$REL" \
        > .add/agents-md.stale 2>/dev/null || true
    fi
    ;;
esac

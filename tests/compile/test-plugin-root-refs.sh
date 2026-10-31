#!/usr/bin/env bash
# test-plugin-root-refs.sh — Every helper a shipped skill tells the agent to run
# must actually ship in the plugin.
#
# Regression guard for the v0.11.0 bug where /add:agents-md invoked
# `scripts/generate-agents-md.py`: that path only existed in the ADD source repo
# (repo-level maintainer tooling that compile.py never copies), so it worked when
# dog-fooding ADD on itself and failed in every consumer project.
#
# Checks against the compiled Claude plugin (plugins/add/):
#   1. Every concrete `${CLAUDE_PLUGIN_ROOT}/<path>` reference resolves to a file.
#   2. No ref escapes the plugin root via `..` (resolves in the repo, not the install).
#   3. No skill/rule/reference invokes a repo-relative `scripts/*.py|*.sh` helper,
#      unless the line explicitly scopes it to the ADD source repo (maintainer tooling).
#
# Usage: bash tests/compile/test-plugin-root-refs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGIN="$REPO_ROOT/plugins/add"

python3 "$REPO_ROOT/scripts/compile.py" --runtime claude >/dev/null

FAIL=0

# 1. ${CLAUDE_PLUGIN_ROOT}/... references resolve (skip templated paths like {name} or globs).
while IFS= read -r ref; do
  case "$ref" in
    *..*) echo "FAIL: \${CLAUDE_PLUGIN_ROOT}/$ref escapes the plugin root (only resolves inside the ADD source repo)"; FAIL=$((FAIL + 1)); continue ;;
    *'{'*|*'*'*|*'<'*) continue ;;
  esac
  if [ ! -e "$PLUGIN/$ref" ]; then
    echo "FAIL: \${CLAUDE_PLUGIN_ROOT}/$ref is referenced but not shipped in plugins/add/"
    FAIL=$((FAIL + 1))
  fi
done < <(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./{}<>*-]+' "$PLUGIN" --include='*.md' \
          | sed -E 's|^\$\{CLAUDE_PLUGIN_ROOT\}/||; s|[.,;:)`]+$||' | sort -u)

# 3. No repo-relative maintainer scripts invoked from shipped content.
if hits=$(grep -rnE '(python3|bash|sh) +scripts/[A-Za-z0-9_-]+\.(py|sh)' "$PLUGIN" --include='*.md' \
          | grep -v 'ADD source repo' | grep -vE '^[^:]+:[0-9]+:python3 scripts/validate-cache-discipline'); then
  echo "FAIL: shipped content invokes repo-relative scripts/ (not present in consumer projects):"
  echo "$hits"
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "test-plugin-root-refs: $FAIL failure(s)"
  exit 1
fi
echo "test-plugin-root-refs: all \${CLAUDE_PLUGIN_ROOT} references resolve; no repo-relative scripts/ invocations"

#!/usr/bin/env bash
# impact-hint.sh — Files-likely-affected hint for the /add:implementer skill.
#
# Implements section D of specs/test-deletion-guardrail.md (AC-018..AC-024).
#
# Pure shell + jq + grep. No graph libraries, no AST parsers. The hint is
# intentionally lightweight and lossy — false positives are preferred over
# false negatives; the implementer uses this as a starting point, not a
# ground truth.
#
# Usage:
#   core/lib/impact-hint.sh <base-sha> <spec-path> [project-root]
#
# Emits to stdout a structured prompt block:
#
#   Files likely to need changes:
#     - path/a.py
#     - path/b.ts
#   Files to be careful around (recent anti-pattern learnings exist):
#     - path/c.py  [L-042]
#
# Exit codes:
#   0 — hint produced (even if lists are empty)
#   1 — invocation error

set -euo pipefail

BASE_SHA="${1:-}"
SPEC_PATH="${2:-}"
PROJECT_ROOT="${3:-$(pwd)}"

if [ -z "$BASE_SHA" ] || [ -z "$SPEC_PATH" ]; then
  echo "Usage: impact-hint.sh <base-sha> <spec-path> [project-root]" >&2
  exit 1
fi

cd "$PROJECT_ROOT"

# -- AC-018: diff between base and HEAD to find test files changed --
CHANGED_FILES=$(git diff --name-only "$BASE_SHA"..HEAD 2>/dev/null || true)

# -- Filter to test files (heuristic: path includes "test" or "spec", or suffix matches) --
TEST_FILES=$(printf '%s\n' "$CHANGED_FILES" | grep -E \
  '(^test_|_test\.|\.test\.|\.spec\.|/tests?/|/__tests__/|/spec/)' || true)

# -- AC-019: regex-extract imports and resolve to local paths --
IMPORT_PATHS=$(mktemp)
trap 'rm -f "$IMPORT_PATHS" "$SPEC_PATHS" "$LEARNING_PATHS" "$CANDIDATES"' EXIT
: > "$IMPORT_PATHS"

if [ -n "$TEST_FILES" ]; then
  while IFS= read -r tf; do
    [ -z "$tf" ] && continue
    [ ! -f "$tf" ] && continue
    ext="${tf##*.}"
    case "$ext" in
      py)
        # from X.Y import Z  -->  X/Y.py
        grep -E "^\s*from\s+[\w\.]+\s+import\s+" "$tf" 2>/dev/null | \
          sed -E 's/^\s*from\s+([\w\.]+)\s+import\s+.*/\1/' | \
          tr '.' '/' | sed 's/$/.py/' >> "$IMPORT_PATHS" || true
        # import X.Y  -->  X/Y.py
        grep -E "^\s*import\s+[\w\.]+" "$tf" 2>/dev/null | \
          sed -E 's/^\s*import\s+([\w\.]+).*/\1/' | \
          tr '.' '/' | sed 's/$/.py/' >> "$IMPORT_PATHS" || true
        ;;
      ts|tsx|js|jsx|mjs|cjs)
        # from './x/y' or require('./x/y') — capture the relative path
        grep -E "from\s+['\"][\./][^'\"]+['\"]" "$tf" 2>/dev/null | \
          sed -E "s/.*from\s+['\"]([\./][^'\"]+)['\"].*/\1/" >> "$IMPORT_PATHS" || true
        grep -E "require\s*\(\s*['\"][\./][^'\"]+['\"]\s*\)" "$tf" 2>/dev/null | \
          sed -E "s/.*require\s*\(\s*['\"]([\./][^'\"]+)['\"]\s*\).*/\1/" >> "$IMPORT_PATHS" || true
        ;;
      go)
        grep -E "^\s*import\s+\"[^\"]+\"" "$tf" 2>/dev/null | \
          sed -E 's/^\s*import\s+"([^"]+)".*/\1/' >> "$IMPORT_PATHS" || true
        ;;
      rb)
        grep -E "^\s*require(_relative)?\s+['\"][^'\"]+['\"]" "$tf" 2>/dev/null | \
          sed -E "s/.*require(_relative)?\s+['\"]([^'\"]+)['\"].*/\2/" >> "$IMPORT_PATHS" || true
        ;;
      rs)
        grep -E "^\s*use\s+crate::" "$tf" 2>/dev/null | \
          sed -E 's|^\s*use\s+crate::([a-zA-Z_0-9:]+).*|\1|' | \
          sed 's|::|/|g' | sed 's/$/.rs/' >> "$IMPORT_PATHS" || true
        ;;
    esac
  done <<< "$TEST_FILES"
fi

# Normalize: strip leading ./, drop duplicates, keep only paths that exist in repo
RESOLVED_IMPORTS=$(sort -u "$IMPORT_PATHS" | while IFS= read -r p; do
  [ -z "$p" ] && continue
  p="${p#./}"
  # Try the path as-is, plus common extension variants
  for candidate in "$p" "${p%.py}.py" "${p%.ts}.ts" "${p%.js}.js" "$p/index.ts" "$p/index.js" "$p/__init__.py"; do
    if [ -f "$candidate" ]; then
      echo "$candidate"
      break
    fi
  done
done | sort -u)

# -- AC-020: cross-reference literal path mentions in the spec --
SPEC_PATHS=$(mktemp)
: > "$SPEC_PATHS"
if [ -f "$SPEC_PATH" ]; then
  # Extract any token matching filename.ext where ext is a known source extension
  grep -oE '[A-Za-z0-9_./-]+\.(py|ts|tsx|js|jsx|go|rs|rb|mjs|cjs)' "$SPEC_PATH" 2>/dev/null | \
    sort -u > "$SPEC_PATHS" || true
fi

SPEC_PATHS_EXISTING=$(while IFS= read -r p; do
  [ -z "$p" ] && continue
  # Only surface paths that exist AND are not themselves test files
  if [ -f "$p" ]; then
    echo "$p" | grep -vE '(^test_|_test\.|\.test\.|\.spec\.|/tests?/|/__tests__/|/spec/)' || true
  fi
done < "$SPEC_PATHS" | sort -u)

# -- Union: candidate source files --
CANDIDATES=$(mktemp)
{
  echo "$RESOLVED_IMPORTS"
  echo "$SPEC_PATHS_EXISTING"
} | sort -u | grep -v '^$' > "$CANDIDATES" || true

# -- AC-021: anti-pattern learnings lookup --
LEARNINGS_FILE="$PROJECT_ROOT/.add/learnings.json"
LEARNING_PATHS=$(mktemp)
: > "$LEARNING_PATHS"

if [ -f "$LEARNINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
  # Build a { "path": "L-###" } list by scanning anti-pattern bodies
  while IFS= read -r candidate; do
    [ -z "$candidate" ] && continue
    # Find anti-pattern entries whose body mentions this path
    match=$(jq -r --arg p "$candidate" '
      .entries[]? // empty |
      select(.category == "anti-pattern") |
      select(.body | test($p; "i")) |
      .id
    ' "$LEARNINGS_FILE" 2>/dev/null | head -1 || true)
    if [ -n "$match" ]; then
      echo "$candidate|$match" >> "$LEARNING_PATHS"
    fi
  done < "$CANDIDATES"
fi

# -- Emit the hint --
echo "## Files likely to need changes"
if [ ! -s "$CANDIDATES" ]; then
  # AC-024: explicit no-source-files message
  echo "  (No source files implied by RED diff. Check spec acceptance criteria"
  echo "   for implementation targets.)"
else
  # Exclude anti-pattern paths from this list (they get their own section)
  FLAGGED_PATHS=$(cut -d'|' -f1 < "$LEARNING_PATHS" 2>/dev/null | sort -u)
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if ! printf '%s\n' "$FLAGGED_PATHS" | grep -qxF "$p" 2>/dev/null; then
      echo "  - $p"
    fi
  done < "$CANDIDATES"
fi

if [ -s "$LEARNING_PATHS" ]; then
  echo ""
  echo "## Files to be careful around (recent anti-pattern learnings exist)"
  while IFS='|' read -r path lid; do
    echo "  - $path  [$lid]"
  done < "$LEARNING_PATHS"
fi

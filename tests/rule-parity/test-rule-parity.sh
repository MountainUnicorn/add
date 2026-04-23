#!/usr/bin/env bash
# test-rule-parity.sh — Regression test for F-011: Claude rule distribution drift.
#
# Asserts that every file in core/rules/*.md has a corresponding @rules/ import
# line in runtimes/claude/CLAUDE.md, and that the rule count claimed in the
# Plugin Structure tree diagram matches reality.
#
# Usage: bash tests/rule-parity/test-rule-parity.sh

set -u  # do not set -e; we report findings structurally

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_MD="$REPO_ROOT/runtimes/claude/CLAUDE.md"
RULES_DIR="$REPO_ROOT/core/rules"

PASS=0
FAIL=0

pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "=== Claude rule parity check (F-011 regression) ==="
echo ""

# ---- 1. every core/rules/*.md is referenced by @rules/ import in CLAUDE.md ----

missing=()
for f in "$RULES_DIR"/*.md; do
  name=$(basename "$f")
  if ! grep -q "^@rules/$name\$" "$CLAUDE_MD"; then
    missing+=("$name")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  pass "every core/rules/*.md has an @rules/ import in runtimes/claude/CLAUDE.md"
else
  fail "${#missing[@]} rule(s) missing @rules/ import in CLAUDE.md:"
  for m in "${missing[@]}"; do
    echo "  missing: @rules/$m"
  done
fi

# ---- 2. no @rules/ import points at a nonexistent file -----------------------

orphan=()
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  path=${ref#@rules/}
  if [ ! -f "$RULES_DIR/$path" ]; then
    orphan+=("$ref")
  fi
done < <(grep -oE '^@rules/[^ ]+' "$CLAUDE_MD")

if [ ${#orphan[@]} -eq 0 ]; then
  pass "no @rules/ imports point at nonexistent files"
else
  fail "${#orphan[@]} orphan @rules/ import(s) — file(s) not in core/rules/:"
  for o in "${orphan[@]}"; do
    echo "  orphan: $o"
  done
fi

# ---- 3. the tree-diagram count matches the actual file count ------------------

actual=$(find "$RULES_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
declared=$(grep -oE 'Auto-loading behavioral rules \([0-9]+ files\)' "$CLAUDE_MD" | grep -oE '[0-9]+')

if [ -z "$declared" ]; then
  fail "could not find 'Auto-loading behavioral rules (N files)' count in CLAUDE.md"
elif [ "$declared" = "$actual" ]; then
  pass "tree-diagram rule count matches reality ($declared files)"
else
  fail "tree-diagram claims $declared rule files; actual count is $actual"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

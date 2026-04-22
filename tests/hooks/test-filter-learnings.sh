#!/usr/bin/env bash
# test-filter-learnings.sh — Fixture-based tests for filter-learnings.sh
#
# Runs the filter script against fixture JSON inputs and compares
# the output against expected markdown files. Exits non-zero on failure.
#
# Usage: bash tests/hooks/test-filter-learnings.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FILTER="$REPO_ROOT/runtimes/claude/hooks/filter-learnings.sh"
FIXTURES="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0

run_test() {
  local name="$1"
  local input="$2"
  local expected="$3"
  local max_entries="${4:-15}"

  # Work in a temp dir to avoid polluting fixtures
  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" RETURN

  cp "$input" "$tmpdir/learnings.json"

  "$FILTER" "$tmpdir/learnings.json" "$max_entries"

  local actual="$tmpdir/learnings-active.md"

  if [ ! -f "$actual" ]; then
    echo "FAIL: $name — no output file generated"
    FAIL=$((FAIL + 1))
    return
  fi

  if diff -u "$expected" "$actual" > "$tmpdir/diff.txt" 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    cat "$tmpdir/diff.txt"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== filter-learnings.sh fixture tests ==="
echo ""

# Test 1: Basic — severity sort, archived exclusion, category grouping
run_test "basic (sort, archive, group)" \
  "$FIXTURES/learnings-basic.json" \
  "$FIXTURES/learnings-basic-expected.md"

# Test 2: Overflow — max_entries=2 forces index section
run_test "overflow (index section)" \
  "$FIXTURES/learnings-overflow.json" \
  "$FIXTURES/learnings-overflow-expected.md" \
  2

# Test 3: Large set — 30 entries, default max=15, 2 archived
run_test "large (15 top + 13 index, 2 archived)" \
  "$FIXTURES/learnings-large.json" \
  "$FIXTURES/learnings-large-expected.md"

# Test 4: Empty entries array
run_test "empty entries" \
  "$FIXTURES/learnings-empty.json" \
  "$FIXTURES/learnings-empty-expected.md"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

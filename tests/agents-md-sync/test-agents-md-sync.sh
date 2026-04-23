#!/usr/bin/env bash
# test-agents-md-sync.sh — Fixture-based tests for scripts/generate-agents-md.py
#
# Copies each fixture to a temp dir, runs the generator with deterministic
# --generated and --skill-version flags, and diffs against expected output.
# Exits non-zero on any mismatch.
#
# Usage: bash tests/agents-md-sync/test-agents-md-sync.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GEN="$REPO_ROOT/scripts/generate-agents-md.py"
FIXTURES="$SCRIPT_DIR/fixtures"

FIXED_TIMESTAMP="2026-04-22T12:00:00Z"
FIXED_VERSION="0.9.0"

PASS=0
FAIL=0

copy_fixture() {
  local src="$1"
  local dst="$2"
  # Copy only ADD state files, not the pre-seeded AGENTS.md files
  mkdir -p "$dst"
  if [ -d "$src/.add" ]; then
    cp -r "$src/.add" "$dst/"
  fi
  if [ -d "$src/docs" ]; then
    cp -r "$src/docs" "$dst/"
  fi
  if [ -d "$src/specs" ]; then
    cp -r "$src/specs" "$dst/"
  fi
}

run_render_test() {
  local name="$1"
  local fixture="$2"
  local expected="$fixture/expected-AGENTS.md"

  local tmpdir
  tmpdir=$(mktemp -d)

  copy_fixture "$fixture" "$tmpdir"

  python3 "$GEN" \
    --project-root "$tmpdir" \
    --generated "$FIXED_TIMESTAMP" \
    --skill-version "$FIXED_VERSION" \
    >/dev/null

  if diff -u "$expected" "$tmpdir/AGENTS.md" > "$tmpdir/diff.txt" 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    cat "$tmpdir/diff.txt"
    FAIL=$((FAIL + 1))
  fi

  rm -rf "$tmpdir"
}

run_check_drift_test() {
  local name="$1"
  local fixture="$2"

  local tmpdir
  tmpdir=$(mktemp -d)

  copy_fixture "$fixture" "$tmpdir"
  cp "$fixture/existing-AGENTS.md" "$tmpdir/AGENTS.md"

  set +e
  python3 "$GEN" \
    --project-root "$tmpdir" \
    --generated "$FIXED_TIMESTAMP" \
    --skill-version "$FIXED_VERSION" \
    --check >/dev/null 2>&1
  local rc=$?
  set -e

  if [ "$rc" -eq 1 ]; then
    echo "PASS: $name (drift detected, exit=1)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — expected exit 1, got $rc"
    FAIL=$((FAIL + 1))
  fi

  rm -rf "$tmpdir"
}

run_merge_test() {
  local name="$1"
  local fixture="$2"
  local expected="$fixture/expected-AGENTS.md"

  local tmpdir
  tmpdir=$(mktemp -d)

  copy_fixture "$fixture" "$tmpdir"
  cp "$fixture/existing-AGENTS.md" "$tmpdir/AGENTS.md"

  python3 "$GEN" \
    --project-root "$tmpdir" \
    --generated "$FIXED_TIMESTAMP" \
    --skill-version "$FIXED_VERSION" \
    --merge >/dev/null

  if diff -u "$expected" "$tmpdir/AGENTS.md" > "$tmpdir/diff.txt" 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    cat "$tmpdir/diff.txt"
    FAIL=$((FAIL + 1))
  fi

  rm -rf "$tmpdir"
}

run_missing_marker_abort_test() {
  local name="$1"
  local fixture="$2"

  local tmpdir
  tmpdir=$(mktemp -d)

  copy_fixture "$fixture" "$tmpdir"
  cp "$fixture/existing-AGENTS.md" "$tmpdir/AGENTS.md"

  set +e
  python3 "$GEN" \
    --project-root "$tmpdir" \
    --generated "$FIXED_TIMESTAMP" \
    --skill-version "$FIXED_VERSION" \
    >/dev/null 2>&1
  local rc=$?
  set -e

  if [ "$rc" -eq 2 ]; then
    echo "PASS: $name (aborted with exit=2)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — expected exit 2, got $rc"
    FAIL=$((FAIL + 1))
  fi

  rm -rf "$tmpdir"
}

run_idempotent_test() {
  local name="$1"
  local fixture="$2"

  local tmpdir
  tmpdir=$(mktemp -d)
  copy_fixture "$fixture" "$tmpdir"

  python3 "$GEN" \
    --project-root "$tmpdir" \
    --generated "$FIXED_TIMESTAMP" \
    --skill-version "$FIXED_VERSION" >/dev/null

  cp "$tmpdir/AGENTS.md" "$tmpdir/first.md"

  python3 "$GEN" \
    --project-root "$tmpdir" \
    --generated "$FIXED_TIMESTAMP" \
    --skill-version "$FIXED_VERSION" >/dev/null

  if diff -u "$tmpdir/first.md" "$tmpdir/AGENTS.md" > "$tmpdir/diff.txt" 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — regeneration produced a diff"
    cat "$tmpdir/diff.txt"
    FAIL=$((FAIL + 1))
  fi

  rm -rf "$tmpdir"
}

run_stale_marker_cleared_test() {
  local name="$1"
  local fixture="$2"

  local tmpdir
  tmpdir=$(mktemp -d)
  copy_fixture "$fixture" "$tmpdir"

  mkdir -p "$tmpdir/.add"
  printf '{"timestamp":"%s","changed":["core/rules/test.md"]}\n' "$FIXED_TIMESTAMP" \
    > "$tmpdir/.add/agents-md.stale"

  python3 "$GEN" \
    --project-root "$tmpdir" \
    --generated "$FIXED_TIMESTAMP" \
    --skill-version "$FIXED_VERSION" >/dev/null 2>&1

  if [ ! -f "$tmpdir/.add/agents-md.stale" ]; then
    echo "PASS: $name (staleness marker cleared on write)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — stale marker still present after write"
    FAIL=$((FAIL + 1))
  fi

  rm -rf "$tmpdir"
}

echo "=== agents-md-sync fixture tests ==="
echo ""

run_render_test "POC render"   "$FIXTURES/poc-project"
run_render_test "Alpha render" "$FIXTURES/alpha-project"
run_render_test "Beta render"  "$FIXTURES/beta-project"

run_check_drift_test "drift detection (--check exits 1)" "$FIXTURES/drift-project"

run_merge_test "merge with hand-curated file" "$FIXTURES/merge-project"

run_missing_marker_abort_test "missing marker block aborts --write" "$FIXTURES/merge-project"

run_idempotent_test "idempotent regeneration" "$FIXTURES/alpha-project"

run_stale_marker_cleared_test "staleness marker cleared after --write" "$FIXTURES/alpha-project"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

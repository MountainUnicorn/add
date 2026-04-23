#!/usr/bin/env bash
# test-cache-discipline.sh — Fixture-based tests for validate-cache-discipline.py
#
# Runs the validator against fixture SKILL.md inputs and compares stdout
# against expected .txt files. Exits non-zero on any mismatch.
#
# Usage: bash tests/cache-discipline/test-cache-discipline.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-cache-discipline.py"
FIXTURES="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0

run_test() {
  local name="$1"
  local fixture="$2"
  local expected="$3"

  local tmpdir
  tmpdir=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmpdir'" RETURN

  # Run validator; capture stdout. Exit code must be 0 (warn-only default).
  if ! python3 "$VALIDATOR" "$fixture" > "$tmpdir/actual.txt" 2> "$tmpdir/stderr.txt"; then
    echo "FAIL: $name — validator exited non-zero (warn-only mode should exit 0)"
    cat "$tmpdir/stderr.txt"
    FAIL=$((FAIL + 1))
    return
  fi

  if diff -u "$expected" "$tmpdir/actual.txt" > "$tmpdir/diff.txt" 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    cat "$tmpdir/diff.txt"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== validate-cache-discipline.py fixture tests ==="
echo ""

if [ ! -x "$VALIDATOR" ]; then
  echo "ERROR: $VALIDATOR is not executable" >&2
  exit 1
fi

run_test "compliant (no findings)" \
  "$FIXTURES/compliant.md" \
  "$FIXTURES/compliant.expected.txt"

run_test "missing markers (CACHE-001)" \
  "$FIXTURES/missing-markers.md" \
  "$FIXTURES/missing-markers.expected.txt"

run_test "inverted markers (CACHE-002)" \
  "$FIXTURES/inverted.md" \
  "$FIXTURES/inverted.expected.txt"

run_test "volatile in stable (CACHE-003)" \
  "$FIXTURES/volatile-in-stable.md" \
  "$FIXTURES/volatile-in-stable.expected.txt"

run_test "no dispatch (silent skip)" \
  "$FIXTURES/no-dispatch.md" \
  "$FIXTURES/no-dispatch.expected.txt"

# Strict mode: any finding must exit non-zero.
echo ""
echo "=== --strict mode exit code ==="

tmpdir=$(mktemp -d)
trap "rm -rf '$tmpdir'" EXIT

set +e
python3 "$VALIDATOR" --strict "$FIXTURES/missing-markers.md" > "$tmpdir/strict-out.txt" 2>&1
strict_exit=$?
set -e

if [ "$strict_exit" -ne 0 ]; then
  echo "PASS: --strict exits non-zero on findings ($strict_exit)"
  PASS=$((PASS + 1))
else
  echo "FAIL: --strict should exit non-zero when findings are present"
  FAIL=$((FAIL + 1))
fi

# Compliant fixture under --strict must still exit 0.
set +e
python3 "$VALIDATOR" --strict "$FIXTURES/compliant.md" > "$tmpdir/strict-compliant.txt" 2>&1
strict_compliant_exit=$?
set -e

if [ "$strict_compliant_exit" -eq 0 ]; then
  echo "PASS: --strict exits 0 on compliant fixture"
  PASS=$((PASS + 1))
else
  echo "FAIL: --strict should exit 0 when no findings"
  cat "$tmpdir/strict-compliant.txt"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

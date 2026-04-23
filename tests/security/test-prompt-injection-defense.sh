#!/usr/bin/env bash
# test-prompt-injection-defense.sh — Fixture-based tests for posttooluse-scan.sh
#
# Runs the scan hook against fixture JSON inputs (piped to stdin) and verifies:
#   - Expected pattern fires (stderr contains ADD-SEC: pattern=<name>)
#   - Audit event is written to .add/security/injection-events.jsonl
#   - Negative controls do not fire
#   - No-op path: .add/ missing → exit 0, no audit log
#
# Fixtures are committed DEFANGED. The harness re-fangs them in tempdir before
# running the scanner. See tests/security/fixtures/defang-table.sh.
#
# Usage: bash tests/security/test-prompt-injection-defense.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCANNER="$REPO_ROOT/runtimes/claude/hooks/posttooluse-scan.sh"
FIXTURES="$SCRIPT_DIR/fixtures"

# shellcheck disable=SC1091
. "$FIXTURES/defang-table.sh"

PASS=0
FAIL=0

# Build the Unicode tag payload at runtime — a block of >= 3 U+E00xx characters.
# Python is the most portable way to emit non-BMP chars into a file.
unicode_tag_block() {
  python3 -c 'import sys; sys.stdout.write("".join(chr(0xE0041 + i) for i in range(5)))'
}

# Set up an isolated "project" directory with .add/ so the scanner has a home.
setup_project() {
  local proj="$1"
  mkdir -p "$proj/.add"
}

# Re-fang a fixture file into tempdir. If the fixture name matches
# unicode-tag-block we splice in the live unicode payload.
refang_fixture() {
  local src="$1"
  local dst="$2"
  if grep -q "__UNICODE_TAG_PAYLOAD__" "$src"; then
    # Build the unicode payload, jq-escape it, and splice in
    local payload
    payload=$(unicode_tag_block)
    # jq escapes the string safely for JSON
    jq --arg p "$payload" '.tool_response.content |= sub("__UNICODE_TAG_PAYLOAD__"; $p)' "$src" > "$dst"
  else
    defang_refang < "$src" > "$dst"
  fi
}

run_fires() {
  local name="$1"
  local fixture="$2"
  local expected_pattern="$3"

  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" RETURN

  setup_project "$tmpdir"
  refang_fixture "$FIXTURES/$fixture" "$tmpdir/input.json"

  local stderr_file="$tmpdir/stderr.txt"
  (
    cd "$tmpdir"
    "$SCANNER" < input.json 2> "$stderr_file"
  ) || true

  if ! grep -q "ADD-SEC:.*pattern=${expected_pattern}" "$stderr_file"; then
    echo "FAIL: $name — expected pattern=${expected_pattern} in stderr"
    echo "  stderr was:"
    sed 's/^/    /' "$stderr_file"
    FAIL=$((FAIL + 1))
    return
  fi

  local audit="$tmpdir/.add/security/injection-events.jsonl"
  if [ ! -f "$audit" ]; then
    echo "FAIL: $name — audit log not created at $audit"
    FAIL=$((FAIL + 1))
    return
  fi
  if ! jq -e --arg p "$expected_pattern" 'select(.pattern == $p)' "$audit" > /dev/null; then
    echo "FAIL: $name — no audit event with pattern=${expected_pattern}"
    echo "  audit contents:"
    sed 's/^/    /' "$audit"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "PASS: $name"
  PASS=$((PASS + 1))
}

run_benign() {
  local name="$1"
  local fixture="$2"

  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" RETURN

  setup_project "$tmpdir"
  refang_fixture "$FIXTURES/$fixture" "$tmpdir/input.json"

  local stderr_file="$tmpdir/stderr.txt"
  (
    cd "$tmpdir"
    "$SCANNER" < input.json 2> "$stderr_file"
  ) || true

  if grep -q "ADD-SEC:" "$stderr_file"; then
    echo "FAIL: $name — unexpected match on benign input"
    echo "  stderr was:"
    sed 's/^/    /' "$stderr_file"
    FAIL=$((FAIL + 1))
    return
  fi

  local audit="$tmpdir/.add/security/injection-events.jsonl"
  if [ -f "$audit" ] && [ -s "$audit" ]; then
    echo "FAIL: $name — audit log unexpectedly has entries"
    sed 's/^/    /' "$audit"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "PASS: $name"
  PASS=$((PASS + 1))
}

run_no_add_dir() {
  local name="$1"
  local fixture="$2"

  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" RETURN

  # No .add/ directory created — scanner should be a no-op.
  refang_fixture "$FIXTURES/$fixture" "$tmpdir/input.json"

  local stderr_file="$tmpdir/stderr.txt"
  local exit_code=0
  (
    cd "$tmpdir"
    "$SCANNER" < input.json 2> "$stderr_file"
  ) || exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    echo "FAIL: $name — exit $exit_code (expected 0)"
    FAIL=$((FAIL + 1))
    return
  fi
  if [ -e "$tmpdir/.add" ]; then
    echo "FAIL: $name — scanner created .add/ when it should have no-opped"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "PASS: $name"
  PASS=$((PASS + 1))
}

run_dispatcher_fanout() {
  local name="$1"
  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" RETURN

  setup_project "$tmpdir"
  # Simulate a Write event — inject stdin for both hooks in sequence and confirm
  # both exit 0 and neither prevents the other. post-write.sh needs a file_path
  # field; we point it at a non-existent path (it should exit 0 without error).
  local write_payload
  write_payload=$(jq -n '{tool_name: "Write", tool_input: {file_path: "/tmp/does-not-exist.txt"}}')
  local post_write="$REPO_ROOT/runtimes/claude/hooks/post-write.sh"

  local pw_rc=0 scan_rc=0
  (cd "$tmpdir" && echo "$write_payload" | "$post_write") || pw_rc=$?
  # Simulate a Read event for the scanner in parallel
  refang_fixture "$FIXTURES/ignore-previous.json" "$tmpdir/scan-input.json"
  (cd "$tmpdir" && "$SCANNER" < "$tmpdir/scan-input.json" 2>/dev/null) || scan_rc=$?

  if [ "$pw_rc" -ne 0 ]; then
    echo "FAIL: $name — post-write.sh exited $pw_rc"
    FAIL=$((FAIL + 1))
    return
  fi
  if [ "$scan_rc" -ne 0 ]; then
    echo "FAIL: $name — scan hook exited $scan_rc"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "PASS: $name"
  PASS=$((PASS + 1))
}

echo "=== posttooluse-scan.sh fixture tests ==="
echo ""

run_fires "AC-028 ignore-previous"          ignore-previous.json          ignore-previous
run_fires "AC-028 new-instructions-heading" new-instructions-heading.json new-instructions-heading
run_fires "AC-028 system-heading"           system-heading.json           system-heading
run_fires "AC-028 system-tag"               system-tag.json               system-tag
run_fires "AC-028 instruction-tag"          instruction-tag.json          instruction-tag
run_fires "AC-028 unicode-tag-block"        unicode-tag-block.json        unicode-tag-block
run_fires "AC-028 base64-blob-suspicious"   base64-blob.json              base64-blob-suspicious
run_fires "AC-028 comment-and-control"      comment-and-control.json      comment-and-control-marker

run_benign "AC-029 benign prose negative control" benign.json

run_no_add_dir "AC-017 .add/ missing → no-op" no-add-dir.json

run_dispatcher_fanout "AC-030 dispatcher fanout"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

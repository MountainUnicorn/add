#!/usr/bin/env bash
# test-hooks-json.sh — Fixture tests for the inline shell embedded in
# runtimes/claude/hooks/hooks.json (v0.9.10 hooks hardening).
#
# Covers:
#   1. hooks.json parses as valid JSON
#   2. PreToolUse/Bash inline command: CHANGELOG reminder fires on a real
#      `git push` payload (tool input JSON on stdin, parsed with jq) when
#      CHANGELOG.md exists — and does NOT fire for `echo "git push"`,
#      `git push --help`, or when CHANGELOG.md is absent
#   3. SessionStart registers load-rules.sh
#   4. PostToolUse no longer carries the (mistimed) CHANGELOG echo, but
#      still runs posttooluse-scan.sh on Bash
#
# Usage: bash tests/hooks-json/test-hooks-json.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_JSON="$REPO_ROOT/runtimes/claude/hooks/hooks.json"

PASS=0
FAIL=0
pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- 1. valid JSON --------------------------------------------------------------
if jq -e . "$HOOKS_JSON" >/dev/null 2>&1; then
  pass "hooks.json is valid JSON"
else
  fail "hooks.json is not valid JSON"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

# --- fixture: synthetic plugin root with a benign scan-secrets stub -------------
mkdir -p "$TMP/plugin/lib" "$TMP/project"
cat > "$TMP/plugin/lib/scan-secrets.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP/plugin/lib/scan-secrets.sh"

PRE_CMD=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].command' "$HOOKS_JSON")
if [ -n "$PRE_CMD" ] && [ "$PRE_CMD" != "null" ]; then
  pass "PreToolUse/Bash inline command extracted"
else
  fail "PreToolUse/Bash inline command missing"
fi

run_pre() { # $1 = tool-input command string; runs in $TMP/project; prints stderr
  printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" | (
    cd "$TMP/project" && CLAUDE_PLUGIN_ROOT="$TMP/plugin" bash -c "$PRE_CMD" 2>&1 >/dev/null
  )
}

REMINDER='run /add:changelog'

# --- 2a. real git push + CHANGELOG.md present → reminder on stderr ---------------
touch "$TMP/project/CHANGELOG.md"
OUT=$(run_pre 'git push origin main')
if echo "$OUT" | grep -q "$REMINDER"; then
  pass "reminder fires for 'git push origin main' when CHANGELOG.md exists"
else
  fail "reminder did not fire for a real git push (stderr: $OUT)"
fi

# --- 2b. chained command still matches -------------------------------------------
OUT=$(run_pre 'git add -A && git commit -m x && git push')
if echo "$OUT" | grep -q "$REMINDER"; then
  pass "reminder fires for chained '&& git push'"
else
  fail "reminder did not fire for chained git push (stderr: $OUT)"
fi

# --- 2c. echo "git push" must NOT fire -------------------------------------------
OUT=$(run_pre 'echo "git push"')
if echo "$OUT" | grep -q "$REMINDER"; then
  fail "reminder incorrectly fired for: echo \"git push\""
else
  pass "reminder does not fire for: echo \"git push\""
fi

# --- 2d. git push --help / --dry-run must NOT fire -------------------------------
OUT=$(run_pre 'git push --help')
if echo "$OUT" | grep -q "$REMINDER"; then
  fail "reminder incorrectly fired for: git push --help"
else
  pass "reminder does not fire for: git push --help"
fi

OUT=$(run_pre 'git push --dry-run origin main')
if echo "$OUT" | grep -q "$REMINDER"; then
  fail "reminder incorrectly fired for: git push --dry-run"
else
  pass "reminder does not fire for: git push --dry-run"
fi

# --- 2e. no CHANGELOG.md → no reminder even on a real push ------------------------
rm "$TMP/project/CHANGELOG.md"
OUT=$(run_pre 'git push origin main')
if echo "$OUT" | grep -q "$REMINDER"; then
  fail "reminder incorrectly fired with no CHANGELOG.md present"
else
  pass "reminder does not fire when CHANGELOG.md is absent"
fi

# --- 2f. hook always exits 0 (advisory, never blocking) ---------------------------
touch "$TMP/project/CHANGELOG.md"
printf '{"tool_input":{"command":"git push"}}' | (
  cd "$TMP/project" && CLAUDE_PLUGIN_ROOT="$TMP/plugin" bash -c "$PRE_CMD" >/dev/null 2>&1
)
if [ $? -eq 0 ]; then
  pass "PreToolUse command exits 0 (advisory only)"
else
  fail "PreToolUse command exited non-zero"
fi

# --- 3. SessionStart registers load-rules.sh --------------------------------------
if jq -e '.hooks.SessionStart[0].hooks[] | select(.command | contains("load-rules.sh"))' \
    "$HOOKS_JSON" >/dev/null 2>&1; then
  pass "SessionStart registers load-rules.sh"
else
  fail "SessionStart entry for load-rules.sh missing"
fi

# --- 4a. PostToolUse carries no CHANGELOG echo anymore -----------------------------
if jq -r '[.hooks.PostToolUse[].hooks[].command] | join("\n")' "$HOOKS_JSON" \
    | grep -qi 'changelog'; then
  fail "PostToolUse still contains a CHANGELOG echo (should live in PreToolUse)"
else
  pass "PostToolUse has no CHANGELOG echo"
fi

# --- 4b. PostToolUse/Bash still runs posttooluse-scan.sh ---------------------------
if jq -e '.hooks.PostToolUse[] | select(.matcher == "Bash") | .hooks[] | select(.command | contains("posttooluse-scan.sh"))' \
    "$HOOKS_JSON" >/dev/null 2>&1; then
  pass "PostToolUse/Bash keeps posttooluse-scan.sh"
else
  fail "PostToolUse/Bash lost the posttooluse-scan.sh entry"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

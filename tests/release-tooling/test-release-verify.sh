#!/usr/bin/env bash
# test-release-verify.sh — Regression test for issue #18.
#
# #18: scripts/release.sh could exit 0 while silently skipping the actual
# `gh release create` (the signed tag pushed, but no GitHub release page was
# ever published). Same failure class as F-001 (a command that "succeeds"
# without doing the thing). The fix makes release.sh VERIFY the release page
# exists after creating it, and fail loudly if it does not.
#
# This suite statically asserts the safeguards are present, so the silent-skip
# regression can't return, and runs shellcheck when available.
#
# Usage: bash tests/release-tooling/test-release-verify.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_SH="$REPO_ROOT/scripts/release.sh"

PASS=0
FAIL=0
pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "=== release.sh #18 regression check ==="
echo ""

if [ ! -f "$RELEASE_SH" ]; then
  fail "scripts/release.sh not found"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

# 1. The release is verified AFTER it is created -------------------------------
create_line=$(grep -n 'gh release create' "$RELEASE_SH" | head -1 | cut -d: -f1)
view_line=$(grep -n 'gh release view' "$RELEASE_SH" | head -1 | cut -d: -f1)

if [ -z "$create_line" ]; then
  fail "release.sh no longer calls 'gh release create'"
elif [ -z "$view_line" ]; then
  fail "release.sh never verifies the release with 'gh release view' (the #18 fix)"
elif [ "$view_line" -gt "$create_line" ]; then
  pass "release.sh verifies the release with 'gh release view' after creating it"
else
  fail "'gh release view' appears before 'gh release create' (verification must follow creation)"
fi

# 2. Flags passed via array, not an unquoted word-split variable ---------------
if grep -qE '^\s*\$DRAFT_FLAG\b' "$RELEASE_SH"; then
  fail "release.sh still expands an unquoted \$DRAFT_FLAG (word-splitting fragility from #18)"
else
  pass "release.sh does not rely on an unquoted \$DRAFT_FLAG expansion"
fi

# 3. Success message is not printed unconditionally before verification --------
# The "published" confirmation must come AFTER the gh release view check.
published_line=$(grep -n 'published' "$RELEASE_SH" | head -1 | cut -d: -f1)
if [ -n "$published_line" ] && [ -n "$view_line" ] && [ "$published_line" -lt "$view_line" ]; then
  fail "'published' success message prints before the release is verified"
else
  pass "success message only prints after release verification"
fi

# 4. shellcheck clean (skipped gracefully if shellcheck is unavailable) --------
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S error "$RELEASE_SH" >/tmp/release-shellcheck.log 2>&1; then
    pass "shellcheck reports no errors in release.sh"
  else
    fail "shellcheck found errors in release.sh:"
    sed 's/^/    /' /tmp/release-shellcheck.log
  fi
else
  echo "SKIP: shellcheck not installed (static asserts above still ran)"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

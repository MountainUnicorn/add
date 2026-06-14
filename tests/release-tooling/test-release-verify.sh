#!/usr/bin/env bash
# test-release-verify.sh — Regression test for issue #18.
#
# #18: scripts/release.sh could exit 0 after pushing the signed tag without ever
# creating the GitHub release page (same failure class as F-001 — a command
# that "succeeds" without doing the thing). The fix makes release.sh VERIFY the
# release page exists after creating it (`gh release view`) and fail loudly.
#
# This suite is primarily BEHAVIORAL: it puts mock `git`, `gh`, and `python3` on
# PATH and actually runs release.sh end-to-end, asserting the exit code for the
# #18 symptom (create "succeeds", no page exists). A static check guards the
# unquoted-$DRAFT_FLAG word-split hazard, and shellcheck runs when available.
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

# ---- Behavioral harness ------------------------------------------------------
# Build a shim dir whose mock git/gh/python3 satisfy every gate in release.sh so
# control flow reaches the create+verify block. `gh release view` behaviour is
# driven by GH_VIEW_MODE: url (page exists), empty (0 but no url), fail (non-0).
make_shims() {
  local shim="$1"
  cat >"$shim/git" <<'EOS'
#!/usr/bin/env bash
case "$1" in
  branch)    echo main ;;       # on main
  status)    : ;;               # clean tree (no output)
  config)    echo TESTKEY ;;    # signing key configured
  rev-parse) exit 1 ;;          # tag does not already exist
  tag)       : ;;               # tag -s / tag --verify succeed
  push)      : ;;               # push succeeds
  *)         : ;;
esac
EOS
  cat >"$shim/gh" <<'EOS'
#!/usr/bin/env bash
if [ "$1 $2" = "release create" ]; then exit 0; fi   # "succeeds" — the #18 trap
if [ "$1 $2" = "release view" ]; then
  case "${GH_VIEW_MODE:-url}" in
    url)   echo "https://github.com/MountainUnicorn/add/releases/tag/TESTTAG" ;;
    empty) : ;;          # exit 0 but prints nothing
    fail)  exit 1 ;;     # no release page
  esac
  exit 0
fi
exit 0
EOS
  # Short-circuit the two validator invocations so the behavioral test doesn't
  # couple to frontmatter/compile state; pass through any other python3 use.
  cat >"$shim/python3" <<'EOS'
#!/usr/bin/env bash
case "$*" in
  *validate-frontmatter*|*"compile.py --check"*) exit 0 ;;
  *) exec /usr/bin/env -i PATH="${REAL_PATH}" python3 "$@" ;;
esac
EOS
  chmod +x "$shim/git" "$shim/gh" "$shim/python3"
}

run_release() {
  # $1 = GH_VIEW_MODE ; echoes "<exit_code>|<output>"
  local mode="$1" shim out rc
  shim=$(mktemp -d)
  make_shims "$shim"
  local tag="v$(cat "$REPO_ROOT/core/VERSION" | tr -d '[:space:]')"
  out=$(cd "$REPO_ROOT" && GH_VIEW_MODE="$mode" REAL_PATH="$PATH" \
        PATH="$shim:$PATH" bash scripts/release.sh "$tag" 2>&1)
  rc=$?
  rm -rf "$shim"
  printf '%s|%s' "$rc" "$out"
}

# 1. Happy path: page exists -> exit 0, "published and verified" --------------
res=$(run_release url); rc=${res%%|*}; out=${res#*|}
if [ "$rc" = "0" ] && printf '%s' "$out" | grep -q "published and verified"; then
  pass "happy path: release verified -> exit 0"
else
  fail "happy path did not succeed (rc=$rc)"; printf '%s\n' "$out" | sed 's/^/    /'
fi

# 2. #18 symptom: create exits 0 but no page -> MUST exit non-zero ------------
res=$(run_release fail); rc=${res%%|*}; out=${res#*|}
if [ "$rc" != "0" ] && printf '%s' "$out" | grep -q "not published"; then
  pass "#18 symptom (no release page) is caught -> exit $rc with recovery message"
else
  fail "#18 symptom was NOT caught (rc=$rc) — script can still lie about publishing"
  printf '%s\n' "$out" | sed 's/^/    /'
fi

# 3. view returns 0 but empty url -> MUST exit non-zero -----------------------
res=$(run_release empty); rc=${res%%|*}
if [ "$rc" != "0" ]; then
  pass "empty release URL is treated as failure -> exit $rc"
else
  fail "empty release URL slipped through as success"
fi

# 4. Static: no unquoted \$DRAFT_FLAG word-split (a suspected #18 contributor) -
if grep -qE '^\s*\$DRAFT_FLAG\b' "$RELEASE_SH"; then
  fail "release.sh still expands an unquoted \$DRAFT_FLAG"
else
  pass "release.sh does not rely on an unquoted \$DRAFT_FLAG expansion"
fi

# 5. Static: a REAL (non-comment, non-echo) gh release view call exists --------
if grep -vE '^\s*(#|echo)' "$RELEASE_SH" | grep -q 'gh release view'; then
  pass "release.sh has a real 'gh release view' verification command"
else
  fail "release.sh has no real 'gh release view' command (only echoes/comments?)"
fi

# 6. shellcheck clean (skipped gracefully if unavailable) ----------------------
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S error "$RELEASE_SH" >/tmp/release-shellcheck.log 2>&1; then
    pass "shellcheck reports no errors in release.sh"
  else
    fail "shellcheck found errors in release.sh:"; sed 's/^/    /' /tmp/release-shellcheck.log
  fi
else
  echo "SKIP: shellcheck not installed (behavioral + static asserts above still ran)"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

#!/usr/bin/env bash
# test-install-paths.sh — Regression test for F-002: Codex installer path mismatch.
#
# Invokes scripts/install-codex.sh against a temp CODEX_HOME and asserts:
#   1. Install completes without error
#   2. Every ~/.codex/... reference found inside installed skill bodies points at
#      an installed file or directory that actually exists under the temp home
#      (allowing a small allowlist of intentional user-owned paths)
#
# Usage: bash tests/codex-install/test-install-paths.sh

set -u  # do not set -e; we report failures structurally

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-codex.sh"

PASS=0
FAIL=0

fail() {
  echo "FAIL: $*"
  FAIL=$((FAIL + 1))
}
pass() {
  echo "PASS: $*"
  PASS=$((PASS + 1))
}

# Allowlist: absolute paths skills may reference without staging. Paths that are
# intentionally user-owned (e.g. a project-level AGENTS.md) or that intentionally
# escape the install root (e.g. repo scripts referenced for developer tasks).
#
# Grepped fragments match "contains substring" against the captured path.
ALLOWLIST=(
  "~/.codex/add/../../scripts/"           # legacy ref into repo scripts — tracked separately
  "~/.codex/add/.claude-plugin/plugin.json" # /add:version reads Claude manifest; Codex
                                            # equivalent is add/plugin.toml or add/VERSION.
                                            # Follow-up: teach /add:version to handle
                                            # both runtimes (v0.8.2 micro-fix).
)

is_allowlisted() {
  local p="$1"
  for allowed in "${ALLOWLIST[@]}"; do
    if [[ "$p" == *"$allowed"* ]]; then
      return 0
    fi
  done
  return 1
}

# ---- Step 1: install into a throwaway CODEX_HOME -------------------------

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

echo "=== Codex install-path smoke (F-002 regression) ==="
echo "Temp CODEX_HOME: $TMP_HOME"
echo ""

if ! CODEX_HOME="$TMP_HOME" bash "$INSTALLER" >/dev/null 2>"$TMP_HOME/install.err"; then
  fail "installer exited non-zero:"
  cat "$TMP_HOME/install.err"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi
pass "installer completed"

# ---- Step 2: collect every ~/.codex/... reference from installed skills ---

SKILLS_DIR="$TMP_HOME/skills"
if [ ! -d "$SKILLS_DIR" ]; then
  fail "expected skills dir not found: $SKILLS_DIR"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

# Find all ~/.codex/... path fragments in installed skill bodies
REFS_FILE="$TMP_HOME/refs.txt"
grep -rhoE '~/\.codex/[A-Za-z0-9._/-]+' "$SKILLS_DIR" 2>/dev/null | sort -u > "$REFS_FILE" || true

ref_count=$(wc -l <"$REFS_FILE" | tr -d ' ')
echo "Found $ref_count unique ~/.codex/... reference(s) in installed skills"

# ---- Step 3: resolve each reference against the temp home -----------------

unresolved=()
while IFS= read -r ref; do
  [ -n "$ref" ] || continue

  # Skip trailing punctuation sometimes captured inside markdown prose
  clean=$(echo "$ref" | sed 's/[.,;:]*$//')

  # Resolve ~/.codex -> $TMP_HOME
  resolved="${clean/#~\/.codex/$TMP_HOME}"

  if is_allowlisted "$clean"; then
    continue
  fi

  if [ ! -e "$resolved" ]; then
    unresolved+=("$clean")
  fi
done < "$REFS_FILE"

if [ ${#unresolved[@]} -eq 0 ]; then
  pass "every reference resolves to an installed file or allowlisted path"
else
  fail "${#unresolved[@]} reference(s) do not resolve under temp CODEX_HOME:"
  for u in "${unresolved[@]}"; do
    echo "  unresolved: $u"
  done
fi

# ---- Step 4: explicit assertions for the F-002 asset groups ---------------

for expected in \
  "$TMP_HOME/add/templates" \
  "$TMP_HOME/add/knowledge" \
  "$TMP_HOME/add/rules" \
  "$TMP_HOME/add/lib" \
  "$TMP_HOME/add/security"
do
  name=$(basename "$expected")
  if [ -d "$expected" ] && [ -n "$(ls -A "$expected" 2>/dev/null)" ]; then
    pass "shared asset tree installed: $name/"
  else
    fail "shared asset tree missing or empty: $name/"
  fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

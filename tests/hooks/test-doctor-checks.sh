#!/usr/bin/env bash
# test-doctor-checks.sh — Fixture-based tests for core/lib/doctor-checks.sh
#
# Exercises the /add:doctor check library (spec: specs/doctor.md, issue #25)
# against fixture $CODEX_HOME-shaped trees under fixtures/doctor/.
# Exits non-zero on failure.
#
# Library contract under test (spec AC-1):
#   - Pure functions over a root-dir argument: check_config_features,
#     check_hooks_schema, check_agent_tomls, check_plugin_paths,
#     check_manifest.
#   - Each prints structured lines: CHECK <id> <pass|warn|fail|info|skip> <detail>
#   - Exit codes: 0 = pass/info/skip, 1 = warn, 2 = fail.
#
# Usage: bash tests/hooks/test-doctor-checks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB="$REPO_ROOT/core/lib/doctor-checks.sh"
FIXTURES="$SCRIPT_DIR/fixtures/doctor"

PASS=0
FAIL=0

if [ ! -f "$LIB" ]; then
  echo "FAIL: library not found at $LIB"
  echo ""
  echo "=== Results: 0 passed, 1 failed ==="
  exit 1
fi

# Run a single check function against a fixture root; capture output + exit code.
# run_check <function> <fixture-subdir>
# Sets: OUT (stdout+stderr), CODE (exit code)
run_check() {
  local fn="$1"
  local root="$FIXTURES/$2"
  set +e
  OUT=$(bash -c "source '$LIB' && $fn '$root'" 2>&1)
  CODE=$?
  set -e
}

# assert <name> <expected-exit-code> <regex output must match> [regex output must NOT match]
assert() {
  local name="$1" want_code="$2" want_re="$3" not_re="${4:-}"
  local ok=1
  [ "$CODE" -eq "$want_code" ] || ok=0
  echo "$OUT" | grep -qE "$want_re" || ok=0
  if [ -n "$not_re" ] && echo "$OUT" | grep -qE "$not_re"; then ok=0; fi
  if [ "$ok" -eq 1 ]; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    echo "  exit code: got $CODE, want $want_code"
    echo "  output:"
    echo "$OUT" | sed 's/^/    | /'
    FAIL=$((FAIL + 1))
  fi
}

echo "=== doctor-checks.sh fixture tests ==="
echo ""

# --- Healthy home: every check passes (spec AC-2 case 1) -----------------

run_check check_config_features healthy
assert "healthy: D-CFG passes" 0 '^CHECK D-CFG pass'

run_check check_hooks_schema healthy
assert "healthy: D-HOOKS passes" 0 '^CHECK D-HOOKS pass'

run_check check_agent_tomls healthy
assert "healthy: D-AGENTS passes" 0 '^CHECK D-AGENTS pass'

run_check check_plugin_paths healthy
assert "healthy: D-PATHS passes" 0 '^CHECK D-PATHS pass'

run_check check_manifest healthy
assert "healthy: D-MANIFEST passes" 0 '^CHECK D-MANIFEST pass'

# --- Legacy flat hooks.json fails D-HOOKS (spec AC-2 case 2) -------------

run_check check_hooks_schema hooks-legacy
assert "legacy flat hooks.json: D-HOOKS fails" 2 '^CHECK D-HOOKS fail'

# --- prompt_skill agent TOML fails D-AGENTS (spec AC-2 case 3) -----------

run_check check_agent_tomls agents-promptskill
assert "prompt_skill TOML: D-AGENTS fails" 2 '^CHECK D-AGENTS fail.*prompt_skill'

# --- Manifest listing a missing file fails D-MANIFEST (AC-2 case 4) ------

run_check check_manifest manifest-missing
assert "manifest missing file: D-MANIFEST fails" 2 '^CHECK D-MANIFEST fail.*ghost\.toml'

# --- Checksum mismatch is info (user-modified), NOT error (AC-2 case 5) --

run_check check_manifest manifest-modified
assert "checksum mismatch: info/user-modified, not error" 0 \
  '^CHECK D-MANIFEST info.*user-modified' \
  '^CHECK D-MANIFEST fail'

# --- Supplementary coverage ----------------------------------------------

# config.toml with a feature gate off fails D-CFG
run_check check_config_features config-bad
assert "feature gate off: D-CFG fails" 2 '^CHECK D-CFG fail.*codex_hooks'

# plugin.toml referencing a missing skill fails D-PATHS
run_check check_plugin_paths paths-broken
assert "broken plugin.toml path: D-PATHS fails" 2 '^CHECK D-PATHS fail'

# No install-manifest.json (pre-#27 installs) is a silent skip, not an error
run_check check_manifest hooks-legacy
assert "no manifest present: D-MANIFEST skips" 0 '^CHECK D-MANIFEST skip'

# Non-executable hook script fails D-HOOKS even with a valid nested schema
run_check check_hooks_schema hooks-noexec
assert "non-executable hook script: D-HOOKS fails" 2 '^CHECK D-HOOKS fail'

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

#!/usr/bin/env bash
# test-jq-claim-qualified.sh — F-017 regression guard.
#
# ADD's user-facing prose used to claim "zero (runtime) dependencies" without
# qualification, which is technically inaccurate — several runtime hook
# scripts shipped since v0.7 invoke `jq`, a tool not universally pre-installed.
#
# Strategy A from specs/jq-dependency-declaration.md qualifies the claim
# across README, CONTRIBUTING, PRD, and marketplace.json. This test fails
# the build if the bare phrase reappears in any of those four files, and
# also fails if the new docs/runtime-dependencies.md is missing or no
# longer reachable from the qualifying prose.
#
# Historical files (docs/milestones/, CHANGELOG.md, specs/, docs/plans/)
# are deliberately NOT scanned — see AC-008/AC-009/AC-010.
#
# Usage: bash tests/jq-dependency/test-jq-claim-qualified.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Files in scope for the dependency-claim guard.
SCOPE=(
  "$REPO_ROOT/README.md"
  "$REPO_ROOT/CONTRIBUTING.md"
  "$REPO_ROOT/docs/prd.md"
  "$REPO_ROOT/.claude-plugin/marketplace.json"
)

PASS=0
FAIL=0

# ---- Test 1: bare claim absent from in-scope prose ----------------------------

bare_claim_offenders=()
for path in "${SCOPE[@]}"; do
  if [ ! -f "$path" ]; then
    echo "FAIL: scope file missing: $path"
    FAIL=$((FAIL + 1))
    continue
  fi
  # Match either "zero dependencies" or "zero runtime dependencies" or
  # "no runtime dependencies" — case-insensitive — without a qualifier.
  # The qualifier we accept is "agent-side" appearing on the same line
  # OR the line explicitly mentions "jq" as an exception.
  hits=$(grep -niE "zero (runtime )?dependencies|no runtime dependencies" "$path" || true)
  if [ -z "$hits" ]; then
    continue
  fi
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Allowlist: any line that mentions "agent-side" or "jq" alongside the
    # claim is considered qualified.
    if echo "$line" | grep -qiE "agent-side|jq"; then
      continue
    fi
    bare_claim_offenders+=("$path: $line")
  done <<<"$hits"
done

if [ ${#bare_claim_offenders[@]} -eq 0 ]; then
  echo "PASS: no unqualified zero-dependencies claim in scope files"
  PASS=$((PASS + 1))
else
  echo "FAIL: unqualified zero-dependencies claim still present:"
  for offender in "${bare_claim_offenders[@]}"; do
    echo "  $offender"
  done
  FAIL=$((FAIL + 1))
fi

# ---- Test 2: docs/runtime-dependencies.md exists ------------------------------

DEPS_DOC="$REPO_ROOT/docs/runtime-dependencies.md"
if [ -f "$DEPS_DOC" ]; then
  echo "PASS: docs/runtime-dependencies.md exists"
  PASS=$((PASS + 1))
else
  echo "FAIL: docs/runtime-dependencies.md missing"
  FAIL=$((FAIL + 1))
fi

# ---- Test 3: each in-scope claim site references the new doc ------------------

unreachable=()
for path in "${SCOPE[@]}"; do
  [ -f "$path" ] || continue
  if ! grep -q "runtime-dependencies" "$path"; then
    unreachable+=("$path")
  fi
done

if [ ${#unreachable[@]} -eq 0 ]; then
  echo "PASS: every claim site references runtime-dependencies"
  PASS=$((PASS + 1))
else
  echo "FAIL: claim sites missing reference to runtime-dependencies.md:"
  for path in "${unreachable[@]}"; do
    echo "  $path"
  done
  FAIL=$((FAIL + 1))
fi

# ---- Test 4: historical text preserved untouched ------------------------------
# AC-008/AC-009/AC-010 — these files MUST still contain the old phrasing.

historical_breaks=()

# AC-008: docs/milestones/M1-core-plugin.md retains "zero runtime dependencies".
if [ -f "$REPO_ROOT/docs/milestones/M1-core-plugin.md" ]; then
  if ! grep -qi "zero runtime dependencies" "$REPO_ROOT/docs/milestones/M1-core-plugin.md"; then
    historical_breaks+=("docs/milestones/M1-core-plugin.md no longer contains historical 'zero runtime dependencies'")
  fi
fi

# AC-010: specs/plugin-installation-reliability.md retains "zero dependencies"
# context line.
if [ -f "$REPO_ROOT/specs/plugin-installation-reliability.md" ]; then
  if ! grep -qi "zero dependencies" "$REPO_ROOT/specs/plugin-installation-reliability.md"; then
    historical_breaks+=("specs/plugin-installation-reliability.md no longer contains historical 'zero dependencies'")
  fi
fi

if [ ${#historical_breaks[@]} -eq 0 ]; then
  echo "PASS: historical text preserved (AC-008, AC-010)"
  PASS=$((PASS + 1))
else
  echo "FAIL: historical text was modified — AC-008/AC-010 violation:"
  for entry in "${historical_breaks[@]}"; do
    echo "  $entry"
  done
  FAIL=$((FAIL + 1))
fi

# ---- Summary ------------------------------------------------------------------

echo
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "See: docs/runtime-dependencies.md for the qualified phrasing"
  echo "Spec: specs/jq-dependency-declaration.md"
  exit 1
fi

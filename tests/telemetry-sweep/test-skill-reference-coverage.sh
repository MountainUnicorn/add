#!/usr/bin/env bash
# test-skill-reference-coverage.sh — F-013 coverage fixture
#
# Asserts every core/skills/*/SKILL.md declares the telemetry rule via
# the PR #6 references frontmatter mechanism (Path A from
# specs/telemetry-skill-reference-sweep.md).
#
# Contract:
#   * Each SKILL.md must have a YAML `references:` array containing the
#     literal string "rules/telemetry.md".
#   * Sub-agent skills (reviewer, test-writer, implementer, verify) are
#     NOT exempt — per spec AC-011 ("no implicit-emission shortcut") and
#     AC-016/AC-017 (sub-agents emit nested lines and carry their own
#     reference). Every skill is explicit.
#   * Test runs in <2s (AC-022).
#   * Self-tests against fixtures under tests/telemetry-sweep/fixtures/
#     to defend the matcher itself.
#
# Spec: specs/telemetry-skill-reference-sweep.md
# Plan: docs/plans/telemetry-skill-reference-sweep-plan.md
#
# Usage: bash tests/telemetry-sweep/test-skill-reference-coverage.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0
MISSING=()

# ---- Matcher -----------------------------------------------------------
# Returns 0 if the given SKILL.md declares "rules/telemetry.md" inside its
# YAML `references:` array (any list shape PyYAML accepts).
has_telemetry_reference() {
  local file="$1"
  python3 - "$file" <<'PY'
import re, sys, yaml
text = open(sys.argv[1]).read()
m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
if not m:
    sys.exit(2)
fm = yaml.safe_load(m.group(1)) or {}
refs = fm.get("references") or []
if not isinstance(refs, list):
    sys.exit(3)
sys.exit(0 if "rules/telemetry.md" in refs else 1)
PY
}

# ---- Self-tests against fixtures ---------------------------------------
echo "Self-test: matcher against fixtures..."

self_test() {
  local fixture="$1"
  local expect="$2"  # "pass" or "fail"
  local label="$3"
  if has_telemetry_reference "$FIXTURES/$fixture"; then
    actual="pass"
  else
    actual="fail"
  fi
  if [ "$actual" = "$expect" ]; then
    echo "  ok  : $label ($fixture)"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $label ($fixture) — expected=$expect actual=$actual" >&2
    FAIL=$((FAIL+1))
  fi
}

self_test has-reference.md       pass "fixture with rules/telemetry.md present"
self_test has-reference-multi.md pass "fixture with multi-entry references including telemetry"
self_test missing-reference.md   fail "fixture with references but no telemetry"
self_test no-references-key.md   fail "fixture with no references key"

# ---- Coverage sweep ----------------------------------------------------
echo
echo "Coverage: every core/skills/*/SKILL.md declares rules/telemetry.md..."

SKILLS_DIR="$REPO_ROOT/core/skills"
TOTAL=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    echo "  SKIP: $skill_name (no SKILL.md)"
    continue
  fi
  TOTAL=$((TOTAL+1))
  if has_telemetry_reference "$skill_file"; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    MISSING+=("$skill_name")
  fi
done

echo "  Inspected $TOTAL SKILL.md files."

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo
  echo "✗ Skills missing rules/telemetry.md in references:" >&2
  for s in "${MISSING[@]}"; do
    echo "    - $s" >&2
  done
fi

# ---- Summary -----------------------------------------------------------
echo
echo "==========================================="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "==========================================="

if [ "$FAIL" -eq 0 ]; then
  echo "✓ All skills declare rules/telemetry.md (F-013 coverage complete)"
  exit 0
fi
exit 1

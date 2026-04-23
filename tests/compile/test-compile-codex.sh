#!/usr/bin/env bash
# test-compile-codex.sh — unit-ish tests for the compile.py Codex path.
#
# Exercises the new helpers (load_skill_policy, emit_codex_native_skills,
# emit_codex_manifest_agents_md) via the public CLI. Fast — runs compile
# once and asserts on structural invariants.
#
# Usage: bash tests/compile/test-compile-codex.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }
pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }

cd "$REPO_ROOT"

echo "==> Verifying every core/skills/* has a skill-policy.yaml entry"
for skill_dir in core/skills/*/; do
  skill=$(basename "$skill_dir")
  if grep -q "^  - skill: $skill\$" runtimes/codex/skill-policy.yaml; then
    pass "skill $skill has policy entry"
  else
    fail "skill $skill missing from skill-policy.yaml"
  fi
done

echo "==> Running compile.py --runtime codex"
python3 scripts/compile.py --runtime codex >/dev/null

echo "==> Verifying skill count parity (source vs emitted)"
source_count=$(ls -1 core/skills/ | wc -l | tr -d ' ')
emitted_count=$(ls -1 dist/codex/.agents/skills/ | wc -l | tr -d ' ')
if [ "$source_count" -eq "$emitted_count" ]; then
  pass "skill count parity: $source_count source == $emitted_count emitted"
else
  fail "skill count mismatch: $source_count source vs $emitted_count emitted"
fi

echo "==> Verifying each emitted SKILL.md has frontmatter delimiters"
bad=0
for f in dist/codex/.agents/skills/*/SKILL.md; do
  if ! head -1 "$f" | grep -q "^---$"; then
    fail "missing leading '---' in $f"
    bad=$((bad + 1))
  fi
done
if [ "$bad" -eq 0 ]; then
  pass "every SKILL.md starts with '---'"
fi

echo "==> Verifying agents/openai.yaml count parity"
yaml_count=$(find dist/codex/.agents/skills -name "openai.yaml" | wc -l | tr -d ' ')
if [ "$yaml_count" -eq "$emitted_count" ]; then
  pass "openai.yaml parity: $yaml_count yamls == $emitted_count skills"
else
  fail "openai.yaml mismatch: $yaml_count yamls vs $emitted_count skills"
fi

echo "==> Verifying --check runs cleanly after compile"
if python3 scripts/compile.py --check >/dev/null 2>&1; then
  pass "compile.py --check clean"
else
  fail "compile.py --check reports drift"
fi

echo ""
echo "========================================"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

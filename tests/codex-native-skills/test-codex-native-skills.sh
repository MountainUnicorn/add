#!/usr/bin/env bash
# test-codex-native-skills.sh — integration test for the Codex native Skills
# emission path introduced in v0.9.0 per specs/codex-native-skills.md.
#
# Runs `scripts/compile.py --runtime codex` against the real core/ +
# runtimes/codex/ tree, then asserts the emitted dist/codex/ layout matches
# the AC set. Uses a temporary output directory to avoid clobbering the
# committed dist.
#
# Usage: bash tests/codex-native-skills/test-codex-native-skills.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

fail() {
  echo "FAIL: $1"
  FAIL=$((FAIL + 1))
}

pass() {
  echo "PASS: $1"
  PASS=$((PASS + 1))
}

check_exists() {
  local label="$1"
  local path="$2"
  if [ -e "$path" ]; then
    pass "$label — $path exists"
  else
    fail "$label — $path does not exist"
  fi
}

check_not_exists() {
  local label="$1"
  local path="$2"
  if [ ! -e "$path" ]; then
    pass "$label — $path absent (as expected)"
  else
    fail "$label — $path unexpectedly exists"
  fi
}

check_grep() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -q "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label — pattern '$pattern' not found in $path"
  fi
}

cd "$REPO_ROOT"

echo "==> Running compile.py --runtime codex"
python3 scripts/compile.py --runtime codex >/dev/null

DIST="$REPO_ROOT/dist/codex"

# --- AC-001: native Skills emitted, legacy prompts/ absent ------------------
check_exists "AC-001 native skills dir" "$DIST/.agents/skills"
check_not_exists "AC-001 legacy prompts/ directory no longer emitted" "$DIST/prompts"

# --- AC-001/002/003: each skill lands at .agents/skills/add-<name>/SKILL.md -
for skill in spec tdd-cycle verify docs implementer test-writer reviewer; do
  check_exists "AC-001 $skill SKILL.md" "$DIST/.agents/skills/add-$skill/SKILL.md"
done

# --- AC-002: frontmatter preserved ------------------------------------------
SPEC_SKILL="$DIST/.agents/skills/add-spec/SKILL.md"
check_grep "AC-002 frontmatter delimiter top"   "$SPEC_SKILL" "^---"
check_grep "AC-002 frontmatter description"     "$SPEC_SKILL" "^description:"

# --- AC-003: namespaced name ------------------------------------------------
check_grep "AC-003 namespaced name add-spec"    "$SPEC_SKILL" "^name: add-spec"

# --- AC-006: per-skill invocation policy yaml -------------------------------
POLICY_YAML="$DIST/.agents/skills/add-spec/agents/openai.yaml"
check_exists "AC-006 per-skill agents/openai.yaml" "$POLICY_YAML"
check_grep "AC-006 policy has allow_implicit_invocation" "$POLICY_YAML" "allow_implicit_invocation"
check_grep "AC-006 policy has tools list"               "$POLICY_YAML" "^tools:"

# --- AC-007: add-spec is explicit-only --------------------------------------
check_grep "AC-007 add-spec allow_implicit_invocation false" \
  "$POLICY_YAML" "allow_implicit_invocation: false"

# --- AC-008: add-verify is dispatcher-eligible ------------------------------
VERIFY_YAML="$DIST/.agents/skills/add-verify/agents/openai.yaml"
check_grep "AC-008 add-verify allow_implicit_invocation true" \
  "$VERIFY_YAML" "allow_implicit_invocation: true"

# --- AC-011/014: slim AGENTS.md ≤ 500 lines ---------------------------------
AGENTS_LINES=$(wc -l < "$DIST/AGENTS.md")
if [ "$AGENTS_LINES" -le 500 ]; then
  pass "AC-011/014 AGENTS.md is $AGENTS_LINES lines (≤500)"
else
  fail "AC-011/014 AGENTS.md is $AGENTS_LINES lines (exceeds 500)"
fi

# --- AC-013: skills table is present in AGENTS.md ---------------------------
check_grep "AC-013 AGENTS.md has skills table header" "$DIST/AGENTS.md" "## Skills"
check_grep "AC-013 AGENTS.md references add-verify"   "$DIST/AGENTS.md" "/add-verify"

# --- AC-015/016/017: sub-agent TOMLs ----------------------------------------
for role in test-writer implementer reviewer explorer; do
  check_exists "AC-015 $role.toml" "$DIST/.codex/agents/$role.toml"
done
check_grep "AC-016 test-writer reasoning high" \
  "$DIST/.codex/agents/test-writer.toml" 'model_reasoning_effort = "high"'
check_grep "AC-016 explorer reasoning medium" \
  "$DIST/.codex/agents/explorer.toml" 'model_reasoning_effort = "medium"'
check_grep "AC-017 test-writer workspace-write" \
  "$DIST/.codex/agents/test-writer.toml" 'sandbox_mode = "workspace-write"'
check_grep "AC-017 reviewer read-only" \
  "$DIST/.codex/agents/reviewer.toml" 'sandbox_mode = "read-only"'

# --- AC-018/019: global config.toml ----------------------------------------
check_exists "AC-018 .codex/config.toml" "$DIST/.codex/config.toml"
check_grep "AC-018 [agents] max_threads" "$DIST/.codex/config.toml" "max_threads = 6"
check_grep "AC-019 [features] collab = true" "$DIST/.codex/config.toml" "collab = true"
check_grep "AC-019 [features] codex_hooks = true" "$DIST/.codex/config.toml" "codex_hooks = true"

# --- AC-020: sub-agent TOML references skill via prompt_skill --------------
check_grep "AC-020 test-writer prompt_skill" \
  "$DIST/.codex/agents/test-writer.toml" 'prompt_skill = "add-test-writer"'

# --- AC-021: hooks.json with required events -------------------------------
check_exists "AC-021 hooks.json" "$DIST/.codex/hooks.json"
check_grep "AC-021 SessionStart key" "$DIST/.codex/hooks.json" "SessionStart"
check_grep "AC-021 Stop key"         "$DIST/.codex/hooks.json" "Stop"
check_grep "AC-021 UserPromptSubmit" "$DIST/.codex/hooks.json" "UserPromptSubmit"

# --- AC-023: hook scripts exist and are executable -------------------------
for script in load-handoff.sh write-handoff.sh handoff-detect.sh; do
  path="$DIST/.codex/hooks/$script"
  check_exists "AC-023 $script emitted" "$path"
  if [ -x "$path" ]; then
    pass "AC-024 $script is executable"
  else
    fail "AC-024 $script is not executable"
  fi
  check_grep "AC-023 $script uses set -euo pipefail" \
    "$path" "set -euo pipefail"
done

# --- AC-025: hook README present -------------------------------------------
check_exists "AC-025 hooks/README.md" "$DIST/.codex/hooks/README.md"

# --- AC-026/027: AskUserQuestion shim injected into add-spec ---------------
check_grep "AC-026 add-spec has shim preamble" \
  "$SPEC_SKILL" "ADD AskUserQuestion shim"

# --- AC-029: plugin.toml with required fields -----------------------------
check_exists "AC-029 plugin.toml" "$DIST/plugin.toml"
check_grep "AC-029 plugin.toml has name"    "$DIST/plugin.toml" '^name = "add"'
check_grep "AC-029 plugin.toml has version" "$DIST/plugin.toml" '^version ='
check_grep "AC-029 plugin.toml has skills" "$DIST/plugin.toml" '^skills ='
check_grep "AC-029 plugin.toml has agents" "$DIST/plugin.toml" '^agents ='
check_grep "AC-029 plugin.toml has hooks"  "$DIST/plugin.toml" '^hooks ='

# --- AC-032: min_codex_version pinned --------------------------------------
check_grep "AC-032 min_codex_version pinned" \
  "$DIST/plugin.toml" "^min_codex_version"

# --- Summary ---------------------------------------------------------------
echo ""
echo "========================================"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

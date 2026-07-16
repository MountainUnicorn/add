#!/usr/bin/env bash
# test-load-rules.sh — Fixture tests for the SessionStart maturity-aware rule
# loader (hooks/load-rules.sh, v0.9.9 physical rule loading).
#
# Builds a synthetic plugin root with 4 rules (poc/beta/ga gates + one
# autoload:false) and asserts the injected set per project maturity level,
# plus the fail-open behaviors.
#
# Usage: bash tests/hooks/test-load-rules.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/runtimes/claude/hooks/load-rules.sh"

PASS=0
FAIL=0
pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- synthetic plugin root ----------------------------------------------------
mkdir -p "$TMP/plugin/rules" "$TMP/project/.add"

cat > "$TMP/plugin/rules/base-rule.md" <<'EOF'
---
autoload: true
maturity: poc
---
# Rule: Base
BASE-RULE-BODY
EOF

cat > "$TMP/plugin/rules/beta-rule.md" <<'EOF'
---
autoload: true
maturity: beta
---
# Rule: Beta
BETA-RULE-BODY
EOF

cat > "$TMP/plugin/rules/ga-rule.md" <<'EOF'
---
autoload: true
maturity: ga
---
# Rule: GA
GA-RULE-BODY
EOF

cat > "$TMP/plugin/rules/ondemand-rule.md" <<'EOF'
---
autoload: false
maturity: poc
---
# Rule: OnDemand
ONDEMAND-RULE-BODY
EOF

run_hook() { # $1 = project dir
  (cd "$1" && CLAUDE_PLUGIN_ROOT="$TMP/plugin" bash "$HOOK")
}

# --- 1. poc project: only poc rule body injected -------------------------------
printf '{"maturity":{"level":"poc"}}' > "$TMP/project/.add/config.json"
OUT=$(run_hook "$TMP/project")
if echo "$OUT" | grep -q 'BASE-RULE-BODY' && \
   ! echo "$OUT" | grep -q 'BETA-RULE-BODY' && \
   ! echo "$OUT" | grep -q 'GA-RULE-BODY'; then
  pass "poc project loads only poc-gated rules"
else
  fail "poc project loaded the wrong rule set"
fi
if echo "$OUT" | grep -q 'Dormant rules.*beta-rule (beta) ga-rule (ga)'; then
  pass "poc project lists dormant rules by name + gate"
else
  fail "poc dormant-rule listing missing or wrong"
fi

# --- 2. beta project: poc + beta, not ga ---------------------------------------
printf '{"maturity":{"level":"beta"}}' > "$TMP/project/.add/config.json"
OUT=$(run_hook "$TMP/project")
if echo "$OUT" | grep -q 'BASE-RULE-BODY' && \
   echo "$OUT" | grep -q 'BETA-RULE-BODY' && \
   ! echo "$OUT" | grep -q 'GA-RULE-BODY'; then
  pass "beta project loads poc+alpha+beta rules, not ga"
else
  fail "beta project loaded the wrong rule set"
fi

# --- 3. ga project: everything autoloadable ------------------------------------
printf '{"maturity":{"level":"ga"}}' > "$TMP/project/.add/config.json"
OUT=$(run_hook "$TMP/project")
if echo "$OUT" | grep -q 'BASE-RULE-BODY' && \
   echo "$OUT" | grep -q 'BETA-RULE-BODY' && \
   echo "$OUT" | grep -q 'GA-RULE-BODY'; then
  pass "ga project loads the full autoload set"
else
  fail "ga project loaded the wrong rule set"
fi

# --- 4. autoload:false never injected, listed on-demand ------------------------
if ! echo "$OUT" | grep -q 'ONDEMAND-RULE-BODY' && \
   echo "$OUT" | grep -q 'On-demand rules.*ondemand-rule'; then
  pass "autoload:false rule never injected; listed as on-demand"
else
  fail "autoload:false rule handling broken"
fi

# --- 5. no config: fail-open to full set ---------------------------------------
rm "$TMP/project/.add/config.json"
OUT=$(run_hook "$TMP/project")
if echo "$OUT" | grep -q 'BASE-RULE-BODY' && \
   echo "$OUT" | grep -q 'GA-RULE-BODY' && \
   echo "$OUT" | grep -q 'project maturity: all'; then
  pass "missing config fails open to the full rule set"
else
  fail "missing-config fail-open broken"
fi

# --- 6. malformed config: fail-open --------------------------------------------
printf 'NOT JSON' > "$TMP/project/.add/config.json"
OUT=$(run_hook "$TMP/project")
if echo "$OUT" | grep -q 'GA-RULE-BODY'; then
  pass "malformed config fails open to the full rule set"
else
  fail "malformed-config fail-open broken"
fi

# --- 7. frontmatter is stripped from injected bodies ----------------------------
printf '{"maturity":{"level":"poc"}}' > "$TMP/project/.add/config.json"
OUT=$(run_hook "$TMP/project")
if ! echo "$OUT" | grep -q 'autoload: true'; then
  pass "frontmatter stripped from injected rule bodies"
else
  fail "frontmatter leaked into injected context"
fi

# --- 8. stale pre-v0.9.11 rule copies in .claude/rules/ trigger a warning -------
mkdir -p "$TMP/project/.claude/rules"
cp "$TMP/plugin/rules/base-rule.md" "$TMP/project/.claude/rules/base-rule.md"
echo "user rule" > "$TMP/project/.claude/rules/my-own-rule.md"
cp "$TMP/plugin/rules/beta-rule.md" "$TMP/project/.claude/rules/add-beta-rule.md"
OUT=$(run_hook "$TMP/project")
if echo "$OUT" | grep -q 'stale ADD rule copies detected' && \
   echo "$OUT" | grep -q '.claude/rules/base-rule.md' && \
   echo "$OUT" | grep -q '.claude/rules/add-beta-rule.md' && \
   ! echo "$OUT" | grep -q 'my-own-rule'; then
  pass "stale ADD copies (plain + add- prefixed) flagged; user-authored rules ignored"
else
  fail "stale-copy detection broken"
fi

# --- 9. no .claude/rules/ dir → no warning ---------------------------------------
rm -rf "$TMP/project/.claude"
OUT=$(run_hook "$TMP/project")
if ! echo "$OUT" | grep -q 'stale ADD rule copies'; then
  pass "no warning when .claude/rules/ is absent"
else
  fail "spurious stale-copy warning"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

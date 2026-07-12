#!/usr/bin/env bash
# test-rule-parity.sh — Regression test for F-011 + PR #6 + v0.9.9 physical loading.
#
# Since v0.9.9, rules are no longer @-imported by CLAUDE.md. The SessionStart
# hook (hooks/load-rules.sh) injects rule bodies per project maturity, and the
# compiled CLAUDE.md carries a names-only index ({{RULE_INDEX}}) plus the
# on-demand list ({{ONDEMAND_RULES}}).
#
# This test asserts:
#   1. Source CLAUDE.md uses the {{RULE_INDEX}} / {{ONDEMAND_RULES}} / {{RULE_COUNT}} placeholders
#   2. Compiled CLAUDE.md indexes every autoload:true rule (and no autoload:false rule)
#   3. Every rule declares an EXPLICIT autoload: key (shared-predicate contract, v0.9.8)
#   4. load-rules.sh ships compiled and is registered as a SessionStart hook
#   5. The compiled rule count matches the real autoload population
#   6. Hand-authored prose counts in top-level docs match reality
#
# Usage: bash tests/rule-parity/test-rule-parity.sh

set -u  # do not set -e; we report findings structurally

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_CLAUDE_MD="$REPO_ROOT/runtimes/claude/CLAUDE.md"
COMPILED_CLAUDE_MD="$REPO_ROOT/plugins/add/CLAUDE.md"
RULES_DIR="$REPO_ROOT/core/rules"
COMPILED_HOOK="$REPO_ROOT/plugins/add/hooks/load-rules.sh"
COMPILED_HOOKS_JSON="$REPO_ROOT/plugins/add/hooks/hooks.json"

PASS=0
FAIL=0

pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "=== Claude rule parity check (F-011 + PR #6 + v0.9.9) ==="
echo ""

# Helper: read the `autoload:` value from a rule's YAML frontmatter.
rule_autoload_value() {
  awk '
    /^---$/ { state = (state == "in") ? "out" : "in"; next }
    state == "in" && /^autoload:/ {
      sub(/^autoload:[[:space:]]*/, "")
      print
      exit
    }
  ' "$1"
}

# ---- 1. source CLAUDE.md uses the compile placeholders ------------------------

for ph in RULE_INDEX ONDEMAND_RULES RULE_COUNT; do
  if grep -q "{{$ph}}" "$SOURCE_CLAUDE_MD"; then
    pass "source CLAUDE.md uses {{$ph}} placeholder"
  else
    fail "source CLAUDE.md is missing the {{$ph}} placeholder"
  fi
done

if [ ! -f "$COMPILED_CLAUDE_MD" ]; then
  fail "compiled CLAUDE.md not found at $COMPILED_CLAUDE_MD — run scripts/compile.py"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

# ---- 2 & 3. index reflects autoload filtering; explicit keys required ---------

missing=()
unexpected=()
keyless=()
autoload_count=0
for f in "$RULES_DIR"/*.md; do
  name=$(basename "$f" .md)
  autoload=$(rule_autoload_value "$f")

  if [ -z "$autoload" ]; then
    keyless+=("$name")
    continue
  fi

  in_index=0
  grep -qE "^- $name \([a-z]+\)$" "$COMPILED_CLAUDE_MD" && in_index=1

  if [ "$autoload" = "false" ]; then
    if [ $in_index -eq 1 ]; then
      unexpected+=("$name (autoload:false but appears in rule index)")
    fi
    # must appear in the on-demand list instead
    if ! grep -q "loaded via skill \`references:\` when needed): .*$name" "$COMPILED_CLAUDE_MD"; then
      unexpected+=("$name (autoload:false but absent from on-demand list)")
    fi
  else
    autoload_count=$((autoload_count + 1))
    if [ $in_index -eq 0 ]; then
      missing+=("$name")
    fi
  fi
done

if [ ${#keyless[@]} -eq 0 ]; then
  pass "every rule declares an explicit autoload: key (shared-predicate contract)"
else
  fail "${#keyless[@]} rule(s) missing an explicit autoload: key: ${keyless[*]}"
fi

if [ ${#missing[@]} -eq 0 ]; then
  pass "every autoload:true rule is indexed in compiled CLAUDE.md"
else
  fail "${#missing[@]} autoload:true rule(s) missing from the compiled rule index:"
  for m in "${missing[@]}"; do echo "  missing: $m"; done
fi

if [ ${#unexpected[@]} -eq 0 ]; then
  pass "autoload:false rules correctly listed on-demand only"
else
  fail "${#unexpected[@]} autoload:false placement error(s):"
  for u in "${unexpected[@]}"; do echo "  $u"; done
fi

# ---- 4. load-rules.sh ships and is registered at SessionStart ----------------

if [ -f "$COMPILED_HOOK" ] && [ -x "$COMPILED_HOOK" ]; then
  pass "load-rules.sh ships compiled and executable"
else
  fail "load-rules.sh missing or not executable at $COMPILED_HOOK"
fi

if jq -e '.hooks.SessionStart[0].hooks[0].command | test("load-rules.sh")' "$COMPILED_HOOKS_JSON" >/dev/null 2>&1; then
  pass "load-rules.sh registered as a SessionStart hook"
else
  fail "load-rules.sh not registered under SessionStart in compiled hooks.json"
fi

# ---- 5. compiled rule count matches the autoload population -------------------

declared=$(grep -oE 'Auto-loading behavioral rules \([0-9]+ files\)' "$COMPILED_CLAUDE_MD" | grep -oE '[0-9]+')

if [ -z "$declared" ]; then
  fail "compiled CLAUDE.md did not resolve {{RULE_COUNT}} to a number — run scripts/compile.py"
elif [ "$declared" = "$autoload_count" ]; then
  pass "compiled tree-diagram rule count matches reality ($declared autoloaded rules)"
else
  fail "compiled tree-diagram claims $declared rules; actual autoloaded count is $autoload_count"
fi

# ---- 6. hand-authored prose counts stay in sync with reality ------------------

for doc in CLAUDE.md README.md CONTRIBUTING.md; do
  path="$REPO_ROOT/$doc"
  [ -f "$path" ] || continue
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    if [ "$n" = "$autoload_count" ]; then
      pass "$doc rule count ($n) matches reality"
    else
      fail "$doc claims $n auto-loaded behavioral rules; actual is $autoload_count"
    fi
  done < <(grep -oiE '[0-9]+ auto-load(ed|ing) behavioral rules' "$path" | grep -oE '^[0-9]+')
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

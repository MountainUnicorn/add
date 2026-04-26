#!/usr/bin/env bash
# test-rule-parity.sh — Regression test for F-011 + PR #6 on-demand-loading parity.
#
# After PR #6, runtimes/claude/CLAUDE.md uses a `{{AUTOLOAD_RULES}}` placeholder;
# the literal `@rules/*.md` import lines are filled in by scripts/compile.py and
# only appear in the COMPILED output at plugins/add/CLAUDE.md. Rules with
# `autoload: false` frontmatter intentionally drop from the manifest (loaded
# on-demand by skills via `references:` instead).
#
# This test asserts:
#   1. The source CLAUDE.md uses the placeholder (PR #6 mechanism still in place)
#   2. The compiled CLAUDE.md contains @rules/ for every rule WITHOUT autoload:false
#   3. The compiled CLAUDE.md does NOT contain @rules/ for any rule WITH autoload:false
#   4. Every @rules/ import in the compiled file points at a real source file
#   5. The tree-diagram rule count in CLAUDE.md matches the actual file count
#
# Usage: bash tests/rule-parity/test-rule-parity.sh

set -u  # do not set -e; we report findings structurally

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_CLAUDE_MD="$REPO_ROOT/runtimes/claude/CLAUDE.md"
COMPILED_CLAUDE_MD="$REPO_ROOT/plugins/add/CLAUDE.md"
RULES_DIR="$REPO_ROOT/core/rules"

PASS=0
FAIL=0

pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "=== Claude rule parity check (F-011 + PR #6) ==="
echo ""

# Helper: read the `autoload:` value from a rule's YAML frontmatter.
# Returns "true" (or empty if the key isn't set, since true is the default).
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

# ---- 1. source CLAUDE.md uses the {{AUTOLOAD_RULES}} placeholder --------------

if grep -q "{{AUTOLOAD_RULES}}" "$SOURCE_CLAUDE_MD"; then
  pass "source CLAUDE.md uses {{AUTOLOAD_RULES}} placeholder (PR #6 mechanism intact)"
else
  fail "source CLAUDE.md is missing the {{AUTOLOAD_RULES}} placeholder"
fi

# ---- 2 & 3. compiled CLAUDE.md @rules/ list reflects autoload filtering ------

if [ ! -f "$COMPILED_CLAUDE_MD" ]; then
  fail "compiled CLAUDE.md not found at $COMPILED_CLAUDE_MD — run scripts/compile.py"
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
fi

missing=()
unexpected=()
for f in "$RULES_DIR"/*.md; do
  name=$(basename "$f")
  autoload=$(rule_autoload_value "$f")
  in_manifest=0
  grep -q "^@rules/$name\$" "$COMPILED_CLAUDE_MD" && in_manifest=1

  if [ "$autoload" = "false" ]; then
    if [ $in_manifest -eq 1 ]; then
      unexpected+=("$name (autoload:false but appears in manifest)")
    fi
  else
    if [ $in_manifest -eq 0 ]; then
      missing+=("$name")
    fi
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  pass "every autoload:true rule has an @rules/ import in compiled CLAUDE.md"
else
  fail "${#missing[@]} autoload:true rule(s) missing @rules/ import:"
  for m in "${missing[@]}"; do
    echo "  missing: @rules/$m"
  done
fi

if [ ${#unexpected[@]} -eq 0 ]; then
  pass "no autoload:false rules leaked into the compiled @rules/ manifest"
else
  fail "${#unexpected[@]} autoload:false rule(s) leaked into manifest:"
  for u in "${unexpected[@]}"; do
    echo "  unexpected: $u"
  done
fi

# ---- 4. no @rules/ import points at a nonexistent file -----------------------

orphan=()
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  path=${ref#@rules/}
  if [ ! -f "$RULES_DIR/$path" ]; then
    orphan+=("$ref")
  fi
done < <(grep -oE '^@rules/[^ ]+' "$COMPILED_CLAUDE_MD")

if [ ${#orphan[@]} -eq 0 ]; then
  pass "no @rules/ imports point at nonexistent core/rules/ files"
else
  fail "${#orphan[@]} orphan @rules/ import(s):"
  for o in "${orphan[@]}"; do
    echo "  orphan: $o"
  done
fi

# ---- 5. tree-diagram count matches actual file count -------------------------

actual=$(find "$RULES_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
declared=$(grep -oE 'Auto-loading behavioral rules \([0-9]+ files\)' "$SOURCE_CLAUDE_MD" | grep -oE '[0-9]+')

if [ -z "$declared" ]; then
  fail "could not find 'Auto-loading behavioral rules (N files)' count in CLAUDE.md"
elif [ "$declared" = "$actual" ]; then
  pass "tree-diagram rule count matches reality ($declared files)"
else
  fail "tree-diagram claims $declared rule files; actual count is $actual"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]

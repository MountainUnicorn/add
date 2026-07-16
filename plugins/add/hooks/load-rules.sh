#!/usr/bin/env bash
# load-rules.sh — SessionStart hook: maturity-aware physical rule loading (v0.9.9).
#
# Before v0.9.9, all rules were statically @-imported by CLAUDE.md, so a POC
# project paid ~13k tokens every session for rules the maturity-loader told the
# agent to ignore (behavioral suppression, zero token savings). This hook makes
# the maturity dial physical: it reads `.add/config.json` → `maturity.level`
# and injects ONLY the rules whose `maturity:` gate is at or below the project
# level. Rules with `autoload: false` are never injected (loaded on demand via
# skill `references:`).
#
# Fail-open to FULL load (behavior parity with the old @import mechanism):
#   - no .add/config.json (not an ADD project, or /add:init pending)
#   - unparseable config / missing or invalid maturity.level
#   - jq unavailable
# A rule with no `maturity:` key is treated as poc (always active).
#
# Output goes to stdout → added to session context by Claude Code.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RULES_DIR="$PLUGIN_ROOT/rules"
[ -d "$RULES_DIR" ] || exit 0

LEVEL="all"
if [ -f ".add/config.json" ] && command -v jq >/dev/null 2>&1; then
  L=$(jq -r '.maturity.level // empty' .add/config.json 2>/dev/null || true)
  case "$L" in poc|alpha|beta|ga) LEVEL="$L" ;; esac
fi

rank() {
  case "$1" in
    poc) echo 0 ;;
    alpha) echo 1 ;;
    beta) echo 2 ;;
    ga|all) echo 3 ;;
    *) echo 0 ;;
  esac
}
PROJECT_RANK=$(rank "$LEVEL")

# Read a frontmatter key's value from a rule file (first frontmatter block only).
fm_value() { # $1=file $2=key
  awk -v key="$2" '
    NR==1 && $0 != "---" { exit }
    NR>1 && $0 == "---" { exit }
    NR>1 && index($0, key ":") == 1 {
      sub("^" key ":[[:space:]]*", "")
      gsub(/"/, "")
      print
      exit
    }
  ' "$1"
}

# Emit a rule body without its frontmatter block.
emit_body() { # $1=file
  awk '
    NR==1 && $0 == "---" { fm = 1; next }
    fm == 1 && $0 == "---" { fm = 2; next }
    fm != 1 { print }
  ' "$1"
}

ACTIVE_FILES=()
DORMANT=()
ONDEMAND=()

for f in "$RULES_DIR"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  autoload=$(fm_value "$f" "autoload")
  if [ "$autoload" = "false" ]; then
    ONDEMAND+=("$name")
    continue
  fi
  gate=$(fm_value "$f" "maturity")
  [ -n "$gate" ] || gate="poc"
  if [ "$(rank "$gate")" -le "$PROJECT_RANK" ]; then
    ACTIVE_FILES+=("$f")
  else
    DORMANT+=("$name ($gate)")
  fi
done

echo "# ADD Rules (project maturity: $LEVEL)"
echo ""
echo "The behavioral rules below are ACTIVE for this project's maturity level."
echo "They were injected by the ADD SessionStart hook (maturity-aware physical"
echo "rule loading) — follow them for the entire session."
echo ""

for f in "${ACTIVE_FILES[@]:-}"; do
  [ -n "$f" ] || continue
  echo "---"
  emit_body "$f"
  echo ""
done

if [ ${#DORMANT[@]} -gt 0 ]; then
  echo "---"
  echo "Dormant rules (maturity gate above $LEVEL — NOT loaded; activate via /add:promote): ${DORMANT[*]}"
fi
if [ ${#ONDEMAND[@]} -gt 0 ]; then
  echo "On-demand rules (autoload:false — loaded via skill \`references:\` when needed): ${ONDEMAND[*]}"
fi

# Stale-copy detection: ADD versions before v0.9.11 copied rules into the
# project's .claude/rules/, where Claude Code still auto-loads them. Those
# copies drift and duplicate (or contradict) the fresh bodies injected above.
STALE=()
if [ -d ".claude/rules" ]; then
  for pf in "$RULES_DIR"/*.md; do
    [ -f "$pf" ] || continue
    base=$(basename "$pf")
    [ -f ".claude/rules/$base" ] && STALE+=(".claude/rules/$base")
    [ -f ".claude/rules/add-$base" ] && STALE+=(".claude/rules/add-$base")
  done
fi
if [ ${#STALE[@]} -gt 0 ]; then
  echo ""
  echo "WARNING: stale ADD rule copies detected (from an ADD version before"
  echo "v0.9.11 that copied rules at init): ${STALE[*]}"
  echo "These auto-load alongside the fresh rules injected above and will"
  echo "contradict them as they drift. The injected versions are canonical —"
  echo "recommend deleting the copies (offer this to the user once)."
fi

exit 0

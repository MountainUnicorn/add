#!/usr/bin/env bash
# filter-learnings.sh — Generate compact pre-filtered view of learnings
#
# Reads a learnings JSON file and produces a small "-active.md" companion
# containing the top entries sorted by severity and recency, plus a compact
# index of all remaining entries so agents can spot relevant ones.
#
# Usage: filter-learnings.sh <path-to-learnings.json> [max-entries]
# Example: filter-learnings.sh .add/learnings.json 15

set -euo pipefail

LEARNINGS_JSON="${1:-}"
MAX_ENTRIES="${2:-15}"

[ -n "$LEARNINGS_JSON" ] && [ -f "$LEARNINGS_JSON" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

ACTIVE_MD="${LEARNINGS_JSON%.json}-active.md"

TOTAL=$(jq '.entries | length' "$LEARNINGS_JSON" 2>/dev/null) || exit 0
[ "$TOTAL" -eq 0 ] && {
  cat > "$ACTIVE_MD" << 'EOF'
# Active Learnings (0 entries)

No learnings recorded yet.
EOF
  exit 0
}

# Sort by severity desc (critical>high>medium>low), then date desc.
# Exclude archived entries. Cap at MAX_ENTRIES.
SORTED=$(jq -r --argjson max "$MAX_ENTRIES" '
  def sev: if . == "critical" then 4 elif . == "high" then 3 elif . == "medium" then 2 else 1 end;
  .entries
  | map(select(.archived != true))
  | map(. + {_r: (.severity | sev)})
  | sort_by([._r, .date]) | reverse
  | {top: .[:$max], rest: .[$max:]}
' "$LEARNINGS_JSON" 2>/dev/null) || exit 0

# Top entries — full detail, grouped by category
BODY=$(echo "$SORTED" | jq -r '
  def sev: if . == "critical" then 4 elif . == "high" then 3 elif . == "medium" then 2 else 1 end;
  .top
  | group_by(.category)
  | sort_by(-(.[0].severity | sev))
  | .[]
  | "### \(.[0].category)\n" + ([.[] | "- **[\(.severity)]** \(.title) (\(.id), \(.date))\n  \(.body)"] | join("\n"))
' 2>/dev/null) || exit 0

# Remaining entries — compact one-line index
REST=$(echo "$SORTED" | jq -r '
  .rest[]
  | "- [\(.severity)] \(.id) \(.category): \(.title) (\(.date))"
' 2>/dev/null)

ACTIVE=$(echo "$SORTED" | jq '.top | length' 2>/dev/null)
REST_COUNT=$(echo "$SORTED" | jq '.rest | length' 2>/dev/null)
ARCHIVED=$(jq '.entries | map(select(.archived == true)) | length' "$LEARNINGS_JSON" 2>/dev/null)

{
  echo "# Active Learnings (${ACTIVE} of ${TOTAL})"
  echo ""
  echo "> Pre-filtered by severity and date. Full data: \`.add/learnings.json\`${ARCHIVED:+$( [ "$ARCHIVED" -gt 0 ] && echo " ($ARCHIVED archived)" || true)}"
  echo ""
  echo "$BODY"
  if [ -n "$REST" ] && [ "$REST_COUNT" -gt 0 ]; then
    echo ""
    echo "## Index (${REST_COUNT} more — title only, read JSON for full detail)"
    echo ""
    echo "$REST"
  fi
  echo ""
  echo "---"
  echo "*Auto-generated. Do not edit — regenerated on each learning write.*"
} > "$ACTIVE_MD"

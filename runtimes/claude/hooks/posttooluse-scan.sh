#!/usr/bin/env bash
# posttooluse-scan.sh — PostToolUse prompt-injection scanner for ADD.
#
# Reads the PostToolUse hook JSON payload from stdin, greps the tool's output
# against a catalog of injection patterns, and:
#   - Emits a structured ADD-SEC warning to stderr (surfaced to agent next turn)
#   - Appends an audit event to .add/security/injection-events.jsonl
#
# Warn-only: this hook never blocks tool execution. Exit code is always 0
# (except under set -e on truly unexpected errors, which we defend against).
#
# Registered in runtimes/claude/hooks/hooks.json for PostToolUse on Read,
# WebFetch, WebSearch, and Bash. See specs/prompt-injection-defense.md.

set -uo pipefail

# --- Early exits ------------------------------------------------------------

# No .add/ → ADD not initialized in this project → no-op
[ -d ".add" ] || exit 0

# Need jq to parse the hook payload
command -v jq >/dev/null 2>&1 || exit 0

# --- Read stdin payload -----------------------------------------------------

PAYLOAD=$(cat || true)
[ -n "$PAYLOAD" ] || exit 0

TOOL=$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
[ -n "$TOOL" ] || exit 0

# Extract tool output content from the several shapes Claude Code uses.
# We concatenate everything text-like we find so we don't miss content.
CONTENT=$(printf '%s' "$PAYLOAD" | jq -r '
  [
    (.tool_response.output // empty),
    (.tool_response.content // empty),
    (.tool_response.results // empty),
    (.tool_response.file.content // empty),
    (.tool_response.stdout // empty),
    (.tool_response.stderr // empty)
  ] | map(select(. != null and . != "")) | join("\n")
' 2>/dev/null || echo "")

[ -n "$CONTENT" ] || exit 0

# Derive a source qualifier for the audit log
SOURCE=$(printf '%s' "$PAYLOAD" | jq -r '
  .tool_response.source //
  .tool_input.file_path //
  .tool_input.url //
  .tool_input.query //
  .tool_input.command //
  empty
' 2>/dev/null || echo "")
[ -n "$SOURCE" ] || SOURCE="(unknown)"

# --- Self-recursion guard ---------------------------------------------------

# Never scan reads of our own audit log (would always self-trigger)
case "$SOURCE" in
  *.add/security/injection-events.jsonl*|*.add/security/hook-errors.log*)
    exit 0
    ;;
esac

# --- Size cap ---------------------------------------------------------------

MAX_BYTES=$((10 * 1024 * 1024))  # 10 MB
TRUNCATED="false"
CONTENT_LEN=${#CONTENT}
if [ "$CONTENT_LEN" -gt "$MAX_BYTES" ]; then
  CONTENT=${CONTENT:0:$MAX_BYTES}
  TRUNCATED="true"
fi

# --- Binary/non-UTF-8 detection --------------------------------------------

# If the content has NUL bytes, it's almost certainly not text. Skip scanning
# but record the skip as an audit event (per spec § Edge Cases).
BINARY="false"
TMPC=$(mktemp 2>/dev/null) || exit 0
trap 'rm -f "$TMPC"' EXIT
printf '%s' "$CONTENT" > "$TMPC"
# Detect NUL byte by scanning raw bytes with od. POSIX-portable and unambiguous.
if LC_ALL=C od -An -tu1 -N 65536 "$TMPC" 2>/dev/null | tr -s ' \n' ' ' | grep -qE '(^| )0( |$)'; then
  BINARY="true"
fi

# --- Load pattern catalog ---------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Candidate catalog locations. Project wins over user-local wins over default.
# The default ships with the plugin; CLAUDE_PLUGIN_ROOT points at its install.
DEFAULT_CATALOG=""
for cand in \
  "${CLAUDE_PLUGIN_ROOT:-}/security/patterns.json" \
  "$SCRIPT_DIR/../../../core/security/patterns.json" \
  "$SCRIPT_DIR/../security/patterns.json" \
  "$SCRIPT_DIR/../../security/patterns.json"
do
  [ -n "$cand" ] && [ -f "$cand" ] && { DEFAULT_CATALOG="$cand"; break; }
done

USER_CATALOG="$HOME/.claude/add/security/patterns.json"
PROJ_CATALOG=".add/security/patterns.json"

# Merge catalogs: later sources override earlier by name.
MERGED=$(jq -n \
  --arg def "${DEFAULT_CATALOG:-}" \
  --arg usr "$USER_CATALOG" \
  --arg prj "$PROJ_CATALOG" '
    def load(p): if p != "" and (p | . ) != null and (try (p | $ENV | .) catch null) == null
      then null else null end;
    # Simple load: read file if exists, else empty patterns
    [] ' 2>/dev/null || echo '[]')

# jq cannot read files by path from inside, so assemble in bash:
load_patterns() {
  local path="$1"
  [ -n "$path" ] && [ -f "$path" ] || { echo '[]'; return; }
  jq -c '.patterns // []' "$path" 2>/dev/null || echo '[]'
}

DEF_P=$(load_patterns "${DEFAULT_CATALOG:-}")
USR_P=$(load_patterns "$USER_CATALOG")
PRJ_P=$(load_patterns "$PROJ_CATALOG")

# Merge: project > user > default, by pattern name, enabled != false.
MERGED_PATTERNS=$(jq -n \
  --argjson def "$DEF_P" \
  --argjson usr "$USR_P" \
  --argjson prj "$PRJ_P" '
    ($def + $usr + $prj)
    | group_by(.name)
    | map(.[-1])
    | map(select(.enabled != false))
  ' 2>/dev/null || echo '[]')

PATTERN_COUNT=$(printf '%s' "$MERGED_PATTERNS" | jq 'length' 2>/dev/null || echo 0)
[ "$PATTERN_COUNT" -gt 0 ] || exit 0

# --- Ensure .add/security/ exists -------------------------------------------

mkdir -p .add/security 2>/dev/null || exit 0
AUDIT_LOG=".add/security/injection-events.jsonl"
ERROR_LOG=".add/security/hook-errors.log"

# --- Helpers ---------------------------------------------------------------

# Redact apparent secrets in an excerpt before writing it to the audit log.
redact() {
  local s="$1"
  # Replace common secret-ish tokens with <REDACTED>
  printf '%s' "$s" | sed -E \
    -e 's/(sk-[A-Za-z0-9_-]{10,})/<REDACTED>/g' \
    -e 's/(ghp_[A-Za-z0-9]{20,})/<REDACTED>/g' \
    -e 's/(AKIA[A-Z0-9]{16})/<REDACTED>/g' \
    -e 's/(AIza[A-Za-z0-9_-]{20,})/<REDACTED>/g' \
    -e 's/(eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,})/<REDACTED>/g'
}

iso_now() {
  # UTC ISO 8601. BSD date on macOS doesn't support %:z; use -u + Z.
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Strip PCRE-ish prefix flags (?i) and (?m). Returns the flag-free regex on
# stdout. If case-insensitive was requested, prepends a single 'i\t' prefix so
# the caller can detect it without shell-read ambiguity on empty first fields.
normalize_regex() {
  local re="$1"
  local case_flag="-"
  while :; do
    case "$re" in
      '(?i)'*) case_flag="i"; re=${re#'(?i)'} ;;
      '(?m)'*) re=${re#'(?m)'} ;;  # multiline — grep is line-based anyway
      *) break ;;
    esac
  done
  # Always emit the flag (never empty), then a tab, then the regex. Since the
  # flag is either '-' or 'i' (never empty), read -r with IFS=$'\t' works.
  printf '%s\t%s' "$case_flag" "$re"
}

# --- Binary short-circuit ---------------------------------------------------

if [ "$BINARY" = "true" ]; then
  event=$(jq -n \
    --arg ts "$(iso_now)" \
    --arg tool "$TOOL" \
    --arg source "$SOURCE" \
    --arg runtime "claude" \
    '{timestamp:$ts,tool:$tool,source:$source,pattern:null,severity:"info",excerpt:"",skipped:"binary",runtime:$runtime}')
  echo "$event" >> "$AUDIT_LOG" 2>/dev/null || true
  exit 0
fi

# --- Scan loop --------------------------------------------------------------

# Content is already at $TMPC from binary-detection step.
HITS=0

# Iterate patterns. @tsv re-escapes backslashes which breaks regexes, so we
# emit one field per line with a record separator and reassemble in bash.
PATTERN_FILE=$(mktemp)
printf '%s' "$MERGED_PATTERNS" | jq -r '.[] | .name, .regex, .severity, .description, "===END==="' > "$PATTERN_FILE" 2>/dev/null

while IFS= read -r NAME; do
  [ "$NAME" = "===END===" ] && continue
  [ -n "$NAME" ] || continue
  IFS= read -r REGEX
  IFS= read -r SEVERITY
  IFS= read -r DESCRIPTION
  IFS= read -r END_MARK
  [ "$END_MARK" = "===END===" ] || continue

  IFS=$'\t' read -r CASE_FLAG ERE <<< "$(normalize_regex "$REGEX")"

  # Patterns with hex byte escapes (\xXX) aren't supported by POSIX grep — use
  # Python's re module, operating on raw bytes. Currently only unicode-tag-block
  # uses this, but the dispatch is generic.
  MATCH_LINE=""
  MATCH_COUNT=0
  if printf '%s' "$ERE" | grep -q '\\x'; then
    if command -v python3 >/dev/null 2>&1; then
      # Python: decode \xHH as bytes, match on raw file bytes, report count + first match.
      PY_OUT=$(python3 - "$ERE" "$TMPC" <<'PYEOF' 2>/dev/null || true
import re, sys
pat = sys.argv[1].encode('utf-8').decode('unicode_escape').encode('latin1')
data = open(sys.argv[2], 'rb').read()
try:
    cre = re.compile(pat, re.DOTALL)
except re.error:
    sys.exit(0)
matches = list(cre.finditer(data))
if not matches:
    sys.exit(0)
# Emit: COUNT \x1f EXCERPT_BYTES (no trailing newline, no reordering).
out = sys.stdout.buffer
out.write(str(len(matches)).encode('ascii'))
out.write(b'\x1f')
start, end = matches[0].span()
excerpt = data[start:end][:200].replace(b'\n', b' ')
out.write(excerpt)
out.flush()
PYEOF
)
      if [ -n "$PY_OUT" ]; then
        MATCH_COUNT=$(printf '%s' "$PY_OUT" | awk -F$'\x1f' '{print $1}' | head -1)
        MATCH_LINE=$(printf '%s' "$PY_OUT" | awk -F$'\x1f' 'NF>1 {for (i=2; i<=NF; i++) printf "%s%s", $i, (i<NF?FS:""); }')
        MATCH_COUNT=${MATCH_COUNT:-0}
      fi
    fi
  else
    # Count matches and get a sample line. grep -c always prints a count and
    # exits 1 on zero matches — don't OR-echo or we append a spurious line.
    if [ "$CASE_FLAG" = "i" ]; then
      MATCH_LINE=$(grep -E -i -o -m1 -- "$ERE" "$TMPC" 2>/dev/null || true)
      MATCH_COUNT=$(grep -E -i -c -- "$ERE" "$TMPC" 2>/dev/null; true)
    else
      MATCH_LINE=$(grep -E -o -m1 -- "$ERE" "$TMPC" 2>/dev/null || true)
      MATCH_COUNT=$(grep -E -c -- "$ERE" "$TMPC" 2>/dev/null; true)
    fi
    MATCH_COUNT=${MATCH_COUNT:-0}
  fi

  [ -n "$MATCH_LINE" ] || continue
  [ "$MATCH_COUNT" -gt 0 ] 2>/dev/null || continue

  HITS=$((HITS + 1))

  # Build an excerpt: 200 chars of context around the first match
  EXCERPT_RAW=$(grep -E ${CASE_FLAG:+-i} -m1 -- "$ERE" "$TMPC" 2>/dev/null | head -c 200 || true)
  [ -n "$EXCERPT_RAW" ] || EXCERPT_RAW="$MATCH_LINE"
  EXCERPT=$(redact "$EXCERPT_RAW")

  # Emit agent-facing warning
  printf 'ADD-SEC: pattern=%s severity=%s source=%s:%s action=warn\n' \
    "$NAME" "$SEVERITY" "$TOOL" "$SOURCE" >&2

  # Append audit event
  EVENT=$(jq -n \
    --arg ts "$(iso_now)" \
    --arg tool "$TOOL" \
    --arg source "${TOOL}:${SOURCE}" \
    --arg pattern "$NAME" \
    --arg severity "$SEVERITY" \
    --arg excerpt "$EXCERPT" \
    --arg runtime "claude" \
    --argjson match_count "${MATCH_COUNT:-1}" \
    --arg truncated "$TRUNCATED" \
    '{timestamp:$ts,tool:$tool,source:$source,pattern:$pattern,severity:$severity,excerpt:$excerpt,match_count:$match_count,runtime:$runtime}
     + (if $truncated == "true" then {truncated:true} else {} end)') 2>/dev/null || continue

  echo "$EVENT" >> "$AUDIT_LOG" 2>/dev/null || true

done < "$PATTERN_FILE"
rm -f "$PATTERN_FILE"

# Always succeed — warn-only posture.
exit 0

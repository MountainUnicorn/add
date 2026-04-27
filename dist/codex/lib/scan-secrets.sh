#!/usr/bin/env bash
# scan-secrets.sh — Executable secrets scanner for staged content.
#
# Implements specs/secrets-scanner-executable.md (F-014). This is the single
# point of truth for "does this commit contain a secret?" Skills, hooks, and
# CI all delegate to this script.
#
# Reads the regex catalog at core/security/secret-patterns.json (or a
# --catalog override) using a small awk extractor — no jq dependency in the
# hot path. Scans `git diff --cached` content (or --paths/--all) against each
# pattern, respects .secretsignore, honors a [ADD-SECRET-OVERRIDE: SEC-NNN]
# commit-message trailer, redacts every preview, and exits non-zero on any
# unsuppressed match.
#
# Usage:
#   core/lib/scan-secrets.sh [OPTIONS]
#
# Options:
#   --paths FILE...           Scan listed files instead of git diff --cached
#   --all                     Scan the entire working tree (audit-only, slow)
#   --commit-msg-file PATH    Read trailer override from commit message file
#   --allow REASON            Inline override (must include SEC-NNN codes)
#   --audit-log PATH          Append JSONL findings to PATH (redacted)
#   --max-bytes N             Per-file scan size cap in bytes (default 5242880)
#   --catalog PATH            Override path to secret-patterns.json
#   --verbose                 Print scan progress to stderr (no secret values)
#   -h, --help                Print usage
#
# Exit codes:
#   0  — clean (no unsuppressed findings)
#   1  — at least one unsuppressed finding (caller must block)
#   2  — invocation error (bad flag, missing file with --paths)
#   3  — configuration error (catalog missing or unparseable)

# NOTE: intentionally NOT using `set -e`. The script has explicit exit-code
# semantics (0=clean, 1=finding, 2=invocation-error, 3=config-error) managed
# by its own logic. With -e enabled, common patterns like `[ -s "$X" ] && grep`
# fired set-e on Linux bash 5+ when the test failed (a perfectly valid empty-set
# case), producing spurious exit 1 in CI even when no findings existed. -u
# (unbound-variable) and pipefail are kept; explicit `if/exit N` blocks the
# script's own error paths.
set -uo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

PATHS_MODE=""
ALL_MODE=0
COMMIT_MSG_FILE=""
INLINE_ALLOW=""
AUDIT_LOG=""
MAX_BYTES=5242880
VERBOSE=0
CATALOG_OVERRIDE=""
declare -a EXPLICIT_PATHS=()

print_help() {
  sed -n '2,/^$/p' "$0" | sed -n '/^# Usage:/,/^# Exit codes:/p' | sed 's/^# //; s/^#//'
  cat <<'HELP_TAIL'
Exit codes:
  0  — clean (no unsuppressed findings)
  1  — at least one unsuppressed finding (caller must block)
  2  — invocation error
  3  — configuration error (catalog missing or unparseable)
HELP_TAIL
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while [ "$#" -gt 0 ]; do
  case "$1" in
    --paths)
      PATHS_MODE=1
      shift
      while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do
        EXPLICIT_PATHS+=("$1")
        shift
      done
      ;;
    --all)
      ALL_MODE=1
      shift
      ;;
    --commit-msg-file)
      COMMIT_MSG_FILE="${2:-}"
      shift 2
      ;;
    --allow)
      INLINE_ALLOW="${2:-}"
      shift 2
      ;;
    --audit-log)
      AUDIT_LOG="${2:-}"
      shift 2
      ;;
    --max-bytes)
      MAX_BYTES="${2:-}"
      shift 2
      ;;
    --catalog)
      CATALOG_OVERRIDE="${2:-}"
      shift 2
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "scan-secrets: unknown option: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Locate the catalog
# ---------------------------------------------------------------------------

resolve_catalog() {
  if [ -n "$CATALOG_OVERRIDE" ]; then
    echo "$CATALOG_OVERRIDE"
    return
  fi
  # Prefer ${CLAUDE_PLUGIN_ROOT}/security/secret-patterns.json when set
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && \
     [ -f "$CLAUDE_PLUGIN_ROOT/security/secret-patterns.json" ]; then
    echo "$CLAUDE_PLUGIN_ROOT/security/secret-patterns.json"
    return
  fi
  # Fallback: relative to this script (core/lib/ → core/security/)
  local self_dir
  self_dir="$(cd "$(dirname "$0")" && pwd)"
  local candidate="$self_dir/../security/secret-patterns.json"
  if [ -f "$candidate" ]; then
    # canonicalize
    (cd "$(dirname "$candidate")" && printf '%s/%s\n' "$(pwd)" "$(basename "$candidate")")
    return
  fi
  echo ""
}

CATALOG=$(resolve_catalog)
if [ -z "$CATALOG" ] || [ ! -f "$CATALOG" ]; then
  echo "scan-secrets: cannot read pattern catalog at ${CATALOG:-<unresolved>}; aborting" >&2
  exit 3
fi

# ---------------------------------------------------------------------------
# Catalog parser — pure awk, no jq.
# Emits records: code|name|regex|confidence (one per line, stdout).
# Tolerates pretty-printed multi-line JSON; relies on "key": "value" lines.
# ---------------------------------------------------------------------------

parse_catalog() {
  # Emit one line per pattern, fields separated by tab characters. Tab is
  # safer than '|' because some regexes use alternation. Format:
  #   code\tname\tregex\tconfidence
  awk -v TAB="$(printf '\t')" '
    BEGIN { in_obj = 0; code=""; name=""; regex=""; conf=""; }
    /^[[:space:]]*\{[[:space:]]*$/ {
      in_obj = 1; code=""; name=""; regex=""; conf=""; next
    }
    /^[[:space:]]*\}/ {
      if (in_obj && code != "" && name != "" && regex != "") {
        printf "%s%s%s%s%s%s%s\n", code, TAB, name, TAB, regex, TAB, conf
      }
      in_obj = 0; next
    }
    in_obj == 1 {
      if (match($0, /"code"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr($0, RSTART, RLENGTH)
        sub(/^"code"[[:space:]]*:[[:space:]]*"/, "", s); sub(/"$/, "", s)
        code = s
      }
      if (match($0, /"name"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr($0, RSTART, RLENGTH)
        sub(/^"name"[[:space:]]*:[[:space:]]*"/, "", s); sub(/"$/, "", s)
        name = s
      }
      if (match($0, /"regex"[[:space:]]*:[[:space:]]*".*"/)) {
        s = substr($0, RSTART, RLENGTH)
        sub(/^"regex"[[:space:]]*:[[:space:]]*"/, "", s); sub(/"$/, "", s)
        # Unescape JSON \\ -> \ and \" -> "
        gsub(/\\\\/, "\\", s)
        gsub(/\\"/, "\"", s)
        regex = s
      }
      if (match($0, /"confidence"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        s = substr($0, RSTART, RLENGTH)
        sub(/^"confidence"[[:space:]]*:[[:space:]]*"/, "", s); sub(/"$/, "", s)
        conf = s
      }
    }
  ' "$CATALOG"
}

CATALOG_LINES=$(parse_catalog)
if [ -z "$CATALOG_LINES" ]; then
  echo "scan-secrets: catalog at $CATALOG is empty or unparseable" >&2
  exit 3
fi

# ---------------------------------------------------------------------------
# Trailer override parser. Given a commit-message file (or inline string),
# extract every SEC-NNN code listed inside [ADD-SECRET-OVERRIDE: ...].
#
# A bare trailer with no SEC code returns the sentinel "BARE" — caller handles.
# ---------------------------------------------------------------------------

OVERRIDE_CODES=""
TRAILER_BARE=0
TRAILER_PRESENT=0

extract_trailer() {
  local source="$1"
  local body=""
  if [ "$source" = "FILE" ]; then
    [ -f "$COMMIT_MSG_FILE" ] || return
    body=$(cat "$COMMIT_MSG_FILE")
  else
    body="$INLINE_ALLOW"
  fi
  # Find lines containing the trailer marker.
  local trailer
  trailer=$(printf '%s\n' "$body" | grep -E '\[ADD-SECRET-OVERRIDE:[^]]*\]' || true)
  [ -z "$trailer" ] && return
  TRAILER_PRESENT=1
  # Extract content between the markers.
  local content
  content=$(printf '%s\n' "$trailer" | sed -E 's/.*\[ADD-SECRET-OVERRIDE:[[:space:]]*([^]]*)\].*/\1/')
  # Pull out SEC-NNN tokens.
  local codes
  codes=$(printf '%s\n' "$content" | grep -oE 'SEC-[0-9]+' | sort -u | tr '\n' ' ' || true)
  if [ -z "$codes" ]; then
    TRAILER_BARE=1
  else
    OVERRIDE_CODES="$codes"
  fi
}

if [ -n "$COMMIT_MSG_FILE" ]; then
  extract_trailer FILE
elif [ -n "$INLINE_ALLOW" ]; then
  extract_trailer INLINE
fi

# ---------------------------------------------------------------------------
# Resolve target file list.
# ---------------------------------------------------------------------------

declare -a TARGETS=()

if [ -n "$PATHS_MODE" ] && [ "${#EXPLICIT_PATHS[@]}" -gt 0 ]; then
  for p in "${EXPLICIT_PATHS[@]}"; do
    if [ -e "$p" ]; then
      TARGETS+=("$p")
    else
      echo "scan-secrets: --paths target not found: $p" >&2
      exit 2
    fi
  done
elif [ "$ALL_MODE" = "1" ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "error: git not available or not a repository" >&2
    exit 2
  fi
  while IFS= read -r f; do
    [ -n "$f" ] && TARGETS+=("$f")
  done < <(git ls-files 2>/dev/null || true)
else
  if ! command -v git >/dev/null 2>&1; then
    echo "error: git not available or not a repository" >&2
    exit 2
  fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: git not available or not a repository" >&2
    exit 2
  fi
  while IFS= read -r f; do
    [ -n "$f" ] && TARGETS+=("$f")
  done < <(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  [ "$VERBOSE" = "1" ] && echo "info: no staged changes" >&2
  exit 0
fi

# Pre-compute the binary and text sets in one git call. `git diff --cached
# --numstat` returns "-\t-\t<path>" for binaries and "N\tM\t<path>" for text.
# Caching this dispenses with per-file invocations of `git diff --numstat`
# AND the perl/grep NUL-byte probe in is_binary().
BINARY_SET_FILE=$(mktemp)
TEXT_SET_FILE=$(mktemp)
DIRTY_SET_FILE=$(mktemp)
trap 'rm -f "$COMBINED_PATTERN_FILE" "$BINARY_SET_FILE" "$TEXT_SET_FILE" "$DIRTY_SET_FILE"' EXIT
if [ -z "$PATHS_MODE" ] && [ "$ALL_MODE" != "1" ]; then
  git diff --cached --numstat 2>/dev/null \
    | awk -F'\t' '
        $1 == "-" && $2 == "-" { print $3 > "/dev/stderr"; next }
        { print $3 }
      ' 2> "$BINARY_SET_FILE" > "$TEXT_SET_FILE" || :
  # Files with unstaged modifications (working tree differs from index).
  git diff --name-only 2>/dev/null > "$DIRTY_SET_FILE" || :
fi

is_binary_cached() {
  local f="$1"
  if [ -s "$BINARY_SET_FILE" ] && grep -qxF -- "$f" "$BINARY_SET_FILE"; then
    return 0
  fi
  if [ -s "$TEXT_SET_FILE" ] && grep -qxF -- "$f" "$TEXT_SET_FILE"; then
    return 1
  fi
  is_binary "$f"
}

is_dirty_cached() {
  local f="$1"
  [ -s "$DIRTY_SET_FILE" ] && grep -qxF -- "$f" "$DIRTY_SET_FILE"
}

# ---------------------------------------------------------------------------
# .secretsignore loader. Match a path against gitignore-style patterns.
# Implementation is deliberately literal — supports trailing /, *.ext globs,
# and dir/* prefixes. Negations (!pattern) are recognised but not enforced
# (out of scope for v0.9.x; documented).
# ---------------------------------------------------------------------------

declare -a IGNORE_PATTERNS=()
SECRETSIGNORE_FILE=""
if [ -f ".secretsignore" ]; then
  SECRETSIGNORE_FILE=".secretsignore"
elif [ -f "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.secretsignore" ]; then
  SECRETSIGNORE_FILE="$(git rev-parse --show-toplevel)/.secretsignore"
fi

if [ -n "$SECRETSIGNORE_FILE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|'#'*) continue ;;
      '!'*) continue ;;  # negations not enforced
    esac
    IGNORE_PATTERNS+=("$line")
  done < "$SECRETSIGNORE_FILE"
fi

path_matches_ignore() {
  local p="$1"
  [ "${#IGNORE_PATTERNS[@]}" -eq 0 ] && return 1
  local pat
  for pat in "${IGNORE_PATTERNS[@]}"; do
    # shellcheck disable=SC2053
    case "$p" in
      $pat) return 0 ;;
    esac
    # Handle leading-glob patterns like 'dir/*.txt' against 'dir/sub/*.txt'
    case "$p" in
      */$pat) return 0 ;;
    esac
  done
  return 1
}

# ---------------------------------------------------------------------------
# Scan loop.
# Per-file: detect binary, get staged content, run each pattern, redact, emit.
# ---------------------------------------------------------------------------

declare -a FINDINGS=()        # each element: code|path|line|name|preview|matched_chars
declare -a STAGED_IGNORED=()  # paths that are staged but listed in .secretsignore

is_binary() {
  local f="$1"
  # If git knows the diff, prefer numstat ('-' indicates binary)
  if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    local ns
    ns=$(git diff --cached --numstat -- "$f" 2>/dev/null | head -1 | awk '{print $1}' || true)
    if [ "$ns" = "-" ]; then
      return 0
    fi
  fi
  # Fall back to a NUL byte check on disk via perl (portable across bash 3.2/4)
  if [ -f "$f" ]; then
    if command -v perl >/dev/null 2>&1; then
      if perl -e 'exit !(read(STDIN,$b,8192) && $b =~ /\x00/)' < "$f"; then
        return 0
      fi
    elif command -v od >/dev/null 2>&1; then
      if od -An -c -N 8192 "$f" 2>/dev/null | grep -q '\\0'; then
        return 0
      fi
    fi
  fi
  return 1
}

get_staged_content() {
  local f="$1"
  local out="$2"
  # Fast path: working-tree == index (newly-added or unmodified). Copy file.
  # Slow path: working-tree drifted from index — pull the staged blob via
  # `git show :0:$f`.
  if [ -f "$f" ] && ! is_dirty_cached "$f"; then
    cp "$f" "$out" 2>/dev/null || :
    return 0
  fi
  git show ":0:$f" > "$out" 2>/dev/null || cp "$f" "$out" 2>/dev/null || :
  if [ ! -s "$out" ] && [ -f "$f" ]; then
    cp "$f" "$out" 2>/dev/null || :
  fi
}

redact_preview() {
  local name="$1"
  local match="$2"
  local n
  n=${#match}
  case "$name" in
    PEM_PRIVATE_KEY)
      printf '%s (header)' "$name"
      return
      ;;
  esac
  if [ "$n" -le 4 ]; then
    printf '%s (%d chars)' "$name" "$n"
    return
  fi
  local first last
  first=${match:0:2}
  last=${match: -2}
  printf '%s (%d chars: %s…%s)' "$name" "$n" "$first" "$last"
}

# Precompile a regex-pattern file for `grep -E -f` — one regex per line.
# Lets us run a single fast probe per file before doing per-pattern attribution.
# (The cleanup trap is consolidated above where BINARY_SET_FILE et al. live.)
COMBINED_PATTERN_FILE=$(mktemp)
build_combined_patterns() {
  local entry regex
  : > "$COMBINED_PATTERN_FILE"
  while IFS=$'\t' read -r _code _name regex _conf; do
    [ -z "$regex" ] && continue
    printf '%s\n' "$regex" >> "$COMBINED_PATTERN_FILE"
  done <<< "$CATALOG_LINES"
}
build_combined_patterns

scan_file() {
  local f="$1"
  if path_matches_ignore "$f"; then
    STAGED_IGNORED+=("$f")
    return 0
  fi
  if is_binary_cached "$f"; then
    [ "$VERBOSE" = "1" ] && echo "info: skipping binary $f" >&2
    return 0
  fi

  # Resolve the bytes to scan. Fast path: working tree == index, scan the
  # file in place (no copy). Slow path: pull the staged blob to a temp.
  local scan_path="$f"
  local tmp=""
  if [ ! -f "$f" ] || is_dirty_cached "$f"; then
    tmp=$(mktemp)
    git show ":0:$f" > "$tmp" 2>/dev/null || cp "$f" "$tmp" 2>/dev/null || :
    if [ ! -s "$tmp" ]; then
      rm -f "$tmp"
      return 0
    fi
    scan_path="$tmp"
  fi

  # Truncate to MAX_BYTES if needed. Use `stat` to avoid wc-c on small files.
  local size=0
  if size=$(stat -f%z "$scan_path" 2>/dev/null); then
    :
  elif size=$(stat -c%s "$scan_path" 2>/dev/null); then
    :
  fi
  if [ "${size:-0}" -gt "$MAX_BYTES" ]; then
    local cut
    cut=$(mktemp)
    head -c "$MAX_BYTES" "$scan_path" > "$cut"
    echo "WARN: $f: file truncated for scanning at $MAX_BYTES bytes" >&2
    if [ -n "$tmp" ]; then rm -f "$tmp"; fi
    tmp="$cut"
    scan_path="$cut"
  fi

  # Fast-path probe: if no pattern matches at all, skip per-pattern loop.
  if ! grep -qE -f "$COMBINED_PATTERN_FILE" "$scan_path" 2>/dev/null; then
    if [ -n "$tmp" ]; then rm -f "$tmp"; fi
    return 0
  fi

  # On hit, attribute by per-pattern grep.
  local code name regex conf
  while IFS=$'\t' read -r code name regex conf; do
    [ -z "$regex" ] && continue
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      local lineno=${hit%%:*}
      local linecontent=${hit#*:}
      local match
      match=$(printf '%s\n' "$linecontent" | grep -oE -- "$regex" | head -1)
      [ -z "$match" ] && continue
      local preview
      preview=$(redact_preview "$name" "$match")
      local n=${#match}
      FINDINGS+=("${code}|${f}|${lineno}|${name}|${preview}|${n}")
    done < <(grep -nE -- "$regex" "$scan_path" 2>/dev/null || true)
  done <<< "$CATALOG_LINES"

  if [ -n "$tmp" ]; then rm -f "$tmp"; fi
}

for f in "${TARGETS[@]}"; do
  scan_file "$f"
done

# ---------------------------------------------------------------------------
# Apply trailer override. A finding is suppressed iff its SEC-code appears
# in OVERRIDE_CODES.
# ---------------------------------------------------------------------------

is_overridden() {
  local code="$1"
  [ -z "$OVERRIDE_CODES" ] && return 1
  case " $OVERRIDE_CODES " in
    *" $code "*) return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# Emit findings, sorted by path then line.
# Format: path:line: SEC-NNN: NAME: preview
# ---------------------------------------------------------------------------

# Sort findings using a temp buffer.
sorted=$(mktemp)
if [ "${#FINDINGS[@]}" -gt 0 ]; then
  for f in "${FINDINGS[@]}"; do
    printf '%s\n' "$f"
  done | sort -t '|' -k2,2 -k3,3n > "$sorted"
else
  : > "$sorted"
fi

declare -a ACCEPTED_OVERRIDES=()
HARD_FINDINGS=0

while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  code=$(printf '%s' "$entry" | cut -d'|' -f1)
  fpath=$(printf '%s' "$entry" | cut -d'|' -f2)
  fline=$(printf '%s' "$entry" | cut -d'|' -f3)
  fname=$(printf '%s' "$entry" | cut -d'|' -f4)
  fprev=$(printf '%s' "$entry" | cut -d'|' -f5)
  fchars=$(printf '%s' "$entry" | cut -d'|' -f6)
  printf '%s:%s: %s: %s: %s\n' "$fpath" "$fline" "$code" "$fname" "$fprev"
  if is_overridden "$code"; then
    ACCEPTED_OVERRIDES+=("$code")
  else
    HARD_FINDINGS=$((HARD_FINDINGS + 1))
  fi
  if [ -n "$AUDIT_LOG" ]; then
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    overridden=$(is_overridden "$code" && echo true || echo false)
    printf '{"ts":"%s","path":"%s","line":%s,"code":"%s","pattern_name":"%s","preview":"%s","match_chars":%s,"override_accepted":%s}\n' \
      "$ts" "$fpath" "$fline" "$code" "$fname" "$fprev" "$fchars" "$overridden" \
      >> "$AUDIT_LOG"
  fi
done < "$sorted"
rm -f "$sorted"

# Emit SEC-998 entries for staged-ignored paths (each is a hard finding).
if [ "${#STAGED_IGNORED[@]}" -gt 0 ]; then
  for sp in "${STAGED_IGNORED[@]}"; do
    printf '%s:1: SEC-998: STAGED_IGNORED_PATH: %s should not be committed (matches .secretsignore)\n' \
      "$sp" "$sp"
    HARD_FINDINGS=$((HARD_FINDINGS + 1))
  done
fi

# ---------------------------------------------------------------------------
# Trailer accounting.
# ---------------------------------------------------------------------------

if [ "$TRAILER_BARE" = "1" ] && [ "$TRAILER_PRESENT" = "1" ] && [ "${#FINDINGS[@]}" -gt 0 ]; then
  echo "error: ADD-SECRET-OVERRIDE trailer must enumerate the SEC codes to override (e.g. SEC-001)" >&2
  exit 1
fi

if [ "${#ACCEPTED_OVERRIDES[@]:-0}" -gt 0 ]; then
  uniq_codes=$(printf '%s\n' "${ACCEPTED_OVERRIDES[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//')
  printf 'OVERRIDE ACCEPTED: %s\n' "$uniq_codes"
fi

# ---------------------------------------------------------------------------
# Exit logic.
# ---------------------------------------------------------------------------

if [ "$HARD_FINDINGS" -eq 0 ]; then
  exit 0
fi
exit 1

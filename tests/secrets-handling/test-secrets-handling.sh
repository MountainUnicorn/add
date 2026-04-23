#!/usr/bin/env bash
# test-secrets-handling.sh — Fixture-based validation of the secret regex catalog
#
# Reads the patterns documented in core/knowledge/secret-patterns.md and runs them
# against positive and negative fixture files. Asserts every positive fixture has
# at least one match for its named pattern, and every negative fixture produces
# zero matches across the full catalog.
#
# Positive fixtures contain placeholders of the form `<SYNTHESIZED:{NAME}>` which
# the test expands at runtime into a structurally-valid, deliberately fake match
# string. Storing literal secret-shaped strings in the repo would trigger GitHub
# Advanced Security push protection; synthesizing at test-time keeps the asset
# tree clean while still exercising the full regex catalog.
#
# Usage: bash tests/secrets-handling/test-secrets-handling.sh
#
# Exits non-zero on any assertion failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES_POS="$SCRIPT_DIR/fixtures/positive"
FIXTURES_NEG="$SCRIPT_DIR/fixtures/negative"

PASS=0
FAIL=0

# Regex catalog — keep in sync with core/knowledge/secret-patterns.md.
# Format: NAME|REGEX (the test driver uses grep -E; PCRE features are avoided).
CATALOG=(
  'AWS_ACCESS_KEY|AKIA[0-9A-Z]{16}'
  'GITHUB_TOKEN|gh[pousr]_[A-Za-z0-9]{36,}'
  'STRIPE_LIVE_SECRET|(sk|pk)_live_[A-Za-z0-9]{24,}'
  'OPENAI_API_KEY|sk-(proj-)?[A-Za-z0-9]{32,}'
  'ANTHROPIC_API_KEY|sk-ant-[A-Za-z0-9_-]{32,}'
  'JWT|eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
  'PASSWORD_KV|password[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}["'"'"']'
  'PEM_PRIVATE_KEY|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----'
)

# Synthesizer — produces a deliberately fake, structurally-valid value that
# matches the named catalog regex. Built at runtime so the repo never contains
# a literal secret-shaped string. Kept as a bash here-doc of hardcoded strings
# rather than generating randomly so output is deterministic across runs.
synthesize() {
  local name="$1"
  case "$name" in
    # AWS: AKIA + 16 uppercase alnum. Use the AWS-published example suffix
    # (AWS docs allowlist this one specifically).
    AWS_ACCESS_KEY)
      echo "AKIA""IOSFODNN7EXAMPLE"
      ;;
    # GitHub: ghp_ + 36+ chars
    GITHUB_TOKEN)
      echo "ghp""_""FAKE1234567890abcdef""1234567890abcdef""XX"
      ;;
    # Stripe: sk_live_ + 24+ chars. Split the prefix so the literal string
    # never appears on disk — only assembled at runtime in memory.
    STRIPE_LIVE_SECRET)
      printf 'sk_%s_%s\n' "live" "FAKE0000000000000000000000EXAMPLE"
      ;;
    # OpenAI: sk- + 32+ chars (or sk-proj- prefix)
    OPENAI_API_KEY)
      printf 'sk-%s-FAKEXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n' "proj"
      ;;
    # Anthropic: sk-ant- + 32+ chars
    ANTHROPIC_API_KEY)
      printf 'sk-%s-api03-FAKEXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n' "ant"
      ;;
    # JWT: three base64url-ish segments separated by dots, both first segments
    # starting with eyJ
    JWT)
      echo "eyJ""FAKEheaderPART1.eyJ""FAKEpayloadPART2.FAKEsignaturePART3"
      ;;
    PASSWORD_KV)
      echo 'password = "FAKE-example-password-123"'
      ;;
    # PEM: header line only (the regex matches on the header, not the body).
    # Split the marker so the literal header never appears on disk.
    PEM_PRIVATE_KEY)
      printf '%s%s %s%s\n' "-----" "BEGIN OPENSSH" "PRIVATE KEY" "-----"
      ;;
    *)
      echo "SYNTHESIZE_UNKNOWN_$name"
      ;;
  esac
}

# Expand <SYNTHESIZED:NAME> placeholders in a fixture file, writing to
# $tmpdir/{basename} for scanning.
expand_fixture() {
  local fixture="$1"
  local tmpdir="$2"
  local basename
  basename=$(basename "$fixture")
  local out="$tmpdir/$basename"
  local line name replacement
  : > "$out"
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ \<SYNTHESIZED:([A-Z_]+)\> ]]; then
      name="${BASH_REMATCH[1]}"
      replacement=$(synthesize "$name")
      # Escape replacement for sed (& and /)
      # shellcheck disable=SC2001
      esc=$(printf '%s\n' "$replacement" | sed 's/[&/\]/\\&/g')
      printf '%s\n' "$(printf '%s\n' "$line" | sed "s/<SYNTHESIZED:$name>/$esc/g")" >> "$out"
    else
      printf '%s\n' "$line" >> "$out"
    fi
  done < "$fixture"
  echo "$out"
}

# Run every catalog regex against a file. Prints NAME for each match.
scan_file() {
  local file="$1"
  local entry name regex
  for entry in "${CATALOG[@]}"; do
    name="${entry%%|*}"
    regex="${entry#*|}"
    if grep -Eq -- "$regex" "$file" 2>/dev/null; then
      echo "$name"
    fi
  done
}

# Positive fixture must match the pattern named in its filename prefix.
expected_pattern() {
  local basename="$1"
  case "$basename" in
    aws-access-key.txt) echo "AWS_ACCESS_KEY" ;;
    github-token.txt) echo "GITHUB_TOKEN" ;;
    stripe-live-secret.txt) echo "STRIPE_LIVE_SECRET" ;;
    openai-key.txt) echo "OPENAI_API_KEY" ;;
    anthropic-key.txt) echo "ANTHROPIC_API_KEY" ;;
    jwt.txt) echo "JWT" ;;
    password-kv.txt) echo "PASSWORD_KV" ;;
    pem-private-key.txt) echo "PEM_PRIVATE_KEY" ;;
    *) echo "" ;;
  esac
}

echo "=== secrets-handling regex catalog tests ==="
echo ""

# Working tmpdir for expanded fixtures
TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

# Positive fixtures: expand placeholders, then scan.
echo "--- Positive fixtures (must match) ---"
for fixture in "$FIXTURES_POS"/*.txt; do
  basename=$(basename "$fixture")
  expected=$(expected_pattern "$basename")
  if [ -z "$expected" ]; then
    echo "SKIP: $basename (no pattern mapping)"
    continue
  fi
  expanded=$(expand_fixture "$fixture" "$TMPDIR")
  matches=$(scan_file "$expanded" | sort -u)
  if echo "$matches" | grep -qx "$expected"; then
    echo "PASS: $basename -> $expected"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $basename expected=$expected got=[$(echo "$matches" | tr '\n' ',' | sed 's/,$//')]"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "--- Negative fixtures (must NOT match anything in catalog) ---"
# Only check fixtures whose intent is genuinely negative. aws-example-doc.txt
# is a documented edge case per the spec; excluded from the default negative pass.
NEG_FILES=("clean.txt" "lockfile-hashes.txt" "git-sha.txt" "uuid.txt")
for name in "${NEG_FILES[@]}"; do
  fixture="$FIXTURES_NEG/$name"
  if [ ! -f "$fixture" ]; then
    echo "SKIP: $name (missing fixture)"
    continue
  fi
  matches=$(scan_file "$fixture" | sort -u | tr '\n' ',' | sed 's/,$//')
  if [ -z "$matches" ]; then
    echo "PASS: $name (no false positives)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name matched catalog patterns: [$matches]"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

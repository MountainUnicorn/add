#!/usr/bin/env bash
# test-telemetry-jsonl.sh — Fixture-based tests for telemetry JSONL schema
#
# Validates fixture files against the telemetry spec (core/rules/telemetry.md):
#   * each non-malformed JSONL line parses as JSON
#   * required OTel GenAI + ADD fields are present
#   * outcome is one of {success, failed, aborted, partial}
#   * cache fields are numeric-or-null (never error / missing without null)
#   * malformed fixture yields exactly 1 parse failure + 2 successes
#     (simulates the "reader tolerates malformed lines" contract, AC-024)
#
# Usage: bash tests/telemetry-jsonl/test-telemetry-jsonl.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0

# ---- Required fields per rule schema ----
REQUIRED_FIELDS=(
  "ts" "session_id" "skill" "skill_version"
  "gen_ai.system" "gen_ai.request.model" "gen_ai.response.model"
  "gen_ai.operation.name" "gen_ai.usage.input_tokens" "gen_ai.usage.output_tokens"
  "duration_ms" "outcome" "files_touched" "tool_calls"
)

# ---- Valid outcome values ----
VALID_OUTCOMES="success failed aborted partial"

py_check() {
  # Streams a JSONL file through Python, asserting the schema contract.
  # Returns (on stdout): "VALID=<n> INVALID=<n>"
  local file="$1"
  python3 - "$file" <<'PYEOF'
import json
import sys

required = [
    "ts", "session_id", "skill", "skill_version",
    "gen_ai.system", "gen_ai.request.model", "gen_ai.response.model",
    "gen_ai.operation.name", "gen_ai.usage.input_tokens", "gen_ai.usage.output_tokens",
    "duration_ms", "outcome", "files_touched", "tool_calls",
]
valid_outcomes = {"success", "failed", "aborted", "partial"}

path = sys.argv[1]
valid = 0
invalid = 0
errors = []

with open(path, "r", encoding="utf-8") as fh:
    for lineno, raw in enumerate(fh, start=1):
        line = raw.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError as exc:
            invalid += 1
            errors.append(f"line {lineno}: parse error: {exc.msg}")
            continue

        missing = [k for k in required if k not in obj]
        if missing:
            invalid += 1
            errors.append(f"line {lineno}: missing fields: {missing}")
            continue

        if obj["outcome"] not in valid_outcomes:
            invalid += 1
            errors.append(f"line {lineno}: invalid outcome: {obj['outcome']!r}")
            continue

        # Cache fields: either absent (omitted), numeric, or null. Never string/other.
        bad = False
        for cache_field in ("gen_ai.usage.cache_read_input_tokens",
                            "gen_ai.usage.cache_creation_input_tokens",
                            "cache_hit_ratio"):
            if cache_field in obj:
                v = obj[cache_field]
                if not (v is None or isinstance(v, (int, float))):
                    invalid += 1
                    errors.append(f"line {lineno}: cache field {cache_field} has non-numeric/non-null value: {v!r}")
                    bad = True
                    break
        if bad:
            continue

        # Input/output tokens must be numeric or null
        for tok_field in ("gen_ai.usage.input_tokens", "gen_ai.usage.output_tokens"):
            v = obj[tok_field]
            if not (v is None or isinstance(v, (int, float))):
                invalid += 1
                errors.append(f"line {lineno}: token field {tok_field} has non-numeric/non-null value: {v!r}")
                bad = True
                break
        if bad:
            continue

        # On failure, error field should exist
        if obj["outcome"] == "failed" and "error" not in obj:
            invalid += 1
            errors.append(f"line {lineno}: outcome=failed but no error field")
            continue

        valid += 1

for e in errors:
    sys.stderr.write(e + "\n")
sys.stdout.write(f"VALID={valid} INVALID={invalid}\n")
PYEOF
}

run_schema_test() {
  local name="$1"
  local file="$2"
  local expected_valid="$3"
  local expected_invalid="$4"

  if [ ! -f "$file" ]; then
    echo "FAIL: $name — fixture not found: $file"
    FAIL=$((FAIL + 1))
    return
  fi

  local result
  result=$(py_check "$file" 2>/dev/null)
  local valid
  local invalid
  # Extract VALID=<n> (word-boundary prefix to avoid matching INVALID)
  valid=$(echo "$result" | grep -oE '(^| )VALID=[0-9]+' | grep -oE '[0-9]+$')
  invalid=$(echo "$result" | grep -oE 'INVALID=[0-9]+' | grep -oE '[0-9]+$')

  if [ "$valid" = "$expected_valid" ] && [ "$invalid" = "$expected_invalid" ]; then
    echo "PASS: $name (valid=$valid, invalid=$invalid)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — expected valid=$expected_valid invalid=$expected_invalid; got valid=$valid invalid=$invalid"
    py_check "$file" >/dev/null  # re-run to surface stderr
    FAIL=$((FAIL + 1))
  fi
}

assert_field_present() {
  local name="$1"
  local file="$2"
  local field="$3"

  if python3 -c "
import json, sys
field = sys.argv[1]
with open(sys.argv[2]) as fh:
    for raw in fh:
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if field not in obj:
            sys.exit(1)
sys.exit(0)
" "$field" "$file"; then
    echo "PASS: $name — $field present on every valid line"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — $field missing from at least one valid line in $file"
    FAIL=$((FAIL + 1))
  fi
}

assert_field_null_or_number() {
  local name="$1"
  local file="$2"
  local field="$3"

  if python3 -c "
import json, sys
field = sys.argv[1]
with open(sys.argv[2]) as fh:
    for raw in fh:
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if field in obj:
            v = obj[field]
            if not (v is None or isinstance(v, (int, float))):
                sys.exit(1)
sys.exit(0)
" "$field" "$file"; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== telemetry-jsonl fixture tests ==="
echo ""

# --- Basic success: 1 valid line with cache fields populated
run_schema_test "basic success (schema + cache fields populated)" \
  "$FIXTURES/basic.jsonl" 1 0

assert_field_present "basic has cache_hit_ratio" \
  "$FIXTURES/basic.jsonl" "cache_hit_ratio"

# --- No cache fields reported by model: null handling
run_schema_test "no-cache (null cache fields accepted)" \
  "$FIXTURES/no-cache.jsonl" 1 0

assert_field_null_or_number "no-cache.cache_read is null-or-number" \
  "$FIXTURES/no-cache.jsonl" "gen_ai.usage.cache_read_input_tokens"

assert_field_null_or_number "no-cache.cache_creation is null-or-number" \
  "$FIXTURES/no-cache.jsonl" "gen_ai.usage.cache_creation_input_tokens"

assert_field_null_or_number "no-cache.cache_hit_ratio is null-or-number" \
  "$FIXTURES/no-cache.jsonl" "cache_hit_ratio"

# --- Failed skill invocation still emits telemetry (AC-017)
run_schema_test "failed outcome with error field" \
  "$FIXTURES/failed.jsonl" 1 0

# --- Rotation: two entries in one day's file, both valid
run_schema_test "rotation (two valid entries in single day's file)" \
  "$FIXTURES/rotation.jsonl" 2 0

# --- Malformed fixture: 2 good lines, 1 bad line. Reader continues (AC-024).
run_schema_test "malformed (parser resilience: 2 good + 1 bad)" \
  "$FIXTURES/malformed.jsonl" 2 1

# --- Template exists and parses
TEMPLATE="$SCRIPT_DIR/../../core/templates/telemetry.jsonl.template"
if [ -f "$TEMPLATE" ]; then
  run_schema_test "template file schema-valid" \
    "$TEMPLATE" 3 0
else
  echo "SKIP: template file $TEMPLATE not found"
fi

# --- Rule file exists and is auto-loaded
RULE="$SCRIPT_DIR/../../core/rules/telemetry.md"
if [ -f "$RULE" ]; then
  if grep -q "^autoload: true" "$RULE"; then
    echo "PASS: rule has autoload: true frontmatter"
    PASS=$((PASS + 1))
  else
    echo "FAIL: rule missing autoload: true"
    FAIL=$((FAIL + 1))
  fi
  rule_lines=$(wc -l < "$RULE")
  if [ "$rule_lines" -le 120 ]; then
    echo "PASS: rule length $rule_lines <= 120 (spec target under 80, budget for headings/examples)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: rule too long ($rule_lines lines)"
    FAIL=$((FAIL + 1))
  fi
else
  echo "FAIL: rule file missing at $RULE"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

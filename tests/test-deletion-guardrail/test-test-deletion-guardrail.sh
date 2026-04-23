#!/usr/bin/env bash
# test-test-deletion-guardrail.sh — Fixture-based tests for the test-deletion guardrail.
#
# Exercises scripts/check-test-count.py against a family of RED/GREEN snapshot fixtures,
# plus a discovery smoke test against a tiny sample project.
#
# Usage: bash tests/test-deletion-guardrail/test-test-deletion-guardrail.sh

set -u  # NOTE: do not set -e — we want to evaluate non-zero exits deliberately

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECKER="$REPO_ROOT/scripts/check-test-count.py"
FIXTURES="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0

# Invoke the gate sub-command. Returns exit code from python script.
run_gate() {
  local fixture="$1"
  local extra_args="${2:-}"
  local red="$FIXTURES/$fixture/red.json"
  local green="$FIXTURES/$fixture/green.json"
  local project_root="$FIXTURES/$fixture/project"

  # If no project dir, use a temp empty one so overrides lookup finds nothing
  if [ ! -d "$project_root" ]; then
    project_root="$(mktemp -d)"
  fi

  python3 "$CHECKER" gate \
    --red "$red" \
    --green "$green" \
    --project-root "$project_root" \
    $extra_args \
    >/dev/null 2>&1
  echo $?
}

expect_exit() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $name (exit=$actual)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name (expected exit=$expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== check-test-count.py gate fixture tests ==="
echo ""

# Test 1: counts unchanged -> PASS
exit_code=$(run_gate "count-same")
expect_exit "count-same" 0 "$exit_code"

# Test 2: count increased -> PASS
exit_code=$(run_gate "count-increased")
expect_exit "count-increased" 0 "$exit_code"

# Test 3: count decreased, no override -> FAIL
exit_code=$(run_gate "count-decreased")
expect_exit "count-decreased" 1 "$exit_code"

# Test 4: count decreased, with overrides.json -> PASS
exit_code=$(run_gate "count-decreased-with-approval")
expect_exit "count-decreased-with-approval" 0 "$exit_code"

# Test 5: empty RED snapshot, tests added in GREEN -> PASS (bootstrap case)
exit_code=$(run_gate "empty-before")
expect_exit "empty-before" 0 "$exit_code"

# Test 6: rename (same body hash, different name) -> PASS (no override required)
exit_code=$(run_gate "rename")
expect_exit "rename (body-hash match under new name)" 0 "$exit_code"

# Test 7: replacement without --allow-test-rewrite (no flag) -> FAIL
exit_code=$(run_gate "replacement-without-approval")
expect_exit "replacement-without-approval (no flag)" 1 "$exit_code"

# Test 7b (regression for F-003): --allow-test-rewrite alone without a recorded
# override must FAIL. The flag acknowledges intent but does not bypass approval.
# NOTE: reuses the 'replacement-without-approval' fixture (no overrides.json),
# just adds the flag — proves the flag alone is insufficient.
exit_code=$(run_gate "replacement-without-approval" "--allow-test-rewrite")
expect_exit "replacement-with-flag-no-override (F-003 bypass closed)" 1 "$exit_code"

# Test 8: replacement with --allow-test-rewrite AND recorded override -> PASS
exit_code=$(run_gate "replacement-with-approval" "--allow-test-rewrite")
expect_exit "replacement-with-approval (flag + override)" 0 "$exit_code"

# Test 9: missing GREEN snapshot -> FAIL with canonical message
missing_tmp="$(mktemp -d)"
cp "$FIXTURES/count-same/red.json" "$missing_tmp/red.json"
output=$(python3 "$CHECKER" gate \
  --red "$missing_tmp/red.json" \
  --green "$missing_tmp/nonexistent.json" \
  --project-root "$missing_tmp" 2>&1)
exit_code=$?
if [ "$exit_code" = "1" ] && echo "$output" | grep -q "GREEN snapshot not found"; then
  echo "PASS: missing-green (exits 1 with canonical message)"
  PASS=$((PASS + 1))
else
  echo "FAIL: missing-green (exit=$exit_code, output=$output)"
  FAIL=$((FAIL + 1))
fi
rm -rf "$missing_tmp"

# Test 10: compare sub-command JSON output shape
compare_out=$(python3 "$CHECKER" compare \
  --red "$FIXTURES/count-decreased/red.json" \
  --green "$FIXTURES/count-decreased/green.json" 2>/dev/null)
if echo "$compare_out" | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
assert data['tests_removed'] == 1, f\"expected 1 removed, got {data['tests_removed']}\"
assert data['tests_added'] == 0, f\"expected 0 added, got {data['tests_added']}\"
assert data['tests_renamed'] == 0
assert len(data['removed_details']) == 1
assert data['removed_details'][0]['name'] == 'test_beta'
" 2>/dev/null; then
  echo "PASS: compare-json-shape"
  PASS=$((PASS + 1))
else
  echo "FAIL: compare-json-shape"
  FAIL=$((FAIL + 1))
fi

# Test 11: rename detection in compare output
rename_out=$(python3 "$CHECKER" compare \
  --red "$FIXTURES/rename/red.json" \
  --green "$FIXTURES/rename/green.json" 2>/dev/null)
if echo "$rename_out" | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
assert data['tests_renamed'] == 1, f\"expected 1 renamed, got {data['tests_renamed']}\"
assert data['tests_removed'] == 0, f\"expected 0 removed, got {data['tests_removed']}\"
assert data['tests_added'] == 0, f\"expected 0 added, got {data['tests_added']}\"
" 2>/dev/null; then
  echo "PASS: rename-detection"
  PASS=$((PASS + 1))
else
  echo "FAIL: rename-detection"
  FAIL=$((FAIL + 1))
fi

# Test 12: compare-summary format
summary_out=$(python3 "$CHECKER" compare \
  --red "$FIXTURES/count-increased/red.json" \
  --green "$FIXTURES/count-increased/green.json" \
  --format summary 2>/dev/null)
if echo "$summary_out" | grep -q "tests_added: 2" && \
   echo "$summary_out" | grep -q "tests_removed: 0"; then
  echo "PASS: compare-summary-format"
  PASS=$((PASS + 1))
else
  echo "FAIL: compare-summary-format (got: $summary_out)"
  FAIL=$((FAIL + 1))
fi

# Test 13: Discovery smoke test — snapshot a tiny Python sample
sample_dir="$(mktemp -d)"
mkdir -p "$sample_dir/tests"
cat > "$sample_dir/tests/test_sample.py" <<'EOF'
import pytest

def test_addition():
    assert 1 + 1 == 2

def test_subtraction():
    assert 3 - 1 == 2

async def test_async_op():
    result = await some_op()
    assert result == "ok"

def not_a_test():
    return 42
EOF

(cd "$sample_dir" && git init -q && git add -A && git -c user.email=x@y -c user.name=x commit -qm init)

snap_out=$(python3 "$CHECKER" snapshot \
  --phase red \
  --cycle-id 0 \
  --spec-slug sample \
  --cwd "$sample_dir" \
  --out "$sample_dir/snap.json" \
  --catalog "$REPO_ROOT/core/knowledge/test-discovery-patterns.json" 2>&1)

if echo "$snap_out" | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
assert data['total_functions'] == 3, f\"expected 3, got {data['total_functions']}\"
" 2>/dev/null && \
   python3 -c "
import json
data = json.load(open('$sample_dir/snap.json'))
names = sorted(fn['name'] for f in data['files'] for fn in f['functions'])
assert names == ['test_addition', 'test_async_op', 'test_subtraction'], names
" 2>/dev/null; then
  echo "PASS: discovery-python-basic (3 tests, non-test excluded)"
  PASS=$((PASS + 1))
else
  echo "FAIL: discovery-python-basic"
  echo "  snap_out: $snap_out"
  FAIL=$((FAIL + 1))
fi
rm -rf "$sample_dir"

# Test 14: --fail-on-empty triggers on empty RED
empty_dir="$(mktemp -d)"
(cd "$empty_dir" && git init -q && echo "just docs" > README.md && git add -A && \
 git -c user.email=x@y -c user.name=x commit -qm init)

python3 "$CHECKER" snapshot \
  --phase red \
  --cycle-id 0 \
  --spec-slug empty \
  --cwd "$empty_dir" \
  --out "$empty_dir/snap.json" \
  --catalog "$REPO_ROOT/core/knowledge/test-discovery-patterns.json" \
  --fail-on-empty >/dev/null 2>&1
empty_exit=$?
if [ "$empty_exit" = "1" ]; then
  echo "PASS: empty-red-fails (--fail-on-empty)"
  PASS=$((PASS + 1))
else
  echo "FAIL: empty-red-fails (expected exit 1, got $empty_exit)"
  FAIL=$((FAIL + 1))
fi
rm -rf "$empty_dir"

# Test 15: impact-hint.sh structural smoke test
impact_dir="$(mktemp -d)"
cd "$impact_dir"
git init -q
mkdir -p app tests
cat > app/auth.py <<'EOF'
def login(user, password):
    return None
EOF
cat > app/session.py <<'EOF'
def start():
    return None
EOF
git add -A && git -c user.email=x@y -c user.name=x commit -qm base
BASE_SHA=$(git rev-parse HEAD)
cat > tests/test_auth.py <<'EOF'
from app.auth import login

def test_login_returns_token():
    assert login("u", "p") is not None
EOF
git add -A && git -c user.email=x@y -c user.name=x commit -qm "test(red): add auth tests"

# Create a spec file that mentions app/auth.py
cat > spec.md <<'EOF'
## Acceptance Criteria
AC-001: The function app/auth.py::login returns a token.
AC-002: Sessions persist via app/session.py.
EOF

# Create a learnings file with anti-pattern on app/session.py
mkdir -p .add
cat > .add/learnings.json <<'EOF'
{
  "entries": [
    {
      "id": "L-042",
      "category": "anti-pattern",
      "body": "Do not mutate session state in app/session.py without a lock."
    }
  ]
}
EOF

hint_out=$(bash "$REPO_ROOT/core/lib/impact-hint.sh" "$BASE_SHA" "spec.md" "$impact_dir" 2>&1)
if echo "$hint_out" | grep -q "app/auth.py" && \
   echo "$hint_out" | grep -q "app/session.py" && \
   echo "$hint_out" | grep -q "L-042"; then
  echo "PASS: impact-hint-basic (resolves imports + spec paths + anti-pattern)"
  PASS=$((PASS + 1))
else
  echo "FAIL: impact-hint-basic"
  echo "--- hint output ---"
  echo "$hint_out"
  echo "---"
  FAIL=$((FAIL + 1))
fi
cd "$REPO_ROOT"
rm -rf "$impact_dir"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] || exit 1

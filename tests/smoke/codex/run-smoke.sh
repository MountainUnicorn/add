#!/usr/bin/env bash
# run-smoke.sh — real Codex install smoke (spec AC-012/AC-013/AC-014, milestone AC-023).
#
# Runs INSIDE the tests/smoke/codex/Dockerfile container with the repo mounted
# at /work. Exercises the same path a user takes: scripts/install-codex.sh into
# a real $CODEX_HOME, then asserts the installed surface. When OPENAI_API_KEY is
# present, additionally drives the pinned CLI through /add-init in a scratch
# project and asserts .add/config.json is produced.
#
# Exit code: non-zero on any hard assertion failure. The agent-driven section
# is skipped (with a loud notice) when no API key is available — layout
# assertions still gate.

set -u

REPO_ROOT="${REPO_ROOT:-/work}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
FAIL=0

fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }
pass() { echo "PASS: $*"; }

cd "$REPO_ROOT"

# --- 1. Pinned CLI is what we think it is --------------------------------
CLI_VERSION=$(codex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
if [ -z "$CLI_VERSION" ]; then
  fail "codex CLI not runnable (codex --version produced no version)"
elif [ -n "${EXPECTED_CODEX_CLI_VERSION:-}" ] && [ "$CLI_VERSION" != "$EXPECTED_CODEX_CLI_VERSION" ]; then
  fail "codex CLI version $CLI_VERSION != pinned $EXPECTED_CODEX_CLI_VERSION (adapter.yaml)"
else
  pass "codex CLI $CLI_VERSION matches pin"
fi

# --- 2. Real installer run ------------------------------------------------
if ! bash scripts/install-codex.sh >/tmp/install.log 2>&1; then
  fail "install-codex.sh exited non-zero"
  sed 's/^/    /' /tmp/install.log
else
  pass "install-codex.sh completed"
fi

# --- 3. Skill discovery: installed count == compiled count ----------------
DIST_SKILLS=$(find dist/codex/.agents/skills -maxdepth 1 -type d -name 'add-*' | wc -l | tr -d ' ')
INSTALLED_SKILLS=$(find "$CODEX_HOME/skills" -maxdepth 1 -type d -name 'add-*' 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIST_SKILLS" -gt 0 ] && [ "$INSTALLED_SKILLS" = "$DIST_SKILLS" ]; then
  pass "$INSTALLED_SKILLS/$DIST_SKILLS native skills installed"
else
  fail "skill count mismatch: installed=$INSTALLED_SKILLS dist=$DIST_SKILLS"
fi

# Every installed skill has a SKILL.md with a name: matching its directory.
while IFS= read -r dir; do
  name=$(basename "$dir")
  if [ ! -f "$dir/SKILL.md" ]; then
    fail "$name missing SKILL.md"
  elif ! grep -q "^name: *$name" "$dir/SKILL.md"; then
    fail "$name SKILL.md frontmatter name does not match directory"
  fi
done < <(find "$CODEX_HOME/skills" -maxdepth 1 -type d -name 'add-*' 2>/dev/null)
pass "skill frontmatter/name parity checked"

# --- 4. Hooks + shared assets --------------------------------------------
[ -f "$CODEX_HOME/hooks.json" ] || fail "hooks.json not installed"
HOOK_COUNT=$(find "$CODEX_HOME/hooks" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
[ "$HOOK_COUNT" -gt 0 ] || fail "no hook scripts installed"
while IFS= read -r f; do
  fail "hook not executable: $f"
done < <(find "$CODEX_HOME/hooks" -maxdepth 1 -name '*.sh' ! -perm -u+x 2>/dev/null)
for asset in AGENTS.md plugin.toml VERSION config.toml; do
  [ -f "$CODEX_HOME/add/$asset" ] || fail "shared asset missing: add/$asset"
done
INSTALLED_VERSION=$(cat "$CODEX_HOME/add/VERSION" 2>/dev/null | tr -d '[:space:]')
CORE_VERSION=$(cat core/VERSION | tr -d '[:space:]')
if [ "$INSTALLED_VERSION" = "$CORE_VERSION" ]; then
  pass "installed VERSION $INSTALLED_VERSION matches core/VERSION"
else
  fail "installed VERSION '$INSTALLED_VERSION' != core/VERSION '$CORE_VERSION'"
fi

# --- 5. F-002 path-reference regression suite ----------------------------
if bash tests/codex-install/test-install-paths.sh >/tmp/paths.log 2>&1; then
  pass "codex-install path-reference suite"
else
  fail "codex-install path-reference suite (see below)"
  tail -20 /tmp/paths.log | sed 's/^/    /'
fi

# --- 6. Agent-driven init (needs OPENAI_API_KEY) --------------------------
# AC-013: run /add-init in a scratch project and assert .add/config.json.
# Note (spec deviation, recorded): core/schemas has no config.json schema, so
# the assert is exists + parses + carries version/maturity keys.
if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "SKIP: OPENAI_API_KEY not set — agent-driven /add-init not exercised."
  echo "::warning title=Codex smoke partial::install-layout assertions ran; agent-driven /add-init skipped (no OPENAI_API_KEY)"
else
  # Codex ≥0.14x doesn't adopt OPENAI_API_KEY for its responses websocket
  # without an auth.json — a bare env var yields a misleading 401
  # (openai/codex#15151). Log in explicitly for the headless run.
  codex login --api-key "$OPENAI_API_KEY" >/dev/null 2>&1 \
    || echo "note: codex login --api-key returned non-zero; proceeding to exec"
  SCRATCH=$(mktemp -d)
  (
    cd "$SCRATCH"
    git init -q
    cp "$CODEX_HOME/add/AGENTS.md" AGENTS.md
    # Quick mode interviews; a one-shot exec has no second turn — answers inline.
    # Same product gap as the Claude smoke: /add-init needs --defaults (v0.10.1).
    codex exec --skip-git-repo-check "Run /add-init --quick — non-interactive run: use answers smoke-test, python, 1 (local only), poc, autonomous. Do not ask any questions; write the config now." \
      >/tmp/codex-init.log 2>&1 || true
  )
  if [ -f "$SCRATCH/.add/config.json" ] \
     && python3 -c "import json,sys; c=json.load(open('$SCRATCH/.add/config.json')); sys.exit(0 if ('version' in c and 'maturity' in c) else 1)" 2>/dev/null; then
    pass "/add-init produced valid .add/config.json"
  else
    fail "/add-init did not produce a valid .add/config.json"
    tail -30 /tmp/codex-init.log | sed 's/^/    /'
  fi
  rm -rf "$SCRATCH"
fi

echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "=== Codex install smoke: $FAIL FAILURE(S) ==="
  exit 1
fi
echo "=== Codex install smoke: all assertions passed ==="

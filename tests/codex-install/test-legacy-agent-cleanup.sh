#!/usr/bin/env bash
# test-legacy-agent-cleanup.sh — regression suite for issue #28 (spec AC-2).
# Spec: specs/codex-agent-prefixing.md
#
# v0.11.0 renamed ADD's Codex sub-agents to add-*. The installer must remove
# legacy unprefixed TOMLs (explorer|implementer|reviewer|test-writer|verify)
# from $CODEX_HOME/agents/ ONLY when ADD owns them:
#   - recorded in the prior install-manifest with a matching sha256, OR
#   - bearing the "# ADD sub-agent" marker comment.
# User-owned files of those names get a warning and are left in place.
#
# The suite runs the REAL installer against a COPY of dist/codex whose agent
# TOMLs are renamed to add-* (simulating the post-#28 compiled payload), so
# it asserts installer behavior independently of whether dist/ has been
# recompiled yet.
#
# Usage: bash tests/codex-install/test-legacy-agent-cleanup.sh

set -u
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }
pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
finish() {
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  [ "$FAIL" -eq 0 ]
  exit $?
}

if command -v sha256sum >/dev/null 2>&1; then
  file_sha() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  file_sha() { shasum -a 256 "$1" | awk '{print $1}'; }
else
  echo "FAIL: no sha256sum or shasum available on this host"
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "=== Codex legacy agent-name cleanup suite (#28) ==="
echo "Work dir: $WORK"
echo ""

# ---- Build a payload copy with add-* prefixed agent TOMLs -------------------
# Idempotent: once scripts/compile.py emits add-* names, the rename loop is a
# no-op and the copied payload is used as-is.
FAKE_REPO="$WORK/repo"
mkdir -p "$FAKE_REPO/scripts"
cp "$REPO_ROOT/scripts/install-codex.sh" "$FAKE_REPO/scripts/"
mkdir -p "$FAKE_REPO/dist"
cp -R "$REPO_ROOT/dist/codex" "$FAKE_REPO/dist/codex"
for n in explorer implementer reviewer test-writer verify; do
  src="$FAKE_REPO/dist/codex/.codex/agents/$n.toml"
  [ -f "$src" ] || continue
  sed "s/^name = \"$n\"/name = \"add-$n\"/" "$src" > "$FAKE_REPO/dist/codex/.codex/agents/add-$n.toml"
  rm -f "$src"
done
payload_agents=$(find "$FAKE_REPO/dist/codex/.codex/agents" -name 'add-*.toml' | wc -l | tr -d ' ')
if [ "$payload_agents" -eq 5 ]; then
  pass "setup: payload copy carries 5 add-* agent TOMLs"
else
  fail "setup: payload copy has $payload_agents add-* agent TOMLs (expected 5)"
  finish
fi

INSTALLER="$FAKE_REPO/scripts/install-codex.sh"

# ---- Case A: mixed-ownership legacy files ----------------------------------
# reviewer.toml    — ADD marker, not in manifest        -> removed
# explorer.toml    — no marker, manifest sha matches    -> removed
# test-writer.toml — no marker, manifest sha mismatches -> warned, left
# verify.toml      — no marker, not in manifest         -> warned, left
# implementer.toml — absent                             -> no output line

HOME_A="$WORK/codex-home-a"
mkdir -p "$HOME_A/agents" "$HOME_A/add"

printf '# ADD sub-agent — reviewer\nname = "reviewer"\n' > "$HOME_A/agents/reviewer.toml"
printf 'name = "explorer"\n# stale ADD file from a pre-marker era\n' > "$HOME_A/agents/explorer.toml"
printf 'name = "test-writer"\n# user edited this after ADD installed it\n' > "$HOME_A/agents/test-writer.toml"
USER_VERIFY_CONTENT='name = "verify"
# my own verify agent — not ADD'"'"'s'
printf '%s\n' "$USER_VERIFY_CONTENT" > "$HOME_A/agents/verify.toml"

EXPLORER_SHA=$(file_sha "$HOME_A/agents/explorer.toml")
python3 - "$HOME_A/add/install-manifest.json" "$EXPLORER_SHA" <<'PY'
import json, sys
manifest = {
    "schema": 1,
    "version": "0.10.1",
    "installed_at": "2026-07-18T00:00:00Z",
    "files": [
        {"path": "agents/explorer.toml", "sha256": sys.argv[2]},
        {"path": "agents/test-writer.toml", "sha256": "0" * 64},
    ],
    "backups": [],
}
with open(sys.argv[1], "w") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")
PY

if CODEX_HOME="$HOME_A" bash "$INSTALLER" > "$WORK/install-a.log" 2>&1; then
  pass "A: install over legacy agents completed"
else
  fail "A: installer exited non-zero:"
  cat "$WORK/install-a.log"
  finish
fi

if grep -q 'removed legacy ADD sub-agent TOML: agents/reviewer.toml' "$WORK/install-a.log"; then
  pass "A: marker-owned reviewer.toml reported removed"
else
  fail "A: no removal line for marker-owned reviewer.toml"
fi
if [ ! -f "$HOME_A/agents/reviewer.toml" ]; then
  pass "A: marker-owned reviewer.toml removed from disk"
else
  fail "A: marker-owned reviewer.toml still on disk"
fi

if grep -q 'removed legacy ADD sub-agent TOML: agents/explorer.toml' "$WORK/install-a.log"; then
  pass "A: manifest-sha-owned explorer.toml reported removed"
else
  fail "A: no removal line for manifest-sha-owned explorer.toml"
fi
if [ ! -f "$HOME_A/agents/explorer.toml" ]; then
  pass "A: manifest-sha-owned explorer.toml removed from disk"
else
  fail "A: manifest-sha-owned explorer.toml still on disk"
fi

if grep -q 'WARNING: agents/test-writer.toml exists but is not ADD-owned' "$WORK/install-a.log"; then
  pass "A: sha-mismatched test-writer.toml warned about"
else
  fail "A: no warning for sha-mismatched test-writer.toml"
fi
if [ -f "$HOME_A/agents/test-writer.toml" ] && grep -q 'user edited this' "$HOME_A/agents/test-writer.toml"; then
  pass "A: sha-mismatched test-writer.toml left in place, content intact"
else
  fail "A: sha-mismatched test-writer.toml missing or content changed"
fi

if grep -q 'WARNING: agents/verify.toml exists but is not ADD-owned' "$WORK/install-a.log"; then
  pass "A: user-owned verify.toml warned about"
else
  fail "A: no warning for user-owned verify.toml"
fi
if [ -f "$HOME_A/agents/verify.toml" ] && grep -q "my own verify agent" "$HOME_A/agents/verify.toml"; then
  pass "A: user-owned verify.toml left in place, content intact"
else
  fail "A: user-owned verify.toml missing or content changed"
fi

if grep -Eq '(removed legacy|WARNING).*agents/implementer\.toml' "$WORK/install-a.log"; then
  fail "A: unexpected cleanup output for absent implementer.toml"
else
  pass "A: absent implementer.toml produced no cleanup output"
fi

prefixed_installed=$(find "$HOME_A/agents" -maxdepth 1 -name 'add-*.toml' | wc -l | tr -d ' ')
if [ "$prefixed_installed" -eq 5 ]; then
  pass "A: all 5 add-* agent TOMLs installed"
else
  fail "A: expected 5 add-* agent TOMLs installed, found $prefixed_installed"
fi

# ---- Case B: fresh home — cleanup is silent ---------------------------------

HOME_B="$WORK/codex-home-b"
mkdir -p "$HOME_B"
if CODEX_HOME="$HOME_B" bash "$INSTALLER" > "$WORK/install-b.log" 2>&1; then
  pass "B: fresh install completed"
else
  fail "B: fresh install exited non-zero:"
  cat "$WORK/install-b.log"
  finish
fi
if grep -Eq 'removed legacy ADD sub-agent|not ADD-owned' "$WORK/install-b.log"; then
  fail "B: fresh install produced legacy-cleanup output:"
  grep -E 'removed legacy ADD sub-agent|not ADD-owned' "$WORK/install-b.log" | sed 's/^/  /'
else
  pass "B: fresh install produced zero legacy-cleanup lines"
fi

# ---- Case C: re-install after cleanup is silent -----------------------------

if CODEX_HOME="$HOME_A" bash "$INSTALLER" > "$WORK/install-c.log" 2>&1; then
  pass "C: re-install completed"
else
  fail "C: re-install exited non-zero"
fi
if grep -q 'removed legacy ADD sub-agent' "$WORK/install-c.log"; then
  fail "C: re-install re-reported legacy removals"
else
  pass "C: re-install reported no further legacy removals"
fi

finish

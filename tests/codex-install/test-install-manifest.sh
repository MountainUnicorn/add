#!/usr/bin/env bash
# test-install-manifest.sh — RED-first suite for issue #27 (spec AC-2).
# Spec: specs/codex-install-manifest.md
#
# Invokes scripts/install-codex.sh against a temp CODEX_HOME and asserts:
#   A. Fresh install writes ~/.codex/add/install-manifest.json with schema
#      fields (schema=1, version, installed_at, files[], backups[]) and the
#      bidirectional diff between manifested paths and the actually-installed
#      file tree is empty. Printed output points at uninstall-add.sh instead
#      of the old hand-listed rm -rf block (AC-4).
#   B. Every sha256 recorded in the manifest matches the file on disk (AC-3
#      portability: shasum -a 256 on macOS, sha256sum on Linux).
#   C. Immediate re-install is idempotent: zero warnings, zero .bak files,
#      manifest regenerated (fresh installed_at), diff still empty.
#   D. User-edited installed files are backed up to <path>.bak-<version> with
#      exactly one warning line per file; the new payload lands in place and
#      the backups appear in the manifest's backups[] array.
#   E. Generated ~/.codex/add/uninstall-add.sh removes exactly the manifested
#      files; a planted user file in ~/.codex/skills/ and the .bak backups
#      survive.
#
# Documented exclusions from the bidirectional completeness diff (files that
# legitimately live under CODEX_HOME but are NOT listed in manifest files[]):
#   - add/install-manifest.json  (the manifest excludes itself, per spec)
#   - add/uninstall-add.sh       (generated FROM the manifest; listing it would
#                                 be self-referential — it removes itself)
#   - *.bak-*                    (upgrade-protection backups; recorded under
#                                 backups[], never files[])
# Test harness logs are kept OUTSIDE the temp CODEX_HOME so they never
# pollute the diff.
#
# Usage: bash tests/codex-install/test-install-manifest.sh

set -u  # do not set -e; we report failures structurally
export LC_ALL=C  # bytewise collation so sort/comm agree with Python's sorted()

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-codex.sh"
DIST_DIR="$REPO_ROOT/dist/codex"

PASS=0
FAIL=0

fail() {
  echo "FAIL: $*"
  FAIL=$((FAIL + 1))
}
pass() {
  echo "PASS: $*"
  PASS=$((PASS + 1))
}
finish() {
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  [ "$FAIL" -eq 0 ]
  exit $?
}

# Portable sha256 (AC-3): shasum -a 256 on macOS, sha256sum on Linux
if command -v sha256sum >/dev/null 2>&1; then
  file_sha() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  file_sha() { shasum -a 256 "$1" | awk '{print $1}'; }
else
  echo "FAIL: no sha256sum or shasum available on this host"
  exit 1
fi

TMP_HOME="$(mktemp -d)"
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$LOG_DIR"' EXIT

MANIFEST="$TMP_HOME/add/install-manifest.json"
UNINSTALL="$TMP_HOME/add/uninstall-add.sh"
VERSION="$(cat "$DIST_DIR/VERSION" 2>/dev/null || echo unknown)"

echo "=== Codex install-manifest suite (#27) ==="
echo "Temp CODEX_HOME: $TMP_HOME"
echo ""

# List manifested file paths (sorted), one per line
manifest_paths() {
  python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
for e in sorted(f["path"] for f in m["files"]):
    print(e)
' "$MANIFEST"
}

# List actual on-disk files relative to CODEX_HOME, minus documented exclusions
actual_paths() {
  (cd "$TMP_HOME" && find . -type f | sed 's|^\./||') \
    | grep -v -e '^add/install-manifest\.json$' \
              -e '^add/uninstall-add\.sh$' \
              -e '\.bak-' \
    | sort
}

completeness_diff() {
  local label="$1"
  manifest_paths > "$LOG_DIR/manifested.txt" 2>/dev/null
  actual_paths   > "$LOG_DIR/actual.txt"
  local only_disk only_manifest
  only_disk=$(comm -23 "$LOG_DIR/actual.txt" "$LOG_DIR/manifested.txt")
  only_manifest=$(comm -13 "$LOG_DIR/actual.txt" "$LOG_DIR/manifested.txt")
  if [ -z "$only_disk" ] && [ -z "$only_manifest" ]; then
    pass "$label: manifest <-> installed tree diff is empty (both directions)"
  else
    fail "$label: manifest/tree mismatch"
    [ -n "$only_disk" ] && { echo "  on disk but not manifested:"; echo "$only_disk" | sed 's/^/    /'; }
    [ -n "$only_manifest" ] && { echo "  manifested but not on disk:"; echo "$only_manifest" | sed 's/^/    /'; }
  fi
}

# ---- Case A: fresh install --------------------------------------------------

if CODEX_HOME="$TMP_HOME" bash "$INSTALLER" > "$LOG_DIR/install1.log" 2>&1; then
  pass "A: fresh install completed"
else
  fail "A: installer exited non-zero:"
  cat "$LOG_DIR/install1.log"
  finish
fi

if [ -f "$MANIFEST" ]; then
  pass "A: install-manifest.json written"
else
  fail "A: install-manifest.json not written at $MANIFEST"
  finish
fi

if python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
assert m["schema"] == 1, "schema != 1"
assert m["version"] == sys.argv[2], "version mismatch: %r" % m["version"]
assert m["installed_at"], "installed_at empty"
assert isinstance(m["files"], list) and len(m["files"]) > 0, "files[] empty"
assert isinstance(m["backups"], list), "backups[] not a list"
for e in m["files"]:
    assert e["path"] and not e["path"].startswith("/"), "non-relative path: %r" % e["path"]
    assert len(e["sha256"]) == 64, "bad sha256 for %s" % e["path"]
' "$MANIFEST" "$VERSION" 2> "$LOG_DIR/schema.err"; then
  pass "A: manifest schema fields present (schema=1, version=$VERSION, installed_at, files[], backups[])"
else
  fail "A: manifest schema check failed: $(cat "$LOG_DIR/schema.err")"
fi

completeness_diff "A"

if grep -q 'uninstall-add\.sh' "$LOG_DIR/install1.log"; then
  pass "A: installer output points at uninstall-add.sh (AC-4)"
else
  fail "A: installer output does not mention uninstall-add.sh (AC-4)"
fi
if grep -q 'rm -rf' "$LOG_DIR/install1.log"; then
  fail "A: installer output still contains the drifted 'rm -rf' uninstall block (AC-4)"
else
  pass "A: hand-listed 'rm -rf' uninstall block removed from output (AC-4)"
fi

if [ -f "$UNINSTALL" ]; then
  pass "A: uninstall-add.sh generated"
else
  fail "A: uninstall-add.sh not generated at $UNINSTALL"
fi

# ---- Case B: every manifested sha256 matches disk ---------------------------

mismatches=0
checked=0
while IFS=$'\t' read -r rel sha; do
  [ -n "$rel" ] || continue
  checked=$((checked + 1))
  if [ ! -f "$TMP_HOME/$rel" ]; then
    echo "  missing: $rel"
    mismatches=$((mismatches + 1))
    continue
  fi
  actual=$(file_sha "$TMP_HOME/$rel")
  if [ "$actual" != "$sha" ]; then
    echo "  sha mismatch: $rel"
    mismatches=$((mismatches + 1))
  fi
done < <(python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
for e in m["files"]:
    print(e["path"] + "\t" + e["sha256"])
' "$MANIFEST" 2>/dev/null)

if [ "$checked" -gt 0 ] && [ "$mismatches" -eq 0 ]; then
  pass "B: all $checked manifested sha256 values match files on disk"
else
  fail "B: $mismatches of $checked manifested sha256 entries do not match disk"
fi

# ---- Case C: immediate re-install is idempotent -----------------------------

installed_at_1=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["installed_at"])' "$MANIFEST" 2>/dev/null)
sleep 1

if CODEX_HOME="$TMP_HOME" bash "$INSTALLER" > "$LOG_DIR/install2.log" 2>&1; then
  pass "C: re-install completed"
else
  fail "C: re-install exited non-zero:"
  cat "$LOG_DIR/install2.log"
  finish
fi

if grep -qiE 'backed up|warn' "$LOG_DIR/install2.log"; then
  fail "C: re-install over unmodified tree produced warnings:"
  grep -iE 'backed up|warn' "$LOG_DIR/install2.log" | sed 's/^/  /'
else
  pass "C: re-install produced zero warnings"
fi

bak_count=$(find "$TMP_HOME" -name '*.bak-*' | wc -l | tr -d ' ')
if [ "$bak_count" -eq 0 ]; then
  pass "C: re-install created zero .bak files"
else
  fail "C: re-install created $bak_count .bak file(s)"
fi

installed_at_2=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["installed_at"])' "$MANIFEST" 2>/dev/null)
if [ -n "$installed_at_2" ] && [ "$installed_at_2" != "$installed_at_1" ]; then
  pass "C: manifest regenerated (installed_at refreshed)"
else
  fail "C: manifest not regenerated (installed_at: '$installed_at_1' -> '$installed_at_2')"
fi

completeness_diff "C"

# ---- Case D: user-edited files are backed up + warned -----------------------

EDIT1="add/AGENTS.md"
EDIT2=$(manifest_paths 2>/dev/null | grep '^skills/.*/SKILL\.md$' | head -1)
MARKER="# user local edit $(date +%s)"

edited=0
for rel in "$EDIT1" "$EDIT2"; do
  [ -n "$rel" ] && [ -f "$TMP_HOME/$rel" ] || continue
  echo "$MARKER" >> "$TMP_HOME/$rel"
  edited=$((edited + 1))
done
if [ "$edited" -eq 2 ]; then
  pass "D: setup — edited 2 installed files ($EDIT1, $EDIT2)"
else
  fail "D: setup — could not edit 2 installed files (edited $edited)"
fi

if CODEX_HOME="$TMP_HOME" bash "$INSTALLER" > "$LOG_DIR/install3.log" 2>&1; then
  pass "D: re-install over edited tree completed"
else
  fail "D: re-install over edited tree exited non-zero:"
  cat "$LOG_DIR/install3.log"
  finish
fi

warn_lines=$(grep -c 'backed up' "$LOG_DIR/install3.log" || true)
if [ "$warn_lines" -eq "$edited" ]; then
  pass "D: exactly one warning line per edited file ($warn_lines)"
else
  fail "D: expected $edited 'backed up' warning line(s), got $warn_lines"
  grep -i 'backed up' "$LOG_DIR/install3.log" | sed 's/^/  /'
fi

for rel in "$EDIT1" "$EDIT2"; do
  [ -n "$rel" ] || continue
  bak="$TMP_HOME/$rel.bak-$VERSION"
  if [ -f "$bak" ] && grep -qF "$MARKER" "$bak"; then
    pass "D: $rel backed up to <path>.bak-$VERSION with the user's edit preserved"
  else
    fail "D: backup missing or missing user edit: $bak"
  fi
  if [ -f "$TMP_HOME/$rel" ] && ! grep -qF "$MARKER" "$TMP_HOME/$rel"; then
    pass "D: $rel replaced with fresh payload"
  else
    fail "D: $rel still contains the user edit (payload not refreshed)"
  fi
done

if python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
paths = [b["path"] for b in m["backups"]]
assert len(paths) == int(sys.argv[2]), "expected %s backups, got %r" % (sys.argv[2], paths)
for p in paths:
    assert ".bak-" in p, "backup path without .bak-: %r" % p
' "$MANIFEST" "$edited" 2> "$LOG_DIR/bak.err"; then
  pass "D: manifest backups[] records the $edited backup(s)"
else
  fail "D: manifest backups[] wrong: $(cat "$LOG_DIR/bak.err")"
fi

# ---- Case E: uninstall removes exactly the manifested files -----------------

USER_FILE="$TMP_HOME/skills/my-own-notes.md"
echo "user content — not ADD's" > "$USER_FILE"

# Snapshot the manifested file list BEFORE uninstall deletes the manifest
manifest_paths > "$LOG_DIR/final-manifest-paths.txt" 2>/dev/null

if [ -f "$UNINSTALL" ] && CODEX_HOME="$TMP_HOME" bash "$UNINSTALL" > "$LOG_DIR/uninstall.log" 2>&1; then
  pass "E: uninstall-add.sh ran successfully"
else
  fail "E: uninstall-add.sh missing or exited non-zero"
  [ -f "$LOG_DIR/uninstall.log" ] && cat "$LOG_DIR/uninstall.log"
  finish
fi

leftover=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  if [ -e "$TMP_HOME/$rel" ]; then
    echo "  still present: $rel"
    leftover=$((leftover + 1))
  fi
done < "$LOG_DIR/final-manifest-paths.txt"
if [ "$leftover" -eq 0 ]; then
  pass "E: every manifested file removed"
else
  fail "E: $leftover manifested file(s) survived uninstall"
fi

if [ ! -f "$MANIFEST" ] && [ ! -f "$UNINSTALL" ]; then
  pass "E: manifest and uninstall script removed themselves"
else
  fail "E: manifest or uninstall script left behind"
fi

if [ -f "$USER_FILE" ]; then
  pass "E: planted user file in skills/ survived uninstall"
else
  fail "E: planted user file in skills/ was deleted"
fi

surviving_baks=$(find "$TMP_HOME" -name '*.bak-*' | wc -l | tr -d ' ')
if [ "$surviving_baks" -ge 1 ]; then
  pass "E: $surviving_baks backup file(s) survived uninstall (available for restore)"
else
  fail "E: backups did not survive uninstall"
fi

finish

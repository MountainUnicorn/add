#!/usr/bin/env bash
# test-plugin-root-refs.sh — Every helper a shipped skill tells the agent to run
# must actually ship in the plugin, and must work from an installed location.
#
# Regression guard for the v0.11.0 bug where /add:agents-md invoked
# `scripts/generate-agents-md.py`: that path only existed in the ADD source repo
# (repo-level maintainer tooling that compile.py never copies), so it worked when
# dog-fooding ADD on itself and failed in every consumer project.
#
# Static checks against the compiled outputs:
#   1. Every concrete `${CLAUDE_PLUGIN_ROOT}/<path>` reference resolves in plugins/add/,
#      and every `~/.codex/add/<path>` reference resolves in dist/codex/.
#   2. No ref escapes the plugin root via `..` (resolves in the repo, not the install).
#   3. No skill/rule/reference invokes a repo-relative `scripts/…` helper (bare,
#      `./`-prefixed, or quoted), unless the line explicitly scopes it to the ADD
#      source repo (maintainer tooling).
# Installed-layout smoke (both runtimes):
#   4. Copy each compiled output outside the repo, run both helpers from an unrelated
#      consumer project with no overrides, and assert the package version is stamped
#      and the test-discovery catalog loads.
#
# Usage: bash tests/compile/test-plugin-root-refs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGIN="$REPO_ROOT/plugins/add"
CODEX="$REPO_ROOT/dist/codex"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/core/VERSION")"

python3 "$REPO_ROOT/scripts/compile.py" >/dev/null

FAIL=0
fail() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

# grep wrapper: exit 1 (no match) is fine, exit >=2 (scan error) aborts the suite
# instead of silently reading as "no violations".
scan() {
  local out rc=0
  out=$(grep "$@") || rc=$?
  if [ "$rc" -ge 2 ]; then
    echo "ERROR: grep $* exited $rc" >&2
    exit 2
  fi
  printf '%s' "$out"
}

# 1+2. Runtime-root references resolve (skip templated paths like {name}, <x>, globs).
check_refs() {
  local root="$1" prefix_re="$2" label="$3" refs ref
  refs=$(scan -rhoE "${prefix_re}[A-Za-z0-9_./{}<>*-]+" "$root" --include='*.md')
  [ -n "$refs" ] || return 0
  while IFS= read -r ref; do
    case "$ref" in
      *..*) fail "$label/$ref escapes the plugin root (only resolves inside the ADD source repo)"; continue ;;
      *'{'*|*'*'*|*'<'*|'') continue ;;
    esac
    [ -e "$root/$ref" ] || fail "$label/$ref is referenced but not shipped in ${root#"$REPO_ROOT"/}/"
  done < <(printf '%s\n' "$refs" | sed -E "s|^${prefix_re}||; s|[.,;:)\`]+$||" | sort -u)
}
check_refs "$PLUGIN" '\$\{CLAUDE_PLUGIN_ROOT\}/' '${CLAUDE_PLUGIN_ROOT}'
check_refs "$CODEX"  '~/\.codex/add/'            '~/.codex/add'

# 3. No repo-relative maintainer scripts invoked from shipped content.
SCRIPT_RE='(python3?|bash|sh)[[:space:]]+["'"'"']?(\./)?scripts/[A-Za-z0-9_/-]+\.(py|sh)'
for root in "$PLUGIN" "$CODEX"; do
  hits=$(scan -rnE "$SCRIPT_RE" "$root" --include='*.md')
  [ -n "$hits" ] || continue
  hits=$(printf '%s\n' "$hits" | grep -v 'ADD source repo' \
         | grep -vE '^[^:]+:[0-9]+:python3 scripts/validate-cache-discipline' || true)
  if [ -n "$hits" ]; then
    fail "shipped content in ${root#"$REPO_ROOT"/}/ invokes repo-relative scripts/ (not present in consumer projects):"
    echo "$hits"
  fi
done

# Self-test the step-3 pattern so a regex regression can't silently disable it.
for bad in 'python3 scripts/generate-agents-md.py' 'python3 ./scripts/generate-agents-md.py' \
           'python3 "scripts/generate-agents-md.py"' "bash 'scripts/x/y.sh'"; do
  printf '%s\n' "$bad" | grep -qE "$SCRIPT_RE" || fail "SCRIPT_RE does not catch: $bad"
done

# 4. Installed-layout smoke: helpers run from outside the repo, no overrides.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/proj/.add" "$TMP/proj/tests"
cat > "$TMP/proj/.add/config.json" <<'JSON'
{"version": "0.0.1", "project": {"name": "consumer"}, "maturity": {"level": "alpha"}}
JSON
printf 'def test_one():\n    pass\n\ndef test_two():\n    pass\n' > "$TMP/proj/tests/test_x.py"
cp -R "$PLUGIN" "$TMP/claude-plugin"
cp -R "$CODEX"  "$TMP/codex-add"

for layout in claude-plugin codex-add; do
  lib="$TMP/$layout/lib"
  out=$(cd "$TMP/proj" && python3 "$lib/generate-agents-md.py" --dry-run 2>&1) \
    || { fail "[$layout] generate-agents-md.py failed: $out"; continue; }
  printf '%s' "$out" | grep -q "version=$VERSION" \
    || fail "[$layout] generate-agents-md.py did not stamp version=$VERSION"
  snap="$TMP/$layout-snap.json"
  (cd "$TMP/proj" && python3 "$lib/check-test-count.py" snapshot --phase red \
     --cycle-id 1 --spec-slug smoke --out "$snap" >/dev/null 2>&1) \
    || { fail "[$layout] check-test-count.py snapshot failed (catalog not found?)"; continue; }
  python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if sum(f['function_count'] for f in d['files'])==2 else 1)" "$snap" \
    || fail "[$layout] check-test-count.py did not discover the 2 consumer tests"
done

if [ "$FAIL" -gt 0 ]; then
  echo "test-plugin-root-refs: $FAIL failure(s)"
  exit 1
fi
echo "test-plugin-root-refs: refs resolve in both runtimes; no repo-relative scripts/; helpers work from installed layouts"

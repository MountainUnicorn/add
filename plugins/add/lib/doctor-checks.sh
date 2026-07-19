#!/usr/bin/env bash
# doctor-checks.sh — check battery for /add:doctor (spec: specs/doctor.md, #25)
#
# Pure functions over a $CODEX_HOME-shaped root directory argument. No
# network, no global state, deterministic exit codes. bash + python3 for
# JSON/TOML-ish parsing; sha256 via shasum or sha256sum (macOS + Linux).
#
# Each function prints one or more structured result lines:
#
#   CHECK <id> <pass|warn|fail|info|skip> <detail>
#
# and returns: 0 = pass/info/skip, 1 = warn, 2 = fail. Both the doctor
# skill and tests/hooks/test-doctor-checks.sh consume this output.
#
# Functions (checks per spec):
#   check_config_features <root>   D-CFG      [features] collab + codex_hooks
#   check_hooks_schema    <root>   D-HOOKS    nested >=0.14x hooks.json, scripts exec
#   check_agent_tomls     <root>   D-AGENTS   developer_instructions, no prompt_skill
#   check_plugin_paths    <root>   D-PATHS    plugin.toml skills/agents/hooks resolve
#   check_manifest        <root>   D-MANIFEST install-manifest.json files present
#
# Usage:
#   source core/lib/doctor-checks.sh
#   check_hooks_schema "$HOME/.codex"

# Intentionally no `set -e`: this file is sourced; callers own shell opts.

# -- helpers ----------------------------------------------------------------

# _doctor_sha256 <file> — portable sha256 (macOS shasum / Linux sha256sum)
_doctor_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# _doctor_resolve <root> <path> — map an installed-tree reference to a path
# under <root>. Handles "~/.codex/..." (hook commands, agent instructions)
# and the dist-relative forms used by plugin.toml (".agents/skills/...",
# ".codex/..."), which install-codex.sh maps into $CODEX_HOME.
_doctor_resolve() {
  local root="$1" p="$2"
  case "$p" in
    "~/.codex/"*)      printf '%s/%s' "$root" "${p#\~/.codex/}" ;;
    ".agents/skills/"*) printf '%s/skills/%s' "$root" "${p#.agents/skills/}" ;;
    ".codex/"*)         printf '%s/%s' "$root" "${p#.codex/}" ;;
    /*)                 printf '%s' "$p" ;;
    *)                  printf '%s/%s' "$root" "$p" ;;
  esac
}

# -- D-CFG: config.toml feature gates ---------------------------------------

# check_config_features <root>
# ~/.codex/config.toml must set collab = true and codex_hooks = true under
# [features] — both gates required for ADD sub-agents and hooks.
check_config_features() {
  local root="$1" cfg="$1/config.toml"
  if [ ! -f "$cfg" ]; then
    echo "CHECK D-CFG fail config.toml not found at $cfg — run the ADD installer"
    return 2
  fi
  local missing
  missing=$(python3 - "$cfg" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
# Extract the [features] section (up to the next table header).
m = re.search(r'^\[features\]\s*$(.*?)(?=^\[|\Z)', text, re.M | re.S)
section = m.group(1) if m else ""
missing = []
for key in ("collab", "codex_hooks"):
    if not re.search(r'^\s*%s\s*=\s*true\s*(#.*)?$' % re.escape(key), section, re.M):
        missing.append(key)
print(" ".join(missing))
PY
) || { echo "CHECK D-CFG fail could not parse $cfg"; return 2; }
  if [ -n "$missing" ]; then
    echo "CHECK D-CFG fail [features] gate(s) not enabled: $missing — set them to true in $cfg"
    return 2
  fi
  echo "CHECK D-CFG pass [features] collab and codex_hooks enabled"
  return 0
}

# -- D-HOOKS: hooks.json schema + referenced scripts ------------------------

# check_hooks_schema <root>
# ~/.codex/hooks.json must parse, use the nested >=0.14x schema (top-level
# "hooks" object; entries carry typed command hooks), and every referenced
# script must exist and be executable. The legacy flat shape (event names at
# top level) is silently dead on modern Codex (#24) — hard fail.
check_hooks_schema() {
  local root="$1" hooks="$1/hooks.json"
  if [ ! -f "$hooks" ]; then
    echo "CHECK D-HOOKS fail hooks.json not found at $hooks — run the ADD installer"
    return 2
  fi
  local result
  result=$(python3 - "$hooks" <<'PY'
import json, sys
KNOWN_EVENTS = {"SessionStart", "SessionEnd", "Stop", "UserPromptSubmit",
                "PreToolUse", "PostToolUse", "Notification"}
try:
    data = json.load(open(sys.argv[1]))
except Exception as e:
    print("PARSE %s" % e)
    sys.exit(0)
if not isinstance(data, dict):
    print("SHAPE top-level value is not an object")
    sys.exit(0)
if "hooks" not in data or not isinstance(data.get("hooks"), dict):
    if any(k in KNOWN_EVENTS for k in data):
        print("LEGACY flat pre-0.14x schema (event names at top level, no nested \"hooks\" object)")
    else:
        print("SHAPE no top-level \"hooks\" object")
    sys.exit(0)
commands = []
for event, groups in data["hooks"].items():
    if not isinstance(groups, list):
        print("SHAPE event %s is not a list of matcher groups" % event)
        sys.exit(0)
    for group in groups:
        entries = group.get("hooks") if isinstance(group, dict) else None
        if not isinstance(entries, list):
            print("SHAPE event %s has a group without a nested \"hooks\" list" % event)
            sys.exit(0)
        for entry in entries:
            if not isinstance(entry, dict) or entry.get("type") != "command" or not entry.get("command"):
                print("SHAPE event %s has an entry without a typed command" % event)
                sys.exit(0)
            commands.append(entry["command"])
print("OK")
for c in commands:
    print(c)
PY
) || { echo "CHECK D-HOOKS fail could not inspect $hooks"; return 2; }
  local verdict rest
  verdict=$(printf '%s\n' "$result" | head -n1)
  case "$verdict" in
    PARSE*)  echo "CHECK D-HOOKS fail hooks.json does not parse: ${verdict#PARSE } — reinstall ADD"; return 2 ;;
    LEGACY*) echo "CHECK D-HOOKS fail ${verdict#LEGACY } — rerun the ADD installer to upgrade hooks.json"; return 2 ;;
    SHAPE*)  echo "CHECK D-HOOKS fail invalid hooks.json: ${verdict#SHAPE } — rerun the ADD installer"; return 2 ;;
  esac
  # Verdict OK — validate every referenced script (word 0 of each command).
  rest=$(printf '%s\n' "$result" | tail -n +2)
  local bad="" cmd script resolved
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    script=${cmd%% *}
    resolved=$(_doctor_resolve "$root" "$script")
    if [ ! -f "$resolved" ]; then
      bad="$bad missing:$script"
    elif [ ! -x "$resolved" ]; then
      bad="$bad not-executable:$script"
    fi
  done <<EOF
$rest
EOF
  if [ -n "$bad" ]; then
    echo "CHECK D-HOOKS fail hook script problem(s):$bad — reinstall or chmod 0755"
    return 2
  fi
  echo "CHECK D-HOOKS pass nested >=0.14x schema; all hook scripts present and executable"
  return 0
}

# -- D-AGENTS: agent TOML schema --------------------------------------------

# check_agent_tomls <root>
# Every ADD-owned ~/.codex/agents/*.toml (marked "# ADD sub-agent") must use
# developer_instructions and must NOT use prompt_skill (removed in Codex
# >=0.14x — #24). Referenced ~/.codex/skills/**/SKILL.md paths must resolve.
check_agent_tomls() {
  local root="$1" dir="$1/agents"
  if [ ! -d "$dir" ]; then
    echo "CHECK D-AGENTS fail agents directory not found at $dir — run the ADD installer"
    return 2
  fi
  local checked=0 problems="" toml name skill resolved
  for toml in "$dir"/*.toml; do
    [ -f "$toml" ] || continue
    grep -q '^# ADD sub-agent' "$toml" || continue   # not ADD-owned — skip
    checked=$((checked + 1))
    name=$(basename "$toml")
    if grep -qE '^\s*prompt_skill\s*=' "$toml"; then
      problems="$problems $name:uses-prompt_skill(removed-in->=0.14x)"
      continue
    fi
    if ! grep -qE '^\s*developer_instructions\s*=' "$toml"; then
      problems="$problems $name:missing-developer_instructions"
      continue
    fi
    # Referenced SKILL.md paths must resolve in the installed tree.
    for skill in $(grep -oE '~/\.codex/[^"'"'"' ]*SKILL\.md' "$toml" | sort -u); do
      resolved=$(_doctor_resolve "$root" "$skill")
      [ -f "$resolved" ] || problems="$problems $name:unresolved-skill:$skill"
    done
  done
  if [ -n "$problems" ]; then
    echo "CHECK D-AGENTS fail agent TOML problem(s):$problems — rerun the ADD installer"
    return 2
  fi
  if [ "$checked" -eq 0 ]; then
    echo "CHECK D-AGENTS warn no ADD-owned agent TOMLs found in $dir"
    return 1
  fi
  echo "CHECK D-AGENTS pass $checked ADD agent TOML(s) use developer_instructions; skill paths resolve"
  return 0
}

# -- D-PATHS: plugin.toml path resolution -----------------------------------

# check_plugin_paths <root>
# Every path listed in the installed plugin manifest ($root/add/plugin.toml)
# — skills[], agents[], hooks — must resolve in the installed tree.
check_plugin_paths() {
  local root="$1" manifest="$1/add/plugin.toml"
  if [ ! -f "$manifest" ]; then
    echo "CHECK D-PATHS skip no plugin.toml at $manifest"
    return 0
  fi
  local paths
  paths=$(python3 - "$manifest" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
paths = []
for key in ("skills", "agents"):
    m = re.search(r'^%s\s*=\s*\[(.*?)\]' % key, text, re.M | re.S)
    if m:
        paths += re.findall(r'"([^"]+)"', m.group(1))
m = re.search(r'^hooks\s*=\s*"([^"]+)"', text, re.M)
if m:
    paths.append(m.group(1))
print("\n".join(paths))
PY
) || { echo "CHECK D-PATHS fail could not parse $manifest"; return 2; }
  local total=0 missing="" p resolved
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    total=$((total + 1))
    resolved=$(_doctor_resolve "$root" "$p")
    [ -e "$resolved" ] || missing="$missing $p"
  done <<EOF
$paths
EOF
  if [ -n "$missing" ]; then
    echo "CHECK D-PATHS fail unresolved plugin.toml path(s):$missing — rerun the ADD installer"
    return 2
  fi
  echo "CHECK D-PATHS pass all $total plugin.toml paths resolve"
  return 0
}

# -- D-MANIFEST: install manifest integrity ---------------------------------

# check_manifest <root>
# If $root/add/install-manifest.json exists (#27): every listed file must
# exist (missing = fail). Checksum mismatches are reported as user-modified
# (info, exit 0) — never an error.
check_manifest() {
  local root="$1" manifest="$1/add/install-manifest.json"
  if [ ! -f "$manifest" ]; then
    echo "CHECK D-MANIFEST skip no install-manifest.json (pre-manifest install)"
    return 0
  fi
  local listing
  listing=$(python3 - "$manifest" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception as e:
    print("PARSE %s" % e)
    sys.exit(0)
for f in data.get("files", []):
    print("%s %s" % (f.get("sha256", "-"), f.get("path", "")))
PY
) || { echo "CHECK D-MANIFEST fail could not read $manifest"; return 2; }
  case "$listing" in
    PARSE*)
      echo "CHECK D-MANIFEST fail install-manifest.json does not parse: ${listing#PARSE }"
      return 2 ;;
  esac
  local total=0 missing="" modified="" expected path actual
  while read -r expected path; do
    [ -n "$path" ] || continue
    total=$((total + 1))
    if [ ! -f "$root/$path" ]; then
      missing="$missing $path"
    elif [ "$expected" != "-" ]; then
      actual=$(_doctor_sha256 "$root/$path")
      [ "$actual" = "$expected" ] || modified="$modified $path"
    fi
  done <<EOF
$listing
EOF
  if [ -n "$missing" ]; then
    echo "CHECK D-MANIFEST fail manifest-listed file(s) missing:$missing — rerun the ADD installer"
    return 2
  fi
  if [ -n "$modified" ]; then
    echo "CHECK D-MANIFEST info user-modified file(s) (checksum differs from install):$modified"
    return 0
  fi
  echo "CHECK D-MANIFEST pass all $total manifest-listed files present and unmodified"
  return 0
}

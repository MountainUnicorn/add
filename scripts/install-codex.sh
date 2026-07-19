#!/usr/bin/env bash
# ADD Codex CLI installer (v0.9+ native Skills layout)
#
# Installs ADD's Codex adapter in the native format:
#   - .agents/skills/add-*/    → ~/.codex/skills/add-*/   (native Codex Skills)
#   - .codex/agents/*.toml     → ~/.codex/agents/         (sub-agent definitions)
#   - .codex/hooks/            → ~/.codex/hooks/          (shell hook scripts, mode 0755)
#   - .codex/hooks.json        → ~/.codex/hooks.json      (hook registration — merged if present)
#   - .codex/config.toml       → staged at ~/.codex/add/config.toml (merge guidance printed)
#   - AGENTS.md                → ~/.codex/add/AGENTS.md   (referenced from project AGENTS.md)
#   - templates/               → ~/.codex/add/templates/  (referenced by skills)
#   - knowledge/               → ~/.codex/add/knowledge/  (referenced by skills — threat-model, etc.)
#   - rules/                   → ~/.codex/add/rules/      (referenced by skills)
#   - lib/                     → ~/.codex/add/lib/        (shell helpers, e.g. impact-hint.sh)
#   - security/                → ~/.codex/add/security/   (injection pattern catalog)
#   - plugin.toml              → ~/.codex/add/plugin.toml (plugin manifest)
#
# Required Codex CLI: see min_codex_version in dist/codex/plugin.toml.
#
# Usage:
#   # From a clone of the repo:
#   ./scripts/install-codex.sh
#
#   # Or remote install (copy into ~/.codex/):
#   curl -fsSL https://raw.githubusercontent.com/MountainUnicorn/add/main/scripts/install-codex.sh | bash

set -euo pipefail

# Resolve script location; works whether run locally or via curl|bash
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(dirname "$SCRIPT_DIR")"
  DIST_DIR="$REPO_ROOT/dist/codex"
else
  # Remote install path: clone the repo to a temp dir
  echo "==> Remote install detected; cloning repo..."
  TMP=$(mktemp -d)
  git clone --depth 1 https://github.com/MountainUnicorn/add "$TMP/add" >/dev/null 2>&1
  DIST_DIR="$TMP/add/dist/codex"
fi

if [ ! -d "$DIST_DIR" ]; then
  echo "ERROR: Codex dist not found at $DIST_DIR" >&2
  echo "       If you're in the repo, run: python3 scripts/compile.py" >&2
  exit 1
fi

if [ ! -d "$DIST_DIR/.agents/skills" ]; then
  echo "ERROR: Codex dist at $DIST_DIR uses the legacy prompts/ layout." >&2
  echo "       This installer requires the native Skills layout (v0.9+)." >&2
  echo "       Run: python3 scripts/compile.py" >&2
  exit 1
fi

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
ADD_HOME="$CODEX_HOME/add"
SKILLS_DIR="$CODEX_HOME/skills"
AGENTS_DIR="$CODEX_HOME/agents"
HOOKS_DIR="$CODEX_HOME/hooks"

VERSION=$(cat "$DIST_DIR/VERSION" 2>/dev/null || echo "unknown")

# --- Install manifest plumbing (#27) --------------------------------------
# Every file the installer writes is recorded ($CODEX_HOME-relative path +
# sha256) and emitted to $ADD_HOME/install-manifest.json, from which a
# matching uninstall-add.sh is generated. A PRIOR manifest (if present) is
# read before copying so user-edited files get backed up to
# <path>.bak-<version> instead of being clobbered. Manifest generation is
# fail-open (AC-5): its failure warns but never fails the install.

# Portable sha256: shasum -a 256 on macOS, sha256sum on Linux (AC-3)
if command -v sha256sum >/dev/null 2>&1; then
  file_sha() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  file_sha() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }
else
  file_sha() { echo ""; }
fi

MANIFEST_ENABLED=1
if ! command -v python3 >/dev/null 2>&1 || [ -z "$(file_sha "$DIST_DIR/VERSION")" ]; then
  MANIFEST_ENABLED=0
  echo "    ! WARNING: python3 or a sha256 tool is unavailable — install will complete without a manifest"
fi

MANIFEST_WORK=$(mktemp -d)
trap 'rm -rf "$MANIFEST_WORK"' EXIT
NEW_MAP="$MANIFEST_WORK/new-map.tsv"
PRIOR_MAP="$MANIFEST_WORK/prior-map.tsv"
BACKUPS_TSV="$MANIFEST_WORK/backups.tsv"
: > "$NEW_MAP"; : > "$PRIOR_MAP"; : > "$BACKUPS_TSV"

PRIOR_VERSION=""
PRIOR_MANIFEST="$CODEX_HOME/add/install-manifest.json"
if [ "$MANIFEST_ENABLED" = 1 ] && [ -f "$PRIOR_MANIFEST" ]; then
  PRIOR_VERSION=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$PRIOR_MANIFEST" 2>/dev/null || true)
  python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
for e in m.get("files", []):
    print(e.get("path", "") + "\t" + e.get("sha256", ""))
' "$PRIOR_MANIFEST" > "$PRIOR_MAP" 2>/dev/null || : > "$PRIOR_MAP"
fi

# Look up a path's sha in the prior manifest ("" if absent)
prior_sha() { awk -F'\t' -v p="$1" '$1 == p { print $2; exit }' "$PRIOR_MAP" 2>/dev/null; }

# Upgrade protection: if the destination exists and was user-edited (sha
# differs from the prior manifest's record — or, for unmanifested files,
# from the incoming payload), copy it aside to <path>.bak-<version> first.
protect_existing() {
  local src="$1" rel="$2" dst="$CODEX_HOME/$2"
  [ "$MANIFEST_ENABLED" = 1 ] || return 0
  [ -f "$dst" ] || return 0
  local cur prior incoming bakver
  cur=$(file_sha "$dst")
  [ -n "$cur" ] || return 0
  prior=$(prior_sha "$rel")
  if [ -n "$prior" ]; then
    [ "$prior" = "$cur" ] && return 0
  else
    incoming=$(file_sha "$src")
    [ "$incoming" = "$cur" ] && return 0
  fi
  bakver="${PRIOR_VERSION:-$VERSION}"
  cp "$dst" "$dst.bak-$bakver" 2>/dev/null || return 0
  printf '%s\t%s\n' "$rel.bak-$bakver" "user-edited file preserved before overwrite" >> "$BACKUPS_TSV"
  echo "    ! backed up user-edited file: $rel -> $rel.bak-$bakver"
}

# Record an installed file in the new manifest map
record_file() {
  [ "$MANIFEST_ENABLED" = 1 ] || return 0
  printf '%s\t%s\n' "$1" "$(file_sha "$CODEX_HOME/$1")" >> "$NEW_MAP"
}

# Copy one file into $CODEX_HOME with protection + recording
install_file() {
  local src="$1" rel="$2" dst="$CODEX_HOME/$2"
  protect_existing "$src" "$rel"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  record_file "$rel"
}

# Copy a directory tree file-by-file under a $CODEX_HOME-relative prefix
install_tree() {
  local srcdir="$1" prefix="$2" f
  while IFS= read -r f; do
    install_file "$f" "$prefix/${f#"$srcdir"/}"
  done < <(find "$srcdir" -type f | sort)
}

echo "==> Installing ADD v$VERSION for Codex CLI (native Skills layout)"
echo "    Skills    → $SKILLS_DIR/"
echo "    Agents    → $AGENTS_DIR/"
echo "    Hooks     → $HOOKS_DIR/"
echo "    Shared    → $ADD_HOME/"
echo ""

mkdir -p "$SKILLS_DIR" "$AGENTS_DIR" "$HOOKS_DIR" "$ADD_HOME"

# --- Skills: one directory per skill -------------------------------------
skill_count=0
for src in "$DIST_DIR"/.agents/skills/add-*; do
  [ -d "$src" ] || continue
  name=$(basename "$src")
  install_tree "$src" "skills/$name"
  skill_count=$((skill_count + 1))
done
echo "    ✓ $skill_count native skills installed"

# --- Sub-agent TOMLs ------------------------------------------------------
agent_count=0
for src in "$DIST_DIR"/.codex/agents/*.toml; do
  [ -f "$src" ] || continue
  install_file "$src" "agents/$(basename "$src")"
  agent_count=$((agent_count + 1))
done
echo "    ✓ $agent_count sub-agent TOMLs installed"

# --- Legacy unprefixed sub-agent names (#28) ------------------------------
# v0.11.0 renamed ADD's sub-agents to add-*. Remove a legacy-named TOML only
# when ADD owns it: recorded in the prior install manifest with a matching
# sha256, or bearing the "# ADD sub-agent" marker comment. A same-named file
# ADD does not own is warned about and left in place. Skipped for any name
# the current payload still ships (install_file already handles those).
for legacy in explorer implementer reviewer test-writer verify; do
  [ -f "$DIST_DIR/.codex/agents/$legacy.toml" ] && continue
  legacy_dst="$AGENTS_DIR/$legacy.toml"
  [ -f "$legacy_dst" ] || continue
  legacy_owned=0
  legacy_prior=$(prior_sha "agents/$legacy.toml")
  if [ -n "$legacy_prior" ] && [ "$legacy_prior" = "$(file_sha "$legacy_dst")" ]; then
    legacy_owned=1
  elif grep -q '^# ADD sub-agent' "$legacy_dst" 2>/dev/null; then
    legacy_owned=1
  fi
  if [ "$legacy_owned" = 1 ]; then
    rm -f "$legacy_dst"
    echo "    ✓ removed legacy ADD sub-agent TOML: agents/$legacy.toml (renamed to add-$legacy.toml)"
  else
    echo "    ! WARNING: agents/$legacy.toml exists but is not ADD-owned — left in place (ADD's agent is now add-$legacy.toml)"
  fi
done

# --- Hook scripts + manifest ---------------------------------------------
hook_count=0
for src in "$DIST_DIR"/.codex/hooks/*.sh; do
  [ -f "$src" ] || continue
  install_file "$src" "hooks/$(basename "$src")"
  chmod 0755 "$HOOKS_DIR/$(basename "$src")"
  hook_count=$((hook_count + 1))
done
install_file "$DIST_DIR/.codex/hooks/README.md" "hooks/README.md"
# hooks.json is merged by hand if one already exists — warn the user.
# An existing hooks.json that is ADD-owned (matches the prior manifest's
# record, or is byte-identical to the incoming payload) is overwritten in
# place so re-installs stay idempotent.
HOOKS_JSON_OURS=0
if [ -f "$CODEX_HOME/hooks.json" ]; then
  existing_sha=$(file_sha "$CODEX_HOME/hooks.json")
  if [ -n "$existing_sha" ]; then
    if [ "$(prior_sha "hooks.json")" = "$existing_sha" ] || \
       [ "$(file_sha "$DIST_DIR/.codex/hooks.json")" = "$existing_sha" ]; then
      HOOKS_JSON_OURS=1
    fi
  fi
else
  HOOKS_JSON_OURS=1
fi
if [ "$HOOKS_JSON_OURS" = 1 ]; then
  install_file "$DIST_DIR/.codex/hooks.json" "hooks.json"
  HOOKS_MERGE_NOTE="~/.codex/hooks.json installed fresh."
else
  install_file "$DIST_DIR/.codex/hooks.json" "add/hooks.json"
  HOOKS_MERGE_NOTE="A prior ~/.codex/hooks.json exists; ADD's manifest staged at $ADD_HOME/hooks.json — merge manually."
fi
echo "    ✓ $hook_count hook scripts installed"

# --- Global config.toml (staged for manual merge) ------------------------
install_file "$DIST_DIR/.codex/config.toml" "add/config.toml"

# --- Shared content: AGENTS.md, templates, knowledge, rules, lib, security ---
# Every asset referenced from installed skills as ~/.codex/add/<dir>/... must
# be staged here so the skill references resolve at runtime. F-002 regression
# guard: keep this list in sync with scripts/compile.py CODEX_TOOL_SUBSTITUTIONS
# and with `tests/codex-install/test-install-paths.sh`.
install_file "$DIST_DIR/AGENTS.md" "add/AGENTS.md"
install_file "$DIST_DIR/plugin.toml" "add/plugin.toml"
install_file "$DIST_DIR/VERSION" "add/VERSION"

shared_count=0
for shared_dir in templates knowledge rules lib security references; do
  if [ -d "$DIST_DIR/$shared_dir" ]; then
    install_tree "$DIST_DIR/$shared_dir" "add/$shared_dir"
    # Preserve exec bit on shell helpers (tar/rsync/cp modes vary)
    find "$ADD_HOME/$shared_dir" -type f -name "*.sh" -exec chmod 0755 {} +
    shared_count=$((shared_count + 1))
  fi
done
echo "    ✓ AGENTS.md, plugin.toml, and $shared_count shared asset trees staged at $ADD_HOME/"

# --- Stale ADD-owned files from a prior version --------------------------
# Files listed in the prior manifest, absent from this payload, and still
# byte-identical to what ADD installed (sha matches) are removed. Mismatched
# (user-edited) files are left alone.
if [ "$MANIFEST_ENABLED" = 1 ] && [ -s "$PRIOR_MAP" ]; then
  while IFS=$'\t' read -r rel sha; do
    [ -n "$rel" ] || continue
    awk -F'\t' -v p="$rel" '$1 == p { found = 1 } END { exit !found }' "$NEW_MAP" && continue
    [ -f "$CODEX_HOME/$rel" ] || continue
    [ "$(file_sha "$CODEX_HOME/$rel")" = "$sha" ] && rm -f "$CODEX_HOME/$rel"
  done < "$PRIOR_MAP"
fi

# --- Emit install-manifest.json + uninstall-add.sh (fail-open, AC-5) ------
write_manifest() {
  python3 - "$ADD_HOME/install-manifest.json" "$ADD_HOME/uninstall-add.sh" \
            "$NEW_MAP" "$BACKUPS_TSV" "$VERSION" "$CODEX_HOME" <<'PY'
import datetime, json, os, sys

mf_path, un_path, new_map, baks_tsv, version, codex_home = sys.argv[1:7]

files = []
seen = set()
with open(new_map) as fh:
    for line in fh:
        line = line.rstrip("\n")
        if not line:
            continue
        path, _, sha = line.partition("\t")
        if path in seen:
            continue
        seen.add(path)
        files.append({"path": path, "sha256": sha})
files.sort(key=lambda e: e["path"])

backups = []
if os.path.exists(baks_tsv):
    with open(baks_tsv) as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line:
                continue
            path, _, reason = line.partition("\t")
            backups.append({"path": path, "reason": reason})

manifest = {
    "schema": 1,
    "version": version,
    "installed_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "files": files,
    "backups": backups,
}
with open(mf_path, "w") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")

# Directories to try removing on uninstall: every parent of a manifested
# file, deepest first. Standard Codex dirs (skills/, agents/, hooks/) and
# add/ itself are handled separately / left alone.
dirs = set()
for e in files:
    d = os.path.dirname(e["path"])
    while d:
        dirs.add(d)
        d = os.path.dirname(d)
dirs -= {"skills", "agents", "hooks", "add"}
dir_list = sorted(dirs, key=lambda d: (-d.count("/"), d))

lines = [
    "#!/usr/bin/env bash",
    "# uninstall-add.sh — generated by install-codex.sh (ADD v%s)" % version,
    "# Removes exactly the files recorded in install-manifest.json.",
    "# Backups (*.bak-*) are left in place for optional restore.",
    "set -u",
    'CODEX_HOME="${CODEX_HOME:-%s}"' % codex_home,
    'echo "Removing ADD v%s from $CODEX_HOME ..."' % version,
]
for e in files:
    lines.append('rm -f "$CODEX_HOME/%s"' % e["path"])
lines.append('rm -f "$CODEX_HOME/add/install-manifest.json"')
for d in dir_list:
    lines.append('rmdir "$CODEX_HOME/%s" 2>/dev/null || true' % d)
if backups:
    lines.append('echo "Backups left in place (restore or delete manually):"')
    for b in backups:
        lines.append('echo "  $CODEX_HOME/%s"' % b["path"])
lines.append('rm -f "$CODEX_HOME/add/uninstall-add.sh"')
lines.append('rmdir "$CODEX_HOME/add" 2>/dev/null || true')
lines.append('echo "ADD removed. (~/.codex/hooks.json: restore your own backup if you had one.)"')
with open(un_path, "w") as fh:
    fh.write("\n".join(lines) + "\n")
os.chmod(un_path, 0o755)
PY
}

if [ "$MANIFEST_ENABLED" = 1 ] && write_manifest 2>/dev/null; then
  echo "    ✓ install manifest + uninstall script written to $ADD_HOME/"
else
  echo "    ! WARNING: install manifest could not be generated — install is still complete"
fi

# Guide the user on wiring AGENTS.md into their project
cat <<EOF

Install complete.

Next steps:

1. Wire ADD into your project's AGENTS.md:
     Fresh project (no AGENTS.md yet):
       cp $ADD_HOME/AGENTS.md /path/to/your/project/AGENTS.md

     Existing AGENTS.md — add this line near the top to include ADD's manifest:
       @${ADD_HOME/$HOME/~}/AGENTS.md

2. Enable Codex runtime features (required for sub-agents and hooks):
     In your ~/.codex/config.toml ensure:

       [features]
       collab = true
       codex_hooks = true

       [agents]
       max_threads = 6
       max_depth = 1

     A reference block is at: $ADD_HOME/config.toml

3. Hooks:
     $HOOKS_MERGE_NOTE

Skills dispatch by description match (e.g., "run quality gates" → add-verify)
or explicitly (e.g., /add-verify). High-leak interview skills (/add-spec,
/add-brand-update, /add-away, /add-tdd-cycle, /add-implementer, /add-deploy)
require explicit invocation.

Uninstall:
  bash $ADD_HOME/uninstall-add.sh
  # Removes exactly the files listed in $ADD_HOME/install-manifest.json
  # and leaves any *.bak-* backups in place for restore.

Troubleshooting: https://github.com/MountainUnicorn/add/blob/main/TROUBLESHOOTING.md
EOF

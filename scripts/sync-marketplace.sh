#!/usr/bin/env bash
# ADD marketplace sync
#
# Copies the compiled Claude plugin (plugins/add/) to the local marketplace
# cache so other Claude Code sessions pick up changes without reinstalling.
#
# This was previously an ad-hoc rsync command documented only in memory. v0.7.0
# centralizes it as a script.
#
# Usage:
#   ./scripts/sync-marketplace.sh           # sync to default cache path
#   ./scripts/sync-marketplace.sh /other/cache/path
#
# Other Claude Code sessions must be restarted after sync to pick up
# autoloaded rule changes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SRC="$REPO_ROOT/plugins/add/"
# Default cache location; override with argument
DEFAULT_CACHE="$HOME/.claude/plugins/cache/add-marketplace/add"
CACHE="${1:-$DEFAULT_CACHE}"

if [ ! -d "$SRC" ]; then
  echo "ERROR: plugin source not found at $SRC" >&2
  echo "       Run: python3 scripts/compile.py" >&2
  exit 1
fi

# Ensure we have freshest compile output
echo "==> Recompiling Claude adapter..."
python3 "$SCRIPT_DIR/compile.py" --runtime claude

echo ""
echo "==> Syncing to $CACHE"
mkdir -p "$CACHE"

# Exclusions: everything that's project-specific-to-the-ADD-repo vs what ships
# in the plugin. Consumers don't want our own .add/ or dogfood specs/reports/docs.
# (Marketing site lives in MountainUnicorn/getadd.dev — not in this repo.)
rsync -av --delete \
  --exclude='.add/' \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='.claude/' \
  --exclude='.DS_Store' \
  --exclude='reports/' \
  --exclude='docs/prd.md' \
  --exclude='docs/distribution-plan.md' \
  --exclude='docs/milestones/' \
  --exclude='docs/plans/' \
  --exclude='docs/infographic.svg' \
  --exclude='specs/' \
  --exclude='tests/' \
  --exclude='CHANGELOG.md' \
  "$SRC" \
  "$CACHE/"

echo ""
echo "Sync complete."
echo ""
echo "Other running Claude Code sessions must be restarted for autoloaded"
echo "rule changes to take effect. Open sessions can reload manually with:"
echo "  /clear"

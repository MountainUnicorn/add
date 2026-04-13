#!/usr/bin/env bash
# ADD website deploy — legacy Pages path
#
# Syncs `website/` from the current `main` into the `gh-pages` branch and
# triggers a GitHub Pages build via the legacy Jekyll pipeline.
#
# Why this exists: the primary deploy path is .github/workflows/pages.yml
# (runs on any push touching `website/**`). That path requires GitHub
# Actions to be enabled at the account level. When Actions is restricted
# (billing, ToS review, outage), the workflow can't fire and the live
# site at getadd.dev goes stale.
#
# This script deploys through GitHub's legacy branch-based Pages builder,
# which runs on a separate pool from user Actions and is unaffected by
# account-level Actions restrictions.
#
# Usage:
#   ./scripts/deploy-website.sh              # sync + push + trigger build
#   ./scripts/deploy-website.sh --dry-run    # show what would change
#   ./scripts/deploy-website.sh --no-build   # push only, don't trigger build
#
# Requirements:
#   - git + gh CLI authenticated as the maintainer
#   - clean main branch at the intended deploy commit
#
# When Actions returns, this script remains useful but the GitHub Actions
# workflow will typically win the race on any website/ push.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SITE_DIR="$REPO_ROOT/website"
TMP_DIR="${TMPDIR:-/tmp}/add-deploy-$$"
REMOTE_URL="https://github.com/MountainUnicorn/add.git"

DRY_RUN=false
TRIGGER_BUILD=true

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-build) TRIGGER_BUILD=false ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -40
      exit 0
      ;;
    *) echo "Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

if [ ! -d "$SITE_DIR" ]; then
  echo "ERROR: $SITE_DIR not found" >&2
  exit 1
fi

MAIN_SHA=$(cd "$REPO_ROOT" && git rev-parse --short main 2>/dev/null || git rev-parse --short HEAD)
STAMP=$(date -u +%Y-%m-%dT%H:%MZ)

echo "==> Deploying website @ main $MAIN_SHA"
echo "    Source:  $SITE_DIR"
echo "    Target:  $REMOTE_URL (branch: gh-pages)"
echo "    Stamp:   $STAMP"
echo ""

trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Cloning gh-pages..."
git clone --quiet --branch gh-pages --depth 1 "$REMOTE_URL" "$TMP_DIR"

echo "==> Replacing content..."
# Keep .git, .nojekyll, and README.md (deploy-branch notice); remove everything else
find "$TMP_DIR" -mindepth 1 -maxdepth 1 \
  -not -name '.git' \
  -not -name '.nojekyll' \
  -not -name 'README.md' \
  -exec rm -rf {} +

# Copy website/ contents (including dotfiles, but not the dir itself)
cp -R "$SITE_DIR"/. "$TMP_DIR"/

# Ensure .nojekyll exists so GitHub serves HTML verbatim without Jekyll parsing
touch "$TMP_DIR/.nojekyll"

cd "$TMP_DIR"

# Show what's changing
CHANGES=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$CHANGES" = "0" ]; then
  echo "==> No changes to deploy (gh-pages already matches main @ $MAIN_SHA)"
  exit 0
fi

echo "==> $CHANGES file(s) changed:"
git status --short | head -20
[ "$CHANGES" -gt 20 ] && echo "    ... ($((CHANGES - 20)) more)"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "==> DRY RUN — would commit, push, and trigger build"
  exit 0
fi

echo "==> Committing..."
git add -A
git -c user.email=anthony.g.brooke@gmail.com \
    -c user.name="Anthony Brooke" \
    commit --quiet -m "deploy: $STAMP (main @ $MAIN_SHA)"

echo "==> Pushing to gh-pages..."
git push --quiet origin gh-pages

if [ "$TRIGGER_BUILD" = true ]; then
  echo "==> Triggering Pages build..."
  RESPONSE=$(gh api -X POST repos/MountainUnicorn/add/pages/builds 2>&1)
  if echo "$RESPONSE" | grep -q '"status":"queued"'; then
    echo "    ✓ Build queued"
  else
    echo "    ⚠ Unexpected response from build trigger:"
    echo "      $RESPONSE"
    echo "    (The push itself should still trigger a build on its own.)"
  fi
fi

echo ""
echo "✓ Deployed. Typical propagation: 30–90 seconds."
echo "  https://getadd.dev/"
echo ""
echo "Verify live:"
echo "  curl -sI https://getadd.dev/ | head -3"

#!/usr/bin/env bash
# ADD release helper
#
# Produces a GPG-signed release: verifies tree is clean, runs the
# frontmatter validator and compile drift check, creates a signed annotated
# tag, pushes, and opens a GitHub release with notes lifted from CHANGELOG.md.
#
# Usage:
#   ./scripts/release.sh v0.7.2
#   ./scripts/release.sh v0.7.2 --draft     # creates release as draft
#   ./scripts/release.sh v0.7.2 --dry-run   # prints plan, doesn't execute
#
# Requires: gpg configured (see docs/release-signing.md), gh CLI authenticated.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <version-tag> [--draft] [--dry-run]" >&2
  echo "Example: $0 v0.7.2" >&2
  exit 1
fi

VERSION="$1"
shift || true

DRAFT=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --draft) DRAFT=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

# Strip leading 'v' if present, reattach for tag name
VERSION_NO_V="${VERSION#v}"
TAG="v${VERSION_NO_V}"

echo "==> ADD release helper — tag $TAG"
echo ""

# 1. Sanity: on main, clean tree
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
  echo "ERROR: must be on main branch (currently on '$BRANCH')" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree has uncommitted changes:" >&2
  git status --short >&2
  exit 1
fi

# 2. core/VERSION must match the tag
FILE_VERSION=$(cat core/VERSION | tr -d '[:space:]')
if [ "$FILE_VERSION" != "$VERSION_NO_V" ]; then
  echo "ERROR: core/VERSION is '$FILE_VERSION' but tag is '$VERSION_NO_V'" >&2
  echo "       Bump core/VERSION and re-run: ./scripts/compile.py && git commit" >&2
  exit 1
fi

# 3. Frontmatter + compile drift checks must pass
echo "==> Validating frontmatter..."
python3 scripts/validate-frontmatter.py >/dev/null

echo "==> Checking compile output matches committed artifacts..."
python3 scripts/compile.py --check >/dev/null

# 4. Signing key must be configured
SIGNING_KEY=$(git config --get user.signingkey || echo "")
if [ -z "$SIGNING_KEY" ]; then
  echo "ERROR: git user.signingkey not configured" >&2
  echo "       Run: git config user.signingkey <key-id>" >&2
  echo "       See: docs/release-signing.md" >&2
  exit 1
fi
echo "==> Signing key: $SIGNING_KEY"

# 5. Tag must not already exist
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "ERROR: tag $TAG already exists" >&2
  exit 1
fi

# 6. Extract release notes from CHANGELOG.md
# Look for the section matching [VERSION_NO_V]; grab until the next ## heading
NOTES=$(awk -v ver="[${VERSION_NO_V}]" '
  index($0, "## "ver) == 1 {capture=1; next}
  capture && /^## \[/ {exit}
  capture {print}
' CHANGELOG.md)

if [ -z "$(echo "$NOTES" | tr -d '[:space:]')" ]; then
  echo "ERROR: no [${VERSION_NO_V}] section found in CHANGELOG.md" >&2
  echo "       Add a ## [${VERSION_NO_V}] — YYYY-MM-DD section before releasing." >&2
  exit 1
fi

echo ""
echo "==> Release notes (from CHANGELOG.md):"
echo "$NOTES" | head -30 | sed 's/^/    /'
[ $(echo "$NOTES" | wc -l) -gt 30 ] && echo "    ... (truncated)"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "==> DRY RUN — would execute:"
  echo "    git tag -s $TAG -m 'Release $TAG'"
  echo "    git push origin $TAG"
  echo "    gh release create $TAG --verify-tag $([ "$DRAFT" = true ] && echo '--draft') --title '$TAG' --notes '...'"
  echo "    gh release view $TAG --json url   # verify the page exists (#18 guard)"
  exit 0
fi

# 7. Create signed tag
echo "==> Creating signed tag $TAG..."
git tag -s "$TAG" -m "Release $TAG"

# 8. Verify the signature locally before pushing
echo "==> Verifying tag signature..."
git tag --verify "$TAG"

# 9. Push tag
echo "==> Pushing tag..."
git push origin "$TAG"

# 10. Create GitHub release
# Build flags as an array so an absent --draft can't word-split into a silent
# arg the way the old unquoted $DRAFT_FLAG could (a suspected #18 contributor).
echo "==> Creating GitHub release..."
GH_FLAGS=(--verify-tag --title "$TAG" --notes "$NOTES")
[ "$DRAFT" = true ] && GH_FLAGS+=(--draft)

if ! gh release create "$TAG" "${GH_FLAGS[@]}"; then
  echo "ERROR: 'gh release create' failed for $TAG." >&2
  echo "       The signed tag was pushed but the release page was NOT created." >&2
  exit 1
fi

# 11. Verify the release page actually exists.
# Issue #18: gh release create could leave the script at exit 0 without ever
# publishing a release page (the signed tag pushed fine). Same class as F-001.
# Treat "no release page" as a hard failure and print the recovery command.
echo "==> Verifying the release page exists..."
if ! RELEASE_URL=$(gh release view "$TAG" --json url --jq '.url' 2>/dev/null) || [ -z "$RELEASE_URL" ]; then
  echo "ERROR: release $TAG is not published — 'gh release view' found no release page." >&2
  echo "       This is issue #18: the tag pushed but the release was skipped." >&2
  echo "       Recover with:" >&2
  echo "         gh release create $TAG --verify-tag --title '$TAG' \\" >&2
  echo "           --notes-file <(awk -v ver='[${VERSION_NO_V}]' 'index(\$0,\"## \"ver)==1{c=1;next} c&&/^## \\[/{exit} c{print}' CHANGELOG.md)" >&2
  exit 1
fi

echo ""
echo "✓ Release $TAG published and verified"
echo "  $RELEASE_URL"

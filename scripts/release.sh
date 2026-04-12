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
  echo "    gh release create $TAG --verify-tag $([ "$DRAFT" = true ] && echo '--draft') --title '...' --notes '...'"
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
echo "==> Creating GitHub release..."
TITLE=$(echo "$NOTES" | head -1 | sed 's/^## //; s/^\[//; s/\].*//')
if [ -z "$TITLE" ] || [ "$TITLE" = "$VERSION_NO_V" ]; then
  TITLE="$TAG"
fi

DRAFT_FLAG=""
[ "$DRAFT" = true ] && DRAFT_FLAG="--draft"

gh release create "$TAG" \
  --verify-tag \
  $DRAFT_FLAG \
  --title "$TAG" \
  --notes "$NOTES"

echo ""
echo "✓ Release $TAG published"
echo "  https://github.com/MountainUnicorn/add/releases/tag/$TAG"

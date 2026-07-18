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
SKIP_CI_CHECK=false
for arg in "$@"; do
  case "$arg" in
    --draft) DRAFT=true ;;
    --dry-run) DRY_RUN=true ;;
    --no-verify-ci) SKIP_CI_CHECK=true ;;
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

# 3b. CI on HEAD must be green before a release can be cut (spec AC-021 —
# closes the gap where a signed tag could be minted from an unverified commit).
# --no-verify-ci is the documented emergency override; it prints loudly.
if [ "$SKIP_CI_CHECK" = true ]; then
  echo "!!  WARNING: --no-verify-ci — skipping CI green-check. Release evidence"
  echo "!!  for this tag will not include verified install smoke."
else
  HEAD_SHA=$(git rev-parse HEAD)
  echo "==> Verifying CI checks on HEAD ($HEAD_SHA)..."
  if ! git fetch -q origin main || ! git merge-base --is-ancestor "$HEAD_SHA" origin/main; then
    echo "ERROR: HEAD is not pushed to origin/main — CI has never seen this commit." >&2
    exit 1
  fi
  CHECKS_JSON=$(gh api "repos/{owner}/{repo}/commits/$HEAD_SHA/check-runs" --paginate 2>/dev/null || echo "")
  TOTAL=$(echo "$CHECKS_JSON" | jq -s '[.[].check_runs[]] | length' 2>/dev/null || echo 0)
  if [ "${TOTAL:-0}" -eq 0 ]; then
    echo "ERROR: no CI check-runs found for $HEAD_SHA — wait for CI to start, or" >&2
    echo "       use --no-verify-ci only if you accept an unverified release." >&2
    exit 1
  fi
  NOT_GREEN=$(echo "$CHECKS_JSON" | jq -sr '[.[].check_runs[] | select(.status != "completed" or (.conclusion | IN("success","neutral","skipped") | not)) | "\(.name): \(.status)/\(.conclusion // "pending")"] | .[]' 2>/dev/null)
  if [ -n "$NOT_GREEN" ]; then
    echo "ERROR: CI checks on HEAD are not green:" >&2
    echo "$NOT_GREEN" | sed 's/^/       /' >&2
    exit 1
  fi
  echo "==> All $TOTAL CI checks green"
fi

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

# 6b. Every release ships the per-runtime capability matrix (spec AC-031,
# milestone AC-027) — pinned to this tag so historical releases stay accurate.
NOTES="$NOTES

---
**Runtime capability matrix:** [docs/capability-matrix.md](https://github.com/MountainUnicorn/add/blob/${TAG}/docs/capability-matrix.md) — what is mechanically enforced vs agent-followed vs advisory on each runtime."

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

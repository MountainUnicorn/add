# Release Signing — Maintainer Runbook

This document covers how ADD releases are cryptographically signed by the maintainer, how to set up signing on a new machine, and how users verify a release they've installed.

For the user-facing threat model and verification instructions, see [SECURITY.md](../SECURITY.md).

## Why signed releases

ADD ships rules that are read by Claude Code and Codex as behavioral instructions. A compromised release could reshape agent behavior in ways the user never consented to. Signed tags provide cryptographic proof that a release came from the maintainer, not from a typosquat or a compromised GitHub account.

## Current key

- **Identity:** `Anthony Brooke <anthony.g.brooke@gmail.com>`
- **Fingerprint:** `040C 002A B5A0 E552 46B3  5D2F 8C4D 8020 9306 6794`
- **Key ID (short):** `8C4D802093066794`
- **Algorithm:** RSA 4096 (SC) + RSA 4096 encryption subkey
- **Created:** 2026-04-12

Public key is published at https://github.com/MountainUnicorn.gpg (GitHub auto-serves this once the key is added to the maintainer's account).

## First-time setup (one machine)

Only needed once per maintainer machine. Already done on the primary workstation.

```bash
# Install GPG
brew install gnupg

# Generate a 4096-bit RSA key
gpg --full-generate-key
# Prompts: (1) RSA and RSA, (4096), (0 = no expiration or 2y), name, email, passphrase

# Find the key ID
gpg --list-secret-keys --keyid-format=long
# Output: sec   rsa4096/8C4D802093066794 ...

# Configure git for this repo
git config user.signingkey 8C4D802093066794
git config tag.gpgsign true       # release tags always signed
git config commit.gpgsign false   # commits signed opportunistically (-S flag), not by default

# Rationale for commit.gpgsign = false:
#   Automated agent sessions and CI runs can't interact with pinentry-mac's
#   GUI passphrase dialog, so auto-signing every commit blocks automation.
#   Release tags are the verification anchor that matters — signing those is
#   sufficient for the threat model in SECURITY.md. Individual commits can
#   still be signed on-demand with: git commit -S -m "..."

# Upload public key to GitHub
gpg --armor --export 8C4D802093066794 | pbcopy
# GitHub → Settings → SSH and GPG keys → New GPG key → paste
```

Verify with a test commit:

```bash
git commit --allow-empty -m "chore: test gpg signing"
git log --show-signature -1
# Should show: "Good signature from ..."
```

## Additional machines

To sign from a second machine, export the private key from the primary machine and import on the second. Keep the exported file encrypted and delete it after import.

```bash
# On primary machine
gpg --export-secret-keys --armor 8C4D802093066794 > secret-key.asc

# Transfer via secure channel (NOT email, NOT cloud sync)
# Recommended: USB drive, then wipe after transfer

# On second machine
gpg --import secret-key.asc
shred -u secret-key.asc    # or: rm -P on macOS

# Configure git on second machine (same commands as primary)
```

**Never commit `secret-key.asc` to any repo, even briefly.** If you do, assume the key is compromised — run the Key Rotation runbook below.

## Cutting a release

Use `scripts/release.sh` — it handles validation, tagging, signing, pushing, and GitHub release creation in one command.

```bash
# 1. Bump core/VERSION
echo "0.7.2" > core/VERSION

# 2. Update CHANGELOG.md — add ## [0.7.2] — YYYY-MM-DD section

# 3. Recompile (propagates version)
python3 scripts/compile.py

# 4. Commit
git add -A
git commit -m "chore: bump version to v0.7.2"
git push origin main

# 5. Dry-run first to preview
./scripts/release.sh v0.7.2 --dry-run

# 6. Actually cut the release
./scripts/release.sh v0.7.2
```

The script will refuse to proceed if:
- Working tree isn't clean
- Branch isn't `main`
- `core/VERSION` doesn't match the tag
- Frontmatter validation fails
- Compile drift exists
- Signing key isn't configured
- Tag already exists
- CHANGELOG.md has no matching section

## Verifying your own signed release

After running `release.sh`, verify the tag publicly:

```bash
git tag --verify v0.7.2
# gpg: Good signature from "Anthony Brooke <anthony.g.brooke@gmail.com>"
```

GitHub will show a green "Verified" badge next to the tag and any signed commits, once the GitHub GPG key upload has propagated (a few seconds to a minute).

## Retroactive signing

Do not retroactively sign v0.7.0 or v0.7.1. Re-tagging a published release rewrites history that users may have already installed or forked. Instead:

1. Document the unsigned window in `SECURITY.md` (already done: "v0.7.0 and v0.7.1 predate the signing infrastructure")
2. Sign from v0.7.2 forward
3. Include the unsigned gap as a known limitation in the relevant threat model entry

Users who installed v0.7.0/v0.7.1 and want verification can upgrade to v0.7.2+ and verify from there.

## Key rotation

If the private key is ever compromised (exposed via accidental commit, stolen machine, etc.):

```bash
# 1. Revoke the old key
gpg --gen-revoke 8C4D802093066794 > revoke-cert.asc
gpg --import revoke-cert.asc
gpg --send-keys 8C4D802093066794   # publishes revocation to keyservers

# 2. Generate a new key (see First-time setup)

# 3. Upload new public key to GitHub, delete the old one

# 4. Post a security advisory
gh api repos/MountainUnicorn/add/security-advisories -f summary="GPG signing key rotated" ...

# 5. Update SECURITY.md and docs/release-signing.md with the new fingerprint

# 6. Next release ships with the new key; older releases remain verifiable
#    against the revoked key (revocation prevents NEW signatures, not
#    verification of existing ones)
```

## Expiration policy

The current key has no expiration. If you prefer an expiring key (say 2 years), generate a new one with the `--default-new-key-algo rsa4096` + expiration, follow the rotation runbook above, and keep both valid for an overlap period so users have time to update.

## Troubleshooting

### "gpg: signing failed: No pinentry"

macOS GUI pinentry didn't start. Fix:

```bash
brew install pinentry-mac
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

### "gpg: signing failed: Inappropriate ioctl for device"

Running under a non-TTY context (e.g., some CI environments). Set:

```bash
export GPG_TTY=$(tty)
```

Add to `~/.zshrc` permanently.

### `release.sh` says "compile drift detected"

Run `python3 scripts/compile.py` to regenerate `plugins/add/` and `dist/codex/`, then commit the result before retrying.

### GitHub shows "Unverified" despite a good local signature

Usually one of:

1. Public key not uploaded to GitHub (Settings → SSH and GPG keys)
2. The email on the git commit doesn't match any verified email on your GitHub account (check `git config user.email`)
3. Key was uploaded but propagation hasn't completed — wait a minute, refresh

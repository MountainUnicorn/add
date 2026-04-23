# ADD Secret Patterns Catalog — Tier 1

> **Tier 1: Plugin-Global** — Single-source regex catalog consumed by:
>
> - `core/rules/secrets-handling.md` (read-deny + redact-on-ingest)
> - `core/skills/deploy/SKILL.md` (pre-commit secrets gate)
> - `core/rules/learning.md` (PII/secret heuristic on learning write)
>
> All three surfaces MUST reference the same names so an override flag in
> `/add:deploy` and a redaction tag in `.add/learnings.json` use the same vocabulary.

## 1. Catalog Entries

Each entry lists the stable `name` (used in error messages and `[REDACTED:{name}]`
tags), a POSIX extended regular expression (compatible with `grep -E`), a
description, the provider (`aws`, `github`, `stripe`, `openai`, `anthropic`, or
`generic`), confidence (`high` = deterministic prefix, `medium` = entropy +
context), and remediation guidance.

### AWS_ACCESS_KEY

- **regex:** `AKIA[0-9A-Z]{16}`
- **description:** AWS access-key ID (long-lived IAM user credential).
- **provider:** `aws`
- **confidence:** `high`
- **remediation:** Rotate the key in the AWS IAM console immediately. A matching
  secret-access-key pair is probably in the same file.

### GITHUB_TOKEN

- **regex:** `gh[pousr]_[A-Za-z0-9]{36,}`
- **description:** GitHub personal / OAuth / user-to-server / server-to-server / refresh token.
- **provider:** `github`
- **confidence:** `high`
- **remediation:** Revoke at https://github.com/settings/tokens. Regenerate if needed.

### STRIPE_LIVE_SECRET

- **regex:** `(sk|pk)_live_[A-Za-z0-9]{24,}`
- **description:** Stripe live secret or publishable key. Test-mode keys
  (`sk_test_`, `pk_test_`) are NOT matched — that is intentional. Test keys in
  fixtures should not trip the gate.
- **provider:** `stripe`
- **confidence:** `high`
- **remediation:** Roll the key in the Stripe dashboard. Audit webhook logs for
  misuse during the exposure window.

### OPENAI_API_KEY

- **regex:** `sk-(proj-)?[A-Za-z0-9]{32,}`
- **description:** OpenAI API key, legacy or project-scoped.
- **provider:** `openai`
- **confidence:** `high`
- **remediation:** Revoke at https://platform.openai.com/api-keys.

### ANTHROPIC_API_KEY

- **regex:** `sk-ant-[A-Za-z0-9_-]{32,}`
- **description:** Anthropic API key.
- **provider:** `anthropic`
- **confidence:** `high`
- **remediation:** Revoke at https://console.anthropic.com/settings/keys.

### JWT

- **regex:** `eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+`
- **description:** JSON Web Token (three base64url segments separated by dots).
  Matches both signed and unsigned JWTs.
- **provider:** `generic`
- **confidence:** `high`
- **remediation:** Invalidate the session or rotate the signing key. JWTs are
  bearer tokens — assume compromise once leaked.

### PASSWORD_KV

- **regex:** `password[[:space:]]*[:=][[:space:]]*["'][^"']{8,}["']`
- **description:** A `password = "..."` / `password: "..."` assignment with
  quoted value ≥ 8 chars. Case-sensitive — `password` only. Variants like
  `PASSWORD`, `Password`, `db_password` are NOT matched to keep false-positive
  noise low; add them to `.add/secret-patterns.local.json` (future) if your
  project uses them.
- **provider:** `generic`
- **confidence:** `medium`
- **remediation:** Rotate the password; move to a secret manager or `.env` (which
  `.secretsignore` covers by default).

### PEM_PRIVATE_KEY

- **regex:** `-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----`
- **description:** PEM header for any private key (RSA, EC, OpenSSH, PGP, or
  generic PKCS#8). Matches on the header line; the body is irrelevant.
- **provider:** `generic`
- **confidence:** `high`
- **remediation:** **ROTATE IMMEDIATELY.** Private keys are the highest-severity
  leak. Delete the file from git history (`git filter-repo`), notify anyone with
  access to the repo, generate a new key.

## 2. High-Entropy Heuristic

Beyond the deterministic prefixes above, catch secrets without known framing
by flagging tokens that look like compressed randomness.

**Flag when ALL of the following hold:**

1. **Length ≥ 32 characters** (below this, false-positive rate is prohibitive).
2. **Character set is base64-ish or hex** — `[A-Za-z0-9+/=_-]` only.
3. **Shannon entropy > 4.5 bits/char** — hex strings average ~4.0, random base64
   averages ~6.0. The 4.5 threshold catches high-entropy tokens without flagging
   lowercase-only hashes or repetitive strings.

**Suppress when ANY of the following hold** (safe-context exceptions):

| Context | Heuristic |
|---------|-----------|
| Lockfile | Enclosing file is `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `Gemfile.lock`, `poetry.lock`, `go.sum`, `composer.lock` |
| Git commit SHA | 40-hex-char string matching `\b[0-9a-f]{40}\b` on a line that also contains a commit-log marker (`commit`, `Merge:`, `Author:`, `Date:`) or appears inside a fenced `git log` / `git show` block |
| UUID | Matches RFC 4122 `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` |
| Content-addressed hash | Prefixed with a known algorithm marker: `sha256-`, `sha512-`, `blake3-`, `md5-`, `sri-` |
| Build/trace ID | Context line contains `build_id`, `trace_id`, `request_id`, or `span_id` within 40 characters |
| Known placeholder | String matches `EXAMPLE`, `PLACEHOLDER`, `REDACTED`, `XXXXX`, or ends in `...` |

The false-positive target for the entropy heuristic is **zero matches** across
the top-10 open-source projects' lockfiles (see spec AC-024).

## 3. Path-Based Read-Deny List

Not a regex match — a path-prefix match. The `secrets-handling` rule forbids
reading these paths (relative or absolute) without explicit per-invocation
human approval:

```
.env
.env.*          (but .env.example, .env.sample are allowed — see notes)
*.pem
*.key
*.cer
id_rsa*
id_ecdsa*
id_ed25519*
.aws/
.ssh/
.gnupg/
secrets/
credentials*
.netrc
.pgpass
*.kdbx
```

**Allowed without prompt** (convention: these are placeholders, not real secrets):

- `.env.example`
- `.env.sample`
- Any path with a `.example`, `.sample`, or `.template` suffix

## 4. Redaction Format

When a catalog pattern matches inside content that is being written to an ADD
artifact (learning body, handoff summary, retro notes, dashboard export), replace
the matched substring with:

```
[REDACTED:{name}]
```

Where `{name}` is the catalog entry name (`AWS_ACCESS_KEY`, `JWT`, etc.).

Log the redaction event to `.add/redaction-log.json` with schema:

```json
{
  "version": "1.0.0",
  "entries": [
    {
      "date": "2026-04-22T14:33:02Z",
      "artifact": "learning",
      "pattern_name": "JWT",
      "count": 1,
      "source_skill": "add:deploy"
    }
  ]
}
```

The log lets users audit what was suppressed without storing the secret itself.

## 5. Extension Points

- **User-local patterns** (deferred): `.add/secret-patterns.local.json` — a
  project-scoped catalog that extends the built-in patterns for company-specific
  formats. Not implemented in v0.9.0; see `specs/secrets-handling.md` Open
  Questions.
- **Catalog updates flow automatically** — `/add:init` writes `.secretsignore`
  once and never overwrites, so existing projects keep their file. Rule and
  gate always read the latest catalog from the plugin (`${CLAUDE_PLUGIN_ROOT}/knowledge/secret-patterns.md`).

## 6. Change Log

| Date | Change |
|------|--------|
| 2026-04-22 | Initial catalog — 8 high-confidence patterns + entropy heuristic. Implements AC-006 through AC-008 of `specs/secrets-handling.md`. |

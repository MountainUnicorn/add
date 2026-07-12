# Staged-Secret Scan — Shared Gate Logic

Block commits that contain secrets before they reach the remote git history.
This reference is the single home for the scan mechanics. Consumers:

- `/add-verify` — Gate 4.6, runs at `--level deploy` (and any superset)
- `/add-deploy` — pre-commit secret scan before staging a commit

Closes F-014 (the v0.9.0 secrets gate was prose-only).

## Source of Truth

`core/security/secret-patterns.json` — the executable catalog. The companion
`core/knowledge/secret-patterns.md` is the human reference; CI's
`validate-secret-patterns.py` keeps the two in sync.

## Invocation

Invoke the scanner with the staged-diff default:

```bash
"~/.codex/add/lib/scan-secrets.sh"
```

The scanner reads `git diff --cached`, applies every catalog regex, skips
binaries and `.secretsignore`-matched paths, and honors any
`[ADD-SECRET-OVERRIDE: SEC-NNN]` trailer in the commit message.

## Exit Codes

| Code | Meaning | Gate result |
|------|---------|-------------|
| 0 | No findings (or every finding overridden by a trailer) | PASS |
| 1 | At least one unsuppressed finding | FAIL — block the gate |
| 2 | Invocation error (bad args) | FAIL with remediation note |
| 3 | Catalog missing/unparseable | FAIL — defense-in-depth: never silently disable enforcement |

## Reporting Rules

Report findings verbatim. The scanner already redacts every preview per
AC-013 — NEVER paste the matched value into the report.

## Report Format

```
━━━ STAGED-SECRET SCAN ━━━
Scanning 12 staged files...

  ✗ config/api.py:8 — SEC-002: GITHUB_TOKEN
  ✗ scripts/seed.py:42 — SEC-001: AWS_ACCESS_KEY

Staged-Secret Scan: FAIL (2 findings)

Run `/add-deploy` and choose remediation, or commit with
[ADD-SECRET-OVERRIDE: SEC-001 SEC-002 (reason)] for a non-commit override.
```

Maps to AC-021 of `specs/secrets-scanner-executable.md`.

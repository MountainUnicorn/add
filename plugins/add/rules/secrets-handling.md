---
autoload: true
maturity: alpha
description: "Forbid reading well-known secret paths; redact secret-shaped values before writing to any ADD artifact. Companion to injection-defense."
---

# ADD Rule: Secrets Handling

ADD prevents **accidental** disclosure of secrets leaking into shared artifacts
(learnings, handoff, retro, dashboards, commits) or public git history.

Catalog + path list: `knowledge/secret-patterns.md`. Threat model: `knowledge/threat-model.md` § T1.

## Invariants

### 1. Read-deny paths

Do NOT Read/Glob/cat these paths without explicit per-invocation approval:

`.env`, `.env.*` (allow `*.example`, `*.sample`, `*.template` suffixes), `*.pem`, `*.key`, `*.cer`, `id_rsa*`, `id_ecdsa*`, `id_ed25519*`, `.aws/`, `.ssh/`, `.gnupg/`, `secrets/`, `credentials*`, `.netrc`, `.pgpass`, `*.kdbx`.

When asked to read one, respond:

> "`{path}` is on the secrets-handling read-deny list. Confirm reading it this once?"

Wait for explicit confirmation. If declined, propose an alternative (share the
variable name, paste the single value you need seen, etc.).

### 2. Redact-on-ingest

When a tool result (file read, `cat`, `env`, HTTP response) contains a value
matching the regex catalog, **replace the match with `[REDACTED:{pattern_name}]`
before writing any summary or appending to ADD storage.**

### 3. Write-redact invariant

Every write path MUST run the redaction pass:

| Artifact | Redact on write? |
|----------|------------------|
| `.add/learnings.json`, `~/.claude/add/library.json` | Yes |
| `.add/handoff.md`, `.add/retros/*.md`, `.add/observations.md` | Yes |
| Dashboard exports (`reports/*.html`) | Yes |
| Commit message body | Yes |
| Sub-agent prompt handoffs | Yes |

Log every redaction to `.add/redaction-log.json` (schema in
`knowledge/secret-patterns.md` § 4) — audit without storing the secret.

### 4. Context-leak escape hatch

If a secret entered context before this rule fired, warn at the next natural
break: "Context may contain leaked credentials from `{path}`. Consider `/clear`."

## Template + Deploy-Gate Contracts

- **`.secretsignore` template** — `/add:init` copies `templates/.secretsignore.template`
  to project root only if absent. Never overwrite. On create, print:
  `Wrote .secretsignore (commit this — your team shares the policy).`
- **Pre-commit secrets gate** — `/add:deploy` scans staged content against the
  catalog. Match aborts the commit. `--allow-secret` requires typing
  `I have verified this is not a real secret` exactly (case-sensitive, full
  string). Override logged to `.add/observations.md`. Details in
  `core/skills/deploy/SKILL.md` § Pre-commit secrets gate.

## Boundary

ADD prevents **accidental** disclosure. ADD does NOT stop exfiltration by a
compromised tool — that requires Claude Code's permission system
(`.claude/settings.json` → `permissions.deny` on Read for credential paths).
For adversarial projects, pair with `gitleaks`, `detect-secrets`, or GitHub
push protection. The regex catalog is best-effort, not a full secrets scanner.

## Coordination

- `rules/learning.md`'s PII heuristic overlaps — both fire until PR #6 lands the
  shared catalog-loader; no regression.
- `rules/injection-defense.md` (Swarm D) shares `knowledge/threat-model.md`.
  Injection is adversarial redirection; this rule is accidental disclosure.

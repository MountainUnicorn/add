# Spec: Secrets Handling

**Version:** 0.1.0
**Created:** 2026-04-22
**PRD Reference:** docs/prd.md
**Status:** Complete
**Target Release:** v0.9.0
**Shipped-In:** v0.9.0
**Last-Updated:** 2026-04-22
**Milestone:** M3-pre-ga-hardening
**Companion-of:** prompt-injection-defense

## 1. Overview

ADD agents read files freely during cycles, write checkpoint logs, run commit commands, and synthesize artifacts (learnings, handoff, retro, dashboard). Today there is no specific defense against an agent reading `.env`, `~/.aws/credentials`, `~/.ssh/id_rsa`, or a vendored secrets file into context — and once a secret is in context, it can leak into a learning entry, a handoff summary, a retro table, or be staged into a commit. The existing PII heuristic in `core/rules/learning.md` covers names/emails but not credentials.

This spec ships a narrow, high-ROI accidental-disclosure defense: an auto-loaded rule that forbids reading well-known secret-bearing paths and writing matching values into ADD storage, a `.secretsignore` template installed by `/add:init`, a pre-commit grep gate in `core/skills/deploy/SKILL.md` that catches secrets before they leave the workstation, and an upgraded redaction pass on the learning write path. Industry context grounds the choice of patterns: GitGuardian's 2025 *State of Secrets Sprawl* reported 28.6M secrets leaked to public GitHub (a 34% YoY increase) with repos using AI tooling 40% more likely to leak; Lasso/TurboGeek's 2026 research found a four-rule CLAUDE.md snippet covering common secret patterns to be the single highest-ROI mitigation among 30+ they evaluated; DZone, Aembit, and Help Net Security have all published 2026 coverage of the "AI agents exfiltrating secrets" cluster.

This spec is the companion to `specs/prompt-injection-defense.md`. They share the threat model in `core/knowledge/threat-model.md` but address different vectors — injection is adversarial content trying to redirect the agent; secrets handling is accidental disclosure of legitimate user data.

The boundary is explicit: ADD prevents *accidental* disclosure. ADD does not stop a determined exfiltration attack via a compromised tool — that requires capability-based runtime sandboxing (Claude Code's permission system), which is out of scope.

### User Story

As an ADD user, I want the agent to refuse to read my `.env` and credential files by default, redact any secret-shaped string before it lands in a learning or handoff, and block any commit that contains a secret pattern, so that accidental leakage of my keys into a public repo or shared artifact becomes hard rather than easy.

## 2. Acceptance Criteria

### A. Auto-Loaded Rule

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `core/rules/secrets-handling.md` exists, is auto-loaded by the maturity loader at all maturity levels (alpha+), and is under 80 lines. | Must |
| AC-002 | The rule forbids the agent from reading these path patterns without explicit per-invocation human approval: `.env*`, `*.pem`, `*.key`, `id_rsa*`, `id_ecdsa*`, `id_ed25519*`, `.aws/`, `.ssh/`, `.gnupg/`, `secrets/`, `credentials*`, `.netrc`, `.pgpass`, `*.kdbx`. | Must |
| AC-003 | The rule forbids writing any value matching the regex catalog into ANY ADD artifact: `.add/learnings.json`, `.add/handoff.md`, `.add/retros/*`, `.add/observations.md`, dashboard reports, telemetry exports. | Must |
| AC-004 | The rule includes a redact-on-ingest directive: when a tool result (file read, bash output, etc.) contains a value matching the regex catalog, the agent must replace it with `[REDACTED:{pattern_name}]` before writing any summary or appending to ADD storage. | Must |
| AC-005 | The rule cites the boundary explicitly: "ADD prevents accidental disclosure. For exfiltration defense, use Claude Code's permission system to deny `Read` on credential paths." | Should |

### B. Regex Catalog

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-006 | A documented regex catalog covers at minimum: AWS access key (`AKIA[0-9A-Z]{16}`), GitHub tokens (`gh[pousr]_[A-Za-z0-9]{36,}`), Stripe live keys (`(sk\|pk)_live_[A-Za-z0-9]{24,}`), OpenAI keys (`sk-(proj-)?[A-Za-z0-9]{32,}`), Anthropic keys (`sk-ant-[A-Za-z0-9_-]{32,}`), JWTs (`eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+`), generic `password\s*[:=]\s*['"][^'"]{8,}['"]`, and PEM headers (`-----BEGIN (RSA \|EC \|OPENSSH \|PGP )?PRIVATE KEY-----`). | Must |
| AC-007 | A high-entropy heuristic flags base64-ish or hex strings of 32+ characters with Shannon entropy > 4.5 bits/char, but is suppressed inside known safe contexts (lockfile hashes, git SHAs in commit references, content-addressed identifiers). | Should |
| AC-008 | The catalog lives in a single source file (e.g., `core/knowledge/secret-patterns.md`) so the rule, the deploy gate, and the learning redactor all reference the same definitions. | Must |

### C. `.secretsignore` Template

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-009 | `core/templates/.secretsignore.template` exists and uses gitignore-compatible pattern syntax. | Must |
| AC-010 | Default content covers: `.env`, `.env.*`, `!.env.example`, `*.pem`, `*.key`, `*.cer`, `id_rsa*`, `id_ecdsa*`, `id_ed25519*`, `.aws/`, `.ssh/`, `.gnupg/`, `secrets/`, `credentials*`, `.netrc`, `.pgpass`, `*.kdbx`, `terraform.tfvars`, `*.tfvars.json`. | Must |
| AC-011 | `/add:init` writes `.secretsignore` to the project root if absent; never overwrites an existing file. | Must |
| AC-012 | `/add:init` prints a one-line notice when the file is created: `Wrote .secretsignore (commit this — your team shares the policy).` | Should |

### D. Pre-Commit Grep Gate

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-013 | `core/skills/deploy/SKILL.md` runs a secret scan on staged content (`git diff --cached`) before composing the commit message. | Must |
| AC-014 | The scan applies every pattern from the regex catalog (AC-006) plus the high-entropy heuristic (AC-007). | Must |
| AC-015 | On any match, the gate aborts the commit, prints the file path, line number, matched pattern name (not the matched value), and a remediation suggestion: `git restore --staged {file}` and `add to .gitignore or .secretsignore`. | Must |
| AC-016 | A `--allow-secret` flag exists. To use it the human must type the confirmation phrase `I have verified this is not a real secret` in full — case-sensitive, no abbreviation. | Must |
| AC-017 | The `--allow-secret` invocation is recorded in `.add/observations.md` with timestamp, file, pattern name, and the human's stated reason. | Should |
| AC-018 | The gate honors `.secretsignore` — files matching ignore patterns are never staged for scanning, and if they appear staged anyway (user override), the gate flags them as "this file should not be committed at all." | Should |

### E. Learning / Handoff / Retro Redaction

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-019 | `core/rules/learning.md` (or its post-PR-#6 successor) extends its PII heuristic to call the regex catalog (AC-006) and replace matches with `[REDACTED:{pattern_name}]` at write time, before any append to `.add/learnings.json` or `~/.claude/add/library.json`. | Must |
| AC-020 | The same redaction pass runs when writing `.add/handoff.md`, `.add/retros/*.md`, and dashboard report exports. | Must |
| AC-021 | A redaction event logs to `.add/observations.md` (or a new `.add/redaction-log.json`) so the human can audit what was suppressed without seeing the secret itself. | Should |

### F. Threat Model & Tests

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-022 | `core/knowledge/threat-model.md` (created by the prompt-injection-defense spec) gains a "Secrets Disclosure" section linking to this spec and summarizing the four defenses (read-deny, redact-on-ingest, pre-commit gate, learning redactor). | Must |
| AC-023 | A fixture test suite under `tests/secrets/` includes one positive sample per regex pattern in the catalog and asserts the gate fires; one negative sample per common safe content type (`package-lock.json` SHA, `git log` commit SHAs, UUIDs, base64-encoded asset hashes) and asserts the gate does NOT fire. | Must |
| AC-024 | False-positive rate on a corpus of 10 popular open-source repos' lockfiles is zero. | Should |

## 3. User Test Cases

### TC-001: Agent declines to read `.env`

**Precondition:** Project root contains `.env` with real-looking values. Rule is auto-loaded.
**Steps:**
1. User asks agent: "Read .env and tell me the database URL."
2. Rule fires before the Read tool call.
3. Agent responds explaining the policy and asks for explicit confirmation.
**Expected Result:** Agent does not read `.env`. Surfaces the rule citation. Asks: "Confirm reading .env this once?"
**Maps to:** TBD

### TC-002: Pre-commit gate catches a leaked AWS key

**Precondition:** A developer accidentally stages `config/local.py` containing `AWS_KEY = "AKIAIOSFODNN7EXAMPLE"`.
**Steps:**
1. Agent runs `/add:deploy`.
2. Deploy skill runs the staged-content scan.
3. AWS pattern matches.
**Expected Result:** Commit aborts. Output: `config/local.py:14 — AWS_ACCESS_KEY pattern detected. Run: git restore --staged config/local.py && add to .secretsignore.` No commit is created.
**Maps to:** TBD

### TC-003: `--allow-secret` requires confirmation phrase

**Precondition:** Test fixture file `tests/fixtures/fake_keys.py` contains intentionally-fake `AKIA...EXAMPLE` strings. Gate fires correctly.
**Steps:**
1. User runs `/add:deploy --allow-secret`.
2. Skill prompts for confirmation phrase.
3. User types: "ok"
4. Skill rejects.
5. User types: "I have verified this is not a real secret"
6. Skill accepts and proceeds.
**Expected Result:** Commit only proceeds after the exact phrase. The override is recorded in `.add/observations.md` with timestamp, file, pattern, and reason.
**Maps to:** TBD

### TC-004: Learning redaction

**Precondition:** Agent just verified a deployment. Tool output included `Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature` from a curl response.
**Steps:**
1. Post-deploy checkpoint fires.
2. Agent drafts a learning entry summarizing what worked.
3. Redaction pass runs on the entry body.
**Expected Result:** Stored learning text reads `Bearer [REDACTED:JWT]`. The original token does not appear in `.add/learnings.json`. A redaction event is logged.
**Maps to:** TBD

### TC-005: No false positives on lockfile hashes

**Precondition:** A normal commit includes updates to `package-lock.json` with hundreds of `sha512-...` integrity hashes.
**Steps:**
1. Agent runs `/add:deploy`.
2. Gate scans the staged diff.
3. Lockfile context is detected; entropy heuristic suppressed.
**Expected Result:** Commit proceeds. No false-positive output. No `--allow-secret` needed.
**Maps to:** TBD

### TC-006: `/add:init` writes `.secretsignore`

**Precondition:** Fresh project with no `.secretsignore` file.
**Steps:**
1. User runs `/add:init`.
2. Init copies `core/templates/.secretsignore.template` to `./.secretsignore`.
**Expected Result:** `.secretsignore` exists at project root with default content. One-line notice printed. Re-running `/add:init` does not overwrite.
**Maps to:** TBD

### TC-007: PEM private key in a draft commit

**Precondition:** User accidentally pasted an SSH private key into a markdown doc and staged it.
**Steps:**
1. Agent runs `/add:deploy`.
2. Gate detects `-----BEGIN OPENSSH PRIVATE KEY-----` header.
**Expected Result:** Commit aborts with `PEM_PRIVATE_KEY pattern detected`. Suggestion includes `add *.md path or rotate the key immediately if it was real`.
**Maps to:** TBD

## 4. Data Model

### Secret Pattern Catalog Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Stable identifier used in error messages and redaction tags (e.g., `AWS_ACCESS_KEY`, `JWT`, `STRIPE_LIVE_SECRET`) |
| `regex` | string | Yes | The pattern (PCRE-compatible) |
| `description` | string | Yes | Human-readable description for documentation |
| `provider` | string | No | `aws` \| `github` \| `stripe` \| `openai` \| `anthropic` \| `generic` |
| `confidence` | enum | Yes | `high` (deterministic prefix) \| `medium` (entropy + context) |
| `remediation` | string | Yes | Suggested action (e.g., "rotate key in AWS IAM console immediately") |

### Redaction Log Entry (`.add/redaction-log.json`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `date` | string | Yes | ISO 8601 timestamp |
| `artifact` | string | Yes | Where the redaction occurred: `learning` \| `handoff` \| `retro` \| `dashboard` |
| `pattern_name` | string | Yes | Which pattern matched |
| `count` | integer | Yes | Number of redactions in that write event |
| `source_skill` | string | No | Which skill triggered the write |

### `.secretsignore` Default Content (Excerpt)

```
# Environment files
.env
.env.*
!.env.example
!.env.sample

# Private keys and certs
*.pem
*.key
*.cer
id_rsa*
id_ecdsa*
id_ed25519*

# Credential stores
.aws/
.ssh/
.gnupg/
.netrc
.pgpass
*.kdbx

# Secrets directories
secrets/
credentials*

# Infrastructure
terraform.tfvars
*.tfvars.json
```

## 5. API Contract

N/A — pure markdown/JSON plugin. The "API" surface is the regex catalog file, the rule file, the template file, and the deploy skill behavior.

## 6. UI Behavior

CLI output for the pre-commit gate (example):

```
SECRETS GATE — /add:deploy
Scanning 3 staged files...

  ✗ config/local.py:14 — AWS_ACCESS_KEY pattern
  ✗ docs/setup.md:88 — PEM_PRIVATE_KEY pattern

Commit aborted. Two options:

  1. Remove the secrets:
       git restore --staged config/local.py docs/setup.md
       Add config/local.py to .secretsignore
       Rotate any real secrets immediately

  2. False positive (test fixture, example, etc.):
       /add:deploy --allow-secret
       (you will be asked to type a confirmation phrase)
```

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Agent has already read a secret into context before the rule loaded | Redact at write time; warn human that context may contain leaked data; recommend `/clear` |
| `.secretsignore` doesn't exist | Fall back to built-in default patterns from the template; print one-time notice suggesting `/add:init` |
| User legitimately needs to commit a `.env.example` | `!.env.example` negation in default `.secretsignore` allows it; gate's content scan will not match because example files use placeholder values |
| Regex matches inside a string clearly marked as a test fixture (path contains `test`, `fixture`, `example`, `mock`) | Still flag, but downgrade severity in the message and suggest `--allow-secret` rather than full abort |
| Staged file is binary | Skip content scan; flag if filename matches `.secretsignore` patterns (e.g., `*.kdbx`) |
| Commit gate runs but git is not initialized | Skip silently; first-commit projects shouldn't be blocked |
| High-entropy string is a UUID, git SHA, content hash, or build ID | Suppressed by context heuristic; do not flag |
| Pattern catalog updated in plugin upgrade | Existing `.secretsignore` files left untouched (user owns them); rule reads catalog from plugin so updates flow automatically |
| Two sessions write learnings concurrently and both contain a secret | Both redact independently before write; last-write-wins on the JSON file is acceptable since both wrote redacted text |
| Custom/proprietary secret format not in catalog | Out of scope (see non-goals); user can add patterns to a future `.add/secret-patterns.local.json` (deferred) |

## 8. Dependencies

- `core/rules/secrets-handling.md` — new auto-loaded rule (this spec creates it)
- `core/templates/.secretsignore.template` — new template (this spec creates it)
- `core/knowledge/secret-patterns.md` — new catalog (this spec creates it)
- `core/skills/deploy/SKILL.md` — gains pre-commit grep gate
- `core/skills/init/SKILL.md` (or equivalent) — copies the template on init
- `core/rules/learning.md` — extends PII heuristic to call the regex catalog (coordinate with PR #6 if it lands first)
- `core/knowledge/threat-model.md` — gains "Secrets Disclosure" section (created by `specs/prompt-injection-defense.md`)
- `specs/prompt-injection-defense.md` — companion spec; shares threat model

## 9. Infrastructure Prerequisites

| Category | Requirement |
|----------|-------------|
| Environment variables | N/A |
| Registry images | N/A |
| Cloud quotas | N/A |
| Network reachability | N/A |
| CI status | N/A |
| External secrets | N/A |
| Database migrations | N/A |

**Verification before implementation:** Fixture corpus assembled in `tests/secrets/` covering positive samples for every catalog pattern and negative samples for the top 10 lockfile/hash false-positive sources.

## 10. Non-Goals

- Runtime sandbox or filesystem boundary enforcement (Claude Code's permission system, not ADD's)
- Network egress controls
- Encryption-at-rest for `.add/` files
- Detection of custom or proprietary secret formats not in the public catalog
- Rotating leaked secrets automatically (manual step, recommended in error message)
- Server-side secret scanning (GitHub push protection, GitGuardian) — complementary, not replaced by this spec

## 11. Open Questions

- Should `.secretsignore` be auto-added to `.gitignore` by `/add:init`, or kept committed so the team shares the policy? (Lean: commit it. The patterns are not themselves sensitive, and a shared policy beats a private one.)
- The high-entropy heuristic risks false positives on hashes, UUIDs, base64 commits. What is the right entropy threshold + length floor? (Initial proposal: Shannon entropy > 4.5 bits/char AND length >= 32 AND not inside a lockfile/SHA context. Tune with the false-positive test corpus.)
- Should `/add:learnings stats` (or the dashboard) report "X potential secrets redacted in the last 30 days" as a transparency surface? (Lean: yes, low-cost trust signal.)
- Should the rule allow reading `.env.example` and `.env.sample` without prompt, since they are conventionally placeholder-only? (Lean: yes, allow `*.example` and `*.sample` suffixes by default.)

## 12. Sizing

Small. Estimated 1–1.5 days for the rule + template + grep gate + fixture tests. Suitable for Cycle 1 of M3 — early ship removes a GA blocker quickly.

## 13. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-22 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec interview; companion to prompt-injection-defense |

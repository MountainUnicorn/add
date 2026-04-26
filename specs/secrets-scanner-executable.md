# Spec: Executable Secrets Scanner

**Version:** 0.1.0
**Created:** 2026-04-26
**PRD Reference:** docs/prd.md
**Status:** Draft
**Target Release:** v0.9.2
**Milestone:** none (standalone v0.9.x hardening)
**Depends-on:** `specs/secrets-handling.md` (parent spec)

## 1. Overview

ADD v0.9.0 shipped `core/rules/secrets-handling.md`, the `core/knowledge/secret-patterns.md` regex catalog, a `.secretsignore` template, and a "Pre-commit secrets gate" section in `core/skills/deploy/SKILL.md`. Fixture tests under `tests/secrets-handling/` prove every regex pattern matches its synthesized positive sample and ignores curated negatives. **Nothing in that delivery actually blocks anything at runtime.**

The deploy skill describes the gate as prose the agent is expected to enact. Pattern matches in fixtures do not translate to a runtime block on `git push` or `/add:deploy` of a staged secret. The gate is declarative — and a declarative gate is not a gate. This is finding **F-014** in `specs/plugin-family-release-hardening.md` line 43:

> **F-014 P1 v0.9.0** — Secrets gate remains mostly declarative; tests prove regex fixtures but not staged commit blocking behavior.

This spec closes the gap with a small executable script that any caller — a skill, a hook, a human at the shell — can invoke to scan staged content and exit non-zero on an unsuppressed match. The script is the single point of truth for "does this commit contain a secret?" The deploy skill, the verify skill's quality gates, and a future PreToolUse hook on `git push` all delegate to it. Fixture tests assert the *script's* exit code, not just the catalog's regex shape — meaning we test the actual block, not the description of one.

The work is small (one shell script, fixture tree, three doc edits). The leverage is large: F-014 is one of the v0.9.x P1 release blockers, and shipping it converts the secrets-handling story from "documented intent" to "enforced contract."

### User Story

As a developer using ADD on a real project, I want `/add:deploy` (and any future pre-push hook) to actually abort when I have accidentally staged an AWS access key, so that the protection ADD documents in its rules and skills is the protection I get at the moment a mistake would otherwise leave my workstation.

## 2. Acceptance Criteria

### A. Script Existence and Shape

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | A new executable script lives at `core/lib/scan-secrets.sh`. The path is shared (under `core/lib/`) so both the Claude and Codex runtimes get it via `scripts/compile.py`. | Must |
| AC-002 | The script is pure POSIX shell + standard tools (`grep -E`, `git`, `awk`, `sed`, `find`). No Python, no `jq`-required code paths in the hot path. Optional `jq` use must guard with `command -v jq`. Matches the conventions of `core/lib/impact-hint.sh`. | Must |
| AC-003 | The script has a `set -euo pipefail` header, a usage block, and exit codes documented in the header comment: `0` clean, `1` unsuppressed match (block), `2` invocation error, `3` configuration error (missing catalog). | Must |
| AC-004 | Compile (`scripts/compile.py`) copies `core/lib/scan-secrets.sh` verbatim into `plugins/add/lib/` and `dist/codex/.agents/lib/` with the executable bit preserved. | Must |

### B. Catalog Source

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-005 | The script reads its pattern list from a single canonical file at runtime — not from inline hard-coded patterns. The catalog is the source of truth shared with `core/rules/secrets-handling.md` and the existing fixture suite. | Must |
| AC-006 | The catalog file format is parseable from POSIX shell. The spec ships a new structured catalog at `core/security/secret-patterns.json` (one object per pattern: `name`, `regex`, `provider`, `confidence`, `remediation`). Rationale: parsing a markdown catalog from shell requires fragile regex extraction; a JSON catalog parses with a small `awk` extractor that does not depend on `jq`. The existing `core/knowledge/secret-patterns.md` becomes the human-readable reference and links to `core/security/secret-patterns.json` as the executable source. | Must |
| AC-007 | A drift check script (`scripts/validate-secret-patterns.py`) verifies that every pattern named in `core/knowledge/secret-patterns.md` § 1 has a matching entry in `core/security/secret-patterns.json` with the same `name` and a regex that compiles. CI runs the drift check. | Should |

### C. Inputs and Output Format

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-008 | The script scans `git diff --cached` (staged content) by default — not the working tree, not the whole repo. A `--paths <file...>` flag scans explicit files (used by tests and by direct CLI use); a `--all` flag scans the whole tree (opt-in, slow, documented as audit-only). | Must |
| AC-009 | The script respects a project-level `.secretsignore` file with gitignore-compatible syntax. Files matching ignore patterns are skipped. If a `.secretsignore`-listed path is staged anyway, the script emits a `path: SEC-998: STAGED_IGNORED_PATH: ...` finding with non-zero exit (file should not be committed at all). | Must |
| AC-010 | Each finding is emitted on stdout in the exact form: `path:line: SEC-NNN: <pattern-name>: <preview>`. `SEC-NNN` is a stable numeric code per pattern (mapped 1:1 from the JSON catalog: AWS_ACCESS_KEY=001, GITHUB_TOKEN=002, etc.). `<preview>` is a *redacted* representation — see AC-013. | Must |
| AC-011 | Findings are sorted by `path` then `line`, deterministic across runs. | Should |
| AC-012 | Exit code is non-zero (`1`) if and only if at least one unsuppressed finding exists after applying `.secretsignore`, the trailer-override mechanism (AC-014), and the safe-context entropy suppressions documented in `core/knowledge/secret-patterns.md` § 2. | Must |

### D. Redaction in Output and Logs

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-013 | The `<preview>` field never contains the matched value verbatim. It contains: pattern name, character count of the match, and the first and last 2 characters of the match (e.g. `AWS_ACCESS_KEY (20 chars: AK…LE)`). For PEM keys, only the header line content (`-----BEGIN ... PRIVATE KEY-----`) is shown — body content is dropped. | Must |
| AC-014 | The script writes nothing to disk by default. When invoked with `--audit-log <path>`, it appends one JSONL entry per finding to that path. The entry contains `ts`, `path`, `line`, `code`, `pattern_name`, `preview` (redacted form per AC-013), and `match_chars` — never the secret. | Must |
| AC-015 | The script must never echo the matched value to stderr, even on `--verbose` or `--debug`. The fixture suite includes a "redaction integrity" test that captures stdout+stderr and asserts the synthesized fixture-secret string never appears in either stream. | Must |

### E. Bypass Mechanism (Trailer Override)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-016 | The script honors a commit-trailer override of the form `[ADD-SECRET-OVERRIDE: <reason>]`, mirroring the test-deletion guardrail's `[ADD-TEST-DELETE: ...]` trailer pattern. Source: when scanning `git diff --cached` from inside an in-progress commit (e.g. via `prepare-commit-msg`-style invocation), the script reads `COMMIT_EDITMSG` if `--commit-msg-file <path>` is provided. Outside that context the trailer can also be supplied directly via `--allow <reason>` for non-commit invocations. | Must |
| AC-017 | The override applies *per-pattern-name*, not globally. The trailer must list every pattern code being overridden: `[ADD-SECRET-OVERRIDE: SEC-001 (test fixture for AWS regression test) — see specs/foo.md]`. A single bare `[ADD-SECRET-OVERRIDE: ...]` with no SEC-NNN code does NOT silence findings — it errors with "trailer must enumerate the SEC codes to override." | Must |
| AC-018 | An accepted override is recorded by the *caller* (deploy skill, verify skill, hook), not by the script itself — the script reports the override as accepted in its summary line and exits `0`. The record format is the existing `.add/observations.md` line documented in `secrets-handling.md` AC-017. | Should |
| AC-019 | The `I have verified this is not a real secret` interactive confirmation phrase from the parent spec (AC-016 of `secrets-handling.md`) remains the gate for *deploy-time* overrides initiated by `/add:deploy --allow-secret`. The script-level trailer override is the *automation-friendly* path for cases like the ADD repo's own fixture tests, where the deploy skill is not in the loop. | Should |

### F. Wiring Into Skills and Hooks

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-020 | `core/skills/deploy/SKILL.md` § Pre-commit secrets gate is rewritten to invoke `${ADD_RUNTIME_ROOT}/lib/scan-secrets.sh` instead of describing the scan in prose. The interactive `--allow-secret` confirmation phrase (AC-019) wraps the script — caller invokes script first, on exit-1 prompts the human, on phrase match re-invokes with `--allow "<phrase + reason>"`. | Must |
| AC-021 | `core/skills/verify/SKILL.md` gains **Gate 4.6: Staged-Secret Scan**, inserted between Gate 4.5 (AGENTS.md drift) and Gate 5 (Smoke). Gate 4.6 invokes `scan-secrets.sh` with the staged-diff default. Failure blocks the gate run. | Must |
| AC-022 | `core/rules/secrets-handling.md` § "Template + Deploy-Gate Contracts" is updated to point at the executable: "Pre-commit gate is enforced by `lib/scan-secrets.sh`. Skills and hooks delegate to that script — never re-implement the catalog inline." | Must |
| AC-023 | A new entry in `runtimes/claude/hooks/hooks.json` adds a `PreToolUse` matcher for `Bash` commands containing `git push`, invoking `scan-secrets.sh` and emitting the documented hook-feedback message on non-zero exit. The hook is *advisory* in v0.9.2 (warns, does not block) because hook-blocking semantics are still under review per F-012; v0.10 may upgrade to a hard block. | Should |

### G. Performance and Robustness

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-024 | The script completes in under **2 seconds** on a staged diff of 1,000 files totaling 5 MB of text on a 2024-class developer laptop. Measured by the fixture suite's perf test (`tests/secrets-scanner-executable/test-perf.sh`). | Must |
| AC-025 | Binary files (detected via `git diff --cached --numstat` showing `-` for additions or via `file --mime-type` returning a non-text type) are skipped for content scanning. Their *paths* are still checked against `.secretsignore` (e.g. `*.kdbx`). | Must |
| AC-026 | Files larger than 5 MB after staging are scanned with a soft cap: only the first 5 MB are pattern-matched. The script emits a `WARN: <path>: file truncated for scanning at 5 MB` line on stderr. Configurable via `--max-bytes <N>`. | Should |
| AC-027 | Multiple matches in the same file each emit a separate finding line. There is no per-file dedup — the user needs to see every line. Patterns that match overlapping regions on the same line emit one line per pattern (the higher-confidence pattern listed first). | Must |
| AC-028 | Exit-code stability: a clean run is `0`. A run with one finding is `1`. A run with 100 findings is also `1` (exit code is "block or not," count is on stdout). The script never returns a non-zero exit code on transient failure — IO errors, missing catalog, missing git surface as `2` or `3`. | Must |

### H. Tests

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-029 | A fixture suite at `tests/secrets-scanner-executable/` exercises the script end-to-end. Mirrors the `tests/secrets-handling/` synth-at-runtime pattern: positive fixtures use `<SYNTHESIZED:{NAME}>` placeholders to avoid GitHub Advanced Security push-protection collisions. | Must |
| AC-030 | Required test cases (one per case, asserting exit code + stdout shape): clean diff exits 0; staged AWS key exits 1 with `SEC-001`; staged GitHub token exits 1 with `SEC-002`; `.secretsignore`-matched path skipped (exits 0); `.secretsignore`-listed path that is *staged* exits 1 with `SEC-998`; trailer override with matching SEC code exits 0; trailer override missing the SEC code exits 1; binary file skipped (exits 0); empty diff exits 0; perf budget < 2s on a 1k-file fixture diff. | Must |
| AC-031 | A "redaction integrity" test (per AC-015) runs the script against a fixture file containing every synthesized positive secret, captures stdout + stderr to a buffer, and grep-asserts that no synthesized secret string appears in the buffer. Asserts the redacted preview format from AC-013 is correct. | Must |
| AC-032 | The fixture runner integrates with `compile.py --check` and `bash tests/secrets-scanner-executable/test-scan-secrets.sh` runs in CI alongside the existing test-filter-learnings hook test. | Must |

## 3. User Test Cases

### TC-001: Clean diff passes silently

**Precondition:** Project has staged changes consisting of a `README.md` edit and a `src/foo.py` edit. Neither contains any pattern from the catalog.

**Steps:**
1. Run `core/lib/scan-secrets.sh` (no args; defaults to staged diff).
2. Capture exit code, stdout, stderr.

**Expected Result:** Exit code `0`. Stdout is empty (or one informational line: `scan-secrets: 2 files scanned, 0 findings`). Stderr is empty. Wall time well under 2s.

**Maps to:** AC-008, AC-012, AC-024

### TC-002: Staged AWS access key blocks

**Precondition:** Developer has staged `config/local.py` containing a synthesized AWS access-key string.

**Steps:**
1. Agent runs `/add:deploy`.
2. Deploy skill invokes `scan-secrets.sh`.
3. Script finds the AWS key on line 14.

**Expected Result:** Script exits `1`. Stdout contains exactly `config/local.py:14: SEC-001: AWS_ACCESS_KEY: AWS_ACCESS_KEY (20 chars: AK…LE)` (preview redacted per AC-013). Deploy skill aborts the commit and prints the remediation block from existing SKILL.md prose. The literal AWS-key string appears nowhere in any output stream.

**Maps to:** AC-010, AC-012, AC-013, AC-015, AC-020

### TC-003: `.secretsignore` skips a path

**Precondition:** Project root has `.secretsignore` listing `tests/fixtures/*.txt`. A staged file `tests/fixtures/fake_keys.txt` contains a synthesized AWS key.

**Steps:**
1. Run `scan-secrets.sh`.
2. Script reads `.secretsignore`.
3. Path `tests/fixtures/fake_keys.txt` matches and is skipped.

**Expected Result:** Exit code `0`. Stdout shows `tests/fixtures/fake_keys.txt skipped (matched .secretsignore: tests/fixtures/*.txt)`. The file's content is never read.

**Maps to:** AC-009, AC-012

### TC-004: Trailer override unblocks an intentional fixture commit

**Precondition:** Inside the ADD repo itself, the test-suite is committing a new positive fixture for `SEC-001`. The commit message contains the trailer `[ADD-SECRET-OVERRIDE: SEC-001 (positive fixture for AWS regex test)]`. The synthesized AWS-key-shaped string is in `tests/secrets-scanner-executable/fixtures/positive/aws.txt`.

**Steps:**
1. Stage the new fixture.
2. Run `scan-secrets.sh --commit-msg-file .git/COMMIT_EDITMSG`.

**Expected Result:** Exit code `0`. Stdout includes `tests/secrets-scanner-executable/fixtures/positive/aws.txt:1: SEC-001: AWS_ACCESS_KEY: AWS_ACCESS_KEY (20 chars: AK…LE)` and a trailing `OVERRIDE ACCEPTED: SEC-001 — (positive fixture for AWS regex test)`. Caller still records the override per AC-018 to `.add/observations.md`.

**Maps to:** AC-016, AC-017, AC-018

### TC-005: Trailer override missing SEC code is rejected

**Precondition:** Same as TC-004 but the trailer reads `[ADD-SECRET-OVERRIDE: it's just a fixture]` with no `SEC-NNN` enumeration.

**Steps:**
1. Stage the file.
2. Run `scan-secrets.sh --commit-msg-file .git/COMMIT_EDITMSG`.

**Expected Result:** Exit code `1`. Stderr contains `error: ADD-SECRET-OVERRIDE trailer must enumerate the SEC codes to override (e.g. SEC-001)`. The blocking finding is still listed on stdout.

**Maps to:** AC-017

### TC-006: Verify Gate 4.6 surfaces a staged secret as a gate failure

**Precondition:** Developer is iterating on a feature; they run `/add:verify` before committing. A staged file contains a synthesized GitHub token.

**Steps:**
1. Run `/add:verify` at the deploy level (Gate 4.6 active).
2. Verify skill invokes `scan-secrets.sh`.
3. Script returns exit `1`.

**Expected Result:** Verify reports `Gate 4.6 (Staged-Secret Scan): FAIL — config/api.py:8: SEC-002: GITHUB_TOKEN: GITHUB_TOKEN (40 chars: gh…X9)`. Overall verify run exits non-zero. Subsequent gates (Gate 5 Smoke) still run unless the user halts — verify's existing gate-isolation behavior is unchanged.

**Maps to:** AC-021

### TC-007: Performance — 1,000 staged files complete under 2 seconds

**Precondition:** Synthetic fixture diff with 1,000 small text files, none containing secrets.

**Steps:**
1. Time `scan-secrets.sh --paths <generated-list>`.

**Expected Result:** Wall time under 2,000 ms. Exit `0`. No findings. Memory peak under 100 MB.

**Maps to:** AC-024

## 4. Data Model

### Pattern Catalog Entry (`core/security/secret-patterns.json`)

```json
{
  "version": "1.0.0",
  "patterns": [
    {
      "code": "SEC-001",
      "name": "AWS_ACCESS_KEY",
      "regex": "AKIA[0-9A-Z]{16}",
      "provider": "aws",
      "confidence": "high",
      "remediation": "Rotate the key in the AWS IAM console immediately."
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | Yes | Stable numeric code emitted in findings (`SEC-NNN`). 1:1 with `name`. Reserved: `SEC-998` (staged ignored path), `SEC-999` (entropy heuristic). |
| `name` | string | Yes | Human-readable name from `core/knowledge/secret-patterns.md`. |
| `regex` | string | Yes | POSIX ERE pattern (compatible with `grep -E`). |
| `provider` | string | Yes | Free-form provider tag for downstream consumers. |
| `confidence` | enum | Yes | `high` \| `medium`. Drives the entropy-suppression decision in TC-007. |
| `remediation` | string | Yes | Human-readable remediation guidance. Echoed by the caller, never the script. |

### Finding (stdout line)

```
<path>:<line>: <code>: <pattern-name>: <redacted-preview>
```

| Field | Type | Description |
|-------|------|-------------|
| `path` | string | Repo-relative path of the staged file. |
| `line` | integer | 1-based line number within the staged content. |
| `code` | string | `SEC-NNN`. |
| `pattern-name` | string | Catalog `name`. |
| `redacted-preview` | string | Per AC-013: `<NAME> (<N> chars: <first-2>…<last-2>)`. |

### Audit Log Entry (`--audit-log` JSONL)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts` | string | Yes | ISO 8601 UTC. |
| `path` | string | Yes | Repo-relative path. |
| `line` | integer | Yes | Line number. |
| `code` | string | Yes | `SEC-NNN`. |
| `pattern_name` | string | Yes | Catalog name. |
| `preview` | string | Yes | Redacted form per AC-013 — never the secret. |
| `match_chars` | integer | Yes | Length of the match (for triage). |
| `override_accepted` | boolean | No | Present and `true` when a trailer override neutralized this finding. |

## 5. API Contract

The "API" is the script's CLI surface:

```
core/lib/scan-secrets.sh [OPTIONS]

Options:
  --paths FILE...           Scan listed files instead of git diff --cached
  --all                     Scan the entire working tree (audit-only, slow)
  --commit-msg-file PATH    Read trailer override from commit message file
  --allow REASON            Inline override (must include SEC-NNN codes)
  --audit-log PATH          Append JSONL findings to PATH (redacted)
  --max-bytes N             Per-file scan size cap in bytes (default: 5242880)
  --verbose                 Print scan progress to stderr (no secret values)
  -h, --help                Print usage

Exit codes:
  0  — clean (no unsuppressed findings)
  1  — at least one unsuppressed finding (caller must block)
  2  — invocation error (bad flag, missing file with --paths)
  3  — configuration error (catalog missing or unparseable)
```

## 6. UI Behavior

The script itself has no UI; it is a CLI tool. Caller skills present findings through their existing text UI, identical to the current declarative output documented in `core/skills/deploy/SKILL.md`. The change is purely in *who* generated the finding lines (the script, not the agent's prose).

Verify's Gate 4.6 output shape:

```
━━━ GATE 4.6 — STAGED-SECRET SCAN ━━━
Scanning 12 staged files...

  ✗ config/api.py:8 — SEC-002: GITHUB_TOKEN
  ✗ scripts/seed.py:42 — SEC-001: AWS_ACCESS_KEY

Gate 4.6: FAIL (2 findings)

Run `/add:deploy` and choose remediation, or commit with
[ADD-SECRET-OVERRIDE: SEC-001 SEC-002 (reason)] for a non-commit override.
```

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| `core/security/secret-patterns.json` missing or unparseable | Exit `3`. Stderr: `scan-secrets: cannot read pattern catalog at <path>; aborting`. Caller treats as a hard fail (defense-in-depth: silent script disablement is the worst outcome). |
| `.secretsignore` missing | Fall back to scanning all staged files; emit one-line stderr advisory `info: no .secretsignore found; consider /add:init to create one`. Do not block. |
| `.secretsignore` malformed (unsupported syntax) | Skip the bad line with a stderr warning. Continue scanning. |
| Binary file staged (`-` in `git diff --numstat`) | Skip content scan (AC-025). Path still checked against `.secretsignore`. |
| Empty staged diff | Exit `0`. One stderr line: `info: no staged changes`. |
| File deleted in staged diff | No content scan needed (deletion can't introduce a secret). |
| Renamed file | Scan as if newly added (the diff is post-rename content). |
| Match spans multiple lines (PEM body, multi-line JWT) | Pattern matches on first line of header (per AC-013); body is dropped from preview. |
| Two patterns match the same substring (e.g. an OpenAI key inside a JWT) | Emit both findings, sorted by confidence (`high` first), then by code. |
| Trailer override lists a SEC-NNN that produced zero findings | No-op; do not warn (overrides are forward-compatible — committers can future-proof a fixture commit). |
| Trailer present but `--commit-msg-file` not passed | Trailer is ignored. Document loudly in skill docs that the deploy skill always passes `--commit-msg-file`. |
| Concurrent invocations (e.g. parallel verify + manual run) | Each run is independent; no shared state. The optional `--audit-log` append uses POSIX `O_APPEND` for atomicity. |
| Symlink in staged set pointing outside repo | Skip with a stderr warning. Out-of-tree paths are not scanned. |
| `git` not on PATH or no repo | Exit `2`. Stderr: `error: git not available or not a repository`. |
| Path containing newline or unusual characters | Quote in finding output using `printf %q`-equivalent shell escaping. |

## 8. Dependencies

- `core/knowledge/secret-patterns.md` — remains the human-readable reference; gains a header note pointing at `core/security/secret-patterns.json` as the executable source.
- `core/security/secret-patterns.json` — **new**, executable catalog (this spec creates it).
- `core/lib/scan-secrets.sh` — **new**, the executable scanner (this spec creates it).
- `core/skills/deploy/SKILL.md` — § Pre-commit secrets gate rewritten to delegate to the script.
- `core/skills/verify/SKILL.md` — gains Gate 4.6.
- `core/rules/secrets-handling.md` — § Template + Deploy-Gate Contracts updated to cite the script.
- `runtimes/claude/hooks/hooks.json` — gains an advisory PreToolUse matcher for `git push` (AC-023, Should).
- `scripts/compile.py` — must copy `core/lib/scan-secrets.sh` and `core/security/secret-patterns.json` into both runtime outputs with executable bit preserved.
- `scripts/validate-secret-patterns.py` — **new**, drift check (AC-007, Should).
- `tests/secrets-scanner-executable/` — **new** fixture suite.
- Parent spec: `specs/secrets-handling.md` — this spec is its executable enforcement.

## 9. Infrastructure Prerequisites

| Category | Requirement |
|----------|-------------|
| Environment variables | N/A. The script is self-contained. |
| Registry images | N/A. |
| Cloud quotas | N/A. |
| Network reachability | N/A — purely local. |
| CI status | The new fixture suite is added to `.github/workflows/*.yml` alongside `test-filter-learnings.sh`. |
| External secrets | N/A. |
| Database migrations | N/A. |

**Verification before implementation:** Confirm the existing `tests/secrets-handling/` synthesizer pattern works inside the new fixture tree (positive fixtures use `<SYNTHESIZED:{NAME}>` placeholders so the repo never contains literal secret-shaped strings — required to avoid GitHub Advanced Security push-protection collisions, an issue Swarm B hit during v0.9.0 implementation).

## 10. Non-Goals

- **Not a replacement for `gitleaks`, `detect-secrets`, or GitHub push protection.** The script is the floor, not the ceiling. Projects with serious threat models should layer enterprise scanners on top.
- **Whole-repo or git-history scanning** is not the default. `--all` exists but is documented as audit-only; this spec ships staged-diff scanning as the runtime gate.
- **Auto-rotation of leaked secrets** is out of scope. The script reports; the human rotates. Remediation guidance is text in the catalog, not an automated action.
- **Custom user-local pattern catalogs** (`.add/secret-patterns.local.json`) are deferred — already noted in the parent spec's Open Questions.
- **Hard-blocking PreToolUse hook on `git push`.** v0.9.2 ships an *advisory* warning hook; hard blocks await F-012 resolution on hook-feedback semantics.
- **Server-side scanning, CI-only enforcement, or pre-receive hooks.** Out of scope; pair with GitHub push protection on the remote side.
- **Encrypting the audit log.** The audit log contains redacted previews and metadata only — no secret material — so at-rest encryption is the host filesystem's job.

## 11. Open Questions

| ID | Question | Lean |
|----|----------|------|
| Q-001 | Catalog format: shipping `core/security/secret-patterns.json` as a new file vs. parsing the existing markdown catalog from shell. | **Ship the JSON file.** Markdown parsing from shell is fragile; JSON parses with `awk` in a few lines and gives stable structure. The drift check (AC-007) keeps the markdown reference truthful. |
| Q-002 | False-positive policy: should the entropy heuristic (`SEC-999`) block by default, or surface as a warning? | **Warn-only in v0.9.2.** Heuristic accuracy is not yet measured at scale; blocking on entropy alone risks user trust. v0.10 may upgrade after the false-positive corpus expands. |
| Q-003 | Soft-fail runtime ceiling: if the script exceeds `--max-bytes` on a single file, should it block or warn? | **Warn and continue.** A 5 MB file is unusual but legitimate (vendored data, generated tables). The truncated scan still catches secrets in the first 5 MB; the warning lets the human decide. |
| Q-004 | Should `core/security/` be a new top-level directory, or should the JSON catalog live under `core/knowledge/`? | **New `core/security/` directory.** Keeps execution-grade artifacts separate from human-readable knowledge. Sets up future security-tooling artifacts (allow-lists, threat-model JSON) in one place. |
| Q-005 | When the deploy skill calls the script, should the script *also* write to `.add/observations.md` for accepted overrides, or leave that to the caller? | **Leave it to the caller.** The script must remain side-effect-light so it can run inside hooks, CI, and tests with no `.add/` write expectation. |

## 12. Sizing

**Small to Medium.** ~1.5–2 days of focused work:

- ~0.25d: ship `core/security/secret-patterns.json` derived from existing markdown catalog.
- ~0.5d: write `core/lib/scan-secrets.sh` (POSIX shell, awk catalog reader, grep loop, redaction formatter, override parser).
- ~0.25d: write fixture tree under `tests/secrets-scanner-executable/` (synthesizer, positive/negative fixtures, perf harness, redaction-integrity check).
- ~0.25d: rewrite deploy SKILL.md § Pre-commit secrets gate to delegate; add Gate 4.6 to verify SKILL.md; update rule pointer.
- ~0.25d: drift-check script + CI wiring + advisory PreToolUse hook entry.

Closes F-014 (P1) standalone — no milestone dependency. Suitable for a v0.9.2 release.

## 13. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-26 | 0.1.0 | abrooke + Claude | Initial spec for F-014 executable secrets scanner. Closes the declarative-gate gap surfaced by the plugin-family review. |

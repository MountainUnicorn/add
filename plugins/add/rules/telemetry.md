---
autoload: true
maturity: beta
---

# ADD Rule: Structured Telemetry (JSONL)

Every skill invocation appends one JSONL line to `.add/telemetry/{YYYY-MM-DD}.jsonl` aligned with **OpenTelemetry GenAI semantic conventions**. Write-side only — telemetry is **never read into LLM context**. It exists for export, dashboard aggregation, and audit.

## Context Boundary (AC-004)

Never `Read` `.add/telemetry/*` from any skill body. The file is produced by skills, consumed only by `/add:dashboard`, external collectors, and auditors.

## File Location & Rotation (AC-001, AC-005, AC-006)

Default daily: `.add/telemetry/{YYYY-MM-DD}.jsonl` (UTC). Hourly opt-in via `.add/config.json:telemetry.rotation = "hourly"` → `.add/telemetry/{YYYY-MM-DD-HH}.jsonl`. Create the directory on first emission. Append-only; pruning is per-file (AC-003).

## Line Format (AC-002)

One complete JSON object per line, terminated by a single `\n`. No multi-line entries, no trailing commas. Canonical examples: `core/templates/telemetry.jsonl.template`.

## Schema

**Required** on every line:

| Field | Type | Notes |
|-------|------|-------|
| `ts` | string | ISO 8601 UTC, post-flight |
| `session_id` | string | Claude Code session ID or UUIDv4; shared across nested skills |
| `skill` | string | Skill name without namespace |
| `skill_version` | string | ADD version |
| `gen_ai.system` | string | Provider, e.g. `anthropic` |
| `gen_ai.request.model` | string | Model requested |
| `gen_ai.response.model` | string | Model that responded |
| `gen_ai.operation.name` | string | `skill_invocation` or `skill_invocation.nested` (AC-011) |
| `gen_ai.usage.input_tokens` | number\|null | `null` when unknown (AC-018) |
| `gen_ai.usage.output_tokens` | number\|null | `null` when unknown (AC-018) |
| `duration_ms` | number | Wall-clock |
| `outcome` | enum | `success` \| `failed` \| `aborted` \| `partial` (AC-010) |
| `files_touched` | string[] | Deduplicated repo-relative paths; SHA-256-hashed when `redact_files_touched: true` (AC-013) |
| `tool_calls` | object[] | `[{tool, count}]` aggregated, never per-call (AC-012) |

**Optional** (omit or set `null`):

| Field | Type | Notes |
|-------|------|-------|
| `gen_ai.usage.cache_read_input_tokens` | number\|null | Model-reported cache hit tokens (AC-009, cache AC-022) |
| `gen_ai.usage.cache_creation_input_tokens` | number\|null | Model-reported cache write tokens (AC-009, cache AC-022) |
| `cache_hit_ratio` | number\|null | Derived: `cache_read / (cache_read + cache_creation + uncached_input)` (cache AC-024) |
| `error` | string | On `outcome != "success"`, truncated to 500 chars (AC-010) |
| `spec_id` | string | Spec path when applicable |
| `ac_completed` | string[] | AC IDs completed this invocation |

## Null Semantics (AC-018, cache AC-023)

Unknown token/cache values emit `null` — not `0`. Aggregation distinguishes "unknown" from "zero". Missing fields never raise; the skill continues.

## Pre-Flight / Post-Flight Contract (AC-014..AC-017)

**Pre-flight** (after config/learnings read): capture `start_ts`, `session_id`, `skill`, `skill_version`, `spec_id`. **Post-flight** (final step, including on failure): append one line with `duration_ms`, `outcome`, `files_touched`, `tool_calls`, and token/cache counts from session metadata (else `null`). On failure or abort, still emit — `outcome: "failed"` or `"aborted"` plus `error`. No skill exits silently.

Every ADD SKILL.md should reference this rule in its pre-flight block (implicit via autoload today; explicit `@reference core/rules/telemetry.md` sweep is a deferred post-M3 follow-up).

## Outcomes (AC-010)

`success` — AC(s) completed, verification clean. `failed` — error hit; `error` required. `aborted` — user stop. `partial` — some ACs done, some deferred.

## Configuration (AC-019, AC-027)

`.add/config.json:telemetry`:

```json
{"enabled": true, "rotation": "daily", "retention_days": 90, "redact_files_touched": false, "commit_to_git": true}
```

When `enabled: false`, **no emission occurs and no telemetry directory is created** (AC-019).

## Concurrent Writes (AC-030)

POSIX `O_APPEND`: line-buffered writes under 4KB are atomic on macOS/Linux. Entries are typically 600-900 bytes. Windows `fcntl` fallback is v0.9.x scope.

## Retention (AC-028)

Files older than `telemetry.retention_days` (default 90) are deleted during the canonical archive pass (e.g. `/add:learnings archive`). Boundary is inclusive.

## Git Semantics (AC-029)

`telemetry.commit_to_git: true` (default) — `.add/telemetry/` is committed. `false` — add `.add/telemetry/` to `.gitignore` (template follow-up).

## OTel Alignment & Export (AC-025, AC-026)

Field names match the OTel GenAI conventions directly. Collectors (Datadog, Honeycomb, Helicone, Langfuse, Braintrust, Vector, otel-collector) ingest with no ADD-side translation.

```bash
cat .add/telemetry/*.jsonl | jq -c '.' | vector --config otel.toml
```

ADD ships no collector code; export pipeline is the user's choice.

## References

- OpenTelemetry GenAI semantic conventions (stable March 2026)
- NIST AI Agent Standards Initiative; EU AI Act (Aug 2026)
- v0.8 `learnings-active.md` — cache-friendly companion-view precedent
- `specs/telemetry-jsonl.md`; `specs/cache-discipline.md` AC-022..024

# Spec: Telemetry JSONL — Per-Skill Trace Recording

**Version:** 0.1.0
**Created:** 2026-04-22
**PRD Reference:** docs/prd.md
**Status:** Complete
**Target Release:** v0.9.0
**Shipped-In:** v0.9.0
**Last-Updated:** 2026-04-22
**Milestone:** M3-pre-ga-hardening

## 1. Overview

ADD writes learnings, handoffs, retro logs, and away logs — but has no structured per-skill trace recording what actually happened: which model ran, how many tokens it cost, which files it touched, which tools it called, and how it ended. Without that data, `/add:dashboard` shows counts but not cost trends, `/add:retro` runs on human recall instead of evidence, and basic audit questions ("what did the agent do during the August cycle?") have no answer.

This spec adds a single append-only JSONL stream at `.add/telemetry/{YYYY-MM-DD}.jsonl` — one line per skill invocation — using the **OpenTelemetry GenAI semantic conventions** (`gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.operation.name`, etc., stabilizing March 2026). Aligning to the OTel spec means downstream collectors — Datadog, Honeycomb, Helicone, Langfuse, Braintrust — ingest the file natively via a thin adapter, with no ADD-side dependency. The spec ships zero collector code and recommends `vector` or `otel-collector` for projects that want to forward data.

The format is pure write-side: telemetry is **never read into LLM context**. It exists for export, dashboards, and audit. This separation matters — the **EU AI Act** (effective August 2026) and the **NIST AI Agent Standards Initiative** (Jan-Feb 2026) both name auditable agent activity logs as a required deliverable for production AI systems, and ADD's contribution is the simplest possible standards-aligned format that any project can adopt with no infrastructure.

### User Stories

**Story 1:** As a project owner, I want to see real cost and velocity trends per skill, per cycle, and per spec on the dashboard, so I can attribute spend to features and spot model regressions.

**Story 2:** As a compliance reviewer, I want a per-day append-only log of every agent invocation with model, tokens, and outcome, so I can answer audit questions without reconstructing history from chat transcripts.

**Story 3:** As an ops engineer, I want to pipe ADD telemetry into our existing OTel collector with no custom code, so AI agent activity flows into the same observability stack as the rest of the system.

## 2. Acceptance Criteria

### A. File Format & Location

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | Telemetry is written to `.add/telemetry/{YYYY-MM-DD}.jsonl` with one JSON object per line. Files rotate daily by default (UTC date). | Must |
| AC-002 | Each line is a complete, parseable JSON object terminated by a single `\n`. No multi-line entries, no trailing commas. | Must |
| AC-003 | Files are append-only — entries are never modified or deleted in place. Pruning operates at file granularity (delete the whole day's file). | Must |
| AC-004 | Telemetry files are **never read into LLM context** by any skill or rule. They exist solely for export, dashboard aggregation, and audit. | Must |
| AC-005 | If `.add/telemetry/` does not exist when the first emission occurs, it is created automatically. | Must |
| AC-006 | Optional opt-in to hourly rotation via `telemetry.rotation: "hourly"` in `.add/config.json`. File pattern becomes `.add/telemetry/{YYYY-MM-DD-HH}.jsonl`. | Should |

### B. Schema (OpenTelemetry GenAI Aligned)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-007 | Each entry includes the OTel GenAI required fields: `gen_ai.system`, `gen_ai.request.model`, `gen_ai.response.model`, `gen_ai.operation.name`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`. | Must |
| AC-008 | Each entry includes ADD-specific fields: `ts` (ISO 8601 UTC), `session_id`, `skill`, `skill_version`, `duration_ms`, `outcome`, `files_touched`, `tool_calls`, `spec_id` (optional), `ac_completed` (optional). | Must |
| AC-009 | Cache token fields are emitted when reported by the model: `gen_ai.usage.cache_read_input_tokens`, `gen_ai.usage.cache_creation_input_tokens`. Omitted when not available rather than zero-padded. | Should |
| AC-010 | Valid `outcome` values: `"success"`, `"failed"`, `"aborted"`, `"partial"`. On `"failed"`, an `error` field carries the error message (truncated to 500 chars). | Must |
| AC-011 | `gen_ai.operation.name` is `"skill_invocation"` for top-level skill runs. Sub-operations (e.g. nested skill calls) use `"skill_invocation.nested"`. | Should |
| AC-012 | `tool_calls` is an array of `{tool, count}` objects aggregated per invocation — not per-call detail (avoids file bloat). | Must |
| AC-013 | `files_touched` is a deduplicated list of repo-relative paths. When `telemetry.redact_files_touched: true`, paths are replaced with SHA-256 hashes. | Should |

### C. Emission Discipline

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-014 | New rule `core/rules/telemetry.md` (under 80 lines) defines the schema, file location, and emission protocol — referenced by all skills. | Must |
| AC-015 | At skill pre-flight, the agent captures `start_ts`, `session_id`, `skill`, `skill_version`, and `spec_id` (if applicable) into ephemeral state. | Must |
| AC-016 | At skill post-flight, the agent appends a complete entry with `duration_ms`, `outcome`, token counts (read from Claude Code session metadata when available), `files_touched`, and `tool_calls`. | Must |
| AC-017 | On skill failure or abort, a telemetry line is still written with `outcome: "failed"` or `"aborted"` and any captured state. No skill exits silently. | Must |
| AC-018 | Token counts that cannot be determined from session metadata are emitted as `null` rather than `0`, so aggregations distinguish "unknown" from "zero". | Should |
| AC-019 | When `telemetry.enabled: false` in `.add/config.json`, no emission occurs and no telemetry directory is created. | Must |

### D. Dashboard Integration

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-020 | `core/skills/dashboard/SKILL.md` gains a "Cost & Velocity" panel that aggregates `.add/telemetry/*.jsonl` across the project's history. | Must |
| AC-021 | Panel shows per-skill totals: invocation count, total input/output tokens, total cache reads, total duration, success rate. | Must |
| AC-022 | Panel shows per-cycle totals (joined via spec_id → cycle membership) and per-spec totals (grouped by `spec_id`). | Must |
| AC-023 | Panel includes a trend chart over time as inline SVG — no JavaScript dependency. X-axis: day. Y-axes: tokens (left) and invocations (right). | Should |
| AC-024 | Dashboard reader streams JSONL line-by-line and tolerates malformed lines (skip and warn) so a single bad entry does not break aggregation. | Must |

### E. Export Path

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-025 | Documentation at `core/skills/dashboard/SKILL.md` (or a sibling skill doc) shows the recommended export pattern using `vector` or the OTel collector — no code shipped. Example: `cat .add/telemetry/*.jsonl \| jq -c '.' \| otelcli ingest`. | Must |
| AC-026 | Because the schema uses OTel GenAI field names directly, downstream collectors (Datadog, Honeycomb, Helicone, Langfuse, Braintrust) ingest entries without ADD-side translation. | Must |

### F. Config & Retention

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-027 | `.add/config.json` schema gains a `telemetry` block: `{enabled: true, rotation: "daily", retention_days: 90, redact_files_touched: false, commit_to_git: true}`. | Must |
| AC-028 | Retention pruning runs as part of `/add:learnings archive` (or the canonical archive pass) — files older than `retention_days` are deleted. Default 90 days. | Must |
| AC-029 | When `telemetry.commit_to_git: true` (default), `.add/telemetry/` is committed for audit. When `false`, `.gitignore` template includes `.add/telemetry/`. | Must |
| AC-030 | Concurrent writes from parallel agents use `O_APPEND` semantics; line-buffered writes under 4KB are atomic on POSIX. Writes larger than 4KB are split across separate lines (single-skill emission stays well under). | Must |

## 3. User Test Cases

### TC-001: Skill emits telemetry on success

**Precondition:** Project has telemetry enabled (default). No prior telemetry file for today.
**Steps:**
1. Agent runs `/add:tdd-cycle specs/foo.md`
2. Skill completes successfully, touching `specs/foo.md` and `src/foo.py`
3. Post-flight emission appends one line to `.add/telemetry/2026-04-22.jsonl`
**Expected Result:** File exists with one line. JSON parses. Required OTel fields present. `outcome: "success"`. `files_touched` lists the two files. `spec_id: "specs/foo.md"`.
**Maps to:** TBD

### TC-002: Skill emits telemetry on failure

**Precondition:** Telemetry enabled. Test will be made to fail (e.g., spec file missing).
**Steps:**
1. Agent runs `/add:plan specs/missing.md`
2. Skill fails because spec doesn't exist
3. Post-flight emission appends a line with `outcome: "failed"` and an `error` message
**Expected Result:** Telemetry line written despite failure. `outcome: "failed"`. `error` field present and truncated to 500 chars max.
**Maps to:** TBD

### TC-003: Dashboard aggregates telemetry into Cost & Velocity panel

**Precondition:** `.add/telemetry/` contains 14 days of files with ~80 entries total across multiple skills and specs.
**Steps:**
1. Run `/add:dashboard`
2. Dashboard reads all JSONL files
3. Aggregates per-skill, per-cycle, per-spec
4. Renders inline SVG trend chart for the 14-day window
**Expected Result:** HTML dashboard contains a "Cost & Velocity" panel with three tables (per-skill, per-cycle, per-spec) and one SVG trend chart. No JavaScript loaded.
**Maps to:** TBD

### TC-004: Telemetry never enters LLM context

**Precondition:** `.add/telemetry/` contains 30+ days of files (multiple MB total).
**Steps:**
1. Agent runs any ADD skill
2. Skill pre-flight reads config, learnings, observations as usual
3. No skill or rule reads telemetry files
**Expected Result:** Context window contains zero bytes of telemetry data. Confirmed via instrumentation (no Read tool calls against `.add/telemetry/*`).
**Maps to:** TBD

### TC-005: Concurrent writes from parallel agents

**Precondition:** Telemetry enabled. Three subagents running in parallel, each completing a skill within ~100ms of each other.
**Steps:**
1. Three agents finish near-simultaneously
2. Each appends a telemetry line to today's file
3. File is read back
**Expected Result:** Three valid JSON lines present. No interleaved/corrupted lines. Order may vary.
**Maps to:** TBD

### TC-006: Retention pruning removes old files

**Precondition:** `.add/telemetry/` has files dated 100, 90, 89, and 1 day old. `retention_days: 90`.
**Steps:**
1. Run `/add:learnings archive` (or canonical archive trigger)
2. Pruner deletes files older than 90 days
**Expected Result:** Files at 100 days are deleted. Files at 89 and 1 day remain. The 90-day-old file is kept (boundary inclusive).
**Maps to:** TBD

### TC-007: Export to OTel collector

**Precondition:** `vector` or `otel-collector` installed locally with a stdout sink configured. Telemetry directory has ~50 entries.
**Steps:**
1. User runs documented export command: `cat .add/telemetry/*.jsonl | jq -c '.' | vector --config otel.toml`
2. Vector ingests each line as a GenAI span
3. Stdout sink emits the parsed spans
**Expected Result:** All 50 entries appear as OTel GenAI spans with no field-name translation needed. `gen_ai.request.model` and friends map directly.
**Maps to:** TBD

### TC-008: Telemetry disabled

**Precondition:** `.add/config.json` sets `telemetry.enabled: false`.
**Steps:**
1. Agent runs any skill
2. Skill completes normally
**Expected Result:** No telemetry directory created. No telemetry file written. Skill behavior otherwise identical.
**Maps to:** TBD

## 4. Data Model

### TelemetryEntry (one JSON object per JSONL line)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts` | string | Yes | ISO 8601 UTC timestamp of emission (post-flight) |
| `session_id` | string | Yes | UUID — Claude Code session ID if available, else ADD-generated UUIDv4 |
| `skill` | string | Yes | Skill name without namespace, e.g. `tdd-cycle` |
| `skill_version` | string | Yes | ADD version that produced the entry, e.g. `0.9.0` |
| `gen_ai.system` | string | Yes | Provider, e.g. `anthropic` |
| `gen_ai.request.model` | string | Yes | Model requested, e.g. `claude-opus-4-7` |
| `gen_ai.response.model` | string | Yes | Model that responded (may differ from request) |
| `gen_ai.operation.name` | string | Yes | `skill_invocation` or `skill_invocation.nested` |
| `gen_ai.usage.input_tokens` | number\|null | Yes | API-reported input tokens; `null` if unknown |
| `gen_ai.usage.output_tokens` | number\|null | Yes | API-reported output tokens; `null` if unknown |
| `gen_ai.usage.cache_read_input_tokens` | number | No | Cache hit tokens (omit when not reported) |
| `gen_ai.usage.cache_creation_input_tokens` | number | No | Cache write tokens (omit when not reported) |
| `duration_ms` | number | Yes | Wall-clock duration of the skill invocation |
| `outcome` | enum | Yes | `success` \| `failed` \| `aborted` \| `partial` |
| `error` | string | No | Truncated error message when `outcome != success` |
| `files_touched` | string[] | Yes | Deduplicated repo-relative paths (or SHA-256 hashes if redacted) |
| `tool_calls` | object[] | Yes | Aggregated per-tool counts: `[{tool: "Read", count: 4}, ...]` |
| `spec_id` | string | No | Path to the spec being worked on, e.g. `specs/foo.md` |
| `ac_completed` | string[] | No | AC IDs marked complete during this invocation |

### Example Entry

```json
{
  "ts": "2026-04-22T19:51:03Z",
  "session_id": "8f3a91e2-1b4c-4d5e-9f6a-7b2c3d4e5f60",
  "skill": "tdd-cycle",
  "skill_version": "0.9.0",
  "gen_ai.system": "anthropic",
  "gen_ai.request.model": "claude-opus-4-7",
  "gen_ai.response.model": "claude-opus-4-7",
  "gen_ai.usage.input_tokens": 12450,
  "gen_ai.usage.output_tokens": 3210,
  "gen_ai.usage.cache_read_input_tokens": 8340,
  "gen_ai.usage.cache_creation_input_tokens": 0,
  "gen_ai.operation.name": "skill_invocation",
  "duration_ms": 41200,
  "outcome": "success",
  "files_touched": ["specs/foo.md", "src/foo.py"],
  "tool_calls": [{"tool": "Read", "count": 4}, {"tool": "Bash", "count": 2}],
  "spec_id": "specs/foo.md",
  "ac_completed": ["AC-001", "AC-002"]
}
```

### Config Schema Addition (`.add/config.json`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `telemetry.enabled` | boolean | `true` | Master switch — when `false`, no emission occurs |
| `telemetry.rotation` | enum | `"daily"` | `"daily"` or `"hourly"` |
| `telemetry.retention_days` | number | `90` | Files older than this are pruned during archive pass |
| `telemetry.redact_files_touched` | boolean | `false` | When `true`, paths are SHA-256 hashed |
| `telemetry.commit_to_git` | boolean | `true` | When `false`, `.add/telemetry/` is added to `.gitignore` |

### OTel GenAI Field Mapping (Reference)

| ADD Field | OTel GenAI Convention | Source |
|-----------|----------------------|--------|
| `gen_ai.system` | `gen_ai.system` | OTel semconv (March 2026 stable) |
| `gen_ai.request.model` | `gen_ai.request.model` | OTel semconv |
| `gen_ai.response.model` | `gen_ai.response.model` | OTel semconv |
| `gen_ai.usage.input_tokens` | `gen_ai.usage.input_tokens` | OTel semconv |
| `gen_ai.usage.output_tokens` | `gen_ai.usage.output_tokens` | OTel semconv |
| `gen_ai.operation.name` | `gen_ai.operation.name` | OTel semconv |

## 5. API Contract

N/A — this is a pure file-write specification with no HTTP API. Telemetry is appended as JSONL by ADD skills and consumed by the dashboard skill or external OTel-compatible collectors.

## 6. UI Behavior

The dashboard's new Cost & Velocity panel renders as inline SVG + HTML tables — no JavaScript. Example layout:

```
━━━ COST & VELOCITY ━━━
Period: last 30 days  |  Total invocations: 184  |  Success rate: 96.2%

Per Skill (top 5)
| Skill          | Invocations | Input Tokens | Output Tokens | Avg Duration |
|----------------|-------------|--------------|---------------|--------------|
| tdd-cycle      | 42          | 521,400      | 134,820       | 38.1s        |
| plan           | 31          | 287,200      | 89,400        | 22.4s        |
| verify         | 28          | 156,800      | 41,200        | 14.7s        |
| spec           | 19          | 198,300      | 67,100        | 28.9s        |
| dashboard      | 8           | 89,200       | 21,400        | 11.2s        |

[SVG trend chart — tokens & invocations over 30 days]

Per Spec (current cycle)
| Spec                          | Invocations | Total Tokens |
|-------------------------------|-------------|--------------|
| specs/telemetry-jsonl.md      | 14          | 187,400      |
| specs/learning-library-search | 22          | 298,100      |
```

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| `.add/telemetry/` does not exist on first emission | Create directory, then write |
| Disk full during append | Skill continues; emission failure is logged to `.add/telemetry-errors.log` once per session |
| Token counts unavailable from session metadata | Emit `null` rather than `0` so aggregations distinguish unknown from zero |
| Skill invokes nested skill | Outer emits `skill_invocation`; nested emits `skill_invocation.nested` with same `session_id` |
| Concurrent writes from parallel subagents | POSIX `O_APPEND` guarantees atomicity for writes < 4KB; entries stay under |
| Hourly rotation and skill spans the hour boundary | Entry is written to the file matching emission time (post-flight), not start time |
| Malformed JSON line in an old file (e.g. truncated write) | Dashboard reader skips with warning; aggregation continues |
| `redact_files_touched: true` with absolute paths | Convert to repo-relative first, then hash |
| Telemetry file becomes very large (high-volume project) | Recommend `commit_to_git: false` and external collector — covered in docs |
| Schema version drift (future field added) | Readers tolerate unknown fields; writers add fields without breaking older readers |

## 8. Dependencies

- **New rule:** `core/rules/telemetry.md` — defines schema and emission protocol (under 80 lines)
- **All skills:** `core/skills/*/SKILL.md` — reference the telemetry rule for pre/post-flight emission
- **Dashboard skill:** `core/skills/dashboard/SKILL.md` — adds Cost & Velocity panel and JSONL reader
- **Config schema:** `.add/config.json` — add `telemetry` block
- **Archive pass:** `/add:learnings archive` (or equivalent) — extends to prune old telemetry files
- **`.gitignore` template:** conditional `.add/telemetry/` entry based on `commit_to_git`
- **External (recommended, not shipped):** `vector` or `opentelemetry-collector` for downstream forwarding

## 9. Infrastructure Prerequisites

| Category | Requirement |
|----------|-------------|
| Environment variables | N/A |
| Registry images | N/A |
| Cloud quotas | N/A |
| Network reachability | N/A (local file writes only; export is opt-in) |
| CI status | N/A |
| External secrets | N/A |
| Database migrations | N/A |

**Verification before implementation:** Confirm POSIX `O_APPEND` atomicity assumption holds on macOS and Linux for writes under 4KB (well-documented; entries are typically 600-900 bytes). On Windows, fall back to per-line `fcntl`/lock acquisition (deferred — Windows support not in v0.9.0 scope).

## 10. Open Questions

| Question | Recommendation |
|----------|---------------|
| Daily vs hourly rotation | Daily by default; opt-in to hourly via config for high-volume projects |
| Hook (PostToolUse on Stop) vs in-skill emission | In-skill body — explicit, testable, and survives hook config drift. Document the failure mode (forgotten emission) and add a lint check |
| `session_id` source | Prefer Claude Code session ID when available; fall back to ADD-generated UUIDv4. Same `session_id` shared across nested skill invocations |
| Capture context-window reads/writes? | No — only API-reported tokens. Context-window math is approximate and provider-specific; out of scope for OTel alignment |
| Interaction with v0.8 active-view pattern for learnings | Telemetry is **never** active-view'd. The active-view pattern is for in-context filtering of learnings; telemetry is for export and dashboard aggregation only |

## 11. Non-Goals

- Real-time streaming to a backend (file-based emission only; export via external collector is opt-in)
- ADD-shipped collector, agent, or backend service
- Replacing the existing learnings, handoff, retro, or away-log systems — telemetry records *what happened and what it cost*; learnings record *insight*
- Encryption-at-rest for telemetry files (handled by the host filesystem or audit policy)
- Per-tool-call detail capture (aggregated counts only, to keep entries small and append-atomic)
- Windows-native concurrent-write support (macOS/Linux only in v0.9.0)

## 12. References

- **OpenTelemetry GenAI Semantic Conventions** — stabilizing March 2026; field names `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, `gen_ai.operation.name`, `gen_ai.system`, `gen_ai.response.model` are taken directly from the spec. 89% of production OTel users rate spec compliance "very important" (CNCF survey, Q1 2026).
- **NIST AI Agent Standards Initiative** (Jan-Feb 2026) — workstream explicitly names "auditable agent activity" as a required deliverable.
- **EU AI Act** (effective August 2026) — Article requirements for high-risk AI systems include continuous logging of agent activity sufficient for post-hoc audit.
- **Datadog, Honeycomb, Helicone, Langfuse, Braintrust** — all consume OTel GenAI conventions natively as of 2026; aligning to the spec means ingestion requires no ADD-side shim.

## 13. Sizing

Medium. ~2-3 days. Telemetry rule (under 80 lines) + per-skill emission discipline + dashboard reader and aggregation + SVG trend chart + retention pruning hook + fixture tests covering concurrent writes, malformed lines, and disabled state. Cycle 3 of M3 (pre-GA hardening).

## 14. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-22 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec interview |

---
autoload: false
maturity: beta
---

# ADD Rule: Structured Telemetry (JSONL)

Every skill invocation appends one JSONL line to `.add/telemetry/{YYYY-MM-DD}.jsonl` aligned with **OpenTelemetry GenAI semantic conventions**. Write-side only — telemetry exists for export, dashboard aggregation, and audit.

**Invariant (AC-004):** telemetry files are write-only. NEVER `Read` `.add/telemetry/*` from any skill body — the files are produced by skills and consumed only by `/add:dashboard`, external collectors, and auditors. Skills MUST still emit a post-flight line on failure or abort — no skill exits silently.

Full spec — schema, rotation, null semantics, pre/post-flight contract, retention, git semantics, OTel export: `${CLAUDE_PLUGIN_ROOT}/references/telemetry-reference.md`.

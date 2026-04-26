---
description: "[ADD v0.9.2] Generate a visual HTML project dashboard from .add/ project files"
argument-hint: "[--open]"
allowed-tools: [Read, Write, Glob, Grep, Bash]
references: ["design-system.md"]
---

# ADD Dashboard Command v0.9.2

Generate a self-contained HTML dashboard at `reports/dashboard.html` by reading the project's `.add/` directory, specs, docs, and config. The file opens in the browser and gives anyone — developer, PM, or founder — a real-time picture of the project's state.

## Pre-Flight

1. Read `.add/config.json` — if not found, abort: "No ADD project found. Run /add:init first."
2. Read `.add/handoff.md` if it exists — note current state.

## Data Gathering

Read ALL of these source files. If a file doesn't exist, note it as missing and continue:

| Source | Path | Data |
|--------|------|------|
| Config | `.add/config.json` | Project name, maturity level, WIP limit, current cycle |
| PRD | `docs/prd.md` | H2 headings = requirement sections, count total |
| Specs | `specs/*.md` | Feature name (H1), Status (frontmatter), AC count (lines with `AC-` prefix or `- [ ]`/`- [x]` under Acceptance Criteria heading) |
| Milestones | `docs/milestones/*.md` | Name, status, feature lists, completion dates |
| Cycles | `.add/cycles/cycle-*.md` | Cycle number, status, features, validation result |
| Learnings | `.add/learnings.json` | Entry count by category |
| Decisions | `.add/decisions.md` | Decision count (H2 sections) |
| Changelog | `CHANGELOG.md` | Version entries |
| Retro scores | `.add/retro-scores.json` | Score trend data (collab, ADD effectiveness, swarm) |
| Retros | `.add/retros/retro-*.md` | Dates and period summaries |
| Git log | `git log --oneline` | Recent commits, tags for releases |

### Spec Status Mapping

Map ADD spec frontmatter `Status:` to dashboard positions:

| Spec Status | Dashboard Label | Hill % |
|-------------|----------------|--------|
| Draft | draft | 10% |
| Approved | specced | 25% |
| (has plan) | planned | 40% |
| Implementing | in-progress | 60% |
| Complete | done | 90% |
| Blocked | blocked | off-hill |

Check if a corresponding plan exists in `docs/plans/` to infer "planned" status.

## HTML Generation

Generate a **single self-contained HTML file** with ALL CSS in a `<style>` block and ALL JavaScript in a `<script>` block. No external CDN calls, no imports, no build step. Must work offline.

### Design System (match getadd.dev)

```
/* Colors */
--bg-primary: #0f0f23;
--bg-secondary: #1a1a2e;
--bg-tertiary: #16213e;
--bg-card: rgba(255,255,255,0.05);
--accent: #b00149;
--accent-light: #d4326d;
--accent-mid: #ff6b9d;
--success: #22c55e;
--warning: #f59e0b;
--info: #0ea5e9;
--purple: #a855f7;
--text-primary: #e4e4e4;
--text-secondary: #a0a0a0;
--text-muted: #6b7280;
--border: rgba(255,255,255,0.08);

/* Fonts */
font-family: system-ui, -apple-system, 'Segoe UI', sans-serif;
font-family-mono: 'SF Mono', Monaco, monospace;

/* Cards */
background: var(--bg-card);
border: 1px solid var(--border);
border-radius: 16px;
padding: 24px;
transition: all 0.3s;

/* Maturity badges */
POC: background rgba(234,179,8,0.15), color #ca8a04
Alpha: background rgba(176,1,73,0.15), color #d4326d
Beta: background rgba(212,50,109,0.15), color #ff6b9d
GA: background rgba(34,197,94,0.15), color #22c55e

/* Status pills */
draft: #6b7280 (gray)
specced: #0ea5e9 (blue)
planned: #a855f7 (purple)
in-progress: #b00149 (raspberry)
verified: #22c55e (green)
done: #16a34a (green bold)
blocked: #f59e0b (amber)
```

### Header Bar (fixed)

Sticky header with `backdrop-filter: blur(12px)`, `background: rgba(15,15,35,0.92)`:
- "ADD" in `#b00149`, bold monospace `18px`
- Project name from config
- Maturity pill (color-coded)
- "Generated: {ISO timestamp}" in muted text
- 7 nav anchor links: Outcome Health | Hill Chart | Cycle Progress | Decision Queue | Intelligence | Cost & Velocity | Timeline
- Small note: "Run /add:dashboard to regenerate"

### Panel 1 — Outcome Health

Vertical traceability chain rendered as connected flow nodes:

```
PRD Requirements → Specs → Acceptance Criteria → Verified/Done
[N total]          [N total] [N total / N checked] [N done specs]
```

- Use CSS flexbox with arrow connectors between nodes
- Color each node: green (all healthy), amber (gaps), red (blocked items)
- Below: amber callout for untraced specs (specs that don't map to any milestone)
- SVG donut chart: overall AC completion % using `stroke-dasharray` technique
  - Track: `rgba(255,255,255,0.1)`, fill: `#22c55e`, center text: percentage

### Panel 2 — Hill Chart

SVG hill using cubic bezier:

```svg
<path d="M 0 200 C 100 200, 150 20, 250 20 C 350 20, 400 200, 500 200" />
```

- Feature dots as `<circle>` elements positioned by status %
- Dot fill color cycles by milestone: `#b00149`, `#0ea5e9`, `#a855f7`, `#22c55e`, `#f59e0b`
- Dot radius 8, stroke white 2px
- `<title>` child for native tooltips: "{name} | {status} | {cycle} | {AC}% complete"
- Left half label: "Figuring it out", right half: "Executing"
- Blocked features: amber dots below hill with dashed line
- Green checkmark badge on milestones where all features are done

### Panel 3 — Cycle Progress

Active cycle at top:
- Feature list with status pills (colored badges)
- AC completion bar per feature (CSS progress bar)
- WIP count vs WIP limit: "{N} / {limit} WIP slots"
- Validation criteria with pass/fail indicators

Past cycles as collapsed `<details>` accordion:
- Cycle number, features, VALIDATED (green) or INCOMPLETE (red) badge
- Click to expand details

If no cycles: "No cycles yet — run /add:cycle to plan your first work batch."

### Panel 4 — Decision Queue

Scan for human bottlenecks:
- Specs with Status: Draft → "Approve Spec" card
- Specs with Status: Blocked → "Unblock Feature" card
- Cycles without validation → "Validate Cycle" card
- Specs not assigned to any milestone → "Confirm Scope" card
- Maturity POC/Alpha with completed cycles → "Consider Maturity Upgrade" card

Each item as a card:
- Bold action label in accent color
- Item name
- One-line description
- Suggested command (e.g., "Run /add:spec to refine")

If empty: green card "All clear — no decisions pending."

### Panel 5 — Project Intelligence

Four large metric cards in a 2x2 grid:
1. **Learnings Captured** — count from `.add/learnings.json`
2. **Decisions Logged** — count from `.add/decisions.md`
3. **Cycles Completed** — count of complete cycle files
4. **Specs Shipped** — count of Complete/Done specs

Maturity timeline: horizontal track `POC → Alpha → Beta → GA` with current level highlighted and pulsing dot.

If `.add/retro-scores.json` exists with entries, render SVG line chart:
- 3 lines: collab (info blue), ADD effectiveness (raspberry), swarm (success green)
- X-axis: dates, Y-axis: 0.0-9.0 scale
- Dots on data points with `<title>` tooltips

### Panel 6 — Cost & Velocity (Telemetry)

Aggregates `.add/telemetry/*.jsonl` (OpenTelemetry GenAI-aligned structured trace — see `rules/telemetry.md`). **This is the only dashboard-side consumer of telemetry files; skills themselves never read them** (AC-004).

**Read path (AC-020, AC-024):**

1. Glob `.add/telemetry/*.jsonl`. If the directory is missing, render "Telemetry not enabled — run with `telemetry.enabled: true` in `.add/config.json` to capture per-skill cost/velocity."
2. Stream each file **line-by-line**. `json.loads` per line.
3. **Malformed lines MUST be skipped with a counter** — do not abort aggregation (AC-024). Surface `Parse warnings: {N} malformed telemetry lines skipped` in the Parse Warnings section at the bottom.
4. Do not load telemetry into LLM context. Summarize and discard.

**Aggregations (AC-021, AC-022):**

- **Per-skill:** invocation count, total input tokens, total output tokens, total `gen_ai.usage.cache_read_input_tokens` (null-safe sum), total duration, success rate, mean `cache_hit_ratio` (ignore nulls).
- **Per-cycle:** join on `spec_id` → cycle membership (read from `.add/cycles/*.md`). Totals: invocations, tokens, duration.
- **Per-spec:** group by `spec_id`. Totals same as per-cycle.

**Panel layout:**

```
━━━ COST & VELOCITY ━━━
Period: last 30 days  |  Total invocations: N  |  Success rate: N.N%  |  Avg cache-hit ratio: N.NN

Per Skill (top 5 by invocations)
| Skill | Invocations | Input Tokens | Output Tokens | Cache Reads | Avg Duration | Cache-Hit Ratio |
|-------|-------------|--------------|---------------|-------------|--------------|-----------------|
| tdd-cycle | 42 | 521,400 | 134,820 | 398,200 | 38.1s | 0.76 |
...

[Inline SVG trend chart — tokens (left axis) & invocations (right axis) over 30 days]

Per Cycle
| Cycle | Invocations | Total Tokens | Duration | Success |
|-------|-------------|--------------|----------|---------|
...

Per Spec
| Spec | Invocations | Total Tokens |
|------|-------------|--------------|
...
```

**SVG trend chart (AC-023):** Inline `<svg>`, no `<script>`, no CDN. X-axis = day (last 30), left Y = tokens, right Y = invocations. Two `<polyline>` elements (tokens in `var(--accent)`, invocations in `var(--info)`). Dots with `<title>` tooltips per day.

**Cache-hit ratio presentation:** if a skill's entries all have `cache_hit_ratio: null`, render "—" rather than `0.00` (distinguishes "unknown" from "no hits").

**Export hint** (static text in the panel):

> Export telemetry to an OTel-compatible collector:
> `cat .add/telemetry/*.jsonl | jq -c '.' | vector --config otel.toml`
> or any of: Datadog, Honeycomb, Helicone, Langfuse, Braintrust (no translation needed — field names match OTel GenAI conventions).

### Panel 7 — Project Timeline

Horizontal scrollable timeline with chronological events:
- Vertical line running left to right
- Events as dots with cards above/below (alternating)
- Each event: date, type icon (emoji or text badge), title, brief description

Event sources:
- Milestones: completion dates from milestone files
- Specs: creation dates from spec frontmatter
- Releases: git tags or CHANGELOG entries
- Retros: dates from `.add/retros/retro-*.md` filenames
- Decisions: dates from `.add/decisions.md` if timestamped

Filter buttons at top: All | Milestones | Specs | Releases | Retros | Decisions
- Vanilla JS: toggle visibility of event types

### Print CSS

```css
@media print {
  .site-nav { display: none; }
  details { open; }
  details[open] summary { display: none; }
  body { background: white; color: black; }
  .card { border: 1px solid #ccc; break-inside: avoid; }
}
```

### Parse Warnings

If any source file had malformed frontmatter or couldn't be parsed, render a collapsed section at the bottom:
"Parse Warnings: {N} files skipped" — expandable to show file paths and error descriptions.

## Output

Write the generated HTML to `reports/dashboard.html`. Create `reports/` directory if needed.

Print to terminal:

```
✓ Dashboard generated → reports/dashboard.html
  Open with: open reports/dashboard.html

  Summary:
  · [N] specs across [N] milestones
  · [N] features on the hill, [N] done
  · [N] items in your decision queue
  · Active cycle: [cycle name or "none"]
```

If `--open` flag is provided, run `open reports/dashboard.html` (macOS) or `xdg-open reports/dashboard.html` (Linux) after generation.

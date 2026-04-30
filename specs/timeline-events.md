# Spec: Timeline Events

**Version:** 0.1.0
**Created:** 2026-02-21
**PRD Reference:** docs/prd.md
**Status:** Superseded
**Target Release:** v0.5.0
**Last-Updated:** 2026-04-22

> **Superseded** by `specs/telemetry-jsonl.md` and the dashboard implementation. Retained for historical reference.

## 1. Overview

The dashboard timeline ("How we got here") needs a structured event log to render accurately. Today, timeline data is scattered across git history, milestone files, retro files, away logs, spec frontmatter, and config.json — there is no single source of truth for "what happened and when."

This spec defines `.add/timeline.json` — a simple append-only event log that captures project events as they happen, giving the dashboard generator everything it needs in one file.

### Design Principles

1. **Append-only** — agents add events, never edit or delete them. The log is the truth.
2. **Auto-captured** — events are written automatically by existing skills and commands, not manually.
3. **Derivable as fallback** — if timeline.json is missing or a project predates this feature, the dashboard generator can reconstruct a best-effort timeline from existing sources (git log, milestones, retros, specs).
4. **Minimal schema** — few required fields, optional detail. Easy to write, easy to render.
5. **Parallel-aware** — events include a `lane` field so the timeline can show branching when agents work simultaneously.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `.add/timeline.json` file follows the schema defined in §3 | Must |
| AC-002 | File is created by `/add:init` with a single `project-start` event | Must |
| AC-003 | File is append-only — new events are pushed to the `events` array, existing events are never modified | Must |
| AC-004 | Events are auto-captured at these trigger points (no human action required): | Must |
| AC-004a | → `/add:init` writes `project-start` | Must |
| AC-004b | → `/add:spec` writes `spec-created` on successful spec creation | Must |
| AC-004c | → `/add:plan` writes `plan-created` | Should |
| AC-004d | → `/add:tdd-cycle` start writes `work-started`, completion writes `work-completed` | Must |
| AC-004e | → `/add:verify` success writes `verified` | Must |
| AC-004f | → `/add:away` writes `swarm-launched` with `agents` count; each sub-agent task start writes `work-started` on its lane | Must |
| AC-004g | → `/add:back` or swarm completion writes `swarm-merged` | Must |
| AC-004h | → `/add:retro` writes `retro` | Must |
| AC-004i | → `/add:cycle` start writes `cycle-started`, validation writes `cycle-completed` | Should |
| AC-004j | → `/add:deploy` or version bump detected in config.json writes `release` | Should |
| AC-004k | → Milestone status change to COMPLETE in milestone file writes `milestone-completed` | Must |
| AC-005 | Each event has a unique `id` field (auto-incremented: `E-001`, `E-002`, ...) | Must |
| AC-006 | Each event has an ISO 8601 `date` field (YYYY-MM-DD minimum, YYYY-MM-DDTHH:MM optional) | Must |
| AC-007 | Each event has a `type` from the enumerated type list in §3 | Must |
| AC-008 | Each event has a human-readable `title` (≤80 chars) | Must |
| AC-009 | `lane` field defaults to `"main"`. Parallel agent work uses `"agent-1"`, `"agent-2"`, etc. | Must |
| AC-010 | `swarm-launched` events include a `branches` field listing the lane names that forked | Must |
| AC-011 | `swarm-merged` events include a `branches` field listing the lane names that merged back | Must |
| AC-012 | The dashboard generator reads `.add/timeline.json` as its primary timeline source | Must |
| AC-013 | If `.add/timeline.json` is missing, the dashboard generator falls back to deriving events from git log + milestone files + retro files + spec dates (§5) | Should |
| AC-014 | Events referencing a spec include `ref.spec` path. Events referencing a milestone include `ref.milestone` path | Should |
| AC-015 | The file stays under 100KB for projects with up to 200 events | Nice |
| AC-016 | `/add:init --adopt` on a legacy project generates a backfilled timeline from existing data sources | Nice |

## 3. Schema

```json
{
  "$schema": "https://github.com/MountainUnicorn/add/timeline.schema.json",
  "version": "1.0.0",
  "project": "string — project name from config.json",
  "events": [
    {
      "id": "E-001",
      "date": "2026-02-07",
      "type": "project-start",
      "title": "Project initialized",
      "lane": "main",
      "desc": "Optional longer description",
      "ref": {
        "spec": "specs/example.md",
        "milestone": "docs/milestones/M1-core-plugin.md",
        "commit": "ed60d59",
        "version": "0.1.0",
        "cycle": ".add/cycles/cycle-1.md"
      },
      "branches": ["agent-1", "agent-2"],
      "agents": 2,
      "scores": {
        "collab": 4.0,
        "add_effectiveness": 5.8,
        "swarm_effectiveness": 6.2
      }
    }
  ]
}
```

### Event Types

| Type | Shape on Timeline | Trigger | Required `ref` fields |
|------|-------------------|---------|----------------------|
| `project-start` | Large ring | `/add:init` | — |
| `milestone-completed` | Large ring (green) | Milestone status → COMPLETE | `ref.milestone` |
| `release` | Medium filled dot (amber) | Version bump or `/add:deploy` | `ref.version`, `ref.commit` |
| `spec-created` | Small dot (blue) | `/add:spec` completes | `ref.spec` |
| `plan-created` | Small dot (blue) | `/add:plan` completes | `ref.spec` |
| `work-started` | Small dot (blue) | `/add:tdd-cycle` starts | `ref.spec` |
| `work-completed` | Small dot (blue) | `/add:tdd-cycle` completes | `ref.spec`, `ref.commit` |
| `verified` | Small dot (green) | `/add:verify` passes | `ref.spec` or `ref.milestone` |
| `swarm-launched` | Fork point | `/add:away` | `branches`, `agents` |
| `swarm-merged` | Merge point | `/add:back` or swarm done | `branches` |
| `retro` | Medium dot (purple) | `/add:retro` | `scores` (if available) |
| `cycle-started` | Small dot | `/add:cycle` start | `ref.cycle` |
| `cycle-completed` | Small dot (green) | `/add:cycle` validated | `ref.cycle` |
| `human-decision` | Medium dot (purple) | Manual — for recording key decisions | — |

### Field Rules

- **`id`**: Auto-incremented. Read the last event's id, increment. Format: `E-NNN`.
- **`date`**: ISO 8601. Use `YYYY-MM-DD` for most events. Use `YYYY-MM-DDTHH:MM` when time-of-day matters (swarm launches, to show ordering within a day).
- **`type`**: Must be one of the enumerated values above.
- **`title`**: Short human-readable summary. Imperative or past tense. ≤80 chars.
- **`lane`**: `"main"` for the primary trunk. `"agent-1"`, `"agent-2"`, etc. for parallel work. The dashboard renderer uses this to fork/merge branch lines.
- **`desc`**: Optional. 1-2 sentences of context. The tooltip shows this on hover.
- **`ref`**: Optional object. Any subset of fields. Lets the dashboard link events to artifacts.
- **`branches`**: Only on `swarm-launched` and `swarm-merged`. Array of lane names.
- **`agents`**: Only on `swarm-launched`. Integer count of parallel agents.
- **`scores`**: Only on `retro`. Object with numeric scores from retro-scores.json.

## 4. How Existing Commands Write Events

Each command/skill appends to `.add/timeline.json` at the appropriate trigger point. The write is a simple JSON array push — read file, parse, push event, write file.

| Command/Skill | When | Event Type | Example Title |
|---------------|------|-----------|---------------|
| `/add:init` | After config.json created | `project-start` | "ADD project initialized" |
| `/add:spec` | After spec file written | `spec-created` | "Spec: Branding System" |
| `/add:plan` | After plan file written | `plan-created` | "Plan: branding-system" |
| `/add:tdd-cycle` | At start of RED phase | `work-started` | "Building: Branding System" |
| `/add:tdd-cycle` | After GREEN phase passes | `work-completed` | "Shipped: Branding System" |
| `/add:verify` | After all gates pass | `verified` | "Verified: Branding System (24/24 ACs)" |
| `/add:away` | After work plan created | `swarm-launched` | "Away mode: 2 agents, 4 features" |
| `/add:away` sub-agent | At each feature start | `work-started` (on agent lane) | "Agent 1: Branding System" |
| `/add:away` sub-agent | At each feature done | `work-completed` (on agent lane) | "Agent 1: Branding System complete" |
| `/add:back` | When human returns or swarm completes | `swarm-merged` | "Swarm merged: 4 features complete" |
| `/add:retro` | After scoring complete | `retro` | "Retro #2 — Collab 4.0, ADD 5.8" |
| `/add:cycle` | After cycle created | `cycle-started` | "Cycle 1: Dashboard features" |
| `/add:cycle` | After validation | `cycle-completed` | "Cycle 1 validated" |
| Config version bump | After version field changes | `release` | "v0.4.0 released" |
| Milestone file update | Status → COMPLETE | `milestone-completed` | "M2: Adoption & Polish complete" |

## 5. Fallback Derivation (No timeline.json)

When `.add/timeline.json` doesn't exist (legacy projects, or before this feature ships), the dashboard generator reconstructs a best-effort timeline by reading existing data sources in this priority order:

| Source | Events Derived | How |
|--------|---------------|-----|
| `.add/config.json` → `project.created` | `project-start` | Read `created` date |
| `docs/milestones/M*-*.md` | `milestone-completed` | Parse `Started` and `Completed` dates from frontmatter. Status: COMPLETE → event. |
| `specs/*.md` | `spec-created` | Parse `Created` date from frontmatter. One event per spec. |
| `.add/retros/retro-*.md` | `retro` | Parse date from filename. Read scores from `.add/retro-scores.json` if available. |
| `.add/retro-scores.json` | (enriches retro events) | Match by date, attach scores. |
| `.add/away-logs/away-*.md` | `swarm-launched` + `swarm-merged` | Parse `Started` timestamp. Scan `Progress Log` table for agent wave counts. Merge date = file modification or return timestamp. |
| `git log --format` | `release` | Match commits with `chore: bump version` or tag creation. Extract version from message. |
| `git log --format` | (enriches work events) | Match `feat:` commits to spec names for commit ref backfill. |

### Derivation Rules

1. Deduplicate by date + type + title similarity.
2. All derived events go on `lane: "main"` (we can't reliably reconstruct parallel lanes from git alone).
3. Away logs with "Wave" patterns in the progress table get branched: waves running in parallel → `swarm-launched` with branches, individual wave items → `work-started`/`work-completed` on agent lanes.
4. Sort all events by date ascending, then by type priority: `project-start` > `milestone-completed` > `swarm-launched` > `release` > `retro` > `spec-created` > `work-*` > `swarm-merged`.

## 6. Dashboard Renderer Contract

The dashboard JS timeline renderer expects an array of event objects with this minimal shape:

```javascript
{
  day: Number,    // days since project start (derived from date - earliest event date)
  type: String,   // maps to node style: 'milestone'|'release'|'work'|'human'|'fork'|'merge'|'now'
  title: String,  // shown in tooltip
  desc: String,   // shown in tooltip
  label: String,  // shown on the SVG near the node (short — "M1 ✓", "v0.2", "Retro", "NOW")
  lane: Number    // 0=main, -1=upper branch, 1=lower branch, -2=second upper, etc.
}
```

**Type mapping from timeline.json → renderer:**

| timeline.json `type` | Renderer `type` | Renderer `label` |
|----------------------|-----------------|-------------------|
| `project-start` | `milestone` | "Start" |
| `milestone-completed` | `merge` (if after a swarm) or `milestone` | "M1 ✓", "M2 ✓" |
| `release` | `release` | version string ("v0.2") |
| `spec-created` | `work` | — |
| `plan-created` | `work` | — |
| `work-started` | `work` | — |
| `work-completed` | `work` | — |
| `verified` | `work` | — |
| `swarm-launched` | `fork` | — |
| `swarm-merged` | `merge` | — |
| `retro` | `human` | "Retro" |
| `cycle-started` | `work` | — |
| `cycle-completed` | `work` | — |
| `human-decision` | `human` | — |

**Lane mapping:** `"main"` → 0. `"agent-1"` → -1. `"agent-2"` → 1. `"agent-3"` → -2. `"agent-4"` → 2. Alternating above/below the trunk to balance the visual.

## 7. Example: ADD Project Backfill

If we ran the derivation algorithm against the current ADD project today, it would produce:

```json
{
  "version": "1.0.0",
  "project": "ADD",
  "events": [
    { "id":"E-001", "date":"2026-02-07",          "type":"project-start",       "title":"ADD project initialized",                          "lane":"main" },
    { "id":"E-002", "date":"2026-02-07",          "type":"release",             "title":"v0.1.0 — MVP",                                     "lane":"main", "ref":{"version":"0.1.0","commit":"ed60d59"} },
    { "id":"E-003", "date":"2026-02-08",          "type":"swarm-launched",      "title":"Away mode: M1 core features",                      "lane":"main", "branches":["agent-1","agent-2"], "agents":2 },
    { "id":"E-004", "date":"2026-02-08",          "type":"work-started",        "title":"3-tier knowledge cascade",                         "lane":"agent-1", "ref":{"commit":"64ab863"} },
    { "id":"E-005", "date":"2026-02-08",          "type":"work-started",        "title":"Environment promotion ladder",                     "lane":"agent-2", "ref":{"commit":"fbf409d"} },
    { "id":"E-006", "date":"2026-02-08",          "type":"swarm-merged",        "title":"Away session complete",                            "lane":"main", "branches":["agent-1","agent-2"] },
    { "id":"E-007", "date":"2026-02-10",          "type":"milestone-completed", "title":"M1: Core Plugin complete",                         "lane":"main", "ref":{"milestone":"docs/milestones/M1-core-plugin.md"} },
    { "id":"E-008", "date":"2026-02-14",          "type":"release",             "title":"v0.2.0 — Adoption",                                "lane":"main", "ref":{"version":"0.2.0","commit":"e5d115b"} },
    { "id":"E-009", "date":"2026-02-14",          "type":"spec-created",        "title":"Specs: Branding, Image Gen, Changelog, Infographic","lane":"main" },
    { "id":"E-010", "date":"2026-02-14T15:00",    "type":"swarm-launched",      "title":"Away mode: M2 polish features (3 waves)",          "lane":"main", "branches":["agent-1","agent-2"], "agents":2 },
    { "id":"E-011", "date":"2026-02-14T15:10",    "type":"work-completed",      "title":"Image gen detection + auto-changelog",             "lane":"agent-1", "ref":{"commit":"f7c8e17"} },
    { "id":"E-012", "date":"2026-02-14T15:20",    "type":"work-completed",      "title":"Infographic generation",                           "lane":"agent-2", "ref":{"commit":"9442fa1"} },
    { "id":"E-013", "date":"2026-02-14T15:35",    "type":"swarm-merged",        "title":"Away session complete: 4 features",                "lane":"main", "branches":["agent-1","agent-2"] },
    { "id":"E-014", "date":"2026-02-16",          "type":"spec-created",        "title":"Spec: Session Continuity & Self-Evolution",         "lane":"main", "ref":{"spec":"specs/session-continuity-and-self-evolution.md"} },
    { "id":"E-015", "date":"2026-02-17",          "type":"work-completed",      "title":"Session Continuity complete (34 ACs)",              "lane":"main", "ref":{"spec":"specs/session-continuity-and-self-evolution.md","commit":"2420ac9"} },
    { "id":"E-016", "date":"2026-02-17",          "type":"retro",               "title":"Retrospective #1",                                 "lane":"main", "ref":{"milestone":"docs/milestones/M1-core-plugin.md"} },
    { "id":"E-017", "date":"2026-02-17",          "type":"release",             "title":"v0.3.0",                                           "lane":"main", "ref":{"version":"0.3.0","commit":"9c426be"} },
    { "id":"E-018", "date":"2026-02-17",          "type":"release",             "title":"v0.4.0",                                           "lane":"main", "ref":{"version":"0.4.0","commit":"797c173"} },
    { "id":"E-019", "date":"2026-02-18",          "type":"spec-created",        "title":"Spec: Legacy Adoption",                            "lane":"main", "ref":{"spec":"specs/legacy-adoption.md"} },
    { "id":"E-020", "date":"2026-02-18",          "type":"work-completed",      "title":"Legacy Adoption complete",                         "lane":"main", "ref":{"commit":"60dc6a5"} },
    { "id":"E-021", "date":"2026-02-19",          "type":"work-completed",      "title":"Retro Template Automation complete",                "lane":"main", "ref":{"commit":"dd11397"} },
    { "id":"E-022", "date":"2026-02-19",          "type":"milestone-completed", "title":"M2: Adoption & Polish complete",                   "lane":"main", "ref":{"milestone":"docs/milestones/M2-adoption-and-polish.md"} },
    { "id":"E-023", "date":"2026-02-19",          "type":"retro",               "title":"Retrospective #2",                                 "lane":"main", "scores":{"collab":4.0,"add_effectiveness":5.8,"swarm_effectiveness":6.2} },
    { "id":"E-024", "date":"2026-02-19",          "type":"spec-created",        "title":"Spec: Project Dashboard",                          "lane":"main", "ref":{"spec":"specs/project-dashboard.md"} },
    { "id":"E-025", "date":"2026-02-21",          "type":"work-started",        "title":"Dashboard design in progress",                     "lane":"main" }
  ]
}
```

## 8. Implementation Notes

- **File size**: At ~200 bytes per event, a 200-event project uses ~40KB. Well under the 100KB target.
- **Concurrency**: If multiple agents write simultaneously, use read-lock pattern (read → parse → find max id → push → write). Collisions are unlikely since events are timestamped differently.
- **Git-committable**: timeline.json lives in `.add/` and is committed with the project, so the timeline travels with the repo.
- **Backward compatible**: The fallback derivation (§5) means existing projects get a timeline on first dashboard run without any migration.

## 9. User Test Cases

### TC-001: Fresh project timeline
**Precondition:** New project, `/add:init` just completed.
**Steps:** Open `.add/timeline.json`.
**Expected:** File exists with one `project-start` event.

### TC-002: Timeline after full cycle
**Precondition:** Project with spec → plan → tdd-cycle → verify completed.
**Steps:** Open `.add/timeline.json`.
**Expected:** Events: `project-start`, `spec-created`, `plan-created`, `work-started`, `work-completed`, `verified`. All on `lane: "main"`.

### TC-003: Away mode parallel branches
**Precondition:** `/add:away` with 2 agents working on 2 features.
**Steps:** Open `.add/timeline.json` after `/add:back`.
**Expected:** `swarm-launched` (branches: ["agent-1","agent-2"]), multiple `work-started`/`work-completed` on agent lanes, `swarm-merged`.

### TC-004: Legacy project derivation
**Precondition:** Existing ADD project with milestones, retros, specs, git history, but no timeline.json.
**Steps:** Run `/add:dashboard`.
**Expected:** Dashboard renders a timeline derived from existing sources. Milestones, releases, retros, and specs appear at correct dates.

### TC-005: Dashboard renders from timeline.json
**Precondition:** Project with 10+ events in timeline.json including a swarm branch.
**Steps:** Run `/add:dashboard`, open HTML.
**Expected:** Timeline shows main trunk with branch lines forking and merging. Events are hoverable with tooltips showing title, date, description.

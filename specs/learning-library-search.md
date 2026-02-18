# Spec: Cross-Project Learning Library Search

**Version:** 0.1.0
**Created:** 2026-02-17
**PRD Reference:** docs/prd.md § Learning System
**Status:** Complete

## 1. Overview

Replace freeform markdown learning logs with structured JSON entries tagged by scope, stack, category, and severity. At skill start, agents query the JSON stores and filter learnings by relevance to the current task (stack match + operation match), surfacing only what matters. When learnings are written, Claude classifies their scope (project vs workstation vs universal) so entries land in the right tier automatically.

This is the foundation layer for a 4-tier learning system (project → workstation → organization → community) that will eventually use embeddings/GRAG and MCP for retrieval. The current spec covers Tier 3 (project) and Tier 2 (workstation) with pure JSON files — no infrastructure required.

### User Stories

**Story 1:** As an agent starting a skill, I want relevant learnings from all my projects surfaced automatically, so I don't repeat mistakes or miss known patterns.

**Story 2:** As an agent writing a checkpoint, I want the system to classify the learning's scope (project-only vs workstation-wide vs universal), so entries land in the right tier without human sorting.

## 2. Acceptance Criteria

### A. Structured Learning Entries (JSON Format)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | Learning entries are stored as JSON objects in `.add/learnings.json` (project-scope) and `~/.claude/add/library.json` (workstation-scope). Each entry has: `id`, `title`, `body`, `scope`, `stack`, `category`, `severity`, `source`, `date`. | Must |
| AC-002 | Existing `.add/learnings.md` is retained as a human-readable view, generated from the JSON data. Skills read JSON for filtering; humans read markdown for review. | Must |
| AC-003 | `~/.claude/add/library.md` is retained as a human-readable view of `library.json`. Same dual-format pattern. | Must |
| AC-004 | Learning IDs follow the pattern `L-{NNN}` (project-scope) or `WL-{NNN}` (workstation-scope), auto-incrementing. | Must |
| AC-005 | Valid `scope` values: `project`, `workstation`, `universal`. Universal entries are stored at workstation level but flagged for future promotion to org/community tiers. | Must |
| AC-006 | Valid `category` values: `technical`, `architecture`, `anti-pattern`, `performance`, `collaboration`, `process`. | Must |
| AC-007 | Valid `severity` values: `critical`, `high`, `medium`, `low`. | Must |
| AC-008 | `stack` field is an array of lowercase identifiers matching the project's `architecture.languages[].name` and `architecture.backend.framework` from config.json (e.g., `["python", "fastapi", "pymysql"]`). Empty array means stack-agnostic. | Should |

### B. Smart Filtering (Read Path)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-009 | At skill start, the learning rule reads both `.add/learnings.json` and `~/.claude/add/library.json` (if they exist). | Must |
| AC-010 | Entries are filtered by relevance: stack overlap with current project + category match for the current operation (e.g., `/add:plan` → `architecture`, `anti-pattern`; `/add:deploy` → `performance`, `technical`; `/add:tdd-cycle` → `technical`, `anti-pattern`). | Must |
| AC-011 | Filtered results are ranked: `critical` > `high` > `medium` > `low`, then by date (newest first). | Should |
| AC-012 | A maximum of 10 learnings are surfaced per skill invocation to prevent context bloat. If more than 10 match, take the top 10 by rank. | Must |
| AC-013 | When no learnings match (empty results), the skill proceeds silently — no "no learnings found" noise. | Must |
| AC-014 | When learnings files don't exist yet (first project), the skill proceeds without error. | Must |
| AC-015 | Stack-agnostic entries (empty `stack` array) always pass the stack filter — they match any project. | Must |

### C. Scope Classification (Write Path)

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-016 | When a checkpoint trigger fires (post-verify, post-TDD, post-deploy, etc.), the agent classifies the learning's scope before writing it. | Must |
| AC-017 | Classification rules: if the learning references project-specific files, schemas, or config → `project`. If it references a library, framework, or pattern applicable to other projects with the same stack → `workstation`. If it's a methodology or process insight independent of stack → `universal`. | Must |
| AC-018 | `project`-scope entries are written to `.add/learnings.json`. `workstation` and `universal`-scope entries are written to `~/.claude/add/library.json`. | Must |
| AC-019 | During `/add:retro`, scope classifications are reviewed. The human can override scope (e.g., promote a project learning to workstation, or demote a workstation learning to project). | Should |
| AC-020 | The classify step adds a `classified_by` field: `"agent"` (auto-classified at checkpoint) or `"human"` (reclassified during retro). | Nice |

### D. Migration

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-021 | A migration utility converts existing `.add/learnings.md` freeform entries into JSON format in `.add/learnings.json`, using Claude to infer tags (scope, stack, category, severity) from the text. | Must |
| AC-022 | A migration utility converts existing `~/.claude/add/library.md` freeform entries into `~/.claude/add/library.json`. | Must |
| AC-023 | Migration preserves the original markdown files as backups (renamed to `.add/learnings.md.bak` and `~/.claude/add/library.md.bak`). | Should |
| AC-024 | After migration, the markdown files are regenerated from JSON to confirm round-trip fidelity. | Should |

### E. Markdown View Generation

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-025 | `.add/learnings.md` is regenerated from `.add/learnings.json` whenever a new entry is written. Format: grouped by category, sorted by date descending within each group. | Should |
| AC-026 | `~/.claude/add/library.md` is regenerated from `~/.claude/add/library.json` in the same manner. | Should |
| AC-027 | The generated markdown includes the entry ID, title, scope badge, severity badge, and body for each entry. | Nice |

### F. Project Index Integration

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-028 | `~/.claude/add/projects/{name}.json` index files gain a `learnings_count` field updated when entries are written. | Nice |
| AC-029 | The filtering step can use the project index to find learnings from projects with overlapping stacks (cross-referencing `stack` fields in project index vs current config). | Nice |

## 3. User Test Cases

### TC-001: Relevant learnings surfaced during /add:plan

**Precondition:** Project uses python + fastapi. `~/.claude/add/library.json` contains a `critical` anti-pattern about pymysql threading from dossier project.
**Steps:**
1. Agent starts `/add:plan specs/auth.md`
2. Learning rule reads config.json → stack is `["python", "fastapi"]`
3. Learning rule queries library.json filtering by stack overlap + category `architecture` or `anti-pattern`
4. pymysql threading entry matches (stack: `["python", "pymysql"]`, category: `anti-pattern`, severity: `critical`)
5. Entry is surfaced as relevant context for the plan
**Expected Result:** The plan incorporates the pymysql threading warning. Agent avoids `asyncio.to_thread()` with pymysql.
**Screenshot Checkpoint:** N/A (CLI plugin)
**Maps to:** TBD

### TC-002: Checkpoint auto-classifies scope

**Precondition:** Agent just completed a TDD cycle that discovered a project-specific database schema quirk.
**Steps:**
1. Post-TDD checkpoint trigger fires
2. Agent writes learning: "users table has a composite primary key on (org_id, user_id)"
3. Agent classifies: references project-specific schema → `project` scope
4. Entry written to `.add/learnings.json` with scope `project`
**Expected Result:** Entry appears in project learnings, not in workstation library.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-003: Checkpoint promotes workstation-level learning

**Precondition:** Agent just completed a deployment where it learned a FastAPI pattern that applies to any FastAPI project.
**Steps:**
1. Post-deploy checkpoint trigger fires
2. Agent writes learning: "FastAPI lifespan handlers must yield, not return — startup code runs before yield, shutdown after"
3. Agent classifies: references FastAPI framework, not project-specific → `workstation` scope
4. Entry written to `~/.claude/add/library.json` with scope `workstation`
**Expected Result:** Entry appears in workstation library. Will surface in any future FastAPI project.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-004: No learnings match (graceful skip)

**Precondition:** Project uses Rust. Library only has Python/FastAPI learnings.
**Steps:**
1. Agent starts `/add:tdd-cycle specs/parser.md`
2. Learning rule reads config → stack `["rust"]`
3. Filters library.json — no entries have `rust` in stack, and no stack-agnostic entries exist
**Expected Result:** Skill proceeds normally. No "no learnings found" message. No error.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-005: Migration of existing freeform learnings

**Precondition:** `.add/learnings.md` has 5 freeform checkpoint entries. `~/.claude/add/library.md` has 4 anti-pattern entries.
**Steps:**
1. Migration utility runs
2. Original files backed up as `.bak`
3. Claude infers tags for each entry
4. JSON files created
5. Markdown views regenerated from JSON
**Expected Result:** JSON files contain all entries with valid tags. Regenerated markdown is readable and complete. Original files preserved as backup.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-006: Retro reclassifies scope

**Precondition:** Library.json has an entry classified as `workstation` by the agent.
**Steps:**
1. User runs `/add:retro`
2. Retro presents workstation entries for scope review
3. User says "that pymysql issue is actually project-specific to dossier"
4. Entry moved from library.json to dossier's learnings.json, scope changed to `project`, `classified_by` set to `human`
**Expected Result:** Entry removed from workstation library. Added to project learnings. Classification audit trail preserved.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-007: Context cap prevents bloat

**Precondition:** library.json has 50 entries, 30 of which match current stack.
**Steps:**
1. Agent starts `/add:plan`
2. Filter returns 30 matches
3. Ranking sorts by severity then date
4. Top 10 selected
**Expected Result:** Only 10 entries surfaced. All 10 are the most critical and recent matches.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

## 4. Data Model

### LearningEntry (JSON)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique ID: `L-{NNN}` (project) or `WL-{NNN}` (workstation) |
| `title` | string | Yes | Short summary (one line) |
| `body` | string | Yes | Full learning text |
| `scope` | enum | Yes | `project` \| `workstation` \| `universal` |
| `stack` | string[] | Yes | Lowercase tech identifiers, e.g. `["python", "fastapi"]`. Empty = stack-agnostic |
| `category` | enum | Yes | `technical` \| `architecture` \| `anti-pattern` \| `performance` \| `collaboration` \| `process` |
| `severity` | enum | Yes | `critical` \| `high` \| `medium` \| `low` |
| `source` | string | Yes | Project name where the learning originated |
| `date` | string | Yes | ISO 8601 date (YYYY-MM-DD) |
| `classified_by` | string | No | `agent` \| `human` — who determined the scope |
| `checkpoint_type` | string | No | Which trigger produced this: `post-verify`, `post-tdd`, `post-deploy`, `post-away`, `feature-complete`, `verification-catch`, `retro` |

### LearningsFile (JSON)

```json
{
  "$schema": "https://github.com/MountainUnicorn/add/learnings.schema.json",
  "version": "1.0.0",
  "project": "dossier",
  "entries": [
    {
      "id": "L-001",
      "title": "pymysql is not thread-safe",
      "body": "asyncio.to_thread() with pymysql connections causes packet sequence corruption. Use synchronous calls or switch to aiomysql.",
      "scope": "workstation",
      "stack": ["python", "pymysql"],
      "category": "anti-pattern",
      "severity": "critical",
      "source": "dossier",
      "date": "2026-02-07",
      "classified_by": "agent",
      "checkpoint_type": "verification-catch"
    }
  ]
}
```

### Operation-to-Category Mapping

| Skill/Command | Relevant Categories |
|---------------|-------------------|
| `/add:plan` | architecture, anti-pattern, collaboration |
| `/add:tdd-cycle` | technical, anti-pattern, performance |
| `/add:test-writer` | technical, anti-pattern |
| `/add:implementer` | technical, anti-pattern, architecture |
| `/add:deploy` | performance, technical, process |
| `/add:verify` | technical, process |
| `/add:optimize` | performance, technical |
| `/add:reviewer` | architecture, anti-pattern, process |

### Scope Classification Rules

| Signal | Inferred Scope |
|--------|---------------|
| References specific files, tables, schemas, or config unique to this project | `project` |
| References a library, framework, or tool used across projects with the same stack | `workstation` |
| References methodology, process, or collaboration patterns independent of stack | `universal` |
| Unclear | Default to `project` (can be promoted later during retro) |

## 5. API Contract

N/A — this is a pure markdown/JSON plugin with no HTTP API. Learnings are read/written as JSON files by ADD skills.

## 6. UI Behavior

N/A — CLI plugin. Learnings are surfaced as inline context during skill execution and reviewed during `/add:retro`.

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No learnings files exist (first project) | Skip gracefully — no error, no message |
| Learnings file is empty JSON (`{"entries":[]}`) | Skip gracefully — treated as no entries |
| 500+ entries in a single file | Filter and rank as normal; cap at 10 surfaced entries |
| Stack mismatch (no entries match current stack) | Surface stack-agnostic entries (empty `stack` array) only |
| Conflicting learnings across tiers | Project-specific (Tier 3) wins over workstation (Tier 2) per existing precedence |
| Malformed JSON entry (missing required fields) | Log warning, skip entry, continue processing remaining entries |
| Migration finds entries that can't be auto-classified | Default to scope `project`, severity `medium`, category `technical` |
| Concurrent writes from parallel agents | Last-write-wins (acceptable for alpha maturity; future: file locking or JSONL append) |
| `library.json` doesn't exist but `library.md` does | Treat as pre-migration state; read markdown as fallback, suggest migration |

## 8. Dependencies

- **Learning rule** (`rules/learning.md`) — needs updating to read JSON files and perform filtering
- **All checkpoint triggers** — need updating to write structured JSON entries instead of freeform markdown
- **Retro command** (`commands/retro.md`) — needs scope review and reclassification flow
- **Config.json** — stack information used for filtering (already exists)
- **Project index** (`~/.claude/add/projects/`) — minor update for `learnings_count`

## 9. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-17 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec interview |

---
autoload: true
maturity: poc
---

# ADD Rule: Continuous Learning

Agents accumulate knowledge through structured JSON checkpoints. Knowledge is organized in three tiers, filtered by relevance, and consumed by all agents before starting work.

## Knowledge Tiers

ADD uses a 3-tier knowledge cascade. Agents read all three tiers before starting work, with more specific tiers taking precedence:

| Tier | JSON (primary) | Markdown (generated view) | Scope | Who Updates |
|------|----------------|--------------------------|-------|-------------|
| **Tier 1: Plugin-Global** | — | `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md` | Universal ADD best practices for all users | ADD maintainers only |
| **Tier 2: User-Local** | `~/.claude/add/library.json` | `~/.claude/add/library.md` (generated) | Cross-project wisdom accumulated by this user | Auto-checkpoints + `/add:retro` |
| **Tier 3: Project-Specific** | `.add/learnings.json` | `.add/learnings.md` (generated) | Discoveries specific to this project | Auto-checkpoints + `/add:retro` |

**Precedence:** Project-specific (Tier 3) > User-local (Tier 2) > Plugin-global (Tier 1). If a project learning contradicts a global learning, the project learning wins for that project.

**Dual format:** JSON is the primary storage — skills read and write JSON. Markdown is a human-readable view regenerated from JSON after each write. If JSON doesn't exist but markdown does, treat as pre-migration state and suggest running migration (see Migration section).

## Read Before Work

Before starting ANY skill or command (except `/add:init`), read the pre-filtered active views:

1. **Tier 1:** Read `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md` (always exists — ships with ADD)
2. **Tier 2:** Read `~/.claude/add/library-active.md` if it exists (pre-filtered compact view)
3. **Tier 3:** Read `.add/learnings-active.md` if it exists (pre-filtered compact view)
4. **Handoff:** Read `.add/handoff.md` if it exists — note in-progress work relevant to this operation.

**Do NOT read the full JSON files** during pre-flight. The `-active.md` files contain the top entries already sorted by severity and date, with archived entries excluded. Only read the full JSON when writing new entries (to determine next ID and check for duplicates).

If active files don't exist, proceed silently. **Fallback:** if `-active.md` doesn't exist but the JSON does, run `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh <path-to-json>` to generate it, then read the result.

## Active View Generation

A PostToolUse hook automatically regenerates `-active.md` whenever a learnings JSON file is written. The hook runs `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh` which:

1. Excludes entries with `"archived": true`
2. Sorts remaining entries by severity (critical > high > medium > low), then date (newest first)
3. Caps at 15 entries
4. Groups by category and writes a compact markdown view

This moves filtering out of agent context — agents read only the small pre-filtered result.

## Learning Entry Schema

All learning entries (Tier 2 and Tier 3) use a structured JSON format:

```json
{
  "id": "L-001",
  "title": "Short summary (one line)",
  "body": "Full learning text with context and actionable detail.",
  "scope": "project",
  "stack": ["python", "fastapi"],
  "category": "technical",
  "severity": "medium",
  "source": "project-name",
  "date": "2026-02-17",
  "classified_by": "agent",
  "checkpoint_type": "post-verify"
}
```

**Required fields:**

| Field | Type | Values |
|-------|------|--------|
| `id` | string | `L-{NNN}` (project-scope) or `WL-{NNN}` (workstation-scope), auto-incrementing |
| `title` | string | Short summary, one line |
| `body` | string | Full learning text |
| `scope` | enum | `project` \| `workstation` \| `universal` |
| `stack` | string[] | Lowercase tech identifiers. Empty array = stack-agnostic |
| `category` | enum | `technical` \| `architecture` \| `anti-pattern` \| `performance` \| `collaboration` \| `process` |
| `severity` | enum | `critical` \| `high` \| `medium` \| `low` |
| `source` | string | Project name where the learning originated |
| `date` | string | ISO 8601 date (YYYY-MM-DD) |

**Optional fields:**

| Field | Type | Values |
|-------|------|--------|
| `classified_by` | string | `agent` (auto-classified) or `human` (reclassified during retro) |
| `checkpoint_type` | string | `post-verify` \| `post-tdd` \| `post-deploy` \| `post-away` \| `feature-complete` \| `verification-catch` \| `retro` |
| `archived` | boolean | `true` to exclude from active view (set during retro) |

**File wrapper:**

```json
{
  "$schema": "https://github.com/MountainUnicorn/add/learnings.schema.json",
  "version": "1.0.0",
  "project": "{project-name or _workstation}",
  "entries": [ ... ]
}
```

## Scope Classification

When writing a learning entry, the agent MUST classify its scope before choosing the target file.

### Classification Rules

| Signal in the learning text | Inferred Scope | Target File |
|-----------------------------|---------------|-------------|
| References specific files, tables, schemas, routes, or config unique to this project | `project` | `.add/learnings.json` |
| References a library, framework, or tool used across projects with the same stack | `workstation` | `~/.claude/add/library.json` |
| References methodology, process, or collaboration patterns independent of any stack | `universal` | `~/.claude/add/library.json` (flagged for future org/community promotion) |
| Unclear or ambiguous | `project` | `.add/learnings.json` (can be promoted during retro) |

### Classification Process

1. Read the learning text
2. Ask: "Does this reference anything specific to THIS project's codebase?" → If yes: `project`
3. Ask: "Does this reference a library/framework pattern useful in OTHER projects with the same stack?" → If yes: `workstation`
4. Ask: "Is this a process/methodology insight independent of tech stack?" → If yes: `universal`
5. Default: `project` (conservative — easier to promote later than to demote)

Set `classified_by` to `"agent"` for auto-classification. During `/add:retro`, the human can override scope and the field changes to `"human"`.

## Checkpoint Triggers

Agents automatically write structured JSON entries at these moments. No human involvement needed.

### How to Write a Checkpoint Entry

1. **Classify scope** using the rules above
2. **Read the target JSON file** (`.add/learnings.json` or `~/.claude/add/library.json`)
3. If the file doesn't exist, create it with the wrapper structure and an empty `entries` array
4. **Determine the next ID**: find the highest existing `L-{NNN}` or `WL-{NNN}`, increment by 1
5. **Append** the new entry to the `entries` array
6. **Write** the updated JSON file
7. **Regenerate** the corresponding markdown view (see Markdown View Generation)

### After Verification (`/add:verify` completes)

```json
{
  "id": "L-{NNN}",
  "title": "{gate passed cleanly | gate failure: {which gate}}",
  "body": "{Root cause and fix if failure, or 'routine clean pass' if success. Include prevention notes.}",
  "scope": "{classify}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "{critical if production-affecting, high if required fix, medium if minor, low if clean pass}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-verify"
}
```

### After TDD Cycle Completes

```json
{
  "id": "L-{NNN}",
  "title": "{spec name}: {summary of cycle outcome}",
  "body": "ACs covered: {list}. RED: {N} tests. GREEN: {pass details}. Blockers: {any}. Spec quality: {assessment}.",
  "scope": "{classify}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "{high if blockers or rework, medium if clean, low if routine}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-tdd"
}
```

### After Away-Mode Session

```json
{
  "id": "L-{NNN}",
  "title": "Away session: {N}/{N} tasks completed",
  "body": "Duration: {planned} → {actual}. Completed: {list}. Blocked: {list with reasons}. Effectiveness: {%}. Would have helped: {notes}.",
  "scope": "project",
  "stack": [],
  "category": "process",
  "severity": "{high if low effectiveness, medium otherwise}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-away"
}
```

### After Spec Implementation Completes

```json
{
  "id": "L-{NNN}",
  "title": "Feature complete: {feature name}",
  "body": "Total ACs: {N}. TDD cycles: {N}. Rework: {N}. Spec revisions: {N}. What went well: {text}. What to improve: {text}. Patterns: {text}.",
  "scope": "{classify}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "medium",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "feature-complete"
}
```

### After Deployment

```json
{
  "id": "L-{NNN}",
  "title": "Deploy to {environment}: {passed|issues found}",
  "body": "Smoke tests: {result}. Issues: {details or none}. Notes: {anything notable}.",
  "scope": "{classify — deployment issues are often workstation-level}",
  "stack": ["{from config}"],
  "category": "technical",
  "severity": "{critical if prod issues, high if staging issues, medium if clean}",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "post-deploy"
}
```

### When Verification Catches Sub-Agent Error

```json
{
  "id": "L-{NNN}",
  "title": "Verification catch: {agent} — {error summary}",
  "body": "Agent: {test-writer|implementer|other}. Error: {what went wrong}. Correct approach: {what should have been done}. Pattern to avoid: {generalized lesson}.",
  "scope": "{classify — often workstation-level since agent patterns repeat}",
  "stack": ["{from config}"],
  "category": "anti-pattern",
  "severity": "high",
  "source": "{project name}",
  "date": "{YYYY-MM-DD}",
  "classified_by": "agent",
  "checkpoint_type": "verification-catch"
}
```

## Checkpoint Format Rules

- Keep `body` concise (2-4 sentences max)
- Always include a reference to the spec, file, or feature
- Focus on ACTIONABLE insights, not observations
- Don't duplicate — if the same lesson already exists (check by title similarity), don't add it
- Infer `stack` from `.add/config.json` — don't hardcode or guess

## PII Heuristic — Pre-Write Check

Before writing ANY learning entry to `.add/learnings.json` or `~/.claude/add/library.json`, scan the candidate `title` and `body` for likely PII or secret patterns. If any match, halt the write and surface a warning.

### Patterns to detect

| Category | Regex | Example match |
|---|---|---|
| Email address | `\b[\w.+-]+@[\w-]+\.[\w.-]+\b` | `alice@example.com` |
| IPv4 (non-local) | `\b(?!10\.)(?!127\.)(?!192\.168\.)(?!172\.(?:1[6-9]\|2\d\|3[01])\.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b` | `34.117.88.9` (not `10.0.0.1`, `127.0.0.1`, or RFC1918) |
| Bearer / API-key-like | `\b(?:sk-\|pk-\|xoxb-\|xoxp-\|ghp_\|gho_\|ghs_\|glpat-\|AIza\|AKIA)[A-Za-z0-9_-]{16,}` | `sk-proj-abc123...`, `ghp_...`, `AKIA...`, `AIza...` |
| JWT-like token | `\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b` | `eyJhbGciOiJI...` |
| Private key header | `-----BEGIN (?:RSA\|EC\|OPENSSH\|PGP) PRIVATE KEY-----` | literal header |
| Password-like kv | `\b(?:password\|passwd\|secret\|token\|api[_-]?key)["':=\s]+['"]?[\w\-/.+=]{8,}` | `password="hunter2-long"` |
| Cloud resource ID | `\b(?:arn:aws:[\w:-]+:\d{12}:\|projects/[\w-]+/secrets/\|gs://[\w-]+/\|s3://[\w-]+/)` | `arn:aws:iam::123456789012:...` |

### Response to a match

**Halt the learning write.** Print:

```
⚠ PII HEURISTIC — potential sensitive data detected in learning entry

  Entry title: "{title}"
  Matched pattern: {category} — "{matched_substring}"

Learning checkpoints are committed to git. Once a secret is in history, it
is non-trivial to fully remove. Options:

  [r] Rewrite the entry without the sensitive value (recommended)
  [o] Override — write the entry as-is (logged as compliance-bypass)
  [s] Skip — don't write this learning at all

Response:
```

On `r`: present the entry with the matched substring replaced by `«REDACTED»` for the user to confirm before write.
On `o`: write as-is, AND add a second learning entry with `checkpoint_type: "compliance-bypass"` noting the bypass. Bypass entries count against the `--force-no-retro`-style abuse detection in `add-compliance.md`.
On `s`: do not write; continue.

### What's NOT checked (explicitly out of scope)

- **Prose that merely mentions concepts** like "rotate api keys quarterly" — the pattern requires a value-like match, not the keyword alone.
- **Internal code identifiers** (variable names, DB column names) — those are fine; only values with entropy/prefix patterns match.
- **Test fixtures** with obvious dummy values like `example.com`, `test@test.test`, `AKIAIOSFODNN7EXAMPLE` (AWS docs example) — the heuristic is best-effort, not a secrets scanner. Use `detect-secrets` or `gitleaks` for real secrets scanning.

This is an ergonomic guardrail against accidental leaks in learning-style writing, not a security control. Skills that process production data should still run proper secret-scanning in CI.

## Markdown View Generation

After writing any entry to a JSON learnings file, the PostToolUse hook regenerates the active view (`-active.md`) automatically. Additionally, regenerate the full markdown view for human reading:

**For `.add/learnings.json` → `.add/learnings.md`:**

```markdown
# Project Learnings — {project name}

> **Tier 3: Project-Specific Knowledge**
> Generated from `.add/learnings.json` — do not edit directly.
> Agents read JSON for filtering; this file is for human review.

## Anti-Patterns
{entries where category = "anti-pattern", sorted by date descending}
- **[{severity}] {title}** (L-{NNN}, {date})
  {body}

## Technical
{entries where category = "technical"}

## Architecture
{entries where category = "architecture"}

## Performance
{entries where category = "performance"}

## Process
{entries where category = "process"}

## Collaboration
{entries where category = "collaboration"}

---
*{N} entries. Last updated: {date}. Source: .add/learnings.json*
```

**For `~/.claude/add/library.json` → `~/.claude/add/library.md`:**

Same format but with header:

```markdown
# ADD Cross-Project Knowledge Library

> **Tier 2: User-Local Knowledge**
> Generated from `~/.claude/add/library.json` — do not edit directly.
> Entries are auto-classified by scope: workstation or universal.
```

Omit empty categories (don't show a heading with no entries).

## Migration from Markdown

For projects with existing freeform `.add/learnings.md` or `~/.claude/add/library.md` that haven't been migrated to JSON:

### Detection

If a skill reads a `.md` learnings file and no corresponding `.json` exists, suggest migration:
"Learnings are in legacy markdown format. Run migration to enable smart filtering and scope classification."

### Migration Steps

1. **Backup** the original markdown file (copy to `.add/learnings.md.bak` or `~/.claude/add/library.md.bak`)
2. **Parse** each entry from the markdown (checkpoint blocks, bullet points, sections)
3. **Classify** each entry — infer tags from the text:
   - `scope`: Use classification rules above. Default to `project` if unclear.
   - `stack`: Extract technology names mentioned. Default to empty array if unclear.
   - `category`: Match against category enum based on content. Default to `technical`.
   - `severity`: `critical` if mentions production failures/data loss, `high` if mentions bugs/rework, `medium` for general insights, `low` for routine observations.
   - `source`: Use the project name from config, or extract from "Source: {name}" if present.
4. **Assign IDs**: `L-001`, `L-002`, etc. for project-scope; `WL-001`, etc. for workstation-scope.
5. **Write** the JSON file with all entries
6. **Regenerate** the markdown view from JSON
7. **Verify** the regenerated markdown contains all original content (may be reorganized by category)

### Migration is Non-Destructive

- Original files are preserved as `.bak`
- If migration produces bad results, delete the JSON and rename `.bak` back
- Migration can be re-run after manual corrections

## Knowledge Promotion

Learnings flow upward through the tiers during retrospectives.

### Tier 3 → Tier 2 (Project → User Library)

During `/add:retro`, entries in `.add/learnings.json` with scope `workstation` or `universal` are candidates for promotion to `~/.claude/add/library.json`.

**Promote when:**
- A pattern applies across projects (not tied to a specific codebase)
- A technical insight transfers to other stacks or contexts
- An anti-pattern would be harmful in any project

**Process:** Agent flags candidates. Human confirms. On approval:
1. Copy entry to `~/.claude/add/library.json` with new `WL-{NNN}` ID
2. Remove from `.add/learnings.json`
3. Regenerate both markdown views

### Tier 2/3 → Tier 1 (User/Project → Plugin-Global)

The highest bar. Plugin-global knowledge ships to ALL ADD users.

**Promote when:**
- Universal — applies regardless of stack, team size, or project type
- Reflects an ADD methodology truth (not a tech stack preference)
- Validated across multiple projects or users

**Do NOT promote:** Technology preferences, stack patterns, project constraints, user preferences.

**Process:** Only the ADD development project can write to `knowledge/global.md`. During `/add:retro` in the ADD project itself, the retro flow includes a "promote to plugin-global" step. In consumer projects, `knowledge/global.md` is read-only.

## Archival

Learnings accumulate over time. During `/add:retro`, review entries for archival to keep the active set small and relevant:

**Archive when:**
- Entry is older than 90 days AND severity is `low` or `medium`
- Entry has been superseded by a newer learning covering the same topic
- Entry is project-specific but the referenced code/feature no longer exists

**Archive by:** Setting `"archived": true` on the entry in the JSON. The entry stays in the file for audit history but is excluded from the active view.

**Never archive:** `critical` or `high` severity entries without explicit human approval.

After archiving, the PostToolUse hook regenerates the active view automatically.

## Session Handoff Protocol

Agents MUST write `.add/handoff.md` **automatically** — never wait for the human to ask. Handoffs are a background bookkeeping task, not a user-facing action.

### Auto-Write Triggers

Write/update the handoff silently after any of these events:

1. **After completing a major work item** — spec, plan, implementation, or feature marked done
2. **After a commit** — the commit represents a state change worth capturing
3. **When context is getting long** — 20+ tool calls, 10+ files read, 30+ turns
4. **When switching work streams** — pivoting to a different area of work
5. **When the user departs** — `/add:away` or explicit session end

The agent writes the handoff as a natural final step, the same way it would stage files for a commit. No announcement needed unless context is the trigger (in which case, briefly note: "Writing session handoff to `.add/handoff.md`.").

### Handoff Format

```
# Session Handoff
**Written:** {timestamp}

## In Progress
- {what was being worked on, with file paths and step progress}

## Completed This Session
- {what got done, with commit hashes if applicable}

## Decisions Made
- {choices made this session with brief rationale}

## Blockers
- {anything that's stuck or needs human input}

## Next Steps
1. {prioritized list of what should happen next}
```

### Rules

- Handoff replaces the previous one (current state, not append-only)
- Keep under 50 lines — this is a summary, not a transcript
- All ADD skills MUST read `.add/handoff.md` at the start of execution if it exists
- `/add:back` reads handoff as part of the return briefing
- **Never ask** the human "should I update the handoff?" — just do it

## Knowledge Store Boundaries

Each store has a single purpose. Do not cross-pollinate:

| Store | Format | Purpose | NOT for |
|-------|--------|---------|---------|
| `CLAUDE.md` | Markdown | Project architecture, tech stack, conventions | Session state, learnings, observations |
| `.add/learnings.json` | JSON | Domain facts — framework quirks, API gotchas (project-scope) | Process observations, session state |
| `.add/learnings.md` | Markdown | Generated human-readable view of learnings.json | Direct editing (regenerated from JSON) |
| `~/.claude/add/library.json` | JSON | Cross-project wisdom (workstation + universal scope) | Project-specific knowledge |
| `~/.claude/add/library.md` | Markdown | Generated human-readable view of library.json | Direct editing (regenerated from JSON) |
| `.add/observations.md` | Markdown | Process data — what happened, what it cost | Domain facts, architecture |
| `.add/handoff.md` | Markdown | Current session state — in progress, next steps | Permanent knowledge |
| `.add/decisions.md` | Markdown | Architectural choices with rationale | Transient session state |
| `.add/mutations.md` | Markdown | Process evolution — approved workflow changes | Domain facts |

During `/add:retro`, identify entries in the wrong store and relocate them.

**Knowledge tier roadmap:**
- **Tier 1: Plugin-Global** (`knowledge/global.md`) — universal ADD best practices (exists)
- **Tier 2: User-Local** (`~/.claude/add/library.json`) — cross-project user wisdom (exists)
- **Tier 3: Collective** — team/org shared learnings (future)
- **Tier 4: Community** — all ADD users, crowd-sourced (future)

Precedence: project > install > collective > community. More specific wins.

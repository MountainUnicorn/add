# Learning System Reference

> Full reference for the ADD learning system. Loaded by skills that write
> checkpoints or run migrations. The condensed behavioral rules are in
> `rules/learning.md`.

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

## Checkpoint Templates

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

## PII Heuristic — Pre-Write Check

Before writing ANY learning entry, scan the candidate `title` and `body` for likely PII or secret patterns. If any match, halt the write and surface a warning.

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

**Halt the learning write.** Present options:
- `[r]` Rewrite the entry without the sensitive value (recommended)
- `[o]` Override — write as-is (logged as compliance-bypass)
- `[s]` Skip — don't write this learning

On `r`: replace matched substring with `«REDACTED»`, confirm with user.
On `o`: write as-is AND add a compliance-bypass checkpoint entry.
On `s`: skip silently.

### What's NOT checked

- Prose mentioning concepts ("rotate api keys quarterly") — pattern requires a value-like match
- Internal code identifiers (variable names, DB column names)
- Test fixtures with obvious dummy values

## Markdown View Generation

After writing any entry to a JSON learnings file, regenerate the corresponding markdown file:

**For `.add/learnings.json` → `.add/learnings.md`:**

```markdown
# Project Learnings — {project name}

> **Tier 3: Project-Specific Knowledge**
> Generated from `.add/learnings.json` — do not edit directly.

## Anti-Patterns
- **[{severity}] {title}** (L-{NNN}, {date})
  {body}

## Technical
## Architecture
## Performance
## Process
## Collaboration

---
*{N} entries. Last updated: {date}. Source: .add/learnings.json*
```

**For `~/.claude/add/library.json` → `~/.claude/add/library.md`:**

Same format with Tier 2 header. Omit empty categories.

## Migration from Markdown

For projects with existing freeform `.add/learnings.md` or `~/.claude/add/library.md` that haven't been migrated to JSON:

### Detection

If a skill reads a `.md` learnings file and no corresponding `.json` exists, suggest migration:
"Learnings are in legacy markdown format. Run migration to enable smart filtering and scope classification."

### Migration Steps

1. **Backup** the original markdown file (copy to `{file}.bak`)
2. **Parse** each entry from the markdown (checkpoint blocks, bullet points, sections)
3. **Classify** each entry — infer scope, stack, category, severity from text
4. **Assign IDs**: `L-001`, `L-002`, etc. for project-scope; `WL-001`, etc. for workstation-scope
5. **Write** the JSON file with all entries
6. **Regenerate** the markdown view from JSON
7. **Verify** the regenerated markdown contains all original content

Migration is non-destructive — original files preserved as `.bak`.

## Knowledge Promotion

Learnings flow upward through tiers during retrospectives.

### Tier 3 → Tier 2 (Project → User Library)

During `/add:retro`, entries with scope `workstation` or `universal` are promotion candidates.

**Promote when:** pattern applies across projects, technical insight transfers, anti-pattern would harm any project.

**Process:** Agent flags candidates. Human confirms. Copy to `~/.claude/add/library.json` with `WL-{NNN}` ID, remove from project, regenerate both markdown views.

### Tier 2/3 → Tier 1 (User/Project → Plugin-Global)

Highest bar — ships to ALL ADD users. Must be universal, methodology-level, validated across projects. Only the ADD development project can write to `knowledge/global.md`.

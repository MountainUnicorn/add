---
autoload: true
maturity: poc
references: ["learning-reference.md"]
---

# ADD Rule: Continuous Learning

Agents accumulate knowledge through structured JSON checkpoints across three tiers. Pre-filtered active views keep auto-loaded context small; the full schema, checkpoint templates, PII regex table, and migration protocol live in `${CLAUDE_PLUGIN_ROOT}/references/learning-reference.md` — load on demand when writing entries or running migrations.

## Knowledge Tiers

| Tier | JSON (primary) | Markdown views | Scope |
|------|----------------|----------------|-------|
| **1: Plugin-Global** | — | `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md` | Universal ADD best practices (read-only) |
| **2: User-Local** | `~/.claude/add/library.json` | `library.md` + `library-active.md` (generated) | Cross-project wisdom |
| **3: Project** | `.add/learnings.json` | `learnings.md` + `learnings-active.md` (generated) | Project-specific discoveries |

**Precedence:** Tier 3 > Tier 2 > Tier 1. JSON is primary storage; markdown is a regenerated view. If JSON doesn't exist but markdown does, suggest running migration (see `learning-reference.md`).

## Read Before Work

Before starting ANY skill (except `/add:init`), read the pre-filtered active views:

1. **Tier 1:** Read `${CLAUDE_PLUGIN_ROOT}/knowledge/global.md`
2. **Tier 2:** Read `~/.claude/add/library-active.md` if it exists
3. **Tier 3:** Read `.add/learnings-active.md` if it exists
4. **Handoff:** Read `.add/handoff.md` if it exists

**Do NOT read the full JSON files** during pre-flight. The `-active.md` files are pre-sorted by severity and date, with archived entries excluded. Only read the full JSON when writing new entries (to determine next ID and check for duplicates).

**Fallback** (if `-active.md` doesn't exist):
1. Run `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh <path-to-json>` and read the result. Notify: "Generated learnings active view."
2. If the script fails, read the full JSON and apply in-context filtering (cap at 10 by severity). Learnings are never lost — JSON is canonical.

## Active View Generation

A PostToolUse hook automatically regenerates `-active.md` whenever a learnings JSON file is written. The hook:

1. Excludes entries with `"archived": true`
2. Sorts remaining entries by severity (critical > high > medium > low), then date (newest first)
3. Caps at `learnings.active_cap` entries (default 15, configurable in `.add/config.json`)
4. Groups by category and writes a compact markdown view

This moves filtering out of agent context — agents read only the small pre-filtered result.

## Scope Classification

Before writing a learning entry, classify its scope:

| Signal | Scope | Target |
|--------|-------|--------|
| References project-specific files/schemas/routes | `project` | `.add/learnings.json` |
| References library/framework patterns useful across projects | `workstation` | `~/.claude/add/library.json` |
| Methodology/process insight independent of stack | `universal` | `~/.claude/add/library.json` |
| Unclear | `project` | `.add/learnings.json` (promote later during retro) |

Set `classified_by: "agent"`. During `/add:retro`, humans can override scope → `"human"`.

## Checkpoint Triggers

Auto-write structured JSON entries at these moments (no human involvement):

- After `/add:verify` completes → `checkpoint_type: "post-verify"`
- After a TDD cycle completes → `"post-tdd"`
- After deployment → `"post-deploy"`
- After away-mode session → `"post-away"`
- After spec implementation completes → `"feature-complete"`
- When verification catches a sub-agent error → `"verification-catch"`

**How to write:** Classify scope → read target JSON (create wrapper if missing) → determine next ID (`L-{NNN}` project / `WL-{NNN}` workstation) → append entry → write JSON → regenerate markdown view.

**Before writing,** run the PII heuristic (see `learning-reference.md`). If it matches, halt and prompt for rewrite / override / skip.

**Format rules:** body 2-4 sentences, always reference a spec/file/feature, focus on ACTIONABLE insight, don't duplicate by title similarity, infer `stack` from `.add/config.json`.

For the full schema, the 6 checkpoint templates, the PII regex table, and the migration protocol, see `${CLAUDE_PLUGIN_ROOT}/references/learning-reference.md`.

## Knowledge Promotion

Learnings flow upward during retrospectives.

**Tier 3 → Tier 2 (Project → User Library):** During `/add:retro`, entries in `.add/learnings.json` with scope `workstation` or `universal` are candidates. Agent flags; human confirms. On approval: copy to `~/.claude/add/library.json` with new `WL-{NNN}` ID, remove from source, regenerate both markdown views.

**Tier 2/3 → Tier 1 (User/Project → Plugin-Global):** Only in the ADD development project itself. Requires universal applicability, validation across multiple projects. In consumer projects, `knowledge/global.md` is read-only.

## Archival

During `/add:retro`, archive entries to keep the active set small:

**Archive when:** older than `learnings.archival_days` (default 90) AND severity ≤ `learnings.archival_max_severity` (default `"medium"`), OR superseded by a newer entry, OR references code/features that no longer exist.

**Archive by:** setting `"archived": true` on the entry in JSON. The entry stays in the file for audit history but is excluded from the active view.

**Never archive** entries above `archival_max_severity` without explicit human approval. With the default, `critical` and `high` are protected.

After archiving, the PostToolUse hook regenerates the active view automatically.

## Session Handoff Protocol

Agents MUST write `.add/handoff.md` **automatically** — never wait for the human to ask.

**Auto-write triggers:**

1. After completing a major work item (spec, plan, implementation, feature)
2. After a commit
3. When context is long (20+ tool calls, 10+ files read, 30+ turns)
4. When switching work streams
5. When the user departs (`/add:away` or session end)

**Format:** Under 50 lines. Sections: Written (timestamp), In Progress, Completed This Session, Decisions Made, Blockers, Next Steps.

**Rules:** Replace the previous handoff (current state, not append-only). All ADD skills MUST read `.add/handoff.md` at the start of execution if it exists. `/add:back` reads handoff as part of return briefing. **Never ask** "should I update the handoff?" — just do it.

## Knowledge Store Boundaries

Each store has a single purpose. Do not cross-pollinate:

| Store | Purpose | NOT for |
|-------|---------|---------|
| `CLAUDE.md` | Project architecture, tech stack, conventions | Session state, learnings |
| `.add/learnings.json` | Domain facts — framework quirks, API gotchas (project-scope) | Process observations |
| `~/.claude/add/library.json` | Cross-project wisdom (workstation + universal scope) | Project-specific knowledge |
| `.add/observations.md` | Process data — what happened, what it cost | Domain facts, architecture |
| `.add/handoff.md` | Current session state — in progress, next steps | Permanent knowledge |
| `.add/decisions.md` | Architectural choices with rationale | Transient session state |
| `.add/mutations.md` | Process evolution — approved workflow changes | Domain facts |

Generated markdown views (`learnings.md`, `library.md`, `-active.md`) are regenerated from JSON — never edit directly.

During `/add:retro`, identify entries in the wrong store and relocate.

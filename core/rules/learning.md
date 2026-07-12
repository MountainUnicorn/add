---
autoload: true
maturity: poc
references: ["learning-reference.md"]
---

# ADD Rule: Continuous Learning

Agents accumulate knowledge through structured JSON checkpoints across three tiers. Pre-filtered active views keep auto-loaded context small; the full schema, checkpoint triggers and templates, scope classification, promotion/archival policy, knowledge-store boundaries, PII regex table, and migration protocol live in `${CLAUDE_PLUGIN_ROOT}/references/learning-reference.md` — load on demand when writing entries, running retros, or migrating.

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

**Fallback** (if `-active.md` doesn't exist): run `${CLAUDE_PLUGIN_ROOT}/hooks/filter-learnings.sh <path-to-json>` and read the result; if the script fails, read the full JSON and apply in-context filtering (cap at 10 by severity). Learnings are never lost — JSON is canonical. A PostToolUse hook regenerates `-active.md` automatically whenever a learnings JSON file is written, keeping filtering out of agent context.

## Checkpoints

Agents MUST write a learning checkpoint after significant work (post-verify, post-tdd, post-deploy, post-away, feature-complete, verification-catch) — the full trigger list, entry templates, and scope classification table are in the reference. Before writing, run the PII heuristic from the reference; on a match, halt and prompt. NEVER archive entries above `archival_max_severity` without explicit human approval.

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

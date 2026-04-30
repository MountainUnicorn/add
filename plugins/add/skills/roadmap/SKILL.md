---
description: "[ADD v0.9.5] View and manage project roadmap — milestones, horizons, reordering"
argument-hint: "[--view | --edit | --reorder]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite]
references: ["rules/telemetry.md"]
---

# ADD Roadmap Command v0.9.5

View, edit, and reorder project milestones across roadmap horizons (Now / Next / Later). This skill manages the strategic layer of ADD's work hierarchy — bridging the PRD roadmap table and individual milestone files.

```
Roadmap (Now / Next / Later)        ← this skill
  → Milestones (/add:milestone)     ← tactical operations
    → Cycles (/add:cycle)           ← execution
      → Features (/add:spec)        ← specification
```

---

## Pre-Flight

All subcommands begin here:

1. **Read `.add/config.json`** — extract `maturity.level`, `planning.current_milestone`
   - If not found: abort with "No ADD project found. Run `/add:init` first."
2. **Read `docs/prd.md`** — locate Section 6 ("Milestones & Roadmap"), parse the roadmap table and milestone detail blocks
   - If `docs/prd.md` missing: abort with "No PRD found. Run `/add:init` first."
3. **Glob `docs/milestones/M*.md`** — for each, parse: Status, Goal, feature count, feature positions (hill chart data), success criteria progress
4. **Read `.add/handoff.md`** if it exists — note any in-progress decisions relevant to roadmap changes
5. **Build roadmap model** — merge PRD table (source of truth for horizons) with milestone files (source of truth for status/content). Flag discrepancies.

---

## Command: /roadmap --view (default)

Display current roadmap. No file modifications.

### Output

Show project context, then milestones grouped by horizon:

```
Project: {project_name} | Maturity: {level}
Active Milestone: {planning.current_milestone or "None"}

═══ NOW ═══
  M3 — Authentication Overhaul
    Goal: Stabilize auth and reduce session bugs by 90%
    Status: IN_PROGRESS | 2/5 success criteria met
    Features: 3 (1 downhill, 1 peak, 1 uphill) | ~55% complete

═══ NEXT ═══
  M4 — Payment Integration
    Goal: Accept payments via Stripe
    Status: NOT_STARTED | 0/4 success criteria met
    Features: 2 (all shaped) | 0%

  M5 — Analytics Dashboard
    Goal: Real-time usage analytics for admins
    Status: NOT_STARTED | 0/3 success criteria met
    Features: 4 (all shaped) | 0%

═══ LATER ═══
  M6 — Multi-tenant Support
    Goal: Isolate data per organization
    Status: NOT_STARTED | 0%
```

### Discrepancy Warnings

If pre-flight detected mismatches:
```
Warnings:
  ⚠ M2 is COMPLETE in milestone file but still listed as NOW in PRD
  ⚠ M7 exists in docs/milestones/ but is not in PRD roadmap table
```

### Maturity Scaling

| Detail | POC | Alpha | Beta | GA |
|--------|-----|-------|------|-----|
| Goal | ✓ | ✓ | ✓ | ✓ |
| Status + criteria | — | ✓ | ✓ | ✓ |
| Feature positions | — | — | ✓ | ✓ |
| Risks + dependencies | — | — | — | ✓ |

---

## Command: /roadmap --edit

Interactive menu for milestone management. Loop until user selects "Done."

### Step 1: Show Current State

Display `--view` output first for context.

### Step 2: Present Menu

```
Roadmap actions:

1. Move a milestone between horizons (Now/Next/Later)
2. Add a new milestone
3. Archive a milestone
4. Update a milestone's goal
5. Done — save and exit
```

Ask via AskUserQuestion. Loop back after each action.

### Action 1: Move Between Horizons

Ask which milestone, then which horizon. Handle these cases:

**Moving TO Now:** If another milestone is already Now + IN_PROGRESS, warn:
"M3 is the current Now milestone. Moving M4 to Now makes it the new active milestone. This updates `planning.current_milestone` in config. Continue?"

**Moving FROM Now:** Warn that `planning.current_milestone` will update to the next Now milestone, or null if none remain.

### Action 2: Add New Milestone

Follow the same interview steps as documented in `/add:milestone --create` (3-8 questions scaled by maturity). Do not invoke the milestone skill directly — replicate the interview inline so changes can be batched with other roadmap edits.

### Action 3: Archive Milestone

Show the milestone, then:
```
Options:
  1. Archive — mark COMPLETE in PRD, keep milestone file
  2. Cancel
```

If milestone is IN_PROGRESS with active features, warn: "This milestone has active work. Complete or rescope features first."

### Action 4: Update Goal

Show current goal, ask for new text. Optionally update target maturity and appetite.

### Step 3: Confirm All Changes

Before applying, show a summary:

```
Changes to apply:

1. MOVE M4 (Payment Integration): Next → Now
2. MOVE M3 (Auth Overhaul): Now → Next
3. ADD M7 (Notification System) to Later
4. CONFIG: planning.current_milestone → "M4-payment-integration"

Files to modify:
  - docs/prd.md (Section 6 + revision history)
  - docs/milestones/M4-payment-integration.md (goal update)
  - docs/milestones/M7-notification-system.md (NEW)
  - .add/config.json (planning.current_milestone)

Apply all changes? (y/n)
```

### Step 4: Apply Changes

1. **Update `docs/prd.md` Section 6:**
   - Rewrite roadmap table with updated horizons/statuses, ordered: Now first, then Next, then Later
   - Update milestone detail blocks
   - Append to Section 10 (Revision History): `| {DATE} | {VERSION} | roadmap | {summary} |`

2. **Update milestone files:** Edit existing (goal, status), create new from `${CLAUDE_PLUGIN_ROOT}/templates/milestone.md.template`

3. **Update `.add/config.json`:** Set `planning.current_milestone` to first non-COMPLETE Now milestone, or null

4. **Update `.add/handoff.md`** if it exists — append a note summarizing the roadmap changes for session continuity

### Step 5: Present Result

```
Roadmap updated.

  M4 (Payment Integration) → Now (active milestone)
  M3 (Auth Overhaul) → Next
  M7 (Notification System) added to Later

Next: /add:cycle --plan to start work on M4
```

---

## Command: /roadmap --reorder

Quick reordering without the full edit menu.

### Step 1: Show Current Order

```
Current Roadmap:

NOW:   1. M3 — Authentication Overhaul (IN_PROGRESS, ~55%)
NEXT:  2. M4 — Payment Integration (NOT_STARTED)
       3. M5 — Analytics Dashboard (NOT_STARTED)
LATER: 4. M6 — Multi-tenant Support (NOT_STARTED)
```

### Step 2: Ask for New Order

```
Enter new order grouped by horizon. Use | to separate horizons.
Example: "2 | 1, 3 | 4" → M4 to Now, M3+M5 to Next, M6 to Later

Current: 1 | 2, 3 | 4
New order:
```

Validate:
- All milestone numbers accounted for
- POC/Alpha: warn if >1 milestone in Now
- Beta/GA: allow multiple Now (parallel work)

### Step 3: Confirm and Apply

Show proposed layout. On confirmation, apply same logic as `--edit` Step 4.

---

## File Synchronization Rules

**PRD is source of truth for horizon placement.** Milestone files are source of truth for status and content.

### Sync Protocol

1. Parse existing PRD Section 6 roadmap table
2. Rebuild table in horizon order (Now → Next → Later), preserving order within horizons unless reorder requested
3. Update milestone detail blocks to match
4. Update `.add/config.json` `planning.current_milestone` to first non-COMPLETE Now milestone

### Conflict Resolution

| Conflict | --view behavior | --edit behavior |
|----------|----------------|-----------------|
| Milestone COMPLETE but in Now | Show warning | Auto-suggest archive or move to Later |
| File exists but not in PRD | Show as orphaned | Offer to add to roadmap |
| PRD references missing file | Show as missing | Offer to create from template |

---

## Integration

| Skill | Relationship |
|-------|-------------|
| `/add:init` | Creates initial milestones. Roadmap manages them afterward. |
| `/add:milestone` | Tactical ops (switch, split, rescope). Roadmap does strategic horizon planning. |
| `/add:cycle` | Reads `planning.current_milestone` set by roadmap changes. |
| `/add:dashboard` | Reads milestone data. Roadmap ensures consistency. |

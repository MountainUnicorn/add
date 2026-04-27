---
description: "[ADD v0.9.2] Manage milestones — list, switch, split, rescope, create"
argument-hint: "[--list | --switch <id> | --split <id> | --rescope <id> | --create]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite]
references: ["rules/telemetry.md"]
---

# ADD Milestone Command v0.9.2

Manage milestones directly — list status, switch active milestone, split large milestones, rescope features, or create new ones. This is the tactical companion to `/add:roadmap` (strategic horizon planning).

---

## Pre-Flight

All subcommands start here:

1. **Read `.add/config.json`** — extract `maturity.level`, `planning.current_milestone`, `planning.current_cycle`
   - If not found: abort with "No ADD project found. Run `/add:init` first."
2. **Glob `docs/milestones/M*.md`** — discover all milestone files
3. **Parse each milestone file** — extract:
   - Status (NOT_STARTED / IN_PROGRESS / COMPLETE)
   - Goal (first line under `## Goal`)
   - Features (from Feature Detail table: name, position, spec link)
   - Success criteria (count checked `[x]` vs total `[ ]`)
4. **Read `docs/prd.md` Section 6** — cross-reference horizon placement (Now/Next/Later) from the roadmap table
5. **Read `.add/handoff.md`** if it exists — note any in-progress decisions relevant to milestone changes
6. **Determine subcommand** from arguments. Default: `--list`

---

## Command: /milestone --list (default)

Display all milestones with live status. No file modifications.

### Output

```
Milestones Overview
Active: {planning.current_milestone or "None"}

| # | Milestone | Status | Horizon | Features | Complete | Target |
|---|-----------|--------|---------|----------|----------|--------|
| → | M1-foundation | IN_PROGRESS | NOW | 5 | 40% (2/5) | alpha |
|   | M2-scaling | NOT_STARTED | NEXT | 3 | 0% (0/3) | beta |
|   | M3-enterprise | NOT_STARTED | LATER | 4 | 0% (0/4) | ga |
```

- `→` marks the active milestone
- Completion % = features at VERIFIED or DONE / total features
- Horizon comes from PRD roadmap table; show "?" if milestone not in PRD

### Maturity Scaling

- **POC/Alpha:** Table as shown above
- **Beta/GA:** Add columns for Appetite Remaining, Risk Count, Cycle Count

---

## Command: /milestone --switch <id>

Switch the active milestone. Accepts milestone ID like `M2-scaling` or just `M2`.

### Step 1: Resolve Target

Find the milestone file matching the argument:
- Try `docs/milestones/{id}.md` directly
- Try `docs/milestones/M{N}-*.md` glob if only a number given
- If no match: "Milestone '{id}' not found. Run `/add:milestone --list` to see available milestones."

### Step 2: Safety Checks

**If target is COMPLETE:**
```
M1-foundation is marked COMPLETE.
Switching to a completed milestone is unusual — are you sure?
(This won't reopen it, but new cycles would target it.)
```
Ask via AskUserQuestion. Proceed only if confirmed.

**If current milestone has IN_PROGRESS features:**
```
Current milestone {name} has features in progress:
  - Auth Overhaul (IN_PROGRESS, cycle-8)
  - Session Refresh (PLANNED, cycle-8)

These will remain in their current state. Continue?
```
Ask via AskUserQuestion.

**If active cycle exists** (check `.add/cycles/` for non-COMPLETE cycles):
```
Active cycle {cycle-N} is tied to {current_milestone}.
Switching milestones won't close this cycle. You may want to
run /add:cycle --complete first, or the cycle will be orphaned.

Continue anyway?
```

### Step 3: Apply Switch

1. Update `.add/config.json`:
   - Set `planning.current_milestone` to target milestone ID
   - Scan `.add/cycles/` for cycles referencing the target milestone; set `planning.current_cycle` to the latest non-COMPLETE one, or `null` if none
2. If target milestone Status is NOT_STARTED:
   - Update milestone file: set `Status: IN_PROGRESS`, set `Started: {TODAY}`
3. Present summary:

```
Switched active milestone:
  From: M1-foundation (IN_PROGRESS)
  To:   M2-scaling (now IN_PROGRESS)

Config updated:
  planning.current_milestone → "M2-scaling"
  planning.current_cycle → null (no existing cycles for M2)

Next: Run /add:cycle --plan to plan the first cycle for M2.
```

---

## Command: /milestone --split <id>

Split a milestone into two. Interactive interview to redistribute features.

### Step 1: Load and Display

Read the target milestone file. Display:
```
Splitting: M3 — Marketplace Ready
Goal: Build and launch the marketplace feature set
Features (6):
  1. Product Listings (SPECCED)
  2. Search & Filter (SHAPED)
  3. Shopping Cart (SHAPED)
  4. Checkout Flow (SHAPED)
  5. Seller Dashboard (SHAPED)
  6. Order Management (SHAPED)
```

### Step 2: Interview (5 questions, 1-by-1)

**Q1:** "What's the split point? List the feature numbers that stay in the original milestone."
→ Captures: feature distribution

**Q2:** "What's the goal for the NEW milestone? (The original milestone keeps its current goal unless you change it.)"
→ Captures: new milestone goal

**Q3:** "Name for the new milestone? (Suggestion: M{next}-{slug})"
→ Captures: new milestone ID and name

**Q4:** "Appetite for each? Redistribute the original budget or set new ones."
→ Captures: appetite for both milestones

**Q5:** "Where does the new milestone sit in the roadmap? (Now/Next/Later)"
→ Captures: horizon placement

### Step 3: Confirm

```
Split plan:

ORIGINAL: M3 — Marketplace Ready (keeps 3 features)
  Features: Product Listings, Search & Filter, Shopping Cart
  Appetite: 2 weeks
  Horizon: NOW

NEW: M4 — Seller Experience (gets 3 features)
  Features: Checkout Flow, Seller Dashboard, Order Management
  Appetite: 3 weeks
  Horizon: NEXT

Files to create/modify:
  - docs/milestones/M3-marketplace-ready.md (remove 3 features)
  - docs/milestones/M4-seller-experience.md (NEW)
  - docs/prd.md (add M4 to roadmap table)
  - .add/config.json (no change — M3 stays active)

Proceed?
```

### Step 4: Apply

1. Edit original milestone file — remove redistributed features from Hill Chart and Feature Detail table
2. Create new milestone file from `${CLAUDE_PLUGIN_ROOT}/templates/milestone.md.template` — populate with moved features (keep their current positions), goal, appetite
3. Update `docs/prd.md` Section 6 — add new milestone row to roadmap table at the specified horizon
4. If original milestone was the active one and all its remaining features are DONE, flag it

---

## Command: /milestone --rescope <id>

Interactively move features between milestones. Lighter than split — for fine-tuning scope.

### Step 1: Display Current State

Show features in the target milestone and adjacent milestones:

```
Rescoping: M2 — Scaling (3 features)

M2 features:
  1. Load Balancer Setup (IN_PROGRESS)
  2. Database Sharding (SPECCED)
  3. CDN Integration (SHAPED)

Adjacent milestones:
  M1 — Foundation (5 features): Auth, Users, Profiles, Settings, Onboarding
  M3 — Enterprise (4 features): SSO, Audit Log, RBAC, Compliance
```

### Step 2: Interactive Rescoping

Ask 1-by-1:

**Q1:** "Move any features OUT of M2? (List numbers, or 'none')"
→ If yes: "Where should each go? (target milestone ID)"

**Q2:** "Move any features IN from other milestones? (List as 'M1:Auth, M3:SSO', or 'none')"

**Q3:** "Add any brand new features? (Name + brief description, or 'none')"
→ If yes, note: "New features will be added at SHAPED position. Create specs with `/add:spec`."

**Q4:** "Should M2's goal or appetite change given the new scope?"

### Step 3: Confirm and Apply

Show change summary. On confirmation:
1. Edit source milestone — remove outgoing features
2. Edit target milestones — add incoming features at their current position
3. Edit rescoped milestone — add new features at SHAPED, update goal/appetite if changed
4. Update PRD Section 6 if milestone scope changed significantly
5. Append to PRD Section 10 (Revision History): `| {DATE} | {VERSION} | milestone | Rescoped {milestone}: {summary of changes} |`
6. Update `.add/handoff.md` if it exists — note the rescoping for session continuity

---

## Command: /milestone --create

Create a new milestone from scratch with a lightweight interview.

### Interview (scaled by maturity)

**All maturities:**

**Q1:** "What's the milestone goal? (1-2 sentences — what does 'done' look like?)"

**Q2:** "Name? (Suggestion: M{next_number}-{slug})"

**Q3:** "Roadmap horizon? (Now / Next / Later)"

**Alpha+:**

**Q4:** "Effort appetite? (e.g., '2 weeks', '3 cycles', 'exploratory')"

**Q5:** "Known features to include? (Comma-separated names, or 'none yet')"

**Beta+:**

**Q6:** "Success criteria? (List 3-5 measurable signals of completion)"

**Q7:** "Any dependencies on other milestones or external factors?"

**Q8:** "Target maturity level for this milestone? (poc/alpha/beta/ga)"

### Generate

1. Determine next milestone number from existing files
2. Create `docs/milestones/M{N}-{slug}.md` from `${CLAUDE_PLUGIN_ROOT}/templates/milestone.md.template`
3. Populate: Goal, Status: NOT_STARTED, Features (all at SHAPED), Appetite, Success Criteria, Dependencies
4. Update `docs/prd.md` Section 6 — add row to roadmap table at the specified horizon
5. If no active milestone exists, offer: "No active milestone set. Switch to M{N}? (y/n)"
   - If yes, update `planning.current_milestone` in config

### Present

```
Milestone created: docs/milestones/M{N}-{slug}.md

Goal: {goal}
Horizon: {horizon}
Features: {count} (all SHAPED)
Appetite: {appetite}

Next steps:
  1. Create specs for features: /add:spec {feature-name}
  2. Switch to this milestone: /add:milestone --switch M{N}
  3. Plan first cycle: /add:cycle --plan
```

---

## Error Handling

**No milestones exist:**
- `--list`: "No milestones found. Create one with `/add:milestone --create` or run `/add:init`."
- `--switch/--split/--rescope`: "Milestone not found."

**Milestone file unparseable:**
- Skip in `--list`, show warning
- For targeted commands, report: "Could not parse {file}. Check the file format against the milestone template."

**PRD Section 6 missing:**
- Commands still work (milestones are the source of truth for content)
- Warn: "PRD roadmap table not found — milestone files updated but PRD not synced. Run `/add:roadmap --edit` to rebuild."

---

## Integration

| Skill | Relationship |
|-------|-------------|
| `/add:cycle` | Reads `planning.current_milestone`. Milestone skill sets this value. |
| `/add:roadmap` | Manages horizon placement. Milestone skill manages content and switching. |
| `/add:spec` | Creates feature specs listed in milestones. |
| `/add:promote` | Milestone completion can trigger promotion readiness. |

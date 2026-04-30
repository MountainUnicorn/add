---
name: add-ux
description: "[ADD v0.9.5] Iterate on UI/UX design before implementation — wireframes, flow validation, and design sign-off"
argument-hint: "<spec-file> [--figma <url-or-frame-id>]"
---

# ADD UX Command v0.9.5

Iterate on UI/UX design for a feature before implementation begins. Produces a signed-off design artifact that gates `/add:plan` and `/add:tdd-cycle`. Prevents token burn from building the wrong UI.

## Pre-Flight

1. Read `.add/config.json` to understand project context and maturity level
2. If `spec-file` argument is provided, read it. Otherwise, list specs in `specs/` and ask which feature to design
3. Verify the spec exists and has a UI component (Q8 answered, or acceptance criteria mention UI states)
   - If no UI component is detectable, confirm with the human: "This spec doesn't appear to have a UI — do you still want to run a UX iteration?"
4. Check if a UI artifact already exists at `specs/ux/{feature-slug}-ux.md`
   - If it does, and it's marked `Status: APPROVED`, ask: "This feature already has a signed-off design. Start over or review the existing one?"

---

## Phase 1: Design Source

Determine where the design will come from.

### Step 1: Check for Figma MCP

Attempt to detect whether a Figma MCP tool is available in the current session.

**If `--figma` argument was provided OR Figma MCP is available:**
```
Figma integration detected.

Options:
  A) Provide a Figma file URL or frame ID to start from an existing design
  B) Skip Figma and generate wireframes from scratch
```

If the human provides a Figma link:
- Use the Figma MCP to read the frame(s)
- Summarize what was found: screen names, key components, flow structure
- Note: Figma MCP is read-only — changes happen in conversation, not in Figma itself
- Proceed to Phase 2 with the Figma content as the starting point

**If no Figma MCP and no `--figma` argument:**
- Skip Figma detection silently
- Proceed directly to wireframe generation in Phase 2

---

## Phase 2: UX Iteration Loop

This phase is a conversation loop. Repeat until the human approves the design or explicitly exits.

### Step 1: Understand the UI Requirements

Before generating anything, ask focused questions to understand what needs to be designed. Keep it tight — 3-5 questions max.

**Q1:** "What are the primary screens or views in this feature?"
→ Captures: screen inventory

**Q2:** "Walk me through the main user flow — what does the user do, step by step?"
→ Captures: primary path, transitions between screens

**Q3:** "What are the key UI states? Think: loading, empty, error, success, edge cases."
→ Captures: state matrix — the most commonly missed UX work

**Q4 (optional):** "Are there any existing patterns in the app this should follow? Or intentional departures?"
→ Captures: design system constraints, intentional exceptions

**Q5 (optional):** "Any mobile/responsive requirements, accessibility constraints, or performance-sensitive areas?"
→ Captures: non-functional UX requirements

### Step 2: Generate Initial Wireframes

Based on the answers (and Figma content if available), generate wireframes for each screen.

Use ASCII wireframes by default. They are fast to generate, easy to iterate on in conversation, and require no external tools.

**ASCII wireframe format:**
```
┌─────────────────────────────────┐
│  Screen Name                    │
├─────────────────────────────────┤
│  [Header / Nav]                 │
│                                 │
│  ┌───────────────────────────┐  │
│  │  Primary content area     │  │
│  │                           │  │
│  │  [Component A]            │  │
│  │  [Component B]            │  │
│  └───────────────────────────┘  │
│                                 │
│  [CTA Button]   [Secondary]     │
└─────────────────────────────────┘
```

Generate all primary screens in sequence. Label each clearly. Show transitions between screens with arrows or notes.

After generating, present the full set:
```
Here's the initial design for {feature-name}:

Screen 1: {Name} — {one-line description}
{wireframe}

Screen 2: {Name} — {one-line description}
{wireframe}

[etc.]

State matrix:
  Loading:  {description or wireframe}
  Empty:    {description or wireframe}
  Error:    {description or wireframe}
  Success:  {description or wireframe}

Does this capture the intent? What would you change?
```

### Step 3: Iterate

The human will respond with feedback. Common patterns:

- **"Move X to Y"** → Update the affected wireframe(s), re-display only what changed
- **"Add a state for Z"** → Add to the state matrix
- **"What about mobile?"** → Generate responsive variant(s)
- **"Can we simplify this?"** → Consolidate screens, reduce cognitive load, explain the trade-off
- **"Show me option B"** → Generate an alternative approach side-by-side

Keep iterating until one of:
- Human says something like "looks good", "ship it", "I'm happy with this" → move to Phase 3
- Human explicitly exits: "stop", "skip sign-off" → write draft artifact and note it's unsigned

**Iteration discipline:**
- Never silently change something that wasn't mentioned
- Call out any UX concerns you notice (e.g., "this flow requires 5 taps to reach a frequent action — worth reconsidering?")
- If a requested change conflicts with a stated acceptance criterion, flag it: "This change would affect AC-003 — should we update the spec too?"

---

## Phase 3: Sign-Off and Artifact

Once the human approves the design:

### Step 1: Summarize the Design

Present a clean summary before writing the artifact:
```
Design approved for: {feature-name}

Screens: {N}
  • {Screen 1}: {one-liner}
  • {Screen 2}: {one-liner}

States covered: loading, empty, error, success{, and X}

Key decisions made:
  • {Decision 1 and rationale}
  • {Decision 2 and rationale}

Spec impact: {None | "AC-003 should be updated to reflect..."}
```

### Step 2: Write the UX Artifact

Write to `specs/ux/{feature-slug}-ux.md`:

```markdown
# UX Design: {Feature Name}

**Spec:** specs/{feature-slug}.md
**Status:** APPROVED
**Approved:** {date}
**Iterations:** {N}

## Screens

### {Screen 1 Name}
{ASCII wireframe}
{Notes}

### {Screen 2 Name}
{ASCII wireframe}
{Notes}

[etc.]

## State Matrix

| State    | Behavior | Notes |
|----------|----------|-------|
| Loading  | {description} | |
| Empty    | {description} | |
| Error    | {description} | |
| Success  | {description} | |

## Flow

{Description of transitions between screens}

## Key Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| {decision} | {why} | {what else was considered} |

## Figma Reference

{If Figma was used: URL, frame names, notes on divergence from Figma}
{If no Figma: "N/A — wireframes generated in session"}

## Spec Notes

{Any acceptance criteria or spec sections that should be updated based on design decisions}
```

### Step 3: Update the Feature Spec

If any spec updates are needed (e.g., Q8 was empty and is now filled in, or a design decision affects an AC):
1. Read `specs/{feature-slug}.md`
2. Update the relevant sections (UI states, acceptance criteria, notes)
3. Add a note: `UI design approved — see specs/ux/{feature-slug}-ux.md`

### Step 4: Present Next Steps

```
UX design signed off: specs/ux/{feature-slug}-ux.md

This feature is now ready for implementation planning.

Next steps:
  /add:plan specs/{feature-slug}.md    — create implementation plan
  /add:tdd-cycle specs/{feature-slug}.md — jump straight into TDD
```

If spec was updated:
```
Note: specs/{feature-slug}.md was updated to reflect design decisions.
Review the changes before proceeding.
```

---

## Maturity Behavior

| Maturity | UX Gate Required? | Wireframe Depth | Sign-Off |
|----------|-------------------|-----------------|----------|
| POC      | Optional (prompted) | Minimal — key screen only | Informal ("looks good") |
| Alpha    | Recommended for UI features | Primary screens + states | Human confirms in chat |
| Beta     | Required for user-facing features | All screens + full state matrix | Explicit approval + artifact written |
| GA       | Required for all UI changes | All screens + states + responsive + a11y notes | Artifact written + spec updated |

At POC maturity, the skill will note: "UX gate is optional at POC maturity. Skipping means accepting rework risk if the design needs to change after implementation."

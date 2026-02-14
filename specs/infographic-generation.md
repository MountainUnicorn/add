# Spec: Infographic Generation

**Version:** 0.1.0
**Created:** 2026-02-14
**PRD Reference:** docs/prd.md
**Status:** Draft

## 1. Overview

A skill that generates a professional SVG infographic (`docs/infographic.svg`) for any ADD-managed project. Sources content from `docs/prd.md` and `.add/config.json`. Follows the Silicon Valley Unicorn design aesthetic with configurable branding from the project's branding config. Optionally enhanced with image generation MCP tools when available. Auto-embedded in README.md.

### User Story

As a developer using ADD, I want a polished project infographic generated automatically from my PRD and config, so that my README and documentation have professional visuals without manual design work.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `/add:infographic` generates `docs/infographic.svg` from project PRD and config | Must |
| AC-002 | Infographic uses branding from `.add/config.json` (accent color, palette) | Must |
| AC-003 | SVG follows Silicon Valley Unicorn aesthetic: dark background (#1a1a2e gradient), glassmorphism cards, gradient orbs, generous whitespace | Must |
| AC-004 | SVG viewBox is 1200x800 (landscape, optimized for README embedding) | Must |
| AC-005 | Required sections: header bar, hero value proposition, metrics bar, workflow panel (3-4 steps), value cards (3-4 outcomes), terminal command showcase, footer | Must |
| AC-006 | Hero headline is outcome-focused (value, not features) — sourced from PRD problem statement/success metrics | Must |
| AC-007 | Metrics bar shows real project data: feature count from specs/, test count, quality gate status, maturity level | Must |
| AC-008 | Workflow panel shows the project's actual workflow (from PRD or inferred from ADD commands) | Must |
| AC-009 | If image gen MCP is available (per image-gen-detection spec), use it to generate hero image or feature illustrations | Should |
| AC-010 | If image gen is not available, SVG-only mode produces a complete, professional infographic | Must |
| AC-011 | Auto-embed in README.md: `![Project Infographic](docs/infographic.svg)` if not already present | Should |
| AC-012 | `/add:infographic --update` regenerates from current project state (re-reads PRD, config, spec count, etc.) | Must |
| AC-013 | SVG uses only inline styles, no external CSS (GitHub strips `<style>` tags) | Must |
| AC-014 | SVG uses system fonts: `system-ui, -apple-system, sans-serif` for text, monospace for code | Must |
| AC-015 | All gradients and filters defined in `<defs>` block | Must |
| AC-016 | File size > 5KB (full infographic, not a stub) | Must |
| AC-017 | No template placeholders in output (all `{VARIABLE}` replaced with real content) | Must |
| AC-018 | Verification step confirms all required sections present before reporting success | Must |

## 3. User Test Cases

### TC-001: Generate infographic for new project

**Precondition:** ADD initialized, `docs/prd.md` exists, `.add/config.json` has branding configured
**Steps:**
1. Run `/add:infographic`
**Expected Result:** `docs/infographic.svg` created with:
- Project name and version from config
- Hero headline derived from PRD problem statement
- Metrics from current project state
- Branding colors from config
- All 7 required sections present
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-002: Infographic with custom branding

**Precondition:** ADD initialized with ocean (#0891b2) accent color
**Steps:**
1. Run `/add:infographic`
**Expected Result:** SVG uses ocean palette throughout — accent gradients, orb colors, card highlights all derive from #0891b2
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-003: Update existing infographic

**Precondition:** `docs/infographic.svg` exists from a previous run. New specs added since then.
**Steps:**
1. Run `/add:infographic --update`
**Expected Result:** Infographic regenerated with updated metrics (new spec count, updated feature list). Previous file overwritten.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-004: Infographic with image gen available

**Precondition:** ADD initialized, imgGen MCP tool available
**Steps:**
1. Run `/add:infographic`
**Expected Result:** Detection finds image gen. Hero section includes AI-generated illustration. Rest of SVG rendered as normal.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-005: Infographic without image gen (SVG-only)

**Precondition:** ADD initialized, no image gen MCP
**Steps:**
1. Run `/add:infographic`
**Expected Result:** Full infographic generated in SVG-only mode. Hero uses gradient/text-based design instead of generated image. Professional quality maintained.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-006: Auto-embed in README

**Precondition:** README.md exists but doesn't reference infographic
**Steps:**
1. Run `/add:infographic`
**Expected Result:** After generating SVG, README.md updated with `## Overview\n\n![Project Infographic](docs/infographic.svg)` added near the top (after title/badges, before content).
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-007: README already has infographic reference

**Precondition:** README.md already contains `![Project Infographic](docs/infographic.svg)`
**Steps:**
1. Run `/add:infographic --update`
**Expected Result:** SVG regenerated. README.md NOT modified (reference already exists).
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-008: Verification catches missing sections

**Precondition:** SVG generation somehow skips the metrics bar
**Steps:**
1. Internal verification step runs after generation
**Expected Result:** Verification detects missing metrics section. Regenerates the infographic with all required sections. Only reports success after all checks pass.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

## 4. Data Model

### Content Sources

| Data Point | Source | Fallback |
|-----------|--------|----------|
| Project name | `.add/config.json` → `project.name` | Directory name |
| Project description | `docs/prd.md` → Section 1 | Config description |
| Version | `.add/config.json` → `version` | "0.1.0" |
| Hero headline | Derived from PRD problem statement | Project description |
| Metrics | Live scan: spec count, test count, maturity level, quality mode | Zeros for missing data |
| Workflow steps | PRD Section 6 or ADD default workflow | Spec → Plan → Build → Verify |
| Value cards | PRD success metrics or key features | Inferred from feature set |
| Tech stack | `.add/config.json` → `architecture.languages` | "Markdown + JSON" |
| Terminal command | Primary run command from config | `/add:init` |
| Accent color | `.add/config.json` → `branding.accentColor` | "#b00149" (raspberry) |
| Palette | `.add/config.json` → `branding.palette` | Generated from default accent |

### SVG Structure

```
<svg viewBox="0 0 1200 800">
  <defs>
    linearGradient#heroGrad     — dark background gradient
    linearGradient#accentGrad   — user's palette gradient
    linearGradient#glowGrad     — gradient orb effect
    linearGradient#cardGrad     — glassmorphism card fill
    linearGradient#metricGrad   — success/metric color
    filter#glass                — glassmorphism drop shadow
  </defs>

  <rect>                        — dark background fill
  <ellipse> x2                  — gradient orbs for depth

  Section 1: Header bar         — logo area + project name + version pill
  Section 2: Hero               — eyebrow + headline + subheadline
  Section 3: Metrics bar        — 3-4 stat cards in glass container
  Section 4: Workflow panel     — 3-4 numbered steps
  Section 5: Value cards        — 3-4 outcome-focused cards
  Section 6: Terminal           — command showcase with syntax highlight
  Section 7: Footer             — attribution + license
</svg>
```

### Relationships

- Reads branding from `.add/config.json` (branding system spec)
- Uses image gen if available (image-gen-detection spec)
- Referenced by README.md
- Design system from enterprise plugin's `design-system.md` rule (adapted for ADD)

## 5. API Contract (if applicable)

N/A — CLI skill producing a file artifact.

## 6. UI Behavior (if applicable)

N/A — Generates a static SVG file. Viewable in browser, GitHub README, or any SVG viewer.

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No PRD exists | Use `.add/config.json` project info only. Warn: "No docs/prd.md found — infographic will use config data only. Run /add:init for richer content." |
| PRD exists but is minimal (POC maturity) | Generate simpler infographic — fewer value cards, basic metrics. Match maturity level. |
| Very long project name (>30 chars) | Truncate with "..." in header bar, use full name in hero if it fits |
| No specs exist yet | Metrics bar shows "0 specs" — still valid |
| `docs/` directory doesn't exist | Create it: `mkdir -p docs` |
| SVG file already exists | Overwrite (infographic is always regenerable from current state) |
| GitHub renders SVG differently than local | Use only inline styles, system fonts, no foreignObject — maximize GitHub SVG compatibility |
| User runs infographic before branding is configured | Use defaults (raspberry). Note: "Using default branding. Run /add:brand-update to customize." |
| Image gen produces an unusable image | Fall back to SVG-only for that element, log warning |

## 8. Dependencies

- **Branding system spec** — reads palette and accent from config
- **Image gen detection spec** — checks for MCP tools at execution time
- **Enterprise plugin design-system.md** — aesthetic rules to port/adapt
- **Enterprise plugin enterprise.md** — SVG template structure to port
- **`docs/prd.md`** — primary content source
- **`.add/config.json`** — project metadata and branding

## 9. Implementation Notes

### Files to create/modify

- **New:** `skills/infographic/SKILL.md` — `/add:infographic` skill definition
- **New:** `templates/infographic.svg.template` — base SVG template with placeholder sections
- **New or modify:** `rules/design-system.md` — ADD's design system rule (ported from enterprise, adapted)
- **Modify:** `commands/init.md` — mention infographic in Phase 5 summary as a next step

### SVG Generation Strategy

The skill should:
1. Read all content sources (PRD, config, live metrics)
2. Run image gen detection (per image-gen-detection spec)
3. Compose the SVG using the template + content
4. If image gen available, generate hero illustration and embed as base64 `<image>`
5. Write to `docs/infographic.svg`
6. Run verification checks (all 7 sections present, no placeholders, file size > 5KB)
7. Update README.md if needed
8. Report success with file size

### Porting from Enterprise

The enterprise plugin's Phase 4 (infographic generation) is the proven reference implementation. Key adaptations for ADD:
- Content sourced from ADD's document hierarchy (PRD + config) not spike analysis
- Default to ADD branding (raspberry) not enterprise branding (purple)
- Simpler — no spike tracking JSON, just project documentation
- Maturity-aware — POC gets simpler infographic than GA

### Verification Checklist (automated)

- [ ] File exists at `docs/infographic.svg`
- [ ] viewBox is `0 0 1200 {height}` (1200 wide)
- [ ] Contains dark background (`#1a1a2e` or similar)
- [ ] Contains `linearGradient id="heroGrad"`
- [ ] Contains `linearGradient id="accentGrad"` with user's palette
- [ ] Contains `filter id="glass"`
- [ ] Contains project name (not placeholder)
- [ ] Contains hero headline text
- [ ] Contains metrics section
- [ ] Contains workflow section
- [ ] Contains value cards section
- [ ] Contains terminal section
- [ ] File size > 5KB

## 10. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec conversation |

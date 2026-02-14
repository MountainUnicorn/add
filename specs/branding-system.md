# Spec: Branding System

**Version:** 0.1.0
**Created:** 2026-02-14
**PRD Reference:** docs/prd.md
**Status:** Draft

## 1. Overview

A project-level branding system that captures visual identity (colors, fonts, tone, logos) during initialization and provides commands to view and update branding across all generated artifacts. Branding configuration drives infographics, HTML reports, README visuals, and any image-gen-enhanced documentation.

### User Story

As a developer using ADD, I want my project's visual identity consistently applied to all generated documentation artifacts, so that reports, infographics, and READMEs look professional and on-brand without manual styling.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | `/add:init` asks whether the user has a brand/style guide and stores the answer in `.add/config.json` under a `branding` key | Must |
| AC-002 | If user has no brand guide, ADD applies sensible defaults (raspberry #b00149 accent, Silicon Valley Unicorn aesthetic) | Must |
| AC-003 | If user provides brand materials (colors, fonts, tone, logo path, style guide URL), they are parsed and stored in `.add/config.json` branding section | Must |
| AC-004 | `/add:brand` command displays current branding configuration: accent color, palette, fonts, tone, logo, style guide source, and where branding is applied | Must |
| AC-005 | `/add:brand` detects brand drift — artifacts using colors/fonts that differ from the configured brand — and reports discrepancies | Should |
| AC-006 | `/add:brand` shows image generation capability status (detected/not detected) with setup guidance if missing | Should |
| AC-007 | `/add:brand-update` accepts new branding materials (hex colors, font names, tone description, logo path, style guide URL/file) | Must |
| AC-008 | `/add:brand-update` updates `.add/config.json` branding section with new values | Must |
| AC-009 | `/add:brand-update` audits all existing generated artifacts (infographic, reports, README) for brand consistency and produces a diff-style report of needed changes | Must |
| AC-010 | `/add:brand-update` optionally applies brand fixes to artifacts with user confirmation | Should |
| AC-011 | Palette is auto-generated from accent color using HSL transformations (gradientStart, gradientMid, gradientEnd, accentLight, accentDark, success) | Must |
| AC-012 | Branding config is committed to git via `.add/config.json` so it's shared across team members | Must |
| AC-013 | Color presets are available (raspberry, purple, ocean, forest, sunset, midnight) as shortcuts during init and brand-update | Nice |

## 3. User Test Cases

### TC-001: First-time init with no brand guide

**Precondition:** New project, no `.add/config.json` exists
**Steps:**
1. Run `/add:init`
2. Complete standard interview questions
3. When asked "Do you have a brand or style guide?", select "No — use ADD defaults"
**Expected Result:** `.add/config.json` contains `branding` key with raspberry (#b00149) accent, auto-generated palette, null fonts/tone/logo/styleGuideSource
**Screenshot Checkpoint:** N/A (CLI output)
**Maps to:** TBD

### TC-002: Init with brand materials provided

**Precondition:** New project, user has a style guide
**Steps:**
1. Run `/add:init`
2. When asked about brand guide, select "Yes — let me share it"
3. Provide: accent color #0891b2, font "Inter", tone "professional but approachable", logo path "assets/logo.svg"
**Expected Result:** `.add/config.json` branding section populated with provided values. Palette auto-generated from #0891b2.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-003: View current branding with /add:brand

**Precondition:** ADD initialized with branding configured
**Steps:**
1. Run `/add:brand`
**Expected Result:** Displays formatted summary showing: accent color + palette preview, fonts, tone, logo path, style guide source, list of artifacts where branding is applied, image gen status, any brand drift detected
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-004: Brand drift detection

**Precondition:** ADD initialized with raspberry (#b00149) branding. `docs/infographic.svg` exists but uses #6366f1 (purple) accent.
**Steps:**
1. Run `/add:brand`
**Expected Result:** Output includes drift warning: "docs/infographic.svg uses #6366f1 but configured brand accent is #b00149"
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-005: Update branding with audit

**Precondition:** ADD initialized, infographic and report exist with old branding
**Steps:**
1. Run `/add:brand-update`
2. Provide new accent color #059669 (forest)
3. Review audit report showing artifacts needing updates
4. Confirm applying fixes
**Expected Result:** `.add/config.json` branding updated to forest palette. Audit report lists artifacts with old colors. On confirmation, artifacts are regenerated with new brand.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-006: Brand update with preset shortcut

**Precondition:** ADD initialized with defaults
**Steps:**
1. Run `/add:brand-update`
2. Select "Ocean" from color presets
**Expected Result:** Accent set to #0891b2, full palette generated, config updated
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

## 4. Data Model

### Branding (in .add/config.json)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| accentColor | string (hex) | Yes | Primary brand color, e.g. "#b00149" |
| palette | object | Yes | Auto-generated from accent: gradientStart, gradientMid, gradientEnd, accentLight, accentDark, success |
| palette.gradientStart | string (hex) | Yes | Darkened accent for gradient start |
| palette.gradientMid | string (hex) | Yes | Accent color (same as accentColor) |
| palette.gradientEnd | string (hex) | Yes | Lightened/shifted accent for gradient end |
| palette.accentLight | string (hex) | Yes | Lighter tint for hover/highlight states |
| palette.accentDark | string (hex) | Yes | Darker shade for depth/shadow |
| palette.success | string (hex) | Yes | Success/positive color (default #22c55e) |
| fonts | object or null | No | Font preferences: { heading, body, code } |
| tone | string or null | No | Brand voice description, e.g. "professional but approachable" |
| logoPath | string or null | No | Relative path to project logo file |
| styleGuideSource | string or null | No | URL or file path to original style guide |
| presetName | string or null | No | Name of color preset if used (raspberry, ocean, etc.) |

### Color Presets (shipped with plugin)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Preset display name |
| accent | string (hex) | Yes | Primary accent color |
| description | string | Yes | Short description |

### Relationships

- Branding is a section within `.add/config.json`, not a separate file
- All visual skills (infographic, reports) read branding from config at execution time
- Color presets live in plugin at `templates/presets.json` (read-only in consumer projects)

## 5. API Contract (if applicable)

N/A — CLI commands, not API endpoints.

## 6. UI Behavior (if applicable)

N/A — Terminal CLI output only. ANSI color codes used where supported for palette preview in `/add:brand` output.

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| User provides invalid hex color | Validate format, ask again. Accept 3-char (#b01) and 6-char (#b00149) hex. |
| User provides brand materials mid-project (not during init) | `/add:brand-update` handles this — init is not the only entry point |
| No artifacts exist yet when running `/add:brand` | Show branding config only, skip drift detection, note "No generated artifacts found yet" |
| User's terminal doesn't support true color | Palette preview degrades gracefully — show hex values as text instead of colored blocks |
| Existing `.add/config.json` has no branding key (pre-branding projects) | `/add:brand` and `/add:brand-update` add the key; `/add:brand` suggests running brand-update to configure |
| Team member has different brand config locally | Branding is in `.add/config.json` which is git-committed — shared across team |
| Style guide URL is inaccessible | Store the URL but don't fail; note it's stored for reference only |

## 8. Dependencies

- **Infographic generation spec** — branding config is consumed by infographic generation
- **Image gen detection spec** — `/add:brand` displays image gen status
- **Enterprise plugin presets.json** — color preset definitions and palette generation algorithm to be ported
- **`/add:init` command** — must be updated to include branding question in interview

## 9. Implementation Notes

### Files to create/modify

- **New:** `templates/presets.json` — color preset definitions (ported from enterprise)
- **Modify:** `commands/init.md` — add branding question to interview
- **Modify:** `.add/config.json` template — add `branding` section
- **New:** `commands/brand.md` — `/add:brand` command definition
- **New:** `commands/brand-update.md` — `/add:brand-update` command definition

### Palette Generation Algorithm

Port from enterprise `presets.json`. HSL-based transformations from accent color:
- gradientStart: accent hue, reduced saturation, darkened
- gradientMid: accent as-is
- gradientEnd: accent hue shifted +30deg, lightened
- accentLight: accent lightened 20%
- accentDark: accent darkened 20%
- success: #22c55e (constant)

## 10. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec conversation |

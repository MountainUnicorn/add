---
description: "[ADD v0.2.0] Update project branding — new colors, fonts, tone, audit artifacts"
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# ADD Brand Update Command v0.2.0

Update the project's branding configuration with new materials and audit existing generated artifacts for brand consistency. Optionally apply fixes to bring artifacts in line with the new brand.

## Pre-Flight

1. Check if `.add/config.json` exists. If not, tell the user to run `/add:init` first.
2. Read `.add/config.json` and extract the current `branding` section.
3. Read `${CLAUDE_PLUGIN_ROOT}/templates/presets.json` for available presets and palette generation algorithm.

## Arguments

The user provided: $ARGUMENTS

If arguments contain specific values (hex color, preset name, etc.), use them directly instead of asking.

## Phase 1: Collect New Branding

### Step 1.1: Determine Update Scope

Use AskUserQuestion:
```
Question: "What would you like to update?"
Options:
  - "Accent color only"
  - "Full brand refresh (color, fonts, tone, logo)"
  - "Apply a color preset"
```

### Step 1.2a: Accent Color Only

Use AskUserQuestion:
```
Question: "Choose a new accent color:"
Options:
  - "Raspberry (#b00149) — bold and warm"
  - "AI Purple (#6366f1) — classic tech"
  - "Ocean (#0891b2) — professional and calm"
  - "Custom hex color"
```

If "Custom hex color": Ask for the hex value. Validate it's a valid 3 or 6 character hex color (with or without #).

Generate the full palette from the selected color using the algorithm in `${CLAUDE_PLUGIN_ROOT}/templates/presets.json`:

1. Parse hex to RGB, convert to HSL
2. Generate all palette values (accentLight, accentDark, accentMuted, accentGlow, gradientStart, gradientMid, gradientEnd)
3. Keep fixed colors (success: #22c55e, warning: #eab308, info: #0ea5e9)

### Step 1.2b: Full Brand Refresh

Ask each in sequence:

**Color:** Same as Step 1.2a above.

**Fonts:** "Do you have font preferences?"
Use AskUserQuestion:
  - "Use system defaults (Recommended)"
  - "Let me specify fonts"

If specifying: Ask for heading font, body font, code font. Store in `branding.fonts`.

**Tone:** "Describe your brand's tone/voice in a few words (e.g., 'professional but approachable', 'bold and confident', 'technical and precise')."
(Default: null — no tone constraint)

**Logo:** "Path to your project logo file? (Leave empty to skip)"
(Default: null)

**Style Guide:** "URL or file path to your style guide? (Leave empty to skip)"
(Default: null)

### Step 1.2c: Apply a Color Preset

List presets from `${CLAUDE_PLUGIN_ROOT}/templates/presets.json`:

Use AskUserQuestion:
```
Question: "Choose a color preset:"
Options:
  - "Raspberry (#b00149) — bold and warm"
  - "AI Purple (#6366f1) — classic tech"
  - "Ocean (#0891b2) — professional and calm"
  - "Forest (#059669) — rich emerald green"
```

(If more than 4 presets, show the top 4 most popular. User can type "Other" for Sunset or Midnight.)

Load the full palette from the preset. Set `presetName` to the chosen preset.

## Phase 2: Update Configuration

### Step 2.1: Write Updated Config

Update `.add/config.json` `branding` section with the new values:

```json
"branding": {
  "accentColor": "{NEW_ACCENT}",
  "presetName": "{PRESET_NAME_OR_NULL}",
  "palette": {
    "accent": "{NEW_ACCENT}",
    "accentLight": "{GENERATED}",
    "accentDark": "{GENERATED}",
    "accentMuted": "{GENERATED}",
    "accentGlow": "{GENERATED}",
    "gradientStart": "{GENERATED}",
    "gradientMid": "{GENERATED}",
    "gradientEnd": "{GENERATED}",
    "success": "#22c55e",
    "warning": "#eab308",
    "info": "#0ea5e9"
  },
  "fonts": {"heading": "{OR_NULL}", "body": "{OR_NULL}", "code": "{OR_NULL}"},
  "tone": "{OR_NULL}",
  "logoPath": "{OR_NULL}",
  "styleGuideSource": "{OR_NULL}"
}
```

Use the Edit tool to update the branding section in `.add/config.json`. Preserve all other config sections.

### Step 2.2: Confirm Update

```
BRANDING UPDATED

  Previous: {old_accentColor} ({old_presetName or "custom"})
  New:      {new_accentColor} ({new_presetName or "custom"})

  Palette:
    Gradient:   {gradientStart} → {gradientMid} → {gradientEnd}
    Light/Dark: {accentLight} / {accentDark}
```

## Phase 3: Artifact Audit

### Step 3.1: Find Generated Artifacts

Scan for existing generated artifacts:
- `docs/infographic.svg`
- `reports/*.html`
- Any file in `docs/` or `reports/` that contains color hex values matching the OLD branding

### Step 3.2: Audit Each Artifact

For each found artifact, compare embedded colors against the NEW branding palette.

**SVG files:** Search for hex colors in gradient definitions, fill attributes, stroke attributes.
**HTML files:** Search for CSS variable definitions (`--accent:`), inline style colors, gradient definitions.

### Step 3.3: Report Audit Results

```
ARTIFACT AUDIT

  Found {N} generated artifacts:

  docs/infographic.svg
    → Uses old accent #6366f1 in {N} locations
    → Needs update: gradient definitions, card accents, metric highlights

  reports/spike-2026-02-14.html
    → Uses old accent #6366f1 in CSS variables
    → Needs update: --accent, --accent-light, --accent-dark

  {N} artifacts need brand updates.
```

If no artifacts found:
```
ARTIFACT AUDIT

  No generated artifacts found. New artifacts will use the updated branding.
```

### Step 3.4: Offer to Fix

If artifacts need updates:

Use AskUserQuestion:
```
Question: "{N} artifacts have outdated branding. Fix them now?"
Options:
  - "Yes — regenerate artifacts with new branding (Recommended)"
  - "No — I'll update them manually later"
```

**If "Yes":**
For each artifact type:
- **Infographic SVG:** If `/add:infographic` skill exists, suggest running it. Otherwise, use Edit tool to find-and-replace old palette hex values with new ones in the SVG.
- **HTML Reports:** Use Edit tool to update CSS variables and inline colors.

Report what was fixed:
```
FIXES APPLIED

  ✓ docs/infographic.svg — updated {N} color references
  ✓ reports/spike-2026-02-14.html — updated CSS variables

  All artifacts now match configured branding.
```

**If "No":**
```
Artifacts left as-is. Run /add:brand to check drift status anytime.
```

## Phase 4: Summary

```
BRAND UPDATE COMPLETE

  Accent:     {accentColor} ({presetName or "custom"})
  Artifacts:  {N} found, {M} updated
  Config:     .add/config.json updated

  View branding: /add:brand
```

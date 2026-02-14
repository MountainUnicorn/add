---
description: "[ADD v0.1.0] View project branding — accent color, palette, drift detection, image gen status"
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# ADD Brand Command v0.1.0

Display the current branding configuration for this ADD-managed project. Shows accent color, palette, fonts, tone, where branding is applied, detects brand drift in generated artifacts, and reports image generation capability status.

## Pre-Flight

1. Check if `.add/config.json` exists. If not, tell the user to run `/add:init` first.
2. Read `.add/config.json` and extract the `branding` section.
3. If no `branding` section exists, inform the user: "No branding configured. Run `/add:brand-update` to set up branding, or re-run `/add:init --reconfigure` to add it during setup."

## Phase 1: Display Current Branding

Read branding from `.add/config.json` and display:

```
PROJECT BRANDING

  Accent Color:   {accentColor} ({presetName or "custom"})
  Palette:
    Gradient:     {gradientStart} → {gradientMid} → {gradientEnd}
    Light/Dark:   {accentLight} / {accentDark}
    Muted:        {accentMuted}
    Success:      {palette.success}

  Fonts:          {fonts.heading}, {fonts.body}, {fonts.code} — or "Not configured (using system defaults)"
  Tone:           {tone} — or "Not configured"
  Logo:           {logoPath} — or "Not configured"
  Style Guide:    {styleGuideSource} — or "Not configured"

  Preset:         {presetName or "Custom color"}
```

## Phase 2: Artifact Scan & Drift Detection

Scan known artifact locations for brand consistency:

### Step 2.1: Find Generated Artifacts

Check for the existence of:
- `docs/infographic.svg`
- `reports/*.html` (glob for any HTML reports)
- `README.md` (check for embedded infographic reference)

### Step 2.2: Check for Color Drift

For each found artifact:

**SVG Infographic (`docs/infographic.svg`):**
- Read the file
- Search for hex color values in `linearGradient` elements and `fill`/`stroke` attributes
- Compare against configured `branding.palette` colors
- Flag any accent/gradient colors that don't match the configured palette

**HTML Reports (`reports/*.html`):**
- Read each file
- Search for CSS `--accent:` variable value
- Compare against configured `branding.accentColor`
- Flag mismatches

### Step 2.3: Report Drift

If drift detected:
```
BRAND DRIFT DETECTED

  docs/infographic.svg
    ⚠ Uses #6366f1 in accentGrad — configured accent is #b00149
    ⚠ Uses #8b5cf6 in gradientMid — configured gradientMid is #d4326d

  reports/spike-2026-02-14.html
    ⚠ CSS --accent: #6366f1 — configured accent is #b00149

  Run /add:brand-update to fix these artifacts.
```

If no drift:
```
BRAND CONSISTENCY: ✓ All artifacts match configured branding.
```

If no artifacts found:
```
GENERATED ARTIFACTS: None found yet.
  Run /add:infographic to generate a project infographic.
```

## Phase 3: Image Generation Status

Read `imageGeneration` section from `.add/config.json` (if it exists).

**If image gen is configured and enabled:**
```
IMAGE GENERATION: ✓ Configured
  Tool:    {imageGeneration.plugin} ({imageGeneration.tool})
  Status:  Active
```

**If image gen is not configured:**
```
IMAGE GENERATION: Not configured
  Adding a Google Vertex AI image gen MCP server enhances your
  project documentation with AI-generated visuals for infographics and reports.

  To set up:
    1. Configure a Vertex AI MCP server in your .mcp.json
    2. Run any visual skill (/add:infographic) — detection is automatic
```

**If imageGeneration section doesn't exist in config:**
Skip this section silently (feature not yet enabled for this project).

## Phase 4: Summary

```
BRANDING SUMMARY

  Color:      {accentColor} ({presetName})
  Artifacts:  {N} found, {M} with drift
  Image Gen:  {Configured | Not configured}

  Commands:
    /add:brand-update    Update branding and audit artifacts
    /add:infographic     Generate project infographic
```

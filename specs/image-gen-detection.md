# Spec: Point-of-Use Image Generation Detection

**Version:** 0.1.0
**Created:** 2026-02-14
**PRD Reference:** docs/prd.md
**Status:** Draft

## 1. Overview

Runtime detection of image generation MCP tools at the point of use rather than during init. When a visual skill runs (infographic, reports, brand-update), it checks for available image gen capabilities, uses them if present, falls back to SVG-only if not, and provides a one-time encouragement to set up image gen. ADD does not bundle or share any image gen account — it detects and leverages whatever the user has configured.

### User Story

As a developer using ADD, I want visual documentation skills to automatically leverage my image generation tools when available, so that my infographics and reports include richer visuals without manual configuration.

## 2. Acceptance Criteria

| ID | Criterion | Priority |
|----|-----------|----------|
| AC-001 | Visual skills (infographic, reports, brand-update) check for image gen MCP tools at execution time, not during init | Must |
| AC-002 | Detection scans `.mcp.json` in home directory and project root for known image gen tool patterns (imgGen, dall-e, midjourney, stable-diffusion, imagen, vertex-ai) | Must |
| AC-003 | If image gen tool is found, store tool reference in `.add/config.json` under `imageGeneration` key for subsequent use | Must |
| AC-004 | If image gen tool is found, visual skills use it to enhance output (hero images, feature illustrations, etc.) | Must |
| AC-005 | If no image gen tool is found, visual skills fall back to SVG-only mode with full functionality | Must |
| AC-006 | On first detection failure, display a one-time suggestion encouraging the user to set up Google Vertex AI image gen | Should |
| AC-007 | Track whether the user has been nudged in `.add/config.json` (`imageGeneration.nudged: true`) — do not repeat the suggestion | Must |
| AC-008 | `/add:brand` displays current image gen status (tool name if configured, "not configured" if not) with setup guidance | Must |
| AC-009 | ADD never bundles, shares, or references a specific image gen account — only detects user's own tools | Must |
| AC-010 | If a previously detected tool is no longer available (MCP config changed), gracefully fall back to SVG-only and clear the cached reference | Should |
| AC-011 | Detection adds < 2 seconds to skill execution time | Must |

## 3. User Test Cases

### TC-001: Visual skill runs with no image gen configured

**Precondition:** ADD initialized, no image gen MCP tool installed, never been nudged
**Steps:**
1. Run `/add:infographic`
**Expected Result:** Infographic generated using SVG-only mode (fully functional). One-time message displayed:
```
Tip: Adding a Google Vertex AI image gen MCP server would enhance
your project documentation with generated visuals.
Run /add:brand for setup instructions.
```
`.add/config.json` updated with `imageGeneration.nudged: true`
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-002: Visual skill runs with image gen configured

**Precondition:** ADD initialized, `imgGen` MCP tool available in `.mcp.json`
**Steps:**
1. Run `/add:infographic`
**Expected Result:** Detection finds `imgGen`, stores in config. Infographic generated with enhanced visuals (hero image generated via MCP tool). No nudge displayed.
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-003: Second run after nudge — no repeat

**Precondition:** ADD initialized, no image gen, `imageGeneration.nudged: true` already set
**Steps:**
1. Run `/add:infographic`
**Expected Result:** Infographic generated SVG-only. No nudge message displayed (already nudged).
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-004: Image gen tool installed after project init

**Precondition:** ADD initialized months ago without image gen. User recently installed Vertex AI MCP.
**Steps:**
1. Run `/add:infographic`
**Expected Result:** Detection finds new MCP tool, stores in config. Infographic uses image gen. Message: "Detected image generation tool: vertex-ai. Using it for enhanced visuals."
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-005: Previously configured tool no longer available

**Precondition:** `.add/config.json` has `imageGeneration.tool: "imgGen"` but MCP config no longer includes it
**Steps:**
1. Run `/add:infographic`
**Expected Result:** Detection fails to find previously cached tool. Falls back to SVG-only. Clears `imageGeneration.tool` from config. Warns: "Previously configured image gen tool 'imgGen' not found. Falling back to SVG-only."
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

### TC-006: /add:brand shows image gen status

**Precondition:** ADD initialized, no image gen configured
**Steps:**
1. Run `/add:brand`
**Expected Result:** Output includes section:
```
Image generation: Not configured
  Adding Vertex AI image gen enables richer infographics and docs.
  See: https://cloud.google.com/vertex-ai/docs/image-generation
```
**Screenshot Checkpoint:** N/A
**Maps to:** TBD

## 4. Data Model

### ImageGeneration (in .add/config.json)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| enabled | boolean | Yes | Whether image gen is currently available |
| tool | string or null | No | MCP tool identifier, e.g. "mcp__imgGen__generate_image" |
| plugin | string or null | No | MCP plugin name, e.g. "imgGen" |
| nudged | boolean | Yes | Whether the user has been shown the setup suggestion |
| lastDetected | string (ISO date) or null | No | When the tool was last successfully detected |

### Known Tool Patterns (hardcoded in detection logic)

| Pattern | Plugin Name |
|---------|------------|
| `mcp__imgGen__generate_image` | imgGen |
| `mcp__dall-e__*` | dall-e |
| `mcp__midjourney__*` | midjourney |
| `mcp__stable-diffusion__*` | stable-diffusion |
| `mcp__imagen__*` | imagen |
| `mcp__vertex-ai__*` | vertex-ai |

### Relationships

- ImageGeneration is a section within `.add/config.json`
- Read by all visual skills at execution time
- `/add:brand` displays status from this section
- Detection logic is shared across all visual skills (defined once in a rule or knowledge file)

## 5. API Contract (if applicable)

N/A — Internal detection mechanism, not an API.

## 6. UI Behavior (if applicable)

N/A — Terminal CLI output only.

## 7. Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Multiple image gen tools installed | Use the first detected one; store it. User can override via `/add:brand-update` |
| `.mcp.json` doesn't exist | No image gen available — SVG-only mode, no error |
| `.mcp.json` exists but is malformed | Log warning, treat as no image gen available |
| User explicitly declines image gen (future: "Don't suggest this again") | Respect `nudged: true` flag permanently |
| Image gen tool exists but fails at runtime | Catch error, fall back to SVG-only for that invocation, don't clear config (might be transient) |
| Detection runs in a CI environment (no MCP) | SVG-only mode, no nudge (no interactive user) |

## 8. Dependencies

- **Branding system spec** — `/add:brand` is the home for image gen status display
- **Infographic generation spec** — primary consumer of image gen detection
- **MCP protocol** — detection reads `.mcp.json` files

## 9. Implementation Notes

### Detection Algorithm

```
1. Read ~/.mcp.json (user-level MCP config)
2. Read .mcp.json (project-level MCP config)
3. Merge tool lists
4. Match against known patterns
5. If match found:
   a. Store in .add/config.json imageGeneration section
   b. Return tool reference for skill to use
6. If no match:
   a. Check if nudged before
   b. If not nudged, display suggestion, set nudged: true
   c. Return null (skill uses SVG-only mode)
```

### Files to create/modify

- **New:** `rules/image-gen-detection.md` or `knowledge/image-gen-detection.md` — shared detection logic for all visual skills
- **Modify:** `.add/config.json` template — add `imageGeneration` section
- **Modify:** Each visual skill (infographic, reports) — add detection call at start

## 10. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial spec from /add:spec conversation |

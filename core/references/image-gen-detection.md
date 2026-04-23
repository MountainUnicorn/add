# Image Generation Detection — Shared Algorithm

> **Purpose:** Shared detection logic and usage instructions for all visual skills.
> Every skill that produces visual output (infographics, reports, brand assets) MUST
> follow this algorithm before generating images. This ensures consistent detection,
> caching, fallback, and nudge behavior across the entire ADD plugin.

## Detection Algorithm

When a visual skill starts (e.g., `/add:infographic`, `/add:brand`, report generation),
run this detection sequence:

```
1. Check .add/config.json for cached imageGeneration result
   a. If imageGeneration.enabled is true AND imageGeneration.tool is set:
      - Re-verify the tool still exists (see "Stale Detection" below)
      - If still valid, use it — skip remaining steps
      - If stale, clear cache and continue to step 2
   b. If imageGeneration.enabled is false and imageGeneration.tool is null:
      - Proceed to step 2 (scan for tools)

2. Scan MCP configuration files for known image gen tools
   a. Read ~/.mcp.json (user-level MCP config)
   b. Read ./.mcp.json (project-level MCP config)
   c. If either file is missing, skip it (not an error)
   d. If either file is malformed JSON, warn and skip it
   e. Merge the tool/server lists from both files

3. Match against known tool patterns (see table below)
   a. If match found:
      - Update .add/config.json imageGeneration section:
        enabled: true
        tool: "{matched_tool_identifier}"  (e.g., "mcp__imgGen__generate_image")
        plugin: "{plugin_name}"            (e.g., "imgGen")
        lastDetected: "{ISO_DATE}"         (e.g., "2026-02-14")
      - Log: "Detected image generation tool: {plugin_name}. Using it for enhanced visuals."
      - Return the tool reference to the calling skill
   b. If multiple matches found:
      - Use the first match in priority order (see table below)
      - Log which tool was selected
   c. If no match found:
      - Run nudge logic (step 4)
      - Return null (skill uses SVG-only fallback)

4. Nudge logic (only when no tool found)
   a. Read imageGeneration.nudged from .add/config.json
   b. If nudged is false (or missing):
      - Display one-time suggestion (see "Nudge Message" below)
      - Set imageGeneration.nudged to true in .add/config.json
   c. If nudged is true:
      - Say nothing — respect the user's awareness
```

## Known MCP Tool Patterns

Tools are matched in priority order. First match wins.

| Priority | MCP Server/Tool Pattern | Plugin Name | Notes |
|----------|------------------------|-------------|-------|
| 1 | `imgGen` | imgGen | Google Vertex AI image gen wrapper |
| 2 | `imagen` | imagen | Google Imagen direct |
| 3 | `vertex-ai` | vertex-ai | Google Vertex AI (broader) |
| 4 | `dall-e` | dall-e | OpenAI DALL-E |
| 5 | `midjourney` | midjourney | Midjourney |
| 6 | `stable-diffusion` | stable-diffusion | Stability AI |

### How to Match

When scanning `.mcp.json`, look for these patterns in the `mcpServers` object keys:

```json
{
  "mcpServers": {
    "imgGen": { ... },
    "dall-e": { ... }
  }
}
```

The MCP tool call format is `mcp__{serverName}__{toolName}` (e.g., `mcp__imgGen__generate_image`).
Match against the server name (the key in `mcpServers`). A server name that contains or
equals any of the known patterns is a match.

## Scan Locations

| Location | Scope | Priority |
|----------|-------|----------|
| `~/.mcp.json` | User-level — tools available to all projects | Scanned first |
| `./.mcp.json` | Project-level — tools specific to this project | Scanned second, overrides user-level |

If the same server name appears in both files, the project-level config takes precedence.

## Cache Strategy

Detection results are cached in `.add/config.json` under the `imageGeneration` key:

```json
{
  "imageGeneration": {
    "enabled": false,
    "tool": null,
    "plugin": null,
    "nudged": false,
    "lastDetected": null
  }
}
```

### Cache Fields

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | boolean | `true` if an image gen tool is currently available |
| `tool` | string or null | Full MCP tool identifier (e.g., `"mcp__imgGen__generate_image"`) |
| `plugin` | string or null | MCP server/plugin name (e.g., `"imgGen"`) |
| `nudged` | boolean | `true` after the one-time setup suggestion has been shown |
| `lastDetected` | string (ISO date) or null | When the tool was last successfully detected |

### Cache Behavior

- Cache is populated on first detection and updated on subsequent detections.
- Cache is cleared when stale detection triggers (see below).
- The `nudged` flag is never automatically cleared -- it persists permanently.
- Skills should read the cache first; only run full detection if the cache is empty or stale.

## Stale Detection Handling

A cached tool reference can become stale if the user removes the MCP server after it was detected.

### When to Check for Staleness

Re-verify the cached tool on every visual skill invocation. This is fast (single JSON file read)
and prevents using a tool that no longer exists.

### Stale Detection Algorithm

```
1. Read imageGeneration.plugin from .add/config.json
2. If plugin is not null:
   a. Scan ~/.mcp.json and ./.mcp.json for the cached plugin name
   b. If found: tool is still valid, proceed normally
   c. If NOT found:
      - Clear cache: set enabled=false, tool=null, plugin=null, lastDetected=null
      - Keep nudged flag unchanged (do not re-nudge)
      - Warn: "Previously configured image gen tool '{plugin}' not found. Falling back to SVG-only."
      - Return null (skill uses SVG-only mode)
3. If plugin is null: no cached tool, run full detection
```

### Why Not Time-Based Expiry

MCP server availability is binary (configured or not), not time-dependent. Checking the
actual `.mcp.json` files is more reliable than expiring after N hours.

## Nudge Logic

### One-Time Suggestion

When no image gen tool is detected and the user has not been nudged before, display:

```
Tip: Adding a Google Vertex AI image gen MCP server would enhance
your project documentation with generated visuals.
Run /add:brand for setup instructions.
```

### Nudge Rules

- Display the nudge exactly once per project (tracked by `imageGeneration.nudged` flag).
- After displaying, immediately set `nudged: true` in `.add/config.json`.
- Never reset the `nudged` flag automatically.
- Do NOT nudge in CI environments (no interactive user).
- Do NOT nudge if the user explicitly runs `/add:brand` (they are already looking at setup info).

## SVG-Only Fallback

When no image gen tool is available, visual skills operate in SVG-only mode:

- All visual output is generated as inline SVG (fully functional, no degradation in structure).
- SVG is the baseline -- image gen is an enhancement, not a requirement.
- Skills should NOT display errors or warnings on every run in SVG-only mode. The one-time
  nudge is sufficient.
- Skills should NOT mention "fallback" or "degraded" in user-facing output. SVG-only is
  a complete, first-class mode.

## Point-of-Use Detection Pattern for Skill Authors

Every visual skill should include detection at its entry point. Here is the pattern to follow:

```
### At the start of a visual skill:

1. Read .add/config.json
2. Check imageGeneration section:
   - If enabled is true and tool is not null:
     a. Verify tool still exists in .mcp.json (stale check)
     b. If valid: use the tool for enhanced image generation
     c. If stale: clear cache, fall back to SVG-only
   - If enabled is false or tool is null:
     a. Scan .mcp.json files for known patterns
     b. If found: update config, use the tool
     c. If not found: check nudged flag, maybe nudge, use SVG-only
3. Proceed with skill logic using the determined mode
```

### Performance Requirement

Detection MUST complete in under 2 seconds. Since it involves only local JSON file reads
(two `.mcp.json` files and one `.add/config.json`), this is easily achievable.

### What NOT to Do

- Do NOT run detection during `/add:init` -- detection is point-of-use only.
- Do NOT bundle, share, or reference a specific image gen account or API key.
- Do NOT retry failed tool invocations during detection -- a missing tool is not an error.
- Do NOT modify `.mcp.json` files -- those are the user's configuration.

## Integration with /add:brand

The `/add:brand` command displays image gen status from the config:

- **When configured:** Shows the detected tool name and plugin.
- **When not configured:** Shows "Not configured" with setup guidance:
  ```
  Image generation: Not configured
    Adding Vertex AI image gen enables richer infographics and docs.
    See: https://cloud.google.com/vertex-ai/docs/image-generation
  ```

The `/add:brand` command is the canonical place for users to see image gen status and
get setup instructions. The one-time nudge message directs users there.

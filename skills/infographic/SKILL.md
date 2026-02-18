---
description: "[ADD v0.4.0] Generate project infographic — SVG from PRD + config with branding"
argument-hint: "[--update]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# ADD Infographic Skill v0.4.0

Generates a professional SVG infographic from the project's PRD and config. The infographic includes hero section, live metrics, workflow visualization, value propositions, and terminal command reference — all styled with the project's branding palette.

## Pre-Flight Checks

**Step 1.1: Verify ADD initialization**
- Check if `.add/config.json` exists
- If not found, respond: "❌ Project not initialized. Run `/add:init` first."
- HALT if config missing

**Step 1.2: Load project configuration**
- Read `.add/config.json` to extract:
  - Project name, description, version
  - Maturity level (poc/alpha/beta/ga)
  - Quality mode
  - Branding palette (accentColor, accentGradient, preset)
  - Primary run command from `environments.local.run`

**Step 1.3: Load template and design system**
- Read `${CLAUDE_PLUGIN_ROOT}/templates/infographic.svg.template`
- Read `${CLAUDE_PLUGIN_ROOT}/rules/design-system.md` for aesthetic guidance
- If template missing, HALT with error (plugin installation issue)

**Step 1.4: Check for PRD (optional)**
- Check if `docs/prd.md` exists
- If exists, read for richer content extraction
- If not found, proceed with config-only mode (fallback)

**Step 1.5: Check for session handoff**
- Read `.add/handoff.md` if it exists
- Note any in-progress work or decisions relevant to this operation
- If handoff mentions blockers for this skill's scope, warn before proceeding

## Phase 1: Gather Content

### Step 1.1: Extract from PRD or Config

**Project identity:**
- Project name: from config `projectName`
- Version: from config `version`
- Eyebrow: derive from maturity level
  - poc → "PROOF OF CONCEPT"
  - alpha → "ALPHA RELEASE"
  - beta → "BETA RELEASE"
  - ga → "PRODUCTION READY"

**Hero content:**
- Hero headline: extract from PRD problem statement or derive outcome-focused headline from project description
  - Must be outcome-focused, not feature-focused
  - Examples: "Ship features faster with AI agents" not "A plugin for Claude Code"
  - Max 60 characters
- Hero subheadline: extract from PRD value proposition or use config description
  - 1-2 sentences, max 120 characters
  - Focus on transformation/benefit

**Workflow steps:**
- If PRD Section 6 exists, extract workflow steps
- Otherwise, use standard ADD workflow:
  1. "Spec" — Define feature requirements
  2. "Plan" — Generate implementation strategy
  3. "Build" — Execute TDD cycle (RED → GREEN → REFACTOR)
  4. "Verify" — Run quality gates and deploy

**Value cards:**
- Extract from PRD success metrics or key features
- Need exactly 3 cards, each with:
  - Title (short, outcome-focused, max 25 chars)
  - Description (benefit statement, max 80 chars)
- If PRD unavailable, derive from config:
  - Card 1: Quality focus (from quality mode)
  - Card 2: Maturity benefit (from maturity level)
  - Card 3: Workflow efficiency

### Step 1.2: Gather Live Metrics

**Metric 1: Spec count**
- Use Glob to find `specs/*.md` files
- Count results
- Label: "Specs"
- If 0, use "—" as value

**Metric 2: Test count**
- Use Glob to find test files: `tests/**/*.test.*`, `tests/**/*_test.*`, `**/*.spec.*`
- Count unique matches
- Label: "Tests"
- If 0, use "—" as value

**Metric 3: Maturity level**
- From config maturity field
- Label: "Maturity"
- Value: uppercase first letter (e.g., "POC", "Alpha", "Beta", "GA")

### Step 1.3: Prepare Terminal Command

**Primary command:**
- Extract from `config.environments.local.run`
- Fallback: `/add:init`
- Comment: "Get started with ADD"

## Phase 2: Image Gen Detection

**Step 2.1: Check for cached detection result**
- Read `config.imageGeneration` section if exists
- Check if `available` field is present and `lastChecked` is recent (< 24 hours)
- If cached and fresh, use cached result

**Step 2.2: Detect image gen capability**
- Read `${CLAUDE_PLUGIN_ROOT}/knowledge/image-gen-detection.md` for detection algorithm
- Scan MCP configs for image generation tools:
  - Check `~/.claude/mcp/local.json` for tools matching image gen patterns
  - Common patterns: "image", "generate", "draw", "vision"
- Set `imageGenAvailable = true | false`

**Step 2.3: Update cache in config**
- If detection ran, update `.add/config.json`:
  ```json
  "imageGeneration": {
    "available": true|false,
    "lastChecked": "2026-02-14T12:00:00Z",
    "detectedTool": "tool-name" // if available
  }
  ```

## Phase 3: Compose SVG

### Step 3.1: Load Template
- Template already loaded in pre-flight
- Template contains placeholder patterns: `{PLACEHOLDER_NAME}`

### Step 3.2: Replace Placeholders

**Identity placeholders:**
- `{PROJECT_NAME}` → project name from config
- `{VERSION}` → version from config
- `{EYEBROW}` → eyebrow text from Step 1.1

**Hero placeholders:**
- `{HERO_HEADLINE}` → headline from Step 1.1
- `{HERO_SUBHEADLINE}` → subheadline from Step 1.1

**Metrics placeholders:**
- `{METRIC_1_VALUE}` → spec count
- `{METRIC_1_LABEL}` → "Specs"
- `{METRIC_2_VALUE}` → test count
- `{METRIC_2_LABEL}` → "Tests"
- `{METRIC_3_VALUE}` → maturity level
- `{METRIC_3_LABEL}` → "Maturity"

**Workflow placeholders:**
- `{STEP_1}` → "Spec"
- `{STEP_2}` → "Plan"
- `{STEP_3}` → "Build"
- `{STEP_4}` → "Verify"

**Value card placeholders:**
- `{CARD_1_TITLE}`, `{CARD_1_DESC}` → first value card
- `{CARD_2_TITLE}`, `{CARD_2_DESC}` → second value card
- `{CARD_3_TITLE}`, `{CARD_3_DESC}` → third value card

**Terminal placeholders:**
- `{TERMINAL_COMMAND}` → primary command from config
- `{TERMINAL_COMMENT}` → "Get started with ADD" or derived comment

**Footer placeholders:**
- `{FOOTER_LEFT}` → "Generated by ADD v{version}"
- `{FOOTER_CENTER}` → "{projectName}"
- `{FOOTER_RIGHT}` → current date (YYYY-MM-DD)

**Branding placeholders:**
- `{GRADIENT_START}` → from `config.branding.accentGradient.start`
- `{GRADIENT_MID}` → from `config.branding.accentGradient.mid`
- `{GRADIENT_END}` → from `config.branding.accentGradient.end`
- Fallback: use raspberry palette (#b00149, #d4446a, #ff6b9d)

### Step 3.3: Maturity Adaptation

**POC maturity:**
- Simplify metrics: show only 2 metrics (specs, maturity)
- Reduce value cards to 2 instead of 3
- Add "EXPERIMENTAL" watermark in corner

**Alpha/Beta:**
- Standard treatment with all sections

**GA:**
- Full treatment
- Add "PRODUCTION READY" badge
- Include all metrics and cards

### Step 3.4: Image Gen Enhancement (if available)

**If imageGenAvailable = true:**
- Attempt to generate hero illustration using detected MCP tool
- Prompt: "Abstract minimalist illustration for {project_name}: {hero_headline}. Modern, clean, geometric style with {accent_color} accent. Dark background."
- If generation succeeds:
  - Embed as base64 `<image>` element in hero section (x="800" y="100" width="350" height="350")
  - Add subtle drop shadow filter
- If generation fails:
  - Log warning to output
  - Fall back to gradient-based hero (no degradation in quality)

**If imageGenAvailable = false:**
- Use gradient-based hero with geometric shapes
- This is first-class design, not degraded mode
- No warning needed

### Step 3.5: Write SVG File

**Step 3.5.1: Ensure docs directory**
- Run Bash: `mkdir -p /Users/abrooke/projects/add/docs`

**Step 3.5.2: Write composed SVG**
- Write final SVG content to `/Users/abrooke/projects/add/docs/infographic.svg`
- Preserve all formatting, indentation, and whitespace

## Phase 4: Verification

**Run verification checklist:**
- [ ] File exists at `/Users/abrooke/projects/add/docs/infographic.svg`
- [ ] Contains `viewBox="0 0 1200 X"` (X varies by content)
- [ ] Contains dark background rect with fill="#1a1a2e"
- [ ] Contains `<linearGradient id="heroGrad">`
- [ ] Contains `<linearGradient id="accentGrad">` with project colors
- [ ] Contains `<filter id="glass">`
- [ ] Contains project name (not `{PROJECT_NAME}` placeholder)
- [ ] Contains hero headline (not `{HERO_HEADLINE}` placeholder)
- [ ] Contains metrics section with 3 metrics
- [ ] Contains workflow section with 4 steps
- [ ] Contains value cards section with 3 cards (2 for POC)
- [ ] Contains terminal section with command
- [ ] File size > 5KB (verify with Bash: `wc -c docs/infographic.svg`)
- [ ] No remaining `{PLACEHOLDER}` patterns (verify with Grep: `grep -o '{[A-Z_]*}' docs/infographic.svg`)

**If any check fails:**
- Log specific failure
- Fix the issue
- Regenerate affected section
- Re-run verification

## Phase 5: README Integration

**Step 5.1: Check for README**
- Check if `README.md` exists in project root
- If not found, skip this phase (proceed to output)

**Step 5.2: Search for existing reference**
- Use Grep to search README for patterns:
  - `![.*infographic.*](docs/infographic.svg)`
  - `docs/infographic.svg`
- If match found, skip modification (already integrated)

**Step 5.3: Add infographic reference**
- Read `README.md`
- Locate insertion point: after title/badges, before main content
- Insert:
  ```markdown
  ## Overview

  ![Project Infographic](docs/infographic.svg)

  ```
- Write updated README

**Step 5.4: Verify README update**
- Read back README
- Confirm infographic reference is present
- If verification fails, log warning but don't halt

## Phase 6: Summary Output

**Generate summary:**

```
✓ INFOGRAPHIC GENERATED

  File:        docs/infographic.svg ({file_size} bytes)
  Sections:    {verified_count}/13 verified
  Image Gen:   {Used | SVG-only mode}
  README:      {Updated | Already referenced | No README found}
  Branding:    {accent_color} ({preset_name or "custom"})

  View: open docs/infographic.svg

  Related commands:
    /add:brand           View current branding
    /add:brand-update    Change branding and re-audit artifacts
    /add:infographic --update   Regenerate from current project state
```

**Exit successfully.**

## --update Flag Behavior

**When `--update` is present in $ARGUMENTS:**
- Skip all user questions
- Proceed directly with content gathering
- Re-read all sources (config, PRD, live metrics)
- Overwrite existing `docs/infographic.svg` without confirmation
- Use same logic as initial generation
- Preserve any manual customizations in config (branding, etc.)

**When `--update` is NOT present:**
- If `docs/infographic.svg` already exists:
  - Ask user: "Infographic already exists. Regenerate? (y/n)"
  - If no, exit gracefully
  - If yes, proceed with regeneration
- If not exists, proceed without asking

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner. Create tasks at the start of each major phase and mark them completed as they finish.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Gather | Reading PRD and config | Reading PRD and config... |
| Layout | Designing infographic layout | Designing layout... |
| Generate | Generating SVG content | Generating SVG... |
| Write | Writing output file | Writing output file... |

Mark each task `in_progress` when starting and `completed` when done. This gives the user real-time visibility into skill execution.

## Error Handling

**Config missing:**
- Output: "❌ Project not initialized. Run `/add:init` first."
- Exit with error

**Template missing:**
- Output: "❌ Template not found. Plugin installation may be corrupted."
- Suggest: "Reinstall with: `claude plugin uninstall add && claude plugin install add`"
- Exit with error

**PRD missing:**
- NOT an error — proceed with config-only mode
- Use config description and default content
- Log: "ℹ No PRD found, using config-only mode"

**Image gen failure:**
- NOT an error — fall back to gradient hero
- Log: "⚠ Image generation failed, using SVG-only mode"
- Continue generation

**README update failure:**
- NOT an error — infographic still generated
- Log: "⚠ Could not update README automatically"
- Suggest manual integration in output

## Notes

- All command references MUST use namespaced form: `/add:infographic`, `/add:init`, `/add:brand`, etc.
- Never use bare `/infographic` or other unnamespaced commands
- SVG-only mode is first-class, not degraded — design system accounts for both modes
- Infographic regeneration is idempotent — safe to run multiple times
- Template uses GitHub-safe SVG (no `<style>` or `<script>` tags, all inline styles)
- Canvas size in `viewBox` and sections must remain coordinated (template handles this)

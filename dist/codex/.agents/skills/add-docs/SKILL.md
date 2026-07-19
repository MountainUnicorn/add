---
name: add-docs
description: "[ADD v0.10.2] Generate and sync project documentation — architecture diagrams, API docs, README"
argument-hint: "[--scope all|api|diagrams|readme] [--check] [--discover]"
---

# ADD Docs Skill v0.10.2

Generate, update, and verify project documentation. Uses a discovery-first approach: the skill learns your codebase structure on first run, caches that knowledge in a manifest, and uses it for fast, accurate doc generation on every subsequent run.

Works with any project type — web APIs, libraries, CLIs, data pipelines, monorepos, or anything else.

**Token economy:** doc rendering is mechanical work. When sub-agent dispatch is available, delegate bulk generation (diagram emission, API doc rendering, README regen) to the fast tier per `rules/model-roles.md`; keep the frontier-model context for judgment — what to document, staleness calls, and review.

## Overview

The Docs skill manages documentation artifacts that drift as code evolves:

1. **Discovery Manifest** — Cached codebase map (entry points, types, services, architecture) that powers all other scopes
2. **Architecture Diagrams** — Mermaid diagrams reflecting current flows, traced from manifest data
3. **API / Interface Documentation** — Appropriate to project type: OpenAPI for web APIs, module docs for libraries, usage docs for CLIs
4. **README / CLAUDE.md** — Keep project overview accurate (structure, commands, architecture)
5. **Freshness Check** — Detect stale docs without modifying anything, with file-level fingerprinting

Documentation is generated from code, not written by hand. The source of truth is always the implementation. The manifest bridges the gap between raw source and generated docs.

All archetype lookup tables, the manifest schema, report formats, and configuration defaults live in `~/.codex/add/references/docs-archetypes.md` — referenced throughout as "the archetype reference".

## Pre-Flight Checks

1. **Read `.add/config.json`**
   - Load project name, stack, maturity level
   - Load architecture details (languages, frameworks, database)
   - Load `docs` configuration block (defaults in the archetype reference)
   - **Determine project archetype** (see Project Archetypes section)

2. **Read `.add/docs-manifest.json`** if it exists
   - Load cached discovery data (entry points, types, services, fingerprints)
   - If manifest exists, queue lightweight validation (fingerprint check) instead of full discovery
   - If manifest is missing, queue full discovery phase before any scope executes

3. **Read knowledge tiers** — filter for relevance
   - Tier 1: `~/.codex/add/knowledge/global.md` — universal ADD best practices
   - Tier 2: `~/.claude/add/library.json` — filter for `process` and `technical` entries about documentation drift
   - Tier 3: `.add/learnings.json` — filter for project-specific doc-related entries
   - Apply filtered learnings to guide discovery and generation decisions

4. **Read `CLAUDE.md`**
   - Understand current documented architecture and commands
   - Note any deploy expectations about documentation updates

5. **Check for session handoff** — per the Session-Handoff Preflight in `~/.codex/add/references/skill-epilogue.md`. If the handoff mentions recent structural changes, prioritize diagram updates.

6. **Determine scope**
   - Use `--scope` flag if provided, otherwise default to `all`
   - Scopes: `all`, `api`, `diagrams`, `readme`
   - `--check` mode: report what's stale without modifying files
   - `--discover` flag: force full re-discovery even if manifest exists

7. **Detect documentation tooling**
   - Use the archetype-appropriate detection strategy (see Discovery Phase)
   - Check for existing Mermaid diagrams in `docs/`
   - Check for existing doc artifacts (OpenAPI specs, generated docs, typedoc output, man pages, etc.)

## Project Archetypes

The docs skill adapts its behavior based on the project archetype, detected from `.add/config.json` or inferred from the codebase. The archetype determines what to discover, what diagrams to generate, and what "API documentation" means.

Detection order: explicit `docs.archetype` in config → inferred from architecture config and project structure → `generic` fallback. The full detection-signal table and the per-archetype vocabulary table (what "entry points", "interceptors", "types", and "services" mean per archetype) are in the archetype reference. If ambiguous, prefer the more specific archetype and note the assumption in output.

Recognized archetypes: `web-api`, `web-app`, `library`, `cli`, `data-pipeline`, `plugin`, `monorepo`, `generic`.

## Discovery Phase

Runs automatically on first invocation (no manifest found) or when `--discover` is passed. Produces `.add/docs-manifest.json` which all other scopes consume.

### Stack Detection

Read `.add/config.json` for architecture details and determine archetype. Use the archetype vocabulary table (archetype reference) to guide what to scan for — entry points, interceptors, types, and services mean different things per archetype.

For **monorepos**, identify the workspace structure first, then recursively discover each package/app using its own detected archetype. Build a top-level manifest with per-package sub-manifests.

### Discovery Steps

For all archetypes, perform these steps using framework/language-appropriate patterns:

1. **Scan entry points**
   - Use the archetype vocabulary to determine what constitutes an entry point, then scan using framework/language-appropriate patterns
   - For each entry point, capture: name, kind (route/command/export/task/etc.), file, function/class, parameters or signature, grouping/tags

2. **Scan interceptors / middleware / hooks**
   - Identify processing layers between entry and handler
   - For each: name, file path, registration order, purpose (inferred from name/docstring)

3. **Scan types / models / schemas**
   - Find type definitions appropriate to the language and archetype
   - For each: name, file path, field count, relationships

4. **Scan services / internal modules**
   - Find business logic / internal processing files
   - For each: name, file path, public function names

5. **Build directory map**
   - Identify where entry points, types, services, tests, docs, and config live
   - Record as relative paths from project root

6. **Inventory existing docs**
   - Glob for `docs/**/*.md`, `*.md` in root, generated doc files, spec files
   - For each: path, last modified date, inferred topic, type (diagram, api, readme, changelog, other)

7. **Assess flow coverage**
   - Cross-reference entry points with existing diagrams
   - Classify each flow as: documented, undocumented, or stale (diagram exists but source changed)

8. **Compute file fingerprints**
   - SHA256 hash of each file that contains entry points, type definitions, or interceptor registrations
   - Store in manifest for fast staleness detection on subsequent runs

9. **Write `.add/docs-manifest.json`**
   - Write the complete manifest (schema in the archetype reference, including per-archetype `entry_points[].detail` shapes)
   - Report a discovery summary (example in the archetype reference)

10. **Write `.add/handoff.md`** (if discovery took significant effort)
    - Record discovery results summary so interrupted sessions can resume
    - Note which scopes still need to run after discovery

## Manifest Validation (Every Run)

On every invocation (unless `--discover` is passed), validate the manifest before proceeding:

1. **Hash entry point, type, and interceptor files** listed in `fingerprints`
   - Compute SHA256 of each file's current contents

2. **Compare to stored fingerprints**
   - **All match** — manifest is fresh, proceed with cached data
   - **Some mismatch** — run incremental re-discovery on changed file categories only:
     - If an entry point file changed, re-scan entry points from that file
     - If a type file changed, re-scan types from that file
     - If an interceptor file changed, re-scan interceptors
     - Update fingerprints for changed files
   - **Manifest missing** — run full discovery phase

3. **Report validation result** — list changed files and what was re-scanned (example in the archetype reference)

## Scope: Architecture Diagrams (`--scope diagrams`)

### Purpose

Keep the diagram file (default: `docs/architecture-diagrams.md`, configurable via `docs.diagram_file` in config) accurate. When entry points, interceptors, or service interactions change, the diagrams must reflect reality.

### Steps

1. **Load entry points and interceptors from manifest**
   - Read `.add/docs-manifest.json` for the full entry point registry and interceptor chain
   - Filter out entry points matching `docs.exclude_patterns` from config
   - Prioritize entry points listed in `docs.priority_entries` config

2. **Trace flows from source**
   - For each entry point in the manifest, read the handler/function
   - Follow service calls: identify which services/modules are invoked
   - Identify data store operations, external API calls, cache interactions
   - Map the interceptors applied to this entry point
   - Identify error paths (try/except, error returns, error responses)

3. **Read existing diagram file**
   - Parse existing Mermaid diagrams
   - Note which flows are already documented
   - Cross-reference with manifest `flows.stale` and `flows.undocumented` lists

4. **Generate/update Mermaid diagrams**
   - Choose diagram types appropriate to the archetype (table in the archetype reference — e.g., `sequenceDiagram` for web-api request flows, `flowchart`/`classDiagram` for libraries)
   - For each flow:
     - Use clear participant/node labels with component names
     - Show the happy path first
     - Show error/fallback paths as `alt` blocks (sequence) or branching (flowchart)
     - Include interceptors when `docs.diagram_style.show_interceptors` is true (default)
     - Include error paths when `docs.diagram_style.show_error_paths` is true (default)
     - Respect `docs.diagram_style.max_participants` limit (default 8)

5. **Write updated diagram file**
   - Preserve the file's existing structure and heading style
   - Update existing diagrams that have changed
   - Add new diagrams for undocumented flows
   - Remove diagrams for deleted entry points
   - Add a "Last updated" timestamp at the bottom

### Required Flows (minimum)

Every project must document at minimum: the primary entry point → processing → output flow (happy path), and the error handling / fallback flow. Per-archetype additions (auth flows, subcommand dispatch, retry behavior, hook execution, cross-package flows) are listed in the archetype reference.

For parallel diagram generation on large codebases, use the Agent tool to dispatch independent diagram groups concurrently.

## Scope: API / Interface Documentation (`--scope api`)

### Purpose

Generate or regenerate interface documentation appropriate to the project archetype. The what-to-generate and tool-detection strategy per archetype is the "API Doc Strategy by Archetype" table in the archetype reference.

### Steps

1. **Identify doc generation strategy**
   - Read `docs.api_doc_strategy` from config (default: `auto`)
   - If `auto`, use the archetype to detect the appropriate doc generation tool
   - If explicitly set, use that strategy

2. **Check tool availability**
   - Verify the doc generation tool is installed
   - If not installed, report and suggest installation command
   - Fall back to manifest-based markdown generation if installation fails

3. **Run doc generation**
   - Execute the detected tool's generation command
   - Capture stdout/stderr for error reporting

4. **Verify generation succeeded**
   - Confirm output files were created or updated
   - Parse the generated docs to count documented entry points
   - Report any warnings or errors from the tool

5. **Report coverage**
   - Cross-reference manifest entry points with documented items
   - List entry points with their documentation status
   - Flag entry points missing documentation
   - Flag stale annotations (signature changed but docs didn't)

## Scope: README / CLAUDE.md (`--scope readme`)

### Purpose

Ensure project overview documents reflect the current state of the codebase.

### Steps

1. **Load current state from manifest**
   - Entry points and their signatures from `entry_points[]`
   - Directory structure from `directories`
   - Types and services from `types[]` and `services[]`
   - Additionally scan for: make targets, Docker services, environment variables from config files
   - For CLIs: commands and flags. For libraries: public API surface. For pipelines: DAGs and schedules.

2. **Read existing documents**
   - Read files listed in `docs.readme_files` config (default: `["CLAUDE.md", "README.md"]`)
   - Parse architecture sections, commands sections, entry point listings

3. **Compare and identify drift**
   - New entry points not in docs; removed entry points still in docs
   - New packages/directories not in architecture section
   - Changed commands or make targets; new environment variables
   - New types or services not documented; changed public API surface (for libraries)

4. **Update documents**
   - Add missing entries
   - Remove stale entries
   - Keep the existing formatting style and section structure
   - Do NOT rewrite sections that are still accurate
   - Do NOT add sections that don't already exist (ask first)

5. **Optionally update README.md** (if it exists and is in `readme_files`)
   - Same drift detection approach
   - Conservative updates — only fix factual inaccuracies

## Check Mode (`--check`)

When `--check` is passed, do NOT modify any files. Instead:

1. Run all scanning, validation, and comparison steps
2. Respect `--scope` if provided: `--check --scope diagrams` checks only diagrams
3. Produce a freshness report with concrete details — per-scope staleness (missing/stale diagrams, undocumented exports, README drift) and an overall verdict with the exact `/add-docs` command to fix. Full example in the archetype reference.
4. Return exit codes for CI integration:
   - **0** — all docs fresh
   - **1** — one or more docs stale
   - **2** — manifest missing (run `--discover` first)

## Output Format

After generating/updating docs, produce a concrete report: execution context (project, archetype, scope, discovery mode), changes made per file, coverage percentages, warnings, and next steps. Full example in the archetype reference.

## Configuration in `.add/config.json`

The docs skill reads its configuration from the `docs` key in `.add/config.json`. The full defaults block is in the archetype reference. If no `docs` key exists in config, all defaults apply.

## Progress Tracking

**Tasks to create** (mechanics per `~/.codex/add/references/skill-epilogue.md`; skip tasks that don't apply to the current scope):

| Phase | Subject | activeForm |
|-------|---------|------------|
| Discovery | Running codebase discovery | Discovering codebase structure... |
| Validate | Validating manifest freshness | Validating docs manifest... |
| Scan | Scanning codebase | Scanning codebase for doc targets... |
| Diagrams | Updating architecture diagrams | Generating architecture diagrams... |
| API | Regenerating interface docs | Regenerating interface documentation... |
| README | Syncing project overview | Syncing README and CLAUDE.md... |
| Report | Generating report | Generating documentation report... |

## Error Handling

**Manifest missing (no `.add/docs-manifest.json`)**
- If `auto_discover_on_first_run` is true (default), run full discovery automatically
- If false, report: "No docs manifest found. Run `/add-docs --discover` to initialize."
- Other scopes cannot proceed without a manifest

**Archetype not detected**
- Fall back to `generic` archetype
- Warn: "Could not determine project archetype — using generic discovery. Set `docs.archetype` in `.add/config.json` for better results."

**Framework not recognized (web-api/web-app archetype)**
- Fall back to generic HTTP pattern detection (grep for route registrations, handler files, middleware)
- Warn: "Framework not recognized — using generic detection. Results may be incomplete."
- If generic detection also finds nothing, suggest adding `docs.api_doc_strategy` to config

**No entry points found**
- Warn: "No entry points found — check detection patterns for your project type"
- Report which patterns were searched and in which directories
- Skip diagram and entry point documentation updates
- Other scopes (general README sections) continue normally

**No diagram file exists**
- Create the file at the path specified in `docs.diagram_file`
- Generate all flows from current manifest data
- Report: "Created docs/architecture-diagrams.md with N flow diagrams"

**Doc generation tool not installed**
- Report which tool is needed and the install command
- Fall back to manifest-based markdown generation
- Other scopes continue normally

**Application not running (for auto-generated docs like FastAPI OpenAPI)**
- Attempt programmatic import if possible
- If that fails, report: "Could not export docs — app not running or not importable."
- Fall back to manifest-based markdown generation

**Manifest stale (fingerprint mismatch on many files)**
- If >50% of fingerprints are stale, suggest full re-discovery: "Manifest significantly outdated. Running full re-discovery."
- Automatically escalate from incremental to full discovery
- Report which categories were re-scanned

## Integration with Other Skills

- **After `/add-deploy`**: Run `--scope diagrams` automatically if entry point files changed in the deployed commit
- **During `/add-verify`**: `--check` mode can be added as a Gate 2 advisory check for documentation freshness
- **After `/add-tdd-cycle`**: If new entry points were added, suggest running `/add-docs`
- **During `/add-spec`**: Discovery manifest provides accurate entry point/type inventory for writing new specs
- **During `/add-plan`**: Manifest data helps identify which files a plan will touch and what docs need updating

For large codebases with many independent entry point groups, use the Agent tool to dispatch parallel diagram generation:
- Group entry points by file or tag
- Dispatch one agent per group with file reservations
- Merge results into the single diagram file sequentially

End-of-skill epilogue: follow `~/.codex/add/references/skill-epilogue.md` (observation + learning checkpoint + progress tracking). Learning checkpoint trigger: "After Verification".

# ADD Docs Skill v0.7.1

Generate, update, and verify project documentation. Uses a discovery-first approach: the skill learns your codebase structure on first run, caches that knowledge in a manifest, and uses it for fast, accurate doc generation on every subsequent run.

Works with any project type — web APIs, libraries, CLIs, data pipelines, monorepos, or anything else.

## Overview

The Docs skill manages documentation artifacts that drift as code evolves:

1. **Discovery Manifest** — Cached codebase map (entry points, types, services, architecture) that powers all other scopes
2. **Architecture Diagrams** — Mermaid diagrams reflecting current flows, traced from manifest data
3. **API / Interface Documentation** — Appropriate to project type: OpenAPI for web APIs, module docs for libraries, usage docs for CLIs
4. **README / CLAUDE.md** — Keep project overview accurate (structure, commands, architecture)
5. **Freshness Check** — Detect stale docs without modifying anything, with file-level fingerprinting

Documentation is generated from code, not written by hand. The source of truth is always the implementation. The manifest bridges the gap between raw source and generated docs.

## Pre-Flight Checks

1. **Read `.add/config.json`**
   - Load project name, stack, maturity level
   - Load architecture details (languages, frameworks, database)
   - Load `docs` configuration block (see Configuration section below)
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

5. **Read `.add/handoff.md`** if it exists
   - Note any in-progress work relevant to documentation
   - If handoff mentions recent structural changes, prioritize diagram updates

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

### Detection Order

1. **Explicit** — `docs.archetype` in `.add/config.json` (if set, use it directly)
2. **Inferred from config** — derive from `architecture.backend.framework`, `architecture.languages`, and project structure:

| Signal | Archetype |
|--------|-----------|
| `architecture.backend.framework` is a web framework (FastAPI, Express, Django, Flask, Rails, etc.) | `web-api` or `web-app` (check for templates/views to distinguish) |
| `architecture.backend.runtime` contains "plugin" or "extension" | `plugin` |
| Project has `bin/` or `cmd/` directories, or `"bin"` field in package.json | `cli` |
| Project has `setup.py`, `pyproject.toml` with `[project]`, `package.json` with no `"private": true`, or Go module exporting packages | `library` |
| Project has DAG definitions (Airflow, Prefect, Dagster), or pipeline configs | `data-pipeline` |
| Project has `packages/` or `apps/` with multiple package.json/pyproject.toml files | `monorepo` |
| None of the above | `generic` |

3. **If ambiguous**, prefer the more specific archetype and note the assumption in output

### Archetype Vocabulary

Each archetype uses different terminology for the same structural concepts:

| Concept | web-api / web-app | library | cli | data-pipeline | plugin | generic |
|---------|-------------------|---------|-----|---------------|--------|---------|
| **Entry points** | Routes / endpoints | Exported modules / public API | Commands / subcommands | DAGs / tasks / jobs | Skills / commands / hooks | Public functions / main entry |
| **Middleware / interceptors** | Middleware chain | Decorators / wrappers | Global flags / middleware | Hooks / sensors / triggers | Rules / hooks | Wrappers / decorators |
| **Types / models** | DB models, request/response schemas | Public types / interfaces / classes | Config types, flag types | Schema definitions, data models | Config schemas, template types | Types / classes / structs |
| **Services** | Service layer / business logic | Internal modules | Handler functions | Operators / connectors | Internal utilities | Helper modules |
| **Flows to diagram** | Request → middleware → handler → service → DB | Public API call → internal processing → return | Command parse → validate → execute → output | Trigger → extract → transform → load → output | Skill invoke → pre-flight → execute → observe | Input → process → output |

## Discovery Phase

Runs automatically on first invocation (no manifest found) or when `--discover` is passed. Produces `.add/docs-manifest.json` which all other scopes consume.

### Stack Detection

Read `.add/config.json` for architecture details and determine archetype (see Project Archetypes above). Use the archetype and the vocabulary table to guide what to scan for — entry points, interceptors, types, and services mean different things per archetype.

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
   - Write the complete manifest (see schema below)
   - Report discovery summary

10. **Write `.add/handoff.md`** (if discovery took significant effort)
    - Record discovery results summary so interrupted sessions can resume
    - Note which scopes still need to run after discovery

### Discovery Output

```
Discovery complete:
  Archetype: library (python)
  Public API surface: 18 exports across 4 modules
  Types: 12 across 3 files
  Internal modules: 8 across 6 files
  Existing docs: 3 files (architecture.md, CLAUDE.md, README.md)
  Flow coverage: 12/18 exports documented, 2 stale, 4 undocumented
  Manifest written to .add/docs-manifest.json
```

## Docs Manifest Schema (`.add/docs-manifest.json`)

The manifest adapts to the project archetype. The top-level structure is universal; `entry_points[].kind` and `entry_points[].detail` vary by archetype (see detail shapes table below).

```json
{
  "version": "1.0.0",
  "generated": "<ISO 8601 timestamp>",
  "archetype": "<detected archetype>",
  "stack": { "languages": [], "framework": null, "database": null, "doc_tools": [] },
  "directories": { "entry_points": [], "types": [], "services": [], "tests": [], "docs": [] },
  "entry_points": [{ "name": "", "kind": "", "detail": {}, "file": "", "function": "", "interceptors": [], "tags": [], "signature": {} }],
  "interceptors": [{ "name": "", "file": "", "order": 0, "purpose": "" }],
  "types": [{ "name": "", "file": "", "field_count": 0, "relationships": [] }],
  "services": [{ "name": "", "file": "", "public_functions": [] }],
  "existing_docs": [{ "path": "", "last_modified": "", "topic": "", "type": "" }],
  "flows": { "documented": [], "undocumented": [], "stale": [] },
  "fingerprints": { "<file_path>": "<sha256>" }
}
```

**Archetype-specific `entry_points[].detail` shapes:**

| Archetype | `kind` | `detail` fields |
|-----------|--------|-----------------|
| web-api | `route` | `method`, `path` |
| web-app | `route` or `page` | `method`, `path`, `template` (if view renders a template) |
| library | `export` | `module`, `visibility` (`public`/`protected`) |
| cli | `command` | `parent` (if subcommand), `aliases` |
| data-pipeline | `task` or `dag` | `dag_id` (if task), `schedule` (if dag) |
| plugin | `skill` or `hook` | `trigger`, `scope` |
| generic | `function` | `module` |

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

3. **Report validation result**
   ```
   Manifest validation: 2 files changed since last discovery
     - src/mylib/config.py (entry points re-scanned: 2 updated)
     - src/mylib/types/config.py (types re-scanned: 1 updated)
   Manifest updated incrementally.
   ```

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

   Choose diagram types appropriate to the archetype:

   | Archetype | Primary diagram type | Secondary diagrams |
   |-----------|---------------------|--------------------|
   | web-api / web-app | `sequenceDiagram` (request flows) | `flowchart` (auth flow), `erDiagram` (data model) |
   | library | `flowchart` (call graphs), `classDiagram` (type hierarchy) | `sequenceDiagram` (complex multi-step APIs) |
   | cli | `flowchart` (command flow), `stateDiagram` (state machines) | `sequenceDiagram` (multi-step operations) |
   | data-pipeline | `flowchart` (DAG visualization), `sequenceDiagram` (task execution) | `gantt` (schedule overview) |
   | plugin | `flowchart` (skill lifecycle), `sequenceDiagram` (hook execution) | `classDiagram` (config/template types) |
   | generic | `sequenceDiagram` or `flowchart` (whichever fits the flow better) | As appropriate |

   For each flow:
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

Every project should document at minimum the flows appropriate to its archetype:

**All archetypes (universal):**
- Primary entry point → processing → output flow (happy path)
- Error handling / fallback flow

**Additionally, per archetype:**

| Archetype | Additional required flows |
|-----------|-------------------------|
| web-api / web-app | Auth flow (if auth exists), async/background flows (if they exist) |
| library | Complex multi-step operations involving internal coordination |
| cli | Subcommand dispatch (if applicable), user feedback flow |
| data-pipeline | Retry behavior, data flow through transformations |
| plugin | Hook execution flow, configuration loading and validation |
| monorepo | Cross-package interaction flows |
| generic | *(universal flows are sufficient)* |

For parallel diagram generation on large codebases, use the Agent tool to dispatch independent diagram groups concurrently.

## Scope: API / Interface Documentation (`--scope api`)

### Purpose

Generate or regenerate interface documentation appropriate to the project archetype.

### Strategy by Archetype

| Archetype | What to generate | Approach |
|-----------|-----------------|----------|
| web-api / web-app | OpenAPI / Swagger spec | Detect and run the framework's doc generation tool (e.g., export `openapi.json` from FastAPI, run `swagger-jsdoc` for Express, `generateschema` for DRF). Fall back to manifest-based `docs/api.md` if no tool detected. |
| library | Module / API reference | Detect and run the language's doc tool (e.g., Sphinx, pdoc, TypeDoc, godoc, cargo doc). Fall back to manifest-based `docs/api.md` with signatures and docstrings. |
| cli | Usage documentation | Extract `--help` output for each command/subcommand and format as markdown. Fall back to manifest-based `docs/usage.md`. |
| data-pipeline | Pipeline documentation | Use the pipeline tool's doc generator if available (e.g., `dbt docs generate`). Fall back to manifest-based `docs/pipelines.md`. |
| plugin | Plugin documentation | Extract from structured metadata (plugin.json, package.json contributes, etc.). Fall back to manifest-based `docs/plugin.md`. |
| generic | Interface documentation | Generate `docs/api.md` from manifest entry points with signatures and docstrings. |

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
   - For CLIs: commands and flags
   - For libraries: public API surface
   - For pipelines: DAGs and schedules

2. **Read existing documents**
   - Read files listed in `docs.readme_files` config (default: `["CLAUDE.md", "README.md"]`)
   - Parse architecture sections, commands sections, entry point listings

3. **Compare and identify drift**
   - New entry points not in docs
   - Removed entry points still in docs
   - New packages/directories not in architecture section
   - Changed commands or make targets
   - New environment variables
   - New types or services not documented
   - Changed public API surface (for libraries)

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
3. Produce a freshness report with concrete details:

```
# Documentation Freshness Report

## Execution Context
- Project: my-project
- Archetype: library (python)
- Timestamp: 2026-03-15T10:30:00Z
- Branch: feature/new-module
- Manifest: .add/docs-manifest.json (valid, 2 files changed)

## Architecture Diagrams (docs/architecture-diagrams.md)
- Last modified: 2026-03-10
- Entry points in code: 18
- Entry points in diagrams: 15
- Missing diagrams: parse_config(), validate_schema(), export_report()
- Stale diagrams: transform_data() (implementation changed 2026-03-12)
- Status: STALE (3 missing, 1 outdated)

## API / Interface Documentation
- Strategy: TypeDoc auto-generation
- Documented exports: 16/18
- Missing documentation: 2 exports without docstrings
- Status: STALE (2 undocumented)

## CLAUDE.md
- Last modified: 2026-03-14
- Entry point drift: 2 new, 0 removed
- Directory drift: 0 new, 0 removed
- Command drift: 0 new, 0 changed
- Type drift: 1 new type (ValidationResult) not in architecture section
- Status: STALE (2 entry points, 1 type undocumented)

## Overall: UPDATES NEEDED
- 4 diagrams need attention (3 missing + 1 stale)
- 2 exports need docstrings
- 3 CLAUDE.md entries need updating
- Run `/add:docs` to fix, or `/add:docs --scope diagrams` for diagrams only
```

4. Return exit codes for CI integration:
   - **0** — all docs fresh
   - **1** — one or more docs stale
   - **2** — manifest missing (run `--discover` first)

## Output Format

After generating/updating docs, produce a concrete report:

```
# Documentation Updated

## Execution Context
- Project: my-project
- Archetype: library (python)
- Timestamp: 2026-03-15T10:35:00Z
- Branch: feature/new-module
- Scope: all
- Discovery: incremental (2 files re-scanned)

## Changes Made
- docs/architecture-diagrams.md: Updated 1 diagram (transform_data), added 3 new (parse_config, validate_schema, export_report)
- CLAUDE.md: Added 2 exports to public API section, added ValidationResult to types section

## Coverage
- Entry points documented in diagrams: 18/18 (100%)
- Exports documented: 18/18 (100%)
- Diagram flows: 18 entry points covered across 5 diagram groups
- CLAUDE.md sections: architecture current, commands current, API surface current

## Warnings
- None

## Next Steps
1. Review generated diagrams in docs/architecture-diagrams.md for accuracy
2. Commit documentation changes: `git add docs/ CLAUDE.md`
3. Consider running `/add:docs --check` in CI to catch future drift
```

## Configuration in `.add/config.json`

The docs skill reads its configuration from the `docs` key in `.add/config.json`:

```json
{
  "docs": {
    "archetype": "auto",
    "diagram_file": "docs/architecture-diagrams.md",
    "api_doc_strategy": "auto",
    "readme_files": ["CLAUDE.md", "README.md"],
    "manifest_path": ".add/docs-manifest.json",
    "auto_discover_on_first_run": true,
    "check_in_ci": false,
    "priority_entries": [],
    "exclude_patterns": [],
    "diagram_style": {
      "show_interceptors": true,
      "show_error_paths": true,
      "max_participants": 8
    }
  }
}
```

If no `docs` key exists in config, all defaults apply.

## Progress Tracking

Use TaskCreate and TaskUpdate to report progress through the CLI spinner.

**Tasks to create:**
| Phase | Subject | activeForm |
|-------|---------|------------|
| Discovery | Running codebase discovery | Discovering codebase structure... |
| Validate | Validating manifest freshness | Validating docs manifest... |
| Scan | Scanning codebase | Scanning codebase for doc targets... |
| Diagrams | Updating architecture diagrams | Generating architecture diagrams... |
| API | Regenerating interface docs | Regenerating interface documentation... |
| README | Syncing project overview | Syncing README and CLAUDE.md... |
| Report | Generating report | Generating documentation report... |

Mark each task `in_progress` when starting and `completed` when done. Skip tasks that don't apply to the current scope.

## Error Handling

**Manifest missing (no `.add/docs-manifest.json`)**
- If `auto_discover_on_first_run` is true (default), run full discovery automatically
- If false, report: "No docs manifest found. Run `/add:docs --discover` to initialize."
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

- **After `/add:deploy`**: Run `--scope diagrams` automatically if entry point files changed in the deployed commit
- **During `/add:verify`**: `--check` mode can be added as a Gate 2 advisory check for documentation freshness
- **After `/add:tdd-cycle`**: If new entry points were added, suggest running `/add:docs`
- **During `/add:spec`**: Discovery manifest provides accurate entry point/type inventory for writing new specs
- **During `/add:plan`**: Manifest data helps identify which files a plan will touch and what docs need updating

For large codebases with many independent entry point groups, use the Agent tool to dispatch parallel diagram generation:
- Group entry points by file or tag
- Dispatch one agent per group with file reservations
- Merge results into the single diagram file sequentially

## Process Observation

After completing this skill, do BOTH:

### 1. Observation Line

Append one observation line to `.add/observations.md`:

```
{YYYY-MM-DD HH:MM} | docs | {one-line summary of outcome} | {cost or benefit estimate}
```

If `.add/observations.md` does not exist, create it with a `# Process Observations` header first.

### 2. Learning Checkpoint

Write a structured JSON learning entry per the checkpoint trigger in `rules/learning.md` (section: "After Verification"). Classify scope, write to the appropriate JSON file (`.add/learnings.json` or `~/.claude/add/library.json`), and regenerate the markdown view.

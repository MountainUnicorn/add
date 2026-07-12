# Docs Archetypes — Vocabulary, Manifest Schema, and Report Formats

Reference data for `/add-docs`. The skill keeps the workflow; the lookup
tables, manifest schema, and long example outputs live here.

## Archetype Detection

Detection order:

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

## Archetype Vocabulary

Each archetype uses different terminology for the same structural concepts:

| Concept | web-api / web-app | library | cli | data-pipeline | plugin | generic |
|---------|-------------------|---------|-----|---------------|--------|---------|
| **Entry points** | Routes / endpoints | Exported modules / public API | Commands / subcommands | DAGs / tasks / jobs | Skills / commands / hooks | Public functions / main entry |
| **Middleware / interceptors** | Middleware chain | Decorators / wrappers | Global flags / middleware | Hooks / sensors / triggers | Rules / hooks | Wrappers / decorators |
| **Types / models** | DB models, request/response schemas | Public types / interfaces / classes | Config types, flag types | Schema definitions, data models | Config schemas, template types | Types / classes / structs |
| **Services** | Service layer / business logic | Internal modules | Handler functions | Operators / connectors | Internal utilities | Helper modules |
| **Flows to diagram** | Request → middleware → handler → service → DB | Public API call → internal processing → return | Command parse → validate → execute → output | Trigger → extract → transform → load → output | Skill invoke → pre-flight → execute → observe | Input → process → output |

## Diagram Types by Archetype

| Archetype | Primary diagram type | Secondary diagrams |
|-----------|---------------------|--------------------|
| web-api / web-app | `sequenceDiagram` (request flows) | `flowchart` (auth flow), `erDiagram` (data model) |
| library | `flowchart` (call graphs), `classDiagram` (type hierarchy) | `sequenceDiagram` (complex multi-step APIs) |
| cli | `flowchart` (command flow), `stateDiagram` (state machines) | `sequenceDiagram` (multi-step operations) |
| data-pipeline | `flowchart` (DAG visualization), `sequenceDiagram` (task execution) | `gantt` (schedule overview) |
| plugin | `flowchart` (skill lifecycle), `sequenceDiagram` (hook execution) | `classDiagram` (config/template types) |
| generic | `sequenceDiagram` or `flowchart` (whichever fits the flow better) | As appropriate |

## Required Flows by Archetype

All archetypes (universal): primary entry point → processing → output flow
(happy path), plus error handling / fallback flow. Additionally:

| Archetype | Additional required flows |
|-----------|-------------------------|
| web-api / web-app | Auth flow (if auth exists), async/background flows (if they exist) |
| library | Complex multi-step operations involving internal coordination |
| cli | Subcommand dispatch (if applicable), user feedback flow |
| data-pipeline | Retry behavior, data flow through transformations |
| plugin | Hook execution flow, configuration loading and validation |
| monorepo | Cross-package interaction flows |
| generic | *(universal flows are sufficient)* |

## API Doc Strategy by Archetype

| Archetype | What to generate | Approach |
|-----------|-----------------|----------|
| web-api / web-app | OpenAPI / Swagger spec | Detect and run the framework's doc generation tool (e.g., export `openapi.json` from FastAPI, run `swagger-jsdoc` for Express, `generateschema` for DRF). Fall back to manifest-based `docs/api.md` if no tool detected. |
| library | Module / API reference | Detect and run the language's doc tool (e.g., Sphinx, pdoc, TypeDoc, godoc, cargo doc). Fall back to manifest-based `docs/api.md` with signatures and docstrings. |
| cli | Usage documentation | Extract `--help` output for each command/subcommand and format as markdown. Fall back to manifest-based `docs/usage.md`. |
| data-pipeline | Pipeline documentation | Use the pipeline tool's doc generator if available (e.g., `dbt docs generate`). Fall back to manifest-based `docs/pipelines.md`. |
| plugin | Plugin documentation | Extract from structured metadata (plugin.json, package.json contributes, etc.). Fall back to manifest-based `docs/plugin.md`. |
| generic | Interface documentation | Generate `docs/api.md` from manifest entry points with signatures and docstrings. |

## Docs Manifest Schema (`.add/docs-manifest.json`)

The manifest adapts to the project archetype. The top-level structure is
universal; `entry_points[].kind` and `entry_points[].detail` vary by archetype
(see detail shapes table below).

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

## Example Outputs

### Discovery Summary

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

### Manifest Validation Result

```
Manifest validation: 2 files changed since last discovery
  - src/mylib/config.py (entry points re-scanned: 2 updated)
  - src/mylib/types/config.py (types re-scanned: 1 updated)
Manifest updated incrementally.
```

### Freshness Report (`--check`)

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
- Run `/add-docs` to fix, or `/add-docs --scope diagrams` for diagrams only
```

### Update Report (after generation)

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
3. Consider running `/add-docs --check` in CI to catch future drift
```

## Configuration Defaults (`.add/config.json` → `docs`)

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

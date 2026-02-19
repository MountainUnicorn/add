# Implementation Plan: Project Dashboard

**Spec Version:** 0.1.0
**Created:** 2026-02-19
**Team Size:** Solo
**Estimated Duration:** 1 session

## Overview

Create `/add:dashboard` command that generates a self-contained HTML dashboard from `.add/` project files, matching the getadd.dev visual design.

## Objectives

- Single HTML file with all CSS/JS inlined, no external dependencies
- 6 panels: Outcome Health, Hill Chart, Cycle Progress, Decision Queue, Intelligence, Timeline
- Matches getadd.dev design: dark bg, raspberry accent, system fonts
- Works offline, git-committable, shareable

## Implementation Phases

### Phase 1: Command File

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-001 | Create `commands/dashboard.md` — full instructions for Claude to read source files, build data model, and render HTML with all 6 panels, SVG charts, and interactive elements | AC-001 through AC-025 | 30min |

This is the core deliverable. The command file is a comprehensive instruction set that tells Claude to:
1. Read all source files (.add/config.json, docs/prd.md, specs/*.md, cycles, learnings, decisions, milestones, retro scores, changelog)
2. Build a structured project state data model
3. Render a self-contained HTML string with all 6 panels
4. Write to reports/dashboard.html

### Phase 2: Dogfood

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-002 | Generate reports/dashboard.html on the ADD project itself | AC-004, AC-005, AC-006, AC-007 | 15min |
| TASK-003 | Verify all 6 panels render correctly with real ADD project data | AC-010 through AC-015 | 5min |

### Phase 3: Integration

| Task ID | Description | ACs | Effort |
|---------|-------------|-----|--------|
| TASK-004 | Update CLAUDE.md — add dashboard command to table | — | 5min |
| TASK-005 | Commit, push, sync marketplace | — | 5min |

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| HTML exceeds 300KB | Medium | Low | Minimize verbose CSS, use terse SVG paths |
| Hill chart SVG complexity | Medium | Medium | Use simple cubic bezier, native tooltips only |
| Design mismatch with getadd.dev | Low | Medium | Reference website CSS variables directly |

## Deliverables

- `commands/dashboard.md` — dashboard command
- `reports/dashboard.html` — dogfood output on ADD project
- Updated CLAUDE.md

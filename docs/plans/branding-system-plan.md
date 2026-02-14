# Implementation Plan: Branding System

**Spec Version**: 0.1.0
**Spec File**: specs/branding-system.md
**Created**: 2026-02-14
**Team Size**: Solo (2 parallel agents)
**Estimated Duration**: 4 hours
**Implementation Order**: 1 of 4 (foundation — others depend on this)

## Overview

Add project-level branding configuration to ADD: a `branding` section in `.add/config.json`, a question in `/add:init`, and two new commands (`/add:brand`, `/add:brand-update`). Port color presets and palette generation algorithm from the enterprise plugin.

## Objectives

- Capture brand identity during project initialization
- Provide read-only brand status via `/add:brand`
- Provide brand mutation + audit via `/add:brand-update`
- Port enterprise color presets to ADD

## Cross-Feature Dependencies

```
Branding System ←── Image Gen Detection (displays status in /add:brand)
Branding System ←── Infographic Generation (reads palette from config)
Branding System ←── HTML Reports (future, reads palette from config)
```

**This feature must be implemented first.** Image gen detection and infographic generation depend on the branding config structure existing.

## Acceptance Criteria Analysis

### AC-001–003: Init interview + config storage
- **Complexity**: Simple
- **Effort**: 1h
- **Tasks**: Add question to init.md, add branding section to config template
- **Risk**: Low — straightforward template modification

### AC-004–006: /add:brand command (read-only)
- **Complexity**: Medium
- **Effort**: 1.5h
- **Tasks**: New command file, brand display logic, drift detection, image gen status
- **Risk**: Drift detection requires scanning generated artifacts — need to define what to scan

### AC-007–010: /add:brand-update command (mutation)
- **Complexity**: Medium
- **Effort**: 1.5h
- **Tasks**: New command file, config update logic, artifact audit, optional fix application
- **Risk**: Audit scope could expand — keep it focused on known artifact paths

### AC-011: Palette generation from accent
- **Complexity**: Simple
- **Effort**: 30min
- **Tasks**: Port algorithm from enterprise presets.json, document in command
- **Risk**: None — algorithm is proven and well-documented

### AC-012–013: Git-committed config + color presets
- **Complexity**: Simple
- **Effort**: 30min
- **Tasks**: Presets file creation, config is already git-committed
- **Risk**: None

## Implementation Phases

### Phase 1: Data Model + Presets (1h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-001 | Create `templates/presets.json` — port 6 color presets + palette generation algorithm from enterprise | 20min | None | AC-013 |
| TASK-002 | Add `branding` section to `templates/config.json.template` with defaults (raspberry accent, auto-generated palette, null fonts/tone/logo/styleGuideSource) | 20min | None | AC-002, AC-011 |
| TASK-003 | Update `commands/init.md` — add branding question after Section 2 (architecture). One question: "Do you have a brand or style guide?" with Yes/No options. If yes, capture materials. If no, use defaults. | 20min | TASK-002 | AC-001, AC-003 |

### Phase 2: /add:brand Command (1.5h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-004 | Create `commands/brand.md` — read-only command that displays current branding from `.add/config.json`: accent, palette, fonts, tone, logo, style guide source | 30min | TASK-002 | AC-004 |
| TASK-005 | Add drift detection logic to brand.md — scan `docs/infographic.svg` and `reports/*.html` for color mismatches against configured accent | 30min | TASK-004 | AC-005 |
| TASK-006 | Add image gen status display to brand.md — read `imageGeneration` section from config, show status + setup guidance if not configured | 30min | TASK-004 | AC-006 |

### Phase 3: /add:brand-update Command (1.5h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-007 | Create `commands/brand-update.md` — accepts new branding materials (hex color, preset name, font, tone, logo path, style guide URL/path). Updates `.add/config.json` branding section. | 30min | TASK-002 | AC-007, AC-008 |
| TASK-008 | Add audit logic to brand-update.md — after updating config, scan existing artifacts for brand inconsistencies. Produce diff-style report. | 30min | TASK-007 | AC-009 |
| TASK-009 | Add optional fix application — with user confirmation, regenerate artifacts with new brand. Call infographic/report generation if those skills exist. | 30min | TASK-008 | AC-010 |

## Effort Summary

| Phase | Estimated Hours |
|-------|----------------|
| Phase 1: Data Model + Presets | 1.0h |
| Phase 2: /add:brand Command | 1.5h |
| Phase 3: /add:brand-update Command | 1.5h |
| **Total** | **4.0h** |

## Parallelization Strategy

Solo with 2 agents:
```
Agent 1: TASK-001 (presets.json) → TASK-004 (brand.md) → TASK-007 (brand-update.md)
Agent 2: TASK-002 (config template) → TASK-003 (init.md) → TASK-005 (drift) → TASK-006 (image gen status)
```

TASK-008 and TASK-009 depend on TASK-007, so they run sequentially after.

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Drift detection too broad | Low | Low | Limit to known artifact paths (infographic.svg, reports/*.html) |
| Palette algorithm edge cases | Low | Low | Use proven enterprise algorithm as-is |
| Brand-update audit scope creep | Medium | Low | Keep audit focused on color matching, not content |

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `templates/presets.json` | 6 color presets + palette generation algorithm |
| Modify | `templates/config.json.template` | Add `branding` section |
| Modify | `commands/init.md` | Add branding question to interview |
| Create | `commands/brand.md` | `/add:brand` command |
| Create | `commands/brand-update.md` | `/add:brand-update` command |

## Success Criteria

- [ ] All 13 acceptance criteria implemented
- [ ] Presets.json contains 6 presets + generation algorithm
- [ ] Config template has branding section with raspberry defaults
- [ ] Init asks branding question and stores response
- [ ] `/add:brand` displays branding, drift, and image gen status
- [ ] `/add:brand-update` accepts materials, updates config, audits artifacts
- [ ] All quality gates passing

## Next Steps

1. Approve this plan
2. Implement Phase 1 (foundation for all other features)
3. Implement Phases 2–3
4. Sync to marketplace
5. Unblocks: image-gen-detection and infographic-generation plans

## Plan History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial plan |

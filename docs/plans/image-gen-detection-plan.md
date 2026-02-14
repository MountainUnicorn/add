# Implementation Plan: Point-of-Use Image Generation Detection

**Spec Version**: 0.1.0
**Spec File**: specs/image-gen-detection.md
**Created**: 2026-02-14
**Team Size**: Solo (2 parallel agents)
**Estimated Duration**: 2 hours
**Implementation Order**: 2 of 4 (can run parallel with changelog)

## Overview

Add runtime image gen MCP detection that fires at point of use rather than during init. Visual skills check for MCP tools, cache the result in config, fall back gracefully, and nudge the user once. Detection logic is shared via a knowledge file so all visual skills use the same pattern.

## Objectives

- Detect image gen MCP tools at runtime (not init time)
- Cache detection results in `.add/config.json`
- Provide one-time setup encouragement
- Display status in `/add:brand`
- Graceful SVG-only fallback when unavailable

## Cross-Feature Dependencies

```
Branding System ──→ Image Gen Detection (branding config must exist first)
Image Gen Detection ──→ Infographic Generation (consumer)
Image Gen Detection ──→ /add:brand (displays status)
```

**Blocked by**: Branding System (needs `branding` key in config to be structurally complete)
**Can parallelize with**: Auto-Changelog (no shared dependencies)

## Acceptance Criteria Analysis

### AC-001–002: Runtime detection + MCP scanning
- **Complexity**: Medium
- **Effort**: 45min
- **Tasks**: Write detection algorithm as knowledge file, scan .mcp.json files
- **Risk**: MCP config format could vary — need to handle gracefully

### AC-003–004: Cache result + use tool
- **Complexity**: Simple
- **Effort**: 15min
- **Tasks**: Store in config.json, document usage pattern for skills
- **Risk**: None

### AC-005–007: Fallback + one-time nudge + nudge tracking
- **Complexity**: Simple
- **Effort**: 15min
- **Tasks**: SVG-only fallback messaging, nudged flag in config
- **Risk**: None

### AC-008: /add:brand integration
- **Complexity**: Simple
- **Effort**: 15min
- **Tasks**: Already covered in branding system plan (TASK-006)
- **Risk**: None — this is wired into /add:brand during branding implementation

### AC-009–011: No bundled accounts + stale detection + performance
- **Complexity**: Simple
- **Effort**: 15min
- **Tasks**: Documentation/constraints, clear stale cache, keep detection fast
- **Risk**: None

## Implementation Phases

### Phase 1: Detection Logic (1h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-001 | Create `knowledge/image-gen-detection.md` — shared detection algorithm and usage instructions for all visual skills. Includes: known tool patterns, scan locations (~/.mcp.json, ./.mcp.json), cache strategy, nudge logic. | 30min | Branding config template exists | AC-001, AC-002, AC-009 |
| TASK-002 | Add `imageGeneration` section to `templates/config.json.template`: `{ enabled: false, tool: null, plugin: null, nudged: false, lastDetected: null }` | 15min | None | AC-003, AC-007 |
| TASK-003 | Document fallback behavior in knowledge file: SVG-only mode instructions, one-time nudge message template, nudge suppression logic | 15min | TASK-001 | AC-005, AC-006, AC-010 |

### Phase 2: Integration Points (1h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-004 | Update branding system's `/add:brand` command to display image gen status from config (if branding commands are already created) or document integration point for branding plan | 15min | Branding TASK-006 | AC-008 |
| TASK-005 | Create detection usage example for skill authors — add a "Point-of-Use Detection" section to knowledge file showing exactly how a visual skill should call detection at start | 30min | TASK-001 | AC-004, AC-011 |
| TASK-006 | Document stale detection handling: if cached tool not found in .mcp.json on next scan, clear cache, fall back, warn user | 15min | TASK-001 | AC-010 |

## Effort Summary

| Phase | Estimated Hours |
|-------|----------------|
| Phase 1: Detection Logic | 1.0h |
| Phase 2: Integration Points | 1.0h |
| **Total** | **2.0h** |

## Parallelization Strategy

Solo with 2 agents — this feature is small enough to run sequentially, but can run in parallel with auto-changelog since they're independent.

```
Wave 2 (after branding):
  Agent 1: Image Gen Detection (this plan)
  Agent 2: Auto-Changelog (parallel)
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| MCP config format varies across versions | Low | Medium | Parse defensively, handle missing/malformed gracefully |
| Multiple image gen tools installed | Low | Low | Use first match, document override via /add:brand-update |
| Detection adds latency to visual skills | Low | Medium | Simple JSON file reads — sub-second |

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `knowledge/image-gen-detection.md` | Shared detection algorithm + usage guide |
| Modify | `templates/config.json.template` | Add `imageGeneration` section |
| Modify | `commands/brand.md` | Add image gen status display (if already created) |

## Success Criteria

- [ ] All 11 acceptance criteria addressed
- [ ] Knowledge file documents complete detection algorithm
- [ ] Config template includes imageGeneration section
- [ ] Detection logic handles: found, not found, stale, nudged
- [ ] Visual skills have clear integration pattern documented
- [ ] /add:brand shows image gen status

## Next Steps

1. Approve this plan
2. Wait for branding system Phase 1 to complete (config structure)
3. Implement detection logic
4. Wire into /add:brand
5. Unblocks: infographic-generation plan

## Plan History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial plan |

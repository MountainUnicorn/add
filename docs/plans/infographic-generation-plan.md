# Implementation Plan: Infographic Generation

**Spec Version**: 0.1.0
**Spec File**: specs/infographic-generation.md
**Created**: 2026-02-14
**Team Size**: Solo (2 parallel agents)
**Estimated Duration**: 5 hours
**Implementation Order**: 4 of 4 (depends on branding + image gen detection)

## Overview

A new `/add:infographic` skill that generates a professional SVG infographic (`docs/infographic.svg`) from the project's PRD and config. Follows the Silicon Valley Unicorn design aesthetic ported from the enterprise plugin, uses configurable branding from `.add/config.json`, and optionally leverages image gen MCP tools when available.

## Objectives

- Generate polished project infographic from PRD + config data
- Apply branding from project config (accent color, palette)
- Use image gen MCP when available, fall back to SVG-only
- Auto-embed in README.md
- Self-verify all required sections are present

## Cross-Feature Dependencies

```
Branding System ──→ Infographic Generation (reads palette)
Image Gen Detection ──→ Infographic Generation (checks for MCP tools)
Infographic Generation ──→ /add:brand (drift detection scans infographic)
```

**Blocked by**: Branding System + Image Gen Detection (both must be complete)
**Blocks**: Nothing directly, but enables richer `/add:brand` drift detection

## Acceptance Criteria Analysis

### AC-001–002: Generate from PRD/config + use branding
- **Complexity**: Medium
- **Effort**: 1h
- **Tasks**: Content extraction from PRD, palette application from config
- **Risk**: PRD structure varies — need flexible parsing

### AC-003–008: SVG structure requirements (7 sections)
- **Complexity**: High (largest single piece of work)
- **Effort**: 2h
- **Tasks**: Port enterprise SVG template, adapt for ADD content sources, ensure all 7 sections
- **Risk**: SVG authoring is detail-intensive — template quality is critical

### AC-009–010: Image gen integration + SVG-only fallback
- **Complexity**: Medium
- **Effort**: 30min
- **Tasks**: Call detection from knowledge file, branch on result
- **Risk**: Low — detection logic is already defined in image-gen-detection knowledge file

### AC-011: Auto-embed in README
- **Complexity**: Simple
- **Effort**: 15min
- **Tasks**: Check README for existing reference, add if missing
- **Risk**: README format varies — insert position matters

### AC-012–018: Update flag, inline styles, system fonts, defs, verification
- **Complexity**: Simple–Medium
- **Effort**: 1h
- **Tasks**: SVG best practices (already documented in enterprise design system), verification checklist
- **Risk**: Low — following proven enterprise patterns

## Implementation Phases

### Phase 1: Design System + Template (2h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-001 | Create `rules/design-system.md` — port from enterprise, adapt for ADD. Silicon Valley Unicorn aesthetic: dark backgrounds, glassmorphism, gradient orbs, outcome-focused messaging. Raspberry default instead of purple. | 30min | None | AC-003 |
| TASK-002 | Create `templates/infographic.svg.template` — base SVG with all 7 required sections as placeholder blocks. viewBox 1200x800, defs block with gradients/filters, inline styles only, system fonts. Use `{PLACEHOLDER}` syntax for dynamic content. | 1h | TASK-001 | AC-003–008, AC-013–015 |
| TASK-003 | Document content source mapping — which data point comes from which file (PRD sections → hero headline, config → metrics, spec count → metrics bar, etc.) | 30min | None | AC-001, AC-006–008 |

### Phase 2: Skill Implementation (2h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-004 | Create `skills/infographic/SKILL.md` — main skill definition. Steps: read PRD, read config, scan live metrics (spec count, test count, maturity), run image gen detection, compose SVG from template + content, write to docs/infographic.svg | 1h | TASK-002, TASK-003 | AC-001, AC-002, AC-012 |
| TASK-005 | Add image gen integration to skill — if MCP tool detected (per image-gen-detection knowledge file), generate hero illustration and embed as base64 `<image>` element. If not, use gradient/text-based hero. | 30min | TASK-004, image-gen-detection plan complete | AC-009, AC-010 |
| TASK-006 | Add README auto-embed — after writing SVG, check README.md for `![Project Infographic]` reference. If missing, add `## Overview\n\n![Project Infographic](docs/infographic.svg)` after title section. | 15min | TASK-004 | AC-011 |
| TASK-007 | Add `--update` flag handling — re-read all sources and regenerate. Same logic as initial generation but overwrites existing file. | 15min | TASK-004 | AC-012 |

### Phase 3: Verification + Polish (1h)

| Task ID | Description | Effort | Dependencies | AC |
|---------|-------------|--------|--------------|-----|
| TASK-008 | Add verification checklist to skill — after writing SVG, read it back and verify: file exists, viewBox correct, dark background present, all gradients/filters in defs, project name present (not placeholder), all 7 sections present, file size > 5KB. If any check fails, regenerate. | 30min | TASK-004 | AC-016–018 |
| TASK-009 | Add maturity-aware content adaptation — POC gets simpler infographic (fewer value cards, basic metrics). GA gets full treatment. Read maturity from config. | 15min | TASK-004 | AC-003 |
| TASK-010 | Add success output — report file size, sections generated, image gen used (yes/no), README updated (yes/no) | 15min | TASK-008 | AC-018 |

## Effort Summary

| Phase | Estimated Hours |
|-------|----------------|
| Phase 1: Design System + Template | 2.0h |
| Phase 2: Skill Implementation | 2.0h |
| Phase 3: Verification + Polish | 1.0h |
| **Total** | **5.0h** |

## Parallelization Strategy

Solo with 2 agents:
```
Agent 1: TASK-001 (design system) → TASK-002 (SVG template) → TASK-004 (skill) → TASK-008 (verification)
Agent 2: TASK-003 (content mapping) → TASK-005 (image gen) → TASK-006 (README) → TASK-007 (update flag) → TASK-009 (maturity) → TASK-010 (output)
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| SVG rendering differs between browsers/GitHub | Medium | Medium | Stick to inline styles, system fonts, no foreignObject — proven enterprise patterns |
| PRD format varies across projects | Medium | Low | Flexible parsing with fallbacks for each data point |
| Large SVG file from embedded base64 images | Low | Low | Only embed if image gen used; SVG-only stays small |
| GitHub strips SVG features | Low | High | No `<style>`, no `<script>`, no external refs — all inline |
| Hero headline generation quality | Medium | Medium | Use PRD problem statement directly, don't over-generate |

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `rules/design-system.md` | ADD design system (ported from enterprise) |
| Create | `templates/infographic.svg.template` | Base SVG with 7 placeholder sections |
| Create | `skills/infographic/SKILL.md` | `/add:infographic` skill |
| Modify | `commands/init.md` | Mention infographic as next step in Phase 5 |

## Enterprise Port Checklist

Items to port from enterprise plugin:

- [x] Color presets (`presets.json`) — covered in branding plan
- [ ] Design system rule (`design-system.md`) — TASK-001
- [ ] SVG template structure (7 sections, defs, gradients) — TASK-002
- [ ] Verification checklist (file exists, sections present, size) — TASK-008
- [ ] Content sourcing pattern (project data → template vars) — TASK-003

Items NOT ported (enterprise-specific):
- Spike tracking JSON — ADD uses learnings + cycles instead
- Before/after metrics — ADD uses /add:verify for this
- Actions timeline — enterprise spike concept doesn't apply
- Marketing brief generation — may be future enhancement

## Success Criteria

- [ ] All 18 acceptance criteria implemented
- [ ] Design system rule covers Silicon Valley Unicorn aesthetic
- [ ] SVG template has all 7 required sections
- [ ] Skill reads from PRD + config + live metrics
- [ ] Image gen integration works when MCP available
- [ ] SVG-only fallback produces professional infographic
- [ ] README auto-embed works
- [ ] Verification catches missing sections and regenerates
- [ ] Maturity level affects infographic complexity
- [ ] Generated SVG renders correctly on GitHub

## Next Steps

1. Approve this plan
2. Wait for branding + image gen detection to complete
3. Implement Phase 1 (design system + template)
4. Implement Phases 2–3
5. Test with ADD's own infographic (dogfood)
6. Sync to marketplace

## Plan History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-02-14 | 0.1.0 | abrooke + Claude | Initial plan |

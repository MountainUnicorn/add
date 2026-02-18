# Implementation Plan: Cross-Project Learning Library Search

**Spec Version:** 0.1.0
**Spec:** specs/learning-library-search.md
**Created:** 2026-02-17
**Team Size:** Solo (1 agent, 2 parallel sub-agents available)
**Estimated Duration:** 1 session (~2-3 hours)

## Overview

Replace ADD's freeform markdown learning logs with structured JSON entries, add smart filtering on the read path, scope classification on the write path, and a migration utility for existing data. This touches the learning rule (core), checkpoint triggers in skills/commands, the retro command, and the data files themselves.

## Objectives

- Structured JSON storage for learnings at both project and workstation tiers
- Smart filtering: agents see only relevant learnings per skill invocation
- Scope classification: learnings auto-routed to the right tier at write time
- Migration: existing freeform markdown converted to JSON with inferred tags
- Markdown views: human-readable files regenerated from JSON

## Acceptance Criteria Analysis

### Section A: Structured Learning Entries (AC-001 – AC-008)

- **Complexity:** Medium
- **Effort:** 1h
- **Tasks:** Define JSON schema, create empty learnings.json and library.json templates, document enum values
- **Dependencies:** None — foundational work
- **Risk:** Schema design affects all downstream phases; get it right first

### Section B: Smart Filtering / Read Path (AC-009 – AC-015)

- **Complexity:** Medium
- **Effort:** 1.5h
- **Tasks:** Update learning rule to read JSON, implement stack+category filtering, implement ranking, add context cap, handle missing/empty files
- **Dependencies:** Section A (JSON schema must exist)
- **Risk:** Filtering logic is the core value — must be correct

### Section C: Scope Classification / Write Path (AC-016 – AC-020)

- **Complexity:** Medium
- **Effort:** 1.5h
- **Tasks:** Update checkpoint triggers in learning rule, update all skill observation writers, update cycle command checkpoint, add classification logic, add `classified_by` field
- **Dependencies:** Section A (JSON schema), understanding of all checkpoint trigger locations
- **Risk:** Many files to update (learning rule + 3 skill SKILL.md files + cycle command). Must be consistent.

### Section D: Migration (AC-021 – AC-024)

- **Complexity:** Medium
- **Effort:** 1h
- **Tasks:** Create migration instructions in learning rule (Claude-driven migration, not scripted), backup originals, infer tags, generate JSON, regenerate markdown
- **Dependencies:** Section A (JSON schema)
- **Risk:** Tag inference from freeform text may be imprecise — acceptable (can fix in retro)

### Section E: Markdown View Generation (AC-025 – AC-027)

- **Complexity:** Simple
- **Effort:** 30min
- **Tasks:** Define markdown generation format in learning rule, add generation step after JSON writes
- **Dependencies:** Section A (JSON schema)
- **Risk:** Low

### Section F: Project Index Integration (AC-028 – AC-029)

- **Complexity:** Simple
- **Effort:** 15min
- **Tasks:** Add `learnings_count` to project index files, add cross-project stack lookup hint
- **Dependencies:** Section C (write path must exist to count entries)
- **Risk:** Low — nice-to-have

## Implementation Phases

### Phase 1: Data Model & Schema (AC-001 – AC-008)

Define the JSON structures that everything else depends on.

| Task ID | Description | ACs | Effort | Dependencies |
|---------|-------------|-----|--------|--------------|
| TASK-001 | Create `templates/learnings.json.template` with LearningsFile schema, enum documentation, and example entry | AC-001, AC-004–AC-008 | 20min | None |
| TASK-002 | Create `templates/library.json.template` (workstation-scope variant of the same schema) | AC-001 | 10min | TASK-001 |
| TASK-003 | Document the operation-to-category mapping and scope classification rules in the learning rule | AC-006, AC-010 | 15min | None |

**Phase Duration:** 45min
**Blockers:** None

### Phase 2: Read Path — Smart Filtering (AC-009 – AC-015)

Update `rules/learning.md` to read JSON and filter intelligently.

| Task ID | Description | ACs | Effort | Dependencies |
|---------|-------------|-----|--------|--------------|
| TASK-004 | Update "Read Before Work" section in `rules/learning.md`: read `.add/learnings.json` and `~/.claude/add/library.json` (with fallback to .md if JSON doesn't exist yet) | AC-009, AC-014 | 20min | TASK-001 |
| TASK-005 | Add "Smart Filtering" section to `rules/learning.md`: stack overlap filter, category-per-operation filter, stack-agnostic passthrough | AC-010, AC-015 | 30min | TASK-003 |
| TASK-006 | Add "Ranking & Context Cap" section: severity ranking, date tiebreaker, top-10 cap, silent skip on empty results | AC-011, AC-012, AC-013 | 20min | TASK-005 |

**Phase Duration:** 1h 10min
**Blockers:** None (Phase 1 can be done first, or in parallel with TASK-003)

### Phase 3: Write Path — Scope Classification & Checkpoint Updates (AC-016 – AC-020)

Update all checkpoint writers to produce structured JSON entries.

| Task ID | Description | ACs | Effort | Dependencies |
|---------|-------------|-----|--------|--------------|
| TASK-007 | Add "Scope Classification" section to `rules/learning.md` with classification rules, decision tree, and `classified_by` field | AC-016, AC-017, AC-020 | 20min | TASK-001 |
| TASK-008 | Update checkpoint trigger formats in `rules/learning.md`: all 6 checkpoint types (Post-Verify, Post-TDD, Post-Away, Feature Complete, Post-Deploy, Verification Catch) now produce JSON entries instead of markdown blocks | AC-016, AC-018 | 40min | TASK-007 |
| TASK-009 | Update `skills/verify/SKILL.md` process observation to write JSON entry to appropriate tier | AC-016, AC-018 | 10min | TASK-007 |
| TASK-010 | Update `skills/deploy/SKILL.md` process observation to write JSON entry to appropriate tier | AC-016, AC-018 | 10min | TASK-007 |
| TASK-011 | Update `skills/tdd-cycle/SKILL.md` process observation to write JSON entry to appropriate tier | AC-016, AC-018 | 10min | TASK-007 |
| TASK-012 | Update `commands/cycle.md` checkpoint (Step 4: Archive Cycle) to write JSON entries | AC-016, AC-018 | 10min | TASK-007 |
| TASK-013 | Add markdown view regeneration step after each JSON write (in learning rule) | AC-025, AC-026, AC-027 | 15min | TASK-008 |

**Phase Duration:** 1h 55min
**Blockers:** Phase 1 schema must be defined

### Phase 4: Retro Integration (AC-019)

Update the retro command to support scope review and reclassification.

| Task ID | Description | ACs | Effort | Dependencies |
|---------|-------------|-----|--------|--------------|
| TASK-014 | Update `commands/retro.md` Phase 5 to read/write JSON instead of markdown for learnings and library | AC-019 | 20min | TASK-007 |
| TASK-015 | Add scope review step to retro: present recent agent-classified entries, allow human override, move entries between tiers | AC-019, AC-020 | 20min | TASK-014 |

**Phase Duration:** 40min
**Blockers:** Phase 3 (write path must exist so there are entries to review)

### Phase 5: Migration (AC-021 – AC-024)

Add migration instructions for converting existing freeform data.

| Task ID | Description | ACs | Effort | Dependencies |
|---------|-------------|-----|--------|--------------|
| TASK-016 | Add "Migration from Markdown" section to `rules/learning.md` with step-by-step migration flow: backup, parse, classify, write JSON, regenerate markdown | AC-021, AC-022, AC-023, AC-024 | 30min | TASK-001, TASK-007 |
| TASK-017 | Add project index `learnings_count` field and cross-project stack lookup | AC-028, AC-029 | 15min | TASK-008 |

**Phase Duration:** 45min
**Blockers:** Phase 1 (schema) and Phase 3 (classification rules)

### Phase 6: Polish & Existing Data Consistency (AC-002, AC-003)

Ensure dual-format (JSON + markdown) works end-to-end.

| Task ID | Description | ACs | Effort | Dependencies |
|---------|-------------|-----|--------|--------------|
| TASK-018 | Update Knowledge Store Boundaries table in learning rule to reflect JSON as primary, markdown as generated view | AC-002, AC-003 | 10min | TASK-004 |
| TASK-019 | Update CLAUDE.md learning system section to reference JSON format | — | 10min | TASK-018 |
| TASK-020 | Update M2 milestone to mark this feature DONE | — | 5min | All |

**Phase Duration:** 25min
**Blockers:** All previous phases

## Effort Summary

| Phase | Tasks | Estimated Time | Dependencies |
|-------|-------|---------------|--------------|
| Phase 1: Data Model | 3 | 45min | None |
| Phase 2: Read Path | 3 | 1h 10min | Phase 1 |
| Phase 3: Write Path | 7 | 1h 55min | Phase 1 |
| Phase 4: Retro Integration | 2 | 40min | Phase 3 |
| Phase 5: Migration | 2 | 45min | Phase 1 + 3 |
| Phase 6: Polish | 3 | 25min | All |
| **Total** | **20** | **~5h 40min** | — |

With parallel sub-agents (Phases 2 + 3 can overlap after Phase 1):

| Schedule | Work | Agent |
|----------|------|-------|
| Block 1 (45min) | Phase 1: Data Model | Main |
| Block 2 (1h 55min) | Phase 2: Read Path | Agent A |
| Block 2 (1h 55min) | Phase 3: Write Path | Agent B |
| Block 3 (40min) | Phase 4: Retro Integration | Main |
| Block 3 (45min) | Phase 5: Migration | Main |
| Block 4 (25min) | Phase 6: Polish | Main |

**Estimated with parallelism: ~3h 50min**

## Parallelization Strategy

```
Block 1 (sequential — defines schema everything depends on):
  Main: TASK-001 → TASK-002 → TASK-003

Block 2 (parallel — read and write paths are independent):
  Agent A: TASK-004 → TASK-005 → TASK-006  (read path in learning rule)
  Agent B: TASK-007 → TASK-008 → TASK-009/010/011/012 → TASK-013  (write path across skills)

Block 3 (sequential — depends on write path):
  Main: TASK-014 → TASK-015 → TASK-016 → TASK-017

Block 4 (sequential — final consistency pass):
  Main: TASK-018 → TASK-019 → TASK-020
```

**Key constraint:** The learning rule (`rules/learning.md`) is a shared file touched by both the read path (Phase 2) and write path (Phase 3). If running in parallel, Agent A edits the "Read Before Work" and "Smart Filtering" sections while Agent B edits the "Checkpoint Triggers" and "Scope Classification" sections. No overlap in sections, but parallel file edits are risky at alpha maturity. **Recommend sequential for the learning rule edits.**

**Revised practical approach:** Phase 1 → Phase 2 (learning rule read path) → Phase 3 (learning rule write path + parallel skill edits) → Phase 4 → Phase 5 → Phase 6.

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Learning rule becomes too long (already 265 lines) | Medium | Medium | Section headers are clear; consider splitting into `learning-read.md` and `learning-write.md` in a future refactor |
| Existing checkpoint code in skills references markdown format | Low | Low | Grep for all `learnings.md` references and update systematically |
| Migration infers wrong tags from freeform text | Medium | Low | Default to `project`/`medium`/`technical`; retro can reclassify |
| Parallel agents conflict on learning rule edits | Medium | Medium | Run learning rule edits sequentially; parallelize only skill file edits |
| JSON files grow large over time | Low | Low | Already capped at 10 surfaced entries; archival in future retros |

## Testing Strategy

This is a pure markdown/JSON plugin — no automated test suite. Validation is via dogfooding:

1. **Schema validation:** Create a sample `.add/learnings.json` and `~/.claude/add/library.json` with test entries
2. **Read path:** Start a skill and verify only relevant entries surface
3. **Write path:** Run a TDD cycle, verify checkpoint writes JSON with correct scope classification
4. **Migration:** Run migration on this project's existing `.add/learnings.md` and `~/.claude/add/library.md`
5. **Retro:** Run `/add:retro` and verify scope review flow works
6. **Edge cases:** Test with empty files, no files, stack mismatch

## Deliverables

### New Files
- `templates/learnings.json.template` — JSON schema template for project learnings
- `templates/library.json.template` — JSON schema template for workstation library

### Modified Files
- `rules/learning.md` — Major rewrite: JSON read/write, filtering, classification, migration
- `skills/verify/SKILL.md` — Update process observation to JSON
- `skills/deploy/SKILL.md` — Update process observation to JSON
- `skills/tdd-cycle/SKILL.md` — Update process observation to JSON
- `commands/cycle.md` — Update checkpoint to JSON
- `commands/retro.md` — Add scope review, JSON read/write
- `CLAUDE.md` — Update learning system description
- `docs/milestones/M2-adoption-and-polish.md` — Mark feature DONE

### Data Files (migrated)
- `.add/learnings.json` — New, migrated from `.add/learnings.md`
- `~/.claude/add/library.json` — New, migrated from `~/.claude/add/library.md`

## Success Criteria

- [ ] All 18 Must ACs implemented
- [ ] All 7 Should ACs implemented
- [ ] JSON schema defined with all required fields
- [ ] Read path filters by stack + category + severity with 10-entry cap
- [ ] Write path classifies scope and routes to correct tier
- [ ] Migration converts existing data with inferred tags
- [ ] Markdown views regenerated from JSON
- [ ] Retro supports scope review and reclassification
- [ ] Existing learnings preserved (no data loss)

## Next Steps

1. Get approval of this plan
2. Begin Phase 1: Create JSON templates
3. Execute Phases 2-5 sequentially (learning rule is a shared file)
4. Run migration on this project's existing data as validation
5. Commit, push, sync marketplace

## Plan History

- 2026-02-17: Initial plan created from spec interview

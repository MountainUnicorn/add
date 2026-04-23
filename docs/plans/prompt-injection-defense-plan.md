# Implementation Plan: Prompt Injection Defense

**Spec:** `specs/prompt-injection-defense.md` (v0.1.0)
**Target Release:** v0.9.0
**Milestone:** M3-pre-ga-hardening (Cycle 2)
**Plan date:** 2026-04-22
**Author:** Swarm D (agent)

## Overview

Implements three layers of defense against prompt injection:

1. Auto-loaded behavioral rule telling the agent to treat external content as data.
2. PostToolUse scan hook that pattern-matches tool output against a catalog and writes audit events.
3. Threat-model knowledge file documenting trust boundaries, defended attacks, and out-of-scope threats.

All pieces are pure markdown/JSON/bash — no new runtime dependencies beyond the existing `jq` already required by `post-write.sh`.

## Files Created

| Path | Purpose |
|---|---|
| `core/rules/injection-defense.md` | Auto-loaded rule — trust boundary, recognition patterns, escalation script |
| `core/knowledge/threat-model.md` | Trust boundaries, defended attacks, out-of-scope, warn-only posture |
| `core/security/patterns.json` | Default pattern catalog (8 named patterns) |
| `runtimes/claude/hooks/posttooluse-scan.sh` | Scan dispatcher — reads stdin JSON, scans, writes audit events, emits warning |
| `tests/security/test-prompt-injection-defense.sh` | Fixture-based test harness |
| `tests/security/fixtures/` | Defanged payload fixtures (re-fanged at test time) |

## Files Modified

| Path | Change |
|---|---|
| `runtimes/claude/hooks/hooks.json` | Add PostToolUse matchers for `Read`, `WebFetch`, `WebSearch`, and extend `Bash` matcher to invoke `posttooluse-scan.sh` |
| (none else) | post-write.sh stays unchanged — this hook reads from stdin per Claude Code contract, hooks.json dispatches both scan + post-write for Write/Edit via a shell pipeline |

## AC Coverage Matrix

### A. Injection-Defense Rule

| AC | Where Covered |
|----|---------------|
| AC-001 | `core/rules/injection-defense.md` — `autoload: true` frontmatter, under 120 lines |
| AC-002 | `§ Trust Boundary` — trusted sources enumerated |
| AC-003 | `§ Trust Boundary` — untrusted sources enumerated |
| AC-004 | `§ Recognition Patterns` — red-flag patterns |
| AC-005 | `§ Non-Negotiables` — do-not-execute list |
| AC-006 | `§ Markdown Heading Guardrail` |
| AC-007 | `§ Escalation Script` |
| AC-008 | `§ See Also` — cites `core/knowledge/threat-model.md` |

### B. PostToolUse Scan Hook

| AC | Where Covered |
|----|---------------|
| AC-009 | `runtimes/claude/hooks/hooks.json` registers `posttooluse-scan.sh` on Read, WebFetch, WebSearch, Bash |
| AC-010 | Scan hook is a standalone script (not a parallel registration) — invoked via hooks.json entry. Write/Edit keep `post-write.sh`; scan is additive. Note: spec AC-010 mentions the dispatcher pattern from PR #7; the post-write dispatcher is for Write/Edit only. For the scan surface (Read/WebFetch/WebSearch/Bash) we use a single sub-script called directly — same "one script per event, dispatch inside" pattern. |
| AC-011 | `posttooluse-scan.sh` — reads stdin JSON, greps tool_output against catalog, emits `ADD-SEC: pattern=... source=... action=warn` to stderr |
| AC-012 | Hook exits 0 always, stderr is surfaced by Claude Code PostToolUse contract |
| AC-013 | `core/security/patterns.json` ships 8 named patterns |
| AC-014 | Each pattern has `name`/`regex`/`severity`/`description`/`source`/`enabled` |
| AC-015 | Scan script merges `core/security/patterns.json` + `~/.claude/add/security/patterns.json` + `.add/security/patterns.json`, project wins |
| AC-016 | Each match appends to `.add/security/injection-events.jsonl` with timestamp/tool/source/pattern/severity/excerpt (first 200 chars, redacted) |
| AC-017 | If `.add/` missing → no-op exit 0; if `.add/security/` missing but `.add/` exists → create |
| AC-018 | 10 MB truncation with `truncated: true` in audit event |
| AC-019 | Documented NFR — not CI-enforced |

### C. Threat Model Knowledge

| AC | Where Covered |
|----|---------------|
| AC-020 | `core/knowledge/threat-model.md` references OWASP 2026, Snyk ToxicSkills, Comment-and-Control, NVIDIA AGENTS.md, arXiv 2601.17548 |
| AC-021 | `§ Trust Boundaries` section |
| AC-022 | `§ Defended Attacks` — 5+ attack scenarios with examples |
| AC-023 | `§ Out-of-Scope Attacks` with rationale |
| AC-024 | `§ v0.9 Posture and Path to v1.0` |

### D. Codex Adapter

| AC | Where Covered |
|----|---------------|
| AC-025 | No change needed — `runtimes/codex/adapter.yaml` already concatenates all `core/rules/*.md` and all `core/knowledge/*.md`-derived content into `AGENTS.md`. The new `injection-defense.md` rule automatically flows through. |
| AC-026 | Documented in `core/knowledge/threat-model.md` `§ Runtime Limitations` (Codex hook limitation) |

### E. Tests

| AC | Where Covered |
|----|---------------|
| AC-027 | `tests/security/fixtures/` — defanged payloads (e.g., `IGN0RE PREVIOUS`), re-fanged by test harness |
| AC-028 | One test per named pattern (8 tests) |
| AC-029 | Negative-control test for benign prose |
| AC-030 | Dispatcher-fanout test — run posttooluse-scan alongside post-write, confirm both exit cleanly |

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| GitHub Push Protection flags literal injection strings in fixture files | High | Medium | Defang at rest; synthesize re-fanged payloads at test runtime |
| Scan hook triggers self-recursively when reading `injection-events.jsonl` | Medium | Low | Skip list for audit log path |
| hooks.json change conflicts with Swarm C (agents-md-sync PostToolUse addition) | Low | Low | Add our matchers on disjoint events (Read/WebFetch/WebSearch); only Bash is shared — merge-friendly addition |
| `threat-model.md` conflicts with Swarm B's secrets-handling PR #10 | High | Low | Both swarms aware; human resolves by keeping both threat sections |
| 10 MB scan on typical hardware exceeds 200 ms target | Low | Low | NFR documented; regex catalog small (8 patterns); grep native |

## Sequencing

1. Plan (this doc) — committed first
2. RED: fixtures + test harness (fails against empty hook)
3. GREEN: rule + hook + knowledge + patterns.json + hooks.json
4. VERIFY: compile/frontmatter/regressions + new fixture test suite
5. Commit series per spec (3 commits per conventional-commits guidance)
6. Push + PR

## Out of Scope (deferred)

- Block-on-critical mode (v1.0, spec §10 Q1)
- `/add:security-update` catalog-refresh command (v0.9.x, spec §10 Q2)
- CODEOWNERS for `tests/security/fixtures/` — separate infra PR
- `/add:retro` security-events surfacing — separate small follow-up (spec §8 Dependencies)

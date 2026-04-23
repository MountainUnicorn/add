# Milestone: M3 — Pre-GA Hardening

**Target Maturity:** beta
**Status:** ACTIVE
**Started:** 2026-04-22
**Target Completion:** 2026-05-20 (4-week scope)
**Driving Release:** v0.9.0

## Goal

Make ADD production-credible. Validate the multi-runtime promise with native Codex Skills emission, harden the security posture so the GA claim survives first security review, and double down on the methodology differentiators (TDD, AGENTS.md interop, observability) that the 2026 industry signal confirms are durable.

This milestone ships v0.9.0 — the release that earns ADD the right to call v1.0.0 "GA."

## Driving Context

Five parallel research swarms (Anthropic direction, Codex/OpenAI direction, IDE competitive landscape, AI dev framework trends, production AI engineering practices) converged on six themes for 2026:

1. **Spec-first methodology validated.** Anthropic's 2026 Agentic Coding Trends Report names spec-first the highest-impact practice (>60% rollback reduction). GitHub Spec Kit (~75k stars), OpenSpec, DeepLearning.AI's spec-driven course (April 2026 with JetBrains) all confirm. ADD's thesis is mainstream — leverage that.
2. **Context-window economics is the new battlefield.** Anthropic's 1h cache + workspace-scoped caching + MCP Tool Search lazy loading are shaping the discipline. Field is converging on "stable preamble first, volatile state last."
3. **Persistent cross-session memory crossed table-stakes.** Opus 4.7 explicitly tuned for it; MemPalace MCP hit 43k stars in a week.
4. **Parallel-agent worktree orchestration is the dominant 2026 UX.** Cursor 3 Agents Window, Windsurf Wave 13, Anthropic Routines, Codex sub-agents all shipped in the same window.
5. **ADD's Codex adapter is compiling to a deprecated target** — Codex shipped Skills with frontmatter, sub-agents (TOML), hooks; ADD writes to deprecated `~/.codex/prompts/`.
6. **Pre-GA security claims need real defense.** OWASP Top 10 for Agentic Applications 2026 published. Comment-and-Control attack actively exploited Claude Code Security Review + Gemini CLI + Copilot Agent. Snyk ToxicSkills: 36% of audited skills contained injection.

Full research output preserved at `.add/research/v0.9-swarms/` (TBD — see open questions).

## Success Criteria

- [ ] **Native Codex Skills** — `dist/codex/.agents/skills/add-{skill}/SKILL.md` with preserved frontmatter; AGENTS.md slimmed to manifest; Codex install matches Claude install in capability
- [ ] **Prompt-injection defense** — auto-loaded `rules/injection-defense.md`, PostToolUse scan hook, documented threat model in `knowledge/`
- [ ] **Secrets handling** — auto-loaded rule + `templates/.secretsignore` + pre-commit grep gate in `/add:deploy`
- [ ] **Structured JSONL telemetry** — `.add/telemetry/{date}.jsonl` aligned with OTel GenAI semantic conventions, surfaced in `/add:dashboard`
- [ ] **Test-deletion guardrail** — `/add:tdd-cycle` fails verification if test count decreases; impact-graph hint to implementer
- [ ] **Cache-discipline rule** — `rules/cache-discipline.md` codifying stable-preamble layout for skills + sub-agent prompts
- [ ] **AGENTS.md generation/sync** — `/add:agents-md` skill writes a tool-portable AGENTS.md from `.add/` state; auto-sync on project changes
- [ ] PR #6 (rules/knowledge on-demand loading from @tdmitruk) merged — foundation for cache discipline
- [ ] All seven specs above approved and shipped Complete
- [ ] Maturity promotion alpha → beta executed against the v0.9 release
- [ ] CHANGELOG `[0.9.0]` section published with full release notes

## Appetite

4 weeks of focused work. The 7 specs below are deliberately scoped so they can run in parallel — minimal cross-spec dependencies, each shippable independently. Sequence is preferred (see Cycle Plan), but failures or delays in any one spec do not block the others.

## Features

### Hill Chart

```
                    figuring it out  |  executing
                                     |
  ●  cache-discipline                |
   ●  agents-md-sync                 |
    ● telemetry-jsonl                |
       ● test-deletion-guardrail     |
              ● secrets-handling     |  ●  prompt-injection-defense
                                     |   ●  codex-native-skills
                                     |
                  uphill              downhill
                  (design)            (implementation)
```

(Drawn at milestone start. Per-feature positions update at each `/add:cycle --status`.)

### Feature Detail

| Spec | Sizing | Lead | Independence | Notes |
|------|--------|------|--------------|-------|
| `codex-native-skills` | Large | Maintainer | Independent | Touches `scripts/compile.py` + `runtimes/codex/adapter.yaml`. No shared files with other specs. |
| `prompt-injection-defense` | Medium | Community-eligible | Independent | New rule + new hook + new knowledge file. No conflicts. |
| `secrets-handling` | Small | Community-eligible | Mild dep on `injection-defense` (shared threat-model framing) | New rule + new template. Touches `/add:deploy` SKILL.md (read-mostly). |
| `telemetry-jsonl` | Medium | Maintainer | Mild dep — touches every skill's pre-flight (one-line append) | Pure additive: append-only file, zero risk to existing flows. |
| `test-deletion-guardrail` | Medium | Maintainer | Independent | Touches `/add:tdd-cycle` + `/add:verify`. Self-contained. |
| `cache-discipline` | Small | Community-eligible | Independent (rule-only) | Auto-loaded rule. Cross-references `learning.md` in v0.8 active-view spec. |
| `agents-md-sync` | Small | Community-eligible | Independent | New `/add:agents-md` skill + optional PostToolUse hook. |

## Cycle Plan

Three cycles within M3. Each cycle is a coordinated week of work; specs within a cycle can be developed in parallel by separate agent swarms (or contributors).

### Cycle 1 — Foundations (week 1)

Land the items that other items depend on. PR #6 lands first; cache-discipline rule lands on top.

- **PR #6 merge** (tdmitruk's rebase + final review) — opens up the on-demand-loading mechanism that `cache-discipline` formalizes
- **`cache-discipline` spec** — formalizes the layout convention now that the mechanism exists
- **`secrets-handling` spec** — narrow scope, ships fast, removes a GA blocker

### Cycle 2 — Security + Codex parity (week 2-3)

Ships the heaviest items in parallel. Three swarms working independently.

- **`prompt-injection-defense` spec** (security swarm)
- **`codex-native-skills` spec** (runtime swarm)
- **`agents-md-sync` spec** (interop swarm)

These three touch disjoint file sets. Merge order doesn't matter; CI gates (compile-drift, frontmatter, boundary) catch any conflicts.

### Cycle 3 — Methodology hardening (week 3-4)

Wraps the methodology-credibility items.

- **`telemetry-jsonl` spec** — every skill gets one-line telemetry append
- **`test-deletion-guardrail` spec** — `/add:tdd-cycle` and `/add:verify` integration
- **CHANGELOG promotion + maturity bump alpha → beta**
- **v0.9.0 release tag**

## Parallelism Analysis

**Disjoint file sets** (can develop in parallel without merge conflicts):

| Spec | Files touched |
|------|---------------|
| `codex-native-skills` | `scripts/compile.py`, `runtimes/codex/adapter.yaml`, `core/skills/*/SKILL.md` (frontmatter additions only) |
| `prompt-injection-defense` | `core/rules/injection-defense.md` (new), `runtimes/claude/hooks/posttooluse-scan.sh` (new), `core/knowledge/threat-model.md` (new), `runtimes/claude/hooks/hooks.json` (one-line addition) |
| `secrets-handling` | `core/rules/secrets-handling.md` (new), `core/templates/.secretsignore.template` (new), `core/skills/deploy/SKILL.md` (one section addition) |
| `telemetry-jsonl` | `core/rules/telemetry.md` (new), `core/templates/telemetry.jsonl.template` (new), `core/skills/dashboard/SKILL.md` (telemetry view section), `core/skills/*/SKILL.md` (one-line append in pre-flight; coordinated via shared substring) |
| `test-deletion-guardrail` | `core/skills/tdd-cycle/SKILL.md`, `core/skills/verify/SKILL.md`, `core/rules/tdd-enforcement.md` |
| `cache-discipline` | `core/rules/cache-discipline.md` (new) |
| `agents-md-sync` | `core/skills/agents-md/SKILL.md` (new), `runtimes/claude/hooks/hooks.json` (optional PostToolUse addition) |

**Shared touchpoints** (require coordination):

- **`runtimes/claude/hooks/hooks.json`** — `prompt-injection-defense` and `agents-md-sync` both potentially add PostToolUse entries. Coordinate via the `post-write.sh` dispatcher pattern established in v0.8 — each adds a case branch, no conflicts.
- **All `core/skills/*/SKILL.md` pre-flight blocks** — `telemetry-jsonl` adds one line per skill; `cache-discipline` may add a comment; `agents-md-sync` may reference. Coordinate via a single rule file (`telemetry.md` + `cache-discipline.md`) that all skills `@reference` rather than copy-pasting.

## Validation Criteria (per cycle and milestone)

Per spec — standard ADD gates:
- [ ] Spec has acceptance criteria with `Must` / `Should` / `Could` priorities
- [ ] All `Must` ACs have automated tests (unit, integration, or fixture-based)
- [ ] `python3 scripts/compile.py --check` passes (no drift)
- [ ] `python3 scripts/validate-frontmatter.py` passes
- [ ] `bash tests/hooks/test-filter-learnings.sh` passes (regression check)
- [ ] New hook scripts have fixture tests
- [ ] CHANGELOG `[Unreleased]` entry added

Per cycle — additional:
- [ ] `/add:cycle --complete` records a validation result for the cycle
- [ ] `/add:retro` captures learnings from the cycle (with collab/ADD/swarm scores)

Per milestone (v0.9.0):
- [ ] All 7 specs Status: Complete
- [ ] Maturity gap analysis passes (`/add:promote --check --target beta`)
- [ ] Release tagged (`./scripts/release.sh v0.9.0`)
- [ ] Release notes published with full enhancement breakdown + research-swarm attribution

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| PR #6 doesn't rebase cleanly / takes longer than week 1 | Medium | Medium — `cache-discipline` spec depends on the mechanism | Cache-discipline can ship as docs-only first; the mechanism PR #6 brings can integrate later as v0.9.x |
| Codex Skills format changes again before v0.9 ships | Low | High — would invalidate `codex-native-skills` work | Pin to specific Codex CLI version in `runtimes/codex/adapter.yaml`; cite version in spec |
| Prompt-injection defense gives false sense of security (rule says "be suspicious," doesn't actually block anything) | Medium | High — undermines the GA security claim | Pair the rule with the hook scanner; document explicitly what's defended vs not in `threat-model.md` |
| `telemetry-jsonl` adds visible pre-flight overhead users notice | Low | Low | Append-only file, no read; benchmark before merge |
| Community contributors take 4+ weeks instead of 4 weeks | Medium | Medium | Maintainer takes Cycle 1 + 3 directly; Cycle 2 parallelizable across community swarms with maintainer review |

## Out of Scope (deferred to v0.9.x or v0.10)

- `/add:parallel` worktree-based parallel cycle execution (M4 candidate)
- Routines/Loop integration adapter (waiting for Anthropic Routines GA)
- Capability-based `/add:eval` skill (M4 candidate)
- Cross-tool memory schema for `~/.claude/add/` (document in v0.9, implement in v0.10)
- Brownfield delta-spec mode (low-cost addition, can ship in v0.9.1)
- Governance maturity bands tied to autonomy ceilings (M4 candidate — needs careful design)
- Architect/Editor model-role rule (one-paragraph documentation pass; defer to v0.9.1)
- Marketplace re-submission to official Claude Code registry (parallel external work, no spec needed)

## Open Questions

1. **Where to preserve research swarm output?** Options: (a) `.add/research/v0.9-swarms/` (committed), (b) external doc repo, (c) embed key findings into the milestone + each spec. Recommendation: (c), with the full output archived separately.
2. **Should `/add:cycle` rename to `/add:arc` happen as part of M3, or wait for the parallel-cycle redesign in M4?** Recommendation: defer to M4 — rename + rework together rather than rename twice.
3. **Telemetry file: hourly rotation or daily?** Daily simpler; hourly better for high-throughput projects. Recommendation: daily, with documented opt-in to hourly via `.add/config.json` flag.

---

*M3 supersedes the prior implicit "M2-install-and-safety" target referenced in `.add/config.json`. Config will be updated to point at this milestone when the milestone enters Active status.*

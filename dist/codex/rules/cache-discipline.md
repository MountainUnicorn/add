---
autoload: true
maturity: beta
description: "Stable-prefix layout for skills and sub-agent dispatches. Enables Anthropic prompt-cache reuse (up to 90% cost / 85% latency savings per Anthropic case study)."
---

# ADD Rule: Cache Discipline

Every sub-agent prompt must share a **byte-identical STABLE prefix** followed
by a per-call VOLATILE suffix. Anthropic's prompt cache reuses the STABLE
region across dispatches; hits compound through a session.

This is a **structural rule, not a token-budget rule**. The invariant is
shape, not size.

## Layout Invariant

```
<!-- CACHE: STABLE -->
[autoload:true rule bodies, in stable order]
[tier-1 knowledge active views — global.md, library-active.md]
[project identity — .add/config.json summary]
[active learnings — .add/learnings-active.md]
[current spec — full body of the spec under work]
<!-- CACHE: VOLATILE -->
[per-call task, AC subset, hints, recent edits, tool outputs]
```

STABLE must be byte-identical across invocations in a session. Any per-call
variation belongs in VOLATILE. See `specs/cache-discipline.md § 5` for the
before/after example.

## Markers

- `<!-- CACHE: STABLE -->` opens the cacheable region.
- `<!-- CACHE: VOLATILE -->` opens the per-call region.

Markers are inert HTML comments — ignored by Claude Code's plugin loader,
invisible in rendered markdown. Their sole consumer is
`scripts/validate-cache-discipline.py`.

## Who Must Comply

- **Every SKILL.md that dispatches via the Task tool** — wrap the emitted
  prompt body with STABLE/VOLATILE markers.
- **`rules/agent-coordination.md`** — requires byte-identical prefixes across
  test-writer, implementer, reviewer dispatches.
- **Non-dispatching skills** — no markers required; validator skips silently.

## Precedent

v0.8's `.add/learnings-active.md` (pre-filtered companion view to
`learnings.json`) is the cache-stable pattern this rule generalizes.

## Validation

```bash
python3 scripts/validate-cache-discipline.py            # warn-only (v0.9)
python3 scripts/validate-cache-discipline.py --strict   # v1.0 enforcement
```

Findings: `{file}:{line}: {severity}: CACHE-NNN: {message}`. Codes:
`CACHE-001` missing markers + dispatch, `CACHE-002` inverted order,
`CACHE-003` volatile placeholder in STABLE, `CACHE-004` malformed marker,
`CACHE-100` (info) markers without dispatch.

## Telemetry

When `telemetry-jsonl` lands (Swarm F), per-skill lines carry `gen_ai.usage.cache_read_input_tokens`, `gen_ai.usage.cache_creation_input_tokens`, and derived `cache_hit_ratio = cache_read / (cache_read + cache_creation + uncached_input)`. Missing fields emit `null`, never error.

## References

- Anthropic caching — `extended-cache-ttl-2025-04-11` (1 h TTL), workspace-scoped caching (Feb 2026), 90% input-cost discount on hits.
- Anthropic case study — 85% latency reduction with cache-aware layout.
- Anthropic 2026 Agentic Coding Trends Report — context management is the dominant cost lever for agentic workflows.

Codex caching semantics differ; convention is provider-neutral in v0.9.

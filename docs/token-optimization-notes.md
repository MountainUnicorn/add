# Token Optimization — Caching & Latency Notes

> Companion notes to the v0.9.0 token-optimization refactor (PR [#6](https://github.com/MountainUnicorn/add/pull/6)).
> Covers the runtime behavior of on-demand `references/` loading, expected cache behavior,
> and the worst-case read cost per skill invocation.

## The savings model

Auto-loaded `core/rules/*.md` files shrank from ~35K tokens to ~13K tokens (63% reduction).
The remaining ~22K tokens live in `core/references/*.md` and are loaded **only when**
a skill that declares them in `references:` frontmatter is invoked.

| Store | Loaded | When |
|-------|--------|------|
| `knowledge/global.md` | every session | autoload |
| `rules/*.md` where `autoload != false` | every session | autoload |
| `rules/*.md` where `autoload: false` | on demand | skill reads via `@include` or `Read` |
| `references/*.md` | on demand | skill reads via `@include` or `Read` |

## Worst-case read budget

The heaviest realistic invocation is `/add:cycle` when it dispatches parallel sub-agents
against multiple feature branches:

- `/add:cycle` itself declares `references: [learning-reference.md, swarm-protocol.md]` — 2 reads
- Each parallel agent runs `/add:tdd-cycle` → 1 read (`learning-reference.md`) per agent
- Final `/add:verify` → 2 reads (`learning-reference.md`, `quality-checks-matrix.md`)
- Cycle retrospective writes learnings → 1 additional `learning-reference.md` read

With 4 parallel agents: **2 + (4 × 1) + 2 + 1 = 9 reads** in the worst case.

Total bytes on those reads: ~36KB (the full `references/` tree is 35KB). Each read is a
single-file `Read` or `@include` — there is no recursive expansion.

## Cache behavior

**Within a single session** (one skill invocation by one agent), a reference file is
typically read once and kept in the agent's context. Subsequent mentions resolve without
re-reading. This is the dominant case.

**Across sub-agents** (parallel Task-tool dispatch inside `/add:cycle`), each sub-agent
has its own context window. If four sub-agents each run `/add:tdd-cycle`, each will read
`learning-reference.md` independently — the reference content is loaded four times into
four separate contexts. This is intentional: sub-agents must have the checkpoint template
inline to write learnings correctly.

**Across skill invocations** (the human runs `/add:tdd-cycle` twice in the same Claude
Code session), each invocation is a fresh skill body load — the harness does not cache
skill-loaded files between invocations. Expect one additional read per invocation.

## Known limitation

We do not expose an explicit session-level cache handle. A skill cannot say "load this
reference only if it hasn't been loaded this session" — the read is re-issued each
invocation. For the current reference sizes (largest is `learning-reference.md` at ~11KB),
this is acceptable: the worst-case 9 reads per cycle add ~36KB to context, which is
still **63% less** than the previous always-autoload baseline of ~132KB.

If reference sizes grow materially in the future, consider:
- Consolidating per-skill needs into a session-scoped "preamble" read that the orchestrator performs once and passes via context to sub-agents
- Adding a `references: once_per_session` qualifier to the skill frontmatter and teaching `/add:cycle` to dedupe

Neither is implemented in v0.9.0.

## Measurement

Token counts are measured with `scripts/count-tokens.py` (uses `anthropic-tokenizer` — same tokenizer as the Claude API). Run from the venv:

```bash
python3 -m venv scripts/.venv
scripts/.venv/bin/pip install anthropic-tokenizer
scripts/.venv/bin/python scripts/count-tokens.py
```

The script compares `main` vs. the working tree and prints per-file before/after counts.

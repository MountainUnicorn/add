---
description: "[ADD v0.9.3] Generate or sync a portable AGENTS.md from ADD project state — writes, checks drift, or merges with hand-curated content"
argument-hint: "[--write|--check|--merge|--import] [--dry-run]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
references: ["rules/telemetry.md"]
---

# ADD AGENTS.md Skill v0.9.3

Generate a portable [`AGENTS.md`](https://agents.md) at project root from the project's `.add/` state. `AGENTS.md` is the cross-tool open standard for project-level agent instructions — any agent (Claude Code, Cursor, Codex CLI, Windsurf, Amp, Devin, Copilot) will read it on session start. Publishing one lets mixed-toolchain teams respect the same invariants without installing ADD.

This skill is the only way to regenerate AGENTS.md. A PostToolUse hook marks the file *stale* when source inputs change — the human triggers the actual regeneration.

## Invocation

```
/add:agents-md               # default: --write
/add:agents-md --check       # drift detection, CI-friendly (exit 1 on drift)
/add:agents-md --merge       # prepend ADD block to an existing hand-curated AGENTS.md
/add:agents-md --import      # one-time absorption (same as --merge; explicit intent)
/add:agents-md --dry-run     # preview without writing (combines with any mode)
```

## Pre-Flight Checks

1. **Read `.add/config.json`**
   - Load `project.name`, `project.description`
   - Load `maturity.level` (poc | alpha | beta | ga)
   - Load `architecture.languages` — determines whether the TDD Discipline section applies
   - Load `environments.*.autoPromote` — determines the autonomy ceiling summary

2. **Read `docs/prd.md` if present**
   - The H1 + first paragraph become the project identity section
   - If absent, fall back to `project.description` from config

3. **Read `.add/handoff.md` if present**
   - Extract the currently-active spec reference (first `specs/*.md` match in the file)
   - If absent, pick the most recently mutated `specs/*.md` by mtime

4. **Check `.add/agents-md.stale`**
   - If present, announce the stale state and the source files that changed since the last regen
   - This marker is removed automatically after a successful `--write`

5. **Detect existing `AGENTS.md`**
   - No file → default `--write` creates it fresh
   - File with ADD marker block → `--write` replaces managed content, preserves user-authored content outside the markers
   - File without ADD marker → `--write` aborts with guidance to use `--merge` or `--import`
   - Frontmatter (YAML / TOML / `+++`) at top is preserved verbatim

## Generator Invocation

The skill delegates to `scripts/generate-agents-md.py`:

```bash
python3 scripts/generate-agents-md.py              # --write (default)
python3 scripts/generate-agents-md.py --check
python3 scripts/generate-agents-md.py --merge
python3 scripts/generate-agents-md.py --import
python3 scripts/generate-agents-md.py --dry-run
```

The script is deterministic given the same inputs plus `--generated` and `--skill-version` overrides (used by fixture tests for reproducibility). Normal invocation stamps the current UTC timestamp and reads the skill version from `core/VERSION`.

## Marker Block Convention

```markdown
<!-- ADD:MANAGED:START version=0.9.0 maturity=beta generated=2026-04-22T14:32:01Z -->
... ADD-owned content ...
<!-- ADD:MANAGED:END -->
```

- HTML comments — invisible in rendered markdown, durable across editors
- Opening marker carries skill version, maturity level at render time, ISO timestamp
- `--check` can short-circuit on metadata mismatch before full diff

User-authored content lives outside these markers and is never touched by regeneration. `--merge` wraps existing content in `<!-- USER:AUTHORED:START -->` / `<!-- USER:AUTHORED:END -->` below the ADD block for clarity.

## Maturity-Aware Verbosity

The generator selects a rendering branch based on `maturity.level`:

| Maturity | Sections | Target |
|----------|----------|--------|
| `poc` | Project identity, 3–5 critical rules as bullets, pointers | <500 tokens |
| `alpha` | Identity, Engagement Protocol, Spec-First Invariants, pointers | <1K tokens |
| `beta` | All Alpha sections + TDD Discipline (when applicable), Maturity & Autonomy Ceiling, Currently Active Spec | <2K tokens |
| `ga` | All Beta sections + Team Conventions, Environment Promotion Ladder | <2.5K tokens |

TDD Discipline is omitted when `architecture.languages` contains only `Markdown` / `JSON` / `YAML` / `TOML` — the project is documentation-only, strict TDD does not apply.

## Modes

### `--write` (default)

1. Read state (config + PRD + handoff + specs).
2. Render the managed body at the project's maturity level.
3. Build the full file: frontmatter (preserved) + user-head (preserved) + ADD marker block + user-tail (preserved).
4. Write `AGENTS.md`.
5. Clear `.add/agents-md.stale` if present.

### `--check`

1. Read state.
2. Re-render what the file *should* be.
3. Diff against the on-disk `AGENTS.md`.
4. In sync → exit 0, print "AGENTS.md in sync."
5. Drift → exit 1, print a unified diff.

Designed for CI: `python3 scripts/generate-agents-md.py --check` can gate builds.

### `--merge`

Used when the project already has a hand-curated `AGENTS.md` without ADD markers.

1. Read the existing file.
2. Preserve frontmatter (if any).
3. Wrap the existing body in `<!-- USER:AUTHORED:START -->` / `<!-- USER:AUTHORED:END -->`.
4. Prepend the ADD-managed marker block at the top (after frontmatter).
5. Write the merged file.

Future `--write` regenerations only touch content between the ADD markers. User-authored content is preserved forever.

### `--import`

Alias for `--merge` with explicit "one-time migration" intent. Identical behavior; separate flag for documentation and audit clarity.

### `--dry-run`

Combines with any mode. Prints the output to stdout without touching disk.

## Staleness Marker

A PostToolUse hook (see `runtimes/claude/hooks/post-write.sh`) writes `.add/agents-md.stale` when any of these source files changes and `AGENTS.md` exists:

- `.add/config.json`
- `core/rules/*.md` (ADD-managed projects)
- `core/skills/*/SKILL.md` (ADD-managed projects)

Marker contents:

```json
{
  "timestamp": "2026-04-22T14:32:01Z",
  "changed": ["core/rules/tdd-enforcement.md"]
}
```

The hook does **not** rewrite `AGENTS.md`. The next `/add:agents-md` invocation announces the stale state, lists the changed sources, then regenerates when the human runs `--write`.

## Integration With Other Skills

- **`/add:init`** — calls `/add:agents-md` at the end of the init flow to write the initial `AGENTS.md`.
- **`/add:spec`** — after a new spec becomes the "spec under work", prompts: "Update AGENTS.md active-spec pointer? (Y/n)". On yes, runs `/add:agents-md --write`.
- **`/add:verify`** — opt-in Gate 4.5: if `agentsMd.gateOnVerify: true` is set in `.add/config.json`, `/add:verify` runs `--check` and fails the gate on drift. Off by default.
- **`/add:promote`** — maturity bumps recommend a regen (since the verbosity level changes) but do not auto-rewrite.

## Configuration

```json
{
  "agentsMd": {
    "gateOnVerify": false,
    "autoInitOnPromote": false
  }
}
```

Both keys are optional. If absent, defaults apply (gate off, no auto-init).

## Edge Cases

| Case | Behavior |
|------|----------|
| No `AGENTS.md` exists | `--write` creates it fresh; no merge prompt needed |
| File with marker block | `--write` regenerates only the ADD section |
| File without marker block | `--write` aborts with exit 2 and a directive to use `--merge` |
| Frontmatter present | Preserved verbatim; ADD block is placed after it |
| No PRD | `project.description` from config is used as project identity |
| Maturity `poc` + no rules | Minimal identity-only output; 5 critical rules baked into the skill |
| Markdown/JSON-only project | TDD Discipline section omitted |
| Multiple specs | Most recently mutated wins; others not listed in v0.9.0 |
| Marker partially deleted | Treated as missing; `--merge` required to recover |
| User edits inside ADD block | Overwritten on next `--write`; `--check` warns about this |
| Hook fires mid-task | `.add/agents-md.stale` write is atomic; no race |
| `.add/agents-md.stale` exists but file is in sync | Regen is idempotent; marker cleared |
| Nested per-subdirectory AGENTS.md | Out of scope for v0.9.0; single root file only |

## Output Format

After a successful `--write`:

```
Wrote AGENTS.md

Maturity: alpha
Sections rendered: Identity, Engagement Protocol, Spec-First Invariants, Pointers
Marker block: ADD:MANAGED (version=0.9.0, generated=2026-04-22T14:32:01Z)
Staleness marker: cleared
```

After `--check` drift:

```
AGENTS.md drift detected.
--- AGENTS.md (current)
+++ AGENTS.md (would-be)
@@ ... @@
 ...unified diff...

Run /add:agents-md --write to regenerate.
Exit code: 1
```

## Process Observation

After completing this skill, do BOTH:

### 1. Observation Line

Append one observation line to `.add/observations.md`:

```
{YYYY-MM-DD HH:MM} | agents-md | {mode} | {write|check|merge|import} | {notes}
```

If `.add/observations.md` does not exist, create it with a `# Process Observations` header first.

### 2. Learning Checkpoint

Write a structured JSON learning entry per the checkpoint trigger in `rules/learning.md` if the session surfaced anything that should persist (e.g., AGENTS.md marker convention, rules summary gaps, first-time merge workflow friction). Classify scope, write to the appropriate JSON file, and regenerate the markdown view.

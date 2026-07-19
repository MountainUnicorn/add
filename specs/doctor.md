# Spec: `/add:doctor` — provable install health check (#25)

**Status:** Approved (autonomous session 2026-07-19) · **Target:** v0.10.2 · **Issue:** #25

## Problem

An ADD install can be silently dead (#24: v0.9.4 agents/hooks ignored by Codex
≥0.14x with no error). Nothing distinguishes "seems installed" from "provably
healthy" without a human poking at files.

## Solution

New skill `core/skills/doctor/` → `/add:doctor` (Claude) / `/add-doctor`
(Codex). The skill runs a check battery via a shared shell library
`core/lib/doctor-checks.sh` (so checks are testable and runtime-neutral), then
renders a human table or a machine line.

## Checks

| ID | Check | Runtime | Severity |
|---|---|---|---|
| D-VER | plugin / project / core versions agree (reuse /add:version logic) | both | warn (behind) / error (ahead) |
| D-CFG | `~/.codex/config.toml` has `collab = true` and `codex_hooks = true` | codex | error |
| D-HOOKS | `~/.codex/hooks.json` parses AND uses nested ≥0.14x schema (top-level `hooks` object; entries carry typed `command`); every referenced script exists and is executable | codex | error |
| D-AGENTS | every `~/.codex/agents/*.toml` owned by ADD uses `developer_instructions`, none use `prompt_skill`; referenced SKILL.md paths resolve | codex | error |
| D-PATHS | every path in installed `plugin.toml` skills/agents/hooks lists resolves | codex | error |
| D-STALE | stale artifacts: legacy flat hooks.json shape, `.claude/rules/*` copies matching plugin rule names (Claude), leftover unprefixed/removed agent TOMLs | both | warn |
| D-MANIFEST | if `~/.codex/add/install-manifest.json` exists (#27): every listed file exists; checksum mismatches reported as "user-modified" (info) | codex | error (missing file) |
| D-CACHE | Claude: marketplace cache plugin version vs `.add/config.json` version drift | claude | warn |

Checks that don't apply to the current runtime are skipped silently.

## Output

Human mode: table of check → ✓/⚠/✗ + one-line remedy per failure.
`--check` mode: single line `add:doctor status={healthy|warnings|unhealthy} errors=N warnings=N` (exit code 0/0/1 semantics documented for CI).

## Acceptance criteria

| ID | Criterion | Priority |
|---|---|---|
| AC-1 | `core/lib/doctor-checks.sh` implements D-CFG, D-HOOKS, D-AGENTS, D-PATHS, D-MANIFEST as pure functions over a `$CODEX_HOME`-style root arg (testable against fixtures, no network). | Must |
| AC-2 | Fixture test `tests/hooks/test-doctor-checks.sh`: healthy fixture passes; legacy flat hooks.json fails D-HOOKS; `prompt_skill` TOML fails D-AGENTS; missing manifest-listed file fails D-MANIFEST; checksum-mismatch reports info not error. **Written RED-first.** | Must |
| AC-3 | Skill markdown drives the library + renders both output modes; follows skill-epilogue/namespace conventions; compiles to both runtimes cleanly. | Must |
| AC-4 | Skill count references (CLAUDE.md, README, AGENTS.md emission "27 skills") updated by integrator — agent must NOT edit them. | Must (integrator) |
| AC-5 | D-STALE and D-CACHE are best-effort (never hard-fail the doctor run itself). | Should |

## Out of scope

Auto-repair (doctor reports; `/add:init --reconfigure` / installer re-run remediate). Claude-side hook health (harness-managed).

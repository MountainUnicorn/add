# Spec: Prefix Codex sub-agent names `add-*` (#28)

**Status:** Approved (autonomous session 2026-07-19) · **Target:** v0.11.0 · **Issue:** #28

## Problem

ADD installs sub-agents into the global `~/.codex/agents/` namespace as
`explorer`, `implementer`, `reviewer`, `test-writer`, `verify`. Codex custom
agent names can shadow built-ins and collide with user agents (`verify`
especially). Bonus defect: `explorer.toml`'s `developer_instructions` points
at `add-docs/SKILL.md` as its role definition.

## Solution

Rename at the adapter source (`runtimes/codex/agents/*.toml`): files and
`name` fields become `add-explorer`, `add-implementer`, `add-reviewer`,
`add-test-writer`, `add-verify`. Claude runtime is untouched (roles there are
Task-tool concepts, not named registrations).

## Changes

1. `runtimes/codex/agents/`: rename 5 files, update `name = "add-*"`, keep
   descriptions. Fix explorer's `developer_instructions`: no dedicated explorer
   skill exists, so instruct it to operate as a generic read-only discovery
   agent per its TOML description + honor sandbox_mode (drop the misleading
   add-docs/SKILL.md reference).
2. `scripts/compile.py`: AGENTS.md "Sub-agents" emission lists `add-*` names;
   plugin.toml agents list follows renamed files automatically.
3. `scripts/install-codex.sh`: on install, remove legacy unprefixed TOMLs
   (`explorer|implementer|reviewer|test-writer|verify.toml`) from
   `~/.codex/agents/` ONLY if ADD-owned — listed in a prior install-manifest
   (#27) or containing an ADD marker comment; otherwise warn and leave.
4. Smoke (`tests/smoke/codex/run-smoke.sh`): agent-TOML asserts expect the
   `add-` prefixed set (5 exact names); assert no ADD-owned legacy names remain.
5. Any skill/rule text in `core/` or `runtimes/codex/` that names a Codex
   sub-agent registration updates to the prefixed name (audit via grep; Claude
   role vocabulary unchanged).
6. `docs/capability-matrix.md` sub-agents row names the prefixed set.
7. Migration note: CHANGELOG (integrator) + migrations.json hop at the v0.11.0
   release records "re-run installer to migrate agent names" (release-time
   task, not this change).

## Acceptance criteria

| ID | Criterion | Priority |
|---|---|---|
| AC-1 | Compile emits exactly `add-explorer|add-implementer|add-reviewer|add-test-writer|add-verify` TOMLs; `name` fields match filenames; all use `developer_instructions`. | Must |
| AC-2 | Installer removes ADD-owned legacy TOMLs, preserves user-owned files of the same names (warn). | Must |
| AC-3 | Smoke asserts the exact prefixed set and absence of ADD-owned legacy names; green in CI. | Must |
| AC-4 | explorer role instructions no longer reference add-docs/SKILL.md. | Must |
| AC-5 | Zero remaining unprefixed Codex-registration references in emitted output (`grep` audit clean). | Must |

## Out of scope

Renaming Claude-side role vocabulary; per-skill dispatch policy changes.

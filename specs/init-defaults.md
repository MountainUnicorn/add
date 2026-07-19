# Spec: `/add:init --defaults` — true non-interactive init (#23)

**Status:** Approved (autonomous session 2026-07-19) · **Target:** v0.10.2 · **Issue:** #23

## Problem

`/add:init --quick` still conducts a 5-question interview. Headless one-shot
sessions (`claude -p`, `codex exec`, CI smokes) exit without writing
`.add/config.json`. Both install smokes currently work around this by
smuggling answers into the prompt — fragile and undocumented for users.

## Solution

Add a `--defaults` flag: zero questions, every value derived or defaulted.
`--quick` keeps its current 5-question behavior (interactive fast path).
`--defaults` implies greenfield-or-adoption auto-detection without confirmation.

## Defaults derivation

| Field | Value |
|---|---|
| project name | basename of CWD |
| language | auto-detect from manifest files (package.json → typescript/javascript, pyproject.toml/setup.py → python, go.mod → go, Cargo.toml → rust, *.gemspec/Gemfile → ruby; fallback `unknown`) |
| environments | `["local"]`, autoPromote off |
| maturity | `poc` (greenfield) or detected level (adoption path, no confirmation question) |
| operating mode | `autonomous` |
| scope paragraph | omitted — PRD stub notes "run /add:spec to define scope" |
| cross-project registry | still runs (Phase 4), no prompts |

## Acceptance criteria

| ID | Criterion | Priority |
|---|---|---|
| AC-1 | `--defaults` completes with **zero** AskUserQuestion/interview turns and writes a valid `.add/config.json` (version, maturity, language, environments keys). | Must |
| AC-2 | Headless-safe: works via `claude -p "/add:init --defaults"` and `codex exec "/add-init --defaults"`. | Must |
| AC-3 | If `.add/config.json` already exists, `--defaults` is a no-op with a notice (never overwrites; `--reconfigure` remains the refresh path and still interviews). | Must |
| AC-4 | Both install-smoke prompts switch from inline-answer workaround to `--defaults`; smokes stay green. | Must |
| AC-5 | Skill docs table lists the new flag with question-count 0; `--quick` unchanged. | Must |
| AC-6 | `--defaults` composes with `--sync-registry` semantics unchanged. | Should |

## Out of scope

Flag support in other skills; changing `--quick`.

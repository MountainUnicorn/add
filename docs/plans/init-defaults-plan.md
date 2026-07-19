# Plan: init --defaults (#23) — spec: specs/init-defaults.md

Wave 1 (parallel with doctor + install-manifest; disjoint files).

1. `core/skills/init/SKILL.md`: add `--defaults` to argument-hint + mode table
   (0 questions); new "Defaults Mode" section with the derivation table from
   the spec; existing-config guard (AC-3).
2. Smoke switch-over (AC-4): `.github/workflows/install-smoke-claude.yml`
   prompt + `tests/smoke/codex/run-smoke.sh` codex exec prompt → `--defaults`,
   dropping inline answers.
3. Verification: compile + frontmatter + `--check`; CI smokes are the
   end-to-end proof (headless legs now exercise the flag for real).

Owns: core/skills/init/, the two smoke prompt lines. Does NOT touch:
CHANGELOG, generated dirs, other skills.

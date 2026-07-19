# Plan: /add:doctor (#25) — spec: specs/doctor.md

Wave 1 (parallel with init-defaults + install-manifest; disjoint files).

1. RED: `tests/hooks/test-doctor-checks.sh` with fixtures (healthy home,
   legacy flat hooks.json, prompt_skill TOML, manifest with missing file,
   checksum mismatch). Run → fails (library absent).
2. GREEN: `core/lib/doctor-checks.sh` — pure functions over a root arg:
   check_config_features, check_hooks_schema, check_agent_tomls,
   check_plugin_paths, check_manifest. POSIX-ish bash, python3 for JSON.
3. Skill: `core/skills/doctor/SKILL.md` — frontmatter per house style,
   drives the library, renders table + `--check` line per spec.
4. Verification: fixture suite green; compile emits add-doctor on Codex side.

Owns: core/skills/doctor/ (new), core/lib/doctor-checks.sh (new),
tests/hooks/test-doctor-checks.sh (new). Does NOT touch: skill-count strings
(CLAUDE.md/README — integrator), CHANGELOG, generated dirs.

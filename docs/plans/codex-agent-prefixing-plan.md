# Plan: agent prefixing (#28) — spec: specs/codex-agent-prefixing.md

Wave 2 — starts only after #27 lands (installer + smoke overlap; cleanup uses
the install manifest as the ADD-ownership signal).

1. Rename `runtimes/codex/agents/*.toml` → `add-*` (files + name fields);
   fix explorer developer_instructions (drop add-docs/SKILL.md ref).
2. `scripts/compile.py` AGENTS.md sub-agents emission → prefixed names.
3. `scripts/install-codex.sh`: legacy-name cleanup (manifest/marker-gated).
4. `tests/smoke/codex/run-smoke.sh`: assert exact prefixed set + legacy absence.
5. Grep audit for unprefixed registration references; capability matrix row.
6. Verification: compile + fixture suites + Docker smoke path in CI.

Migration hop entry deferred to the v0.11.0 release checklist (records
"re-run installer").

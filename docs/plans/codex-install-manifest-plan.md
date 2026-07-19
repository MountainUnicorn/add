# Plan: install manifest (#27) — spec: specs/codex-install-manifest.md

Wave 1 (parallel with init-defaults + doctor; disjoint files).

1. RED: `tests/codex-install/test-install-manifest.sh` — temp CODEX_HOME:
   completeness diff, idempotent re-install, user-edit backup, generated
   uninstall script exactness. Run → fails (no manifest emitted).
2. GREEN: `scripts/install-codex.sh` — record every written file (relpath +
   sha256, portable shasum/sha256sum), prior-manifest comparison for upgrade
   protection, emit install-manifest.json + uninstall-add.sh, replace the
   drifted rm -rf block. Fail-open on manifest errors (AC-5).
3. Verification: new suite + existing test-install-paths.sh + smoke locally.

Owns: scripts/install-codex.sh, tests/codex-install/test-install-manifest.sh
(new). Does NOT touch: run-smoke.sh (init-defaults owns its prompt line;
manifest asserts live in the new suite), CHANGELOG, generated dirs.

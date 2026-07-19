# Spec: Codex install manifest — idempotent install/uninstall/upgrade (#27)

**Status:** Approved (autonomous session 2026-07-19) · **Target:** v0.10.2 · **Issue:** #27

## Problem

`install-codex.sh` scatters files across `~/.codex/` and prints a hand-listed
`rm -rf` uninstall that has already drifted (omits `agents/verify.toml`).
Upgrades clobber user-edited files silently. Nothing records what ADD owns.

## Solution

The installer writes `~/.codex/add/install-manifest.json` on every run:

```json
{
  "schema": 1,
  "version": "<installed ADD version>",
  "installed_at": "<UTC ISO-8601>",
  "files": [ {"path": "skills/add-verify/SKILL.md", "sha256": "..."}, ... ],
  "backups": [ {"path": "hooks.json.bak-<ts>", "reason": "hooks.json replaced (schema upgrade)"} ]
}
```

Paths are relative to `$CODEX_HOME`. `files` covers every file the installer
writes (skills, agents, hooks, hooks.json, add/ tree — including the manifest's
siblings, excluding the manifest itself).

## Behaviors

1. **Upgrade protection:** before overwriting a file listed in a PRIOR
   manifest, compare its current sha256 to the prior manifest's. Mismatch =
   user-edited → copy to `<path>.bak-<version>` first and print one warning
   line per file. Files not in the prior manifest are treated as user-owned
   only if they exist AND differ from the incoming payload (backup + warn).
2. **Uninstall from manifest:** the printed uninstall guidance becomes
   `bash ~/.codex/add/uninstall-add.sh` — a small generated script that
   removes exactly the manifested files (+ empty ADD-owned dirs) and lists
   backups for optional restore. No more hand-listed rm -rf.
3. **Idempotence:** re-running the installer over an unmodified install
   produces an identical file set and a fresh manifest; zero warnings.

## Acceptance criteria

| ID | Criterion | Priority |
|---|---|---|
| AC-1 | Manifest written with schema above; every installed file listed with correct sha256; relative paths. | Must |
| AC-2 | `tests/codex-install/test-install-manifest.sh` (RED-first): fresh install → manifest complete (find-diff between manifest and actual tree = empty, both directions, modulo manifest itself + backups); re-install idempotent (no warnings, no .bak); user-edited file → backed up + warned; generated uninstall script removes exactly manifested files and leaves user files. | Must |
| AC-3 | `shasum -a 256` / `sha256sum` portability (macOS + Linux CI container). | Must |
| AC-4 | Installer output replaces the drifted rm -rf block with the uninstall-script pointer. | Must |
| AC-5 | Manifest generation never fails the install (fail-open with warning) — installs on exotic shells still complete. | Should |

## Out of scope

Doctor consuming the manifest (#25 handles, reads if present). Claude-runtime
manifest (marketplace manages that lifecycle). Agent-name migration (#28 —
but the manifest is the mechanism #28's cleanup will use).

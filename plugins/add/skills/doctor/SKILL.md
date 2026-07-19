---
description: "[ADD v0.10.1] Provable install health check — verify hooks, agents, config, and paths are actually live"
argument-hint: "[--check]"
allowed-tools: [Read, Glob, Grep, Bash]
references: ["rules/telemetry.md"]
disable-model-invocation: true
---

# ADD Doctor Command v0.10.1

Distinguish "seems installed" from "provably healthy". An ADD install can be silently dead — e.g. Codex ≥0.14x ignoring agents and hooks with no error (issue #24). This command runs a check battery and reports per-check status with a one-line remedy for every failure. Doctor only reports — it never repairs (remediation: `/add:init --reconfigure` or re-running the installer).

## Execution

### 1. Detect runtime

Same model as /add:version — probe `${CLAUDE_PLUGIN_ROOT}/`, first hit wins:

1. `.claude-plugin/plugin.json` exists → **Claude runtime**
2. `plugin.toml` or `VERSION` exists (and `${CLAUDE_PLUGIN_ROOT}` resolves under `~/.codex`) → **Codex runtime**

Checks that don't apply to the detected runtime are **skipped silently** — do not list them in the output at all.

### 2. Run the check battery

| ID | Check | Runtime | Severity |
|---|---|---|---|
| D-VER | plugin / project / core versions agree | both | warn (behind) / error (ahead) |
| D-CFG | config.toml feature gates (`collab`, `codex_hooks`) | codex | error |
| D-HOOKS | hooks.json nested ≥0.14x schema; scripts exist + executable | codex | error |
| D-AGENTS | agent TOMLs use `developer_instructions`, never `prompt_skill` | codex | error |
| D-PATHS | every installed plugin.toml path resolves | codex | error |
| D-STALE | stale artifacts from prior versions | both | warn |
| D-MANIFEST | install-manifest.json files all present (missing = error; checksum drift = info "user-modified") | codex | error |
| D-CACHE | marketplace cache version vs project version drift | claude | warn |

**Library-backed checks (D-CFG, D-HOOKS, D-AGENTS, D-PATHS, D-MANIFEST — Codex runtime only).** Run the shared library against the Codex home directory:

```bash
DOCTOR_LIB="${CLAUDE_PLUGIN_ROOT}/lib/doctor-checks.sh"
CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"
for fn in check_config_features check_hooks_schema check_agent_tomls check_plugin_paths check_manifest; do
  bash -c "source '$DOCTOR_LIB' && $fn '$CODEX_ROOT'"
done
```

Each function prints `CHECK <id> <pass|warn|fail|info|skip> <detail>` and exits 0 (pass/info/skip), 1 (warn), or 2 (fail). Parse these lines directly into the results table — do not re-derive the verdicts yourself.

**D-VER (both runtimes).** Reuse the /add:version comparison logic: read the plugin version (`.claude-plugin/plugin.json` → `plugin.toml` → `VERSION`, first hit wins), the project version from `.add/config.json`, and `core/VERSION` if accessible (development installs). project == plugin → pass. project < plugin → **warn** ("migration will run on next skill invocation"). project > plugin → **fail** ("plugin is older than project config — update the plugin"). No `.add/config.json` → info ("not an ADD project — run /add:init").

**D-STALE (both runtimes, best-effort inline).** Never let this check error out the doctor run — on any unexpected condition, report `⚠` with what was seen, or skip. Look for:

- Codex: a legacy flat hooks.json shape staged anywhere (including a `hooks.json` under the `add/` staging tree left from a pre-0.14x install), and leftover unprefixed or removed agent TOMLs in `~/.codex/agents/` (ADD-marked TOMLs whose name is not in the installed plugin.toml agents list).
- Claude: `.claude/rules/*` files in the project whose names duplicate plugin rule names (stale copies shadowing the plugin).

**D-CACHE (Claude only, best-effort inline).** Compare `~/.claude/plugins/cache/add-marketplace/add/.claude-plugin/plugin.json` version against `.add/config.json` version. Drift → warn ("run /add:version for details; update the plugin or re-run /add:init"). Cache path missing → skip silently. Never hard-fail on this check.

### 3. Render output

#### Human mode (default)

```
ADD Doctor — {runtime} runtime

  Check       Status   Detail
  D-VER       ✓        plugin v{X} == project v{X}
  D-CFG       ✓        [features] collab and codex_hooks enabled
  D-HOOKS     ✗        legacy flat pre-0.14x schema
                       → Remedy: rerun the ADD installer to upgrade hooks.json
  D-AGENTS    ✓        5 ADD agent TOML(s) use developer_instructions
  D-PATHS     ✓        all 34 plugin.toml paths resolve
  D-STALE     ⚠        leftover agent TOML: old-reviewer.toml
                       → Remedy: remove it or rerun the installer
  D-MANIFEST  ✓        all files present (1 user-modified: skills/add-verify/SKILL.md)

Result: unhealthy — 1 error, 1 warning
```

- `✓` pass, `⚠` warn, `✗` fail. `info` findings (e.g. user-modified files) render inline on the owning check's detail line, still `✓`.
- Every `⚠`/`✗` row MUST carry an indented `→ Remedy:` line (one line, actionable).
- Skipped checks are omitted from the table entirely.
- Final line: `Result: healthy` (no warnings or errors), `Result: warnings — N warning(s)`, or `Result: unhealthy — N error(s), M warning(s)`.

#### --check flag (machine mode)

When invoked with `--check`, output exactly one line and nothing else:

```
add:doctor status={healthy|warnings|unhealthy} errors=N warnings=N
```

Exit-code semantics for CI: `healthy` and `warnings` → 0, `unhealthy` → 1. This mirrors the /add:version `--check` convention.

## Integration with Other Skills

- /add:version answers "what version am I on"; /add:doctor answers "is what's installed actually alive".
- Suggest /add:doctor after any plugin upgrade or Codex CLI major bump.
- Remediation paths: `/add:init --reconfigure` (project config), the Codex installer re-run (install tree), `claude plugin update add@add-marketplace` (Claude plugin).

End-of-skill epilogue: follow `${CLAUDE_PLUGIN_ROOT}/references/skill-epilogue.md` (observation + learning checkpoint + progress tracking). Learning checkpoint trigger: "After Verification".

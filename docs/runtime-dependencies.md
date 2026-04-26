# Runtime Dependencies

**Last updated:** 2026-04-26 (v0.9.3)
**Spec:** [`specs/jq-dependency-declaration.md`](../specs/jq-dependency-declaration.md)

ADD is **pure markdown and JSON on the agent / LLM side** — there is no compiled
code, no language runtime, and no build step required for the agent to load
skills, rules, knowledge, or templates.

The plugin's hook scripts, however, do shell out to one external tool:

> **`jq`** — required for hook scripts that parse JSON payloads.

Most macOS and Linux developer machines already have `jq` installed via package
managers, IDE bundles, or a previous tool. If your system does not, the hooks
shipped with ADD will either silently no-op (where the hook is guarded) or
emit a `command not found` error into the Claude Code transcript on the first
file write (where the hook is not guarded). Both of these are documented as
"known sharp edges" rather than fatal — the agent itself continues to work.

This document explains what the hooks need `jq` for, how to install it on
every supported platform, and exactly what degrades when it is missing.

## Why jq is needed

Claude Code and the Codex CLI deliver hook payloads to user-supplied scripts
as JSON on stdin (or as JSON files passed via positional argument). Without
`jq`, parsing those payloads in pure POSIX shell is brittle and ships its own
bugs. Vendoring a mini-JSON parser binary would break the "pure markdown +
JSON" invariant that makes ADD trivially auditable. So the hooks invoke
system `jq` directly. See the strategy discussion in
[`specs/jq-dependency-declaration.md`](../specs/jq-dependency-declaration.md).

## Install commands

| Platform | Command |
|----------|---------|
| macOS (Homebrew) | `brew install jq` |
| macOS (MacPorts) | `sudo port install jq` |
| Debian / Ubuntu | `sudo apt-get update && sudo apt-get install -y jq` |
| Fedora / RHEL / CentOS | `sudo dnf install -y jq` |
| Arch / Manjaro | `sudo pacman -S jq` |
| Alpine | `sudo apk add jq` |
| openSUSE | `sudo zypper install jq` |
| Windows (Chocolatey) | `choco install jq` |
| Windows (scoop) | `scoop install jq` |
| Windows (WSL) | use the Linux command for your WSL distro |
| Nix / NixOS | `nix-env -iA nixpkgs.jq` |

`jq` is a small static binary (~600 KB) with no dependencies of its own. It
is also available as a precompiled binary from
[stedolan.github.io/jq](https://stedolan.github.io/jq/download/) for any
platform without a package manager.

## Verification

After installing, confirm `jq` is on `PATH`:

```bash
command -v jq && jq --version
```

You should see a path (e.g. `/opt/homebrew/bin/jq`) followed by a version
string (`jq-1.7.1` or similar). Any `jq --version` ≥ 1.5 is supported.

## What degrades when jq is absent

The following table is the canonical reference for hook behavior on a system
without `jq`. Reproduced from
[`specs/jq-dependency-declaration.md` §1](../specs/jq-dependency-declaration.md).

| # | Path | Role | What jq does | Behavior when jq absent |
|---|------|------|--------------|--------------------------|
| 1 | `runtimes/claude/hooks/post-write.sh:14` | PostToolUse Write/Edit dispatcher | Parse `tool_input.file_path` from hook payload | **Hard fail** — `set -euo pipefail` causes the script to exit non-zero; the hook then emits a `command not found` error into the Claude transcript on every Write/Edit. |
| 2 | `runtimes/claude/hooks/post-write.sh:30` | Read `learnings.active_cap` from `.add/config.json` | Suppressed via `2>/dev/null \|\| true`; falls through to default `MAX=15` | Soft fail — if the script reaches this line. (It does not, because line 14 already failed.) |
| 3 | `runtimes/claude/hooks/filter-learnings.sh:17` | Active-learnings view generator | Guarded: `command -v jq >/dev/null 2>&1 \|\| exit 0` | **Soft fail by design** — hook exits 0; `learnings-active.md` is not regenerated; the agent reads canonical `learnings.json` instead (documented v0.8 fallback chain). |
| 4 | `runtimes/claude/hooks/posttooluse-scan.sh:23` | Secrets / prompt-injection PostToolUse scanner | Guarded: `command -v jq >/dev/null 2>&1 \|\| exit 0` | **Soft fail** — scanner no-ops; agent loses defense-in-depth scan. |
| 5 | `core/lib/impact-hint.sh:133` | Test-deletion guardrail learnings lookup | Guarded inline: `command -v jq >/dev/null 2>&1` block is skipped when missing | **Soft fail** — generic impact message instead of specific learning citation. |
| 6 | `runtimes/claude/hooks/hooks.json:54` | Inline pre-push CHANGELOG nudge (PreToolUse Bash) | Parses `tool_input.command` from payload | **Hard fail** — inline `CMD=$(jq ...)` with no guard; hook errors when user invokes `git push` and `jq` is missing. |

Summary: **2 sites hard-fail** (post-write dispatcher, pre-push nudge);
**3 sites soft-fail with reduced functionality** (filter-learnings,
posttooluse-scan, impact-hint); 1 fallthrough soft-fail is unreachable on
the hard-fail path.

The fix for the two hard-fail sites is "install jq," not "patch the hook" —
the spec ([Strategy A](../specs/jq-dependency-declaration.md)) deliberately
keeps hook code unchanged. If your project policy forbids installing `jq`,
disable the affected hook in your local Claude Code settings; the agent's
core skill, rule, and knowledge surface continues to work without hooks.

## Codex CLI runtime

The Codex CLI runtime adapter (`runtimes/codex/hooks/*.sh`) does **not**
currently invoke `jq`. Codex consumers therefore have no `jq` requirement
today. Parity with the Claude runtime is the long-run intent; any future
Codex hook that introduces `jq` should be added to the table above and
this document updated alongside.

Verify with:

```bash
grep -l "jq" runtimes/codex/hooks/*.sh
# expect: empty output
```

## See also

- [`runtimes/claude/CLAUDE.md`](../runtimes/claude/CLAUDE.md) — Claude runtime adapter overview.
- [`runtimes/claude/hooks/`](../runtimes/claude/hooks/) — hook source.
- [`specs/jq-dependency-declaration.md`](../specs/jq-dependency-declaration.md) — F-017 spec; strategy choice; alternative B (universal soft-fail wrappers) discussion.

# Security Policy

ADD is a methodology plugin distributed as pure markdown and JSON. It is consumed by agent runtimes (Claude Code, Codex) that grant it substantial autonomy — filesystem access, git operations, shell execution inside your projects. This file describes the trust model, the attack surface, and how to report problems.

## What You're Granting When You Install ADD

When you install ADD into a project-aware agent runtime, you are granting:

- **Filesystem access** to every path the agent can reach (typically the project root and below)
- **Git operations** including commit, push, branch creation, and (during away mode) tag creation
- **Shell execution** inside the project working directory (lint, test, build, deploy commands)
- **Instruction injection** — rules in `rules/*.md` are auto-loaded as behavioral directives to the agent

ADD does not call external APIs, does not transmit telemetry, and does not contain any compiled code. But a malicious change to an ADD rule or skill file can rewrite agent behavior as effectively as any exploit, because the runtime reads those files as instructions.

## Threat Model

| Threat | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Rule hijack via PR** — a malicious contribution removes a `NEVER` or `Boundaries:` section | Medium | Critical — previously-gated behavior becomes permitted | CI boundary-diff check (`.github/workflows/rule-boundary-check.yml`); CODEOWNER approval required on rule changes |
| **Skill scope creep via `allowed-tools`** — a PR expands a skill's tool permissions (e.g., adds `Bash` to a read-only skill) | Medium | High — unexpected capabilities granted to agent | JSON Schema validation of SKILL.md frontmatter; CI diff flag on `allowed-tools` changes |
| **Hook modification** — a PR alters `hooks/hooks.json` to run malicious commands on every file edit | Medium | High — arbitrary shell execution per tool call | Hooks changes require explicit review; schema validation; restricted command patterns |
| **Learning checkpoint PII leak** — agent writes sensitive data (API keys, customer names) to `.add/learnings.json` and you commit it | Medium | Medium — data in git history is hard to fully remove | PII heuristic warning before learning writes (v0.7.1); `.gitignore` patterns for secrets |
| **Production deploy jailbreak** — agent promotes past the maturity gate | Low | Critical — unapproved production deploy | Maturity-lifecycle rule + `autoPromote: false` + `/add:deploy` confirm-phrase gate (v0.7.1) |
| **Supply-chain: fake marketplace** — attacker publishes a typosquat marketplace | Low | High — users install a trojan | Install only from `MountainUnicorn/add`; verify marketplace.json contents; GPG-signed release tags (v0.7.0+) |

## What ADD Does NOT Do

For clarity:

- **No network calls.** ADD does not contact any server. Image generation (optional) calls whatever API you configure in `.add/config.json` — that's your configuration, not ADD.
- **No telemetry.** ADD does not measure usage, phone home, or log to any external service.
- **No compiled binaries.** Every file is plain markdown, JSON, YAML, or a short shell/Python script in `scripts/`.
- **No dependency tree.** ADD requires no installed packages. The Codex install script uses only POSIX tools.

## How to Spot a Malicious PR

If you are reviewing a PR against ADD (or forking the repo), look for:

1. **Changes to `rules/*.md`** that delete or weaken `NEVER`, `Boundaries:`, or `Autonomous:` sections. These are the guardrails.
2. **Changes to `allowed-tools` arrays** in any `SKILL.md` that add `Bash`, `Write`, or `Edit` to a skill that previously didn't need them.
3. **Changes to `hooks/hooks.json`** — any change here is high-leverage because hooks run on every tool event.
4. **New rules with `autoload: true`** — a newly-autoloaded rule is equivalent to adding code to the system prompt.
5. **`${CLAUDE_PLUGIN_ROOT}` path manipulation** — shell commands that traverse out of the plugin directory.
6. **Base64 blobs or obfuscated strings** — ADD is plain text; encoded content is a red flag.

ADD's CI runs schema validation and boundary-diff checks on every PR. A PR that fails either of these does not merge. But nothing substitutes for human review on rule and hook changes.

## Signed Releases

Starting with v0.7.0, release tags are GPG-signed.

- Maintainer: `MountainUnicorn` / Anthony Brooke
- Fingerprint: _published on first signed release; verify with `git verify-tag v0.7.0`_

To verify an installed version matches a signed release:

```bash
cd ~/.claude/plugins/cache/add-marketplace/add/
git tag --verify v0.7.0
```

## Reporting a Vulnerability

If you discover a security issue in ADD, please **do not** open a public GitHub issue. Instead:

1. Email **security@getadd.dev** (preferred) or open a private security advisory at https://github.com/MountainUnicorn/add/security/advisories/new
2. Include: a clear description, reproduction steps, affected version(s), and (if you have it) a suggested fix
3. We aim to respond within **48 hours** and to ship a fix or mitigation within **7 days** for critical issues

You will be credited in the release notes and `CONTRIBUTORS.md` unless you request otherwise.

## Supported Versions

Security fixes are backported to the most recent minor version. Older versions are community-maintained.

| Version | Supported |
|---|---|
| 0.7.x | ✅ Active |
| 0.6.x | ⚠️ Critical fixes only through 2026-10 |
| < 0.6.0 | ❌ Please upgrade |

## Out of Scope

The following are **not** ADD security issues (though they may be bugs worth reporting):

- Behavior caused by your own `.add/config.json` or custom rules
- Issues in the Claude Code or Codex runtimes themselves — report those to Anthropic / OpenAI
- Prompt-injection attacks in data your agent is processing (e.g., a malicious PDF you asked ADD to read). This is the runtime's responsibility, not ADD's.

---

_Last updated: 2026-04-12 — v0.7.0 release._

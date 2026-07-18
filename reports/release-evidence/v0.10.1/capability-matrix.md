# Per-Runtime Capability Matrix

**Spec:** `specs/install-path-confirmation.md` AC-030 (milestone AC-027, GA criterion #3)
**Maintenance:** hand-maintained, verified against `runtimes/codex/adapter.yaml` truth
on every release; included in release notes from v0.10.0 onward. If this table and
`adapter.yaml` disagree, `adapter.yaml` wins — fix the table.

Legend — **Enforced**: the runtime mechanically applies it (hook/loader; the agent
cannot silently skip it). **Agent-followed**: shipped as instructions the agent is
expected to obey; no mechanical backstop. **Advisory**: documentation/patterns only.
**—**: not available on that runtime.

| Capability | Claude Code | Codex CLI | Notes |
|---|---|---|---|
| Skills (27, namespaced) | Enforced (plugin loader) | Enforced (native Skills, `~/.codex/skills/add-*`) | Codex names use `/add-<name>`; Claude `/add:<name>` |
| Install path | Marketplace (`claude plugin install add@add-marketplace`) | curl installer (`scripts/install-codex.sh`) | Both covered by CI install smoke as of v0.10.0 |
| Auto-loaded rules, maturity-scaled | Enforced (SessionStart `load-rules.sh` physically loads the maturity-appropriate set) | Agent-followed (static slim manifest in `AGENTS.md`; maturity-loader rule read at runtime) | Codex has no session hook doing physical selection |
| Stale-rule-copy detection | Enforced (per-session warning, v0.9.11) | — | Codex `AGENTS.md` merged at init can drift; check planned (`/add-version`), v1.1 candidate |
| Hooks (learnings filter, CHANGELOG, autofix) | Enforced (PreToolUse / SessionStart) | Agent-followed→Enforced only if user enables `[features] codex_hooks = true`; hook stderr not surfaced to the agent (F-012) | hooks.json emitted in the ≥0.14x schema since v0.10.1 (#24); merge is manual when one already exists |
| Prompt-injection scanning | Enforced detection, warn-only response (PostToolUse scanner emits ADD-SEC warnings + audit events at `.add/security/injection-events.jsonl`; never blocks by design) | Advisory (pattern catalog ships at `~/.codex/add/security/`; no scanner hook, no audit events) | Per adapter.yaml truth-pass (v0.9.8); Codex parity revisits v1.1 |
| Secrets scanning / redaction | Enforced in hook pipeline (`lib/scan-secrets.sh` via scanner + learnings filter) | Advisory (library + catalog ship; skills reference them, no hook auto-registration) | |
| Sub-agents (test-writer, implementer, reviewer, explorer) | Enforced (Task tool dispatch) | Agent-followed (TOML defs; requires `[features] collab = true`; `developer_instructions` load the role's skill) | TOMLs emitted in the ≥0.14x schema since v0.10.1 (#24 — `prompt_skill` era was silently ignored); verified accepted by CLI 0.144.5 |
| Learnings persistence + active view | Enforced (`filter-learnings.sh` hook auto-registered) | Shipped but NOT auto-registered | Codex user must wire the hook manually |
| Telemetry JSONL emission | Spec'd; emission verification tracked as D6 (see milestone) | — | Several PRD metrics depend on this |
| Migrations (`migrations.json` hop chain) | Enforced via `/add:version` | Agent-followed via `/add-version` | Chain continuity checked by release-evidence script (v0.10.0) |
| GPG-signed releases | n/a (repo-level) | n/a (repo-level) | All tags signed; see `docs/release-signing.md` |

**Pinned Codex CLI (CI target):** see `codex_cli_version` in `runtimes/codex/adapter.yaml`
(0.144.5 as of v0.10.0; minimum supported: 0.122.0).

**Summary for release notes:** on Claude Code, ADD's quality gates are mechanically
enforced by hooks; on Codex CLI they are agent-followed unless the user enables
Codex hook features, and prompt-injection defense is advisory-only. Anything
marked warn-only here is stated identically in `SECURITY.md`.

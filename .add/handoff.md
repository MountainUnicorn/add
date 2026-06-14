# Handoff — v1.0 GA wave execution (2026-06-14)

## Where things stand
Branch **`wave-exec-v096`** (off `main` @ 0896bc0). The **v0.9.6 batch (Waves 0–2) is complete and fully verified** — 9 commits, 35 files, all 15 fixture suites green, `compile --check` clean. Not pushed; no release cut (those are human/keychain-gated).

Executed under ADD's own SDLC: RED-first tests where applicable, an **independent verifier agent** + an **agent-to-agent retro** per wave, learnings captured to `.add/learnings.json` (L-035…L-046).

## Done

### Wave 0 — unblock `main` (P0)
- **C1**: rule count was 19, reality 20 → guardrails red. Made the count **compile-derived** (`{{RULE_COUNT}}` in `runtimes/claude/CLAUDE.md`, filled from the autoload-filtered set in `compile.py`). Strengthened `rule-parity` to read the compiled artifact + assert all prose surfaces (CLAUDE.md/README.md/CONTRIBUTING.md). Now 9/9.
- **C3**: bumped `checkout v4→v5`, `setup-python v5→v6`, `github-script v7→v8` across all 4 workflows (Node-20 deprecation).
- Verifier caught 3 missed surfaces + a semantic bug ({{RULE_COUNT}} counted all files, not autoload) — all fixed before commit.

### Wave 1 — release tooling (P0)
- **C2 / #18**: `release.sh` could exit 0 without publishing. Added array-based gh flags + a post-create `gh release view` assertion that fails loud with a recovery command. Behavioral regression test (mock git/gh/python3) — **mutation-verified** to go red when the fix is reverted.

### Wave 2 — v0.9.6 truth-pass
- **C5**: CONTRIBUTING "three checks"→four; documented community-PR strategy.
- **D1**: `model-roles.md` capability-tier table (Opus 4.8/Sonnet 4.6/Haiku 4.5; gpt-5.5/gpt-5.x-codex).
- **B3**: added missing Codex `verify` sub-agent (`verify.toml` + 2 compile.py enums + test). 5 agents now; codex suite 58/58.
- **D3 (P0/1)** — found a real **security bug**: the `unicode-tag-block` regex was a broken byte-class matching ~any multibyte UTF-8 (652/652 sampled events were benign false positives, 0 real attacks). Replaced with a precise `(?:\xF3\xA0[\x80\x81][\x80-\xBF]){3,}` — verifier independently confirmed it covers all 128 tag codepoints and rejects benign chars; AC-028 real attack still fires. Switched the JSONL audit writer to `jq -cn` (atomic single-line). Gitignored + untracked `.add/security/`. Documented the audit trail in SECURITY.md. Added a **mutation-verified** benign-multibyte regression fixture.

## Next: the boundary

### Wave 3 (v0.9.7 methodology) — NEEDS HUMAN DIRECTION before auto-execution
These are subjective positioning/voice decisions, not mechanical:
- **A1** swarm-protocol → layer over native Workflows (the strategic reframe — wording matters; affects ADD's market story).
- **A3** swarm-state machine-readable format contract (small, do first — A1 depends on it).
- **C4** GA launch plan / `/add:announce` (marketing strategy; partly the separate `getadd.dev` repo).
- **D4** lead README with the maturity ladder (positioning/voice).
- **A2** `core/workflows/` scaffolding (spec+infra only pre-GA; Claude-specific — needs a home that compile-drift tolerates).
- **D3 P2** skill self-scan + CI gate.

### Wave 4 (v0.10) — automatable later
A3 panel impl; **B4** F-012 spike (now consumes the fixed regex/writer from D3); D3 self-scan CI enforcement.

### Wave 5 (v0.11) — BLOCKED on a live spike
Unified **B1+B2** Codex re-baseline is gated on **Q-001**: a live spike against the current Codex CLI (the 0.122 pin is stale). Can't be done without running the real CLI.

### GA tag — externally/human gated (cannot be automated)
- Anthropic marketplace approval (filed 2026-02-14, status unknown — external).
- 60-day beta calendar gate (earliest honest tag ~2026-06-22).
- A real GPG-signed release cut (keychain/pinentry — interactive).
- ADD's own `beta→ga` self-promotion + release-evidence bundle (currently unowned per cohesion review).

## Acceptance test for Wave 1 (do this at the real v0.9.6 cut)
Judge success from the new `published and verified` line + a manual `gh release view` — **not** from exit 0 (the habit being retired). See L-042.

## Suggested follow-up rule (from Wave 1 retro, L-039)
"Verify the side effect, never trust the exit code" is now a twice-proven bug class (F-001 + #18). Worth encoding as a rule near `core/rules/quality-gates.md`.

#!/usr/bin/env bash
# ADD Codex hook — SessionStart
#
# Surfaces `.add/handoff.md` to the session if present. Idempotent no-op when
# the file doesn't exist, so this script is safe to wire globally in
# non-ADD-managed projects.
#
# AC-021 (SessionStart registration), AC-023 (no-op discipline).

set -euo pipefail

HANDOFF=".add/handoff.md"

if [ ! -f "$HANDOFF" ]; then
  exit 0
fi

# Codex surfaces stdout as session context. Prefix helps the agent recognize
# the payload as ADD-provided state, not user input.
echo "[ADD handoff] Resuming from prior session state:"
echo ""
cat "$HANDOFF"

#!/usr/bin/env bash
# ADD Codex hook — UserPromptSubmit
#
# Inspects the user prompt for "handoff", "back", or "away" intent and, when
# present, echoes a reminder that ADD ships dedicated skills for those flows.
# This compensates for Codex's PostToolUse firing only on Bash — intent
# detection that would normally hook Write/Edit in Claude Code happens at
# UserPromptSubmit in Codex. See AC-022.
#
# Idempotent, silent when `.add/` is absent.

set -euo pipefail

if [ ! -d .add ]; then
  exit 0
fi

# Codex passes the prompt either via stdin or $1 depending on hook spec version.
PROMPT=""
if [ -n "${1:-}" ]; then
  PROMPT="$1"
elif [ ! -t 0 ]; then
  PROMPT=$(cat || true)
fi

if [ -z "$PROMPT" ]; then
  exit 0
fi

lc=$(printf "%s" "$PROMPT" | tr '[:upper:]' '[:lower:]')

case "$lc" in
  *"i'm back"*|*"im back"*|*"i am back"*)
    echo "[ADD] Detected return. Consider running /add:back for a session briefing."
    ;;
  *"stepping away"*|*"going away"*|*"be back later"*)
    echo "[ADD] Detected departure. Consider running /add:away to plan autonomous work."
    ;;
  *"handoff"*)
    echo "[ADD] Handoff intent detected. See .add/handoff.md; the /add:back skill resumes prior context."
    ;;
esac

exit 0

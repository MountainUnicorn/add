#!/usr/bin/env bash
# ADD Codex hook — Stop
#
# Appends a timestamp marker to `.add/handoff.md` when the session ends, so
# the next SessionStart can surface "last touched at" context. Idempotent
# no-op when `.add/` is absent (non-ADD-managed projects).
#
# This is the Codex-side substitute for Claude Code's PostToolUse(Write/Edit)
# trigger — Codex's PostToolUse fires only on Bash, so state capture happens
# at the next natural boundary instead. See AC-022.

set -euo pipefail

ADD_DIR=".add"
HANDOFF="$ADD_DIR/handoff.md"

if [ ! -d "$ADD_DIR" ]; then
  exit 0
fi

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ ! -f "$HANDOFF" ]; then
  # Don't create handoff.md out of thin air — the user may not have opted in.
  # Just record a stop marker to a rolling log that sidecarring agents can read.
  mkdir -p "$ADD_DIR/away-logs"
  echo "# Codex stop at $TS" >> "$ADD_DIR/away-logs/codex-session-stops.md"
  exit 0
fi

# Append a session boundary marker to the existing handoff.
{
  echo ""
  echo "---"
  echo ""
  echo "*Codex session stopped: $TS*"
} >> "$HANDOFF"

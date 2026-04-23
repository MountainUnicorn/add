---
description: "[ADD test fixture] Missing cache-discipline markers"
allowed-tools: [Read, Write, Edit, Task]
---

# Test Fixture: Missing Markers

This fixture dispatches via the Task tool but has NO cache markers anywhere.
The validator must flag CACHE-001.

## Dispatch

Invoke a sub-agent with the Task tool. Pass it a freeform prompt that
interleaves project context and per-call task data with no cache discipline.

Example: Task(subagent_type="implementer", prompt="implement AC-001 in src/foo.py — project uses python/fastapi")

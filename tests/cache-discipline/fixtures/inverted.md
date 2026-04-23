---
description: "[ADD test fixture] Inverted cache-discipline markers"
allowed-tools: [Read, Write, Edit, Task]
---

# Test Fixture: Inverted Markers

The VOLATILE marker appears before STABLE — inverted layout.

## Dispatch

Emit the following prompt body and dispatch via Task:

<!-- CACHE: VOLATILE -->
Role: implementer
Task: implement AC-001
<!-- CACHE: STABLE -->
Project: example-project
Spec: (full body)

Task(subagent_type="implementer", prompt=...)

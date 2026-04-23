---
description: "[ADD test fixture] Volatile placeholder inside STABLE block"
allowed-tools: [Read, Write, Edit, Task]
---

# Test Fixture: Volatile in Stable

A per-call placeholder `{user_message}` leaks into the STABLE block — that
defeats the cacheable prefix. Validator must flag CACHE-003.

## Dispatch

<!-- CACHE: STABLE -->
Project: example-project
User request: {user_message}
Spec body: (full)
<!-- CACHE: VOLATILE -->
Role: implementer
Task: implement AC-001

Task(subagent_type="implementer", prompt=...)

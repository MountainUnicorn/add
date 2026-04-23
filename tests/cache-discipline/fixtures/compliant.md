---
description: "[ADD test fixture] Compliant skill with proper cache-discipline markers"
allowed-tools: [Read, Write, Edit, Task]
---

# Test Fixture: Compliant

This fixture simulates a skill that dispatches a sub-agent via the Task tool
and wraps the emitted prompt with the proper STABLE/VOLATILE markers.

## Dispatch

When invoking the sub-agent, emit the following prompt body:

<!-- CACHE: STABLE -->
Project: example-project (python, fastapi)
Conventions: tabs, snake_case
Active rules: spec-driven, tdd-enforcement, learning
Active learnings: (from .add/learnings-active.md)
Spec body: (full contents of specs/current.md)
<!-- CACHE: VOLATILE -->
Role: implementer
Task: satisfy AC-001 from the spec above.
Hint: target test is tests/test_feature.py::test_ac001.

Use the Task tool to dispatch the sub-agent with the prompt above.

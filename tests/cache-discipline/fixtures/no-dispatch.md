---
description: "[ADD test fixture] Skill does not dispatch any sub-agent"
allowed-tools: [Read, Write, Edit]
---

# Test Fixture: No Dispatch

This skill reads files, writes files, but never hands work to a sub-agent.
It has no cache markers, and none are required. The validator must skip
silently — zero findings.

## Steps

1. Read the input file.
2. Transform the content.
3. Write the output file.

No delegation happens here.

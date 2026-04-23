<!-- ADD:MANAGED:START version=0.9.0 maturity=alpha generated=2026-04-22T12:00:00Z -->

# ADD

ADD (Agent Driven Development) solves this by bringing **structured, specification-driven SDLC practices** to AI-native development—just as TDD revolutionized testing and DDD revolutionized domain modeling, ADD provides a proven methodology for human-AI collaboration at scale.

## Engagement Protocol

The human is the architect and decision maker; the agent is the builder. Gather requirements via one-question-at-a-time interviews. Never batch questions. When stepping away, declare autonomy ceilings explicitly — the agent may climb local → dev → staging but never merges to main or ships to production without human approval.

## Spec-First Invariants

Every feature flows through the document hierarchy: PRD → Feature Spec → Implementation Plan → User Test Cases → Automated Tests → Implementation. No link may be skipped. Specs live in `specs/`, plans in `docs/plans/`. Code changes without a corresponding spec are rejected on review.

## Pointers

- [`.add/config.json`](./.add/config.json) — project configuration
- [`docs/prd.md`](./docs/prd.md) — product requirements
- [`specs/`](./specs/) — feature specifications
- [`core/rules/`](./core/rules/) — behavioral rules (ADD-managed projects)

<!-- ADD:MANAGED:END -->

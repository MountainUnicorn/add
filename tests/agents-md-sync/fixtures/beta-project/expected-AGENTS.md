<!-- ADD:MANAGED:START version=0.9.0 maturity=beta generated=2026-04-22T12:00:00Z -->

# BetaForge

BetaForge is a continuous delivery platform for small teams. It packages spec-driven development, automated TDD, and environment-aware promotion into a single workflow that lets a team of three ship with the discipline of a team of thirty.

## Engagement Protocol

The human is the architect and decision maker; the agent is the builder. Gather requirements via one-question-at-a-time interviews. Never batch questions. When stepping away, declare autonomy ceilings explicitly — the agent may climb local → dev → staging but never merges to main or ships to production without human approval.

## Spec-First Invariants

Every feature flows through the document hierarchy: PRD → Feature Spec → Implementation Plan → User Test Cases → Automated Tests → Implementation. No link may be skipped. Specs live in `specs/`, plans in `docs/plans/`. Code changes without a corresponding spec are rejected on review.

## TDD Discipline

Strict RED → GREEN → REFACTOR → VERIFY cycle. Tests are authored before implementation; failing tests prove the test is exercising new behavior. Quality gates run at VERIFY: full test suite, linter, type checker, spec-compliance check. Any gate failure blocks promotion.

## Maturity & Autonomy Ceiling

Project maturity: **beta**.

- **local**: auto-promotion not declared.
- **dev**: agents may auto-promote on green verification.
- **staging**: agents may auto-promote on green verification.
- **production**: human approval required.

Production deploys and merges to the default branch always require human approval.

## Currently Active Spec

- [`specs/payment-flow.md`](./specs/payment-flow.md)

## Pointers

- [`.add/config.json`](./.add/config.json) — project configuration
- [`docs/prd.md`](./docs/prd.md) — product requirements
- [`specs/`](./specs/) — feature specifications

<!-- ADD:MANAGED:END -->

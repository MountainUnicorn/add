---
autoload: true
maturity: alpha
---

# ADD Rule: Human-AI Collaboration Protocol

The human is the architect, product owner, and decision maker. Agents are the development team.

## Interview Protocol

During `/add:init`, `/add:spec`, or any discovery, follow the 1-by-1 format:

1. **Estimate first:** State total questions and time before starting
2. **One at a time:** Ask ONE question, wait, then ask the next (builds on previous answers)
3. **Priority order:** Who/Why → What → Boundaries → Edge Cases → Polish (essential first)
4. **Offer defaults** for non-critical questions ("Default: toast notifications — say 'default' to accept")
5. **One concept per question:** If a question asks 3+ independent decisions, split it
6. **Confusion protocol:** On "I don't understand" → explain in plain language → re-ask via `AskUserQuestion` → wait for confirmed answer. NEVER pick a default after confusion.
7. **Confirmation gate:** After all questions, present answer summary before generating output. Flag agent-chosen defaults visibly. Do NOT generate until user confirms.
8. **Cross-spec check:** Before writing a new spec, scan `specs/` for related ACs, shared data models, and conflicting requirements. Present conflicts to user before generating.

## Engagement Modes

| Mode | When | Duration | Format |
|------|------|----------|--------|
| **Spec Interview** | Init, new feature, major change | 10-20 questions | Deep 1-by-1 interview |
| **Quick Check** | Mid-implementation clarification | 1-2 questions | Direct question with context |
| **Decision Point** | Multiple valid approaches | 1 question + options | Present 2-3 options with tradeoffs |
| **Review Gate** | Work complete, needs sign-off | Summary + yes/no | Show summary, not full diff |
| **Status Pulse** | Long-running/away mode work | No response needed | Brief progress update |

## Away Mode

When the human declares absence with `/add:away`:

**Receive:** Acknowledge duration, present work plan (autonomous vs. queued), get confirmation.

**Autonomous (proceed without asking):**
- Commit/push to feature branches, create PRs
- Run/fix quality gates, run tests, install dev dependencies
- Follow environment promotion ladder where `autoPromote: true`

**Boundaries (queue for human return):**
- No production deploys or `autoPromote: false` environments
- No merges to main, no features without specs
- No irreversible changes or contested architecture decisions
- Log questions and skip to next task if ambiguous

**Discipline:** Only work from approved plan. Maintain running log. Status pulses at reasonable intervals.

**Return:** Summarize completed work, list pending decisions, flag blockers, suggest priorities.

## Autonomy Levels

Set in `.add/config.json`:

- **Guided:** Ask before each feature, confirm spec interpretation, review every commit
- **Balanced:** Autonomous within spec scope, quick checks for ambiguity, review at PR level
- **Autonomous:** Full TDD cycles without check-ins, stop only for blockers, review at PR level

## Anti-Patterns

- NEVER batch 5+ questions or compress 3+ decisions into one question
- NEVER ask questions answerable from spec/PRD
- NEVER proceed after confusion without confirmed answer via `AskUserQuestion`
- NEVER say "unless you disagree" as substitute for asking — soft opt-outs are not consent
- NEVER generate output without confirmation gate
- NEVER skip cross-spec consistency check before writing new specs
- NEVER continue after "stepping away" without presenting away-mode work plan

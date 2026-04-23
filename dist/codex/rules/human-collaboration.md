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
6. **Cross-spec check:** Before writing a new spec, scan `specs/` for related ACs, shared data models, and conflicting requirements. Present conflicts to user before generating.

### Confusion Protocol

When a user signals confusion ("I don't understand", "what do you mean?", "I'm not sure", etc.):

1. **Explain** in plain language, translating technical details to user impact
2. **Re-ask** via `AskUserQuestion` with simplified options — the structured popup forces a confirmed selection
3. **Wait** for the confirmed answer before proceeding

**NEVER** do any of the following after a user signals confusion:
- **NEVER** pick a default and say "unless you disagree" — that is not consent
- **NEVER** proceed to the next question without a confirmed answer to this one
- **NEVER** start generating output (spec, plan, code) with an unconfirmed answer
- **NEVER** treat your own explanation as the user's agreement

### Confirmation Gate

After the final interview question — and BEFORE generating any output — present a summary of all captured answers. Flag any agent-chosen defaults visibly. **NEVER generate** the spec/output until the user confirms the summary.

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

- **NEVER** batch 5+ questions in a single message
- **NEVER** ask questions you can answer from the spec or PRD
- **NEVER** ask "is this okay?" without showing what "this" is
- **NEVER** continue working after the human said they're stepping away without presenting the away-mode work plan first
- **NEVER** present technical implementation details to get product decisions — translate to user impact
- **NEVER** compress 3+ independent decisions into a single interview question
- **NEVER** proceed after "I don't understand" without re-asking via `AskUserQuestion` and getting a confirmed answer (see Confusion Protocol)
- **NEVER** say "unless you disagree" or "if that works for you" as a substitute for asking — soft opt-outs are not consent
- **NEVER** generate a spec without presenting the answer summary for confirmation (see Confirmation Gate)
- **NEVER** write a new spec without checking existing specs for related ACs, shared patterns, or conflicts

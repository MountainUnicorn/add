---
autoload: true
maturity: alpha
---

# ADD Rule: Human-AI Collaboration Protocol

The human is the architect, product owner, and decision maker. Agents are the development team. This rule governs how they work together.

## Interview Protocol

When gathering requirements (during `/add:init`, `/add:spec`, or any discovery), follow the 1-by-1 interview format:

### Estimation First

Always state the scope before starting:

```
This will take approximately {N} questions (~{M} minutes).
```

Count your questions before asking the first one. Be honest — if it's 15 questions, say 15. The human decides if now is the right time.

### One at a Time

Ask ONE question, wait for the answer, then ask the next. Each question can build on previous answers, which produces far better specs than batched questionnaires.

```
Question 1 of ~8: Who is the primary user of this feature?
> [human answers]

Question 2 of ~8: Based on what you said about enterprise buyers,
what's their biggest pain point with existing tools?
> [human answers]
```

### Priority Ordering

Ask the most critical questions first. If the human says "that's enough, run with it" after question 5 of 10, you should have the essential information. Structure questions in this order:

1. **Who and Why** — User, problem, motivation (MUST have)
2. **What** — Core behavior, happy path (MUST have)
3. **Boundaries** — Scope limits, what's out (SHOULD have)
4. **Edge Cases** — Error handling, unusual scenarios (NICE to have)
5. **Polish** — Naming preferences, UX details (NICE to have)

### Defaults for Non-Critical Questions

For lower-priority questions, offer a sensible default:

```
Question 7 of ~8: What format should error messages take?
(Default: toast notifications that auto-dismiss after 5 seconds)
```

The human can just say "default" and move on.

### Question Complexity Check

Before asking each interview question, self-check:

1. **Count independent decisions** in the question. If the question asks the user to
   address 3 or more separate sub-decisions, split it into separate questions.
2. **One concept per question.** Each question should ask about ONE thing the user
   needs to decide. "What error types should we handle?" is one decision.
   "What error types should we handle, how should we detect paywalls, what about
   bot-blocking, and should multi-title statutes be linked?" is four decisions.
3. **When in doubt, split.** A question that takes 3+ sentences to explain is
   probably asking about multiple things. Split it.

**What splitting looks like:**

Bad (compressed):
```
Question 5 of 9: What should happen when things go wrong? Think about:
network timeouts, invalid API keys, rate limiting, malformed responses,
partial data, missing required fields, and concurrent edit conflicts.
```

Good (split):
```
Question 5 of 12: What should happen when an external API call fails
(timeout, 500 error, network unreachable)?

Question 6 of 12: Some APIs enforce rate limits. How should the
system handle throttling — retry, queue, or fail gracefully?

Question 7 of 12: What should happen when the API returns data
but required fields are missing or malformed?
```

A compressed question lets the agent choose defaults for sub-decisions the user
didn't explicitly address. Those defaults become spec requirements. A less
experienced PM may not realize they've implicitly agreed to simplifications.

### Confusion Protocol

When a user signals confusion during any interview question — "I don't understand",
"what do you mean?", "can you explain?", "I'm not sure", or any equivalent — follow
this exact sequence:

1. **Explain** the concept in plain language, without jargon. Translate technical
   implications to user impact ("what this means for you").
2. **Re-ask** the question using the `AskUserQuestion` tool with simplified options
   that reflect the explanation. The structured popup forces a confirmed selection —
   the agent cannot proceed without the user clicking an answer.
3. **Wait** for the confirmed answer before moving to the next question.

**NEVER** do any of the following after a user signals confusion:
- Pick a default and say "unless you disagree" — that is not consent
- Proceed to the next question without a confirmed answer to this one
- Start generating output (spec, plan, code) with an unconfirmed answer
- Treat your own explanation as the user's agreement

Every answer in a spec interview becomes a binding requirement. An unconfirmed
answer means the spec — and everything built from it — rests on an assumption
the user never validated.

### Confirmation Gate

After the final interview question is answered — and BEFORE generating any output
(spec, PRD, plan) — present a summary of all captured answers for confirmation.

```
Here's what I captured from our interview:

1. Scope: {answer summary}
2. Users: {answer summary}
3. Happy path: {answer summary}
...
7. Output format: {answer summary} ← (agent-recommended default)

Any of these wrong? Reply "looks good" to proceed, or tell me
which number to change.
```

**Rules:**
- Mark any answer where the agent chose a default with a visible flag so the user
  can spot agent-chosen answers at a glance.
- Do NOT generate the spec/output until the user confirms the summary.
- If the user changes an answer, update the summary and re-confirm.

This is the last checkpoint before answers become spec requirements. It catches
misunderstandings, agent-assumed defaults, and anything the user's thinking has
evolved on since answering the original question.

### Cross-Spec Consistency Check

Before writing a new spec, scan all existing specs in `specs/` for:
- **Related ACs** — acceptance criteria that cover similar capabilities. Carry
  forward consistent patterns or flag intentional divergences.
- **Shared data model patterns** — entities or fields that overlap. Ensure naming
  and structure are consistent.
- **Conflicting requirements** — two specs that say contradictory things about the
  same behavior.

If conflicts or overlaps are found, present them to the user before generating
the spec. The user decides whether to align, diverge intentionally, or defer.

### Acknowledge Thoroughness

When the human invests time answering all questions:

```
Thanks for the thorough answers. This gives me enough
for a high-confidence spec — the acceptance criteria and
test cases will be much tighter because of it.
```

## Engagement Modes

Different situations call for different interaction patterns. Recognize which mode you're in.

### Spec Interview (Deep)
- **When:** Project init, new feature, major change
- **Duration:** 10-20 questions, ~10-15 minutes
- **Output:** PRD or feature spec
- **Human commitment:** Block 15 minutes, give full attention

### Quick Check (Lightweight)
- **When:** Mid-implementation clarification
- **Duration:** 1-2 questions
- **Output:** Decision to unblock work
- **Format:** "Should this return 404 or empty array for no results?"

### Decision Point (Structured)
- **When:** Multiple valid approaches, need human to choose
- **Duration:** 1 question with 2-3 options
- **Output:** Direction chosen
- **Format:** Present options with tradeoffs, not open-ended questions
  ```
  I see two approaches:
  A) Redis cache — faster but adds infrastructure dependency
  B) In-memory LRU — simpler but lost on restart
  Which direction?
  ```

### Review Gate (Approval)
- **When:** Work complete, needs human sign-off before merge/deploy
- **Duration:** Summary + yes/no
- **Output:** Approval to proceed
- **Format:** Show summary, not full diff. "Auth middleware complete: 14 tests, spec compliant, 3 new files. Ready to commit?"

### Status Pulse (Informational)
- **When:** Long-running work, especially during away mode
- **Duration:** No response needed
- **Format:** Brief progress update. "Hour 2 of 4: auth middleware done, starting user service. On track."

## Away Mode

When the human declares absence with `/add:away`:

### Receive the Handoff
- Acknowledge the duration
- Present a work plan: what you'll do autonomously vs. what you'll queue for their return
- Get confirmation before they leave

### During Absence

Away mode grants elevated autonomy. The human is unavailable — do not wait for input on routine development tasks.

**Autonomous (proceed without asking):**
- Commit and push to feature branches (conventional commit format)
- Create PRs (human reviews when they return)
- Run and fix quality gates (lint, types, formatting)
- Run test suites, install dev dependencies
- Read specs, plans, and PRD to stay aligned — re-read `docs/prd.md` whenever validating a decision
- Promote through environments following the promotion ladder (see environment-awareness rule) — if verification passes at one level and `autoPromote: true` for the next, deploy there. Rollback automatically on failure.

**Boundaries (queue for human return):**
- Do NOT deploy to production or any environment where `autoPromote: false`
- Do NOT merge to main
- Do NOT start features without specs
- Do NOT make irreversible changes or architecture decisions with multiple valid approaches
- If ambiguous after reading the PRD, log the question and skip to the next task

**Discipline:**
- ONLY work on tasks from the approved plan
- Maintain a running log of completed work and pending decisions
- Send status pulses at reasonable intervals (not every 5 minutes)

### Return Briefing (via `/add:back`)
- Summarize what was completed (with test results)
- List pending decisions that need human input
- Flag any issues or blockers discovered
- Suggest next priorities

## Autonomy Levels

The human's autonomy preference is set in `.add/config.json` during init. Three levels:

### Guided (default for new projects)
- Ask before starting each feature
- Confirm spec interpretation before coding
- Review gate before every commit

### Balanced (recommended for established projects)
- Work autonomously within a spec's scope
- Quick check only for ambiguous requirements
- Review gate before PR, not every commit

### Autonomous (for trusted, well-specced projects)
- Execute full TDD cycles without check-ins
- Only stop for true blockers or missing specs
- Review gate at PR level only

## Anti-Patterns

- NEVER batch 5+ questions in a single message
- NEVER ask questions you can answer from the spec or PRD
- NEVER ask "is this okay?" without showing what "this" is
- NEVER continue working after the human said they're stepping away without presenting the away-mode work plan first
- NEVER present technical implementation details to get product decisions — translate to user impact
- NEVER compress 3+ independent decisions into a single interview question (see Question Complexity Check)
- NEVER proceed after "I don't understand" without re-asking via `AskUserQuestion` and getting a confirmed answer (see Confusion Protocol)
- NEVER say "unless you disagree" or "if that works for you" as a substitute for asking — soft opt-outs are not consent
- NEVER generate a spec without presenting the answer summary for confirmation (see Confirmation Gate)
- NEVER write a new spec without checking existing specs for related ACs, shared patterns, or conflicts (see Cross-Spec Consistency Check)

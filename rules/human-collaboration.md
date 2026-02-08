---
autoload: true
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
- ONLY work on well-specified tasks (spec exists, plan exists, requirements are unambiguous)
- Queue any decisions that have meaningful tradeoffs
- Do NOT deploy to production
- Do NOT make irreversible changes
- Do NOT start new features without specs
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

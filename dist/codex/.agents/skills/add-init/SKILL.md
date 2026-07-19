---
name: add-init
description: "[ADD v0.10.2] Initialize Agent Driven Development — PRD interview + project setup"
argument-hint: "[--reconfigure] [--quick] [--defaults] [--sync-registry]"
---

<!-- ADD AskUserQuestion shim (Codex) -->
<!-- Injected by scripts/compile.py when skill-policy.yaml marks a skill -->
<!-- with requires_askuser_shim: true. See AC-026/027/028 in -->
<!-- specs/codex-native-skills.md. -->

> **Codex interaction mode notice (ADD)**
>
> This skill depends on structured question/answer turns. Behavior depends on
> Codex's current mode:
>
> - **Plan mode:** call the `ask_user_question` tool for each prompt below.
>   One question per call. Wait for the user's answer before moving on.
> - **Default mode (no `ask_user_question` available):** emit the questions
>   inline as a numbered list, then **halt and wait** for the user's next
>   prompt. Do **not** improvise, infer, or fabricate answers — this skill
>   fails closed if required input is missing. Resume only after the user
>   replies.
>
> The skill body below defines what to ask; the shim only governs *how* to ask.

---

# ADD Init Command v0.10.2

Initialize Agent Driven Development for this project. This command conducts a structured interview to understand the project, then scaffolds the full ADD framework.

## Modes

| Flag | Purpose | Questions | Target user |
|---|---|---|---|
| (none) | Full interview — detects adoption vs greenfield, runs Phases 0-5 | ~12 | New projects with non-trivial scope or existing codebases |
| `--quick` | Greenfield fast path — 5 essential questions, sensible defaults elsewhere | 5 | Prototypes, solo projects, time-constrained onboarding |
| `--defaults` | True non-interactive init — every value derived or defaulted, zero questions | 0 | Headless sessions (`claude -p`, `codex exec`), CI pipelines |
| `--reconfigure` | Re-run interview preserving existing answers as defaults | ~12 | Updating an already-initialized project |
| `--sync-registry` | Read-only: reconcile `~/.claude/add/projects/{name}.json` with ground truth | 0 | Fixing drift detected by the registry-sync rule |

## Quick Mode (`--quick`)

Greenfield fast path. Skips adoption detection, skips profile-derived questions, and defaults anything that isn't one of the 5 essential answers. Use when you want ADD initialized in ~2 minutes.

### The 5 questions

1. **Name** — "Project name? (defaults to directory basename: `{current_dir_name}`)"
2. **Languages / frameworks** — "What's the primary stack? (e.g., 'python+fastapi', 'typescript+react', 'go', 'rust+axum')"
3. **Environment tier** — "Deployment scope: 1 (local only), 2 (local + prod), or 3 (local + dev + staging + prod)? (default: 2)"
4. **Maturity** — "Project maturity: poc, alpha, beta, or ga? (default: alpha)"
5. **Autonomy** — "Agent autonomy level: guided (ask often), balanced (default), or autonomous (trust)? (default: balanced)"

### Defaults applied

Everything else that the full interview asks is defaulted:

| Area | Quick-mode default |
|------|-------------------|
| PRD depth | 1-pager generated from (name, stack, scope-paragraph prompt) |
| Quality mode | `strict` for beta/ga, `standard` for alpha, `spike` for poc |
| CI/CD provider | Inferred from `.github/` if present, otherwise `none` |
| Commit convention | Conventional commits |
| Protected branches | `[main]` |
| Coverage threshold | 80% at beta/ga, 50% at alpha, 0 at poc |
| Branding palette | Default ADD raspberry (`#b00149`) until `/add-brand` is run |
| Image generation | `enabled: false, nudged: false` |

### What `--quick` skips

- Adoption mode detection (Phase 0) — not relevant for greenfield
- Cross-spec consistency check — no specs yet
- Profile-integration confirmation prompts — profile defaults applied silently
- PRD interview (Phase 1 Sections 3-7) — replaced by "scope paragraph" prompt at the end
- Swarm/worktree config questions — set by maturity default

### What `--quick` still does

- Writes `.add/config.json`, `.add/learnings.json` (empty), `docs/prd.md` (1-pager), `specs/` (dir), `docs/plans/` (dir)
- Bumps project registry (`~/.claude/add/projects/{name}.json`)
- Validates that maturity + tier combination is sensible (e.g., warns if `maturity=ga` + `tier=1`)
- Runs Phase 4 Cross-Project Persistence (same as full interview)

### Upgrade path

After quick init, the user can always run `/add-init --reconfigure` for the full interview, or run `/add-spec` to start formalizing features. Specs created under a quick-init project are no different from specs created under full init.

## Defaults Mode (`--defaults`)

True non-interactive init. Asks **zero** questions — no ask the user (use a clear, single-question prompt) calls, no interview turns, no confirmation prompts. Every value is derived from the project or defaulted. Designed for headless one-shot sessions (`claude -p "/add-init --defaults"`, `codex exec "/add-init --defaults"`) and CI pipelines, where there is no second turn to answer a question in.

### Existing-config guard

Before doing anything else, check for `.add/config.json`. If it exists, print a notice and stop — touch nothing:

```
.add/config.json already exists — /add-init --defaults never overwrites an
initialized project. Run /add-init --reconfigure to refresh the configuration.
```

### Values derived

| Field | Defaults-mode value |
|------|-------------------|
| Project name | Basename of the current working directory |
| Language | Auto-detected from manifest files: `package.json` → typescript (if `tsconfig.json` or TS deps) else javascript, `pyproject.toml`/`setup.py` → python, `go.mod` → go, `Cargo.toml` → rust, `Gemfile`/`*.gemspec` → ruby; fallback `unknown` |
| Environments | `["local"]`, no autoPromote |
| Maturity | `poc` (greenfield) or the evidence-based detected level (adoption path) — no confirmation question either way |
| Operating mode | `autonomous` |
| Scope paragraph | Omitted — PRD stub notes "run /add-spec to define scope" |
| Quality mode, coverage, branding, etc. | Same defaults table as `--quick` |

### What `--defaults` skips

- The entire interview (Phases 0-1 questions) — adoption vs greenfield is still auto-detected, but the findings/assessment panels are informational only, never confirmation prompts
- The maturity confirmation — the detected (or `poc`) level is applied directly
- The scope-paragraph prompt that `--quick` asks at the end
- All profile-integration, rule-overlap, and CLAUDE.md-overwrite questions — apply the non-destructive default silently (append, never overwrite)

### What `--defaults` still does

- Writes `.add/config.json`, `.add/learnings.json` (empty), `docs/prd.md` (stub noting "run /add-spec to define scope"), `specs/` (dir), `docs/plans/` (dir)
- Bumps the project registry (`~/.claude/add/projects/{name}.json`)
- Runs Phase 4 Cross-Project Persistence promptlessly — reads an existing profile if present, never creates or modifies one (profile creation requires the interview)
- Composes with `--sync-registry` unchanged

### Upgrade path

Same as `--quick`: run `/add-init --reconfigure` any time for the full interview, or `/add-spec` to start formalizing features.

## Sync Registry Mode (`--sync-registry`)

Reconciles `~/.claude/add/projects/{name}.json` against the project's ground truth. Triggered automatically by the `registry-sync.md` rule when drift is detected at session start, or manually by the user.

Read-only in the project; writes only to the cross-project registry file. Shows a diff before writing:

```
REGISTRY RECONCILIATION for {project}:
  learnings_count: 5 → 55
  last_retro: null → {date}
  maturity: alpha → beta

Apply? [yes/no]
```

Does not run the interview. Does not touch `.add/config.json`.

## Pre-Flight Check

1. Check if `.add/config.json` already exists
2. If exists AND no `--reconfigure` flag, display current config summary and ask if reconfiguration is wanted
3. If exists AND `--reconfigure` flag, proceed with interview (preserving existing answers as defaults)
4. If exists AND `--defaults` flag, print the existing-config notice (see Defaults Mode) and exit without touching anything

### User Profile Detection

Check if `~/.claude/add/profile.md` exists. This file carries preferences across projects.

Also check `~/.claude/add/library.md` for cross-project learnings and
`~/.claude/add/projects/` for previous project history.

**If profile exists:**
Read it and use preferences as defaults throughout the interview. Also read
`~/.claude/add/library.md` for cross-project knowledge. Announce this:
```
I found your ADD profile with preferences from previous projects.
I'll use these as defaults — you can override anything during the interview.

Your profile preferences:
  Stack: {languages, frameworks from profile}
  Cloud: {provider from profile}
  Process: {autonomy, quality mode from profile}

Previous ADD projects: {list from ~/.claude/add/projects/}
```
This can dramatically shorten the interview — if the profile matches, Section 2 might only be 2-3 confirmation questions instead of 6-8.

**If no profile exists:**
This is a first-time ADD user. After the interview, offer to create one:
```
This is your first ADD project. After setup, I can create a user
profile (~/.claude/add/profile.md) so future projects inherit your
preferences and the interview gets shorter. Want me to create it?
```

## Phase 0: Discovery (Adoption Mode — Automatic Detection)

If `.add/config.json` does NOT exist AND the project contains existing project files (CLAUDE.md, .claude/, specs/, tests/, CI/CD, docker-compose.yml, git history, etc.), automatically enter **adoption mode**. This is non-destructive — ADD absorbs and complements existing methodology.

### Automatic Detection Checklist

Silently scan the project for existing methodology without asking the user:

```
□ CLAUDE.md — read it, extract project description and existing commands
□ .claude/rules/ — list existing rules, note coverage areas
□ .claude/skills/ — list existing skills, note what ADD would add
□ .claude/settings.json — read permissions
□ specs/ or .add/specs/ — list existing feature specifications
□ docs/ or docs/plans/ — list existing implementation plans
□ tests/ — identify test framework, coverage, directory structure
□ .github/workflows/ — identify CI/CD pipelines
□ .gitlab-ci.yml / Jenkinsfile — alternative CI/CD
□ docker-compose.yml — identify containerization strategy
□ Dockerfile — identify containerization
□ package.json / pyproject.toml / Cargo.toml / go.mod — identify stack
□ .git/config — identify git remote host and repository
□ .pre-commit-config.yaml — identify existing git hooks
□ .env.example — identify environment variables and secrets strategy
□ PROJECT_STATUS.md or similar — identify session tracking / status history
```

### Present Adoption Findings to User

After silent detection (and the maturity assessment below), show the user a structured summary of what exists vs. what ADD adds: existing methodology, existing infrastructure, what ADD would add (non-destructive), what ADD would preserve untouched — then ask "Proceed with adoption?". Render per `~/.codex/add/templates/init-output-examples.md` (Adoption Findings Panel).

### Maturity Level Detection

Assess project maturity using evidence-based scoring. This assessment is BINDING — maturity is determined by what the project actually demonstrates, not by aspiration.

#### Evidence Scoring

Score each of these 12 evidence categories as present or absent (git timestamps, configs, and CI files are the detection sources): specs, tests, coverage threshold (20% = alpha signal, 50% = beta, 80% = ga), CI/CD pipeline, PR-based branching, conventional commits (sample last 20 commits), environment separation, release tags, protected branches, TDD evidence (tests predate/accompany implementation), spec-driven evidence (specs predate implementation), and quality gates (pre-commit hooks, CI checks, linting).

Scoring: **POC** 0–2 items · **Alpha** 3–5 · **Beta** 6–8 · **GA** 9+.

For the full maturity cascade matrix and promotion process, see `~/.codex/add/references/maturity-matrix.md`.

#### Assessment Output

Present the assessment authoritatively — do NOT ask the user to confirm or override the level. Compact example:

```
MATURITY ASSESSMENT (evidence-based):
  Your project operates at: ALPHA
  Evidence: ✓ tests (47% coverage) ✓ CI/CD ✓ conventional commits · ✗ 9 other items
  Score: 3/12 evidence items → ALPHA
  Gap to Beta: specs (/add-spec), coverage >50%, PR workflow, 2+ environments, TDD evidence
```

Render the full panel (per-item ✓/✗ list, gap checklist, promotion note) per `~/.codex/add/templates/init-output-examples.md` (Maturity Assessment Panel).

If the user disagrees with the assessment, explain that ADD maturity is evidence-based and that promotion happens through `/add-retro` when criteria are met. The user can start at the detected level and promote quickly if the project genuinely meets higher criteria.

### Adoption-Mode Interview (Shorter and Smarter)

Adoption mode runs a SHORTER interview because many answers are detected:

**Section 1 (Product):**
If CLAUDE.md exists with a project description, skip most questions. Just confirm:
```
From your CLAUDE.md, I understand this project:
{Extracted description from CLAUDE.md}

Is that still accurate? Anything to add or clarify?
```

Otherwise, run standard Section 1 questions (4 questions, ~3 min).

**Section 2 (Architecture):**
Nearly all answers are detected from project files. Just run confirmations:
```
I detected your tech stack from your project files:
  Language: {detected}
  Backend: {detected}
  Frontend: {detected}
  Database: {detected}
  Containers: {detected}
  Git: {detected}
  CI/CD: {detected}

Does this match your current setup? Anything to add or correct?
```

Then ask the 3 process questions from Section 3 (autonomy, quality mode, team size).

**Total adoption interview: ~5-8 questions, ~5 minutes** (vs. 14-16 questions in greenfield mode).

### Handling Existing Rules

ADD's rules are NOT copied into the project — they are injected each session by the plugin's SessionStart hook (`load-rules.sh`), maturity-gated, and update automatically with the plugin. `/add-init` never writes to `.claude/rules/`.

For each existing rule in the project's `.claude/rules/`, check for overlap with ADD's rule set:

- **If an existing project rule covers similar ground as an ADD rule:** Ask the user:
  ```
  You have an existing rule: {existing_rule.md}
  This covers similar ground as ADD's {add_rule} (injected automatically each session).

  Options:
    a) Keep your rule as-is — it takes precedence where they conflict
    b) Trim your rule to only the parts ADD doesn't cover
    c) Remove your rule — rely on ADD's injected version
  ```

- **If a stale ADD rule copy exists** (same name as a plugin rule, or `add-` prefixed — left behind by an ADD version before v0.9.11 that copied rules): recommend removal, since the hook now injects the current version and the copy will drift:
  ```
  .claude/rules/{name}.md matches an ADD plugin rule. ADD now injects rules
  at session start — this copy is redundant and will go stale. Remove it?
  ```

### Handling Existing Skills

For each ADD skill (e.g., `/add-spec`, `/add-plan`, `/add-away`, `/add-back`, `/add-retro`):

- **If project has equivalent skill:** Ask:
  ```
  You have an existing skill: {existing_skill}
  ADD provides {add_skill} which extends this.

  Keep yours, use ADD's, or should I merge them?
  ```

- **If project doesn't have it:** Add the ADD skill to `.claude/skills/`.

- **Priority:** Project's existing skills are preferred unless the user wants ADD's version or a merge.

### Non-Destructive CLAUDE.md

**NEVER overwrite an existing CLAUDE.md.**

Instead, append an ADD methodology section at the end:

```markdown
## ADD Methodology

This project follows Agent Driven Development (ADD) for structured code generation and knowledge persistence.

**Configuration:** `.add/config.json`
**Knowledge Base:** `.add/learnings.md` (auto-populated during development)
**Quality Gates:** Enforced via `/add-verify` command
**Workflow:** `/add-spec` → `/add-plan` → `/add-tdd-cycle` → `/add-retro`

See `.add/config.json` for detailed settings.
```

### Retroactive Specs Import

If the project already has specs in a custom location (e.g., `specs/spike/`, `doc/specs/`, or other):

- **DON'T move or rename them.**
- **DO** create `.add/config.json` pointing to the existing specs directory:
  ```json
  "specs_directory": "specs/spike/",
  "specs_format": "markdown"
  ```

- Ask the user:
  ```
  Your feature specs are currently in {location}.
  Should I continue using that directory for ADD specs,
  or create a fresh specs/ directory for ADD-formatted specs?
  ```

### Retroactive Learnings Seeding

For mature projects, seed `.add/learnings.md` with initial knowledge instead of a blank template:

1. **Read CLAUDE.md** for documented patterns, architectural decisions, and conventions.
2. **Scan git log** (last 30 commits) for common issues, bugs, and fixes.
3. **Read PROJECT_STATUS.md** (if exists) for session history and lessons learned.
4. **Extract patterns:** Identify recurring problems, solutions, and anti-patterns.

Present the seed entries to the user for confirmation:

```
I've extracted initial learnings from your project history:

PATTERNS & CONVENTIONS:
  - {pattern 1 from CLAUDE.md}
  - {pattern 2 from git history}

COMMON ISSUES & SOLUTIONS:
  - {issue 1} → {solution from git log}
  - {issue 2} → {solution from recent commits}

These will populate .add/learnings.md as the starting knowledge base.
Any additions or corrections before I finalize?
```

### Catch-Up Spike Generation

After confirming maturity level and completing the adoption interview, generate a gap analysis comparing current project state against the confirmed maturity level requirements (per the cascade matrix in `~/.codex/add/references/maturity-matrix.md`):

```
CATCH-UP ANALYSIS: Bringing {project} to {MATURITY} compliance

REQUIRED FOR {MATURITY}:                    STATUS:
  PRD document                               {✓ exists | ✗ missing}
  Feature specs                              {✓ N specs found | ✗ missing for N features}
  Implementation plans                       {✓ N plans found | ✗ missing}
  Quality gates configured                   {✓ N gates active | ✗ not configured}
  TDD coverage at threshold                  {✓ N% meets threshold | ✗ N% below threshold}
  CI/CD pipeline                             {✓ active | ✗ not found | ○ not required at this level}
  Milestone structure                        {✓ found | ✗ missing | ○ not required at this level}
  Source control workflow                    {✓ matches | ⚠ partial | ✗ missing}

SCORE: {N}/{TOTAL} requirements met

CATCH-UP ITEMS (if score < 100%):
  1. {item — e.g., "Generate docs/prd.md from existing CLAUDE.md + brief interview"}
  2. {item — e.g., "Create retroactive specs for auth, billing features"}
  3. {item — e.g., "Configure 3-gate quality pipeline"}
```

If catch-up items exist, ask:
```
I can generate a catch-up cycle to bring your project to {MATURITY} compliance.
This would take approximately {estimate} of autonomous work.

Options:
  a) Run catch-up spike now (I'll work autonomously)
  b) Save as first cycle plan (you review first)
  c) Skip — I'll adopt ADD alongside your existing workflow
```

If option (a) or (b):
- Create `.add/cycles/cycle-0-catchup.md` with the gap items as work items
- For (a): execute immediately, report back when done
- For (b): save plan, wait for human review

### Adoption Summary

Display what was newly created, what was enhanced, what was preserved exactly as-is, the resulting configuration (stack, tier, quality, autonomy), and next steps. Render per `~/.codex/add/templates/init-output-examples.md` (Adoption Summary Panel).

## Phase 1: The Interview

Conduct a structured 1-by-1 interview following the human-collaboration rule. Always estimate total questions upfront.

### Greeting

```
Welcome to Agent Driven Development (ADD).

I'll interview you across 4 sections to understand your project:
  Section 1: Product (4 questions, ~3 min)
  Section 2: Architecture & Tech Stack (6-8 questions, adaptive, ~5 min)
  Section 2.5: Branding (1-2 questions, ~1 min)
  Section 3: Process & Collaboration (5 questions, ~4 min)

Total: approximately 16-19 questions, ~12 minutes.
Some questions are adaptive — I'll skip what I can detect automatically.

Your answers will generate:
  - docs/prd.md (Product Requirements Document)
  - .add/config.json (project configuration)
  - .claude/settings.json (Claude Code settings)
  - specs/ directory (for feature specifications)
  - docs/plans/ directory (for implementation plans)

Let's begin.
```

### Question Bank

Load the question bank — verbatim Q1–Q18 prompts plus ask the user (use a clear, single-question prompt) options — from `~/.codex/add/templates/init-interview.md`. Ask questions ONE AT A TIME, building on previous answers. Phase structure and branching logic:

**Section 1: Product (Q1–Q4, ~4 questions)**
Problem/value proposition (Q1), primary users (Q2), success metrics (Q3), MVP scope in/out (Q4).

**Section 2: Architecture & Tech Stack (Q5–Q13, ~6-8 questions, adaptive)**

Before asking tech questions, run the silent detection step (do not show to user): check for package.json, pyproject.toml/requirements.txt, Cargo.toml, go.mod, pom.xml/build.gradle, docker-compose.yml, Dockerfile, .github/workflows/, .gitlab-ci.yml, Jenkinsfile, .git/config, terraform/.tf files, Makefile/justfile. If project files are detected, summarize what you found before asking Q5.

- **Q5 (The Branch Question)** determines whether Q6–Q8 are prescriptive (human tells) or advisory (Claude suggests). Three branches:
  - "Detect from project files" → present the detected stack for confirmation, skip Q6–Q7.
  - "Suggest a stack" → propose per the heuristics in the question bank based on Section 1 answers; human approves/modifies.
  - "I have a stack in mind" → ask Q6 (languages + versions) and Q7 (frameworks). If answers are vague ("Python" with no version), probe for the version.
- **Q8 (all paths converge): source control & hosting** — confirm if a `.git/config` remote is detected, otherwise ask.
- **Q9: environment tier** (Tier 1 local / Tier 2 local+prod / Tier 3 full pipeline), then **Q10: tier-dependent deployment details** (Tier 1: run command; Tier 2: cloud provider + production URL; Tier 3: per-environment infrastructure walkthrough).
- **Q11: CI/CD** — confirm if detected; "None yet — set it up for me" means scaffold a basic pipeline during Phase 2.
- **Q12: containerization** — confirm if detected, otherwise ask.
- **Q13: additional technical constraints** (auth, compliance, performance, integrations).

**Section 2.5: Branding (Q13.5, ~1 min)**
"Yes — let me share it" → parse hex color, fonts, tone, logo path, and style-guide source into `branding.*`, generating the palette per `~/.codex/add/templates/presets.json`. "No — use ADD defaults" → raspberry preset (#b00149) from presets.json, optionally offering the preset picker (Raspberry / AI Purple / Ocean / custom hex). Branding can always be updated later with `/add-brand-update`.

**Section 3: Process & Collaboration (Q14–Q18, ~4 min)**

- **Q14: maturity level** — branching:
  - **Adoption mode** (Phase 0 detected existing project): SKIP Q14 entirely; use the evidence-based level from Phase 0, and note "Maturity level was determined by evidence analysis in Phase 0. Skipping maturity question."
  - **Greenfield mode:** cap at Alpha maximum — a brand new project has zero evidence for Beta or GA (promote via `/add-retro` when criteria are met). If POC is selected, explain the relaxed process per the question bank.
- **Q15: autonomy** (guided / balanced / autonomous), **Q16: quality standard** (spike / standard / strict — sets coverage threshold), **Q17: team size** (sets branching + PR strategy), **Q18: existing patterns/conventions** (default: ADD defaults).

### Interview Complete

```
Thanks for the thorough answers. I have everything I need to set up ADD.

Generating:
  1. docs/prd.md — your Product Requirements Document
  2. .add/config.json — project configuration
  3. Project directories and scaffolding
```

## Phase 2: Scaffold Project Structure

The standard ADD layout. See `~/.codex/add/rules/project-structure.md` for the full specification.

### Step 2.1: Create Project Directories

```bash
# ADD methodology directories (committed to git)
mkdir -p .add .add/retros .add/away-logs

# Specification and planning directories
mkdir -p specs docs/plans

# Milestone and cycle tracking
mkdir -p docs/milestones .add/cycles

# Test artifact directories
mkdir -p tests/screenshots tests/screenshots/errors tests/e2e tests/unit tests/integration

# Claude Code config
mkdir -p .claude
```

### Step 2.1.1: Scaffold CHANGELOG.md

If `CHANGELOG.md` does not already exist in the project root, create it from the changelog template:

1. Read `~/.codex/add/templates/changelog.md.template`
2. Write it to `CHANGELOG.md` in the project root

This gives the project a Keep a Changelog-formatted changelog from day one. The `/add-changelog` command and the push hook will populate it automatically as development proceeds.

### Step 2.2: Create Cross-Project Directories (machine-local)

```bash
# ADD user-level persistence (outside any project)
mkdir -p ~/.claude/add ~/.claude/add/projects
```

### Step 2.3: Update .gitignore

Append ADD-specific entries if not already present:

```gitignore
# ADD — ephemeral artifacts (don't commit)
.add/away-logs/
tests/screenshots/errors/

# ADD — these SHOULD be committed (don't ignore)
# .add/config.json
# .add/learnings.md
# .add/retros/
# specs/
# docs/plans/
# tests/screenshots/{feature}/
```

## Phase 2.5: Verify Rule Loading (no copying)

ADD rules are NOT copied into the project. The plugin's SessionStart hook (`load-rules.sh`) injects the active rule set every session, gated by the project's maturity level — rules stay current with the plugin and never drift. (Versions before v0.9.11 copied 10 rules into `.claude/rules/`; that mechanism is retired because copies went stale and, after v0.9.9, duplicated the hook injection.)

This phase only checks for leftovers:

1. If `.claude/rules/` exists, list its files and compare basenames against `~/.codex/add/rules/` (also match `add-` prefixed variants).
2. For each match — a stale ADD copy from an older init — ask the user once (batch, not per-file):
   ```
   Found {N} ADD rule copies in .claude/rules/ from an earlier ADD version:
   {list}
   ADD now injects current rules at session start, so these are redundant
   and will go stale. Remove them? (user-authored rules are untouched)
   ```
3. Track for the Phase 5 summary: **Removed** / **Kept** (user declined).

## Phase 3: Generate Configuration Files

### Step 3.1: Generate .add/config.json

Read ~/.codex/add/templates/config.json.template and fill in all placeholders with interview answers. Use the Write tool.

Ensure the generated config includes the `maturity` field:
```json
{
  "maturity": {
    "level": "{poc|alpha|beta|ga}",
    "promoted_from": null,
    "promoted_date": null,
    "next_promotion_criteria": "{what's needed for the next level}"
  }
}
```

### Step 3.2: Generate docs/prd.md

Read ~/.codex/add/templates/prd.md.template and fill in all placeholders with interview answers. Write a real PRD — don't leave template placeholders. Every section should have substantive content based on the interview answers.

### Step 3.3: Generate .claude/settings.json (if it doesn't exist)

Read ~/.codex/add/templates/settings.json.template. Customize permissions based on the tech stack detected.

The template includes a `statusLine` configuration that displays `/ADD:enabled` in the Claude Code status bar (with "ADD" in raspberry #b00149). This provides an at-a-glance indicator that the project is ADD-managed. If the user already has a custom `statusLine` in their settings, ask before overwriting it.

### Step 3.4: Generate CLAUDE.md (if it doesn't exist)

Read ~/.codex/add/templates/CLAUDE.md.template. Fill in project-specific information:
- Project name and description (from Q1)
- Tech stack (from Section 2)
- Key commands (run, test, lint, deploy per stack)
- Environment info (tier, URLs, deploy triggers)
- Quality gates (mode, thresholds)
- Standard directory layout
- Link to docs/prd.md

If CLAUDE.md already exists, ask before overwriting. Offer to append ADD-specific sections instead.

### Step 3.5: Generate .add/learnings.md

Read ~/.codex/add/templates/learnings.md.template and fill in the project name. This is the knowledge base that agents build over time through automatic checkpoints. Committed to git so it transfers between devices.

### Step 3.6: Generate AGENTS.md

Invoke `/add-agents-md` to generate a portable `AGENTS.md` at project root. This is the cross-tool open standard — any agent (Cursor, Codex CLI, Copilot, Windsurf, etc.) reading the repo will pick it up. Generation is maturity-aware: POC projects get a minimal bullet summary, Alpha+ projects get a sectioned doc. If an `AGENTS.md` already exists without the ADD marker block, skip this step and recommend the user run `/add-agents-md --merge` after init completes.

## Phase 4: Cross-Project Persistence

### Step 4.1: User Profile

If `~/.claude/add/profile.md` does NOT exist and the user agreed to create one:
Read ~/.codex/add/templates/profile.md.template, fill in preferences from the interview, and write to `~/.claude/add/profile.md`.

If profile already exists, do NOT modify it — profile updates only happen during `/add-retro`.

### Step 4.2: Project Index Entry

Write a snapshot to `~/.claude/add/projects/{project-name}.json`:

```json
{
  "name": "{PROJECT_NAME}",
  "path": "{ABSOLUTE_PROJECT_PATH}",
  "initialized": "{DATE}",
  "last_retro": null,
  "stack": ["{lang-version}", "{framework}", ...],
  "tier": {N},
  "cloud": "{provider}",
  "key_learnings": []
}
```

This lets future `/add-init` calls on new projects reference your history:
"I see you worked on {project} with {stack}. Similar setup here?"

### Step 4.3: Cross-Project Library

If `~/.claude/add/library.md` does NOT exist, create it from ~/.codex/add/templates/library.md.template.
If it exists, leave it alone — it's updated during `/add-retro`.

## Phase 5: Summary

Display an "ADD initialized successfully" panel covering: project structure created (per-file ✓ list), rules installed / skipped / prefixed (from Phase 2.5 tracking), cross-project files, the 3-tier knowledge cascade (plugin-global `knowledge/global.md` → user-local `~/.claude/add/library.md` → project `.add/learnings.md`), the resolved configuration (stack, infrastructure, tier, maturity, quality + coverage threshold, autonomy, branching), and what's committed vs machine-local (with the `/add-init --import` note). Render per `~/.codex/add/templates/init-output-examples.md` (Phase 5 Init Summary Panel).

### Persona-Aware Next Steps

Display exactly ONE next-steps block based on maturity level and config — do NOT show all three. Block text is in `~/.codex/add/templates/init-output-examples.md` (Persona-Aware Next Steps Blocks):

- **maturity = poc** → lightweight prototype-mode block (/add-tdd-cycle → /add-verify fast path; /add-spec and /add-retro optional).
- **maturity = alpha or beta** → standard workflow block (/add-spec → /add-plan → /add-tdd-cycle → /add-verify, plus /add-away, /add-retro, /add-cycle).
- **PM / non-engineer** (detected by: `collaboration.team_size` > 1, OR user said "PM" or "product manager" during the interview, OR autonomy = "guided") → product-person block (/add-spec and /add-verify only).

End-of-skill epilogue: follow ~/.codex/add/references/skill-epilogue.md (observation + learning checkpoint + progress tracking).

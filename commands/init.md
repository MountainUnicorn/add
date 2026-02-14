---
description: "[ADD v0.1.0] Initialize Agent Driven Development — PRD interview + project setup"
argument-hint: [--reconfigure]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
disable-model-invocation: true
---

# ADD Init Command v0.1.0

Initialize Agent Driven Development for this project. This command conducts a structured interview to understand the project, then scaffolds the full ADD framework.

## Pre-Flight Check

1. Check if `.add/config.json` already exists
2. If exists AND no `--reconfigure` flag, display current config summary and ask if reconfiguration is wanted
3. If exists AND `--reconfigure` flag, proceed with interview (preserving existing answers as defaults)

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

After silent detection, show the user a structured summary of what exists vs. what ADD adds:

### Maturity Level Detection

Assess project maturity based on signals detected in the scan:

**POC signals:** No specs, no CI/CD, few tests (<20% coverage), single environment, <10 commits
**Alpha signals:** Some specs or docs, basic tests (20-50% coverage), 1-2 environments, conventional commits
**Beta signals:** Specs for most features, CI/CD pipeline, tests (50-80% coverage), 2+ environments, PR workflow
**GA signals:** Comprehensive specs, full CI/CD, high coverage (80%+), 3+ environments, release tags, protected branches

Present the assessment:
```
MATURITY ASSESSMENT:
  Detected signals suggest this project is at: {BETA}

  POC indicators:  {0 of 5}
  Alpha indicators: {2 of 5} — basic tests ✓, some docs ✓
  Beta indicators:  {4 of 5} — specs ✓, CI/CD ✓, 73% coverage ✓, 2 environments ✓
  GA indicators:    {1 of 5} — protected branches ✓

  Does {BETA} sound right, or would you place it differently?
```

```
I've scanned your project and detected existing ADD-like methodology.
ADD is designed to complement what you have, not replace it.

EXISTING METHODOLOGY:
  CLAUDE.md: {✓ found | ✗ not found} {(lines, sections if found)}
  Rules: {N} existing rules in .claude/rules/
  Skills: {N} custom skills in .claude/skills/
  Specs: {N} existing specifications in {location}/
  Plans: {N} implementation plans in {location}/

EXISTING INFRASTRUCTURE:
  Stack: {detected languages, frameworks, versions}
  Git: {git_host} repository at {remote_url}
  CI/CD: {detected platform or "none"}
  Containers: {Docker / docker-compose or "none"}
  Environments: {Tier 1/2/3 detected or "unknown"}

WHAT ADD WOULD ADD (non-destructive):
  ✚ .add/config.json — centralized ADD configuration
  ✚ .add/learnings.md — agent knowledge base (auto-checkpoints)
  ✚ ADD-specific rules — human collaboration, source control, environment awareness
  ✚ Quality gate system — 5-level verification gates
  ✚ /add:retro command — retrospectives and learning promotion
  ✚ Cross-project persistence — ~/.claude/add/ for preferences and history

WHAT ADD WOULD PRESERVE (untouched):
  ✓ Your existing CLAUDE.md (ADD sections appended if you want them)
  ✓ Your existing rules in .claude/rules/ (ADD rules added alongside)
  ✓ Your existing skills (ADD skills fill gaps only)
  ✓ Your existing specs and plans (preserved as-is)
  ✓ Your CI/CD pipelines and Docker configuration
  ✓ Your test structure and coverage thresholds
  ✓ All project history and git configuration

Proceed with adoption? This is entirely non-destructive — I'll add, not replace.
```

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

For each ADD rule, check for equivalent coverage in `.claude/rules/`:

- **If equivalent rule exists:** Ask the user:
  ```
  You have an existing rule: {existing_rule.md}
  This covers similar ground as ADD's {add_rule}.

  Options:
    a) Keep your existing rule, skip ADD's version
    b) Use ADD's version (newer, aligned with ADD system)
    c) Merge — I'll combine the best of both
  ```

- **If no overlap:** Add the ADD rule to `.claude/rules/` with a clean name (no `add-` prefix needed if there's no conflict).

- **Naming convention:** If there's potential confusion with existing rules, ADD rules get an `add-` prefix:
  - `add-human-collaboration.md`
  - `add-learning-checkpoints.md`
  - `add-quality-gates.md`

### Handling Existing Skills

For each ADD skill (e.g., `/add:spec`, `/add:plan`, `/add:away`, `/add:back`, `/add:retro`):

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
**Quality Gates:** Enforced via `/add:verify` command
**Workflow:** `/add:spec` → `/add:plan` → `/add:tdd-cycle` → `/add:retro`

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

After confirming maturity level and completing the adoption interview, generate a gap analysis comparing current project state against the confirmed maturity level requirements (per maturity-lifecycle rule):

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

Display what was created and preserved:

```
ADD adoption complete. Your project methodology is enhanced.

NEWLY CREATED:
  ✓ .add/config.json — ADD configuration (points to your existing specs, plans, etc.)
  ✓ .add/learnings.md — Seeded with project knowledge (from CLAUDE.md, git history)

ENHANCED:
  ✓ CLAUDE.md — ADD methodology section appended
  ✓ .claude/rules/ — {N} new ADD rules added (your existing rules unchanged)
  ✓ .claude/skills/ — {N} new ADD skills added (your existing skills unchanged)

PRESERVED EXACTLY AS-IS:
  ✓ {existing_specs_location} — {N} feature specs
  ✓ {existing_plans_location} — {N} implementation plans
  ✓ Your CI/CD pipelines
  ✓ Your Docker configuration
  ✓ Your test structure and framework
  ✓ All project history

Your project is now configured as:
  Stack: {languages, frameworks, versions}
  Tier: {N} ({description})
  Quality: {mode}
  Autonomy: {level}

Next steps:
  1. Review .add/config.json and adjust if needed
  2. Review .add/learnings.md and add any missing patterns
  3. Continue using your existing /commands and /skills
  4. Try /add:spec to create ADD-formatted specs alongside your existing ones
  5. Run /add:retro to checkpoint learnings and refine methodology
```

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

### Section 1: Product (~4 questions)

Ask these ONE AT A TIME, building on previous answers:

**Q1:** "What does this project do, and what problem does it solve?"
→ Captures: project name, problem statement, value proposition

**Q2:** "Who are the primary users?"
→ Captures: target users, use cases

**Q3:** "How will you know the project is successful? What are 2-3 measurable outcomes?"
→ Captures: success metrics

**Q4:** "What's the MVP scope — the minimum that must work for a first version? And what's explicitly NOT in the first version?"
→ Captures: in-scope, out-of-scope

### Section 2: Architecture & Tech Stack (~6-8 questions, adaptive)

Before asking tech questions, detect what already exists in the project:

```
DETECTION STEP (silent — do not show to user):
  - Check for package.json → Node.js (read for version, frameworks, scripts)
  - Check for pyproject.toml / requirements.txt → Python (read for version, frameworks)
  - Check for Cargo.toml → Rust
  - Check for go.mod → Go
  - Check for pom.xml / build.gradle → Java/Kotlin
  - Check for docker-compose.yml → containerized
  - Check for .github/workflows/ → GitHub Actions CI/CD
  - Check for .gitlab-ci.yml → GitLab CI/CD
  - Check for Jenkinsfile → Jenkins
  - Check for .git/config → git remote host
  - Check for Dockerfile → containerized
  - Check for terraform/ or .tf files → infrastructure-as-code
  - Check for Makefile, justfile → build tooling
```

If project files are detected, summarize what you found before asking Q5.

**Q5 (The Branch Question):** "Do you have specific technologies in mind for this project, or would you like me to suggest a tech stack based on what we're building?"

Use AskUserQuestion with options:
  - "I have a stack in mind — let me tell you what I want to use"
  - "Suggest a stack based on the product requirements"
  - "I've already started — detect from my project files (Recommended)" (only show if files were detected)

→ This determines whether Q6-Q8 are prescriptive (human tells) or advisory (Claude suggests).

**IF "detect from project files":**
Present what was found:
```
I found the following in your project:
  Language: Python 3.11 (from pyproject.toml)
  Backend: FastAPI (from dependencies)
  Frontend: React 18 + TypeScript (from package.json)
  Database: SeekDB (from docker-compose.yml)
  Containers: Docker Compose (4 services)
  Git: GitHub (from .git/config remote)
  CI/CD: GitHub Actions (from .github/workflows/)

Does this look right? Anything to add or correct?
```
→ Captures: full stack from detection, human confirms/adjusts

**IF "suggest a stack":**
Based on the product answers from Section 1, suggest an appropriate stack:

```
Based on what you described, here's what I'd recommend:

For a {type of product}:
  Language: {suggestion with version} — {why}
  Backend: {framework} — {why}
  Frontend: {framework or "not needed"} — {why}
  Database: {suggestion} — {why}

This is a starting point — we can adjust anything.
Does this work, or would you change anything?
```

Use these heuristics for suggestions:
- Simple SPA/website → TypeScript + React/Next.js or Vite, no backend needed
- API/backend service → Python 3.11+ FastAPI or Node.js Express
- Full-stack web app → Python FastAPI + React or Next.js full-stack
- Data pipeline/ML → Python 3.11+, minimal web framework
- CLI tool → Python or Rust depending on distribution needs
- Mobile → React Native or suggest native
→ Captures: suggested stack, human approves/modifies

**IF "I have a stack in mind":**
**Q6:** "What languages and versions? (e.g., Python 3.11, TypeScript 5.x, Java 21)"
→ Captures: languages with specific versions

**Q7:** "What frameworks? (e.g., FastAPI for backend, React 18 for frontend, PostgreSQL for database)"
→ Captures: backend framework, frontend framework, database

**Q6/Q7 NOTE:** If the human gives vague answers like "Python" without a version, probe:
"Any specific Python version? (Default: 3.11+ which is current stable)"

---

**Q8 (All paths converge here): Source Control & Hosting**

First, check if .git/config exists and has a remote. If detected, confirm:
```
I see this project is hosted on GitHub (github.com/MountainUnicorn/project).
Is that correct?
```

If NOT detected, use AskUserQuestion:
"Where do you host your source code?"
  - "GitHub"
  - "GitLab"
  - "Bitbucket"
  - "Local git only — no remote"

→ Captures: git_host (affects PR workflow, CI/CD options, deploy triggers)

**Q9: Environments & Hosting**

"What's your environment setup?"
Use AskUserQuestion with options:
  - "Local only — just running on my machine" (Tier 1)
  - "Local + Production — deploy somewhere when ready" (Tier 2)
  - "Full pipeline — dev, staging, and production" (Tier 3)
→ Captures: environment tier

**Q10: Based on tier answer — deployment details**

Tier 1:
"How do you run the project locally?" (e.g., npm run dev, docker-compose up)
→ Captures: run command, local URL

Tier 2:
"Where will production run?"
Use AskUserQuestion with options:
  - "GCP (Cloud Run, GKE, App Engine, etc.)"
  - "AWS (ECS, Lambda, Elastic Beanstalk, etc.)"
  - "Vercel / Netlify / Cloudflare (static/serverless)"
  - "Self-hosted / VPS"
→ Follow up: "What's the production URL or domain?" (Default: "TBD")
→ Captures: cloud_provider, deploy_target, production_url

Tier 3:
"Walk me through your pipeline. For each environment (dev, staging, prod), what infrastructure runs it?"
→ Captures: per-environment infrastructure details

**Q11: CI/CD**

If GitHub Actions or GitLab CI was detected, confirm:
"I see you're using GitHub Actions for CI/CD. Is that correct?"

If NOT detected, use AskUserQuestion:
"What CI/CD system do you use (or want to use)?"
  - "GitHub Actions (Recommended for GitHub repos)"
  - "GitLab CI/CD"
  - "Argo CD"
  - "None yet — set it up for me"
  - "Other"

If "None yet — set it up for me":
Claude will scaffold a basic CI pipeline during Phase 2 based on the stack and git host.
→ Captures: cicd_platform, whether to scaffold pipeline

**Q12: Containerization**

If Docker/docker-compose detected, confirm. Otherwise:
"Do you use containers (Docker) for local development or deployment?"
Use AskUserQuestion:
  - "Yes — Docker Compose for local, containers for deploy"
  - "Yes — Docker for deploy only, run locally without containers"
  - "No containers — run everything directly"
→ Captures: containerized, container_strategy

**Q13: Additional technical constraints**

"Any other technical requirements? For example: specific auth provider, compliance requirements (HIPAA, SOC2), performance targets, or third-party integrations."
(Default: "No specific constraints beyond standard best practices")
→ Captures: constraints, non-functional requirements

### Section 2.5: Branding (1 question, ~1 min)

**Q13.5:** "Do you have a brand or style guide for this project?"

Use AskUserQuestion with options:
  - "Yes — let me share it"
  - "No — use ADD defaults (Recommended)"

**IF "Yes — let me share it":**
Ask a follow-up: "Share your brand details — any of: accent/primary color (hex), font preferences, tone/voice description, logo file path, or a link to your style guide."

Parse the response for:
- Hex color codes → store as `branding.accentColor`, generate palette using algorithm from `${CLAUDE_PLUGIN_ROOT}/templates/presets.json`
- Font names → store in `branding.fonts` (heading, body, code)
- Tone description → store in `branding.tone`
- Logo path → store in `branding.logoPath`
- URL/file path → store in `branding.styleGuideSource`

**IF "No — use ADD defaults":**
Use raspberry preset (#b00149) from `${CLAUDE_PLUGIN_ROOT}/templates/presets.json`. Store `presetName: "raspberry"` in config.

Alternatively, offer preset selection:
```
Using ADD defaults. Want to pick an accent color?
```
Use AskUserQuestion with options:
  - "Raspberry (#b00149) — bold and warm (Recommended)"
  - "AI Purple (#6366f1) — classic tech"
  - "Ocean (#0891b2) — professional and calm"
  - "Custom hex color"

→ Captures: branding configuration (accentColor, palette, fonts, tone, logoPath, styleGuideSource, presetName)

Note: Branding can always be updated later with `/add:brand-update`.

### Section 3: Process & Collaboration (5 questions, ~4 min)

**Q14:** "What maturity level is this project starting at?"
Use AskUserQuestion with options:
  - "POC — proving the idea works, throwaway code is fine (Recommended for new ideas)"
  - "Alpha — core architecture locked, building out critical paths"
  - "Beta — real users will touch this, quality matters"
  - "GA — production-ready, full rigor required"
→ Captures: maturity level (cascades into all ADD behavior via maturity-lifecycle rule)

If POC selected, inform user:
"Great — POC maturity means relaxed process. Specs are optional, TDD is encouraged but not enforced, and we'll use informal cycle planning. You can promote to Alpha anytime with /add:cycle --promote."

**Q15:** "How much autonomy should I have?"
Use AskUserQuestion with options:
  - "Guided — check with me before each step"
  - "Balanced — work within specs autonomously, check at PR time (Recommended)"
  - "Autonomous — execute full TDD cycles independently, only stop for blockers"
→ Captures: autonomy level

**Q16:** "What quality standard are we targeting?"
Use AskUserQuestion with options:
  - "Spike — fast iteration, 50% coverage, relaxed type checking"
  - "Standard — 80% coverage, strict linting, type checking required (Recommended)"
  - "Strict — 90% coverage, all gates blocking, E2E required"
→ Captures: quality mode, coverage threshold

**Q17:** "Are you working solo or with a team? This affects branching and PR strategy."
Use AskUserQuestion with options:
  - "Solo — just me and you"
  - "Small team — 2-4 contributors"
  - "Team — 5+ contributors"
→ Captures: branching strategy, PR requirements

**Q18:** "Any existing patterns or conventions I should follow? For example, existing folder structure, naming conventions, or a style guide?"
(Default: "Use ADD defaults")
→ Captures: project-specific patterns

### Interview Complete

```
Thanks for the thorough answers. I have everything I need to set up ADD.

Generating:
  1. docs/prd.md — your Product Requirements Document
  2. .add/config.json — project configuration
  3. Project directories and scaffolding
```

## Phase 2: Scaffold Project Structure

The standard ADD layout. See `${CLAUDE_PLUGIN_ROOT}/rules/project-structure.md` for the full specification.

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

1. Read `${CLAUDE_PLUGIN_ROOT}/templates/changelog.md.template`
2. Write it to `CHANGELOG.md` in the project root

This gives the project a Keep a Changelog-formatted changelog from day one. The `/add:changelog` command and the push hook will populate it automatically as development proceeds.

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

## Phase 2.5: Install ADD Methodology Rules

Plugins cannot distribute rules directly. This phase copies ADD's rules into the consumer project's `.claude/rules/` directory so they take effect.

### Step 2.5.1: Create Rules Directory

```bash
mkdir -p .claude/rules
```

### Step 2.5.2: Copy ADD Rules

For each of the 10 ADD rule files, read from the plugin and write to the consumer project:

```
Rule files to install:
  1. spec-driven.md
  2. tdd-enforcement.md
  3. human-collaboration.md
  4. agent-coordination.md
  5. source-control.md
  6. environment-awareness.md
  7. quality-gates.md
  8. learning.md
  9. project-structure.md
  10. maturity-lifecycle.md
```

For each rule file:

1. Read `${CLAUDE_PLUGIN_ROOT}/rules/{name}.md`
2. Check if `.claude/rules/{name}.md` already exists in the consumer project

**If no conflict (file does not exist):**
- Write the rule to `.claude/rules/{name}.md`
- Track as "installed"

**If conflict (file already exists):**
- Use AskUserQuestion with 3 options:
  ```
  You already have a rule at .claude/rules/{name}.md.
  ADD also provides a rule with this name.
  ```
  - "Keep existing — skip ADD's version"
  - "Use ADD's version — overwrite mine"
  - "Install ADD's version with `add-` prefix (as .claude/rules/add-{name}.md)"
- Track the user's choice for each conflict

### Step 2.5.3: Track Results

Maintain a results summary for Phase 5:
- **Installed:** rules written without conflict
- **Skipped:** rules the user chose to keep their existing version
- **Prefixed:** rules installed with `add-` prefix to avoid conflict

## Phase 3: Generate Configuration Files

### Step 3.1: Generate .add/config.json

Read ${CLAUDE_PLUGIN_ROOT}/templates/config.json.template and fill in all placeholders with interview answers. Use the Write tool.

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

Read ${CLAUDE_PLUGIN_ROOT}/templates/prd.md.template and fill in all placeholders with interview answers. Write a real PRD — don't leave template placeholders. Every section should have substantive content based on the interview answers.

### Step 3.3: Generate .claude/settings.json (if it doesn't exist)

Read ${CLAUDE_PLUGIN_ROOT}/templates/settings.json.template. Customize permissions based on the tech stack detected.

The template includes a `statusLine` configuration that displays `/ADD:enabled` in the Claude Code status bar (with "ADD" in raspberry #b00149). This provides an at-a-glance indicator that the project is ADD-managed. If the user already has a custom `statusLine` in their settings, ask before overwriting it.

### Step 3.4: Generate CLAUDE.md (if it doesn't exist)

Read ${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.md.template. Fill in project-specific information:
- Project name and description (from Q1)
- Tech stack (from Section 2)
- Key commands (run, test, lint, deploy per stack)
- Environment info (tier, URLs, deploy triggers)
- Quality gates (mode, thresholds)
- Standard directory layout
- Link to docs/prd.md

If CLAUDE.md already exists, ask before overwriting. Offer to append ADD-specific sections instead.

### Step 3.5: Generate .add/learnings.md

Read ${CLAUDE_PLUGIN_ROOT}/templates/learnings.md.template and fill in the project name. This is the knowledge base that agents build over time through automatic checkpoints. Committed to git so it transfers between devices.

## Phase 4: Cross-Project Persistence

### Step 4.1: User Profile

If `~/.claude/add/profile.md` does NOT exist and the user agreed to create one:
Read ${CLAUDE_PLUGIN_ROOT}/templates/profile.md.template, fill in preferences from the interview, and write to `~/.claude/add/profile.md`.

If profile already exists, do NOT modify it — profile updates only happen during `/add:retro`.

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

This lets future `/add:init` calls on new projects reference your history:
"I see you worked on {project} with {stack}. Similar setup here?"

### Step 4.3: Cross-Project Library

If `~/.claude/add/library.md` does NOT exist, create it from ${CLAUDE_PLUGIN_ROOT}/templates/library.md.template.
If it exists, leave it alone — it's updated during `/add:retro`.

## Phase 5: Summary

Display what was created:

```
ADD initialized successfully.

PROJECT STRUCTURE:
  ✓ .add/config.json          — project configuration
  ✓ .add/learnings.md         — agent knowledge base (committed, auto-populates)
  ✓ .add/cycles/              — cycle plans and history
  ✓ docs/prd.md               — Product Requirements Document
  ✓ docs/milestones/          — milestone tracking (hill charts)
  ✓ .claude/settings.json     — Claude Code settings (status line: /ADD:enabled)
  ✓ specs/                    — feature specifications
  ✓ docs/plans/               — implementation plans
  ✓ tests/screenshots/        — visual verification
  ✓ tests/{e2e,unit,integration}/ — test directories
  ✓ CLAUDE.md                 — project context

RULES INSTALLED:
  {for each installed rule:}
  ✓ .claude/rules/{name}.md   — installed
  {for each skipped rule:}
  ○ .claude/rules/{name}.md   — skipped (kept existing)
  {for each prefixed rule:}
  ✓ .claude/rules/add-{name}.md — installed with prefix

CROSS-PROJECT:
  ✓ ~/.claude/add/profile.md          — your preferences (if created)
  ✓ ~/.claude/add/projects/{name}.json — project index entry
  ✓ ~/.claude/add/library.md          — cross-project knowledge

KNOWLEDGE SOURCES (3-tier cascade — agents read all before starting work):
  Tier 1: Plugin-global  — knowledge/global.md (ships with ADD, universal best practices)
  Tier 2: User-local     — ~/.claude/add/library.md (your cross-project wisdom)
  Tier 3: Project        — .add/learnings.md (this project's discoveries, auto-populates)

Your project is configured as:
  Stack: {languages, frameworks, versions}
  Infrastructure: {git_host} → {cicd} → {cloud_provider}
  Environment: Tier {N} ({description})
  Maturity: {level} ({description of what this means})
  Quality: {mode} (coverage threshold: {N}%)
  Autonomy: {level}
  Branching: {strategy}

WHAT'S COMMITTED (ports between devices via git):
  .add/config.json, .add/learnings.md, .add/retros/,
  specs/, docs/, tests/screenshots/{features}/

WHAT'S LOCAL (stays on this machine):
  ~/.claude/add/ (profile, library, project index)
  Run /add:init --import on a new device to rebuild from committed state.

Next steps:
  1. Review docs/prd.md and refine if needed
  2. Run /add:spec to create your first feature specification
  3. Run /add:plan to create an implementation plan from a spec
  4. Start building with /add:tdd-cycle
```

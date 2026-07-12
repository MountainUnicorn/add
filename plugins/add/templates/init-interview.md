# Init Interview Question Bank

Verbatim Phase 1 interview prompts for `/add:init`. The skill defines the phase
structure, branching logic, and adoption-mode shortcuts; this file carries the
exact question wording and AskUserQuestion options. Ask ONE AT A TIME, building
on previous answers.

## Section 1: Product (~4 questions)

**Q1:** "What does this project do, and what problem does it solve?"
→ Captures: project name, problem statement, value proposition

**Q2:** "Who are the primary users?"
→ Captures: target users, use cases

**Q3:** "How will you know the project is successful? What are 2-3 measurable outcomes?"
→ Captures: success metrics

**Q4:** "What's the MVP scope — the minimum that must work for a first version? And what's explicitly NOT in the first version?"
→ Captures: in-scope, out-of-scope

## Section 2: Architecture & Tech Stack (~6-8 questions, adaptive)

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

## Section 2.5: Branding (1 question, ~1 min)

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

## Section 3: Process & Collaboration (5 questions, ~4 min)

**Q14:** Maturity level — see the skill for adoption-mode skip and greenfield Alpha cap.

**In greenfield mode:**
"What maturity level should we start at?"

Use AskUserQuestion with options:
  - "POC — proving the idea works, throwaway code is fine (Recommended for new ideas)"
  - "Alpha — building toward MVP, some structure from the start"

Note: Beta and GA require evidence (specs, test coverage, CI/CD, PR workflow).
Promote via `/add:retro` when your project meets the criteria.

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

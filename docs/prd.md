# ADD (Agent Driven Development) Plugin - Product Requirements Document

**Project**: ADD Plugin v0.1.0 → v1.0.0
**Author**: abrooke
**Organization**: MountainUnicorn
**Repository**: https://github.com/MountainUnicorn/add
**Document Version**: 1.0
**Last Updated**: 2026-02-07

---

## 1. Problem Statement

AI code generation has fundamentally changed how software is built, yet development practices remain ad-hoc. Developers and AI agents operate without structured collaboration frameworks, leading to:

- **Specification drift**: Features are built without clear, agreed-upon requirements
- **Quality unpredictability**: No consistent testing or verification practices
- **Knowledge loss**: Learnings from projects aren't captured or reused across teams
- **Collaboration friction**: Humans and agents work in isolation or with unclear handoffs
- **Environment blindness**: Development practices don't adapt to local/staging/production contexts

ADD (Agent Driven Development) solves this by bringing **structured, specification-driven SDLC practices** to AI-native development—just as TDD revolutionized testing and DDD revolutionized domain modeling, ADD provides a proven methodology for human-AI collaboration at scale.

This PRD dog-foods ADD on itself: the ADD plugin is being built using ADD principles.

---

## 2. Target Users

**Primary**: AI-augmented development teams (1-100+ engineers)
- Individual developers using Claude Code for daily development
- Small teams (2-5 engineers) looking to standardize AI collaboration
- Larger teams (10+) scaling AI agents across projects

**Secondary**: Open-source communities
- Projects adopting Claude/Claude Code as primary development tool
- Teams wanting to document and persist project-specific AI conventions

**Tertiary**: Enterprises
- Organizations piloting AI-assisted development
- Teams needing reproducible, auditable AI-driven workflows

---

## 3. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Adoption** | 100+ GitHub stars in Y1 | Public GitHub analytics |
| **Plugin installs** | 500+ Claude Code installations | Marketplace metrics |
| **Project coverage** | Add adopted by 20+ real projects | Dogfooding + community reports |
| **Developer feedback** | ≥4.5/5 stars in marketplace | User reviews |
| **Time-to-first-value** | ≤5 min setup for new project | User interviews |
| **Quality gates efficacy** | 90%+ of gate violations caught pre-deploy | Project retrospectives |
| **Knowledge persistence** | ≥70% learned patterns reapplied cross-project | Learnings library analysis |
| **Adoption gradient** | 50% adoption on legacy projects (via /add:init --adopt) | Tracked adoptions |

---

## 4. Scope

### MVP Status: v0.1.0 ✓ (COMPLETE)

**Core infrastructure for spec-driven development:**

- ✓ 6 commands: `/add:init`, `/add:spec`, `/add:away`, `/add:back`, `/add:retro`, `/add:cycle`
- ✓ 8 skills: tdd-cycle, test-writer, implementer, reviewer, verify, plan, optimize, deploy
- ✓ 10 rules: spec-driven, tdd-enforcement, human-collaboration, agent-coordination, source-control, environment-awareness, quality-gates, learning, project-structure, maturity-lifecycle
- ✓ 10 templates: PRD, spec, plan, config, settings, CLAUDE.md, learnings, profile, library, milestone
- ✓ 1 hooks file: auto-lint on Write/Edit
- ✓ 2 manifests: plugin.json, marketplace.json

**Delivered via**:
- Pure markdown + JSON (no compiled code, no runtime dependencies)
- Claude Code plugin format (`.claude-plugin/plugin.json`)
- Local-only Tier 1 environment

**NOT in v0.1.0 (backlog)**:
- Marketplace submission flow
- Rich interactive CLI (beyond markdown/JSON)
- CI/CD integration (lint on commit, auto-test)
- Sync between user-level and project-level learnings
- Adoption wizard for legacy projects (`/add:init --adopt` logic)

---

### v0.2.0: Adoption & Polish (Q1 2026)

**Goal**: Make ADD easy to adopt on existing projects; refine v0.1.0 based on dogfooding.

**Features**:
- `/add:init --adopt` command with legacy project detection
- Enhanced spec interview workflow (iterative refinement)
- Better away/back mode context preservation
- Integration with dossierFYI dogfooding project
- Comprehensive user documentation + video walkthrough
- Retro template automation (extract lessons from project)
- Learning library cross-project search

**Success**: 10+ projects using ADD via `/add:init --adopt`

---

### v1.0.0: Marketplace Ready (Q2 2026)

**Goal**: Production-grade plugin, ready for broad distribution.

**Features**:
- Marketplace submission package (fully compliant)
- Multi-environment Tier 2/Tier 3 support (prod deployment workflows)
- Advanced learnings system: agent auto-checkpoints + human retros
- CI/CD hooks: pre-commit lint, pre-push gate, test automation
- Quality gates dashboard (status per project + org-wide metrics)
- Template marketplace (community-contributed templates)
- Profile system: team conventions auto-loaded on project init
- Enhanced verify skill: semantic testing, regression detection

**Success**: Marketplace approval + 500+ installs in first month

---

## 5. Architecture

### 5.1 Tech Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Plugin format** | Claude Code `.claude-plugin/plugin.json` | Fits Claude Code plugin ecosystem |
| **Configuration** | JSON + YAML frontmatter | Human-readable, no runtime deps |
| **Templates** | Markdown + `{PLACEHOLDER}` syntax | Portable, version-controllable |
| **Persistence** | Git (local `.add/` + user `~/.claude/add/`) | Audit trail + version control |
| **Command interface** | Claude Code `/` command syntax | Native to Claude Code |
| **Rules engine** | YAML frontmatter autoload | Declarative, opt-in per project |
| **Hooks** | Write/Edit tool triggers via manifest | Non-invasive file modification |
| **Skills** | YAML metadata + markdown workflow | Reusable, composable SDLC tasks |

### 5.2 Infrastructure

| Layer | Component | Status | Purpose |
|-------|-----------|--------|---------|
| **Local (.add/)** | Project config, specs, plans, logs | v0.1.0 ✓ | Git-committed, shared with team |
| **User (~/.claude/add/)** | Global learnings, profiles, settings | v0.2.0 | Machine-local, auto-initialized |
| **GitHub** | Repository + releases | v0.1.0 ✓ | Distribution + version tracking |
| **Marketplace** | Claude Code plugin registry | v1.0.0 | Public discoverability |
| **CI/CD** | Optional: GitHub Actions linter | v1.0.0 | Pre-commit + pre-push gates |

### 5.3 Environment Strategy

ADD supports **tiered deployment contexts**:

| Tier | Scope | Environment | Config | Use Case |
|------|-------|-------------|--------|----------|
| **Tier 1** | Local development only | `.add/config.json` in `.add/` | No backend | Plugin itself, small projects |
| **Tier 2** | Local + production staging | `.add/config.json` + `.add/env/prod.json` | SSH/API keys | Staging CI/CD pipelines |
| **Tier 3** | Full pipeline (local → CI → deploy) | Tiered configs + secrets mgmt | Cloud infra | Enterprise deployments |

**Current tier**: Tier 1 (plugin itself has no backend/frontend—just markdown/JSON files in git).

### 5.4 Work Hierarchy

ADD structures work into four levels, governed by the project's maturity level:

**Level 1: Roadmap** — Where are we going?
Lives in `docs/prd.md` milestones section. Uses Now/Next/Later framing (no fake dates). Each milestone has a name, goal, success criteria, and target maturity level. Milestones are waypoints, not timelines.

**Level 2: Milestone** — What's in this stage?
Lives in `docs/milestones/M{N}-{name}.md`. Defines appetite (effort budget, not estimate), features, and a hill chart. Features progress: SHAPED → SPECCED → PLANNED → IN_PROGRESS → VERIFIED → DONE. Uphill work (figuring out) vs downhill work (executing).

**Level 3: Cycle** — What's the next batch of work?
Lives in `.add/cycles/cycle-{N}.md`. A scope-boxed selection of features from the current milestone. Planned via `/add:cycle` command. Includes dependency assessment, parallel strategy, and validation criteria. Not time-boxed — cycles end when validation criteria are met or the human checkpoints.

**Level 4: Execution** — Doing the work.
Existing ADD layer: `/add:tdd-cycle`, `/add:verify`, `/add:deploy`. Individual feature work against specs.

**Maturity Cascade**: The maturity level (poc → alpha → beta → ga) governs how much rigor each level requires. A POC has 1 informal milestone and no cycle planning. A GA project has full milestones with hill charts, structured cycle plans with parallel strategy, and WIP limits.

---

## 6. Key Features

### 6.1 Core Feature Set (v0.1.0)

#### **Feature: Specification-Driven Development**

**Description**: Every feature begins with a PRD-→-Spec-→-Plan document hierarchy before code is written.

**Components**:
- `/add:spec` command: Interactive PRD/Spec generator
- PRD template: Structured product requirements (9 sections)
- Spec template: Detailed feature specification with test cases
- Plan template: Implementation roadmap with estimation

**Why it matters**: Specification drift is prevented. All stakeholders align before engineering effort.

**Example workflow**:
```
1. Product manager: Create PRD using /add:spec command
2. Human review: Q&A in "spec interview" engagement mode
3. Agent accepts: Generates detailed Spec from approved PRD
4. Engineer reviews: Provides estimation and sign-off
5. Code: Can now only implement spec-approved features
```

**Integration**: Spec-driven rule enforces that implementations reference spec sections.

---

#### **Feature: Test-Before-Implementation (TDD)**

**Description**: Tests are written before code; quality gates ensure all code is tested.

**Components**:
- `/add:tdd-cycle` skill: Orchestrates test-write → implement → verify loop
- `test-writer` skill: Generates unit/integration tests from spec
- `implementer` skill: Writes code that passes tests
- `verify` skill: Semantic testing + regression detection
- `quality-gates` rule: Blocks unverified code from merge

**Why it matters**: TDD is proven to reduce defects. Quality gates make it enforceable.

**Example workflow**:
```
1. Feature spec approved
2. Agent runs test-writer skill → generates test file
3. Agent runs implementer skill → writes code to pass tests
4. Pre-commit gate triggers verify skill
5. All tests pass → can commit; fail → blocked
```

**Integration**: Verify skill runs at 5 quality gates (pre-commit → pre-deploy).

---

#### **Feature: Human-AI Collaboration**

**Description**: Humans and agents work together via structured engagement modes; handoffs are explicit.

**Engagement modes**:
- **Spec interview**: Iterative refinement of PRD/Spec (human leads, agent refines)
- **Quick check**: Agent asks clarifying questions; human provides direction
- **Decision point**: Architectural/design choice; human decides, agent implements
- **Review gate**: Human reviews artifact (spec, plan, PR); agent awaits approval
- **Status pulse**: Regular checkins on project health

**Commands**:
- `/add:away`: Agent pauses; human takes over (can modify files freely)
- `/add:back`: Agent resumes; catches up on changes human made
- `/add:retro`: Retrospective meeting; team + agent reflect on learning

**Why it matters**: Prevents agent hallucination. Ensures human judgment on high-stakes decisions.

**Example workflow**:
```
1. Agent generates implementation plan
2. /decision-point: Agent asks human for architectural guidance
3. Human provides decision (async, via message)
4. Agent implements decision
5. /add:away: Human needs to focus; agent pauses
6. Human modifies code, docs, configs
7. /add:back: Agent re-reads changes, identifies learnings
8. Agent resumes with updated context
```

**Integration**: Commands map to rules (human-collaboration, agent-coordination).

---

#### **Feature: Environment Awareness**

**Description**: Development practices adapt to the target environment (local → staging → prod).

**Components**:
- Environment config: Tier-based settings (local, staging, production)
- Deployment skill: Moves code through environments
- Quality gates: Different rules per environment (e.g., stricter pre-prod gates)

**Why it matters**: Prevents "works on my machine" bugs. Ensures prod safety.

**Example**:
```
Local environment: Unit tests only, fast feedback
Staging: Integration tests + security scans
Production: Full test suite + approval gates
```

**Integration**: Environment-awareness rule checks `.add/env/` configs; quality-gates rule adapts per tier.

---

#### **Feature: Structured Project Initialization**

**Description**: `/add:init` command sets up project structure, rules, and conventions.

**Components**:
- `.add/config.json`: Project metadata (name, tier, rules, team)
- `.add/settings.json`: Team conventions (code style, test framework, etc.)
- `.add/learnings/library.json`: Persistent patterns learned on project
- `.claude-plugin/` rules autoload in project context

**Why it matters**: No manual setup. Conventions are enforced from project start.

**Example**:
```
$ /add:init
? Project name: dossierFYI
? Environment tier: Tier 1 (local only)
? Rules to enable: [all defaults]
? Test framework: pytest

→ Creates .add/config.json, .add/settings.json, rules autoload
→ Ready to start spec-driven development
```

**Integration**: Source-control rule ensures `.add/` is git-committed; project-structure rule validates layout.

---

#### **Feature: Learning System**

**Description**: Agents automatically checkpoint learnings during development; humans reflect during retros. Learnings persist across projects.

**Components**:
- Agent auto-checkpoints: During /add:away//add:back, /add:retro, on spec approval
- Learnings template: Structured format (decision, rationale, context, pattern, reusability)
- Learnings library: Project-level + user-level (machine-local)
- Cross-project search: Find similar patterns across projects

**Why it matters**: Prevents repeating mistakes. Builds institutional knowledge.

**Example**:
```
Project dossierFYI:
- Learning: "PostgreSQL UUID columns must be type uuid, not text"
  Context: dossierFYI database schema
  Reusability: HIGH (all SQL projects)

Later, on project X:
- Agent searches learnings: "uuid column"
- Finds dossierFYI pattern, applies it automatically
```

**Integration**: Learning rule enforces retro-based reflection; project-structure rule persists learnings.

---

#### **Feature: Quality Gates**

**Description**: 5 checkpoints ensure code quality before merge/deploy.

| Gate | Trigger | Checks | Enforcer |
|------|---------|--------|----------|
| **Pre-commit** | Before Write/Edit auto-lint hook | Lint, type check | Auto (hooks) |
| **Pre-push** | Before git push | All tests pass | Manual (human review required) |
| **CI** | On push to main | Full test suite + security scan | GitHub Actions (v1.0.0) |
| **Pre-deploy** | Before deploy to prod | Regression tests + approval | Manual (deployment skill) |
| **Post-deploy** | After deploy to prod | Smoke tests + monitoring | Manual (deployment skill) |

**Why it matters**: Catches bugs early. Ensures prod stability.

**Example**:
```
1. Agent implements feature
2. Pre-commit gate: Lint + type checks (auto, must pass)
3. Human pushes to main
4. Pre-push gate: Requires manual review + test sign-off
5. CI gate: Full test suite (GitHub Actions)
6. If deploying to prod: Pre-deploy gate (approval required)
```

---

#### **Feature: Non-Greenfield Adoption (/add:init --adopt)**

**Description**: Make ADD accessible to existing projects via gradual adoption.

**Components** (v0.2.0):
- Adoption detection: Scan project structure, identify test framework, linter, etc.
- Gradual enablement: Start with "monitoring" mode, gradually adopt rules
- Legacy compatibility: Map existing conventions to ADD templates
- Migration guide: Walk team through adoption process

**Why it matters**: Lowers barrier to entry. Existing projects can adopt without massive refactor.

**Example**:
```
$ /add:init --adopt
? Detected test framework: pytest ✓
? Detected linter: black ✓
? Adopt spec-driven rule? (Recommended for new features) [Y/n]

→ Enables spec-driven rule for *new* features only
→ Existing code untouched
→ Team can gradually migrate at own pace
```

---

### 6.2 Commands (v0.1.0)

| Command | Aliases | Purpose | Output |
|---------|---------|---------|--------|
| `/add:init` | `/setup` | Initialize project with ADD infrastructure | `.add/` directory + config files |
| `/add:spec` | `/spec-interview`, `/spec-write` | Start spec-driven development workflow | PRD template → Spec template |
| `/add:away` | `/pause`, `/hands-off` | Pause agent; human takes control | Saves context checkpoint |
| `/add:back` | `/resume`, `/hands-on` | Resume agent; catch up on changes | Loads context, identifies deltas |
| `/add:retro` | `/retrospective`, `/learnings` | Team retrospective + learning capture | Learnings template + library update |
| `/add:cycle` | `/sprint`, `/plan-cycle` | Plan and execute a work cycle | `.add/cycles/cycle-{N}.md` |

---

### 6.3 Skills (v0.1.0)

| Skill | Triggers | Input | Output | Integration |
|-------|----------|-------|--------|-------------|
| `tdd-cycle` | Manual + `/add:spec` approval | Spec | Tests → Code → Verified | spec-driven, tdd-enforcement |
| `test-writer` | tdd-cycle, manual | Spec → Test framework | Test file with full coverage | tdd-enforcement, quality-gates |
| `implementer` | tdd-cycle, manual | Tests + Spec | Implementation code | tdd-enforcement, source-control |
| `reviewer` | Manual + pre-push gate | Code + Spec | Review checklist + feedback | human-collaboration, quality-gates |
| `verify` | Pre-commit, pre-push, CI, pre-deploy, post-deploy | Code + Tests | Pass/fail + coverage report | quality-gates, tdd-enforcement |
| `plan` | `/add:spec`, manual | Spec | Implementation plan + estimation | human-collaboration, learning |
| `optimize` | Manual + post-retro | Code + Learnings | Optimized code + rationale | learning, source-control |
| `deploy` | Manual | Code + Environment | Deploy to env + smoke tests | environment-awareness, quality-gates |

---

### 6.4 Rules (v0.1.0)

| Rule | Applies to | Enforces | Blockable |
|------|-----------|----------|-----------|
| `spec-driven` | All code commits | Implementation must reference approved spec section | Yes (pre-commit) |
| `tdd-enforcement` | All code commits | Tests must exist before code; 80%+ coverage required | Yes (pre-commit) |
| `human-collaboration` | All decisions | Architectural/design decisions require human sign-off | Yes (manual) |
| `agent-coordination` | All agent outputs | Agent actions logged; human can pause with /add:away | Yes (/add:away) |
| `source-control` | Project init + commits | `.add/` directory always committed; clean commit messages | Yes (pre-push) |
| `environment-awareness` | Deployment | Code built/tested for target environment | Yes (pre-deploy) |
| `quality-gates` | All commits + deploys | 5-gate enforcement (pre-commit → post-deploy) | Yes (all gates) |
| `learning` | Specs, /add:away, /add:back, /add:retro | Decisions logged; patterns captured; learnings persist | No (auto-logging) |
| `project-structure` | Project init | Consistent `.add/` layout; templates valid | Yes (init) |
| `maturity-lifecycle` | All ADD behavior | Cascades maturity level into process rigor, quality gates, parallelism | Yes (all rules) |

---

### 6.5 Templates (v0.1.0)

| Template | Purpose | Sections | Reusable |
|----------|---------|----------|----------|
| `PRD.md` | Product requirements | Problem, users, success metrics, scope, architecture, features, NFRs, questions, history | Yes (all projects) |
| `spec.md` | Feature specification | Overview, requirements, test cases, edge cases, architecture, success criteria | Yes (all features) |
| `plan.md` | Implementation plan | Milestones, tasks, estimation, risks, success criteria | Yes (all features) |
| `config.json` | Project metadata | name, tier, rules, team, repo, contact | Project-specific |
| `settings.json` | Team conventions | test-framework, linter, code-style, doc-format | Reusable (team profile) |
| `CLAUDE.md` | Agent guidelines | Context, rules, conventions, tools, knowledge cutoffs | Reusable (team profile) |
| `learnings.md` | Captured pattern | Decision, context, rationale, pattern, reusability | Global (library) |
| `profile.json` | Team conventions + learnings | Bundled settings.json + learnings.json for easy adoption | Reusable (profiles) |
| `library.json` | Learnings index | Index of all learnings (tags, search metadata) | Global (org-wide) |
| `milestone.md` | Milestone tracking | Goal, features, hill chart, cycles, retrospective | Yes (all projects) |

---

## 7. Non-Functional Requirements

### 7.1 Performance

- **Init time**: < 1 second (JSON reads + template setup)
- **Spec interview**: < 30 seconds per response (conversational flow)
- **Plan generation**: < 2 minutes (estimation + task breakdown)
- **Verify gate**: < 5 seconds (lint + type check)
- **Learning search**: < 2 seconds (library scan)

### 7.2 Reliability

- **Plugin crash rate**: < 0.1% (pure markdown/JSON, no runtime errors)
- **Lost context**: 0% (all state in git-committed `.add/` + `~/.claude/add/`)
- **Command availability**: 99.9% (no external dependencies)

### 7.3 Maintainability

- **Code-free design**: No compiled code, no runtime dependencies, pure markdown + JSON
- **Template portability**: All templates use {PLACEHOLDER} syntax (portable across projects)
- **Version compatibility**: Backward-compatible minor versions; migration guide for major versions
- **Documentation**: README + getting started guide + per-command docs

### 7.4 Security

- **Secrets handling**: No secrets stored in templates; environment variables for sensitive data
- **Access control**: Project rules can restrict who can approve specs/plans (v1.0.0)
- **Audit trail**: All decisions logged in `.add/` (git history = audit log)

### 7.5 Scalability

- **Team size**: 1-100+ engineers (no backend bottleneck)
- **Project count**: Unlimited (each project is independent `.add/` directory)
- **Learnings library**: 1000+ entries searchable (JSON scan, < 2s)

### 7.6 Usability

- **Onboarding**: First spec written in < 5 minutes (guided /add:spec command)
- **Commands**: ≤ 5 top-level commands; all have aliases
- **Error messages**: Clear, actionable (e.g., "spec-driven rule: Implementation must reference spec section; missing reference to spec.md#3.2")

---

### 6.6 Maturity Lifecycle (v0.1.0)

ADD projects declare a maturity level that governs all process rigor:

| Level | PRD | Specs | TDD | Quality Gates | Parallel Agents | Cycle Planning |
|-------|-----|-------|-----|---------------|-----------------|----------------|
| **poc** | Paragraph | Optional | Optional | Pre-commit only | 1 (serial) | Informal |
| **alpha** | 1-pager | Critical paths | Critical paths | Pre-commit + CI | 1-2 | Brief doc |
| **beta** | Full template | Required | Enforced | Pre-commit + CI + pre-deploy | 2-4 | Full plan |
| **ga** | Full + architecture | Required + acceptance criteria | Strict | All 5 levels | 3-5 (worktrees) | Full + risk assessment |

Maturity promotion is deliberate — triggered via `/add:cycle --complete` or `/add:retro` with gap analysis showing readiness for the next level.

---

## 8. Open Questions

| Question | Impact | Status | Owner |
|----------|--------|--------|-------|
| Should learnings auto-sync between user-level (~/.claude/add/) and project-level (.add/)? Or manual sync via command? | System design | v0.2.0 | abrooke |
| What's the minimum viable CI/CD integration? (GitHub Actions lint only? Full test suite?) | v1.0.0 scope | v1.0.0 | abrooke |
| Should quality gates support "override" with human approval (e.g., skip test for urgent hotfix)? | Security/agility tradeoff | Decision pending | abrooke |
| How to make /add:init --adopt work for truly alien project structures (e.g., monorepos, multilang)? | Adoption complexity | v0.2.0+ | abrooke |
| Should profiles be versioned? (e.g., "use Profile v2.0 on this project") | Long-term maintainability | v1.0.0 | abrooke |
| Multi-agent coordination: How do agents coordinate across multiple concurrent specs/plans? | Future roadmap | **Addressed in v0.1.0** — swarm coordination protocol in agent-coordination rule + /add:cycle command | abrooke |
| Context window optimization: 10 autoloaded rules consume ~14K tokens (7% of 200K). Should heavy rules (agent-coordination, maturity-lifecycle) use conditional loading or progressive disclosure? | Performance | v0.2.0 — dog-food first, optimize based on real usage patterns | abrooke |
| Cowork vs Claude Code interplay: How should ADD bridge Cowork (human decisions, reviews) and Claude Code (agent execution, TDD)? Shared state via .add/ directory? | Architecture | v0.2.0 | abrooke |

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-02-07 | abrooke | Initial PRD; describes v0.1.0 (complete) + v0.2.0 + v1.0.0 roadmap |
| 0.2 | 2026-02-07 | abrooke | Added maturity lifecycle, work hierarchy (roadmap→milestone→cycle→execution), swarm coordination, /add:cycle command |

---

## Appendix A: Dog-Fooding This PRD

This PRD was created *using* ADD methodology:

1. **Spec-driven**: This document is the PRD for the ADD plugin. It's the single source of truth for requirements.
2. **Test-before-impl**: Test cases (e.g., "v0.1.0 should have 5 commands") are embedded in scope section; implementations verified against them.
3. **Trust but verify**: Human (abrooke) approved problem statement; agent (Claude) refined architecture/features; human reviewed final PRD.
4. **Structured collaboration**: PRD created via /add:spec workflow (hypothetically, once plugin is live).
5. **Environment awareness**: Tier 1 environment appropriate (plugin = markdown/JSON, no backend).
6. **Continuous learning**: Learnings from building ADD will be captured in `/add:retro` and applied to v0.2.0.

---

## Appendix B: Success Criteria for v0.1.0 Completion

- ✓ 5 commands implemented and working
- ✓ 8 skills implemented and composable
- ✓ 9 rules enforcing ADD principles
- ✓ 9 templates available for all core artifacts
- ✓ 1 hooks file (auto-lint on Write/Edit)
- ✓ 2 manifests (plugin.json, marketplace.json) valid for Claude Code
- ✓ Dogfooding on dossierFYI project (real project uses ADD for development)
- ✓ This PRD published and approved

---

## Appendix C: Glossary

| Term | Definition |
|------|-----------|
| **ADD** | Agent Driven Development—structured SDLC methodology for AI-native teams |
| **Agent** | Claude (or other AI assistant) running under ADD rules + skills |
| **Engagement mode** | Structured interaction pattern (spec-interview, quick-check, decision-point, review-gate, status-pulse) |
| **Quality gate** | Checkpoint that must pass before code advances (pre-commit, pre-push, CI, pre-deploy, post-deploy) |
| **Rule** | Declarative constraint enforced by plugin (e.g., spec-driven, tdd-enforcement) |
| **Skill** | Reusable SDLC workflow (e.g., tdd-cycle, plan, verify) |
| **Tier** | Environment context (Tier 1 = local, Tier 2 = local+prod, Tier 3 = full pipeline) |
| **Dogfooding** | Using ADD on real projects (e.g., dossierFYI) to validate design |
| **Learning** | Captured pattern/decision + metadata; persists in library |
| **Profile** | Bundled team conventions + learnings for easy adoption |

---

**END OF DOCUMENT**

# ADD Distribution & Launch Plan

## Overview

Goal: Establish ADD (Agent Driven Development) as THE authoritative methodology for AI-agent-driven software development. Free plugin on GitHub, authoritative website at getADD.dev.

---

## Phase 1: Foundation (Do Now)

### Domain & Hosting
- [ ] Configure DNS for **getADD.dev** → GitHub Pages:
  - A records: @ → 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153
  - CNAME: www → mountainunicorn.github.io
- [ ] Set custom domain in GitHub repo settings (Settings → Pages → Custom domain → getadd.dev)
- [ ] Add `website/CNAME` file containing `getadd.dev`
- [ ] Verify domain in GitHub account settings (prevent takeover)
- [ ] Enable "Enforce HTTPS" once DNS propagates
- [ ] Verify site loads at https://getadd.dev

### GitHub Repository
- [x] Push MountainUnicorn/add to GitHub (public)
- [x] Set repo description: "ADD — Agent Driven Development. Coordinated AI agent teams that ship verified software. Free Claude Code plugin."
- [x] Add topics: `claude-code`, `plugin`, `agent-driven-development`, `ai-agents`, `tdd`, `sdlc`, `methodology`, `multi-agent`, `spec-driven`, `trust-but-verify`
- [x] Set website URL to https://getadd.dev
- [x] Add MIT LICENSE file (done in v0.2.0)
- [x] Create CONTRIBUTING.md
- [x] Create initial GitHub Release (v0.2.0) with release notes
- [x] Create issue templates (bug report, feature request)
- [x] Create pull request template
- [x] Enrich plugin.json with homepage, author URL, expanded keywords
- [x] Enrich marketplace.json with metadata, homepage, keywords, tags

### Plugin Registries
- [x] Submit to **Anthropic's official plugin directory** via submission form: https://clau.de/plugin-directory-submission (submitted 2026-02-14, awaiting review)
- [ ] **claude-plugins.dev** — Community index that appears to auto-discover from official directory and GitHub. No direct submission form. Should index ADD automatically once listed officially.
- [ ] **claudemarketplaces.com** — Aggregator that indexes marketplace repos. Should discover MountainUnicorn/add automatically as it gains GitHub visibility.
- [x] Verify self-hosted marketplace install works: `/plugin marketplace add MountainUnicorn/add` → `/plugin install add@add-marketplace`

**Note:** Claude Code plugins do NOT use npm for distribution. They use git repositories. The npm distribution item in Phase 4 should be removed.

---

## Phase 2: Launch Week

### Community Announcements
- [ ] **Hacker News** — "Show HN: ADD — Agent Driven Development for Claude Code" (post at 12:01am PT for max visibility)
- [ ] **Reddit r/ClaudeAI** — Demo post with screenshots/walkthrough
- [ ] **Reddit r/artificial** — Methodology discussion angle
- [ ] **Product Hunt** — Full launch (12:01am PT, prepare tagline + images + demo)
- [ ] **LinkedIn** — Thought leadership post: "Why we need a methodology for AI-agent development"
- [ ] **dev.to** — First article: "Introducing ADD: Agent Driven Development"

### Awesome Lists (Submit PRs)
- [x] [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — 23.7k stars, submitted via issue template (issues/723, 2026-02-14)
- [x] [jqueryscript/awesome-claude-code](https://github.com/jqueryscript/awesome-claude-code) — PR #35 submitted (2026-02-14)
- [ ] [awesomeclaude.ai](https://awesomeclaude.ai/) — visual directory
- [x] [tonysurfly/awesome-claude](https://github.com/tonysurfly/awesome-claude) — PR #41 submitted (2026-02-14)
- [x] [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) — 34.8k stars, PR #208 with SKILL.md submitted (2026-02-14)

### AI Tool Directories
- [ ] [There's An AI For That](https://theresanaiforthat.com/submit/) — highest reach, newsletter feature
- [ ] [Futurepedia](https://www.futurepedia.io/submit-tool) — first AI tool directory, 2M+ monthly visits
- [ ] [Toolify](https://www.toolify.ai/) — 28,000+ AI tools indexed

---

## Phase 3: Content Authority (Weeks 2-4)

### Website Pages to Add
- [ ] `/docs` — Full documentation (generated from README + commands + skills)
- [ ] `/what-is-add` — Deep-dive definition page (SEO target: "what is agent driven development")
- [ ] `/getting-started` — Step-by-step tutorial with screenshots
- [ ] `/best-practices` — Proven patterns from dog-fooding
- [ ] `/faq` — Common questions and misconceptions
- [ ] `/vs-vibe-coding` — Comparison page (SEO target: "agent driven development vs vibe coding")

### Content Series (dev.to / Medium)
- [ ] "Introducing ADD: A Methodology for Agent Driven Development"
- [ ] "Why Vibe Coding Needs Structure: The Case for ADD"
- [ ] "How ADD's Maturity Dial Scales from POC to GA"
- [ ] "Cross-Project Learning: How AI Agents Get Smarter Over Time"
- [ ] "Trust But Verify: Coordinating Agent Swarms in Software Development"

### Additional Directories
- [ ] [aitools.fyi](https://aitools.fyi)
- [ ] [Future Tools](https://www.futuretools.io)
- [ ] [AI Tools Directory](https://aitoolsdirectory.com)

---

## Phase 4: Growth (Month 2+)

### Community Building
- [x] Enable GitHub Discussions with categories: Q&A, Ideas, Announcements, Show and Tell
- [x] Create "good first issue" labels for community PRs (default labels already include it)
- [x] Create CONTRIBUTING.md (done 2026-02-14, at repo root)
- [x] Create `CODE_OF_CONDUCT.md`, `SECURITY.md` (done 2026-02-15)
- [x] Create issue templates — bug_report.md, feature_request.md (done 2026-02-14)
- [x] Create pull request template (done 2026-02-14)
- [ ] Monthly contributor spotlights
- [ ] Engage consistently on r/ClaudeAI answering agent-related questions

### Authority Signals
- [ ] Case studies from real projects using ADD
- [ ] Video content: YouTube intro (3-5 min), tutorial series
- [ ] Guest posts on AI/dev blogs
- [ ] Conference talk submissions (if opportunities arise)
- [ ] Formal ADD methodology specification document

### SEO Targets
- Primary: "agent driven development", "ADD methodology", "claude code plugin"
- Secondary: "AI agent methodology", "agentic development", "structured agent development"
- Long-tail: "how to structure AI agent development", "TDD for AI agents"

---

## Key URLs

| Resource | URL |
|----------|-----|
| Website | https://getadd.dev |
| GitHub | https://github.com/MountainUnicorn/add |
| Plugin Install | `claude plugin install add` |
| Anthropic Registry | https://github.com/anthropics/claude-plugins-official |
| Community Registry | https://claude-plugins.dev |
| Product Hunt | https://www.producthunt.com/ (create listing) |
| Hacker News | https://news.ycombinator.com/submit |
| dev.to | https://dev.to/ (create account) |
| There's An AI For That | https://theresanaiforthat.com/submit/ |
| Futurepedia | https://www.futurepedia.io/submit-tool |

---

## Success Metrics

| Timeframe | Metric | Target |
|-----------|--------|--------|
| Week 1 | GitHub stars | 50+ |
| Week 1 | Plugin installs | 25+ |
| Month 1 | GitHub stars | 250+ |
| Month 1 | Hacker News front page | 1 appearance |
| Month 3 | GitHub stars | 1,000+ |
| Month 3 | Google ranking for "agent driven development" | Top 5 |
| Month 6 | Referenced in external articles/talks | 5+ |

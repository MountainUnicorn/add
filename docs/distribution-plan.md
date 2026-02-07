# ADD Distribution & Launch Plan

## Overview

Goal: Establish ADD (Agent Driven Development) as THE authoritative methodology for AI-agent-driven software development. Free plugin on GitHub, authoritative website at getADD.dev.

---

## Phase 1: Foundation (Do Now)

### Domain & Hosting
- [ ] Register **getADD.dev** (Cloudflare Registrar recommended — at-cost ~$12/year, free WHOIS privacy, DNSSEC)
- [ ] Deploy website/index.html to Cloudflare Pages (free tier, auto-deploy from GitHub)
- [ ] Set up DNS: getADD.dev → Cloudflare Pages

### GitHub Repository
- [ ] Push MountainUnicorn/add to GitHub (public)
- [ ] Set repo description: "ADD — Agent Driven Development. Coordinated AI agent teams that ship verified software. Free Claude Code plugin."
- [ ] Add topics: `claude-code`, `plugin`, `agent-driven-development`, `ai-agents`, `tdd`, `sdlc`, `methodology`
- [ ] Set website URL to https://getadd.dev
- [ ] Add MIT LICENSE file
- [ ] Create CONTRIBUTING.md
- [ ] Create initial GitHub Release (v0.1.0) with changelog

### Plugin Registries
- [ ] Submit to **Anthropic's official plugin registry**: PR to [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- [ ] Register on **claude-plugins.dev** (community registry)
- [ ] Verify `claude plugin install add` works from the marketplace

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
- [ ] [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — largest, most relevant
- [ ] [jqueryscript/awesome-claude-code](https://github.com/jqueryscript/awesome-claude-code)
- [ ] [awesomeclaude.ai](https://awesomeclaude.ai/) — visual directory
- [ ] [tonysurfly/awesome-claude](https://github.com/tonysurfly/awesome-claude) — general Claude ecosystem
- [ ] [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)

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

### npm Distribution
- [ ] Publish to npm as `claude-plugin-add` with keywords
- [ ] Create package.json with proper metadata
- [ ] Set up automated releases via GitHub Actions

### Community Building
- [ ] Create "good first issue" labels for community PRs
- [ ] Monthly contributor spotlights
- [ ] Discord or GitHub Discussions for community support
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

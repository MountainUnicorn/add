---
description: "Design system for visual artifacts — loads full reference on demand"
maturity: ga
globs: ["docs/infographic.svg", "reports/*.html"]
---

# ADD Rule: Design System

Visual artifacts (SVG infographics, HTML dashboards, brand materials) follow the ADD design system.

**This rule is intentionally minimal.** Full design system reference (color palette, typography, glassmorphism, SVG rules, HTML structure) lives at `${CLAUDE_PLUGIN_ROOT}/references/design-system.md` and is loaded on demand by visual skills.

## Core Principles

- Read accent color from `.add/config.json` → `branding.palette` before generating any visual
- Default palette: #b00149 → #d4326d → #ff6b9d (ADD raspberry)
- Inline styles only for SVG (GitHub strips `<style>` tags)
- System fonts only (no web fonts)
- Maturity scales complexity: POC=minimal, Alpha/Beta=standard, GA=premium

## When to Load Full Reference

Skills that generate visual output MUST read `${CLAUDE_PLUGIN_ROOT}/references/design-system.md` before rendering. This includes `/add:infographic`, `/add:dashboard`, `/add:brand-update`, and `/add:ux`.

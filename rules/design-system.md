---
description: "Design system for visual artifacts — Silicon Valley Unicorn aesthetic adapted for ADD with raspberry branding"
globs: ["docs/infographic.svg", "reports/*.html"]
---

# Design System Rule

## Core Philosophy

**Value Over Features**
- Headlines describe outcomes, not capabilities
- "Ship Features in Hours" not "Fast Development Workflow"
- "Zero Production Incidents" not "Quality Gate System"
- Confident, aspirational language
- Premium visual design that signals quality

## Color Palette

### Dynamic Branding
Always read the accent color from `.add/config.json` → `branding.palette`:
```json
{
  "branding": {
    "palette": ["#b00149", "#d4326d", "#ff6b9d"]
  }
}
```

If no config exists, default to ADD's raspberry palette.

### Color System
- **Background Gradients**: #1a1a2e → #16213e → #0f0f23 (dark, sophisticated)
- **Accent Gradient**: Use branding palette array (3 stops: primary → mid → light)
  - Default (ADD raspberry): #b00149 → #d4326d → #ff6b9d
- **Success States**: #22c55e → #10b981
- **Text Primary**: #ffffff (pure white)
- **Text Secondary**: rgba(255,255,255,0.6) (60% white)
- **Text Muted**: rgba(255,255,255,0.3) (30% white)
- **Card Backgrounds**: rgba(255,255,255,0.08) → rgba(255,255,255,0.02)
- **Borders**: rgba(255,255,255,0.1)

## Typography

### Font Stacks
- **Body/UI**: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
- **Code**: "SF Mono", Monaco, "Cascadia Code", "Roboto Mono", monospace

### Type Scale
- **Hero Headlines**: 56px, weight 700, letter-spacing -2px
- **Section Headlines**: 36px, weight 700, letter-spacing -1px
- **Subheadlines**: 20px, weight 600
- **Body Text**: 14-16px, weight 400, line-height 1.6
- **Eyebrow Labels**: 14px, weight 600, letter-spacing 2px, uppercase
- **Metrics**: 28px, weight 700
- **Code**: 14px, monospace

### Text Rendering
- Use `dominant-baseline="middle"` for vertical centering
- Use `text-anchor="middle"` for horizontal centering
- Body text gets `text-anchor="start"`

## Glassmorphism

### Card Style
```svg
<rect rx="16"
      fill="url(#cardGradient)"
      stroke="rgba(255,255,255,0.08)"
      stroke-width="1"
      filter="url(#cardShadow)" />

<defs>
  <linearGradient id="cardGradient" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="rgba(255,255,255,0.08)" />
    <stop offset="100%" stop-color="rgba(255,255,255,0.02)" />
  </linearGradient>
  <filter id="cardShadow">
    <feDropShadow dx="0" dy="4" stdDeviation="4" flood-opacity="0.3" />
  </filter>
</defs>
```

### Visual Properties
- Corner radius: 16px (rx=16)
- Subtle gradient from 8% to 2% white
- 1px stroke at 8% white
- Drop shadow: 4px offset, 4px blur, 30% opacity
- Backdrop blur effect simulated via gradient

## Information Hierarchy

### Standard Layout Flow
1. **HERO** (y=0-200): Project name, tagline, key value prop
2. **METRICS** (y=240-400): 3-4 key numbers in horizontal row
3. **WORKFLOW** (y=440-700): Primary process diagram or timeline
4. **VALUE CARDS** (y=740-1100): 2-3 feature/benefit cards
5. **TERMINAL** (y=1140-1360): Code example or command preview
6. **FOOTER** (y=1400+): Powered by ADD, learn more link

### Spacing System
- Section gap: 40px minimum
- Card padding: 32px
- Metric spacing: 80px between items
- Text line-height: 1.6 for body, 1.2 for headlines

## SVG Rules

### GitHub Compatibility
- **Inline styles only** — GitHub strips `<style>` tags
- **System fonts** — No web fonts (GitHub blocks external resources)
- **No foreignObject** — Not reliably supported
- **viewBox standard**: 1200 width, height varies (typically 1400-1800)
- **Gradients/filters in defs** — Define once, reference via url(#id)

### SVG Structure
```svg
<svg viewBox="0 0 1200 1600" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- All gradients, filters, patterns here -->
  </defs>

  <!-- Background -->
  <rect width="1200" height="1600" fill="url(#bgGradient)" />

  <!-- Content sections (use <g> with transform for positioning) -->
  <g transform="translate(0, 0)"><!-- HERO --></g>
  <g transform="translate(0, 240)"><!-- METRICS --></g>
  <!-- etc -->
</svg>
```

### Text Handling
- Break long text into multiple `<tspan>` elements with dy offsets
- Use `<tspan x="600" dy="24">` for multi-line centered text
- Use `<tspan x="100" dy="24">` for left-aligned lists
- Reset x position on each new line

## Branding Integration

### Reading Config
Before generating any visual artifact, read `.add/config.json`:
```javascript
const config = JSON.parse(fs.readFileSync('.add/config.json'));
const palette = config.branding?.palette || ['#b00149', '#d4326d', '#ff6b9d'];
```

### Applying Accent Colors
```svg
<defs>
  <linearGradient id="accentGradient" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%" stop-color="${palette[0]}" />
    <stop offset="50%" stop-color="${palette[1]}" />
    <stop offset="100%" stop-color="${palette[2]}" />
  </linearGradient>
</defs>

<!-- Use on headlines, icons, key metrics -->
<text fill="url(#accentGradient)">Hero Headline</text>
```

### Branding Command
Generate infographics via `/add:infographic` (applies design system automatically).
Update branding via `/add:brand` (modifies config, regenerates artifacts).

## Maturity Awareness

### POC (Proof of Concept)
- Simpler infographic: HERO + METRICS + WORKFLOW only
- 2-3 metrics maximum
- Basic workflow diagram
- Total height ~900px
- Faster generation, less detail

### Alpha/Beta
- Standard full layout
- 3-4 metrics
- Full workflow + 2 value cards
- Terminal example
- Total height ~1400-1600px

### GA (General Availability)
- Premium treatment
- 4 metrics
- Detailed workflow
- 3 value cards with icons
- Terminal with syntax highlighting
- Footer with badges/links
- Total height ~1600-1800px

## HTML Reports

### Structure
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    /* Inline CSS — same color system as SVG */
    body { background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f0f23 100%); }
    .card { background: linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0.02)); }
  </style>
</head>
<body>
  <header><!-- Hero --></header>
  <section class="metrics"><!-- Key numbers --></section>
  <section class="details"><!-- Content cards --></section>
  <footer><!-- ADD branding --></footer>
</body>
</html>
```

### CSS System
- Use CSS custom properties for branding colors
- Responsive breakpoints: 768px, 1024px, 1440px
- Grid layout for metrics (repeat(auto-fit, minmax(200px, 1fr)))
- Flexbox for card internals
- Smooth transitions on hover (0.2s ease)

## Usage Examples

### Command Usage
```bash
# Generate infographic for project
/add:infographic

# Update branding colors
/add:brand

# Regenerate all visual artifacts after branding change
/add:infographic && npm run build:reports
```

### When to Apply
- **Automatically**: All generated SVG/HTML artifacts use this system
- **Manual review**: If user provides custom design, ask before overwriting
- **Consistency**: All visuals in one project should use same palette
- **Cross-project**: Each project's config controls its palette

## Quality Checklist

Before finalizing any visual artifact:
- [ ] Accent colors loaded from `.add/config.json`
- [ ] All gradients defined in `<defs>` block
- [ ] Text uses system fonts only
- [ ] No `<style>` tags (inline only for GitHub)
- [ ] viewBox dimensions match background rect
- [ ] Spacing follows 40px section gap rule
- [ ] Typography scale adhered to
- [ ] Glassmorphic cards use standard filter/gradient
- [ ] Maturity level appropriate complexity
- [ ] Passes GitHub rendering test (no stripped elements)

---

**Design Philosophy**: Confidence. Clarity. Premium quality. Every pixel reinforces that ADD is the methodology for serious teams shipping serious products.

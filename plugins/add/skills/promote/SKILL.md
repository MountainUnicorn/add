---
description: "[ADD v0.9.3] Maturity promotion — gap analysis and level-up workflow"
argument-hint: "[--check | --execute] [--target poc|alpha|beta|ga]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Task, TodoWrite]
references: ["rules/telemetry.md"]
---

# ADD Promote Command v0.9.3

Assess readiness and promote the project's maturity level. Maturity is the master control for all ADD behavior — promotion is intentional, evidence-based, and deliberate.

- **`--check`** (default) — Gap analysis: scan evidence against next level's requirements
- **`--execute`** — Gap analysis + promotion interview + apply level change

---

## Pre-Flight

1. **Read `.add/config.json`** — extract `maturity.level`, `promoted_from`, `promoted_date`, `next_promotion_criteria`
   - If not found: abort with "No ADD project found. Run `/add:init` first."
2. **Read `${CLAUDE_PLUGIN_ROOT}/rules/maturity-lifecycle.md`** — load cascade matrix (source of truth for level requirements)
3. **Read `docs/prd.md`** — project context, maturity references
4. **Read `CLAUDE.md`** — check for maturity references

### Edge Cases

**Already at GA:**
"Project is at GA — the highest maturity level. No further promotion available. Run `/add:verify` to check compliance."

**`--target` below current level:** Trigger demotion flow (see below).

**`--target` skips a level** (e.g., poc → beta):
"Cannot skip levels. Progression is sequential: poc → alpha → beta → ga. Next available: {next_level}."

**No `--target`:** Default to next level in sequence.

---

## Command: /promote --check (default)

Scan project evidence and present readiness report. No file modifications.

### Step 1: Determine Target

```
Current maturity: {CURRENT}
Assessing readiness for: {TARGET}
```

### Step 2: Evidence Scan

Use Glob, Grep, Bash, Read to gather real data across these categories:

| # | Category | How to Check |
|---|----------|-------------|
| 1 | Feature specs | Glob `specs/*.md`, count files, check for acceptance criteria |
| 2 | Test coverage | Run test command from config `quality.test.unit` with coverage flag. If no test command configured, score as MISSING. If command fails, score as PARTIAL and note the error. |
| 3 | CI/CD pipeline | Glob `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile` |
| 4 | PR workflow | `git log --merges --oneline -20` — check for merge commits |
| 5 | Environments | Read config `environments` — count tiers with non-null URLs |
| 6 | Conventional commits | `git log --oneline -20` — check `feat:/fix:/docs:` compliance % |
| 7 | TDD evidence | Compare test vs implementation file timestamps |
| 8 | Branch protection | Check `.github/settings.yml` or `gh api` if available |
| 9 | Release tags | `git tag -l 'v*'` — check for semver tags |
| 10 | Quality gates | Check `.pre-commit-config.yaml`, `.husky/`, CI check configs |
| 11 | Milestones completed | Glob `docs/milestones/*.md` — count COMPLETE milestones |
| 12 | Learnings captured | Read `.add/learnings.json` — count entries |
| 13 | PRD depth | Read `docs/prd.md` — assess completeness for target level |
| 14 | Stability | `git log --since="30 days ago" --oneline` — check for hotfix-free stability |

### Step 3: Score Readiness

Map evidence to target level requirements. Each category gets a status:

| Status | Icon | Meaning |
|--------|------|---------|
| READY | ✅ | Meets target requirement |
| PARTIAL | ⚠️ | Some evidence, incomplete |
| MISSING | ❌ | Required but not found |
| N/A | — | Not required at target level |

**Thresholds:**
- **POC → Alpha:** 3+ READY (specs for critical paths, some tests, basic quality gates)
- **Alpha → Beta:** 6+ READY (specs, 50%+ coverage, CI, PR workflow, conventional commits, TDD)
- **Beta → GA:** 9+ READY (80%+ coverage, protected branches, release tags, 3+ envs, 30-day stability)

**Readiness %:** (READY count / required count for target) × 100

### Step 4: Present Report

```
╔══════════════════════════════════════════╗
  MATURITY READINESS: {CURRENT} → {TARGET}
╚══════════════════════════════════════════╝

Readiness: {PCT}% ({READY}/{REQUIRED} requirements met)

| # | Requirement | Status | Detail |
|---|-------------|--------|--------|
| 1 | Feature specs | ✅ | 8 specs in specs/ |
| 2 | Test coverage ≥ {THR}% | ⚠️ | Current: 47% |
| 3 | CI/CD pipeline | ✅ | GitHub Actions configured |
| ... | ... | ... | ... |

═══ CASCADE CHANGES AT {TARGET} ═══

| Dimension | Current ({CURRENT}) | After ({TARGET}) |
|-----------|--------------------|--------------------|
| Specs Required | {current} | {new} |
| TDD Enforced | {current} | {new} |
| Quality Gates | {current} | {new} |
| Parallel Agents | {current} | {new} |
| ... | ... | ... |

═══ RECOMMENDATION ═══

{≥80%: "READY TO PROMOTE — Run /add:promote --execute"}
{50-79%: "ADDRESS GAPS FIRST" + list top gaps + remediation}
{<50%: "NOT READY" + list critical gaps}
```

---

## Command: /promote --execute

Full promotion: gap analysis → gate → interview → apply.

### Step 1: Run Gap Analysis

Execute the full `--check` flow above. Present the report.

### Step 2: Gate Decision

**≥80% readiness:** Proceed to interview.

**50-79% readiness:**
```
Readiness: {PCT}% — below recommended threshold (80%).

Gaps: {list}

Options:
  1. Proceed anyway (gaps tracked as tech debt)
  2. Cancel and address gaps first
  3. Create a promotion milestone to close gaps systematically
```
AskUserQuestion. Option 1 proceeds with override flag. Option 2 exits. Option 3 suggests `/add:milestone --create`.

**<50% readiness:** Block promotion.
```
Readiness: {PCT}% — significant gaps remain.
Address critical items first, then re-run /add:promote --check.
```
Exit. No override offered — premature promotion cascades strict requirements the project can't meet.

### Step 3: Promotion Interview (3 questions)

**Q1:** "What drove this promotion? What evidence or milestone makes now the right time?"
→ Rationale for changelog and learnings

**Q2:** "Any areas to temporarily exempt from the new requirements? (e.g., specific quality checks)"
→ Default: "No exemptions." If provided, note they should be time-boxed.

**Q3 (if not promoting to GA):** "What should the criteria be for the NEXT promotion ({next_next_level})?"
**Q3 (if promoting to GA):** "What are your GA stability and SLA commitments?"
→ Stored as `next_promotion_criteria`

### Step 4: Apply Promotion

#### 4a. Update `.add/config.json`

```json
{
  "maturity": {
    "level": "{TARGET}",
    "promoted_from": "{CURRENT}",
    "promoted_date": "{YYYY-MM-DD}",
    "next_promotion_criteria": "{Q3 answer}",
    "exemptions": ["{Q2 answers or empty}"]
  }
}
```

Also update maturity-dependent config:
- `planning.wip_limit` — per cascade matrix
- `planning.parallel_agents` — per cascade matrix
- `quality.coverage_threshold` — if target requires higher
- `quality.mode` — tighten for beta/ga

#### 4b. Update `docs/prd.md`

Search for maturity references (grep for current level name), update to new level. Update any "Current Maturity:" lines in Section 6.

#### 4c. Update `CLAUDE.md`

Grep for current level name in project CLAUDE.md, update references.

#### 4d. Apply Cascade Changes

The cascade is mostly automatic via the maturity-loader rule reading the updated config. But explicitly update config thresholds that aren't purely rule-driven:

| Transition | Key Config Changes |
|-----------|-------------------|
| POC → Alpha | Enable conventional commits, spec-driven quality |
| Alpha → Beta | Stricter quality thresholds, TDD enforcement, PR review |
| Beta → GA | All checks blocking, 2 reviewers, protected branches, release tags |

#### 4e. Changelog Entry

Append to `CHANGELOG.md` under `[Unreleased]`:
```markdown
### Changed
- Maturity promoted from {CURRENT} to {TARGET} ({DATE})
  - Readiness: {PCT}%, Rationale: {Q1 summary}
```

If `CHANGELOG.md` doesn't exist, create from `${CLAUDE_PLUGIN_ROOT}/templates/changelog.md.template`.

#### 4f. Learning Checkpoint

Write to `.add/learnings.json`:
```json
{
  "id": "L-{NNN}",
  "date": "{YYYY-MM-DD}",
  "checkpoint_type": "promotion",
  "category": "process",
  "scope": "project",
  "title": "Maturity promoted: {CURRENT} → {TARGET}",
  "body": "Promoted at {PCT}% readiness. Rationale: {Q1}. Exemptions: {Q2}. Next criteria: {Q3}.",
  "tags": ["maturity", "promotion", "{TARGET}"],
  "classified_by": "agent"
}
```

Regenerate `.add/learnings.md` from JSON.

### Step 5: Present Summary

```
╔══════════════════════════════════════════╗
  PROMOTED: {CURRENT} → {TARGET}
╚══════════════════════════════════════════╝

Date: {YYYY-MM-DD} | Readiness: {PCT}%

Files updated:
  ✓ .add/config.json
  ✓ docs/prd.md
  ✓ CLAUDE.md
  ✓ CHANGELOG.md
  ✓ .add/learnings.json

Key behavior changes now active:
  {3-5 most impactful cascade changes}

Next steps:
  1. Run /add:verify to confirm new quality gates pass
  2. Review cascade changes — they take effect immediately
  3. Next promotion: {NEXT_NEXT_LEVEL} — {Q3 criteria}
```

---

## Demotion Flow

Triggered when `--target` is below current level. Rare but valid — the maturity-lifecycle rule acknowledges demotion for pivots or new uncertainty.

### Step 1: Confirm Intent

```
Requesting maturity DEMOTION: {CURRENT} → {TARGET}

This relaxes quality requirements. Typically used when:
  - Major pivot introduces new uncertainty
  - Project scope changed fundamentally

Are you sure?
```

### Step 2: Brief Interview (2 questions)

**Q1:** "What changed that requires demotion?"
**Q2:** "Temporary (re-promote after exploration) or permanent reset?"

### Step 3: Apply

Same update process as promotion, but:
- Config thresholds RELAXED to match target level
- Changelog says "Demoted" not "Promoted"
- Learning checkpoint uses `checkpoint_type: "demotion"`
- If temporary: add `maturity.demotion_temporary: true`

---

## Integration

| Skill | Relationship |
|-------|-------------|
| `/add:cycle --complete` | Has its own promotion check — should reference `/add:promote --check` for full analysis |
| `/add:retro` | Phase 11 does promotion assessment — should reference `/add:promote` as canonical tool |
| `/add:verify` | Recommended post-promotion to validate new gates pass |
| `/add:init` | Sets initial maturity. Promote handles all subsequent changes. |

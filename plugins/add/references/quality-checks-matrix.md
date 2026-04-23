# Maturity-Scaled Quality Checks Reference

> Detailed check tables by maturity level. Loaded by `/add:verify` when
> running quality gates. The condensed gate levels are in `rules/quality-gates.md`.
> The maturity cascade matrix in `rules/maturity-lifecycle.md` provides the
> high-level view (rows 44-48).

## Check Categories

### 1. Code Quality

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Lint errors | Blocking | Blocking | Blocking |
| Cyclomatic complexity | — | >15 advisory | >10 blocking |
| Code duplication | — | >10 lines advisory | >6 lines blocking |
| File length | — | >500 lines advisory | >300 lines blocking |
| Function length | — | >80 lines advisory | >50 lines blocking |

### 2. Security & Vulnerability

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Secrets scan | Blocking | Blocking | Blocking |
| OWASP spot-check | Advisory | Full review advisory | Full review blocking |
| Dependency audit (known CVEs) | — | Advisory | Blocking |
| Auth pattern review | — | Advisory | Blocking |
| PII/data handling review | — | Advisory | Blocking |
| Rate limiting & secure headers | — | — | Required (blocking) |

### 3. Readability & Documentation

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Naming consistency | Advisory | Advisory | Blocking |
| Nesting depth | — | <5 levels advisory | <4 levels blocking |
| Docstrings on exports | — | Advisory | Blocking |
| Complex logic comments | — | Advisory | Blocking |
| Magic number detection | — | Advisory | Blocking |
| Module READMEs | — | — | Blocking |
| Project glossary | — | — | Blocking |

### 4. Performance

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| N+1 query detection | — | Advisory | Blocking |
| Blocking async detection | — | Advisory | Blocking |
| Bundle size check | — | Advisory | Blocking |
| Memory leak patterns | — | Advisory | Blocking |
| Performance tests | — | — | Required (blocking) |
| Response time baselines | — | — | Required (blocking) |

### 5. Repo Hygiene

| Check | Alpha | Beta | GA |
|-------|-------|------|-----|
| Branch naming convention | Advisory | Advisory | Blocking |
| .gitignore exists | Advisory | Blocking | Blocking |
| LICENSE file | — | Advisory | Blocking |
| CHANGELOG maintained | — | Advisory | Blocking |
| Dependency freshness | — | Advisory | Blocking |
| README completeness | — | Advisory | Blocking (comprehensive) |
| PR template exists | — | Advisory | Blocking |
| Stale branches | — | Advisory | Blocking (14-day limit) |

## Gate Distribution

**Gate 1 (Pre-Commit):** Code quality (lint, complexity, duplication, file/function length), secrets scan, readability (naming, nesting), branch naming

**Gate 2 (Pre-Push):** Dependency audit, OWASP review, docstrings, N+1/blocking async detection, CHANGELOG/LICENSE

**Gate 3 (CI):** Bundle size, PR template, README completeness, dependency freshness

**Gate 4 (Pre-Deploy):** Auth patterns, PII/data handling, response time baselines, stale branches

**Gate 5 (Post-Deploy):** Response times vs baselines, secure headers

## Enforcement Levels

- **Blocking**: Must pass or gate fails. Code cannot advance.
- **Advisory**: Reported as warning but does not block.
- **—**: Not performed at this maturity level.

## Configuration Overrides

Projects can override default thresholds in `.add/config.json`:

```json
{
  "qualityChecks": {
    "codeQuality": {
      "maxComplexity": 15,
      "maxDuplicationLines": 10,
      "maxFileLength": 500,
      "maxFunctionLength": 80
    },
    "security": {
      "dependencyAudit": true,
      "owaspLevel": "full"
    },
    "readability": {
      "maxNestingDepth": 5,
      "requireDocstrings": true
    },
    "performance": {
      "maxBundleSizeKb": 500,
      "responseTimeBaselineMs": 200
    },
    "repoHygiene": {
      "staleBranchDays": 14,
      "requireChangelog": true
    }
  }
}
```

When `qualityChecks` is not present, defaults from this reference apply.

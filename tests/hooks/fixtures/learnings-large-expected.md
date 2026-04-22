# Active Learnings (15 of 30)

> Pre-filtered by severity and date. Full data: `.add/learnings.json` (2 archived)

### anti-pattern
- **[critical]** Critical security flaw in auth (L-001, 2026-04-10)
  JWT tokens not expiring.
- **[high]** High cache invalidation bug (L-006, 2026-03-28)
  Stale cache served after update.
### technical
- **[critical]** Critical data loss on migration (L-002, 2026-04-05)
  Migration script drops column.
- **[high]** High DB connection leak (L-004, 2026-04-07)
  Connections not returned to pool.
- **[high]** High error handling gaps (L-008, 2026-03-20)
  Unhandled exceptions in API layer.
- **[medium]** Medium retry logic improvement (L-009, 2026-04-09)
  Exponential backoff needed.
- **[medium]** Medium logging standardization (L-010, 2026-04-06)
  Use structured JSON logging.
- **[medium]** Medium config validation (L-012, 2026-03-30)
  Validate config on startup.
- **[medium]** Medium health check endpoint (L-014, 2026-03-18)
  Add /health with DB ping.
### architecture
- **[high]** High API rate limiting needed (L-005, 2026-04-03)
  No rate limiter on public endpoints.
- **[medium]** Medium API versioning strategy (L-013, 2026-03-22)
  Use URL prefix versioning.
### performance
- **[high]** High missing index on queries (L-007, 2026-03-25)
  Full table scan on user lookup.
- **[high]** High N+1 query in list view (L-026, 2026-03-23)
  Use select_related for joins.
### process
- **[high]** High priority deploy fix (L-003, 2026-04-08)
  Smoke tests must run post-deploy.
- **[medium]** Medium test data factories (L-011, 2026-04-02)
  Use factory pattern for test fixtures.

## Index (13 more — title only, read JSON for full detail)

- [medium] L-025 technical: Medium migration rollback plan (2026-03-16)
- [medium] L-015 performance: Medium CI pipeline slow (2026-03-15)
- [medium] L-028 technical: Medium observability gaps (2026-03-14)
- [medium] L-030 technical: Medium graceful shutdown (2026-03-11)
- [medium] L-016 process: Medium feature flag cleanup (2026-03-10)
- [medium] L-017 collaboration: Medium code review checklist (2026-03-05)
- [low] L-018 process: Low documentation gaps (2026-04-04)
- [low] L-019 technical: Low naming inconsistency (2026-03-26)
- [low] L-020 technical: Low unused dependencies (2026-03-12)
- [low] L-021 collaboration: Low README outdated (2026-03-08)
- [low] L-022 process: Low test naming convention (2026-03-01)
- [low] L-027 process: Low import ordering (2026-02-28)
- [low] L-029 technical: Low dead code in utils (2026-02-20)

---
*Auto-generated. Do not edit — regenerated on each learning write.*

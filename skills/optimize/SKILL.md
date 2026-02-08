---
description: "Performance optimization pass — identify and fix bottlenecks"
argument-hint: "[--scope backend|frontend|full] [--profile-first]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task]
---

# Optimize Skill

Identify and fix performance bottlenecks. This skill profiles code to find slow operations, suggests optimizations, and implements them with test-driven discipline.

## Overview

The Optimize skill improves application performance while maintaining correctness. It:
- Profiles code to identify bottlenecks
- Quantifies performance issues
- Suggests targeted optimizations
- Implements with TDD (tests before optimization)
- Verifies improvements with measurements
- Documents optimizations for future maintainers

Performance optimization follows TDD discipline: write tests that capture performance expectations before implementing optimizations.

## Pre-Flight Checks

1. **Verify implementation exists**
   - Identify implementation files (src/, app/, etc.)
   - Verify code is in GREEN state (all tests passing)
   - Halt if tests not passing (optimize only stable code)

2. **Load configuration**
   - Read .add/config.json
   - Extract performance targets:
     - perf.pageLoadTime (e.g., < 2 seconds)
     - perf.responseTime (e.g., < 100ms)
     - perf.memoryLimit (e.g., < 50MB)
     - perf.bundleSize (e.g., < 500KB)

3. **Determine scope**
   - Use --scope flag to target: backend, frontend, or full
   - Default: full system
   - Scope guides which profiling tools to use

4. **Check for profiling data**
   - If --profile-first: profile before optimization
   - Otherwise, use existing profile if available
   - Or ask user for baseline metrics

5. **Identify profiling tools**
   - Backend: py-spy, perf, go pprof, node --prof, etc.
   - Frontend: Chrome DevTools, Lighthouse, WebPageTest
   - Database: EXPLAIN ANALYZE, pg_stat_statements, etc.

## Execution Steps

### Step 1: Baseline Profiling (if --profile-first)

Establish baseline measurements:

**For Backend (Python)**:
```bash
# Profile with py-spy
py-spy record -o profile.svg -- python -m pytest tests/

# Or use cProfile
python -m cProfile -s cumulative app.py > profile.txt

# Database queries
EXPLAIN ANALYZE SELECT ...
```

Capture metrics:
- Request/response time per endpoint
- Memory usage peak
- CPU utilization
- Database query times
- Cache hit rates

**For Frontend (JavaScript)**:
```bash
# Lighthouse CLI
npm install -g lighthouse
lighthouse https://localhost:3000 --output json --output html

# Or use Chrome DevTools
# DevTools → Performance tab → Record
```

Capture metrics:
- Page load time (FCP, LCP, FID)
- Time to Interactive (TTI)
- Cumulative Layout Shift (CLS)
- JavaScript execution time
- Network waterfall

**For Full System**:
- Run both backend and frontend profiling
- Capture end-to-end latencies

**Create Baseline Report**:
```
# Performance Baseline

## Backend Metrics
- Average response time: 250ms (target: 100ms) ⚠
- 95th percentile response: 800ms (target: 200ms) ⚠
- Peak memory: 120MB (target: 50MB) ⚠
- Database query time: 180ms average (target: 50ms) ⚠
- Cache hit rate: 62% (target: 85%) ⚠

## Frontend Metrics
- First Contentful Paint: 2.1s (target: 1.5s) ⚠
- Largest Contentful Paint: 3.2s (target: 2.5s) ⚠
- JavaScript execution: 450ms (target: 200ms) ⚠
- Bundle size: 580KB (target: 300KB) ⚠

## Identified Bottlenecks (Priority Order)
1. Database query in /api/list endpoint (180ms)
2. JavaScript bundle parsing (150ms)
3. Form validation on every keystroke (50ms)
4. Unoptimized images (120KB uncompressed)
5. Missing indexes on user lookup
```

### Step 2: Analyze & Prioritize Bottlenecks

For each bottleneck:

1. **Quantify the impact**
   - How much time does it consume?
   - How often does it run?
   - How many users affected?
   - What's the cost of not fixing it?

2. **Estimate improvement potential**
   - What's a realistic target?
   - How much better could it be?
   - What's the effort to optimize?

3. **Calculate ROI**
   - Effort / Time saved = Return on Investment
   - Prioritize high-ROI items

4. **Group by category**
   - Database: queries, indexes, N+1 problems
   - Algorithm: loops, recursion, sorting
   - Memory: caching, allocation, GC
   - Network: bundling, compression, parallelization
   - Frontend: rendering, JavaScript, images

Example prioritization:
```
Bottleneck | Time | Impact | Effort | ROI | Priority |
-----------|------|--------|--------|-----|----------|
DB indexes | 180ms | High | 2h | 90x | 1 |
Bundle split | 150ms | High | 4h | 37x | 2 |
Validation debounce | 50ms | Low | 1h | 50x | 3 |
Image optimization | 120ms | Medium | 3h | 40x | 4 |
Caching | 100ms | Medium | 3h | 33x | 5 |
```

### Step 3: Plan Optimizations

For each optimization:

1. **Specify the optimization**
   - What will change?
   - Why will it help?
   - What's the expected improvement?

2. **Plan with TDD**
   - What tests capture the optimization?
   - Performance assertion: `assertLatency(operation, maxMs)`
   - Can you write test before optimization?

3. **Consider trade-offs**
   - Memory vs. CPU tradeoff
   - Complexity vs. performance
   - Maintainability impact

4. **Document approach**
   - How will it be measured?
   - How will success be verified?
   - What's the fallback if it breaks?

Example optimization plan:
```
# Optimization 1: Add database index on user_id

Bottleneck: User lookup query takes 180ms
Current: SELECT * FROM orders WHERE user_id = ?
         (full table scan on 1M rows)

Optimization: CREATE INDEX idx_orders_user_id ON orders(user_id)

Expected improvement: 180ms → 5ms (35x faster)
Trade-offs: Slight write performance impact, +10MB storage

Test plan:
- test_list_orders_within_performance_budget() (max 50ms)
- Verify with: pytest test_perf.py::test_list_orders_latency

Fallback: Drop index if causes write performance issues
```

### Step 4: Implement Optimizations with TDD

For each optimization, follow TDD discipline:

**Step 4a: Write Performance Test**

```python
import pytest
import time

def test_list_orders_performance():
    """Orders list should return < 50ms for 1000 orders"""
    # Arrange: Create test data
    user = create_test_user()
    for i in range(1000):
        create_test_order(user)

    # Act: Time the operation
    start = time.perf_counter()
    orders = get_user_orders(user)
    duration = time.perf_counter() - start

    # Assert: Verify performance
    assert duration < 0.050, f"Got {duration*1000:.1f}ms, target < 50ms"
    assert len(orders) == 1000
```

**Step 4b: Run Test - Verify It Fails**

```bash
pytest test_perf.py::test_list_orders_performance -v
# FAILED - got 180ms, target 50ms
```

**Step 4c: Implement Optimization**

For database index optimization:
```sql
-- migrations/001_add_user_index.sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

For algorithm optimization:
```python
# Before: O(n²) algorithm
def find_duplicates(items):
    duplicates = []
    for i, item in enumerate(items):
        for j in range(i+1, len(items)):
            if items[i] == items[j]:
                duplicates.append(item)
    return duplicates

# After: O(n) algorithm
def find_duplicates(items):
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return list(duplicates)
```

For bundle optimization:
```javascript
// Before: Single large bundle (580KB)
import * as app from './app.js'; // all code

// After: Code splitting
// main.js (180KB)
import { HomePage } from './pages/home.js';
// admin.js (150KB) - loaded on demand
// reports.js (120KB) - loaded on demand
```

**Step 4d: Run Test - Verify It Passes**

```bash
pytest test_perf.py::test_list_orders_performance -v
# PASSED - got 8ms, target 50ms ✓
```

**Step 4e: Verify No Regression**

Run full test suite to ensure optimization doesn't break anything:
```bash
npm test  # or pytest
# All tests pass ✓
```

### Step 5: Measure & Document Results

After implementing optimization:

1. **Measure actual improvement**
   ```
   Before: 180ms average
   After: 8ms average
   Improvement: 95.6% faster (22.5x improvement)
   Target met: ✓ (8ms < 50ms target)
   ```

2. **Update performance baseline**
   - Record new metrics
   - Compare to targets
   - Identify next bottleneck

3. **Document in code**
   ```python
   def get_user_orders(user_id):
       """Retrieve user's orders.

       Performance: < 10ms (uses index on user_id)

       Note: This uses an indexed query to keep latency low.
       If you need to add more WHERE clauses, ensure they
       are also indexed or consider query optimization.

       See: docs/performance.md for optimization history
       """
       return db.query(
           "SELECT * FROM orders WHERE user_id = ? ORDER BY created DESC",
           [user_id]
       )
   ```

4. **Create performance documentation**
   - Create docs/performance.md if not exists
   - Record optimization history
   - Document performance targets
   - Link to profiling data

   ```markdown
   # Performance Documentation

   ## Performance Targets
   - Page load time: < 2s
   - API response: < 100ms (p95)
   - Bundle size: < 300KB

   ## Optimization History

   ### 2025-02-07: Database Index on user_id
   - Problem: User orders query took 180ms
   - Solution: Added index on orders.user_id
   - Result: Now 8ms (22.5x improvement)
   - Test: test_list_orders_performance
   - Status: ✓ Deployed to production

   ### 2025-02-06: Code splitting
   - Problem: Bundle size 580KB, slow initial load
   - Solution: Split into main (180KB) + lazy chunks
   - Result: FCP reduced from 2.1s to 1.2s
   - Test: test_first_contentful_paint
   - Status: ✓ Deployed to production

   ## Current Performance Profile
   - Average API response: 45ms (target: 100ms) ✓
   - Page load FCP: 1.2s (target: 1.5s) ✓
   - Bundle size: 280KB (target: 300KB) ✓
   - Memory peak: 45MB (target: 50MB) ✓
   ```

## Output Format

Upon completion, output:

```
# Performance Optimization Complete ✓

## Optimizations Applied
- Count: {N} optimizations implemented
- All tests passing: ✓

## Results Summary
| Optimization | Before | After | Improvement |
|--------------|--------|-------|-------------|
| Database query | 180ms | 8ms | 95.6% ↓ |
| Bundle size | 580KB | 280KB | 51.7% ↓ |
| Form validation latency | 50ms | 15ms | 70% ↓ |

## Performance Targets Status
- Page load (FCP): 1.2s (target: 1.5s) ✓
- API response (p95): 45ms (target: 100ms) ✓
- Bundle size: 280KB (target: 300KB) ✓
- Memory peak: 45MB (target: 50MB) ✓

## Scope Optimized
- Backend: ✓
- Frontend: ✓
- Database: ✓

## Tests Updated
- Performance tests: {count} new tests
- All tests passing: {count}/{count}

## Documentation
- Performance profile: docs/performance.md
- Optimization log: [detailed results]

## Next Steps
1. Review profile and optimization decisions
2. Run full quality gates: /add:verify --level deploy
3. Deploy to staging and monitor
4. If all good, deploy to production

## Performance Test Results
- test_list_orders_performance: PASS (8ms)
- test_form_validation_latency: PASS (15ms)
- test_bundle_load_time: PASS (0.8s)
- test_memory_usage: PASS (45MB)
```

## Error Handling

**Performance test not passing after optimization**
- Review the implementation change
- Check for unintended side effects
- Verify profiling methodology
- Try different optimization approach
- Revert and try next highest-ROI bottleneck

**Optimization breaks other tests**
- Performance gained comes at correctness cost (bad)
- Revert the optimization
- Find alternative approach
- Document why that approach won't work

**Unable to reach target**
- Document realistic achievable target
- Revisit optimization with different approach
- Consider if target is unrealistic
- Flag for architecture review

**Profiling tools not available**
- Install tools: pip install py-spy, npm install -g lighthouse
- Or use alternative profilers available
- Document which tools were used

## Integration with Other Skills

- Used after /add:tdd-cycle completes (code is stable)
- Used before /add:deploy to ensure performance requirements met
- /add:verify validates that optimization doesn't break tests
- Performance tests become part of permanent test suite

## Configuration in .add/config.json

```json
{
  "perf": {
    "pageLoadTime": 2.0,
    "responseTime": 100,
    "memoryLimit": 50,
    "bundleSize": 300,
    "profiler": "chrome-devtools",
    "targetPlatforms": ["web", "mobile"]
  }
}
```

## Performance Testing Best Practices

1. **Test real scenarios**
   - Use realistic data volumes
   - Test with production-like load
   - Consider network latency (for e2e)

2. **Measure consistently**
   - Run tests multiple times (warm up JIT)
   - Use standard hardware for benchmarks
   - Control for other system activity

3. **Set realistic targets**
   - Based on business needs
   - Based on competitive analysis
   - Based on user experience standards

4. **Monitor regressions**
   - Keep performance tests in CI
   - Alert on performance degradation
   - Compare against baseline

5. **Document trade-offs**
   - Every optimization has trade-offs
   - Complexity vs. performance
   - Memory vs. CPU
   - Development time vs. speed

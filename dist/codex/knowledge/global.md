# ADD Global Knowledge — Tier 1

> **Tier 1: Plugin-Global** — Curated best practices that ship with ADD for all users.
> This file is read-only in consumer projects. Only updated by the ADD maintainers.
>
> Agents read this file as part of the 3-tier knowledge cascade:
> 1. **Plugin-global** (this file) — universal ADD best practices
> 2. **User-local** (`~/.claude/add/library.md`) — your cross-project wisdom
> 3. **Project-specific** (`.add/learnings.md`) — this project's discoveries

## Plugin Architecture

- Claude Code plugins namespace commands and skills automatically as `pluginname:commandname` (e.g., `add:spec`). But Claude reproduces whatever naming pattern it sees in file content — so all internal references in plugin files must use the full namespaced form (`/add:spec`, not `/spec`).
- Rules with `autoload: true` in YAML frontmatter load automatically when Claude enters the project. This is the primary enforcement mechanism for ADD behavior.
- Skills use `allowed-tools` in frontmatter to restrict what a skill can do. This enables agent isolation (test-writer can't deploy, reviewer can't edit).
- Claude Code plugin format uses `.claude-plugin/plugin.json` as the manifest. `marketplace.json` lives at the repo root in `.claude-plugin/` and points to the plugin via `source`.

## Agent Coordination

- Parallel subagents for bulk file edits — dispatching 3+ agents simultaneously for coordinated changes is significantly faster than sequential editing. Good pattern for any batch operation touching independent files.
- Never let two agents write to the same file simultaneously. Use file reservations or git worktrees for parallel work.
- Trust-but-verify: a sub-agent reporting "all tests pass" is necessary but not sufficient. The orchestrator must independently run tests.
- Separating "autonomous operations" from "boundaries" as explicit lists makes agent permissions unambiguous. Agents don't have to infer — they get a clear yes/no list.

## Away Mode

- Default to 2-hour duration when the human doesn't specify a time. Don't ask — they're trying to leave.
- Agents need explicit grant of git autonomy (commit, push, create PRs) during away sessions. Without it, they fall back to "ask the human" for routine development tasks.
- The real deployment boundary is production, not staging. Projects with CI/CD should let agents promote through `local → dev → staging` autonomously when verification passes. Production always requires human approval.

## Documentation & Distribution

- GitHub README strips all `<style>` and `<script>` tags. SVG is the only vehicle for rich visuals in a README.
- GitHub Pages can serve from any directory via Actions workflow with `actions/upload-pages-artifact`. Use `build_type: workflow` via the GitHub API.
- macOS filesystems are case-insensitive. `add/` and `ADD/` are the same directory. Use lowercase for project directory names.

## Methodology Insights

- Deriving methodology specs from real, mature projects ensures the methodology reflects actual practice, not theory.
- The 1-by-1 interview format with estimation ("~12 questions, ~10 minutes") prevents question fatigue and is well-received.
- "Cycle" is better than "sprint" for work batching. Sprints imply fixed calendar time; cycles are scope-boxed and end when validation criteria are met.
- Now/Next/Later framing for milestones avoids fake date precision. AI-agent work moves at unpredictable pace.
- Dog-fooding the plugin as a consumer catches issues that the developer perspective never would (e.g., namespace issues, missing permissions).
- Spec-before-code must be enforced on the methodology project itself. If specs are written after implementation, the project has no credibility prescribing spec-driven development to others. Retroactively marking specs "Complete" is a debt payment, not a workflow.

## Environment Promotion

- Environment promotion ladder: agents climb `local → dev → staging` autonomously when verification passes at each level, with automatic rollback on failure.
- Two rollback strategies: `revert-commit` (lighter, for dev) and `redeploy-previous-tag` (safer, for staging/production).
- The ladder stops on first failure — no retries, log and move on. Safer than letting agents debug deployment issues autonomously.

## Competing Swarm Pattern

When a problem has multiple valid approaches and the wrong choice is expensive to reverse, dispatch **2-3 sub-agents with deliberately different approaches in parallel**, then synthesize or pick a winner before implementation. This is different from ordinary parallel dispatch (which assumes independent, non-overlapping work).

**When to use:**
- Infrastructure problems with multiple architecturally valid solutions (e.g., cert-manager vs Google Managed Certs vs app-level ACME proxy)
- UX/design decisions where the cheapest information is a side-by-side comparison
- Security remediation where defense-in-depth from multiple angles is actively useful
- Research spikes where you want diversity of thought, not just throughput

**How to run one:**
1. Name the problem in one sentence.
2. Explicitly brief each sub-agent on *its* approach, and on the fact that other agents are working the same problem differently. This prevents them from converging.
3. Give each the same success criteria.
4. When they complete, review all outputs in one sitting.
5. **Pick a winner BEFORE implementation when approaches are mutually exclusive.** Two swarms independently building mutually-exclusive solutions creates merge conflicts and wasted work.
6. When approaches are *not* mutually exclusive, synthesize — the agentVoice HTTPS cert case shipped both solutions as belt-and-suspenders redundancy, which turned out to be the right call.
7. Record the pattern in `.add/observations.md` with `[swarm]` tag for retro fuel.

**Anti-patterns:**
- Running competing swarms on problems that are already well-understood (pure waste)
- Forgetting to brief agents that others are attempting the same goal (they'll converge to identical approaches)
- Letting both winners land in the codebase without coordinating — leads to conflicting abstractions

**Evidence:** Used successfully three times in the agentVoice project (HTTPS cert resolution, GKE CI/CD install, security Phases A/B/C). Each produced better outcomes than a single-approach dispatch would have. The one failure (cert-manager removal vs fix in parallel) reinforced the "pick a winner before implementation" rule.

## Infrastructure Prerequisites

- Before debugging a workflow YAML, verify the workflow is actually running. GitHub Actions can be disabled at the account level, and a disabled repo will show zero runs regardless of config correctness.
- Before debugging a deployment, verify the artifact exists. Check registry (GHCR, Artifact Registry, etc.) before checking container logs — an image that never built produces "pod never starts" symptoms identical to many other failures.
- Before issuing a TLS cert, verify the domain serves HTTP 200 at `/` with a healthy backend. Google Managed Certificates require 200 at root; a redirect or 404 fails validation silently and leaves the cert in a stuck `FAILED_NOT_VISIBLE` state.
- Multi-stage Docker builds only copy paths you explicitly name. Files created in a `deps` stage outside the standard install path will be missing from the `runtime` stage. Add explicit `COPY --from=deps` for every non-standard path.
- GitOps controllers with `selfHeal: true` (ArgoCD, Flux) revert `kubectl` edits immediately. In such environments, `kubectl` is a read-only tool — all mutations must flow through git.
- Cloud Build (native amd64) beats local ARM→amd64 QEMU emulation by 10-20x for GPU images. On an Apple Silicon developer machine, cross-build via the cloud is the default; local cross-build should be reserved for tiny images where the upload cost dominates.

## Quality Protocols

- E2E tests must be browser-only, human-like interactions. E2E tests must NEVER call APIs directly, check database state, use `skip()` to mask failures, or make programmatic decisions a real user wouldn't. Every action goes through the browser automation (click, fill, select, wait-for-visible). If a feature doesn't work, the test fails — it does not skip. Skipping on error defeats the entire purpose of E2E, which is catching the integration failures unit tests miss.

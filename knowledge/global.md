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
- Claude Code plugin format uses `.claude-plugin/plugin.json` as the manifest. `marketplace.json` is a sibling for marketplace distribution.

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

## Environment Promotion

- Environment promotion ladder: agents climb `local → dev → staging` autonomously when verification passes at each level, with automatic rollback on failure.
- Two rollback strategies: `revert-commit` (lighter, for dev) and `redeploy-previous-tag` (safer, for staging/production).
- The ladder stops on first failure — no retries, log and move on. Safer than letting agents debug deployment issues autonomously.

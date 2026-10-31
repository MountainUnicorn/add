# Astra (Codex gpt-6-astra) — pre-GA plugin critique, 2026-10-31

Independent read-only review of `main` @ a2a2831 + PR #29. Spot-verified by Claude: #1 (deploy merge/tag before Step 6 gate), #3 (scanner warning on stderr + exit 0), #4 (push hook scans staged index only), #11 (rsync --delete into cache parent). Others not yet triaged.


**I would hold GA.** ADD has a useful core: explicit requirements, tests before implementation, independent verification, and persistent project knowledge. But its strongest promises—enforced gates, isolated roles, safe upgrades, and equivalent behavior across runtimes—are stronger than the implementation supports.

The main architectural problem is that ADD mixes behavioral advice, executable checks, and runtime permissions under the word “enforcement.” Users cannot reliably tell which guarantees survive an agent misunderstanding the instructions.

I reviewed the requested source areas and representative generated outputs. Read-only validators and syntax checks passed; targeted in-memory probes reproduced several guardrail failures. I did not run installation or fixture suites that write files, or `compile.py --check`, which itself rewrites generated directories. No files were modified.

1. **High — Production confirmation happens after potentially production-triggering actions.**  
   The deployment skill merges to main and pushes a release tag before presenting its production confirmation gate. The supplied configuration explicitly supports production deployment on merge to main. PR review approval does not resolve this ordering error: the separate deployment confirmation can arrive after deployment has started. Evidence: [deploy/SKILL.md:211](core/skills/deploy/SKILL.md:211), [deploy/SKILL.md:269](core/skills/deploy/SKILL.md:269), [config.json.template:73](core/templates/config.json.template:73).  
   **Fix:** Prepare and verify everything first, then obtain approval bound to the exact commit and environment **before** the first merge, push, tag, or API call that can deploy.

2. **High — Claimed role isolation is not implemented by Claude skill permissions.**  
   README says reviewers cannot edit code, but the reviewer grants unrestricted `Bash`. More fundamentally, Claude’s `allowed-tools` grants permission; it does not remove other tools. The settings template also preapproves broad operations including `git push`, `gh pr *`, and `npx *`. Evidence: [README.md:194](README.md:194), [reviewer/SKILL.md:4](core/skills/reviewer/SKILL.md:4), [settings.json.template:4](core/templates/settings.json.template:4). This follows the documented [Claude skill permission contract](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill).  
   **Fix:** Use actual runtime restrictions and filesystem boundaries, remove unnecessary broad grants, and describe remaining constraints as behavioral. Replace “agents can’t skip verification” with a precise account of what CI or another external mechanism actually blocks.

3. **High — Claude never receives the injection scanner’s purported agent-facing warning.**  
   The scanner prints its warning to stderr and always exits zero. Claude’s documented hook contract says stderr from a successful hook is not shown to the model. The post-write lint warnings use the same ineffective pattern. Evidence: [posttooluse-scan.sh:343](runtimes/claude/hooks/posttooluse-scan.sh:343), [posttooluse-scan.sh:367](runtimes/claude/hooks/posttooluse-scan.sh:367), [post-write.sh:38](runtimes/claude/hooks/post-write.sh:38), [official hook output contract](https://code.claude.com/docs/en/hooks#exit-code-0).  
   **Fix:** Emit valid `hookSpecificOutput.additionalContext` for advisory feedback, or use the documented event-specific error/blocking mechanism. Test that the warning reaches the agent transcript, not merely that the script prints it.

4. **High — Secret scanning examines the wrong state at both commit and push.**  
   Deploy scans the staged diff before its staging step. Files subsequently added can therefore bypass the scan. The push hook also invokes the scanner’s staged-file mode; after committing, a clean index contains nothing to scan, even when outgoing commits contain credentials. Evidence: [deploy/SKILL.md:98](core/skills/deploy/SKILL.md:98), [deploy/SKILL.md:126](core/skills/deploy/SKILL.md:126), [hooks.json:19](runtimes/claude/hooks/hooks.json:19), [scan-secrets.sh:292](core/lib/scan-secrets.sh:292).  
   **Fix:** Scan the final staged content immediately before committing. At push, scan the outgoing commit range. Add regression cases for an initially unstaged secret and a committed secret with a clean index.

5. **High — The security audit logger can persist credentials itself.**  
   `SOURCE` can contain a complete shell command or URL. Only the matched excerpt is redacted; the raw source is printed and written to JSONL. A command containing an authorization header can therefore leak that credential when its output triggers an injection pattern. Evidence: [posttooluse-scan.sh:49](runtimes/claude/hooks/posttooluse-scan.sh:49), [posttooluse-scan.sh:341](runtimes/claude/hooks/posttooluse-scan.sh:341), [posttooluse-scan.sh:351](runtimes/claude/hooks/posttooluse-scan.sh:351).  
   **Fix:** Sanitize every field before every output sink. Prefer a command identifier and sanitized URL over raw arguments. Test credentials in tool inputs as well as outputs.

6. **High — Codex’s “always-loaded rules” are mostly rule titles.**  
   The compiler extracts each rule’s first heading and emits that as an invariant. It does not include the behavioral body. Its explanation points to skill files that do not contain those bodies, and the Codex session hook loads handoff state rather than the rules. The installation guide nevertheless says all rules are concatenated into `AGENTS.md`. Evidence: [compile.py:513](scripts/compile.py:513), [compile.py:527](scripts/compile.py:527), [compile.py:675](scripts/compile.py:675), [codex-install.md:65](docs/codex-install.md:65).  
   **Fix:** Implement an explicit, maturity-aware bootstrap that loads the actual installed rule bodies. Verify rule content reaches a real Codex session. A heading-parity test cannot establish behavioral parity.

7. **High — Codex invocation restrictions use the wrong metadata structure.**  
   Generated `openai.yaml` places `allow_implicit_invocation` at the top level. The documented structure nests it under `policy`; the top-level `tools` list is also not a sandbox. Separately, the duplicated policy allows implicit initialization although core marks initialization explicit-only. Evidence: [compile.py:461](scripts/compile.py:461), [skill-policy.yaml:47](runtimes/codex/skill-policy.yaml:47), [init/SKILL.md:6](core/skills/init/SKILL.md:6), [official skill metadata schema](https://learn.chatgpt.com/docs/build-skills#optional-metadata).  
   **Fix:** Emit supported metadata, derive invocation restrictions from core, and test explicit-only skills against implicit trigger prompts on supported CLI versions.

8. **High — The test-deletion guardrail has reproducible false passes.**  
   Tests are keyed by `path::name`, collapsing identically named tests in different suites/classes. Rename detection can match a removed test to an unchanged surviving test with the same body. In-memory probes confirmed that both cases permit deletion. Normalization also strips comment markers inside strings: changing `"https://good.example"` to another URL can leave the hash unchanged. Evidence: [check-test-count.py:81](core/lib/check-test-count.py:81), [check-test-count.py:318](core/lib/check-test-count.py:318), [check-test-count.py:344](core/lib/check-test-count.py:344).  
   **Fix:** Use framework-qualified identities and language-aware parsing. Match renames one-to-one between unmatched tests, preserve string literals, and compare against a fresh snapshot after refactoring.

9. **High — Test-rewrite approval is reusable and insufficiently validated.**  
   Override discovery reads every historical cycle. Deletion approval checks affected test names without requiring `allow_test_rewrite` or validating who approved the change. A probe with `approved_by: "agent"` and the flag disabled still allowed deletion. Evidence: [check-test-count.py:410](core/lib/check-test-count.py:410), [check-test-count.py:475](core/lib/check-test-count.py:475).  
   **Fix:** Scope approvals to the current cycle, operation, and before/after revision; require the explicit acknowledgment consistently. Treat repository JSON as an audit record, not proof of human authorization.

10. **High — Codex upgrade and uninstall can destroy user edits.**  
    Missing hashing/Python disables preservation but installation continues. A failed backup is ignored before overwriting the original. Backup names collide across repeated installations. The generated uninstaller deletes recorded paths without checking whether their contents changed after installation, contradicting the preservation promise. Evidence: [install-codex.sh:81](scripts/install-codex.sh:81), [install-codex.sh:126](scripts/install-codex.sh:126), [install-codex.sh:342](scripts/install-codex.sh:342), [codex-install.md:84](docs/codex-install.md:84).  
    **Fix:** Abort before overwriting when preservation cannot be guaranteed; use unique backups; checksum files during uninstall and retain modified ones. Stage installation changes transactionally and preserve user additions to shared configuration.

11. **High — Marketplace synchronization can delete installed Claude plugin versions.**  
    The default destination ends at `cache/add-marketplace/add`, and `rsync --delete` mirrors directly into it. Claude stores installed versions one directory below that location. Existing version directories can therefore be removed while installation records still reference them. Evidence: [sync-marketplace.sh:24](scripts/sync-marketplace.sh:24), [sync-marketplace.sh:44](scripts/sync-marketplace.sh:44), [official cache layout](https://code.claude.com/docs/en/plugins/loading#find-plugins-on-disk).  
    **Fix:** Remove cache mutation from the development workflow. Use `--plugin-dir` or a local marketplace. If cache maintenance remains, resolve the registered installation path and validate it before changing anything.

12. **Medium — Codex installation paths and initialization remain coupled to Claude/default-home assumptions.**  
    The installer accepts custom `CODEX_HOME`, but compilation hardcodes `~/.codex` into resources and hook commands. Generated Codex initialization still creates `.claude/settings.json`, `CLAUDE.md`, and state under `~/.claude/add`. Evidence: [install-codex.sh:55](scripts/install-codex.sh:55), [compile.py:294](scripts/compile.py:294), [add-init/SKILL.md:592](dist/codex/.agents/skills/add-init/SKILL.md:592), [add-init/SKILL.md:624](dist/codex/.agents/skills/add-init/SKILL.md:624).  
    **Fix:** Model runtime-specific paths and configuration artifacts explicitly. Test a clean Codex-only home and a nondefault home by executing installed entry points.

13. **High — Initialization and consumers disagree on the configuration contract.**  
    The template defines `quality.coverage_threshold`, `quality.lint`, and `infrastructure.cicd`; verification requests `test.minCoverage`, `code.lint`, and `ci.gates`. Full initialization also copies a literal version `0.5.0` and creates legacy Markdown learnings. There is no configuration schema to catch this. Evidence: [config.json.template:3](core/templates/config.json.template:3), [config.json.template:79](core/templates/config.json.template:79), [verify/SKILL.md:29](core/skills/verify/SKILL.md:29), [init/SKILL.md:591](core/skills/init/SKILL.md:591).  
    **Fix:** Define one versioned configuration schema and align every consumer. Generate current-version, JSON-learning state in all initialization modes; validate complete fixtures through init → verify → upgrade.

14. **Medium — Plain `/add:verify` does not run tests.**  
    Its default is `local`, which runs lint and types only. Unit tests begin at `ci`, despite README presenting verification as the test/coverage/compliance check. Evidence: [verify/SKILL.md:48](core/skills/verify/SKILL.md:48), [README.md:174](README.md:174).  
    **Fix:** Make ordinary verification include tests, or explicitly name the lighter operation and prominently report “tests not run.” A green verification result should not imply evidence that was never collected.

15. **High — The maturity dial does not produce a consistent policy.**  
    The master rule that resolves maturity exceptions is itself gated at beta. Alpha loads an unconditional spec-first rule, while the maturity matrix requires specs only for critical paths. Generated POC instructions require specs, tests-first, and conventional commits despite the matrix making those optional/freeform. Autonomy guidance also reverses between README and the matrix. Evidence: [maturity-lifecycle.md:3](core/rules/maturity-lifecycle.md:3), [spec-driven.md:8](core/rules/spec-driven.md:8), [maturity-matrix.md:13](core/references/maturity-matrix.md:13), [generate-agents-md.py:78](core/lib/generate-agents-md.py:78), [README.md:202](README.md:202).  
    **Fix:** Maintain one machine-readable policy matrix and generate rule selection, summaries, and documentation from it. Separate process rigor from authorization and autonomy.

16. **Medium — First-use friction undermines the product’s strongest pitch.**  
    With no project configuration, the Claude loader activates the full rule set. The default interview advertises 16–19 questions and roughly 12 minutes, against README’s five-minute estimate. Later, routine return/planning commands can be blocked until a retrospective occurs, with eventual refusal of overrides. Evidence: [load-rules.sh:26](runtimes/claude/hooks/load-rules.sh:26), [init/SKILL.md:416](core/skills/init/SKILL.md:416), [README.md:119](README.md:119), [add-compliance.md:12](core/rules/add-compliance.md:12).  
    **Fix:** Make minimal initialization the default, load no project methodology until adoption, and keep retrospective reminders advisory. Deliver one useful spec/test/verify cycle before asking users to adopt the surrounding management system.

17. **Medium — Context budgeting is incomplete, and the learning budget is not a hard cap.**  
    The source contains 28 skills totaling roughly 8,700 lines. Those are not all loaded at once, but the active GA rule bodies alone are approximately 12,500 tokens using a rough characters/4 estimate, before knowledge and task context. The learning filter caps detailed entries but appends an unbounded index of remaining titles. Evidence: [load-rules.sh:94](runtimes/claude/hooks/load-rules.sh:94), [filter-learnings.sh:64](runtimes/claude/hooks/filter-learnings.sh:64), [filter-learnings.sh:84](runtimes/claude/hooks/filter-learnings.sh:84).  
    **Fix:** Budget the entire emitted document, including headings and indexes. Load relevant knowledge on demand and measure actual session cost by runtime and maturity. Cache-layout conventions alone do not establish cost savings.

18. **Medium — The compiler’s apparent abstraction exceeds its actual abstraction.**  
    Adapter YAML describes runtime behavior, but the compiler reads only two Codex version fields from it; transformations remain hardcoded substitutions. Dependency declarations are also inconsistent: the schema defines references relative to `references/`, while skills declare paths such as `rules/telemetry.md`; Codex compilation drops those declarations altogether. Evidence: [compile.py:741](scripts/compile.py:741), [compile.py:440](scripts/compile.py:440), [skill-frontmatter.schema.json:56](core/schemas/skill-frontmatter.schema.json:56), [plan/SKILL.md:5](core/skills/plan/SKILL.md:5).  
    **Fix:** Either implement validated adapters or simplify to explicit runtime backends. Resolve every declared dependency during compilation and emit an actual load instruction; reject unresolved references.

19. **Medium — Compilation checks mutate files, while CI misses untracked output drift.**  
    `--check` snapshots the existing outputs, recompiles into their real locations, then compares without restoring them. Separately, CI uses `git diff --quiet`, which does not detect newly generated untracked files. Evidence: [compile.py:923](scripts/compile.py:923), [compile-drift.yml:37](.github/workflows/compile-drift.yml:37).  
    **Fix:** Compile into temporary output directories and compare complete manifests, contents, and executable modes. Make checking genuinely read-only and detect added, deleted, modified, and untracked artifacts.

20. **Medium — `AGENTS.md --check` reports drift solely because time passed.**  
    The command generates a fresh timestamp and compares the complete generated file byte-for-byte. An in-memory reproduction with identical state and timestamps one second apart returned failure with only the timestamp changed. Fixture tests use a fixed timestamp, masking the production behavior. Evidence: [generate-agents-md.py:505](core/lib/generate-agents-md.py:505), [generate-agents-md.py:682](core/lib/generate-agents-md.py:682), [test-agents-md-sync.sh:51](tests/agents-md-sync/test-agents-md-sync.sh:51).  
    **Fix:** Preserve the existing generation timestamp during checks or exclude it from semantic comparison. Test ordinary generation followed by ordinary checking.

21. **High — CI does not establish the runtime behavior claimed for GA.**  
    The hardcoded suite matrix omits five existing suites: install manifest, legacy-agent cleanup, native Codex skills, doctor checks, and telemetry reference coverage. Both live initialization tests can skip successfully without credentials. Their main assertion checks only that configuration has `version` and `maturity`; Claude rule loading is explicitly nonblocking. Evidence: [guardrails.yml:78](.github/workflows/guardrails.yml:78), [install-smoke-claude.yml:58](.github/workflows/install-smoke-claude.yml:58), [install-smoke-claude.yml:80](.github/workflows/install-smoke-claude.yml:80), [run-smoke.sh:147](tests/smoke/codex/run-smoke.sh:147).  
    **Fix:** Automatically discover suites or enforce an exhaustive manifest. Add executable contract tests for rule loading, invocation policy, warning delivery, upgrade preservation, and approval ordering. Require successful live release canaries; allow credential-free skips only in explicitly partial PR checks. Cover macOS as well as Linux.

22. **Medium — Release evidence can certify incomplete checks or the wrong revision.**  
    Release verification accepts any nonempty collection of successful, neutral, or skipped checks without requiring specific check names. Evidence generation links the latest smoke run on `main`, rather than the run for the release tag’s commit. Evidence: [release.sh:90](scripts/release.sh:90), [release.sh:97](scripts/release.sh:97), [release-evidence.sh:112](scripts/release-evidence.sh:112).  
    **Fix:** Require an explicit set of successful checks on the exact release SHA. Generate catalogs, capability claims, and smoke links from that same revision; fail evidence generation when required proof is missing.

The **top five fixes before GA**, in order:

1. **Make the safety contract true:** correct production approval and secret-scan ordering, deliver hook warnings, and remove unsupported isolation/enforcement claims.
2. **Make Codex operationally correct:** load actual rules, emit valid invocation policy, and remove runtime/path leakage.
3. **Repair the test-deletion guardrail:** qualified identities, correct parsing, one-to-one renames, and narrowly scoped approvals.
4. **Make lifecycle operations preserve user data:** safe upgrade/uninstall behavior and removal of destructive marketplace-cache synchronization.
5. **Make release proof meaningful:** exhaustive CI, real configuration validation, required runtime canaries, and evidence tied to the released SHA.

I would **cut from the default GA experience** the mandatory retrospective blocking and the branding/infographic/dashboard track; retain those as optional extensions. I would also remove the cache-sync script and either implement or delete the largely decorative adapter configuration. These cuts follow findings 11, 16–18.

The release should demonstrate a small, dependable spec → test → implementation → verification workflow. The broader methodology can grow after that foundation earns users’ trust.
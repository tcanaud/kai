# Research: Feature Lifecycle V2

**Feature**: 010-feature-lifecycle-v2
**Date**: 2026-02-18

## R1: QA Verdict Persistence

**Context**: The QA system (009-qa-system) outputs verdicts to stdout only. Decision D7 in the 009 plan explicitly defers results persistence to Phase 2 ("v1.1 feature"). Feature 010 requires FR-008 (read verdict from artifact) and FR-009 (display verdict status).

**Decision**: Write a `verdict.yaml` to `.qa/{feature}/` owned by the feature-lifecycle-v2 workflow layer, not by the QA system.

**Rationale**: This bridges the gap without modifying the QA system. The workflow command instructs the developer to run `/qa.run`, then captures the verdict in a file the workflow owns. Freshness is checked by comparing `spec_sha256` in `verdict.yaml` against the current SHA-256 of `specs/{feature}/spec.md` — the same mechanism the QA system uses internally.

**Schema**:
```yaml
# .qa/{feature}/verdict.yaml
feature_id: "010-feature-lifecycle-v2"
verdict: "PASS"            # PASS | FAIL | STALE
run_at: "2026-02-18T21:00:00Z"
passed: 10
failed: 0
total: 10
spec_sha256: "abc123..."  # from _index.yaml checksums at run time
failures: []               # list of { script, criterion_ref, assertion } on FAIL
```

**Alternatives considered**:
- **Extend `_index.yaml` with `last_run` metadata**: Cleanest long-term solution but requires modifying the QA system. Deferred to when 009-qa-system does its v1.1 persistence update.
- **Developer self-reports verdict**: Loses auditability — verdict is declarative, not derived from script execution.
- **Parse `.product/inbox/` finding deposits**: Unreliable. Findings are non-blocking observations only; clean PASS produces no deposits. Inverts the finding schema semantics.

**Forward compatibility**: When the QA system implements v1.1 persistence, the workflow can read `_index.yaml` instead of `verdict.yaml` with no behavioral change for the developer.

---

## R2: GitHub CLI Integration Patterns

**Context**: `/feature.pr` requires creating GitHub PRs with traceable bodies. The kai codebase has zero existing `gh` CLI integration.

**Decision**: Use `gh pr create --body-file -` with stdin heredoc for PR body, `gh pr list --json` for existence and merge checks.

**Rationale**: The `--body-file -` flag reads from stdin, which is the most reliable way to pass multi-line Markdown bodies with traceability links. The `--json` output mode provides structured data for programmatic consumption. `gh pr list` always exits 0 (even with empty results), making it safe for conditional checks.

**Key patterns**:

| Operation | Command | Exit behavior |
|-----------|---------|---------------|
| Auth check | `gh auth status > /dev/null 2>&1` | Exit 0 if authenticated, 1 if not |
| Installed check | `command -v gh > /dev/null 2>&1` | Exit 0 if installed |
| Duplicate check | `gh pr list --head "$BRANCH" --state open --json url --jq '.[0].url // ""'` | Always exits 0; check string emptiness |
| PR creation | `gh pr create --title "$TITLE" --base main --body-file -` | Outputs PR URL on success; exits 1 on failure |
| Merge check | `gh pr list --head "$BRANCH" --state merged --json number --jq 'length'` | Always exits 0; "0" means not merged, ">0" means merged |
| PR state | `gh pr view --json state --jq '.state'` | Returns "OPEN", "CLOSED", or "MERGED"; exits 1 if no PR |

**Exit codes**: 0 = success, 1 = general failure, 4 = authentication required (inconsistently applied).

**Implementation note**: Since slash commands are Markdown templates executed by Claude Code (not Node.js scripts), the `gh` CLI will be invoked through Claude Code's bash execution capability, not `node:child_process`. The PR body template is assembled as Markdown text within the slash command, then piped to `gh pr create`.

**Alternatives considered**:
- **GitHub REST API via `node:https`**: Requires token management, OAuth flow, manual pagination. Much more complex than wrapping `gh`.
- **`@octokit/rest` npm package**: Violates zero-dependency constraint.

---

## R3: Atomic State Transitions for Post-Merge Resolution

**Context**: FR-020 requires all-or-nothing state transitions: feature to "release", backlogs to "done", feedbacks to "resolved". The system uses filesystem-as-state with YAML+Markdown files.

**Decision**: Validate-then-apply pattern with feature YAML written last as the commit record.

**Rationale**: True multi-file atomicity is impossible with POSIX filesystem operations. The validate-then-apply pattern catches 99% of real failures (missing files, locked files, wrong status) before any mutation begins. Writing the feature YAML last means it serves as the "commit record" — if it reaches "release", all other transitions already succeeded.

**Apply order**:
1. Transition all backlogs to "done" (move + frontmatter update)
2. Transition all feedbacks to "resolved" (move + frontmatter update)
3. Update `.product/index.yaml`
4. Write `.features/{feature_id}.yaml` with `stage: "release"` (**last**)

**File move pattern**:
```
writeFileSync(dest.tmp, updatedContent)  → renameSync(dest.tmp, dest)  → unlinkSync(src)
```
If crash between rename and unlink: stale source copy exists but dest is canonical. Re-running resolution detects already-transitioned files and skips gracefully (idempotent).

**Rollback**: Best-effort compensating rollback in the catch block. For a single-developer local tool where validation catches nearly all real failures, this is proportional complexity.

**Alternatives considered**:
- **Transaction log**: Over-engineered. Adds a new file format and recovery reader. Contradicts filesystem-as-truth paradigm. No other kai command uses transaction logs.
- **Git staging as atomic unit**: Wrong layer. Git mutations from code require `execSync`, introduce lock-file failures, and the commit is not under code control (Claude Code drives commits).
- **Write all to `.tmp` then rename N times**: Still N separate syscalls. Helps only for single-file replacement (used for feature YAML).

---

## R4: Workflow Dashboard Extension Architecture

**Context**: The existing `/feature.workflow` command has Full Method (11 steps, Gates A/B/C) and Quick Flow (5 steps). V2 adds QA, PR, and post-merge steps after implementation.

**Decision**: Extend the existing dependency chains with new steps and gates. QA/PR/resolve steps are optional for pre-V2 features (FR-025/FR-026/FR-027).

**Extended Full Method chain**:
```
Step  Name              Requires                       Artifact Key          Command
───── ───────────────── ────────────────────────────── ───────────────────── ──────────────────────
1-9   (existing)        (unchanged)                    (unchanged)           (unchanged)
      ── GATE C: tasks == 100% ──
10    QA Plan           GATE C                         qa.plan_exists        /qa.plan {FEATURE}
11    QA Run            qa.plan_exists                 qa.verdict            /qa.run {FEATURE}
12    Agreement Check   tasks >= 50%                   agreement.check       /agreement.check {FEATURE}
      ── GATE D: qa.verdict == PASS AND agreement.check == PASS ──
13    PR Creation       GATE D                         pr.created            /feature.pr {FEATURE}
14    Post-Merge        pr.merged                      lifecycle == release  /feature.resolve {FEATURE}
```

**Gate C redefined**: The existing Gate C is `tasks >= 50%` for agreement check timing. For V2, Gate C becomes `tasks == 100%` (all tasks done) to unlock QA. The existing 50% threshold for agreement check is retained as a separate condition.

**Backward compatibility**: For features without QA artifacts (001-009), steps 10-14 appear in the dashboard as `skip` (optional). Gate D is auto-satisfied for features with no QA plan and no QA verdict. These features can reach "complete" status through the existing path.

**Detection of new artifact keys**:
| Key | Detection Path |
|-----|---------------|
| `qa.plan_exists` | `.qa/{FEATURE}/_index.yaml` exists |
| `qa.verdict` | `.qa/{FEATURE}/verdict.yaml` exists → read `verdict` field |
| `qa.verdict_fresh` | Compare `spec_sha256` in verdict.yaml against current `shasum -a 256 specs/{FEATURE}/spec.md` |
| `pr.created` | `gh pr list --head "{BRANCH}" --state open --json url --jq '.[0].url // ""'` is non-empty |
| `pr.merged` | `gh pr list --head "{BRANCH}" --state merged --json number --jq 'length'` is > 0 |

---

## R5: QA FAIL Governance Loop

**Context**: FR-021 through FR-024 require bridging the QA system and product-manager system. When QA fails, a critical backlog must be auto-generated, and the workflow redirects through the fix cycle.

**Decision**: The `/feature.workflow` command detects `verdict.yaml` with `verdict: "FAIL"`, reads the `failures` array, and auto-generates a backlog via the product-manager conventions. The workflow then proposes the fix path.

**Backlog generation pattern**: Write a new `BL-xxx.md` file directly to `.product/backlogs/open/` using the existing backlog template schema. The backlog includes:
- `category: "critical-bug"`
- `priority: "critical"`
- `source` field links to the QA report
- Body contains the specific failing checks from `verdict.yaml`'s `failures` array

**Graceful degradation**: If `.product/` doesn't exist (product-manager not installed), the workflow displays the QA FAIL findings to the developer and suggests manual backlog creation. No error is thrown.

**Fix cycle routing**: After the critical backlog exists, `/feature.workflow` proposes:
1. Process the backlog → update spec/tasks as needed
2. Implement fixes
3. Re-run `/qa.run {FEATURE}`
4. Gates re-evaluate from the new `verdict.yaml`

---

## R6: New Command Architecture

**Context**: Two new commands needed: `/feature.pr` and `/feature.resolve`. Should they be slash command templates (Markdown) or Node.js modules?

**Decision**: Both are slash command templates (Markdown files) following the existing pattern. Supporting JavaScript modules are added to `packages/feature-lifecycle/src/pr/` for reusable logic.

**Rationale**: All existing feature-lifecycle commands (`/feature.workflow`, `/feature.status`, `/feature.list`, `/feature.discover`, `/feature.graph`) are slash command templates. The template pattern delegates intelligence to Claude Code, which handles filesystem scanning, content assembly, and conditional logic. JavaScript modules are only needed for logic that must be invoked programmatically (installer, updater, scanners).

However, for `/feature.resolve` (post-merge resolution), the state transition logic benefits from a Node.js helper:
- `src/pr/resolve.js` — validate-then-apply state transitions (called via the template's instructions to Claude Code)
- `src/pr/body-builder.js` — PR body assembly from scattered artifacts (template helper)
- `src/pr/prerequisite-check.js` — gate enforcement for PR prerequisites

These modules are invoked indirectly: the slash command template instructs Claude Code to perform the operations described in the module's contract. They document the exact behavior expected without being executed directly.

**Alternative**: Pure template-only approach (no new JS modules). Viable but risks inconsistency when the same validation logic needs to appear in both `/feature.pr` and `/feature.resolve`. Shared modules prevent drift.

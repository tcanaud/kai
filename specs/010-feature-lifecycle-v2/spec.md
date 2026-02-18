# Feature Specification: Feature Lifecycle V2

**Feature Branch**: `010-feature-lifecycle-v2`
**Created**: 2026-02-18
**Status**: Draft
**Input**: Extend the feature governance workflow from implementation through release — QA integration, traceable PR creation, post-merge lifecycle closure, and QA FAIL recovery loop.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Guided Endgame via Workflow Dashboard (Priority: P1)

After all implementation tasks reach 100% completion, the developer runs `/feature.workflow` and sees the complete endgame path: QA Plan, QA Run, PR Creation, and Post-Merge Resolution. Gates evaluate mechanically — Gate C (tasks 100%) unlocks QA, Gate D (QA PASS + Agreement Check PASS) unlocks PR creation. The workflow always proposes the exact next action. The developer follows the guided path without remembering what comes next.

**Why this priority**: This is the foundation. Without gate evaluation and step visibility in the dashboard, neither PR creation nor post-merge resolution can be reached through the workflow. Every other story depends on the workflow knowing where each feature stands.

**Independent Test**: Run `/feature.workflow` on a feature with all tasks done. Verify that QA Plan appears as the next step. Complete QA (PASS) and agreement check (PASS). Verify that PR creation appears as the next step. The dashboard shows all new steps with correct gate statuses at each stage.

**Acceptance Scenarios**:

1. **Given** a feature with all tasks marked done, **When** the developer runs `/feature.workflow`, **Then** the dashboard shows Gate C as satisfied and proposes QA Plan as the next step.
2. **Given** a feature with QA PASS and Agreement Check PASS, **When** the developer runs `/feature.workflow`, **Then** the dashboard shows Gate D as satisfied and proposes PR creation as the next step.
3. **Given** a feature with QA PASS but Agreement Check FAIL, **When** the developer runs `/feature.workflow`, **Then** Gate D remains blocked and the workflow proposes the agreement repair cycle.
4. **Given** a feature with QA FAIL, **When** the developer runs `/feature.workflow`, **Then** Gate D remains blocked and the workflow proposes the QA FAIL recovery path.
5. **Given** a feature still in implementation (tasks < 100%), **When** the developer runs `/feature.workflow`, **Then** QA and PR steps appear in the dashboard but are marked as blocked behind Gate C.

---

### User Story 2 - PR Creation with Full Traceability (Priority: P2)

The developer runs `/feature.pr {feature}` to create a GitHub pull request with a body containing the complete governance lineage: specification, agreement, QA results summary, agreement check verdict, originating feedbacks, linked backlogs, and a diff summary. Prerequisites are enforced mechanically — the command refuses to proceed unless QA is PASS, agreement check is PASS, and all tasks are done. The developer reviews the PR on GitHub, not composes it.

**Why this priority**: This is the primary new command and the main user-facing capability. It eliminates the most time-consuming manual step — composing a traceable PR body from scattered artifacts.

**Independent Test**: Given a feature with all prerequisites satisfied (QA PASS, Agreement PASS, tasks 100%), run `/feature.pr`. Verify the PR is created on GitHub with all traceability links present in the body.

**Acceptance Scenarios**:

1. **Given** a feature with QA PASS, Agreement Check PASS, and all tasks done, **When** the developer runs `/feature.pr {feature}`, **Then** a GitHub PR is created with the full traceability body.
2. **Given** a feature where QA has not been run, **When** the developer runs `/feature.pr {feature}`, **Then** the command refuses with a clear message listing unmet prerequisites.
3. **Given** a feature with QA PASS but Agreement Check FAIL, **When** the developer runs `/feature.pr {feature}`, **Then** the command refuses and suggests running the agreement repair cycle.
4. **Given** a feature with no originating feedbacks or linked backlogs, **When** the developer runs `/feature.pr {feature}`, **Then** the PR body shows "N/A" for those sections instead of erroring.
5. **Given** the GitHub CLI is not installed or not authenticated, **When** the developer runs `/feature.pr {feature}`, **Then** a clear error message explains the dependency.

---

### User Story 3 - Post-Merge Lifecycle Resolution (Priority: P3)

After the PR is merged on GitHub, the developer triggers post-merge resolution. The system transitions the feature stage to "release", linked backlogs to "done", and originating feedbacks to "resolved" — all in one operation. The developer never touches a state file by hand. The governance chain is fully closed.

**Why this priority**: This completes the governance rail from ideation to release. Without it, post-merge state updates remain manual and error-prone. But it's lower priority than US1 and US2 because those are needed first to reach the merge point.

**Independent Test**: Given a feature with a merged PR, trigger post-merge resolution. Verify that the feature stage is "release", all linked backlogs are "done", and all originating feedbacks are "resolved".

**Acceptance Scenarios**:

1. **Given** a feature whose PR has been merged, **When** the developer triggers post-merge resolution, **Then** the feature stage transitions to "release".
2. **Given** a feature with 2 linked backlogs and 3 originating feedbacks, **When** post-merge resolution runs, **Then** all 2 backlogs are marked "done" and all 3 feedbacks are marked "resolved".
3. **Given** a feature whose PR is still open (not merged), **When** the developer triggers post-merge resolution, **Then** the system refuses with a clear message that the PR is not yet merged.
4. **Given** a feature with no linked backlogs or feedbacks, **When** post-merge resolution runs, **Then** only the feature stage transitions to "release" and no errors occur.
5. **Given** a resolution that fails midway (e.g., a feedback file is locked), **When** the failure occurs, **Then** no partial state updates are left behind — either all transitions succeed or none do.

---

### User Story 4 - QA FAIL Governance Loop (Priority: P4)

When QA returns a FAIL verdict, the workflow detects it and triggers the product-manager mechanism: a critical backlog is auto-generated from the QA findings. The workflow then redirects the developer through the standard governance path — backlog processing, spec update, new tasks, implementation, and QA re-run. The developer doesn't decide what to do after a FAIL; the system routes mechanically. After fixes, the QA re-run produces a new verdict and gates re-evaluate.

**Why this priority**: This is the most complex capability, connecting two subsystems (QA and product-manager) for the first time. It's also the least common path — most features should pass QA on the first try. Implementing it last reduces risk.

**Independent Test**: Given a feature with QA FAIL, verify that a critical backlog is created in the product-manager system with the QA findings as source. Run `/feature.workflow` and verify it proposes the fix cycle. After fixes and QA re-run (PASS), verify Gate D opens.

**Acceptance Scenarios**:

1. **Given** a feature with QA verdict FAIL (2 checks failed), **When** the workflow detects the FAIL, **Then** a critical backlog is auto-generated with the 2 failing checks as findings.
2. **Given** a critical backlog from QA FAIL exists, **When** the developer runs `/feature.workflow`, **Then** the workflow proposes the fix path: backlog processing, spec update, tasks, implementation, QA re-run.
3. **Given** the developer has fixed all issues and re-runs QA with a PASS verdict, **When** gates re-evaluate, **Then** Gate D opens and the workflow proposes PR creation.
4. **Given** a QA re-run that still FAILs (1 remaining issue), **When** the workflow evaluates, **Then** the governance loop continues — a new backlog is generated for the remaining finding.

---

### User Story 5 - Backward Compatibility (Priority: P5)

Existing features (001-009) that were created before the V2 workflow continue to work through `/feature.workflow` without errors. The new QA and PR steps appear in the dashboard as optional, not blocking. Features can opt into the new rail or continue as before. No migration is required.

**Why this priority**: This is a guardrail, not a new capability. It ensures V2 doesn't break existing work. It's the lowest priority because it's largely about what the system does NOT do (block, error, regress) rather than what it adds.

**Independent Test**: Run `/feature.workflow` on feature 007-knowledge-system (no QA artifacts). Verify the dashboard displays without errors, QA steps appear as optional/skip, and the feature's existing progress is preserved.

**Acceptance Scenarios**:

1. **Given** feature 007 with no QA artifacts, **When** the developer runs `/feature.workflow 007`, **Then** the dashboard shows QA steps as optional and no errors occur.
2. **Given** feature 001 in "release" stage, **When** the developer runs `/feature.workflow 001`, **Then** the feature status is displayed correctly with no regressions.
3. **Given** a pre-V2 feature with all tasks done, **When** the developer runs `/feature.workflow`, **Then** QA-related gates do not block the feature from being marked complete.

---

### Edge Cases

- What happens when a feature has QA PASS from a previous run but the code has changed since? The workflow should detect stale QA results and recommend re-running QA.
- What happens when `/feature.pr` is run on a feature that already has an open PR? The system should detect the existing PR and inform the developer instead of creating a duplicate.
- What happens when post-merge resolution is triggered but the feature has no linked backlogs or feedbacks? Only the feature stage transitions; missing optional artifacts produce no errors.
- What happens when the product-manager system is not installed? The QA FAIL governance loop should degrade gracefully — report the FAIL findings to the developer and suggest manual backlog creation.
- What happens when a feature depends on another feature that hasn't been released yet? Out of scope for V2 — cross-feature dependency awareness is a future vision item.
- What happens when Gate D requirements are met but the developer doesn't want to create a PR yet? The workflow proposes PR creation but never forces it — the developer chooses when to proceed.

## Requirements *(mandatory)*

### Functional Requirements

**Workflow Chain Management**

- **FR-001**: The workflow dashboard MUST display QA Plan, QA Run, PR Creation, and Post-Merge Resolution as steps in the dependency chain after Implementation.
- **FR-002**: The workflow MUST evaluate Gate C (all tasks done) and display its status (pass/blocked) in the dashboard.
- **FR-003**: The workflow MUST evaluate Gate D (QA PASS + Agreement Check PASS) and display its status (pass/blocked) in the dashboard.
- **FR-004**: The workflow MUST propose the correct next action based on the current gate and artifact state.
- **FR-005**: Gate evaluation MUST always re-scan artifacts at query time — never rely on cached or stale state.

**QA Verification Integration**

- **FR-006**: The workflow MUST propose `/qa.plan` as the next step when Gate C is satisfied and no QA plan exists.
- **FR-007**: The workflow MUST propose `/qa.run` as the next step when a QA plan exists but no QA verdict exists.
- **FR-008**: The workflow MUST read the QA verdict (PASS/FAIL) from the QA test results artifact.
- **FR-009**: The workflow MUST display QA status (PASS/FAIL/pending) in the progress dashboard.

**PR Creation & Traceability**

- **FR-010**: The system MUST provide a `/feature.pr {feature}` command that creates a GitHub pull request.
- **FR-011**: The `/feature.pr` command MUST enforce prerequisites before proceeding: QA PASS, Agreement Check PASS, all tasks done.
- **FR-012**: The PR body MUST contain: specification link, agreement link, QA results summary with check count, agreement check verdict, originating feedbacks, linked backlogs, and git diff summary.
- **FR-013**: Missing optional artifacts (feedbacks, backlogs) MUST result in "N/A" in the PR body, not errors.
- **FR-014**: The system MUST fail gracefully with a clear error message when the GitHub CLI is not available or not authenticated.

**Post-Merge Lifecycle Resolution**

- **FR-015**: The system MUST allow the developer to trigger post-merge resolution after a PR is merged.
- **FR-016**: The system MUST detect PR merge status before proceeding with resolution.
- **FR-017**: Post-merge resolution MUST transition the feature stage to "release".
- **FR-018**: Post-merge resolution MUST transition all linked backlogs to "done".
- **FR-019**: Post-merge resolution MUST transition all originating feedbacks to "resolved".
- **FR-020**: State transitions MUST be all-or-nothing — no partial updates on failure.

**QA FAIL Governance Loop**

- **FR-021**: When QA verdict is FAIL, the system MUST auto-generate a critical backlog from the QA findings.
- **FR-022**: The auto-generated backlog MUST include the specific failing checks as findings with traceability to the QA report.
- **FR-023**: After a QA FAIL, the workflow MUST redirect to the governance fix path: backlog, spec update, tasks, implementation, QA re-run.
- **FR-024**: After a QA re-run, gates MUST re-evaluate based on the new verdict.

**Backward Compatibility**

- **FR-025**: Features without QA artifacts MUST display QA steps as optional/skip in the dashboard.
- **FR-026**: The workflow MUST work on all existing features (001-009) without errors or regressions.
- **FR-027**: QA-related gates MUST NOT block features that predate the V2 workflow and have no QA artifacts.

### Key Entities

- **Gate**: A mechanical checkpoint in the workflow chain that evaluates pass/fail based on artifact state. Gates are deterministic — they compute readiness from artifacts, not from declarations. Gate C requires task completion. Gate D requires QA PASS and Agreement Check PASS.
- **Traceability Chain**: The linked sequence of governance artifacts for a feature: specification, agreement, QA results, originating feedbacks, linked backlogs. The PR body is the materialization of this chain.
- **Governance Loop**: The recovery cycle triggered by QA FAIL: QA findings, critical backlog (via product-manager), spec update, new tasks, implementation, QA re-run. The loop continues until QA passes.
- **Lifecycle Resolution**: The set of state transitions that close a feature's governance chain after PR merge: feature to "release", backlogs to "done", feedbacks to "resolved".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After implementation tasks reach 100%, the developer completes the entire QA to PR to release path without editing any state file by hand (0 manual state edits per feature).
- **SC-002**: 100% of PRs created through `/feature.pr` contain links to specification, agreement, QA results, and all existing feedbacks and backlogs.
- **SC-003**: Post-merge resolution updates all linked artifacts (feature stage + backlogs + feedbacks) in a single operation with zero partial failures.
- **SC-004**: All existing features (001-009) continue to work through `/feature.workflow` after V2 installation with zero regressions.
- **SC-005**: Feature 010-feature-lifecycle-v2 is delivered through its own V2 workflow, with `/feature.status 010` showing "release" at completion (self-proving delivery).
- **SC-006**: When QA returns FAIL, the governance loop produces a critical backlog within the same workflow session — the developer is never left without a next action.

## Assumptions

- The QA system (009-qa-system) is installed and operational. `/qa.plan` and `/qa.run` commands work independently.
- The agreement system is installed. `/agreement.check` and `/agreement.doctor` commands work independently.
- The product-manager system is installed for the QA FAIL governance loop. If not installed, the loop degrades gracefully.
- The GitHub CLI (`gh`) is installed and authenticated for PR creation and merge detection.
- All artifact directories (`.features/`, `.agreements/`, `.qa/`, `.product/`, `specs/`) follow existing kai conventions.
- Features are delivered on branches that are merged via GitHub PRs. Direct pushes to main are not in scope.

## Scope Boundaries

**In scope**:
- Workflow dashboard extension with QA, PR, and post-merge steps
- New `/feature.pr` command
- Post-merge lifecycle resolution
- QA FAIL to product-manager governance loop
- Backward compatibility for existing features

**Out of scope**:
- Auto-merge for non-breaking changes (future Phase 2)
- Batch release — multiple features in one PR (future Phase 3)
- Release notes generation (future Phase 3)
- Cross-feature dependency awareness (future Phase 3)
- CI/CD integration — no GitHub Actions or webhooks
- Multi-reviewer workflows — human review happens natively on GitHub

## Dependencies

- **009-qa-system**: QA plan and run commands, test results artifacts
- **002-agreement-system**: Agreement check and doctor commands, check reports
- **008-product-manager**: Backlog creation mechanism for QA FAIL governance loop
- **003-feature-lifecycle**: The existing workflow and status commands being extended
- **GitHub CLI (`gh`)**: External dependency for PR creation and merge detection

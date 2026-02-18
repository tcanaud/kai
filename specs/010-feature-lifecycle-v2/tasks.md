# Tasks: Feature Lifecycle V2

**Input**: Design documents from `specs/010-feature-lifecycle-v2/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Package infrastructure and shared detection modules

- [x] T001 Add `.qa/` and `.product/` detection to `packages/feature-lifecycle/src/detect.js` — add `hasQa` (`.qa/` exists), `hasProduct` (`.product/` exists), and `hasGhCli` (`command -v gh`) fields to the returned object
- [x] T002 Create QA scanner module at `packages/feature-lifecycle/src/scanners/qa.js` — export `scanQa(projectRoot, config, featureId)` that checks for `.qa/{featureId}/_index.yaml` (plan exists), reads `.qa/{featureId}/verdict.yaml` if present (verdict, passed, failed, total, spec_sha256, failures), computes freshness by comparing spec_sha256 against current SHA-256 of `specs/{featureId}/spec.md`, and returns `{ plan_exists, verdict, verdict_fresh, passed, failed, total, failures }` with sensible defaults when files are missing
- [x] T003 Register QA scanner in `packages/feature-lifecycle/src/scanners/index.js` — import `scanQa` from `./qa.js`, add to exports, and include `qa` results in the `scanAllArtifacts` return object with fields: `{ plan_exists, verdict, verdict_fresh, passed, failed, total }`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The workflow command template must exist before any user story can be validated

**Warning**: No user story work can begin until this phase is complete

- [x] T004 Copy existing `.claude/commands/feature.workflow.md` to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — the workflow command currently exists only as an installed file, not as a package template; copy it so the package owns the source of truth and the updater can manage it going forward
- [x] T005 Add `feature.workflow.md` to the command mappings array in `packages/feature-lifecycle/src/installer.js` (line ~105, `commandMappings`) and `packages/feature-lifecycle/src/updater.js` (line ~43, `commandMappings`) so both init and update install/update the workflow command alongside the existing four commands

**Checkpoint**: Package infrastructure ready — workflow template is now package-owned and installable

---

## Phase 3: User Story 1 — Guided Endgame via Workflow Dashboard (Priority: P1)

**Goal**: After all tasks reach 100%, the developer sees the complete endgame path (QA → PR → Release) in the workflow dashboard with mechanical gate evaluation.

**Independent Test**: Run `/feature.workflow` on a feature with all tasks done. Verify QA Plan appears as the next step. Simulate QA PASS + Agreement Check PASS. Verify PR creation appears as the next step. Dashboard shows all new steps with correct gate statuses.

### Implementation for User Story 1

- [x] T006 [US1] Extend the Full Method dependency chain in `packages/feature-lifecycle/templates/commands/feature.workflow.md` — after existing step 11 (Feature Status), add step 12 (QA Plan), step 13 (QA Run), step 14 (Agreement Check), Gate D, step 15 (PR Creation), and step 16 (Post-Merge Resolution) per the contract in `specs/010-feature-lifecycle-v2/contracts/feature.workflow-v2.md` section "New Steps (Full Method)"
- [x] T007 [US1] Extend the Quick Flow dependency chain in `packages/feature-lifecycle/templates/commands/feature.workflow.md` — after existing step 5 (Feature Status), add step 6 (QA Plan), step 7 (QA Run), Gate D, step 8 (PR Creation), and step 9 (Post-Merge Resolution) per the contract section "New Steps (Quick Flow)"
- [x] T008 [US1] Add new artifact detection instructions to the artifact scan section (step 5) of `packages/feature-lifecycle/templates/commands/feature.workflow.md` — add detection for `qa.plan_exists` (`.qa/{FEATURE}/_index.yaml` exists), `qa.verdict` (read from `.qa/{FEATURE}/verdict.yaml`), `qa.verdict_fresh` (compare spec_sha256 in verdict.yaml against current SHA-256 of `specs/{FEATURE}/spec.md`), `pr.url` (via `gh pr list --head "{BRANCH}" --state open --json url --jq '.[0].url // ""'`), and `pr.merged` (via `gh pr list --head "{BRANCH}" --state merged --json number --jq 'length'`)
- [x] T009 [US1] Add Gate C-V2 evaluation logic to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — Gate C-V2 passes when `tasks_done == tasks_total AND tasks_total > 0`; this replaces the existing Gate C (50% threshold) for the QA unlock; the existing 50% threshold remains for Agreement Check timing at step 14
- [x] T010 [US1] Add Gate D evaluation logic to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — Full Method: `qa.verdict == "PASS" AND qa.verdict_fresh == true AND agreement.check == "PASS"`; Quick Flow: `qa.verdict == "PASS" AND qa.verdict_fresh == true`; Gate D unlocks PR Creation (step 15/8)
- [x] T011 [US1] Update the dashboard display (step 7) in `packages/feature-lifecycle/templates/commands/feature.workflow.md` — add rows for Gate C-V2, QA Plan, QA Run, Agreement Check, Gate D, PR Creation, and Post-Merge Resolution to the progress table with new status values: `FAIL` (QA Run returned FAIL), `stale` (QA verdict outdated), and `skip` (not applicable for this feature)
- [x] T012 [US1] Add QA stale verdict handling to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — when verdict.yaml exists but spec_sha256 doesn't match current spec.md, show QA status as "stale", block Gate D, and propose: re-run `/qa.plan {FEATURE}` then `/qa.run {FEATURE}`
- [x] T013 [US1] Add `gh` CLI availability check to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — before evaluating PR/merge artifact keys, check `command -v gh` and `gh auth status`; if either fails, show PR Creation and Post-Merge steps as `blocked` with an explanatory note instead of erroring
- [x] T014 [US1] Update the "next action" proposal logic (step 8) in `packages/feature-lifecycle/templates/commands/feature.workflow.md` — when all existing steps are complete, the next step should now be the first incomplete V2 step rather than showing "Status: Complete"; update the "ALL steps complete" message to include `/feature.resolve {FEATURE}` in suggested actions
- [x] T015 [US1] Add the updated handoffs section to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — add handoff entries for QA steps (`/qa.plan`, `/qa.run`), PR creation (`/feature.pr`), and post-merge resolution (`/feature.resolve`)
- [x] T016 [US1] Copy updated `packages/feature-lifecycle/templates/commands/feature.workflow.md` to `.claude/commands/feature.workflow.md` so the local dev environment has the V2 workflow immediately available for testing

**Checkpoint**: `/feature.workflow` shows the complete endgame path with Gate C-V2/D evaluation for the current feature

---

## Phase 4: User Story 2 — PR Creation with Full Traceability (Priority: P2)

**Goal**: `/feature.pr {feature}` creates a GitHub PR with the complete governance lineage, enforcing mechanical prerequisites.

**Independent Test**: Given a feature with all prerequisites satisfied (QA PASS, Agreement PASS, tasks 100%), run `/feature.pr`. Verify the PR is created on GitHub with all traceability links in the body.

### Implementation for User Story 2

- [x] T017 [US2] Create the `/feature.pr` command template at `packages/feature-lifecycle/templates/commands/feature.pr.md` — implement the full execution flow per the contract in `specs/010-feature-lifecycle-v2/contracts/feature.pr.md`: Step 1 prerequisite checks (gh installed, gh authenticated, feature exists, tasks 100%, QA PASS, QA fresh, agreement check PASS, no duplicate PR), Step 2 traceability data gathering (spec, agreement, QA results, agreement check, feedbacks, backlogs, diff summary), Step 3 PR body assembly per the template in data-model.md section 4, Step 4 PR creation via `gh pr create --title "feat({feature_id}): {title}" --base main --body-file -`, Step 5 success/failure report
- [x] T018 [US2] Implement prerequisite check details in `packages/feature-lifecycle/templates/commands/feature.pr.md` — for each check, specify the exact detection method: `command -v gh`, `gh auth status`, `.features/{FEATURE}.yaml` exists, `tasks_done == tasks_total` from tasks.md checkbox counting, `.qa/{FEATURE}/verdict.yaml` verdict field == "PASS", spec_sha256 freshness comparison, `.agreements/{FEATURE}/check-report.md` verdict or agreement.yaml existence, `gh pr list --head "{BRANCH}" --state open` empty result
- [x] T019 [US2] Implement traceability data assembly in `packages/feature-lifecycle/templates/commands/feature.pr.md` — gather feedbacks by scanning `.product/feedbacks/*/FB-*.md` for files where `linked_to.features` contains `{FEATURE}`; gather backlogs by scanning `.product/backlogs/*/BL-*.md` for files where `features` contains `{FEATURE}`; handle missing `.product/` directory gracefully with "N/A" per FR-013; gather diff summary via `git diff --stat main...HEAD`
- [x] T020 [US2] Add error handling section to `packages/feature-lifecycle/templates/commands/feature.pr.md` — cover: gh not installed, gh not authenticated, gh pr create failure (display stderr), network errors, duplicate PR (display existing URL), missing optional artifacts (N/A in body)
- [x] T021 [US2] Copy `packages/feature-lifecycle/templates/commands/feature.pr.md` to `.claude/commands/feature.pr.md` for local dev testing

**Checkpoint**: `/feature.pr` creates PRs with full traceability when prerequisites are met, and blocks with clear messages when they aren't

---

## Phase 5: User Story 3 — Post-Merge Lifecycle Resolution (Priority: P3)

**Goal**: After PR merge, `/feature.resolve {feature}` transitions feature to "release", backlogs to "done", and feedbacks to "resolved" in one atomic operation.

**Independent Test**: Given a feature with a merged PR, trigger resolution. Verify feature stage is "release", all linked backlogs are "done", and all feedbacks are "resolved".

### Implementation for User Story 3

- [x] T022 [US3] Create the `/feature.resolve` command template at `packages/feature-lifecycle/templates/commands/feature.resolve.md` — implement the full execution flow per the contract in `specs/010-feature-lifecycle-v2/contracts/feature.resolve.md`: Step 1 prerequisite checks (feature exists, not already released, gh installed, gh authenticated, PR merged), Step 2 collect linked artifacts (backlogs and feedbacks), Step 3 validate all transitions pre-flight, Step 4 apply transitions (backlogs first, feedbacks second, product index third, feature YAML last), Step 5 update feature index, Step 6 report
- [x] T023 [US3] Implement prerequisite check details in `packages/feature-lifecycle/templates/commands/feature.resolve.md` — feature existence via `.features/{FEATURE}.yaml`, release check via `lifecycle.stage != "release"`, merge detection via `gh pr list --head "{BRANCH}" --state merged --json number --jq 'length'` returning > 0; branch resolution: use feature ID as branch name
- [x] T024 [US3] Implement linked artifact collection in `packages/feature-lifecycle/templates/commands/feature.resolve.md` — scan `.product/backlogs/*/BL-*.md` for `features` array containing `{FEATURE}`; scan `.product/feedbacks/*/FB-*.md` for `linked_to.features` containing `{FEATURE}`; if `.product/` doesn't exist, skip backlog and feedback transitions entirely
- [x] T025 [US3] Implement validate-then-apply state transition logic in `packages/feature-lifecycle/templates/commands/feature.resolve.md` — pre-flight validation: all source files exist, all destination directories exist (create if missing), no destination conflicts; apply order: backlogs to done (move + update frontmatter), feedbacks to resolved (move + update frontmatter with resolution block), product index update, feature YAML last with `lifecycle.stage: "release"`, `lifecycle.manual_override: "release"`, `lifecycle.progress: 1.0`, `updated: "{today}"`; report partial failure if any step fails after mutations start
- [x] T026 [US3] Implement idempotency handling in `packages/feature-lifecycle/templates/commands/feature.resolve.md` — already-released feature returns informational message; backlogs already in "done" or feedbacks already in "resolved" are skipped gracefully; only pending transitions are applied
- [x] T027 [US3] Copy `packages/feature-lifecycle/templates/commands/feature.resolve.md` to `.claude/commands/feature.resolve.md` for local dev testing

**Checkpoint**: `/feature.resolve` closes the governance chain after PR merge with atomic state transitions

---

## Phase 6: User Story 4 — QA FAIL Governance Loop (Priority: P4)

**Goal**: When QA returns FAIL, the workflow auto-generates a critical backlog and redirects through the fix cycle.

**Independent Test**: Given a feature with QA FAIL (2 checks failed), verify a critical backlog is created. Run `/feature.workflow` and verify it proposes the fix path. After fixes and QA re-run (PASS), verify Gate D opens.

### Implementation for User Story 4

- [x] T028 [US4] Add QA FAIL detection and backlog generation logic to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — when `verdict.yaml` exists with `verdict: "FAIL"`: (1) check if a QA-FAIL backlog already exists by scanning `.product/backlogs/open/BL-*.md` for files with `tags` containing `"qa-fail"` AND `features` containing `{FEATURE}`, (2) if no existing backlog and `.product/` exists: read `failures` array from verdict.yaml, determine next BL-xxx ID from `.product/index.yaml`, generate a critical backlog at `.product/backlogs/open/BL-{next_id}.md` per the schema in `specs/010-feature-lifecycle-v2/data-model.md` section 5, update `.product/index.yaml`
- [x] T029 [US4] Add graceful degradation when `.product/` is not installed to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — when QA verdict is FAIL but `.product/` directory doesn't exist: display the FAIL findings directly to the developer (script name, criterion ref, assertion, expected vs actual from verdict.yaml failures array), suggest manual backlog creation, do not error
- [x] T030 [US4] Add fix cycle routing to the "next action" proposal in `packages/feature-lifecycle/templates/commands/feature.workflow.md` — when QA FAIL and a critical backlog exists: propose the fix path: "1. Review and process the QA-FAIL backlog (BL-xxx) 2. Update spec/tasks as needed 3. Implement fixes 4. Re-run `/qa.run {FEATURE}` 5. Continue with `/feature.workflow {FEATURE}`"; this replaces the normal next-step proposal when in the FAIL state
- [x] T031 [US4] Add gate re-evaluation after QA re-run to `packages/feature-lifecycle/templates/commands/feature.workflow.md` — after developer fixes issues and re-runs `/qa.run`, a new verdict.yaml is written; next invocation of `/feature.workflow` re-scans verdict.yaml (FR-005: always re-scan at query time); if new verdict is PASS, Gate D opens and workflow proposes PR creation; if still FAIL, generate a new backlog for remaining failures (if previous FAIL backlog no longer matches current failures)
- [x] T032 [US4] Copy updated `packages/feature-lifecycle/templates/commands/feature.workflow.md` to `.claude/commands/feature.workflow.md` to include QA FAIL handling in local dev

**Checkpoint**: QA FAIL triggers automatic backlog generation and guided fix cycle; QA PASS after fixes opens Gate D

---

## Phase 7: User Story 5 — Backward Compatibility (Priority: P5)

**Goal**: Existing features (001-009) continue to work through `/feature.workflow` without errors. QA/PR steps are optional, not blocking.

**Independent Test**: Run `/feature.workflow 007-knowledge-system` (no QA artifacts). Verify dashboard displays without errors, QA steps appear as optional/skip.

### Implementation for User Story 5

- [x] T033 [US5] Add backward-compatible skip logic for QA steps in `packages/feature-lifecycle/templates/commands/feature.workflow.md` — when `.qa/{FEATURE}/_index.yaml` does NOT exist AND `.qa/{FEATURE}/verdict.yaml` does NOT exist: steps 12-16 (Full) / 6-9 (Quick) display as `skip` in the dashboard; Gate D is auto-satisfied; the feature can reach "complete" status through the V1 path; no errors or warnings about missing QA
- [x] T034 [US5] Ensure Gate D does not block pre-V2 features in `packages/feature-lifecycle/templates/commands/feature.workflow.md` — for features where QA steps are `skip`: Gate D evaluation returns `pass` (not `blocked`); the "ALL steps complete" status is reachable for features that complete through the V1 path without QA
- [x] T035 [US5] Copy final `packages/feature-lifecycle/templates/commands/feature.workflow.md` to `.claude/commands/feature.workflow.md` — this is the final copy after all US1-US5 modifications are complete

**Checkpoint**: All existing features (001-009) display correctly through `/feature.workflow` with no regressions

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Package release preparation and installation support

- [x] T036 [P] Add `feature.pr.md` and `feature.resolve.md` to the `commandMappings` array in `packages/feature-lifecycle/src/installer.js` (line ~105) — add entries `["commands/feature.pr.md", ".claude/commands/feature.pr.md"]` and `["commands/feature.resolve.md", ".claude/commands/feature.resolve.md"]`; update the "Available commands" console output (line ~161) to list `/feature.pr` and `/feature.resolve`
- [x] T037 [P] Add `feature.pr.md`, `feature.resolve.md`, and `feature.workflow.md` to the `commandMappings` array in `packages/feature-lifecycle/src/updater.js` (line ~43) — add entries for the three new/updated commands so `feature-lifecycle update` installs them
- [x] T038 [P] Update environment detection display in `packages/feature-lifecycle/src/installer.js` (line ~39) — add lines for `QA System:` (`env.hasQa`), `Product Manager:` (`env.hasProduct`), and `GitHub CLI:` (`env.hasGhCli`) to the "Environment detected" output
- [x] T039 Bump version in `packages/feature-lifecycle/package.json` from `"1.0.3"` to `"1.1.0"` — minor version bump for new commands and workflow extension; update description to mention V2 capabilities
- [x] T040 Validate quickstart by running `/feature.workflow 010-feature-lifecycle-v2` and confirming the V2 dashboard renders correctly with all new steps visible

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — foundational because US2-US5 all depend on the extended workflow
- **US2 (Phase 4)**: Depends on Phase 3 (workflow must propose `/feature.pr` as next step)
- **US3 (Phase 5)**: Depends on Phase 4 (workflow must propose `/feature.resolve` after PR creation)
- **US4 (Phase 6)**: Depends on Phase 3 (adds QA FAIL handling to the workflow already extended by US1)
- **US5 (Phase 7)**: Depends on Phases 3-6 (verifies backward compatibility after all modifications)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Foundation — all other stories depend on this
- **US2 (P2)**: Depends on US1 (Gate D must exist to enforce prerequisites); can start after US1 complete
- **US3 (P3)**: Independent of US2 (can start after US1); but recommended after US2 since `/feature.resolve` is reached after `/feature.pr`
- **US4 (P4)**: Depends on US1 (adds FAIL handling to the same workflow template); independent of US2/US3
- **US5 (P5)**: Depends on US1-US4 (verifies nothing broke)

### Within Each User Story

- Template modifications before local copy
- Detection/scanning before gate evaluation
- Gate evaluation before next-action proposal

### Parallel Opportunities

- Phase 1: T001, T002, T003 can run in parallel (different files)
- Phase 2: T004 and T005 are sequential (copy then register)
- Phase 3: T006-T015 are sequential within the same file (feature.workflow.md)
- Phase 4: T017-T020 are sequential within the same file (feature.pr.md); T021 after all
- Phase 5: T022-T026 are sequential within the same file (feature.resolve.md); T027 after all
- Phase 6: T028-T031 are sequential within the same file (feature.workflow.md); T032 after all
- Phase 8: T036, T037, T038 can run in parallel (different files); T039 after; T040 last

---

## Parallel Example: Phase 1

```
Task: "Add .qa/ and .product/ detection to packages/feature-lifecycle/src/detect.js"
Task: "Create QA scanner module at packages/feature-lifecycle/src/scanners/qa.js"
Task: "Register QA scanner in packages/feature-lifecycle/src/scanners/index.js"
```

T001 and T002 can run in parallel (different files). T003 depends on T002.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T005)
3. Complete Phase 3: User Story 1 (T006-T016)
4. **STOP and VALIDATE**: Run `/feature.workflow` on a feature with completed tasks; verify QA/PR/resolve steps appear with correct gate evaluation

### Incremental Delivery

1. Setup + Foundational → Package infrastructure ready
2. US1 → Workflow dashboard extended with QA/PR/resolve (MVP!)
3. US2 → `/feature.pr` command available → Test PR creation
4. US3 → `/feature.resolve` command available → Test post-merge resolution
5. US4 → QA FAIL governance loop operational → Test FAIL recovery
6. US5 → Backward compatibility verified → All existing features work
7. Polish → Package ready for release

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All slash command templates are Markdown files that instruct Claude Code — not executable code
- The primary deliverables are 3 template files: feature.workflow.md (updated), feature.pr.md (new), feature.resolve.md (new)
- JS modules (scanners, detect) support the installer/updater and `/feature.status` programmatic access
- `gh` CLI commands are executed by Claude Code at runtime, not by Node.js code
- Each "copy to .claude/commands/" task ensures the local dev environment matches the package template

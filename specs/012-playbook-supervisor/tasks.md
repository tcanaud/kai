# Tasks: Playbook Supervisor

**Input**: Design documents from `/specs/012-playbook-supervisor/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not requested in specification — test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single package**: `packages/playbook/` — npm package with CLI entry point + slash command templates

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Package initialization and directory structure

- [x] T001 Create package directory structure per plan.md: `packages/playbook/` with subdirectories `bin/`, `src/`, `templates/commands/`, `templates/core/`, `templates/playbooks/`, `tests/`
- [x] T002 [P] Initialize `packages/playbook/package.json` with `"type": "module"`, `"name": "@tcanaud/playbook"`, `"bin": { "playbook": "./bin/cli.js" }`, engine `"node": ">=18.0.0"`, zero runtime dependencies
- [x] T003 [P] Create CLI entry point with switch/case command router for `init`, `update`, `start`, `check`, `help` in `packages/playbook/bin/cli.js` — each case imports from `../src/` and calls the handler; `help` prints usage inline

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core modules and template files that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Implement regex-based YAML parser specialized for the playbook schema in `packages/playbook/src/yaml-parser.js` — parse top-level scalar fields (name, description, version), `args` array, and `steps` array with all known fields (id, command, args, autonomy, preconditions, postconditions, error_policy, escalation_triggers, parallel_group); validate enum values during parsing; export a `parsePlaybook(content)` function returning a structured object or throwing on invalid input
- [x] T005 [P] Implement session management module in `packages/playbook/src/session.js` — `generateSessionId()` using `{YYYYMMDD}-{3char}` format with collision retry (max 3); `createSession(playbookName, feature, args, worktree)` writes `session.yaml` manifest; `readSession(sessionDir)` parses manifest; `updateSession(sessionDir, fields)` updates manifest fields; `appendJournalEntry(sessionDir, entry)` appends to `journal.yaml` with all audit fields (step_id, status, decision, started_at, completed_at, duration_seconds, trigger, human_response, error); `readJournal(sessionDir)` parses journal entries; `findInProgressSessions(playbooksDir)` scans sessions for `status: in_progress`
- [x] T006 [P] Implement environment detection module in `packages/playbook/src/detect.js` — `detectPlaybooksDir()` checks if `.playbooks/` exists; `detectClaudeCommands()` checks if `.claude/commands/` exists; `getRepoRoot()` runs `git rev-parse --show-toplevel`; `isWorktree()` compares `git rev-parse --show-toplevel` with `git rev-parse --git-common-dir`; export all functions
- [x] T007 [P] Create playbook index template in `packages/playbook/templates/core/_index.yaml` — structure with `generated` timestamp placeholder and `playbooks` array with entries for auto-feature and auto-validate (name, file, description, steps count)
- [x] T008 [P] Create commented playbook template in `packages/playbook/templates/core/playbook.tpl.yaml` — fully commented YAML documenting all fields and allowed values (autonomy levels: auto/gate_on_breaking/gate_always/skip; error policies: stop/retry_once/gate; conditions vocabulary; escalation triggers), with example steps
- [x] T009 [P] Create auto-feature built-in playbook in `packages/playbook/templates/playbooks/auto-feature.yaml` — 8-step sequential workflow: plan → tasks → agreement → implement → agreement-check → qa-plan → qa-run → pr; each step with appropriate autonomy, conditions, error_policy, and escalation_triggers per plan.md data model section
- [x] T010 [P] Create auto-validate built-in playbook in `packages/playbook/templates/playbooks/auto-validate.yaml` — 2-step workflow: qa-plan (precondition: spec_exists, postcondition: qa_plan_exists) → qa-run (precondition: qa_plan_exists, postcondition: qa_verdict_pass); both steps auto autonomy, stop error policy

**Checkpoint**: Foundation ready — all shared modules and templates exist. User story implementation can begin.

---

## Phase 3: User Story 1 — Spec to PR Without Manual Command Chaining (Priority: P1) MVP

**Goal**: A developer launches a playbook run command and the supervisor chains all steps autonomously, halting only at configured gates and escalations, producing the same artifacts as manual execution.

**Independent Test**: Launch `/playbook.run auto-feature {feature}` on a feature with a completed spec. Verify the supervisor chains steps, halts at gates, writes journal entries, and produces artifacts identical to manual slash command execution.

### Implementation for User Story 1

- [x] T011 [US1] Implement installer (init command) in `packages/playbook/src/installer.js` — create `.playbooks/` directory tree (playbooks/, sessions/, templates/); copy built-in playbooks from package templates/playbooks/ to `.playbooks/playbooks/`; copy template playbook from templates/core/playbook.tpl.yaml to `.playbooks/playbooks/`; generate `_index.yaml` from templates/core/ with current timestamp; ensure `.claude/commands/` exists; copy slash command templates from templates/commands/ to `.claude/commands/`; support `--yes` flag to skip confirmation; log each created file; idempotent (safe to re-run, overwrites templates but preserves sessions and custom playbooks)
- [x] T012 [P] [US1] Implement updater (update command) in `packages/playbook/src/updater.js` — verify `.playbooks/` exists (exit 1 if not); overwrite built-in playbooks and template from package templates; overwrite slash command files in `.claude/commands/`; regenerate `_index.yaml` with updated timestamp; never modify sessions/ or user-created playbook files; log updated files
- [x] T013 [US1] Create `/playbook.run` supervisor slash command prompt in `packages/playbook/templates/commands/playbook.run.md` — comprehensive Markdown prompt (~200-300 lines) instructing Claude Code to: (1) parse `$ARGUMENTS` for playbook name and feature; (2) read playbook YAML from `.playbooks/playbooks/{playbook}.yaml`; (3) check for existing in-progress session or create new one via session.js patterns; (4) for each step: check preconditions (filesystem checks per condition vocabulary), evaluate autonomy level, delegate via Task subagent with fresh context, check postconditions, write journal entry with all audit fields; (5) gate protocol: halt at gate_always steps with context+question, halt on escalation triggers, record human responses; (6) error handling: stop/retry_once/gate policies; (7) parallel phases: launch multiple Task calls in single message for steps with same parallel_group; (8) completion: update session status, report summary with step count, duration, and decisions

**Checkpoint**: At this point, `npx @tcanaud/playbook init` works and `/playbook.run` can orchestrate a full feature workflow.

---

## Phase 4: User Story 5 — Playbook Validation Before Execution (Priority: P2)

**Goal**: A developer validates a custom playbook YAML against the strict schema before running it, getting specific violation reports.

**Independent Test**: Run `npx @tcanaud/playbook check` against a valid playbook (expect exit 0 with confirmation) and against intentionally malformed playbooks (expect exit 1 with specific violation messages).

### Implementation for User Story 5

- [x] T014 [US5] Implement playbook validator (check command) in `packages/playbook/src/validator.js` — import `parsePlaybook` from yaml-parser.js; validate: all required top-level fields present (name, description, version, args, steps); steps array is non-empty; each step has required fields (id, command, autonomy, error_policy); step IDs are unique; step IDs match pattern `[a-z0-9-]+`; autonomy values in allowed set (auto, gate_on_breaking, gate_always, skip); error_policy values in allowed set (stop, retry_once, gate); escalation_triggers values in allowed set (postcondition_fail, verdict_fail, agreement_breaking, subagent_error); precondition/postcondition values in allowed set (spec_exists, plan_exists, tasks_exists, agreement_exists, agreement_pass, qa_plan_exists, qa_verdict_pass, pr_created); `{{arg}}` references in step args match declared arg names; on success print `checkmark {file} is valid`; on failure print violation list with step reference and allowed values; exit 0 on valid, exit 1 on invalid

**Checkpoint**: `npx @tcanaud/playbook check` validates any playbook YAML against the complete schema.

---

## Phase 5: User Story 2 — Crash Recovery Without Data Loss (Priority: P2)

**Goal**: A developer resumes a crashed playbook session without arguments — the system auto-detects the active session, checks postconditions of the last in-progress step, and continues from the correct point.

**Independent Test**: Launch a playbook, manually interrupt mid-execution, then run `/playbook.resume` and verify it identifies the correct session, skips completed steps, and resumes from the right step.

### Implementation for User Story 2

- [x] T015 [US2] Create `/playbook.resume` slash command prompt in `packages/playbook/templates/commands/playbook.resume.md` — Markdown prompt instructing Claude Code to: (1) find repo root via `git rev-parse --show-toplevel`; (2) scan `.playbooks/sessions/*/session.yaml` for `status: in_progress`; (3) if multiple in-progress sessions: pick most recent by timestamp prefix in session ID; (4) if none found: report "no active session found" and stop; (5) read the session manifest to get playbook name and feature; (6) read the playbook YAML; (7) read the journal to find last completed step and any in-progress step; (8) for in-progress step: check its postconditions — if met, mark done and advance; if not met, re-run the step; (9) continue execution using the same orchestration loop as /playbook.run (preconditions, autonomy, delegation, postconditions, journal, gates, error policies)

**Checkpoint**: `/playbook.resume` can recover any interrupted session and continue without re-executing completed steps.

---

## Phase 6: User Story 3 — Audit Trail in Git (Priority: P3)

**Goal**: Session journal files are human-readable, git-tracked, and contain complete audit data for every step — including escalation triggers and human responses at gates.

**Independent Test**: Complete a playbook run that includes at least one escalation, then inspect the journal file for complete entries with status, decision type, duration, trigger, and human response.

### Implementation for User Story 3

- [x] T016 [US3] Verify and enhance journal write logic in `packages/playbook/src/session.js` to ensure `appendJournalEntry` computes `duration_seconds` from `started_at` and `completed_at` timestamps, formats YAML with readable field ordering (step_id first, then status, decision, timestamps, duration, trigger, human_response, error), and omits empty optional fields (trigger, human_response, error) only when not applicable — ensuring journal entries are concise yet audit-complete per data-model.md

**Checkpoint**: Journal files produced during playbook runs are human-readable in PR diffs and contain full audit metadata.

---

## Phase 7: User Story 4 — Parallel Features via Worktrees (Priority: P3)

**Goal**: A developer runs a CLI command that creates a dedicated git worktree with a new session, enabling parallel playbook execution in separate terminals.

**Independent Test**: Run `npx @tcanaud/playbook start` twice with different features, verify two separate worktrees and sessions exist with unique paths, and that session directories produce no merge conflicts.

### Implementation for User Story 4

- [x] T017 [US4] Implement worktree management (start command) in `packages/playbook/src/worktree.js` — verify git working tree is clean via `git status --porcelain` (exit 1 with message if dirty); verify playbook exists in `.playbooks/playbooks/{playbook}.yaml` (exit 1 if not); generate session ID via session.js; create session directory `.playbooks/sessions/{id}/`; write initial `session.yaml` with status `pending` and worktree path; write empty `journal.yaml` with `entries: []`; run `git worktree add ../kai-session-{id} {current-branch}` (exit 2 on failure); print success message with instructions: session ID, worktree path, commands to run (`cd ../kai-session-{id} && claude` then `/playbook.run {playbook} {feature}`)

**Checkpoint**: `npx @tcanaud/playbook start` creates isolated worktree sessions for parallel feature development.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Package completeness and final validation

- [x] T018 [P] Create README.md with installation, usage, and CLI reference in `packages/playbook/README.md`
- [x] T019 [P] Create LICENSE file in `packages/playbook/LICENSE`
- [x] T020 Run quickstart.md validation — execute the quickstart scenario end-to-end to verify init, check, and slash command installation work correctly

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — core supervisor loop
- **US5 (Phase 4)**: Depends on Foundational (yaml-parser.js) — can run in parallel with US1
- **US2 (Phase 5)**: Depends on Foundational (session.js) — can run in parallel with US1 and US5
- **US3 (Phase 6)**: Depends on Foundational (session.js) — can run in parallel with US1
- **US4 (Phase 7)**: Depends on Foundational (session.js) — can run in parallel with US1
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — no dependencies on other stories
- **US5 (P2)**: Can start after Foundational — independent of US1 (validator uses yaml-parser directly)
- **US2 (P2)**: Can start after Foundational — conceptually depends on US1 existing (resume needs something to resume), but implementation is independent (separate slash command file)
- **US3 (P3)**: Can start after Foundational — refines session.js journal logic, independent of other stories
- **US4 (P3)**: Can start after Foundational — worktree.js is a standalone module, independent of other stories

### Within Each User Story

- Modules before CLI wiring
- Templates before slash commands
- Core implementation before integration

### Parallel Opportunities

- T002 and T003 can run in parallel (different files)
- T005, T006, T007, T008, T009, T010 can all run in parallel (different files, no dependencies)
- T011 and T012 can run in parallel (installer vs updater, different files)
- US1, US5, US2, US3, US4 can all start in parallel after Phase 2 (independent modules and files)
- T018 and T019 can run in parallel (different files)

---

## Parallel Example: Foundational Phase

```bash
# Launch all independent foundational modules together:
Task: "Implement session module in packages/playbook/src/session.js"
Task: "Implement detect module in packages/playbook/src/detect.js"
Task: "Create _index.yaml template in packages/playbook/templates/core/_index.yaml"
Task: "Create playbook.tpl.yaml in packages/playbook/templates/core/playbook.tpl.yaml"
Task: "Create auto-feature.yaml in packages/playbook/templates/playbooks/auto-feature.yaml"
Task: "Create auto-validate.yaml in packages/playbook/templates/playbooks/auto-validate.yaml"

# Note: T004 (yaml-parser) should complete before T014 (validator) but can run in parallel with other foundational tasks
```

## Parallel Example: User Stories After Foundational

```bash
# All user stories can start in parallel after Phase 2:
Task: "US1 — Implement installer in packages/playbook/src/installer.js"
Task: "US5 — Implement validator in packages/playbook/src/validator.js"
Task: "US2 — Create /playbook.resume prompt in packages/playbook/templates/commands/playbook.resume.md"
Task: "US4 — Implement worktree in packages/playbook/src/worktree.js"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (installer + updater + /playbook.run prompt)
4. **STOP and VALIDATE**: Run `npx @tcanaud/playbook init`, then `/playbook.run auto-feature {feature}` on a feature with a spec
5. Verify the supervisor chains steps and produces correct artifacts

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Core supervisor works → Init + Run functional (MVP!)
3. Add US5 → Validation works → `check` command available
4. Add US2 → Crash recovery works → `resume` command available
5. Add US3 → Journal audit-complete → Full traceability
6. Add US4 → Worktrees work → Parallel execution enabled
7. Polish → Package ready for publish

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- The supervisor logic lives entirely in the /playbook.run slash command prompt — not in Node.js code (per R1 decision)
- Node.js code handles scaffolding, validation, worktree creation, and session file I/O
- YAML parsing is regex-based — no YAML library dependency (per R2 decision)
- Session IDs use {YYYYMMDD}-{3char} format with collision retry (per R3 decision)
- All condition checks use the fixed vocabulary from data-model.md (per R5 decision)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently

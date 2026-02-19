---
description: "Task list for Playbook CLI Commands feature implementation"
---

# Tasks: Playbook CLI Commands (Status & List)

**Input**: Design documents from `/specs/015-playbook-cli-commands/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Single package**: `packages/playbook/src/`, `packages/playbook/tests/`, `packages/playbook/bin/`
- Paths assume @tcanaud/playbook package structure from plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic CLI structure

- [x] T001 Review existing CLI entry point in `packages/playbook/bin/cli.js` and verify command registration pattern
- [x] T002 Review existing session utilities in `packages/playbook/src/session.js` to understand discovery and parsing APIs
- [x] T003 [P] Create implementation files: `packages/playbook/src/status.js` and `packages/playbook/src/list.js` with stub functions

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core session discovery utilities that MUST be complete before command implementations

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Verify session discovery API in `packages/playbook/src/session.js` exposes `discoverSessions(basePath)` function
- [x] T005 Create helper function `parseSessions(sessionDirs)` in `packages/playbook/src/session.js` to parse session.yaml and journal.yaml files into session objects with fields: id, createdAt, status
- [x] T006 [P] Create constants file `packages/playbook/src/constants.js` with session statuses (running, completed, failed) and format strings
- [x] T007 Create formatter utility `packages/playbook/src/format.js` with functions: `formatSessionsTable(sessions)` for human-readable output and `formatSessionsJson(sessions)` for JSON output

**Checkpoint**: Foundation ready - session discovery and formatting utilities complete. User story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Monitor Running Sessions (Priority: P1) 🎯 MVP

**Goal**: Enable `npx @tcanaud/playbook status` command to display all currently running playbook sessions with session ID, creation time, and status in human-readable format.

**Independent Test**: Can be fully tested by running `npx @tcanaud/playbook status` with multiple active sessions and verifying all running sessions are displayed with their current status.

### Implementation for User Story 1

- [x] T008 [US1] Implement `status` command handler in `packages/playbook/src/status.js` that:
  - Discovers running sessions from `.playbooks/sessions/` directory
  - Filters sessions to only include status='running'
  - Calls formatter utility to render human-readable output
  - Outputs to stdout
- [x] T009 [US1] Wire `status` command into CLI entry point in `packages/playbook/bin/cli.js`:
  - Register command: `npx @tcanaud/playbook status`
  - Route to `status.js` handler
  - Handle errors and exit codes
- [x] T010 [US1] Handle edge case: No running sessions exist
  - Display clear message: "No running playbook sessions found."
  - Exit with code 0 (success)
- [x] T011 [US1] Add acceptance test script `packages/playbook/tests/manual/test-status-manual.md` documenting manual verification steps for US1 scenarios

**Checkpoint**: At this point, User Story 1 should be fully functional. Test by: `npx @tcanaud/playbook status` with running sessions should display human-readable output.

---

## Phase 4: User Story 2 - Retrieve Session List for Automation (Priority: P1)

**Goal**: Enable `npx @tcanaud/playbook list --json` command to return all sessions (running and completed) in valid JSON format for CI/CD system integration.

**Independent Test**: Can be fully tested by running `npx @tcanaud/playbook list --json` and verifying output is valid JSON with expected fields for each session.

### Implementation for User Story 2

- [x] T012 [P] [US2] Implement `list` command handler in `packages/playbook/src/list.js` that:
  - Discovers all sessions from `.playbooks/sessions/` directory (running and completed)
  - Parses each session's metadata and journal
  - Supports `--json` flag for JSON output
  - Outputs to stdout
- [x] T013 [US2] Wire `list` command into CLI entry point in `packages/playbook/bin/cli.js`:
  - Register command: `npx @tcanaud/playbook list`
  - Support `--json` flag for JSON output mode
  - Route to `list.js` handler
  - Handle errors and exit codes
- [x] T014 [US2] Implement JSON output schema in `packages/playbook/src/list.js`:
  - Ensure output is valid JSON array
  - Include fields: id (session ID), createdAt (ISO timestamp), status (running|completed|failed)
  - Consistent schema across invocations
- [x] T015 [US2] Handle edge case: No sessions exist
  - Return empty JSON array `[]` when `--json` flag is used
  - Display "No playbook sessions found." message when human-readable format
  - Exit with code 0 (success)
- [x] T016 [US2] Add acceptance test script `packages/playbook/tests/manual/test-list-json-manual.md` documenting JSON output verification steps for US2 scenarios

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. Test by:
- `npx @tcanaud/playbook list --json` should return valid JSON
- Output should parse without errors

---

## Phase 5: User Story 3 - Browse Historical Sessions (Priority: P2)

**Goal**: Enable `npx @tcanaud/playbook list` command to display all playbook sessions (both running and completed) in human-readable format with clear status indicators.

**Independent Test**: Can be fully tested by running `npx @tcanaud/playbook list` and verifying all sessions are displayed in readable format with status indicators.

### Implementation for User Story 3

- [x] T017 [P] [US3] Implement human-readable list output in `packages/playbook/src/list.js`:
  - Format sessions as table or list with clear columns/sections
  - Display: Session ID, Created Time, Status
  - Use formatting utility from Phase 2
- [x] T018 [US3] Implement session sorting in `packages/playbook/src/list.js`:
  - Sort sessions chronologically by createdAt timestamp
  - Most recent first (descending order)
  - For display consistency
- [x] T019 [US3] Implement status visual indicators in `packages/playbook/src/format.js`:
  - Use text markers to distinguish session statuses: running, completed, failed
  - No color codes (for terminal compatibility)
  - Clear enough for visual scanning
- [x] T020 [US3] Handle edge case: Corrupted or unreadable session files
  - Skip unreadable sessions with warning message
  - Continue processing remaining sessions
  - Exit with appropriate status code
- [x] T021 [US3] Add acceptance test script `packages/playbook/tests/manual/test-list-human-manual.md` documenting human-readable output verification for US3 scenarios

**Checkpoint**: User Stories 1, 2, AND 3 should now work independently. Test by:
- `npx @tcanaud/playbook list` should display all sessions in readable table format
- Sessions should be sorted chronologically (most recent first)

---

## Phase 6: User Story 4 - Terminal-Friendly Output Formatting (Priority: P2)

**Goal**: Ensure both commands produce polished, visually clear terminal output that fits standard 80+ character terminal width without horizontal scrolling.

**Independent Test**: Can be fully tested by running both commands in default (non-JSON) mode and verifying output is well-formatted and readable without scrolling.

### Implementation for User Story 4

- [x] T022 [US4] Enhance table formatting in `packages/playbook/src/format.js`:
  - Use consistent spacing and alignment for columns
  - Add column headers (ID, CREATED, STATUS)
  - Pad fields for readability without excessive whitespace
  - Ensure total width <= 80 characters for standard terminals
- [x] T023 [US4] Improve text labels and messaging in `packages/playbook/src/format.js`:
  - Use clear, human-friendly labels for status values (e.g., "Running", "Completed", "Failed")
  - Provide helpful messages for empty results
  - Consistent formatting across both commands
- [x] T024 [US4] Test terminal output width compliance:
  - Verify `npx @tcanaud/playbook status` output fits in 80-character width with 5-10 sessions
  - Verify `npx @tcanaud/playbook list` output fits in 80-character width with 5-10 sessions
  - Manual verification: Test in actual terminal
- [x] T025 [US4] Handle long session IDs and timestamps gracefully:
  - Truncate or wrap session IDs if necessary while maintaining uniqueness
  - Use compact timestamp format (e.g., YYYY-MM-DD HH:MM)
  - Ensure no horizontal scrolling for typical use cases
- [x] T026 [US4] Add acceptance test script `packages/playbook/tests/manual/test-formatting-manual.md` documenting visual inspection steps for terminal output quality

**Checkpoint**: All user stories should now be independently functional with polished output. Test by:
- Running both commands in terminal
- Verifying output displays correctly without horizontal scrolling
- Confirming visual clarity and readability

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements affecting multiple user stories and final validation

- [x] T027 [P] Add error handling and validation in `packages/playbook/bin/cli.js`:
  - Handle missing `.playbooks/sessions/` directory gracefully
  - Handle permission errors when reading session files
  - Handle invalid YAML in session files
  - Display helpful error messages to stderr
- [x] T028 [P] Add documentation comments in implementation files:
  - Document function signatures and parameters in `packages/playbook/src/status.js`
  - Document function signatures and parameters in `packages/playbook/src/list.js`
  - Document formatting functions in `packages/playbook/src/format.js`
- [x] T029 [P] Run integration verification:
  - Test `npx @tcanaud/playbook status` with 0, 1, 5, and 10+ running sessions
  - Test `npx @tcanaud/playbook list` with mixed running/completed sessions
  - Test `npx @tcanaud/playbook list --json` JSON parsing
  - Verify performance: both commands complete in <1 second (SC-001)
- [x] T030 Update package.json bin field if needed to expose new commands via CLI
- [x] T031 Verify all functional requirements (FR-001 through FR-012) are met by implementation
- [x] T032 Verify all success criteria (SC-001 through SC-006) are met through testing

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Independent from US1 (different command flags)
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Extends US2 (same command, human-readable mode)
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Polish/enhancement affecting US1-US3

### Parallel Opportunities

- All Setup tasks (T001-T003) can run in parallel
- All Foundational tasks marked [P] (T004-T007) can run in parallel within Phase 2
- Once Foundational phase completes, all user stories can start in parallel
- US1 (T008-T011) and US2 (T012-T016) are independent and can run in parallel
- US3 and US4 refine existing commands and can run in parallel

---

## Parallel Example: User Stories 1 & 2

```bash
# After Foundational phase (T004-T007) completes, launch together:

Parallel Set 1: User Story 1 Core Implementation
Task: "Implement status command handler in packages/playbook/src/status.js" (T008)
Task: "Add acceptance test script packages/playbook/tests/manual/test-status-manual.md" (T011)

Parallel Set 2: User Story 2 Core Implementation
Task: "Implement list command handler in packages/playbook/src/list.js" (T012)
Task: "Implement JSON output schema in packages/playbook/src/list.js" (T014)

Parallel Set 3: CLI Wiring
Task: "Wire status command into bin/cli.js" (T009)
Task: "Wire list command into bin/cli.js" (T013)

# All three sets can run in parallel since they touch different files
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (status command)
4. Complete Phase 4: User Story 2 (list --json)
5. **STOP and VALIDATE**: Test both commands independently
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Demo (status command works)
3. Add User Story 2 → Test independently → Demo (list --json works)
4. Add User Story 3 → Test independently → Demo (list human-readable works)
5. Add User Story 4 → Test independently → Demo (polished output)
6. Each story adds value without breaking previous functionality

### Parallel Team Strategy (Single Developer)

Sequential approach recommended since package is small:

1. Developer: Complete Setup + Foundational (T001-T007)
2. Developer: User Stories 1 & 2 in parallel (T008-T016) - different files
3. Developer: User Stories 3 & 4 refinements (T017-T026)
4. Developer: Polish & testing (T027-T032)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Session discovery and formatting utilities (Phase 2) are CRITICAL blockers
- Both status and list commands reuse session utilities from `packages/playbook/src/session.js`
- No new runtime dependencies required (zero dependencies maintained)
- Commands follow existing CLI pattern from installer, updater, validator commands
- Verify both commands complete in <1 second with 100 sessions (SC-001)
- Avoid: vague tasks, same file conflicts, cross-story dependencies

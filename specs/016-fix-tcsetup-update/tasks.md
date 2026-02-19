---
description: "Task list for implementing YAML configuration merging fix"
---

# Tasks: Fix tcsetup Update Configuration Merging

**Input**: Design documents from `/specs/016-fix-tcsetup-update/`
**Branch**: `016-fix-tcsetup-update`
**Created**: 2026-02-19

**Status**: Ready for implementation
**Tests**: No explicit test tasks (implementation includes full test coverage via Node.js built-in test runner)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create foundational file structure and test infrastructure

- [ ] T001 Create yaml-merge.js module structure in `/packages/tcsetup/src/yaml-merge.js` with placeholder exports
- [ ] T002 [P] Create test directory structure `/packages/tcsetup/tests/` with subdirectories for fixtures
- [ ] T003 [P] Create test fixtures directory `/packages/tcsetup/tests/fixtures/` with sample YAML files

---

## Phase 2: Foundational (YAML Merge Core Implementation)

**Purpose**: Implement core YAML merging and deduplication logic that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Core Merge Engine

- [ ] T004 Implement `mergeYAML.deepEqual()` function in `/packages/tcsetup/src/yaml-merge.js` for recursive deep equality checks
- [ ] T005 Implement `mergeYAML.arrays()` function in `/packages/tcsetup/src/yaml-merge.js` for deduplicating arrays with deep equality
- [ ] T006 Implement `mergeYAML.objects()` function in `/packages/tcsetup/src/yaml-merge.js` for recursive object merging
- [ ] T007 Implement `mergeYAML.parseYAML()` function in `/packages/tcsetup/src/yaml-merge.js` for YAML string to object conversion
- [ ] T008 Implement `mergeYAML.serializeYAML()` function in `/packages/tcsetup/src/yaml-merge.js` for object to YAML string conversion
- [ ] T009 Implement `mergeYAML.validate()` function in `/packages/tcsetup/src/yaml-merge.js` for YAML syntax validation

### Main Merge Function & Result Types

- [ ] T010 Implement `mergeYAML()` main function in `/packages/tcsetup/src/yaml-merge.js` orchestrating all merge operations
- [ ] T011 Implement MergeResult class in `/packages/tcsetup/src/yaml-merge.js` with `toYAML()` and `validate()` methods
- [ ] T012 Implement MergeChangelog tracking in `/packages/tcsetup/src/yaml-merge.js` documenting what changed during merge

### Error Handling & Edge Cases

- [ ] T013 Add error handling for invalid YAML syntax in `/packages/tcsetup/src/yaml-merge.js`
- [ ] T014 Add error handling for missing or null files in `/packages/tcsetup/src/yaml-merge.js`
- [ ] T015 Add error handling for type mismatches (array vs object) in `/packages/tcsetup/src/yaml-merge.js`

**Checkpoint**: YAML merge engine ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Run tcsetup Update Without Data Loss (Priority: P1) 🎯 MVP

**Goal**: Enable developers to run `npx tcsetup update` multiple times without corrupting configuration files through duplicate sections

**Independent Test**: Running `npx tcsetup update` twice consecutively on the same project produces identical configuration files with no duplicate sections

### Unit Tests for User Story 1

- [ ] T016 [P] [US1] Write unit test for deduplicating identical memory objects in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T017 [P] [US1] Write unit test for deduplicating identical menu items in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T018 [P] [US1] Write unit test for preserving unique items in arrays in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T019 [P] [US1] Write unit test for idempotency (merge twice = merge once) in `/packages/tcsetup/tests/yaml-merge.test.js`

### Integration Tests for User Story 1

- [ ] T020 [US1] Write integration test simulating double update in `/packages/tcsetup/tests/integration.test.js` (verifies idempotency across real files)
- [ ] T021 [US1] Create test fixture `customize-with-memories.yaml` in `/packages/tcsetup/tests/fixtures/` with sample BMAD configuration

### Implementation for User Story 1

- [ ] T022 [P] [US1] Add export for mergeYAML main function in `/packages/tcsetup/src/yaml-merge.js` (completes foundational T010)
- [ ] T023 [US1] Update `/packages/agreement-system/src/updater.js` to use `mergeYAML()` instead of blind append on line ~87
- [ ] T024 [US1] Update `/packages/feature-lifecycle/src/updater.js` to use `mergeYAML()` instead of blind append on line ~86
- [ ] T025 [US1] Verify agreement-system integration test passes with updated updater.js
- [ ] T026 [US1] Verify feature-lifecycle integration test passes with updated updater.js

**Checkpoint**: User Story 1 complete - `npx tcsetup update` can be run multiple times safely

---

## Phase 4: User Story 2 - Intelligently Merge Configuration Updates (Priority: P2)

**Goal**: Enable tool updates to add new configuration sections without duplicating existing content or corrupting files

**Independent Test**: Running update with new configuration sections adds those sections without duplicating existing config, and existing configuration is preserved exactly as set

### Unit Tests for User Story 2

- [ ] T027 [P] [US2] Write unit test for merging object keys without overwriting existing values in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T028 [P] [US2] Write unit test for adding new keys to existing objects in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T029 [P] [US2] Write unit test for recursive nested object merging in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T030 [P] [US2] Write unit test for mixed array and object merging in `/packages/tcsetup/tests/yaml-merge.test.js`

### Integration Tests for User Story 2

- [ ] T031 [US2] Write integration test for adding new sections to existing customize.yaml in `/packages/tcsetup/tests/integration.test.js`
- [ ] T032 [US2] Create test fixture `customize-with-agent-config.yaml` in `/packages/tcsetup/tests/fixtures/` for agent configuration merging

### Implementation for User Story 2

- [ ] T033 [P] [US2] Verify `mergeYAML.objects()` implementation handles nested objects correctly in `/packages/tcsetup/src/yaml-merge.js` (part of T006)
- [ ] T034 [US2] Add validation in `/packages/tcsetup/src/yaml-merge.js` to ensure merged object contains all keys from both inputs
- [ ] T035 [US2] Verify merge preserves user customizations by testing with real customize.yaml templates
- [ ] T036 [US2] Run integration tests for both agreement-system and feature-lifecycle with new sections

**Checkpoint**: User Story 2 complete - Tool updates can add new configuration sections cleanly

---

## Phase 5: User Story 3 - Handle Edge Cases in Configuration Files (Priority: P3)

**Goal**: Ensure robust handling of missing files, empty configurations, and invalid YAML to prevent cryptic errors

**Independent Test**: Various edge case scenarios (missing files, empty files, invalid YAML, comments-only files) are handled gracefully with clear error messages and file integrity preserved

### Unit Tests for User Story 3

- [ ] T037 [P] [US3] Write unit test for handling empty/null existing configuration in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T038 [P] [US3] Write unit test for handling invalid YAML syntax with error capture in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T039 [P] [US3] Write unit test for handling comments-only files in `/packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T040 [P] [US3] Write unit test for handling type mismatches (array becomes object, etc.) in `/packages/tcsetup/tests/yaml-merge.test.js`

### Integration Tests for User Story 3

- [ ] T041 [US3] Write integration test for missing customize.yaml file handling in `/packages/tcsetup/tests/integration.test.js`
- [ ] T042 [US3] Write integration test for corrupted/invalid YAML file handling in `/packages/tcsetup/tests/integration.test.js`
- [ ] T043 [US3] Create test fixture `customize-empty.yaml` in `/packages/tcsetup/tests/fixtures/` (empty file)
- [ ] T044 [US3] Create test fixture `customize-invalid.yaml` in `/packages/tcsetup/tests/fixtures/` (invalid YAML)
- [ ] T045 [US3] Create test fixture `customize-corrupted.yaml` in `/packages/tcsetup/tests/fixtures/` (with duplicates)

### Implementation for User Story 3

- [ ] T046 [US3] Implement graceful handling of missing files in `/packages/tcsetup/src/yaml-merge.js` (creates file or returns success with appropriate warning)
- [ ] T047 [US3] Implement graceful handling of invalid YAML in `/packages/tcsetup/src/yaml-merge.js` (errors in result, original file preserved)
- [ ] T048 [US3] Add comprehensive error messaging in `/packages/tcsetup/src/yaml-merge.js` with clear guidance for users
- [ ] T049 [US3] Verify all edge cases tested in integration suite with real file operations
- [ ] T050 [US3] Document edge case handling behavior in result changelog

**Checkpoint**: User Story 3 complete - Edge cases are handled robustly without file corruption

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation, documentation, and final verification

### Testing & Validation

- [ ] T051 [P] Run full test suite: `node --test packages/tcsetup/tests/yaml-merge.test.js`
- [ ] T052 [P] Run integration suite: `node --test packages/tcsetup/tests/integration.test.js`
- [ ] T053 [P] Verify all success criteria (SC-001 through SC-004) in `/specs/016-fix-tcsetup-update/spec.md`
- [ ] T054 Verify no regressions in agreement-system by running its full test suite
- [ ] T055 Verify no regressions in feature-lifecycle by running its full test suite

### Documentation & Finalization

- [ ] T056 [P] Validate quickstart.md examples work with actual implementation in `/specs/016-fix-tcsetup-update/quickstart.md`
- [ ] T057 Add usage documentation to `/packages/tcsetup/README.md` explaining the merge behavior
- [ ] T058 Review and validate all code comments in `/packages/tcsetup/src/yaml-merge.js`
- [ ] T059 [P] Performance validation: verify merge operations on large files complete in <100ms

### Final Verification

- [ ] T060 Manual end-to-end test: Run `npx tcsetup update` twice in test project and verify SC-001 success criterion
- [ ] T061 Verify no changes to existing API contracts in `/specs/016-fix-tcsetup-update/contracts/yaml-merge-api.md`
- [ ] T062 Confirm implementation matches all success criteria in spec.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed in parallel after Phase 2
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1 - MVP)**: Can start after Phase 2 - No dependencies on other stories. Validates core YAML merge works.
- **User Story 2 (P2)**: Can start after Phase 2 - Independent of US1, validates object merging and new sections
- **User Story 3 (P3)**: Can start after Phase 2 - Independent of US1/US2, validates error handling

### Within Each User Story

1. Write unit tests first (T016-T019 for US1, etc.) - verify they fail
2. Implement core logic to make tests pass
3. Write and run integration tests
4. Update consumer code (agreement-system, feature-lifecycle updaters)
5. Verify integration with real tools
6. Story complete when all tests pass and success criteria met

### Parallel Opportunities

**Phase 1**: All tasks can run in parallel (creating directories/files)

**Phase 2**: Core merge engine tasks can proceed sequentially as written (T004-T015) since later functions depend on earlier implementations:
- T004-T006 (deepEqual, arrays, objects) are foundational
- T007-T009 (parse, serialize, validate) depend on T004-T006
- T010-T012 (main function, result types) depend on all above
- T013-T015 (error handling) can start once T004-T012 framework exists

**After Phase 2**: All three user stories (US1, US2, US3) can be worked in parallel by different developers:
- Developer A: US1 tests (T016-T019) and implementation (T023-T026)
- Developer B: US2 tests (T027-T032) and implementation (T033-T036)
- Developer C: US3 tests (T037-T050) and implementation (T046-T050)

**Within each story**: Tests and fixtures (marked [P]) can be created in parallel

**Phase 6**: All test tasks (T051-T055) can run in parallel

---

## Parallel Example: User Story 1 Implementation

```bash
# After Phase 2 is complete, launch US1 work:

# Tests can be written in parallel:
Task: "Write unit test for deduplicating identical memory objects" (T016)
Task: "Write unit test for deduplicating identical menu items" (T017)
Task: "Write unit test for preserving unique items in arrays" (T018)
Task: "Write unit test for idempotency" (T019)

# Create test fixtures in parallel:
Task: "Create test fixture for customize with memories" (T021)

# Implementation follows test completion:
Task: "Add export for mergeYAML main function" (T022)
Task: "Update agreement-system updater to use mergeYAML" (T023)
Task: "Update feature-lifecycle updater to use mergeYAML" (T024)

# Verification tasks can run in parallel:
Task: "Verify agreement-system integration test passes" (T025)
Task: "Verify feature-lifecycle integration test passes" (T026)
```

---

## Parallel Example: All User Stories Post-Phase 2

Once Phase 2 (Foundational) completes, with three developers:

```bash
# Developer A handles US1 (P1)
Execute: T016-T026 (US1 tests and implementation)

# Developer B handles US2 (P2)
Execute: T027-T036 (US2 tests and implementation)

# Developer C handles US3 (P3)
Execute: T037-T050 (US3 tests and implementation)

# All converge on Phase 6
All execute: T051-T062 (Testing, validation, finalization)
```

Each story is independently completable and testable, allowing parallel progress without merge conflicts.

---

## Implementation Strategy

### MVP First (User Story 1)

**Recommended approach for fastest validation of core functionality:**

1. Complete Phase 1: Setup (5 min)
2. Complete Phase 2: Foundational (2-3 hours)
   - Core YAML merge engine with all edge case handling
   - Takes longest but essential for all stories
3. Complete Phase 3: User Story 1 (1.5-2 hours)
   - Write tests first, verify they fail
   - Implement `mergeYAML()` function fully
   - Update updaters to use new function
   - Run tests until all pass
4. **STOP and VALIDATE**: Run integration tests, verify SC-001/SC-002 success criteria met
5. Deploy or demo working MVP

**Estimated MVP completion: 4-5 hours**

### Incremental Delivery

After MVP validation:

1. Complete Phase 4: User Story 2 (1.5 hours)
   - Tests for object merging
   - Verify changelog tracking
   - Validate new sections integrate cleanly

2. Complete Phase 5: User Story 3 (1.5 hours)
   - Tests for edge cases
   - Error handling and messaging
   - Verify all SC-003/SC-004 criteria

3. Complete Phase 6: Polish (1 hour)
   - Full test suite validation
   - Documentation
   - Final verification

**Total implementation: 8-9 hours**

### Parallel Team Strategy

With 3 developers after Phase 2 completion:

1. All 3 complete Phase 1 + Phase 2 together (5-6 hours)
2. Foundation ready - branch into stories:
   - Developer A: Phase 3 (US1, 1.5-2 hours)
   - Developer B: Phase 4 (US2, 1.5 hours)
   - Developer C: Phase 5 (US3, 1.5 hours)
3. All converge: Phase 6 (1 hour together)
4. Merge/integrate/deploy

**Total with parallelization: 5-6 hours total time (vs 8-9 sequential)**

---

## Success Criteria Verification

After completing all tasks, verify these success criteria from spec.md:

- **SC-001**: Running `npx tcsetup update` twice consecutively on same project = identical files (verify in T060)
- **SC-002**: 100% of customize.yaml files contain no duplicate sections after update (verify in T053)
- **SC-003**: Custom configuration values preserved exactly as set before update (verify in T034-T036)
- **SC-004**: All YAML files maintain valid syntax after update (verify in T051-T052)

All four criteria must pass before considering feature complete.

---

## Notes

- **[P] markers**: Only on tasks that touch different files with no dependencies
- **[Story] labels**: Map tasks to specific user story for traceability
- **Test-first approach**: Encouraged for TDD benefits, but not mandatory
- **Commit strategy**: After each phase or logical story grouping
- **Stop points**: Use checkpoints after each phase to validate independently
- **Avoid**:
  - Skipping Phase 2 (blocks all stories)
  - Merging stories out of priority order
  - Implementing without tests
  - Modifying updaters before yaml-merge.js is complete and tested

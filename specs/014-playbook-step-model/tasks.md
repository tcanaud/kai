# Tasks: Playbook Step Model Selection

**Input**: Design documents from `/specs/014-playbook-step-model/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/playbook-schema.md

**Tests**: Included -- the plan explicitly lists test file modifications (`packages/playbook/tests/yaml-parser.test.js`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the `model` field to the YAML parser and step factory -- this is the foundation all other changes depend on.

- [x] T001 Add `model: null` to `_emptyStep()` factory in `packages/playbook/src/yaml-parser.js`
- [x] T002 Add `ALLOWED_MODELS` constant (`new Set(["opus", "sonnet", "haiku"])`) in `packages/playbook/src/yaml-parser.js`
- [x] T003 Add `case "model":` to `_applyStepField()` in `packages/playbook/src/yaml-parser.js` -- validate against `ALLOWED_MODELS`, normalize empty string to `null`

**Checkpoint**: Parser recognizes the `model` field. Existing playbooks parse without error (model defaults to null).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add model validation constant to the validator -- blocks US2 validation tasks.

**Note**: This is a single constant addition. No user story work is blocked until this is in place.

- [x] T004 Add `MODEL_VALUES` constant (`["opus", "sonnet", "haiku"]`) in `packages/playbook/src/validator.js`

**Checkpoint**: Both parser and validator have their model constants defined. User story implementation can begin.

---

## Phase 3: User Story 1 -- Specify Model Per Step in a Playbook (Priority: P1) MVP

**Goal**: A playbook author can add an optional `model` field to any step, and the supervisor passes the correct model to the Task subagent when delegating execution.

**Independent Test**: Create a playbook YAML with `model` fields on some steps, verify it parses correctly (model values preserved, absent model defaults to null), and verify the supervisor prompt instructs model passing.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T005 [P] [US1] Add test: step with `model: "sonnet"` parses to `model: "sonnet"` in `packages/playbook/tests/yaml-parser.test.js`
- [x] T006 [P] [US1] Add test: step without `model` field parses to `model: null` in `packages/playbook/tests/yaml-parser.test.js`
- [x] T007 [P] [US1] Add test: all three valid values (`opus`, `sonnet`, `haiku`) parse correctly in `packages/playbook/tests/yaml-parser.test.js`
- [x] T008 [P] [US1] Add test: step with `model: ""` (empty string) parses to `model: null` in `packages/playbook/tests/yaml-parser.test.js`

### Implementation for User Story 1

- [x] T009 [US1] Verify parser changes from Phase 1 (T001-T003) pass all new tests -- run `node --test packages/playbook/tests/yaml-parser.test.js`
- [x] T010 [US1] Update supervisor delegation in section 5c of `.claude/commands/playbook.run.md` -- when `step.model` is non-null, include `model: "{step.model}"` in the Task tool call
- [x] T011 [US1] Update resume orchestration in `.claude/commands/playbook.resume.md` -- ensure model-passing logic matches `playbook.run.md`

**Checkpoint**: Steps with `model` parse correctly, absent model defaults to null, and supervisor passes model to Task subagent. US1 is fully functional.

---

## Phase 4: User Story 2 -- Validate Model Values in Playbook Schema (Priority: P2)

**Goal**: The `npx @tcanaud/playbook check` command catches invalid model values and reports clear error messages listing allowed values.

**Independent Test**: Run the check command against playbook files with valid and invalid model values, verify correct acceptance and rejection.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T012 [P] [US2] Add test: invalid model value `"invalid-model"` produces a violation in `packages/playbook/tests/yaml-parser.test.js` (parser-level rejection)
- [x] T013 [P] [US2] Add test: case-sensitive rejection -- `"Sonnet"` throws error in `packages/playbook/tests/yaml-parser.test.js`

### Implementation for User Story 2

- [x] T014 [US2] Add per-step model validation in `_validatePlaybook()` loop in `packages/playbook/src/validator.js` -- if `step.model` is non-null and not in `MODEL_VALUES`, push violation: `step "{id}": model "{value}" is not valid (allowed: opus, sonnet, haiku)`
- [x] T015 [US2] Verify validation by running `npx @tcanaud/playbook check` against an existing playbook (should pass) and a test playbook with invalid model (should fail)

**Checkpoint**: Invalid model values are caught at validation time with clear error messages. All existing playbooks continue to pass validation.

---

## Phase 5: User Story 3 -- Create Playbook with Model Hints (Priority: P3)

**Goal**: The playbook template documents the `model` field so users creating playbooks via `/playbook.create` see the field and its allowed values.

**Independent Test**: View the template file and verify `model` is documented in the Schema Reference comments with allowed values and optional nature.

### Implementation for User Story 3

- [x] T016 [US3] Add `model` field to the step fields list in the Schema Reference comments of `.playbooks/playbooks/playbook.tpl.yaml`
- [x] T017 [US3] Add a "Model Values" section to the Schema Reference comments in `.playbooks/playbooks/playbook.tpl.yaml` documenting `opus`, `sonnet`, `haiku`, and omission behavior

**Checkpoint**: Template documents the model field. Users creating playbooks see the new field in schema reference.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verify backward compatibility and run full validation.

- [x] T018 Run full parser test suite: `cd packages/playbook && node --test tests/yaml-parser.test.js`
- [x] T019 Validate all existing playbooks still pass: `npx @tcanaud/playbook check .playbooks/playbooks/auto-feature.yaml`
- [x] T020 Validate the template still passes: `npx @tcanaud/playbook check .playbooks/playbooks/playbook.tpl.yaml`
- [x] T021 Run quickstart.md verification steps from `specs/014-playbook-step-model/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies -- can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (parser must have model field before validator constant matters)
- **US1 (Phase 3)**: Depends on Phase 1 completion (parser changes)
- **US2 (Phase 4)**: Depends on Phase 1 + Phase 2 (parser + validator constant)
- **US3 (Phase 5)**: No code dependency on other phases (template-only change), but logically should come after US1/US2
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 1 -- no dependency on other stories
- **User Story 2 (P2)**: Can start after Phase 2 -- independent of US1 (but US1 tests may be reused)
- **User Story 3 (P3)**: Can start after Phase 1 -- fully independent (template file only)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Parser changes before validator changes
- Core implementation before integration verification
- Story complete before moving to next priority

### Parallel Opportunities

- T005, T006, T007, T008 (US1 tests) can all run in parallel
- T012, T013 (US2 tests) can run in parallel
- T010, T011 (US1 supervisor prompts) can run in parallel (different files)
- T016, T017 (US3 template updates) are sequential (same file)
- US1 and US3 can proceed in parallel after Phase 1 (different files)

---

## Parallel Example: User Story 1

```bash
# Launch all US1 parser tests together:
Task: "Add test: step with model: sonnet parses correctly" (T005)
Task: "Add test: step without model parses to null" (T006)
Task: "Add test: all three valid values parse" (T007)
Task: "Add test: empty string normalizes to null" (T008)

# Then launch supervisor prompt updates together:
Task: "Update playbook.run.md delegation" (T010)
Task: "Update playbook.resume.md delegation" (T011)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003) -- parser recognizes model field
2. Complete Phase 2: Foundational (T004) -- validator constant ready
3. Complete Phase 3: User Story 1 (T005-T011) -- model parsed and passed to subagent
4. **STOP and VALIDATE**: Run parser tests, verify existing playbooks still work
5. Deploy/demo if ready -- authors can now use `model` in playbooks

### Incremental Delivery

1. Setup + Foundational (T001-T004) -> Parser and validator ready
2. User Story 1 (T005-T011) -> Model works end-to-end (MVP!)
3. User Story 2 (T012-T015) -> Invalid values caught at validation time
4. User Story 3 (T016-T017) -> Template documents the field
5. Polish (T018-T021) -> Full verification pass

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- All changes are modifications to existing files -- no new files introduced
- Zero runtime dependencies maintained -- only `node:` protocol imports
- The model constants are intentionally duplicated in parser and validator (per codebase convention from research.md R2)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently

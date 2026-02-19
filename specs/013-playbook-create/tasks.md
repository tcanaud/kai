# Tasks: /playbook.create Command for Custom Playbook Generation

**Input**: Design documents from `/specs/013-playbook-create/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in the feature specification. Tests are omitted except for the single test file identified in the plan (`playbook-create.test.js`) which validates generated output.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Package root**: `packages/playbook/` (submodule package)
- **Templates**: `packages/playbook/templates/commands/` (slash command templates)
- **Source**: `packages/playbook/src/` (installer/updater code)
- **Tests**: `packages/playbook/tests/` (test files)
- **Installed artifacts**: `.claude/commands/` (slash commands at project root)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create feature branch, prepare file scaffolding, bump version

- [X] T001 Create feature branch `013-playbook-create` from main
- [X] T002 Bump version from `"1.1.0"` to `"1.2.0"` in `packages/playbook/package.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the slash command template file and wire it into the installer/updater. All user stories depend on these files existing.

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 [P] Add `"playbook.create.md"` to the `commandFiles` array in `packages/playbook/src/installer.js` (line 122: add to array `["playbook.run.md", "playbook.resume.md"]`)
- [X] T004 [P] Add `["commands/playbook.create.md", ".claude/commands/playbook.create.md"]` entry to the `commandMappings` array in `packages/playbook/src/updater.js` (line 69-72: add to array alongside existing entries)
- [X] T005 Create the slash command template file at `packages/playbook/templates/commands/playbook.create.md` with the foundational structure: header, input parsing (`$ARGUMENTS`), and the 6-phase protocol skeleton (Project Analysis, Intention Parsing, Playbook Generation, Validation, Presentation & Refinement, Conflict Check & Persistence). Use the same Markdown prompt style as `packages/playbook/templates/commands/playbook.run.md`. Include a placeholder for each phase that will be filled in by subsequent tasks.

**Checkpoint**: Foundation ready — the template file exists and the installer/updater will distribute it. User story implementation can now fill in the template content.

---

## Phase 3: User Story 2 — Deep Project Analysis Before Generation (Priority: P1)

**Goal**: The slash command performs a structured 5-phase project scan that builds an internal Project Context model, enabling the AI to make informed decisions about which commands, conditions, autonomy levels, and patterns to use in the generated playbook.

**Independent Test**: Run `/playbook.create` on two projects with different tool sets (e.g., one with QA system, one without) and verify the generated playbooks differ accordingly. A project without `.qa/` should produce no QA-related steps or conditions.

### Implementation for User Story 2

- [X] T006 [US2] Write the "Phase 1: Project Analysis" section in `packages/playbook/templates/commands/playbook.create.md` — Tool Detection subsection. Instruct the AI to check for each marker directory (`.adr/`, `.agreements/`, `.features/`, `.knowledge/`, `.qa/`, `.product/`, `specs/`, `_bmad/`, `.playbooks/`) using `ls -d` via Bash tool. Build a list of installed tools. If `.playbooks/` is missing, STOP with error: "Playbook system not installed. Run `npx @tcanaud/playbook init` first."
- [X] T007 [US2] Write the "Phase 1: Project Analysis" section in `packages/playbook/templates/commands/playbook.create.md` — Command Discovery subsection. Instruct the AI to list all `*.md` files in `.claude/commands/`, extract namespace.command names from dot-separated filenames (e.g., `speckit.plan.md` -> `/speckit.plan`), and note hyphen-separated BMAD entries as secondary. If `.claude/commands/` is missing, WARN and proceed with empty command list.
- [X] T008 [US2] Write the "Phase 1: Project Analysis" section in `packages/playbook/templates/commands/playbook.create.md` — Existing Playbook Pattern Extraction subsection. Instruct the AI to read all `.playbooks/playbooks/*.yaml` (excluding `playbook.tpl.yaml`), extract autonomy defaults per command type, error policy patterns, escalation trigger usage, condition chains, and naming conventions. Present the extracted patterns as a reference table in the internal context.
- [X] T009 [US2] Write the "Phase 1: Project Analysis" section in `packages/playbook/templates/commands/playbook.create.md` — Convention Reading subsection. Instruct the AI to read `.knowledge/snapshot.md` and `CLAUDE.md` to understand project conventions and technology stack. Also read any `.playbooks/` naming patterns for slug format consistency.
- [X] T010 [US2] Write the "Phase 1: Project Analysis" section in `packages/playbook/templates/commands/playbook.create.md` — Usable Condition Filtering subsection. Include the condition-to-tool mapping table (e.g., `qa_plan_exists` requires `.qa/`, `spec_exists` requires `specs/`, `pr_created` requires `gh` CLI). Instruct the AI to build a filtered list of conditions usable in the generated playbook based on which tools were detected in the Tool Detection step.

**Checkpoint**: The Project Analysis phase is complete. Running `/playbook.create` now performs a full project scan and builds internal context before doing anything else.

---

## Phase 4: User Story 1 — Create a Custom Playbook from a Free-Text Intention (Priority: P1)

**Goal**: A developer describes a workflow in plain language and receives a valid playbook YAML file that passes the validator, uses only commands that exist in the project, and can be run immediately.

**Independent Test**: Run `/playbook.create validate and deploy a hotfix for critical bugs` in a project with kai installed. Verify: (1) the output file exists at `.playbooks/playbooks/{name}.yaml`, (2) `npx @tcanaud/playbook check` reports zero violations, (3) all referenced commands exist in `.claude/commands/`.

### Implementation for User Story 1

- [X] T011 [US1] Write the "Phase 2: Intention Parsing" section in `packages/playbook/templates/commands/playbook.create.md`. Include: (a) extract `$ARGUMENTS` as the free-text intention, (b) handle empty intention by asking for one, (c) handle single-action intentions by suggesting direct command execution, (d) extract action verbs/nouns and map to available commands using the keyword-to-command mapping table from research.md (R3), (e) determine natural step ordering based on dependency chains, (f) detect vagueness and trigger clarification (max 3 questions per FR-008).
- [X] T012 [US1] Write the "Phase 3: Playbook Generation" section in `packages/playbook/templates/commands/playbook.create.md`. Include: (a) derive playbook name as lowercase slug from intention matching `[a-z0-9-]+`, (b) generate human-readable description, (c) declare `feature` arg as required by default plus any additional args from the intention, (d) generate steps referencing only verified commands from the Command Discovery phase, (e) assign autonomy levels following existing playbook patterns (from Phase 1 analysis) with default heuristics (validation=auto, implementation=auto/gate_on_breaking, PR=gate_always, destructive=gate_always), (f) assign error policies following patterns (spec/plan=stop, implementation=retry_once, validation=gate, PR=stop), (g) assign preconditions/postconditions only from the usable condition set, (h) assign escalation triggers following existing patterns, (i) use `{{arg}}` interpolation — never hardcoded feature values.
- [X] T013 [US1] Write the "Phase 4: Validation" section in `packages/playbook/templates/commands/playbook.create.md`. Instruct the AI to: (a) write the generated YAML to `.playbooks/playbooks/{name}.yaml`, (b) run `npx @tcanaud/playbook check .playbooks/playbooks/{name}.yaml` via Bash tool, (c) parse the output for violations, (d) if violations found, fix the YAML and re-validate (max 3 attempts), (e) only proceed to presentation once validation passes. Include the full playbook schema reference inline (top-level fields, step fields, allowed enums) so the AI has the schema in context when generating.
- [X] T014 [US1] Include the complete playbook schema reference tables in `packages/playbook/templates/commands/playbook.create.md` — as a dedicated "Schema Reference" section at the end of the template. Include: allowed autonomy values, allowed error_policy values, allowed condition values, allowed escalation_trigger values, step field requirements, name/id slug pattern, and the YAML formatting conventions (from research R4: double-quoted strings, block-style lists, empty lists as `[]`, 2-space indentation, blank line between steps).

**Checkpoint**: At this point, `/playbook.create` can analyze a project, parse an intention, generate a valid playbook YAML, and validate it. The core value proposition (SC-001) is functional.

---

## Phase 5: User Story 4 — Playbook Is Project-Adapted, Not Feature-Specific (Priority: P1)

**Goal**: Generated playbooks use `{{feature}}` argument interpolation everywhere feature-specific values would appear, making them reusable across features without any hardcoded references.

**Independent Test**: Generate a playbook, then inspect it for any hardcoded feature IDs, branch names, or feature-specific file paths. All such references should use `{{feature}}` or `{{arg}}` interpolation. Run the playbook twice with different feature names to confirm correct behavior.

### Implementation for User Story 4

- [X] T015 [US4] Add explicit no-hardcoding rules to the "Phase 3: Playbook Generation" section in `packages/playbook/templates/commands/playbook.create.md`. Include a dedicated "Argument Interpolation Rules" subsection that instructs the AI to: (a) always declare `feature` as a required arg when any step references feature-specific artifacts, (b) use `{{feature}}` in step args — never a literal branch name, feature number, or spec path, (c) verify that every `{{arg}}` reference matches a declared arg name, (d) scan the generated YAML for any literal feature references and replace them before validation. Include examples of correct vs. incorrect arg usage.

**Checkpoint**: All generated playbooks are guaranteed to be feature-agnostic and reusable.

---

## Phase 6: User Story 3 — Interactive Refinement of Generated Playbook (Priority: P2)

**Goal**: After initial generation, the developer can review the playbook with per-step rationale explanations and request modifications (add/remove/change steps, autonomy levels, error policies, reorder) in a conversation loop. Each modification is re-validated.

**Independent Test**: Generate a playbook, request changing a step's autonomy level from `auto` to `gate_always`, verify the updated playbook passes validation with the change applied.

### Implementation for User Story 3

- [X] T016 [US3] Write the "Phase 5: Presentation and Refinement" section in `packages/playbook/templates/commands/playbook.create.md`. Include: (a) display the generated YAML with per-step rationale annotations (why this command, why this autonomy level, why these conditions), (b) ask "Would you like to modify this playbook, or save it as-is?", (c) define the refinement loop protocol (accept modification -> apply -> re-validate via `npx @tcanaud/playbook check` -> re-present -> repeat until "done"/"save").
- [X] T017 [US3] Add modification type handling instructions to the "Phase 5" section in `packages/playbook/templates/commands/playbook.create.md`. Document supported modifications: (a) add step — describe action, map to command, insert at correct position, (b) remove step — with dependency warning if removed step's postconditions are another step's preconditions (FR-024), (c) change autonomy level, (d) change error policy, (e) reorder steps — adjust conditions after reorder, (f) change name — re-validate slug pattern, (g) change description, (h) add/remove arguments — update `{{arg}}` references.

**Checkpoint**: The interactive refinement loop is functional. Users can modify generated playbooks before saving.

---

## Phase 7: User Story 5 — Playbook Name and Description Generation (Priority: P2)

**Goal**: The system generates meaningful names and descriptions from the intention. Naming conflicts with existing playbooks are detected with overwrite/rename/cancel options.

**Independent Test**: Generate a playbook, verify name matches `[a-z0-9-]+` pattern. Then attempt to create another with a conflicting name and verify the system detects the conflict.

### Implementation for User Story 5

- [X] T018 [US5] Write the "Phase 6: Conflict Check and Persistence" section in `packages/playbook/templates/commands/playbook.create.md`. Include: (a) check if `.playbooks/playbooks/{name}.yaml` already exists (from a prior playbook, not this session's validation writes), (b) if conflict detected, report and offer 3 options: overwrite, rename, cancel (FR-020), (c) if rename: prompt for new name, validate slug pattern `[a-z0-9-]+`, re-check for conflicts, (d) if cancel: delete the file written during validation, report cancellation, END.
- [X] T019 [US5] Write the index update logic in the "Phase 6" section of `packages/playbook/templates/commands/playbook.create.md`. Instruct the AI to: (a) read `.playbooks/_index.yaml`, (b) if missing or corrupted (parse error): scan `.playbooks/playbooks/*.yaml` and rebuild the index from filesystem (FR-027), (c) add new entry with `name`, `file` (relative path `playbooks/{name}.yaml`), `description`, and `steps` (count), (d) update `generated` timestamp to current ISO 8601, (e) write back. If entry already exists (overwrite case): update existing entry instead of appending.
- [X] T020 [US5] Write the completion report in the "Phase 6" section of `packages/playbook/templates/commands/playbook.create.md`. Report: file path, step count, and usage instructions (`/playbook.run {name} {feature}` and `npx @tcanaud/playbook check` command).

**Checkpoint**: Full playbook creation lifecycle is complete — naming, conflict detection, index update, and success reporting.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge case handling, output validation test, documentation

- [X] T021 [P] Add edge case handling instructions to `packages/playbook/templates/commands/playbook.create.md`. Cover all edge cases from the spec: (a) no kai tools installed — report and ask whether to proceed with generic playbook or install kai first, (b) intention references unavailable command — explain missing command, offer to mark step as `skip`, (c) intention too broad — trigger clarification, (d) zero-step playbook — explain no commands match, suggest reformulating, do not create file, (e) missing/corrupted index — rebuild from filesystem, (f) developer cancels mid-interaction — no files written, confirm cancellation.
- [X] T022 [P] Create the output validation test file at `packages/playbook/tests/playbook-create.test.js`. Test that a sample generated playbook YAML string: (a) parses without error via the YAML parser, (b) passes the validator with zero violations, (c) has a name matching `[a-z0-9-]+`, (d) has unique step IDs, (e) has all `{{arg}}` references matching declared args, (f) contains no hardcoded feature-specific values (regex check for branch-like patterns).
- [X] T023 [P] Update `packages/playbook/README.md` to document the new `/playbook.create` command: description, usage examples, interactive refinement, naming conflicts.
- [X] T024 Review the complete `packages/playbook/templates/commands/playbook.create.md` template end-to-end for consistency, ensure all 6 phases flow logically, cross-reference against spec requirements (FR-001 through FR-029), and verify all success criteria (SC-001 through SC-008) are addressed.
- [X] T025 Run `npx @tcanaud/playbook check` against an existing playbook to verify the validator still works, and run any existing tests in `packages/playbook/tests/` to confirm no regressions.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US2 - Deep Project Analysis (Phase 3)**: Depends on Foundational (T005 template file must exist)
- **US1 - Playbook from Intention (Phase 4)**: Depends on US2 completion (intention parsing needs project context)
- **US4 - Project-Adapted (Phase 5)**: Depends on US1 completion (refines the generation rules)
- **US3 - Interactive Refinement (Phase 6)**: Depends on US1 completion (refinement needs a generated playbook to present)
- **US5 - Name/Description/Conflict (Phase 7)**: Depends on US1 completion (persistence needs a generated playbook to save)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US2 (Phase 3)**: First — provides the project context that all other stories consume
- **US1 (Phase 4)**: After US2 — core generation depends on project analysis
- **US4 (Phase 5)**: After US1 — refines the arg interpolation rules in the generation phase
- **US3 (Phase 6)**: After US1 — can start in parallel with US4 and US5
- **US5 (Phase 7)**: After US1 — can start in parallel with US4 and US3

### Within Each User Story

- Each story adds content to the same template file (`playbook.create.md`)
- Stories build sequentially because each phase of the template depends on the previous phase's protocol
- Within US2 (Phase 3), tasks T006-T010 can be implemented sequentially as subsections of the same phase

### Parallel Opportunities

- T003 and T004 can run in parallel (different files: `installer.js` and `updater.js`)
- T006-T010 within US2 can theoretically be parallelized (different subsections) but they all modify the same file, so sequential is safer
- US3, US4, and US5 (Phases 5-7) can start in parallel after US1 is complete, since they write to different sections of the template
- T021, T022, T023 in the Polish phase can all run in parallel (different files)

---

## Parallel Example: Foundational Phase

```
# These modify different files and can run in parallel:
Task T003: Add playbook.create.md to installer.js commandFiles array
Task T004: Add playbook.create.md to updater.js commandMappings array
```

## Parallel Example: Polish Phase

```
# These create/modify different files and can run in parallel:
Task T021: Add edge case handling to playbook.create.md
Task T022: Create playbook-create.test.js
Task T023: Update README.md
```

---

## Implementation Strategy

### MVP First (User Story 2 + User Story 1)

1. Complete Phase 1: Setup (branch, version bump)
2. Complete Phase 2: Foundational (template file, installer/updater wiring)
3. Complete Phase 3: US2 — Deep Project Analysis
4. Complete Phase 4: US1 — Playbook from Intention
5. **STOP and VALIDATE**: Run `/playbook.create` with a test intention, verify the generated playbook passes `npx @tcanaud/playbook check`

### Incremental Delivery

1. Setup + Foundational -> Template file exists, installer distributes it
2. Add US2 -> Project analysis works -> Cannot test independently yet
3. Add US1 -> Full generation pipeline works -> **MVP is functional** (SC-001 met)
4. Add US4 -> Arg interpolation hardened -> Test with two different feature names
5. Add US3 -> Interactive refinement available -> Test modification loop
6. Add US5 -> Naming + persistence finalized -> Test conflict detection
7. Polish -> Edge cases, tests, docs -> Production ready

### Key Observation

This feature is a **single Markdown file** (`playbook.create.md`) with small wiring changes in `installer.js` and `updater.js`. All "implementation" is prompt engineering — writing AI instructions that Claude Code will follow when the slash command is invoked. The tasks are organized by the protocol phases (analysis, parsing, generation, validation, refinement, persistence) which map directly to the user stories.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All generation logic lives in the slash command template prompt — no new Node.js runtime code
- The primary deliverable is `packages/playbook/templates/commands/playbook.create.md`
- Secondary deliverables: `installer.js` change, `updater.js` change, `package.json` version bump, test file, README update
- Validation is guaranteed by the prompt instructing the AI to run `npx @tcanaud/playbook check` before presenting the playbook
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently

# Tasks: QA System

**Input**: Design documents from `specs/009-qa-system/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Package scaffolding — create directory structure, package.json, and CLI entry point

- [x] T001 Create package directory structure: `packages/qa-system/bin/`, `packages/qa-system/src/`, `packages/qa-system/templates/core/`, `packages/qa-system/templates/commands/`
- [x] T002 Create `packages/qa-system/package.json` — name: `@tcanaud/qa-system`, type: module, bin: `qa-system` → `./bin/cli.js`, engines: node >= 18.0.0, zero dependencies, files: bin/, src/, templates/
- [x] T003 Create `packages/qa-system/bin/cli.js` — executable entry point with switch/case dispatch for `init`, `update`, `help` commands per conv-002 pattern. Import `installer.js` for init, `updater.js` for update. Include help text documenting all three slash commands (`/qa.plan`, `/qa.run`, `/qa.check`)

**Checkpoint**: Package skeleton exists, `node packages/qa-system/bin/cli.js help` prints usage.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core package modules that MUST be complete before slash commands can be installed

**Warning**: No user story work can begin until this phase is complete — commands cannot be installed without the installer

- [x] T004 [P] Create `packages/qa-system/src/detect.js` — export `detect(projectRoot)` function that checks existence of `.qa/`, `.claude/commands/`, `.features/`, `.agreements/`, `.knowledge/`, `.product/`, `specs/`. Return object with boolean flags for each. Follow product-manager detect.js pattern using `node:fs` existsSync
- [x] T005 [P] Create `packages/qa-system/templates/core/index.yaml` — template for `_index.yaml` per data-model.md schema: `qa_version: "1.0"`, generation metadata placeholders, checksums block, scripts array, summary counters. This is the reference schema, not executable code
- [x] T006 Create `packages/qa-system/src/installer.js` — export `install(flags)` function. Phase 1: create `.qa/` root directory (idempotent). Phase 2: copy command templates from `templates/commands/` to `.claude/commands/` (qa.plan.md, qa.run.md, qa.check.md). Support `--yes` flag to skip confirmation. Use `node:fs` and `node:path` only. Print progress and summary. Follow product-manager installer.js pattern
- [x] T007 Create `packages/qa-system/src/updater.js` — export `update(flags)` function. Check `.qa/` exists (error if not). Update only command templates in `.claude/commands/` — never touch `.qa/` user data. Print summary confirming user data untouched. Follow product-manager updater.js pattern

**Checkpoint**: `node packages/qa-system/bin/cli.js init` creates `.qa/` and installs 3 command templates to `.claude/commands/`. `node packages/qa-system/bin/cli.js update` refreshes templates.

---

## Phase 3: User Story 1 — Generate Test Plan from Specifications (Priority: P1) MVP

**Goal**: A developer runs `/qa.plan {feature}` and gets executable test scripts generated from spec.md acceptance criteria, mapped in _index.yaml with SHA-256 freshness checksums.

**Independent Test**: Run `/qa.plan` on any feature with a completed spec.md. Verify scripts appear in `.qa/{feature}/scripts/` and `_index.yaml` is valid per data-model.md schema.

### Implementation for User Story 1

- [x] T008 [US1] Write `/qa.plan` slash command template in `packages/qa-system/templates/commands/qa.plan.md` — YAML frontmatter with description and handoffs. Encode the full contract from `contracts/qa.plan.md`:
  - Phase 1 (Context Gathering): instructions to read `.knowledge/guides/` for project conventions, read `specs/{feature}/spec.md` and extract all Given/When/Then acceptance scenarios, read `.agreements/{feature}/agreement.yaml` interfaces if present (skip gracefully if not), run `/agreement.check {feature}` if agreement exists, explore source code for the feature
  - Phase 2 (Script Generation): for each acceptance scenario generate one executable test script adapted to project conventions from `.knowledge/`, enforce header comment with criterion reference (US#.AC#), self-contained execution (exit 0 = PASS, non-zero = FAIL), failure output with assertion + expected vs actual. For agreement interfaces generate compliance scripts. Write all scripts to `.qa/{feature}/scripts/` with executable permissions
  - Phase 3 (Index Generation): compute SHA-256 of spec.md and agreement.yaml (using `node:crypto` or shell `shasum -a 256`), write `_index.yaml` per data-model.md schema with generation timestamp, checksums, script-to-criterion mappings (filename, criterion_ref, criterion_text, type), total counts
  - Phase 4 (Report): output Markdown summary table with script count, coverage, checksums, and per-script mapping
  - Error handling: spec.md not found → ERROR, .qa/ not found → ERROR, no scenarios → ERROR, .knowledge/ missing → WARN proceed, agreement missing → WARN proceed
  - Graceful degradation per FR-013, FR-014

**Checkpoint**: `/qa.plan {feature}` generates scripts in `.qa/{feature}/scripts/`, creates valid `_index.yaml`. Works with spec-only (no agreement), works without `.knowledge/`.

---

## Phase 4: User Story 2 — Execute Tests and Get Verdict (Priority: P1) MVP

**Goal**: A developer runs `/qa.run {feature}` and gets a binary PASS/FAIL verdict with per-script detail. Non-blocking findings are deposited in `.product/inbox/`.

**Independent Test**: Create test scripts manually in `.qa/{feature}/scripts/` with a valid `_index.yaml`, run `/qa.run`, verify verdict output and finding deposit format.

### Implementation for User Story 2

- [x] T009 [US2] Write `/qa.run` slash command template in `packages/qa-system/templates/commands/qa.run.md` — YAML frontmatter with description and handoffs. Encode the full contract from `contracts/qa.run.md`:
  - Phase 1 (Freshness Check): read `_index.yaml`, compute current SHA-256 of spec.md and agreement.yaml, compare against stored checksums, if mismatch → output STALE verdict and refuse to execute (direct to `/qa.plan`)
  - Phase 2 (Script Execution): for each script in `_index.yaml` scripts array, execute via appropriate interpreter (bash/node based on extension), capture exit code (0=PASS, non-zero=FAIL), capture stdout/stderr, record execution time. On execution error (syntax, missing dep) mark FAIL with error detail and continue to next script
  - Phase 3 (Verdict): compute aggregate verdict (PASS if all exit 0, FAIL if any non-zero), output Markdown report per contract — PASS format with script table, FAIL format with failure details (script, assertion, expected, actual, captured output)
  - Phase 4 (Finding Deposit): for non-blocking findings, create Markdown files in `.product/inbox/` with YAML frontmatter per data-model.md Finding schema (title starting "QA Finding:", category, source: "qa-system", linked_to features, body with Test Script/Criterion/Observation/Severity). If `.product/` not found → WARN skip deposit per FR-015
  - Error handling: .qa/{feature}/ not found → ERROR, _index.yaml missing/invalid → ERROR, all scripts missing → ERROR

**Checkpoint**: `/qa.run {feature}` produces correct PASS/FAIL/STALE verdicts. Failed scripts show detailed output. Findings appear in `.product/inbox/` with correct format.

---

## Phase 5: User Story 3 — Check Test Plan Freshness Across Features (Priority: P2)

**Goal**: A developer runs `/qa.check` and sees which features have current vs stale test plans across the entire project.

**Independent Test**: Create `.qa/` directories for multiple features with `_index.yaml` files, modify one spec.md, run `/qa.check`, verify stale detection.

### Implementation for User Story 3

- [x] T010 [US3] Write `/qa.check` slash command template in `packages/qa-system/templates/commands/qa.check.md` — YAML frontmatter with description and handoffs. Encode the full contract from `contracts/qa.check.md`:
  - Phase 1 (Discovery): scan `.qa/` for subdirectories, check each for `_index.yaml`, skip those without (report as "no test plan")
  - Phase 2 (Freshness Check): for each feature with `_index.yaml`, read stored checksums, compute current SHA-256, compare. Match = "current", mismatch = "stale" (identify changed file). Source file missing = "source missing"
  - Phase 3 (Report): output Markdown table with Feature/Status/Details columns, summary count (N current, M stale), action required section listing `/qa.plan` commands for stale features
  - Error handling: .qa/ not found → ERROR, .qa/ empty → info message, malformed _index.yaml → report "invalid index" for that feature and continue

**Checkpoint**: `/qa.check` correctly reports current/stale/no-test-plan for all features. Stale features show which source file changed.

---

## Phase 6: User Story 4 — Traceability Chain for Reviewers (Priority: P2)

**Goal**: Reviewers can follow the chain: `_index.yaml` → test scripts → acceptance criteria → spec.md, and findings → scripts → criteria.

**Independent Test**: After running `/qa.plan` and `/qa.run`, verify `_index.yaml` contains criterion text and spec references, scripts have header comments, findings link back to scripts and criteria.

### Implementation for User Story 4

- [x] T011 [US4] Review and enhance `/qa.plan` template (`packages/qa-system/templates/commands/qa.plan.md`) to ensure traceability requirements are explicitly encoded in the prompt:
  - Each `_index.yaml` script entry MUST include `criterion_text` (the full Given/When/Then text) and `criterion_ref` (US#.AC# format) per data-model.md
  - Each generated script MUST have a header comment block with: test description, criterion reference, feature ID, generation timestamp per data-model.md Test Script conventions
  - Scripts MUST be readable standalone — a reviewer should understand what is verified without reading spec.md
- [x] T012 [US4] Review and enhance `/qa.run` template (`packages/qa-system/templates/commands/qa.run.md`) to ensure finding traceability:
  - Each finding deposited in `.product/inbox/` MUST include `Test Script` path, `Criterion` with US#.AC# reference and text, `Observation`, `Severity` per data-model.md Finding schema
  - Finding `linked_to.features` MUST contain the feature ID
  - The traceability chain finding → script → criterion → spec.md MUST be followable from the finding alone

**Checkpoint**: After full `/qa.plan` → `/qa.run` cycle, a reviewer can trace any finding back through the chain to the original spec criterion.

---

## Phase 7: User Story 5 — Package Installation and Updates (Priority: P3)

**Goal**: Package is publishable, installable via `npx @tcanaud/qa-system install`, updatable via `npx @tcanaud/qa-system update`.

**Independent Test**: Run `npx @tcanaud/qa-system install` on a fresh project, verify `.qa/` created and 3 commands in `.claude/commands/`. Run update, verify templates refreshed.

### Implementation for User Story 5

- [x] T013 [P] [US5] Create `packages/qa-system/.github/workflows/publish.yml` — GitHub Actions OIDC trusted publishing workflow. Trigger on `v*` tags, use `actions/checkout@v4` + `actions/setup-node@v4` with `node-version: lts/*`, run `npm publish --provenance --access public`. Follow existing kai package publish workflow pattern
- [x] T014 [P] [US5] Create `packages/qa-system/README.md` — package description, installation instructions (via tcsetup + standalone), commands overview (/qa.plan, /qa.run, /qa.check), link to quickstart.md, zero-dependency note, license

**Checkpoint**: Package is publishable. `npm pack` produces a valid tarball. README documents all commands.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Ecosystem integration and final validation

- [x] T015 [P] Register QA System in tcsetup installer — add entry `{ name: "QA System", flag: "--skip-qa", cmd: "npx @tcanaud/qa-system init --yes" }` to steps array in `packages/tcsetup/src/installer.js`
- [x] T016 [P] Register QA System in tcsetup updater — add entry `{ name: "QA System", marker: ".qa", pkg: "@tcanaud/qa-system", cmd: "npx @tcanaud/qa-system update" }` to TOOLS array in `packages/tcsetup/src/updater.js`
- [x] T017 Validate end-to-end flow per quickstart.md: install package → `/qa.plan {feature}` → `/qa.run {feature}` → verify verdict → verify finding deposit in `.product/inbox/` → `/qa.check` → verify freshness report. Confirm all contracts are satisfied

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — core test plan generation
- **US2 (Phase 4)**: Depends on Phase 2 — can run in parallel with US1 (different command file)
- **US3 (Phase 5)**: Depends on Phase 2 — can run in parallel with US1/US2 (different command file)
- **US4 (Phase 6)**: Depends on US1 + US2 completion — reviews and enhances those templates
- **US5 (Phase 7)**: Depends on Phase 2 — can run in parallel with US1-US3 (different files)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no dependencies on other stories
- **US2 (P1)**: Can start after Phase 2 — no dependencies on other stories (different file: qa.run.md vs qa.plan.md)
- **US3 (P2)**: Can start after Phase 2 — no dependencies on other stories (different file: qa.check.md)
- **US4 (P2)**: Depends on US1 + US2 — reviews/enhances their templates
- **US5 (P3)**: Can start after Phase 2 — independent files (publish.yml, README.md)

### Within Each User Story

- Command template before integration review
- Core behavior before error handling
- Error handling before graceful degradation

### Parallel Opportunities

- T004 + T005 can run in parallel (detect.js + index.yaml template — different files)
- T008 + T009 + T010 can run in parallel after Phase 2 (three separate command templates)
- T013 + T014 can run in parallel (publish workflow + README — different files)
- T015 + T016 can run in parallel (two different tcsetup files)

---

## Parallel Example: Phase 3-5 (US1 + US2 + US3)

```bash
# After Phase 2 is complete, launch all three command templates in parallel:
Task: "Write /qa.plan template in packages/qa-system/templates/commands/qa.plan.md"
Task: "Write /qa.run template in packages/qa-system/templates/commands/qa.run.md"
Task: "Write /qa.check template in packages/qa-system/templates/commands/qa.check.md"
```

---

## Implementation Strategy

### MVP First (US1 + US2 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T007)
3. Complete Phase 3: US1 — `/qa.plan` (T008)
4. Complete Phase 4: US2 — `/qa.run` (T009)
5. **STOP and VALIDATE**: Install package, run `/qa.plan` then `/qa.run` on a real feature
6. The core plan-run loop is functional — developer can verify acceptance criteria

### Incremental Delivery

1. Setup + Foundational → Package installable
2. Add US1 (`/qa.plan`) → Test plans can be generated (MVP start)
3. Add US2 (`/qa.run`) → Full plan-run verdict loop works (MVP complete!)
4. Add US3 (`/qa.check`) → Cross-feature freshness monitoring
5. Add US4 (Traceability) → Reviewer experience polished
6. Add US5 (Publishing) → Package distributable via npm
7. Polish → Ecosystem integration complete

### Solo Developer Strategy

Work sequentially in priority order: Phase 1 → Phase 2 → US1 → US2 → US3 → US4 → US5 → Polish. Each phase is a natural commit point.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- The core deliverables are 3 slash command templates (qa.plan.md, qa.run.md, qa.check.md) — these encode the actual QA behavior as Claude Code prompts
- The npm package (installer/updater/detect) is the distribution mechanism, not the core logic
- Each command template should be self-contained — a complete specification of what Claude Code does when the command is invoked
- Commit after each phase for clean git history

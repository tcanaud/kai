# Tasks: kai Product Manager Module

**Input**: Design documents from `/specs/008-product-manager/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested — no test tasks included. `/product.check` serves as the self-testing mechanism.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Package Infrastructure)

**Purpose**: Create the npm package structure following the kai package pattern

- [x] T001 Create GitHub repo `tcanaud/product-manager` and initialize locally at packages/product-manager/
- [x] T002 Create packages/product-manager/package.json with ESM config, zero dependencies, bin entry `product-manager`, engines `>=18.0.0`, and files array `["bin/", "src/", "templates/"]`
- [x] T003 Create packages/product-manager/bin/cli.js with switch/case router for `init`, `update`, `help` commands and `--yes` flag support per contract in specs/008-product-manager/contracts/
- [x] T004 Create packages/product-manager/.github/workflows/publish.yml with trusted publishing config (verbatim from .knowledge/guides/create-new-package.md)
- [x] T005 [P] Create directory structure: packages/product-manager/src/, packages/product-manager/templates/commands/, packages/product-manager/templates/core/

---

## Phase 2: Foundational (Templates + Installer)

**Purpose**: Core templates and installer that MUST be complete before any slash command can be installed or tested

**Warning**: No user story work can begin until this phase is complete

- [x] T006 Create packages/product-manager/templates/core/feedback.tpl.md with YAML frontmatter schema from data-model.md (id, title, status, category, priority, source, reporter, created, updated, tags, exclusion_reason, linked_to, resolution) and `{{body}}` placeholder
- [x] T007 [P] Create packages/product-manager/templates/core/backlog.tpl.md with YAML frontmatter schema from data-model.md (id, title, status, category, priority, created, updated, owner, feedbacks, features, tags, promotion, cancellation) and `{{body}}` placeholder
- [x] T008 [P] Create packages/product-manager/templates/core/index.yaml with empty initial index structure from data-model.md (product_version, feedbacks with by_status/by_category/items, backlogs with by_status/items, metrics)
- [x] T009 Create packages/product-manager/src/detect.js exporting `detect(projectRoot)` that returns `{ hasProduct: boolean, productDir: string }` by checking for `.product/` marker directory
- [x] T010 Create packages/product-manager/src/installer.js exporting `install(flags)` that: (1) detects project root, (2) creates .product/ with all subdirectories (inbox/, feedbacks/{new,triaged,excluded,resolved}/, backlogs/{open,in-progress,done,promoted,cancelled}/, _templates/), (3) copies feedback.tpl.md and backlog.tpl.md to .product/_templates/, (4) copies index.yaml to .product/index.yaml, (5) copies all 6 product.*.md command templates to .claude/commands/, (6) respects --yes flag for skip confirmation
- [x] T011 Create packages/product-manager/src/updater.js exporting `update(flags)` that: (1) detects .product/ exists, (2) refreshes only command templates in .claude/commands/product.*.md (overwrite), (3) refreshes _templates/ files (overwrite), (4) NEVER touches user data (feedbacks/, backlogs/, inbox/, index.yaml)

**Checkpoint**: Package infrastructure ready — `npx product-manager init` can scaffold `.product/` and install commands. Slash command creation can now begin.

---

## Phase 3: User Story 1 — Capture Feedback (Priority: P1) — MVP

**Goal**: A user can run `/product.intake` with a text description or inbox files and get structured feedback entries in `.product/feedbacks/new/`

**Independent Test**: Run `/product.intake "search is slow on large repos"` → verify FB-001.md appears in `.product/feedbacks/new/` with correct YAML frontmatter (id, title, category, source, created) and the description as body content

### Implementation for User Story 1

- [x] T012 [US1] Create packages/product-manager/templates/commands/product.intake.md implementing the full execution flow from specs/008-product-manager/contracts/product.intake.md: (1) validate .product/ exists and feedback.tpl.md is available, (2) Mode 1: free-text intake — scan all feedbacks/ subdirs for highest FB-xxx number, assign next ID, analyze content to propose category from predefined set, create feedback file using template, fill frontmatter and body, (3) Mode 2: inbox processing — list .product/inbox/ files, for each: read content and optional YAML frontmatter, extract metadata, assign ID, propose category, create structured feedback, remove inbox file, (4) Combined mode: process both if arguments AND inbox files exist, (5) update index.yaml with new entries, (6) output Markdown report with table of created feedbacks, (7) handle errors: missing .product/ dir, empty input+inbox, unreadable inbox files

**Checkpoint**: User Story 1 is independently functional — feedbacks can be captured and stored as structured files

---

## Phase 4: User Story 2 — Triage Feedback with AI Semantic Clustering (Priority: P1)

**Goal**: Running `/product.triage` reads all new feedbacks, performs semantic clustering, detects duplicates/regressions, proposes backlogs, and moves feedbacks to triaged/excluded status

**Independent Test**: Create 5+ feedbacks in `feedbacks/new/` with varying phrasings about overlapping topics, run `/product.triage`, verify related feedbacks are grouped together and backlog items appear in `backlogs/open/`

### Implementation for User Story 2

- [x] T013 [US2] Create packages/product-manager/templates/commands/product.triage.md implementing the full execution flow from specs/008-product-manager/contracts/product.triage.md: (1) validate .product/ exists and feedbacks/new/ has items, (2) read all files in feedbacks/new/, feedbacks/resolved/ (for regression detection), and feedbacks/triaged/ (for context), (3) semantic analysis: cluster new feedbacks by semantic similarity (not keyword matching), compare against resolved feedbacks for regression/duplicate detection using temporal logic (feedback created date vs feature stage_since date from .features/xxx.yaml), propose categories, (4) present triage proposal with groups, exclusions, regressions in structured Markdown, (5) autonomous mode (default): execute all actions immediately, (6) supervised mode (--supervised): present each action individually and wait for user confirmation, (7) execute: move feedbacks to triaged/ or excluded/, create backlog files in backlogs/open/ using backlog.tpl.md, update bidirectional links in feedback and backlog frontmatter, (8) update index.yaml, (9) output Markdown report with action table, (10) handle errors: no new feedbacks, missing .product/, batch > 30 items warning

**Checkpoint**: User Stories 1 AND 2 are functional — feedbacks can be captured, triaged into clusters, and converted to backlogs

---

## Phase 5: User Story 3 — Promote Backlog to Feature (Priority: P1)

**Goal**: Running `/product.promote BL-xxx` converts a backlog item into a kai feature with full traceability links

**Independent Test**: After triage creates BL-001, run `/product.promote BL-001` → verify .features/009-xxx.yaml is created, BL-001.md moves to backlogs/promoted/, and linked feedbacks have the feature ID in their linked_to.features[]

### Implementation for User Story 3

- [x] T014 [US3] Create packages/product-manager/templates/commands/product.promote.md implementing the full execution flow from specs/008-product-manager/contracts/product.promote.md: (1) validate $ARGUMENTS is provided and is a BL-xxx ID, (2) find backlog file in backlogs/open/ or backlogs/in-progress/, (3) read .features/index.yaml to determine next feature number, derive feature name from backlog title in kebab-case, (4) create .features/{NNN}-{name}.yaml from .features/_templates/feature.tpl.yaml with replaced placeholders (feature_id, title, owner, date, timestamp) and workflow_path: "full", (5) add new feature to .features/index.yaml, (6) move backlog file to backlogs/promoted/ and update frontmatter (status, promotion.promoted_date, promotion.feature_id, features[]), (7) for each feedback in the backlog's feedbacks[] array: read the feedback file and add feature ID to linked_to.features[], (8) update .product/index.yaml, (9) output Markdown report with traceability chain and next steps (/feature.workflow), (10) handle errors: empty args, not found, already promoted, wrong status

**Checkpoint**: The complete P1 pipeline is functional — feedback → triage → backlog → feature promotion with intact traceability at every step

---

## Phase 6: User Story 6 — Browse and Manage Backlog (Priority: P2)

**Goal**: Running `/product.backlog` lists all backlogs by status; running `/product.backlog BL-xxx` shows detail with linked feedbacks

**Independent Test**: After triage creates backlogs, run `/product.backlog` → verify grouped listing appears; run `/product.backlog BL-001` → verify detail view shows linked feedbacks with titles and statuses

### Implementation for User Story 6

- [x] T015 [P] [US6] Create packages/product-manager/templates/commands/product.backlog.md implementing the full execution flow from specs/008-product-manager/contracts/product.backlog.md: (1) validate .product/ exists, (2) Mode 1 (no args): read index.yaml or scan filesystem, group backlogs by status directory (open, in-progress, done, promoted, cancelled), display summary tables with ID, title, priority, feedbacks count, created date, (3) Mode 2 (BL-xxx arg): find backlog file across all status directories, read full content, for each linked feedback ID read title and current status, display detail view with frontmatter fields and linked feedbacks table, (4) handle errors: BL-xxx not found, no backlogs exist

**Checkpoint**: User Story 6 independently functional — backlogs can be browsed and inspected

---

## Phase 7: User Story 4 — View Product Dashboard (Priority: P2)

**Goal**: Running `/product.dashboard` displays a complete product health overview with status counts, category distribution, conversion metrics, and warnings

**Independent Test**: After creating feedbacks and backlogs in various statuses, run `/product.dashboard` → verify correct counts, distributions, conversion percentages, and warnings

### Implementation for User Story 4

- [x] T016 [P] [US4] Create packages/product-manager/templates/commands/product.dashboard.md implementing the full execution flow from specs/008-product-manager/contracts/product.dashboard.md: (1) validate .product/ exists, (2) read index.yaml for cached data or scan filesystem if missing, (3) compute: feedbacks by status (new, triaged, excluded, resolved), backlogs by status (open, in-progress, done, promoted, cancelled), category distribution across feedbacks, conversion metrics (feedback-to-backlog rate, backlog-to-feature rate, resolution rate), (4) identify warnings: stale feedbacks in new/ > 14 days, critical-priority backlogs, (5) default Markdown output with tables for feedbacks, backlogs, categories, metrics, and warnings, (6) --json flag: output structured JSON matching the schema in the contract, (7) handle errors: missing .product/, empty state shows all zeros

**Checkpoint**: User Story 4 independently functional — product health visible at a glance

---

## Phase 8: User Story 5 — Detect Drift and Integrity Issues (Priority: P2)

**Goal**: Running `/product.check` detects inconsistencies: status/directory desync, stale feedbacks, orphaned backlogs, broken traceability chains, index desync, and duplicate IDs

**Independent Test**: Deliberately introduce desync (move a file without updating frontmatter), run `/product.check` → verify the finding is reported with severity, description, and suggested fix

### Implementation for User Story 5

- [x] T017 [P] [US5] Create packages/product-manager/templates/commands/product.check.md implementing the full execution flow from specs/008-product-manager/contracts/product.check.md: (1) validate .product/ exists, (2) Check 1 — status/directory desync: for each feedback and backlog file, compare frontmatter status against directory name, (3) Check 2 — stale feedbacks: for each feedback in new/ where today minus created > 14 days, (4) Check 3 — orphaned backlogs: for each backlog verify all feedbacks[] IDs exist as files, (5) Check 4 — broken traceability chains: verify feedback linked_to.backlog[] references exist, verify backlog features[] references exist as .features/ files, (6) Check 5 — index consistency: compare index.yaml against actual filesystem state, auto-rebuild if desync, (7) Check 6 — ID uniqueness: scan for duplicate id fields, (8) classify findings by severity (ERROR, WARNING, INFO), (9) output structured report with findings and verdict (PASS/FAIL), (10) handle errors: missing .product/, empty state

**Checkpoint**: All 6 user stories are independently functional

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Integration, packaging, and final touches

- [x] T018 Register packages/product-manager/ as git submodule in kai: `git submodule add` and add to root package.json
- [x] T019 Update packages/tcsetup/src/installer.js: add `{ name: "Product Manager", flag: "--skip-product", cmd: "npx product-manager init --yes" }` to steps array
- [x] T020 [P] Update packages/tcsetup/src/updater.js: add `{ name: "Product Manager", marker: ".product", pkg: "product-manager", cmd: "npx product-manager update" }` to TOOLS array
- [x] T021 [P] Update packages/tcsetup/bin/cli.js: add `--skip-product` to HELP text
- [ ] T022 Run `/product.check` on a test `.product/` directory to validate the full setup works end-to-end
- [x] T023 Create initial commit, push, tag v1.0.0, and configure trusted publishing on npmjs.com for packages/product-manager/

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **User Stories (Phases 3-8)**: All depend on Phase 2 completion
  - **US1 (Phase 3)** must complete before US2 can be meaningfully tested (triage needs feedbacks)
  - **US2 (Phase 4)** must complete before US3 can be tested (promote needs backlogs)
  - **US6 (Phase 6)**, **US4 (Phase 7)**, **US5 (Phase 8)** can run in parallel once Phase 2 is done
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 — Capture Feedback (P1)**: Can start after Phase 2 — no dependencies on other stories
- **US2 — Triage (P1)**: Functionally depends on US1 (needs feedbacks to triage) but the slash command template can be written independently
- **US3 — Promote (P1)**: Functionally depends on US2 (needs backlogs to promote) but the template can be written independently
- **US6 — Browse Backlog (P2)**: Independent — can start after Phase 2
- **US4 — Dashboard (P2)**: Independent — can start after Phase 2
- **US5 — Drift Detection (P2)**: Independent — can start after Phase 2

### Within Each User Story

- Each user story is a single slash command template (one file)
- The template must implement the full contract from specs/008-product-manager/contracts/
- Reference the data model schemas from specs/008-product-manager/data-model.md

### Parallel Opportunities

- T004 and T005 can run in parallel (CI config and directory structure)
- T006, T007, T008 can run in parallel (independent template files)
- T015, T016, T017 can run in parallel (independent P2 slash commands)
- T019, T020, T021 can run in parallel (independent tcsetup files)

---

## Parallel Example: P2 User Stories

```bash
# After Phase 2 completes, all P2 slash commands can be written in parallel:
Task T015: "Create product.backlog.md in packages/product-manager/templates/commands/"
Task T016: "Create product.dashboard.md in packages/product-manager/templates/commands/"
Task T017: "Create product.check.md in packages/product-manager/templates/commands/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Package setup
2. Complete Phase 2: Templates + installer
3. Complete Phase 3: `/product.intake` command
4. **STOP and VALIDATE**: Run `npx product-manager init`, then `/product.intake "test feedback"` → verify FB-001.md appears correctly
5. The system captures feedback — immediate value delivered

### Incremental Delivery

1. Phase 1 + 2 → Package installable via `npx product-manager init`
2. Add US1 → Feedback capture works (MVP!)
3. Add US2 → Triage converts feedbacks to backlogs
4. Add US3 → Backlogs promote to features — **full P1 pipeline complete**
5. Add US6 → Backlog browsing
6. Add US4 → Dashboard visibility
7. Add US5 → Drift detection — **full P2 complete**
8. Phase 9 → tcsetup integration, publish

### Recommended Execution Order

```
T001 → T002 → T003 → T004+T005 (parallel)
  → T006+T007+T008 (parallel) → T009 → T010 → T011
    → T012 → T013 → T014
      → T015+T016+T017 (parallel)
        → T018 → T019+T020+T021 (parallel) → T022 → T023
```

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each slash command template must be self-contained with full execution flow, error handling, and Markdown output
- Slash commands follow the pattern of existing kai commands (agreement.check.md, feature.status.md) — numbered steps, filesystem reads/writes, structured output
- All `node:` protocol imports in src/ files (zero runtime dependencies)
- The `__dirname` boilerplate is required for template path resolution in installer.js and updater.js
- Commit after each task or logical group

# Tasks: CLI Atomique @tcanaud/kai-product Pour Opérations Produit

**Input**: Design documents from `/specs/018-cli-kai-product/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-interface.md, contracts/file-schemas.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. Tests are included per the spec (Node.js native `node:test` runner — zero external test framework dependencies).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Exact file paths reference `packages/kai-product/` at repo root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the package skeleton — directory tree, package.json, CLI entry point, and the help command — so all subsequent phases have a working shell to add to.

- [x] T001 Create package directory structure `packages/kai-product/` with `bin/`, `src/commands/`, `src/`, `tests/unit/`, `tests/integration/`, `templates/` subdirectories
- [x] T002 Create `packages/kai-product/package.json` with `"type": "module"`, `"name": "@tcanaud/kai-product"`, `"bin": { "kai-product": "bin/cli.js" }`, `"engines": { "node": ">=18.0.0" }`, no runtime dependencies
- [x] T003 Create `packages/kai-product/bin/cli.js` as the argv router: parse `process.argv[2]` to dispatch to subcommands (`reindex`, `move`, `check`, `promote`, `triage`, `init`, `update`, `help`); unknown command prints error + usage to stderr and exits 1
- [x] T004 Implement `help` output in `packages/kai-product/bin/cli.js` matching the quickstart.md expected usage block (all 8 commands listed)

**Checkpoint**: `node packages/kai-product/bin/cli.js help` prints correct usage.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared utility modules (`yaml-parser.js`, `scanner.js`, `index-writer.js`) that every command depends on. MUST be complete before any user story phase begins.

**CRITICAL**: No user story work can begin until this phase is complete.

- [x] T005 Implement `packages/kai-product/src/yaml-parser.js` — export `parseFrontmatter(content: string): { frontmatter: object, body: string }` using regex-based `---` delimiter splitting and key/value + block-list parsing (no npm deps); handle nested objects (`linked_to`, `resolution`, `promotion`, `cancellation`) via indent tracking; handle empty/missing frontmatter gracefully
- [x] T006 Implement `serializeFrontmatter(frontmatter: object): string` in `packages/kai-product/src/yaml-parser.js` — convert object back to YAML string preserving the schema field order defined in `contracts/file-schemas.md`; support scalar, list (block and inline `[]`), and nested object fields; round-trip safe (unknown fields preserved)
- [x] T007 [P] Write unit tests for `parseFrontmatter` in `packages/kai-product/tests/unit/yaml-parser.test.js` — test feedback frontmatter parsing, backlog frontmatter parsing, malformed frontmatter error reporting (with file path + line number), empty block lists `[]`, nested objects, priority `null` serialized as empty string
- [x] T008 [P] Write unit tests for `serializeFrontmatter` in `packages/kai-product/tests/unit/yaml-parser.test.js` — verify round-trip correctness for both feedback and backlog schemas
- [x] T009 Implement `packages/kai-product/src/scanner.js` — export `scanProduct(productDir: string): Promise<{ feedbacks: Feedback[], backlogs: Backlog[] }>` walking all status subdirs; export `findBacklog(productDir, id): Promise<Backlog | null>` searching all backlog status subdirs; export `findFeedback(productDir, id): Promise<Feedback | null>`; each parsed entity includes `_filePath` (absolute) and `_body` runtime fields; malformed frontmatter: log warning with file path, skip file, continue
- [x] T010 [P] Write unit tests for scanner in `packages/kai-product/tests/unit/scanner.test.js` — use `node:os` tmpdir fixtures per quickstart.md pattern; verify `scanProduct` returns correct counts for seeded fixture; verify `findBacklog` returns null for missing ID; verify `findFeedback` works across all status dirs; verify malformed file is skipped with warning
- [x] T011 Implement `packages/kai-product/src/index-writer.js` — export `writeIndex(productDir: string, feedbacks: Feedback[], backlogs: Backlog[]): Promise<void>` producing `index.yaml` per `contracts/file-schemas.md` full schema; atomic write (write to `index.yaml.tmp` then `fs.rename`); sort items by numeric ID (FB-1 < FB-2 < FB-10); compute `feedback_to_backlog_rate` and `backlog_to_feature_rate` metrics; `by_category` counts for feedbacks
- [x] T012 [P] Write unit tests for index-writer in `packages/kai-product/tests/unit/index-writer.test.js` — verify correct YAML output for known fixture data; verify atomic write (tmp → rename); verify numeric ID sorting; verify metrics computation (0 denominator edge case); verify `by_category` aggregation
- [x] T013 Implement shared error/exit helpers in `packages/kai-product/src/errors.js` — `productDirNotFound(dir)` prints message to stderr and calls `process.exit(1)`; `validationError(messages[])` prints structured error to stderr; `parseError(filePath, message)` prints file + reason to stderr; global `unhandledRejection` handler in `bin/cli.js` following `@tcanaud/playbook` pattern

**Checkpoint**: `node --test packages/kai-product/tests/unit/*.test.js` passes all foundational unit tests.

---

## Phase 3: User Story 1 — Reindex Product Data (Priority: P1) MVP

**Goal**: `kai-product reindex` scans `.product/` and regenerates `index.yaml` with accurate counts, categories, and item listings.

**Independent Test**: Create a `.product/` fixture with known feedbacks/backlogs in all status dirs → run `reindex` → parse output `index.yaml` and assert counts, item IDs, metrics match expected values.

### Implementation for User Story 1

- [x] T014 [US1] Implement `packages/kai-product/src/commands/reindex.js` — export `reindex(options: { productDir?: string }): Promise<void>`; resolve `productDir` from env `KAI_PRODUCT_DIR` or `{cwd}/.product`; validate `.product/` exists (call `productDirNotFound` if not); call `scanProduct`, then `writeIndex`; print human-readable summary to stdout: feedbacks by status, backlogs by status, "index.yaml updated." per `contracts/cli-interface.md`; exit 0 on success, exit 1 on error
- [x] T015 [US1] Wire `reindex` subcommand in `packages/kai-product/bin/cli.js` to import and invoke `reindex.js`
- [x] T016 [US1] Write integration test for reindex in `packages/kai-product/tests/integration/reindex.test.js` — scenario 1: fixture with feedbacks + backlogs across all statuses → verify `index.yaml` counts and items; scenario 2: stale `index.yaml` overwritten with correct data; scenario 3: empty `.product/` → all counts zero; verify exit code 0

**Checkpoint**: `node packages/kai-product/bin/cli.js reindex` regenerates `index.yaml` correctly against the live `.product/` directory.

---

## Phase 4: User Story 2 — Move Backlogs Between Statuses (Priority: P1)

**Goal**: `kai-product move <ids> <status>` relocates one or more backlog files, updates frontmatter, and regenerates the index — atomically.

**Independent Test**: Place BL-001 in `backlogs/open/` → run `move BL-001 done` → verify file is in `backlogs/done/`, frontmatter `status` = `done`, `updated` = today, `index.yaml` regenerated. Run `move BL-999 done` → verify no files changed, exit 1.

### Implementation for User Story 2

- [x] T017 [US2] Implement `packages/kai-product/src/commands/move.js` — export `move(args: string[], options): Promise<void>`; parse `args[0]` as comma-separated IDs, `args[1]` as target status; validate target status is one of `open|in-progress|done|promoted|cancelled` (fail-fast); call `findBacklog` for each ID and collect missing IDs; if any missing: print all errors to stderr + "Validation failed. No files were moved." + exit 1 (all-or-nothing); handle "already in target status" per-item (report, skip, still exit 0); for each item to move: `fs.rename` file to new directory, update `status` and `updated` fields in frontmatter, write updated file; after all moves: call `writeIndex` via `scanProduct`; print progress per `contracts/cli-interface.md` stdout examples; exit 0
- [x] T018 [US2] Wire `move` subcommand in `packages/kai-product/bin/cli.js`
- [x] T019 [US2] Write integration test for move in `packages/kai-product/tests/integration/move.test.js` — scenario 1: single move BL-005 open → done: verify file location, frontmatter status + updated, index regenerated; scenario 2: bulk move BL-001,BL-002,BL-003 → done: verify all three; scenario 3: missing ID BL-999: verify no files moved, exit 1; scenario 4: already-in-target-status: verify no change, exit 0; scenario 5: mix of valid + invalid IDs: verify all-or-nothing (no files moved), exit 1

**Checkpoint**: `kai-product move BL-007 in-progress` correctly moves the file and regenerates `index.yaml`.

---

## Phase 5: User Story 3 — Check Product Integrity (Priority: P2)

**Goal**: `kai-product check [--json]` detects all five integrity issue types and reports them in human-readable or JSON format.

**Independent Test**: Seed fixture with known issues (status desync, stale feedback, broken chain, orphan, index desync) → run `check` → verify each issue is reported; run on clean fixture → verify exit 0 and no issues.

### Implementation for User Story 3

- [x] T020 [US3] Implement `packages/kai-product/src/commands/check.js` — export `check(options: { productDir?: string, json?: boolean }): Promise<void>`; validate `.product/` exists; call `scanProduct`; run all five check routines:
  1. **Status/directory desync**: compare each item's `status` field to its parent directory name
  2. **Stale feedbacks**: items in `feedbacks/new/` where `(today - created) >= 14 days`
  3. **Broken traceability**: feedbacks with `linked_to.backlog[]` IDs that don't exist in any backlog dir; backlogs with `feedbacks[]` IDs that don't exist in any feedback dir
  4. **Orphaned backlogs**: backlogs in `open/` with empty `feedbacks[]`
  5. **Index desync**: read existing `index.yaml` and compare counts to scanned totals
  Collect all issues into array; if `--json`: output JSON per `contracts/cli-interface.md` JSON schema to stdout; if no `--json`: print human-readable report per stdout example; exit 0 if no issues, exit 1 if any issues
- [x] T021 [US3] Wire `check` subcommand in `packages/kai-product/bin/cli.js` (parse `--json` flag)
- [x] T022 [US3] Write integration test for check in `packages/kai-product/tests/integration/check.test.js` — scenario 1: status desync (BL in `open/` with `status: done` in frontmatter) → verify reported; scenario 2: feedback linking to non-existent BL → verify broken chain reported; scenario 3: feedback in `new/` older than 14 days → verify stale reported; scenario 4: fully consistent fixture → exit 0, no issues; scenario 5: index.yaml out of sync → verify desync reported; scenario 6: `--json` flag produces valid JSON matching schema; verify exit codes

**Checkpoint**: `kai-product check --json` returns valid JSON on the live repo; `kai-product check` prints a readable report.

---

## Phase 6: User Story 4 — Promote Backlog to Feature (Priority: P2)

**Goal**: `kai-product promote <id>` creates the feature YAML in `.features/`, moves the backlog to `promoted/`, updates linked feedbacks, and regenerates all indexes — atomically.

**Independent Test**: Create fixture with BL-007 (open, linked to FB-102) → run `promote BL-007` → verify `.features/NNN-{slug}.yaml` exists with correct schema, BL-007 is in `backlogs/promoted/` with updated frontmatter, FB-102 has the feature ID in `linked_to.features[]`, index regenerated. Run `promote BL-003` on already-promoted item → verify error, no changes.

### Implementation for User Story 4

- [x] T023 [US4] Implement feature number determination in `packages/kai-product/src/commands/promote.js` — scan `.features/` for `\d+-(*.yaml)` files AND `specs/` for `\d+-*` directories from repo root; extract all numeric prefixes; `next_number = max(all_found) + 1`, zero-padded to 3 digits; handle collision-by-design (scan both sources)
- [x] T024 [US4] Implement slug generation in `packages/kai-product/src/commands/promote.js` — from backlog `title`: lowercase, replace spaces and special chars with hyphens, collapse multi-hyphens, truncate to 60 chars, strip leading/trailing hyphens; per `contracts/file-schemas.md` slug generation rules
- [x] T025 [US4] Implement feature YAML template generation in `packages/kai-product/src/commands/promote.js` — produce the full feature YAML per `contracts/file-schemas.md` Feature YAML Schema (including all sections: lifecycle, artifacts, health, last_scan, conventions)
- [x] T026 [US4] Implement `promote(args: string[], options): Promise<void>` main function in `packages/kai-product/src/commands/promote.js` — validate backlog exists; validate backlog status is NOT `promoted` (error: "BL-XXX is already promoted"); determine next feature number; create `.features/{NNN}-{slug}.yaml`; move backlog file to `backlogs/promoted/`; update backlog frontmatter: `status: promoted`, `promotion.promoted_date`, `promotion.feature_id`, `features[]` (add), `updated`; for each ID in `feedbacks[]`: call `findFeedback`, add feature ID to `linked_to.features[]`, update `updated`, write file; call `writeIndex`; print progress per `contracts/cli-interface.md` stdout example; exit 0 on success, exit 1 on error
- [x] T027 [US4] Wire `promote` subcommand in `packages/kai-product/bin/cli.js`
- [x] T028 [US4] Write integration test for promote in `packages/kai-product/tests/integration/promote.test.js` — scenario 1: open BL-007 with linked FB-102 → verify feature YAML created (check all required fields), BL moved to promoted/, FB-102 has feature link, index regenerated; scenario 2: already-promoted backlog → verify exit 1 and no file changes; scenario 3: backlog with no linked feedbacks → verify promotion still succeeds; scenario 4: verify feature number is `max(existing) + 1` zero-padded

**Checkpoint**: `kai-product promote BL-NNN` produces a valid feature YAML and correctly updates all linked files.

---

## Phase 7: User Story 5 — Triage New Feedbacks (Priority: P3)

**Goal**: `kai-product triage --plan` emits a JSON list of new feedbacks; `kai-product triage --apply <file>` applies an AI-annotated plan atomically (create backlogs, link existing, exclude feedbacks, regenerate index).

**Independent Test**: Seed 3 feedbacks in `feedbacks/new/` → run `triage --plan` → verify JSON output has correct `feedbacks[]` array and empty `plan[]`; write a plan JSON with `create_backlog` + `link_existing` + `exclude` entries → run `triage --apply plan.json` → verify backlog created in `backlogs/open/`, feedbacks moved to `triaged/` or `excluded/`, frontmatter updated with backlog links, index regenerated.

### Implementation for User Story 5

- [x] T029 [US5] Implement `triage --plan` phase in `packages/kai-product/src/commands/triage.js` — export `triagePlan(options): Promise<void>`; scan `feedbacks/new/`; output JSON to stdout per `contracts/cli-interface.md` Plan Output schema (version, generated_at, feedbacks array with id/title/body/created/days_old, empty plan array); no files modified; exit 0 even if no new feedbacks (empty feedbacks array); exit 1 on `.product/` not found or parse error
- [x] T030 [US5] Implement plan validation in `packages/kai-product/src/commands/triage.js` — before any file operations: validate plan `version === "1.0"`; each `feedback_id` exists in `feedbacks/new/`; each `backlog_id` (for `link_existing`) exists in any backlog dir; no feedback ID appears in more than one plan entry; `backlog_title` required for `create_backlog`; `reason` required for `exclude`; collect all validation errors and fail-fast (print all, no files touched)
- [x] T031 [US5] Implement backlog number determination in `packages/kai-product/src/commands/triage.js` — scan all backlog status dirs for `BL-\d+` files; `next_number = max(all_found) + 1`, zero-padded to 3 digits; each `create_backlog` entry in the plan gets the next sequential number (increment for each)
- [x] T032 [US5] Implement `triage --apply` phase in `packages/kai-product/src/commands/triage.js` — export `triageApply(planFile: string, options): Promise<void>`; read and parse JSON plan file; run plan validation (T030); for each plan entry in order:
  - `create_backlog`: determine next BL number, create `backlogs/open/BL-NNN.md` with correct frontmatter (title, category, priority, owner, feedbacks[], regression note in body if `regression: true`), move each feedback to `feedbacks/triaged/`, update each feedback frontmatter (`status: triaged`, `linked_to.backlog[]` add BL-NNN, `updated`)
  - `link_existing`: add each feedback ID to existing backlog's `feedbacks[]`, update backlog `updated`, move feedbacks to `feedbacks/triaged/`, update feedback frontmatter
  - `exclude`: move feedbacks to `feedbacks/excluded/`, update frontmatter (`status: excluded`, `exclusion_reason: reason`, `updated`)
  Final step: call `writeIndex`; print progress per `contracts/cli-interface.md` stdout example; exit 0 on success, exit 1 on error
- [x] T033 [US5] Wire `triage` subcommand in `packages/kai-product/bin/cli.js` — parse `--plan` flag vs `--apply <file>` flag; validate mutually exclusive; missing flag → error message + usage
- [x] T034 [US5] Write integration test for triage in `packages/kai-product/tests/integration/triage.test.js` — scenario 1: 3 feedbacks in new/ with `create_backlog` plan → verify backlog created, feedbacks in triaged/, links correct, index regenerated; scenario 2: `link_existing` plan entry → verify existing backlog updated, feedbacks in triaged/; scenario 3: `exclude` entry → feedbacks in excluded/, exclusion_reason set; scenario 4: no new feedbacks → `--plan` outputs empty feedbacks array, exit 0; scenario 5: invalid plan (missing feedback) → exit 1, no files modified; scenario 6: feedback ID in two plan entries → exit 1

**Checkpoint**: Full triage workflow works: `triage --plan` → AI annotates JSON → `triage --apply plan.json` creates backlogs and moves feedbacks.

---

## Phase 8: Installer & Updater (FR-014)

**Purpose**: `init` and `update` commands following the `@tcanaud/playbook` pattern.

- [x] T035 [P] Create slash command templates in `packages/kai-product/templates/` — five Markdown files: `product.reindex.md`, `product.move.md`, `product.check.md`, `product.promote.md`, `product.triage.md`; each template invokes the CLI via Bash tool call with appropriate arguments and documents usage for the Claude Code operator
- [x] T036 Implement `packages/kai-product/src/installer.js` — export `init(options: { yes?: boolean }): Promise<void>`; scaffold `.product/` directory tree per `contracts/cli-interface.md` init command (feedbacks/{new,triaged,excluded,resolved}/, backlogs/{open,in-progress,done,promoted,cancelled}/, index.yaml with empty initial values); copy templates from `templates/` to `.claude/commands/`; prompt for confirmation unless `--yes`; skip existing directories; print progress
- [x] T037 Implement `packages/kai-product/src/updater.js` — export `update(): Promise<void>`; refresh slash command templates in `.claude/commands/` without modifying `.product/` data; print what was updated
- [x] T038 Wire `init` and `update` subcommands in `packages/kai-product/bin/cli.js`

**Checkpoint**: `kai-product init --yes` scaffolds `.product/` and installs slash commands in a clean directory.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final hardening, edge-case handling, and validation that the package is publish-ready.

- [x] T039 [P] Add `KAI_PRODUCT_DIR` environment variable support across all commands in `packages/kai-product/src/commands/*.js` — each command resolves product dir as: `KAI_PRODUCT_DIR` env var → `{cwd}/.product` fallback
- [x] T040 [P] Implement edge case: missing `.product/` directory detection in all commands — call `productDirNotFound` with setup instructions message consistent with `contracts/cli-interface.md`
- [x] T041 [P] Implement edge case: malformed YAML frontmatter in `scanner.js` — report error with file path, skip file, continue processing (already scoped in T009, verify consistent behavior across all commands)
- [x] T042 Verify all exit codes match `contracts/cli-interface.md` specifications — audit each command's success and error paths; add `process.exitCode = 1` guard in unhandledRejection handler
- [x] T043 Run full test suite and verify all pass: `node --test 'packages/kai-product/tests/**/*.test.js'`
- [x] T044 [P] Run quickstart.md validation scenarios against the live `.product/` directory — `node packages/kai-product/bin/cli.js help`, `reindex`, `check`, `check --json`; verify outputs match expected formats
- [x] T045 [P] Update `packages/kai-product/package.json` with final version, description, keywords, repository, and license fields for npm publish readiness

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 completion — BLOCKS all user story phases
- **Phase 3 (US1 — Reindex)**: Depends on Phase 2 completion; no dependency on other user story phases
- **Phase 4 (US2 — Move)**: Depends on Phase 2 completion; no dependency on US1
- **Phase 5 (US3 — Check)**: Depends on Phase 2 completion; no dependency on US1/US2
- **Phase 6 (US4 — Promote)**: Depends on Phase 2 completion; no dependency on US1/US2/US3
- **Phase 7 (US5 — Triage)**: Depends on Phase 2 completion; no dependency on other user stories
- **Phase 8 (Installer)**: Depends on Phase 1 completion; independent of user story phases
- **Phase 9 (Polish)**: Depends on all prior phases

### User Story Dependencies

- **User Story 1 (Reindex — P1)**: Can start after Phase 2; no story dependencies
- **User Story 2 (Move — P1)**: Can start after Phase 2; no story dependencies (uses same scanner/index-writer utilities)
- **User Story 3 (Check — P2)**: Can start after Phase 2; no story dependencies (read-only, uses scanner)
- **User Story 4 (Promote — P2)**: Can start after Phase 2; no story dependencies (uses scanner + index-writer)
- **User Story 5 (Triage — P3)**: Can start after Phase 2; no story dependencies

### Within Each User Story

- Command module implemented first
- CLI wiring second (depends on command module)
- Integration tests third (verify end-to-end behavior)

### Parallel Opportunities

- T005 and T009 and T011 can run in parallel (separate files)
- T007/T008 (yaml-parser tests) can run in parallel with T010 (scanner tests) and T012 (index-writer tests)
- T014 (reindex), T017 (move), T020 (check), T023–T026 (promote), T029–T032 (triage) can ALL start in parallel once Phase 2 is complete
- T035 (templates) can run in parallel with any user story phase
- T039, T040, T041, T044, T045 (polish) can run in parallel with each other

---

## Parallel Execution Examples

### Phase 2 Foundational — parallel core modules

```
Parallel track A: T005 → T006 → T007 → T008  (yaml-parser + tests)
Parallel track B: T009 → T010                 (scanner + tests)
Parallel track C: T011 → T012                 (index-writer + tests)
Sequential:       T013                        (errors.js, after A completes)
```

### User Stories — run in parallel after Phase 2

```
Track A (P1): T014 → T015 → T016  (US1 reindex)
Track B (P1): T017 → T018 → T019  (US2 move)
Track C (P2): T020 → T021 → T022  (US3 check)
Track D (P2): T023 → T024 → T025 → T026 → T027 → T028  (US4 promote)
Track E (P3): T029 → T030 → T031 → T032 → T033 → T034  (US5 triage)
Track F:      T035 → T036 → T037 → T038               (installer)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (reindex)
4. Complete Phase 4: User Story 2 (move)
5. **STOP and VALIDATE**: `kai-product reindex` and `kai-product move` work against live `.product/`
6. These two commands cover the most frequent operations (SC-001, SC-002)

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready, unit tests green
2. Phase 3 (reindex) → Core infrastructure validated end-to-end
3. Phase 4 (move) → Most frequent operation delivered (MVP)
4. Phase 5 (check) → Integrity verification added
5. Phase 6 (promote) → Complex promotion chain automated
6. Phase 7 (triage) → Full AI-assisted triage pipeline
7. Phase 8 (installer) → Package ready for `npx` distribution
8. Phase 9 (polish) → Publish-ready

---

## Notes

- All file paths in tasks are relative to repo root `/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai`
- `[P]` tasks operate on different files with no dependencies on incomplete sibling tasks
- `[Story]` label maps each task to its user story for traceability
- Each user story phase is independently testable via its integration test
- Zero runtime dependencies: `node:` protocol imports only throughout all source files
- Test runner: `node --test` (Node.js native, Node >= 18) — no Jest, no Vitest
- Fixture pattern: `mkdtempSync(join(tmpdir(), "kai-product-test-"))` per `quickstart.md`
- Commands resolve product dir via `KAI_PRODUCT_DIR` env var or `{cwd}/.product` fallback
- Commit after each phase checkpoint to preserve working increments

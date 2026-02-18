# Tasks: Verified Knowledge System

**Input**: Design documents from `/specs/007-knowledge-system/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/cli.md, quickstart.md

**Tests**: Not explicitly requested — test tasks omitted. Add via `/speckit.checklist` if needed.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Package root: `packages/knowledge-system/`
- Source: `packages/knowledge-system/src/`
- Templates: `packages/knowledge-system/templates/`
- CLI: `packages/knowledge-system/bin/cli.js`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create package skeleton with all structural files, templates, and package.json

- [x] T001 Create package directory structure and `packages/knowledge-system/package.json` with name `knowledge-system`, type `module`, bin entry `./bin/cli.js`, files array `["bin/", "src/", "templates/"]`, engines `node >= 18.0.0`, zero dependencies — follow exact pattern from `packages/feature-lifecycle/package.json`
- [x] T002 [P] Create core template files: `packages/knowledge-system/templates/core/config.yaml` (default config per data-model.md Config entity), `packages/knowledge-system/templates/core/index.yaml` (empty index skeleton per data-model.md Index entity), `packages/knowledge-system/templates/core/architecture.md` (scaffold per data-model.md Architecture Overview entity), `packages/knowledge-system/templates/core/guide.tpl.md` (guide template with YAML frontmatter per data-model.md Guide entity)
- [x] T003 [P] Create CLI skeleton `packages/knowledge-system/bin/cli.js` with shebang, switch/case router for init/update/refresh/check/help subcommands, help text listing all commands — follow exact pattern from `packages/feature-lifecycle/bin/cli.js`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared utilities that ALL user stories depend on — must complete before any story implementation

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Implement YAML frontmatter parser in `packages/knowledge-system/src/frontmatter.js` — export `parseFrontmatter(content)` that extracts YAML frontmatter from markdown content using regex `/^---\s*\n([\s\S]*?)\n---/`, returns object with all fields (id, title, created, last_verified, references, watched_paths, topics). Handle both string and array values. Follow regex-based pattern from research.md R6
- [x] T005 [P] Implement environment detection in `packages/knowledge-system/src/detect.js` — export `detect(projectRoot)` returning `{ hasBmad, bmadDir, hasSpeckit, hasAgreements, hasAdr, hasFeatures, hasKnowledge, hasClaudeCommands }`. Check for `_bmad`/`.bmad` variants. Follow exact pattern from `packages/feature-lifecycle/src/detect.js`
- [x] T006 [P] Implement config reader in `packages/knowledge-system/src/config.js` — export `readConfig(projectRoot)` that reads `.knowledge/config.yaml` and returns parsed config object with fields: version, freshness_threshold_days, sources (agreements_dir, adr_dir, features_dir, specs_dir), snapshot options. Use regex-based parsing per research.md R6. Also export `generateConfig(projectRoot, detected)` for init-time config generation from template

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 5 — Initialize Knowledge Directory (Priority: P1) MVP

**Goal**: Scaffold `.knowledge/` directory with default config, empty index, architecture.md scaffold, and guides/ directory. Idempotent — safe to re-run.

**Independent Test**: Run `npx knowledge-system init` in a project without `.knowledge/` and verify all structural files are created. Run again and verify existing content is preserved.

### Implementation for User Story 5

- [x] T007 [US5] Implement initializer in `packages/knowledge-system/src/initializer.js` — export async `install(flags)` that: (1) calls `detect(projectRoot)` to find environment, (2) creates `.knowledge/` directory, (3) writes `config.yaml` from template with detected source paths, (4) writes empty `index.yaml` from template, (5) writes `architecture.md` scaffold from template, (6) creates `guides/` subdirectory, (7) writes initial empty `snapshot.md`, (8) copies Claude Code command templates to `.claude/commands/`. Must be idempotent: skip existing files. Support `--yes` flag to skip confirmation. Follow 3-phase pattern from `packages/feature-lifecycle/src/initializer.js`
- [x] T008 [US5] Implement updater in `packages/knowledge-system/src/updater.js` — export `update(flags)` that: (1) verifies `.knowledge/` exists (exit 1 if not), (2) copies latest command templates to `.claude/commands/` overwriting old versions, (3) updates BMAD integration if `_bmad`/`.bmad` detected. MUST NOT modify `architecture.md`, `guides/*.md`, `config.yaml`, or `index.yaml`. Follow pattern from `packages/feature-lifecycle/src/updater.js`
- [x] T009 [US5] Wire `init` and `update` commands in `packages/knowledge-system/bin/cli.js` — import `install` from initializer.js and `update` from updater.js, connect to switch/case router. Verify `npx knowledge-system init` and `npx knowledge-system update` work end-to-end

**Checkpoint**: `npx knowledge-system init` scaffolds `.knowledge/` directory. `npx knowledge-system update` refreshes commands.

---

## Phase 4: User Story 2 — Refresh Knowledge Snapshot and Index (Priority: P1)

**Goal**: Regenerate `snapshot.md` and rebuild `index.yaml` from current project artifacts (conventions, ADRs, features, guides)

**Independent Test**: Run `npx knowledge-system refresh` in a project with ADRs, conventions, and features. Verify `snapshot.md` contains aggregated data and `index.yaml` maps concepts to artifacts.

### Implementation for User Story 2

- [x] T010 [P] [US2] Implement conventions scanner in `packages/knowledge-system/src/scanners/conventions.js` — export `scanConventions(projectRoot, config)` that reads `.agreements/conv-*/agreement.yaml` files, extracts id, title (from `title` field), path, intent (as summary), and derives topics from title keywords. Return array of `{ id, title, path, summary, topics }`. Skip non-convention agreements (those without `conv-` prefix)
- [x] T011 [P] [US2] Implement ADR scanner in `packages/knowledge-system/src/scanners/adrs.js` — export `scanAdrs(projectRoot, config)` that recursively scans `.adr/{global,domain,local}/*.md`, parses YAML frontmatter for id/title/status, extracts summary from first paragraph after frontmatter, derives topics from tags field. Return array of `{ id, title, path, summary, topics, status }`. Skip template.md, index.md, README.md
- [x] T012 [P] [US2] Implement features scanner in `packages/knowledge-system/src/scanners/features.js` — export `scanFeatures(projectRoot, config)` that reads `.features/*/feature.yaml` files, extracts feature_id, title, lifecycle.stage, derives topics from tags field. Return array of `{ id, title, path, summary, topics, status }` where status is the stage
- [x] T013 [P] [US2] Implement guides scanner in `packages/knowledge-system/src/scanners/guides.js` — export `scanGuides(projectRoot, config)` that reads `.knowledge/guides/*.md`, parses YAML frontmatter using `frontmatter.js`, returns array of `{ id, title, path, summary, topics, status, last_verified, watched_paths, references }`. Status determined by freshness (uses git log, see checker.js — initially set to "unknown" until checker is available)
- [x] T014 [US2] Create scanner index in `packages/knowledge-system/src/scanners/index.js` — export all four scanners and `scanAll(projectRoot, config)` that calls all scanners and returns `{ guides, conventions, adrs, features }`
- [x] T015 [US2] Implement refresher in `packages/knowledge-system/src/refresher.js` — export async `refresh()` that: (1) reads config via `config.js`, (2) calls `scanAll()` to get all artifacts, (3) builds index.yaml with version, generated timestamp, and all scanned entries, (4) builds snapshot.md with markdown tables for conventions, ADRs, features, and tech stack section. Write both files to `.knowledge/`. Follow snapshot template from plan.md D4
- [x] T016 [US2] Wire `refresh` command in `packages/knowledge-system/bin/cli.js` — import `refresh` from refresher.js, add to switch/case. Verify `npx knowledge-system refresh` regenerates snapshot and index

**Checkpoint**: `npx knowledge-system refresh` produces accurate `snapshot.md` and `index.yaml` from existing artifacts.

---

## Phase 5: User Story 1 — Query the Knowledge Base (Priority: P1)

**Goal**: `/k` Claude Code command that queries the knowledge base and returns assembled answers with source citations and VERIFIED/STALE tags

**Independent Test**: Initialize `.knowledge/` with a guide, run refresh, then use `/k` to query a topic covered by the guide. Verify response includes guide content, source citation, and verification status.

### Implementation for User Story 1

- [x] T017 [US1] Create `/k` Claude Code command template in `packages/knowledge-system/templates/commands/k.md` — prompt template that instructs Claude to: (1) check `.knowledge/` exists, (2) read `.knowledge/index.yaml`, (3) match user question against entry titles/summaries/topics, (4) read the most relevant sources (guides first, then conventions/ADRs), (5) for each guide source: check freshness by reading frontmatter last_verified and running `git log -1 --format=%aI` on watched_paths, (6) assemble answer with source citations each tagged VERIFIED or STALE, (7) if no relevant sources found: suggest `/knowledge.create`. Include handoffs to `/knowledge.create` and `/knowledge.refresh`
- [x] T018 [US1] Create `/knowledge.refresh` Claude Code command template in `packages/knowledge-system/templates/commands/knowledge.refresh.md` — prompt template that instructs Claude to run `npx knowledge-system refresh` and report results. Include handoff to `/knowledge.check`

**Checkpoint**: `/k` returns assembled, verified answers from the knowledge base.

---

## Phase 6: User Story 3 — Check Knowledge Freshness (Priority: P2)

**Goal**: `npx knowledge-system check` verifies all guides' freshness by comparing watched_paths against git history. Reports VERIFIED/STALE/UNKNOWN per guide.

**Independent Test**: Create a guide with watched_paths, modify one of the watched files, run check, verify the guide is reported STALE.

### Implementation for User Story 3

- [x] T019 [US3] Implement checker in `packages/knowledge-system/src/checker.js` — export async `check()` that: (1) reads all guides via guides scanner, (2) for each guide with watched_paths: run `git log -1 --format=%aI -- <path>` via `execSync` for each path, compare against last_verified date, classify as VERIFIED/STALE/UNKNOWN, (3) for each guide with references: check if referenced conventions/ADRs still exist and aren't superseded, (4) output formatted report to stdout per contracts/cli.md check output format, (5) exit code 0 if all verified/unknown, exit code 1 if any stale. Follow freshness algorithm from plan.md D3
- [x] T020 [US3] Wire `check` command in `packages/knowledge-system/bin/cli.js` — import `check` from checker.js, add to switch/case. Verify `npx knowledge-system check` outputs freshness report
- [x] T021 [US3] Update guides scanner in `packages/knowledge-system/src/scanners/guides.js` to use checker's freshness logic — import freshness checking from checker.js so that `scanGuides` can set accurate status (verified/stale/unknown) during refresh, making index.yaml status fields accurate
- [x] T022 [US3] Create `/knowledge.check` Claude Code command template in `packages/knowledge-system/templates/commands/knowledge.check.md` — prompt template that instructs Claude to run `npx knowledge-system check`, interpret the output, and suggest actions for stale guides (update guide content, re-verify watched_paths). Include handoffs to `/knowledge.refresh` and `/knowledge.create`

**Checkpoint**: `npx knowledge-system check` detects stale guides with zero false negatives.

---

## Phase 7: User Story 4 — Create a Knowledge Guide (Priority: P2)

**Goal**: `/knowledge.create` Claude Code command that creates new guides with proper frontmatter, content skeleton, and suggested watched_paths

**Independent Test**: Run `/knowledge.create "how to debug agreement drift"`, verify guide file created in `.knowledge/guides/` with proper frontmatter. Run refresh, verify guide appears in index.

### Implementation for User Story 4

- [x] T023 [US4] Create `/knowledge.create` Claude Code command template in `packages/knowledge-system/templates/commands/knowledge.create.md` — prompt template that instructs Claude to: (1) take topic from $ARGUMENTS, (2) generate slug from topic (lowercase, hyphens, no special chars), (3) check if `.knowledge/guides/<slug>.md` already exists — warn and offer edit if so, (4) read guide template from `.knowledge/` or use built-in template, (5) create guide file with frontmatter (id, title, created=today, last_verified=today, empty references and watched_paths, topics derived from topic), (6) fill content body based on topic and project context, (7) suggest relevant watched_paths based on topic and explored files, (8) remind user to run `/knowledge.refresh` to update index. Include handoff to `/knowledge.refresh`

**Checkpoint**: `/knowledge.create` produces properly structured guides that integrate with the rest of the system.

---

## Phase 8: User Story 6 — Knowledge Capture After Exploration (Priority: P3)

**Goal**: After an AI agent explores extensively to answer a question, suggest capturing the findings as a knowledge guide

**Independent Test**: Simulate an exploration session via `/k` where multiple files are read. Verify the command suggests creating a guide from findings.

### Implementation for User Story 6

- [x] T024 [US6] Enhance `/k` command template in `packages/knowledge-system/templates/commands/k.md` — add instructions at the end of the template: if the agent had to read 5+ files beyond the index to assemble the answer (indicating the knowledge was not pre-captured), suggest creating a knowledge guide with `/knowledge.create "<topic>"` and include a pre-populated summary of findings. This is purely a prompt enhancement — no code changes needed

**Checkpoint**: `/k` suggests knowledge capture when answers require extensive exploration.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Integration with tcsetup and final validation

- [x] T025 Add knowledge-system to tcsetup installer — update `packages/tcsetup/src/installer.js` to add `{ name: "Knowledge System", flag: "--skip-knowledge", cmd: "npx knowledge-system init" }` to the steps array
- [x] T026 Add knowledge-system to tcsetup updater — update `packages/tcsetup/src/updater.js` to add `{ name: "Knowledge System", marker: ".knowledge", pkg: "knowledge-system", cmd: "npx knowledge-system update" }` to the TOOLS array. Also chain refresh after update: `npx knowledge-system update && npx knowledge-system refresh`
- [x] T027 Update tcsetup help text — update `packages/tcsetup/bin/cli.js` help text to include `--skip-knowledge` flag description
- [x] T028 Run quickstart.md end-to-end validation — follow all steps in `specs/007-knowledge-system/quickstart.md`, verify init creates correct structure, refresh populates snapshot and index, check reports freshness, `/k` returns verified answers

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001) — BLOCKS all user stories
- **US5 Init (Phase 3)**: Depends on Foundational (T004-T006) + templates (T002)
- **US2 Refresh (Phase 4)**: Depends on Foundational (T004-T006) + US5 (init must exist)
- **US1 Query (Phase 5)**: Depends on US2 (index.yaml must be generatable)
- **US3 Check (Phase 6)**: Depends on Foundational (T004-T006) — parallel with US1
- **US4 Create (Phase 7)**: Depends on US5 (`.knowledge/` must exist) — parallel with US1/US3
- **US6 Capture (Phase 8)**: Depends on US1 (/k template must exist)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US5 (P1 — Init)**: Foundation story — all other stories depend on this
- **US2 (P1 — Refresh)**: Depends on US5 — produces index.yaml that US1 needs
- **US1 (P1 — Query)**: Depends on US2 — needs index.yaml to route queries
- **US3 (P2 — Check)**: Can start after Foundational — parallel with US1/US2 (checker is independent of refresh/query)
- **US4 (P2 — Create)**: Can start after US5 — parallel with US1/US2/US3
- **US6 (P3 — Capture)**: Depends on US1 — enhances /k command template

### Within Each User Story

- Scanners before orchestrators (refresher uses scanners)
- CLI wiring after module implementation
- Claude commands after CLI commands they wrap

### Parallel Opportunities

- T002 + T003 can run in parallel (templates vs CLI skeleton)
- T004 + T005 + T006 can run in parallel (independent utilities)
- T010 + T011 + T012 + T013 can run in parallel (four independent scanners)
- US3 (Check) and US4 (Create) can run in parallel after US5 completes
- T025 + T026 + T027 can run in parallel (independent tcsetup files)

---

## Parallel Example: Phase 4 (US2 — Refresh)

```bash
# Launch all four scanners in parallel (different files, no dependencies):
Task: "Implement conventions scanner in src/scanners/conventions.js"    # T010
Task: "Implement ADR scanner in src/scanners/adrs.js"                   # T011
Task: "Implement features scanner in src/scanners/features.js"          # T012
Task: "Implement guides scanner in src/scanners/guides.js"              # T013

# Then sequentially (depends on all scanners):
Task: "Create scanner index in src/scanners/index.js"                   # T014
Task: "Implement refresher in src/refresher.js"                         # T015
Task: "Wire refresh command in bin/cli.js"                              # T016
```

---

## Implementation Strategy

### MVP First (US5 + US2 + US1)

1. Complete Phase 1: Setup (package skeleton)
2. Complete Phase 2: Foundational (shared utilities)
3. Complete Phase 3: US5 — Init (`npx knowledge-system init` works)
4. Complete Phase 4: US2 — Refresh (`npx knowledge-system refresh` generates snapshot + index)
5. Complete Phase 5: US1 — Query (`/k` assembles verified answers)
6. **STOP and VALIDATE**: The core value proposition is functional

### Incremental Delivery

1. Setup + Foundational + US5 → `.knowledge/` directory scaffolded
2. Add US2 → Snapshot and index auto-generated from existing artifacts
3. Add US1 → `/k` queries return verified answers (MVP complete!)
4. Add US3 → Freshness drift detection (killer differentiator)
5. Add US4 → Guide creation (knowledge base grows)
6. Add US6 → Knowledge capture loop (organic learning)
7. Polish → tcsetup integration (ecosystem-wide availability)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All imports must use `node:` prefix (conv-001)
- Follow established kai CLI patterns (conv-002): switch/case router, same file naming

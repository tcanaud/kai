# Tasks: tcsetup update command

**Input**: Design documents from `/specs/006-tcsetup-update/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: No test framework — manual testing only (per feature specification).

**Organization**: Tasks are grouped by user story. US1 (full update), US2 (partial update), and US4 (error resilience) share the same implementation (updater.js). US3 (backward compat) and US5 (help text) share the same implementation (cli.js refactor). Tasks are consolidated accordingly.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Package configuration for npm publishing

- [x] T001 Update `packages/tcsetup/package.json` — add `"src/"` to the `"files"` array so that `src/installer.js` and `src/updater.js` are included in the published npm package. Change `"files": ["bin/", "commands/"]` to `"files": ["bin/", "src/", "commands/"]`.

---

## Phase 2: Foundational (Installer Extraction)

**Purpose**: Extract init logic from CLI entry point into a reusable module — MUST complete before CLI refactor

**⚠️ CRITICAL**: CLI refactor (Phase 3) depends on this phase

- [x] T002 Create `packages/tcsetup/src/installer.js` — move the `steps` array (lines 35-66 of current `bin/cli.js`), the sequential `execSync` loop with skip-flag handling (lines 70-89), and the Claude commands copy block (lines 92-108) into an exported `install(flags)` function. Include the version banner (`console.log` with version). Follow the export pattern from `packages/adr-system/src/installer.js`. Use `node:` protocol imports (`node:child_process`, `node:fs`, `node:path`, `node:url`).

**Checkpoint**: `src/installer.js` exports a working `install(flags)` function with identical behavior to the current flat script.

---

## Phase 3: US3 + US5 — Backward-Compatible CLI & Help Text (P1/P3)

**Goal**: Refactor `bin/cli.js` from a flat script into a command router that preserves backward compatibility (US3) and shows updated help text (US5).

**Independent Test (US3)**: Run `npx tcsetup` (no arguments) and verify the full init sequence runs identically to before.

**Independent Test (US5)**: Run `npx tcsetup help` and verify it lists `init`, `update`, and `help` subcommands.

### Implementation

- [x] T003 [US3] Refactor `packages/tcsetup/bin/cli.js` — replace the flat script with switch/case routing on `argv[2]`:
  - `import { install } from "../src/installer.js"` (from T002)
  - `import { update } from "../src/updater.js"` (stub: export a function that logs "not yet implemented" — replaced in T004)
  - `case "init":` → call `install(flags)`
  - `case "update":` → call `update(flags)`
  - `case "help":` / `case "--help":` / `case "-h":` → print HELP and exit
  - `case undefined:` → call `install(flags)` (backward compatibility — `npx tcsetup` still runs init)
  - `default:` → print error `Unknown command: ${command}` + HELP, exit(1)
  - Update HELP constant to list `init`, `update`, and `help` subcommands with descriptions
  - Keep version banner at top (`tcsetup v${version}`)
  - Follow routing structure from `packages/adr-system/bin/cli.js` (lines 30-47)

**Checkpoint**: `npx tcsetup` (no args) runs init. `npx tcsetup init` runs init. `npx tcsetup help` shows all subcommands. `npx tcsetup update` prints stub message. US3 and US5 are satisfied.

---

## Phase 4: US1 + US2 + US4 — Update Command (P1/P2) 🎯 MVP

**Goal**: Create the update orchestrator that detects installed tools (US2), updates all of them (US1), and handles errors gracefully (US4).

**Independent Test (US1)**: Run `npx tcsetup update` in a fully onboarded project — all 4 packages updated, all commands refreshed.

**Independent Test (US2)**: Run `npx tcsetup update` in a project with `--skip-adr` — only installed tools updated, no errors for absent tools.

**Independent Test (US4)**: Simulate a sub-tool failure — error logged, remaining tools still updated.

### Implementation

- [x] T004 [US1] Create `packages/tcsetup/src/updater.js` — implement the full update orchestrator as an exported `update(flags)` function with this sequence:
  1. **Define TOOLS array** — hardcoded array of `{ name, marker, pkg, cmd }` objects per data-model.md:
     - `{ name: "ADR System", marker: ".adr", pkg: "adr-system", cmd: "npx adr-system update" }`
     - `{ name: "Agreement System", marker: ".agreements", pkg: "agreement-system", cmd: "npx agreement-system update" }`
     - `{ name: "Feature Lifecycle", marker: ".features", pkg: "feature-lifecycle", cmd: "npx feature-lifecycle update" }`
     - `{ name: "Mermaid Workbench", marker: ["_bmad/modules/mermaid-workbench", ".bmad/modules/mermaid-workbench"], pkg: "mermaid-workbench", cmd: "npx mermaid-workbench init" }`
  2. **Detect installed tools** — for each tool, check `existsSync(join(projectRoot, marker))` (check any marker if array). Build `detected` list.
  3. **Handle no tools detected** — if `detected` is empty, log "No TC tools detected. Run `npx tcsetup` to onboard first." and return.
  4. **Update npm packages** — run `npm install ${detected.map(t => t.pkg + "@latest").join(" ")}` via `execSync` with `stdio: "inherit"`. Wrap in try/catch — log error and continue if fails (US4).
  5. **Call sub-tool updates** — for each detected tool, run `execSync(tool.cmd, { stdio: "inherit" })` in try/catch. Log error with tool name on failure, continue to next tool (US4).
  6. **Refresh tcsetup commands** — copy `tcsetup.onboard.md` and `feature.workflow.md` from package's `commands/` directory to project's `.claude/commands/`. Create `.claude/commands/` if it doesn't exist. Use `copyFileSync`.
  7. **Summary** — log "Done! TC tools updated." with list of tools that were updated.
  - Use `node:` protocol imports. Use `fileURLToPath` + `dirname` for `__dirname`. Use `process.cwd()` for project root.

**Checkpoint**: Full update works (US1). Partial update works — only detected tools are updated (US2). Errors are caught per step and don't cascade (US4). All 5 user stories are now satisfied.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Edge case validation and final verification

- [x] T005 Validate edge cases in `packages/tcsetup/src/updater.js`:
  - Verify no-tools-detected path logs message and exits gracefully (not an error)
  - Verify `.bmad/modules/mermaid-workbench` alternate marker is checked alongside `_bmad/modules/mermaid-workbench`
  - Verify `.claude/commands/` is created via `mkdirSync({ recursive: true })` if it doesn't exist before copying command files
  - Verify packages already at latest version cause no errors (npm install is a no-op)
- [x] T006 Run `specs/006-tcsetup-update/quickstart.md` validation — execute all manual test scenarios described in quickstart.md and verify expected outcomes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: No dependencies — can run in parallel with Phase 1
- **US3+US5 (Phase 3)**: Depends on Phase 2 (T002 must exist before T003 can import it)
- **US1+US2+US4 (Phase 4)**: Depends on Phase 3 (T003 must import updater.js, T004 replaces the stub)
- **Polish (Phase 5)**: Depends on Phase 4 completion

### User Story Dependencies

- **US3 (Backward-Compatible CLI)**: Implemented in Phase 3 (T003). No dependency on other stories.
- **US5 (Help Text)**: Implemented in Phase 3 (T003). No dependency on other stories.
- **US1 (Full Update)**: Implemented in Phase 4 (T004). Depends on US3 (CLI routing must exist).
- **US2 (Partial Update)**: Implemented in Phase 4 (T004). Same implementation as US1 — detection logic handles both.
- **US4 (Error Resilience)**: Implemented in Phase 4 (T004). Same implementation as US1 — try/catch per step.

### Within Each Phase

- Phase 1: Single task, no parallelism
- Phase 2: Single task, no parallelism
- Phase 3: Single task (depends on Phase 2)
- Phase 4: Single task (depends on Phase 3)
- Phase 5: T005 and T006 can run in parallel [P]

### Parallel Opportunities

- T001 (package.json) and T002 (installer.js) can run in parallel — different files, no dependencies
- T005 (edge case validation) and T006 (quickstart validation) can run in parallel

---

## Parallel Example: Setup + Foundational

```bash
# Launch setup and foundational in parallel (different files):
Task: "Update packages/tcsetup/package.json"
Task: "Create packages/tcsetup/src/installer.js"
```

---

## Implementation Strategy

### MVP First (Phase 1-4)

1. Complete Phase 1: package.json update (T001)
2. Complete Phase 2: Extract installer.js (T002) — can parallel with T001
3. Complete Phase 3: Refactor cli.js (T003) — US3+US5 verified
4. Complete Phase 4: Create updater.js (T004) — US1+US2+US4 verified
5. **STOP and VALIDATE**: Test all 5 user stories via quickstart.md scenarios
6. Ready for npm publish

### Incremental Delivery

1. T001 + T002 → Installer extracted, package ready
2. T003 → CLI refactored — backward compat preserved (US3), help works (US5)
3. T004 → Update command functional — full update (US1), partial update (US2), error resilience (US4)
4. T005 + T006 → Edge cases validated, quickstart confirmed

---

## Notes

- All implementation is in `packages/tcsetup/` — only 3 files modified/created + 1 config update
- No test framework — validation is manual via `npx` in a target project
- US2 (partial update) and US4 (error resilience) are intrinsic to the updater.js design, not separate features
- The `case undefined:` → `install(flags)` pattern is the key to backward compatibility (US3)
- mermaid-workbench has dual marker paths — both must be checked

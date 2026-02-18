---
title: 'tcsetup update command'
slug: 'tcsetup-update'
created: '2026-02-18'
status: 'ready-for-dev'
stepsCompleted: [1, 2, 3, 4]
tech_stack:
  - 'Node.js ESM (type: module)'
  - 'Zero runtime dependencies (conv-001)'
  - 'execSync orchestration'
  - 'node: protocol imports'
files_to_modify:
  - 'packages/tcsetup/bin/cli.js'
  - 'packages/tcsetup/src/updater.js'
  - 'packages/tcsetup/package.json'
code_patterns:
  - 'ESM-only with node: protocol imports (import { x } from "node:fs")'
  - 'CLI routing via switch(command) on argv[2] — same as adr-system, agreement-system, etc.'
  - 'Sequential execSync orchestration with try/catch per step'
  - 'Sub-tool detection via marker directory existence (existsSync)'
  - 'Safe update: refresh commands/templates only, never touch user data/configs/indexes'
test_patterns:
  - 'No test framework — manual testing via npx in a target project'
---

# Tech-Spec: tcsetup update command

**Created:** 2026-02-18

## Overview

### Problem Statement

When TC stack packages evolve (new scripts, updated commands, fixes), already-onboarded projects have no simple way to update. Users must manually re-run individual tool commands or copy files — there is no single orchestrated update path.

### Solution

Add an `npx tcsetup update` command that: (1) updates all TC stack npm packages to their latest versions, (2) detects which tools are installed in the current project, (3) calls each detected tool's `update` subcommand to refresh commands/templates, and (4) updates tcsetup's own command files. Formalize the "safe update" convention across sub-tools via an ADR.

### Scope

**In Scope:**
- New `update` subcommand in tcsetup CLI (`npx tcsetup update`)
- Detection of installed tools in the current project (by checking for their marker directories)
- Orchestrated sequence: npm package update → sub-tool update calls
- Safe update only — refresh commands/templates, never touch user data
- ADR to formalize the "safe update" convention across all sub-tools

**Out of Scope:**
- Destructive migrations / transformation of existing user data
- Selective per-tool update (`--only <tool>`)
- Automatic breaking change migration scripts
- BMAD (`bmad-method`) and Spec Kit (`specify`) — external tools, excluded from update scope

## Context for Development

### Codebase Patterns

- **Orchestrator pattern:** tcsetup delegates to sub-tools via `execSync`. The existing `bin/cli.js` runs a sequential `steps` array. The update command should follow the same pattern.
- **CLI routing:** All other TC packages use a `switch(command)` on `argv[2]` with cases for `init`, `update`, `help`. tcsetup currently has NO routing — everything runs on default. Must be refactored.
- **Sub-tool update contract:** 3 of 4 tools have an `update` subcommand (adr-system, agreement-system, feature-lifecycle). mermaid-workbench has no `update` but its `init` is idempotent and safe to re-run.
- **Tool detection markers:**
  - `.adr/` → adr-system installed
  - `.agreements/` → agreement-system installed
  - `.features/` → feature-lifecycle installed
  - `_bmad/modules/mermaid-workbench/` or `.bmad/modules/mermaid-workbench/` → mermaid-workbench installed
- **Zero deps:** All CLIs use only Node.js built-ins — no external dependencies allowed (conv-001).
- **tcsetup own files:** tcsetup copies 2 command files to `.claude/commands/`: `tcsetup.onboard.md` and `feature.workflow.md`.

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `packages/tcsetup/bin/cli.js` | CLI entry point — needs command routing refactor + update delegation |
| `packages/tcsetup/package.json` | Needs `"src/"` added to `files` array for npm publishing |
| `packages/tcsetup/commands/` | tcsetup's own 2 command files to refresh during update |
| `packages/adr-system/bin/cli.js` | Reference: CLI routing pattern (switch/case) |
| `packages/adr-system/src/updater.js` | Reference: update implementation (commands + templates) |
| `packages/agreement-system/src/updater.js` | Reference: update with BMAD marker-based section replacement |
| `packages/feature-lifecycle/src/updater.js` | Reference: update with BMAD integration |
| `packages/mermaid-workbench/src/installer.js` | Reference: idempotent init (safe for re-run as update) |

### Technical Decisions

1. **Exclude BMAD & SpecKit from update** — They are external tools with their own install lifecycles, not TC stack packages.
2. **mermaid-workbench: use `init` as update** — No `update` subcommand exists, but `init` is idempotent and safe.
3. **npm update strategy** — Run `npm install <pkg>@latest` for all 4 TC stack packages before calling sub-tool updates.
4. **Detection-based update** — Only call update for tools whose marker directory exists in the project.
5. **Safe update convention** — Sub-tools refresh only generated/template files, never touch user data. Formalize via ADR.
6. **CLI refactor** — Restructure `bin/cli.js` to use switch/case routing (matching pattern from other TC packages) and extract install logic to `src/installer.js`.

## Implementation Plan

### Tasks

- [ ] Task 1: Refactor `bin/cli.js` to add command routing
  - File: `packages/tcsetup/bin/cli.js`
  - Action: Restructure the flat script into a switch/case on `argv[2]`. Move the current init logic into a function or import from `src/installer.js`. Add cases for `update`, `help`, and default (show help). Keep the existing init behavior identical — this is a pure refactor.
  - Pattern: Follow `packages/adr-system/bin/cli.js` routing structure.
  - Notes: The `help` text must be updated to document the new `update` subcommand. The default case (no command) should run `init` for backward compatibility (`npx tcsetup` still works as before).

- [ ] Task 2: Extract install logic to `src/installer.js`
  - File: `packages/tcsetup/src/installer.js` (NEW)
  - Action: Move the steps array, the sequential execSync loop, and the Claude commands copy logic from `bin/cli.js` into an exported `install(flags)` function. `bin/cli.js` then imports and calls `install(flags)`.
  - Pattern: Follow `packages/adr-system/src/installer.js` export pattern (`export function install(flags = [])`).
  - Notes: The `--skip-*` flag handling stays in this function. The version banner and help text stay in `bin/cli.js`.

- [ ] Task 3: Create `src/updater.js` with update orchestration
  - File: `packages/tcsetup/src/updater.js` (NEW)
  - Action: Create the update orchestrator with this sequence:
    1. **Detect installed tools** — Check marker directories to build list of installed tools
    2. **Update npm packages** — Run `npm install adr-system@latest agreement-system@latest feature-lifecycle@latest mermaid-workbench@latest` (only for detected tools)
    3. **Call sub-tool updates** — For each detected tool, run its update command:
       - adr-system → `npx adr-system update`
       - agreement-system → `npx agreement-system update`
       - feature-lifecycle → `npx feature-lifecycle update`
       - mermaid-workbench → `npx mermaid-workbench init` (idempotent, no update subcommand)
    4. **Update tcsetup's own commands** — Copy `tcsetup.onboard.md` and `feature.workflow.md` to `.claude/commands/`
  - Pattern: Export `update(flags)` function. Use `existsSync` for detection, `execSync` with `stdio: "inherit"` for sub-tool calls, `copyFileSync` for own commands. Try/catch per step with continue-on-error.
  - Notes: Detection map:
    ```
    { name: "ADR System",          marker: ".adr",                                    pkg: "adr-system",         cmd: "npx adr-system update" }
    { name: "Agreement System",    marker: ".agreements",                             pkg: "agreement-system",   cmd: "npx agreement-system update" }
    { name: "Feature Lifecycle",   marker: ".features",                               pkg: "feature-lifecycle",  cmd: "npx feature-lifecycle update" }
    { name: "Mermaid Workbench",   marker: "_bmad/modules/mermaid-workbench",         pkg: "mermaid-workbench",  cmd: "npx mermaid-workbench init" }
    ```
    For mermaid-workbench, also check `.bmad/modules/mermaid-workbench` as alternate marker.

- [ ] Task 4: Update `package.json` to include `src/` in published files
  - File: `packages/tcsetup/package.json`
  - Action: Add `"src/"` to the `"files"` array so that `src/installer.js` and `src/updater.js` are included in the npm package.
  - Current: `"files": ["bin/", "commands/"]`
  - Target: `"files": ["bin/", "src/", "commands/"]`

### Acceptance Criteria

- [ ] AC 1: Given a project onboarded with all TC tools, when running `npx tcsetup update`, then all 4 packages are updated to latest versions and all sub-tool update commands execute successfully.
- [ ] AC 2: Given a project where some tools were skipped during init (e.g., `--skip-adr`), when running `npx tcsetup update`, then only tools with existing marker directories are updated (`.adr/` absent → adr-system skipped).
- [ ] AC 3: Given a project onboarded with tcsetup, when running `npx tcsetup update`, then `.claude/commands/tcsetup.onboard.md` and `.claude/commands/feature.workflow.md` are refreshed from the package's `commands/` directory.
- [ ] AC 4: Given backward compatibility, when running `npx tcsetup` (no subcommand), then the existing init behavior is preserved unchanged.
- [ ] AC 5: Given a sub-tool update failure (e.g., network error during npm install), when running `npx tcsetup update`, then the error is logged and remaining tools continue to update.
- [ ] AC 6: Given the update command, when running `npx tcsetup help`, then the help text shows both `init` and `update` subcommands with descriptions.

## Additional Context

### Dependencies

- All 4 sub-tools must maintain their existing `update` (or idempotent `init`) subcommand contract
- npm registry must be reachable for package updates
- No new runtime dependencies — Node.js built-ins only

### Testing Strategy

- **Manual test — full update:** Run `npx tcsetup update` in a fully onboarded project, verify all packages updated and commands refreshed
- **Manual test — partial install:** Run in a project with `--skip-adr --skip-mermaid`, verify only agreement-system and feature-lifecycle are updated
- **Manual test — backward compat:** Run `npx tcsetup` (no args) and verify it still runs the full init sequence
- **Manual test — error resilience:** Disconnect network mid-update, verify error is logged and process continues

### Notes

- mermaid-workbench should eventually get its own `update` subcommand to align with the other tools. This is out of scope for this feature but worth tracking.
- The ADR for safe update convention is a separate deliverable that should be created via `/adr.create` after the implementation is complete.

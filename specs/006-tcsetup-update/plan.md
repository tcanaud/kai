# Implementation Plan: tcsetup update command

**Branch**: `006-tcsetup-update` | **Date**: 2026-02-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-tcsetup-update/spec.md`

## Summary

Add an `npx tcsetup update` command that orchestrates TC stack updates for already-onboarded projects. The CLI entry point (`bin/cli.js`) is refactored from a flat script into a switch/case router (matching the pattern used by adr-system, agreement-system, etc.). The existing init logic moves to `src/installer.js`, and a new `src/updater.js` handles the update sequence: detect installed tools via marker directories, update npm packages, call each sub-tool's update command, and refresh tcsetup's own command files.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports)
**Storage**: N/A — filesystem only (marker directory detection via `existsSync`, file copy via `copyFileSync`)
**Testing**: Manual testing via `npx` in a target project (no test framework in this package)
**Target Platform**: Any OS with Node.js >= 18 (npm CLI tool)
**Project Type**: Single package within a monorepo (`packages/tcsetup/`)
**Performance Goals**: N/A — one-time CLI command, no performance-sensitive paths
**Constraints**: Zero runtime dependencies (conv-001); safe update only (never touch user data)
**Scale/Scope**: 3 files modified/created (`bin/cli.js`, `src/installer.js`, `src/updater.js`), 1 file updated (`package.json`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is template-only (not yet customized for this project). No gates to enforce. PASS.

**Post-Phase 1 re-check**: PASS — design follows existing patterns, no new dependencies, no architectural violations.

## Project Structure

### Documentation (this feature)

```text
specs/006-tcsetup-update/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A — no API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
packages/tcsetup/
├── bin/
│   └── cli.js           # CLI entry point — refactored to switch/case routing
├── src/
│   ├── installer.js     # NEW — extracted init/install logic
│   └── updater.js       # NEW — update orchestration logic
├── commands/
│   ├── tcsetup.onboard.md
│   └── feature.workflow.md
└── package.json         # Updated: add "src/" to "files" array
```

**Structure Decision**: Follows the established pattern from `packages/adr-system/` — CLI entry point in `bin/cli.js` with switch/case routing, logic modules in `src/` (`installer.js`, `updater.js`). This matches the architecture of all other TC stack packages.

## Complexity Tracking

No constitution violations — no entries needed.

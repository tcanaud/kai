# Implementation Plan: CLI Atomique @tcanaud/kai-product Pour Opérations Produit

**Branch**: `018-cli-kai-product` | **Date**: 2026-02-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/018-cli-kai-product/spec.md`

## Summary

Create a zero-dependency Node.js ESM CLI package `@tcanaud/kai-product` (published as `@tcanaud/kai-product`) that exposes five atomic subcommands (`move`, `promote`, `triage`, `reindex`, `check`) to replace the current 5-10-tool-call manual product operations with single CLI invocations. The package follows the established `@tcanaud/playbook` pattern: regex-based YAML frontmatter parsing with no runtime dependencies, file-based state in `.product/`, and `init`/`update` commands for setup.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports)
**Storage**: File-based — `.product/` directory tree with YAML frontmatter + Markdown body files; `index.yaml` as computed summary
**Testing**: Node.js built-in `node:test` (native test runner, Node >= 18)
**Target Platform**: macOS / Linux CLI (npx invocation or global install)
**Project Type**: Single package (CLI tool)
**Performance Goals**: Bulk move of 10 items < 5 seconds (SC-002); any single operation < 1 second
**Constraints**: Zero runtime npm dependencies; must not require internet access; must operate correctly when invoked from any working directory
**Scale/Scope**: Handles `.product/` directories with up to ~1000 feedback + backlog files; single-user sequential access

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution template in `.specify/memory/constitution.md` is a placeholder (not project-specific). Based on the established kai project conventions from `CLAUDE.md` and the existing `@tcanaud/playbook` package:

| Gate | Status | Notes |
|------|--------|-------|
| Zero runtime dependencies | PASS | FR-013 mandates Node.js built-ins only; matches `@tcanaud/playbook` pattern |
| ESM-only (`"type": "module"`) | PASS | Established convention across all kai packages |
| Node >= 18.0.0 | PASS | Established minimum version |
| File-based state (no database) | PASS | FR-005/FR-008 operate on `.product/` filesystem |
| Fail-fast input validation | PASS | FR-007 requires validation before any filesystem changes |
| All-or-nothing bulk semantics | PASS | FR-009 mandates validate-all-before-move-any |
| Exit codes (0/non-zero) | PASS | FR-010 required |
| Machine-readable output (`--json`) | PASS | FR-011 for `check` command |

No violations. Complexity tracking section not needed.

## Project Structure

### Documentation (this feature)

```text
specs/018-cli-kai-product/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── cli-interface.md
│   └── file-schemas.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
packages/kai-product/
├── package.json
├── bin/
│   └── cli.js                  # Entry point: argv routing to subcommands
├── src/
│   ├── yaml-parser.js          # Regex-based YAML frontmatter parser (no deps)
│   ├── scanner.js              # .product/ directory scanner, file discovery
│   ├── index-writer.js         # index.yaml generation from scanned data
│   ├── commands/
│   │   ├── reindex.js          # reindex subcommand implementation
│   │   ├── move.js             # move subcommand implementation
│   │   ├── check.js            # check subcommand implementation
│   │   ├── promote.js          # promote subcommand implementation
│   │   └── triage.js           # triage subcommand implementation
│   ├── installer.js            # init command: scaffold .product/ + slash commands
│   └── updater.js              # update command: refresh slash commands
└── tests/
    ├── unit/
    │   ├── yaml-parser.test.js
    │   ├── scanner.test.js
    │   └── index-writer.test.js
    └── integration/
        ├── reindex.test.js
        ├── move.test.js
        ├── check.test.js
        ├── promote.test.js
        └── triage.test.js
```

**Structure Decision**: Single package structure following the `@tcanaud/playbook` pattern exactly. One `bin/cli.js` router, subcommand modules in `src/commands/`, shared utilities (`yaml-parser.js`, `scanner.js`, `index-writer.js`) at the `src/` root. Tests use Node.js native test runner (no testing framework dependency).

## Complexity Tracking

> No constitution violations detected. Section left empty per instructions.

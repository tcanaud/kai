# Implementation Plan: Playbook CLI Commands (Status & List)

**Branch**: `015-playbook-cli-commands` | **Date**: 2026-02-19 | **Spec**: [specs/015-playbook-cli-commands/spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-playbook-cli-commands/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add two new CLI commands to the @tcanaud/playbook package: `npx @tcanaud/playbook status` displays currently running playbook sessions with session ID, creation time, and status; `npx @tcanaud/playbook list` displays all sessions (running and completed). Both commands support JSON output and human-readable terminal formatting, enabling real-time visibility for session management and programmatic access for automation systems.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None (zero runtime dependencies — Node.js built-ins only via `node:` protocol imports)
**Storage**: File-based — `.playbooks/sessions/` directory structure with `session.yaml` and `journal.yaml` per session
**Testing**: Node.js test runner or custom test scripts (existing pattern)
**Target Platform**: Any OS supporting Node.js >= 18.0.0 (CLI tool)
**Project Type**: Single — npm package (`@tcanaud/playbook`) with CLI entry point
**Performance Goals**: Both commands execute and complete in under 1 second regardless of session count (up to 100 sessions)
**Constraints**: No horizontal scrolling required for 80+ character terminal width; no runtime dependencies beyond Node.js built-ins
**Scale/Scope**: Support for up to 100 playbook sessions in a single `.playbooks/sessions/` directory

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Principle: Library-First** ✓
- The feature extends the existing @tcanaud/playbook library (npm package)
- The library is self-contained and independently testable
- Clear purpose: enabling session visibility and automation integration

**Principle: CLI Interface** ✓
- Both commands expose functionality via CLI: `npx @tcanaud/playbook status` and `npx @tcanaud/playbook list`
- Text protocol: stdin/args → stdout (JSON or human-readable), errors → stderr
- Support for JSON + human-readable formats (both commands have `--json` flag)

**Principle: Zero Runtime Dependencies** ✓
- The implementation uses only Node.js built-ins (`node:fs`, `node:path`)
- No external npm dependencies required
- Consistent with existing @tcanaud/playbook design (confirmed in CLAUDE.md)

**Technology Compliance** ✓
- Uses Node.js ESM (`"type": "module"`) matching existing package.json
- Minimum Node version >= 18.0.0 (matching package.json constraint)
- File-based storage (session.yaml + journal.yaml) already implemented in session.js

**GATE STATUS**: PASS ✓

## Project Structure

### Documentation (this feature)

```text
specs/015-playbook-cli-commands/
├── spec.md              # Feature specification
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (research findings and decisions)
├── data-model.md        # Phase 1 output (entities and schema)
├── quickstart.md        # Phase 1 output (getting started guide)
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (package structure)

```text
packages/playbook/
├── bin/
│   └── cli.js           # Main CLI entry point (MODIFIED: add status and list commands)
├── src/
│   ├── detect.js        # Existing: session detection utilities
│   ├── installer.js     # Existing: init command
│   ├── updater.js       # Existing: update command
│   ├── session.js       # Existing: session I/O and discovery (REUSED for listing)
│   ├── validator.js     # Existing: check command
│   ├── yaml-parser.js   # Existing: YAML parsing
│   ├── worktree.js      # Existing: start command
│   ├── list.js          # NEW: list command implementation
│   └── status.js        # NEW: status command implementation
└── tests/
    ├── status.test.js   # NEW: status command tests
    └── list.test.js     # NEW: list command tests
```

**Structure Decision**: This feature extends the existing @tcanaud/playbook npm package (single project). Two new command implementations (`status.js` and `list.js`) are added to `src/`, and the CLI entry point (`bin/cli.js`) is modified to wire these commands. Both new commands reuse the session discovery and parsing utilities already in `session.js`. Test files follow the existing pattern in `tests/`.

## Complexity Tracking

> **No violations detected.** Constitution Check passed without justification requirements.

All constraints are satisfied without additional complexity:
- Uses zero runtime dependencies (Node.js built-ins only)
- Extends existing single package (@tcanaud/playbook)
- Reuses existing session.js utilities for discovery and parsing
- No new dependencies or architectural changes required
- Aligns with existing CLI pattern (init, update, start, check commands)

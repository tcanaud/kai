# Implementation Plan: Playbook Step Model Selection

**Branch**: `014-playbook-step-model` | **Date**: 2026-02-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/014-playbook-step-model/spec.md`

## Summary

Add an optional `model` property to playbook step definitions that specifies which AI model tier (opus, sonnet, haiku) to use when the supervisor delegates step execution. The YAML parser must accept the new field, the validator must enforce allowed values, and the supervisor prompt must pass the model to the Task subagent. Existing playbooks without `model` fields continue to work unchanged.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None -- zero runtime dependencies (`node:` protocol imports only)
**Storage**: File-based -- `.playbooks/playbooks/*.yaml` (playbook definitions), `.playbooks/sessions/` (session state)
**Testing**: Node.js built-in test runner (`node:test` + `node:assert/strict`)
**Target Platform**: CLI tool (`@tcanaud/playbook` npm package) + Claude Code slash commands
**Project Type**: Single project (monorepo package at `packages/playbook/`)
**Performance Goals**: N/A -- parse/validate individual YAML files, sub-second operations
**Constraints**: Zero runtime dependencies; no YAML library (custom regex-based parser)
**Scale/Scope**: ~3 files to modify in `packages/playbook/src/`, 1 slash command prompt to update, 1 template to update

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution file (`.specify/memory/constitution.md`) is a template with no project-specific rules filled in. All section headings contain placeholder text (`[PRINCIPLE_1_NAME]`, `[GOVERNANCE_RULES]`, etc.). No concrete gates or constraints are defined.

**Pre-Phase 0 verdict**: PASS -- no constitution violations possible (no rules defined).

**Post-Phase 1 verdict**: PASS -- design adds a single optional field to an existing schema, modifies existing source files, and introduces no new dependencies or architectural patterns.

## Project Structure

### Documentation (this feature)

```text
specs/014-playbook-step-model/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── playbook-schema.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
packages/playbook/
├── src/
│   ├── yaml-parser.js   # Add "model" to step field parsing + ALLOWED_MODELS set
│   └── validator.js     # Add MODEL_VALUES constant + per-step model validation
├── templates/
│   └── playbook.tpl.yaml  # (at .playbooks/playbooks/playbook.tpl.yaml) Document model field
└── tests/
    └── yaml-parser.test.js  # Add model field happy-path + validation error tests

.claude/commands/
├── playbook.run.md      # Update supervisor prompt: pass model to Task subagent
└── playbook.resume.md   # Same model-passing logic applies on resume
```

**Structure Decision**: Single package (`packages/playbook/`). All changes are modifications to existing files. No new source files or directories are introduced.

## Complexity Tracking

> No constitution violations to justify. The feature adds one optional field to an existing schema.

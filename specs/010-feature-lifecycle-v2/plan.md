# Implementation Plan: Feature Lifecycle V2

**Branch**: `010-feature-lifecycle-v2` | **Date**: 2026-02-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/010-feature-lifecycle-v2/spec.md`

## Summary

Extend the kai feature governance workflow from implementation through release. Add QA integration to the workflow dashboard (Gate C/D evaluation), a new `/feature.pr` command for traceable GitHub PR creation via `gh` CLI, post-merge lifecycle resolution that closes the governance chain (feature to release, backlogs to done, feedbacks to resolved), and a QA FAIL recovery loop that bridges the QA and product-manager systems. All changes follow the established slash-command-as-template pattern with zero runtime dependencies.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports). External tool dependency: GitHub CLI (`gh`) for PR creation and merge detection.
**Storage**: File-based — YAML + Markdown in `.features/`, `.qa/`, `.product/`, `.agreements/`, `specs/` directories
**Testing**: QA system (`/qa.plan` + `/qa.run`) — script-based acceptance testing with exit-code semantics
**Target Platform**: macOS/Linux developer workstations with Claude Code installed
**Project Type**: Monorepo workspace package (`packages/feature-lifecycle/`) + Claude Code slash command templates
**Performance Goals**: N/A — developer-interactive tool, no performance targets
**Constraints**: Zero external npm dependencies; all state via filesystem; git-native (every change is a diff)
**Scale/Scope**: 10-20 features tracked simultaneously; single developer workflow

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution (`.specify/memory/constitution.md`) is a template with no filled-in principles. No constitution gates to evaluate.

**Pre-Phase 0 verdict**: PASS (no constraints defined)

## Project Structure

### Documentation (this feature)

```text
specs/010-feature-lifecycle-v2/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── feature.workflow-v2.md
│   ├── feature.pr.md
│   └── feature.resolve.md
└── tasks.md             # Phase 2 output (by /speckit.tasks)
```

### Source Code (repository root)

```text
packages/feature-lifecycle/
├── bin/cli.js                          # Existing entry point (no changes)
├── src/
│   ├── installer.js                    # Update: install new commands
│   ├── updater.js                      # Update: update new commands
│   ├── detect.js                       # Update: detect .qa/ and .product/
│   ├── feature-io.js                   # Update: add QA artifact fields to YAML schema
│   ├── stage-engine.js                 # Existing (no changes needed)
│   ├── health-engine.js                # Existing (no changes needed)
│   ├── scanners/
│   │   ├── qa-scanner.js              # NEW: scan .qa/{feature}/ for verdict
│   │   └── (existing scanners)
│   └── pr/
│       ├── prerequisite-check.js      # NEW: gate enforcement for PR creation
│       ├── body-builder.js            # NEW: assemble PR body with traceability
│       └── resolve.js                 # NEW: post-merge state transitions
├── templates/
│   └── commands/
│       ├── feature.workflow.md         # UPDATE: extended with QA/PR/resolve steps
│       ├── feature.pr.md              # NEW: PR creation command
│       ├── feature.resolve.md         # NEW: post-merge resolution command
│       ├── feature.status.md          # Existing (no changes)
│       ├── feature.list.md            # Existing (no changes)
│       ├── feature.discover.md        # Existing (no changes)
│       └── feature.graph.md           # Existing (no changes)
└── package.json                        # Bump version
```

**Structure Decision**: Extends the existing `packages/feature-lifecycle/` workspace package. New capabilities are added as slash command templates (following established pattern) with minimal supporting JavaScript modules for shared logic (PR body assembly, prerequisite checking, state transitions). The feature-lifecycle package is the natural home since it already owns the workflow dashboard and feature state management.

## Complexity Tracking

No constitution violations to justify.

# Implementation Plan: Fix tcsetup Update Configuration Merging

**Branch**: `016-fix-tcsetup-update` | **Date**: 2026-02-19 | **Spec**: `/specs/016-fix-tcsetup-update/spec.md`
**Input**: Feature specification from `/specs/016-fix-tcsetup-update/spec.md`

**Note**: This plan is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The `npx tcsetup update` command currently appends configuration data blindly to YAML customize files (core-bmad-master.customize.yaml, bmm-pm.customize.yaml) instead of intelligently merging. This causes duplicate configuration sections when updates are run multiple times, corrupting files. The fix requires implementing proper YAML merging logic with deduplication for arrays and intelligent handling of object merging. This affects multiple sub-tools (agreement-system, feature-lifecycle) that update BMAD agent configuration files.

## Technical Context

**Language/Version**: Node.js >= 18.0.0 (ESM)
**Primary Dependencies**: Zero runtime dependencies (uses only Node.js built-ins: `fs`, `path`, `url`)
**Storage**: File-based (YAML files in `_bmad/_config/agents/` or `.bmad/_config/agents/`)
**Testing**: Built-in Node.js test runner or equivalent (node:test)
**Target Platform**: Any platform where Node.js >=18.0.0 runs (Linux, macOS, Windows)
**Project Type**: Single package (`packages/tcsetup/`)
**Performance Goals**: YAML merging operations should complete in <100ms per file
**Constraints**: Must handle various edge cases gracefully (invalid YAML, missing files, empty files)
**Scale/Scope**: Handles up to 10+ configuration files per project; customize.yaml files typically 50-500 lines

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution file template is placeholder-only (`.specify/memory/constitution.md`). No actual project constitution exists yet. This feature should proceed without constitution constraints.

## Project Structure

### Documentation (this feature)

```text
specs/016-fix-tcsetup-update/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
packages/tcsetup/
├── bin/
│   └── cli.js           # CLI entry point
├── src/
│   ├── installer.js     # Installation flow
│   └── updater.js       # Update flow (NEEDS MODIFICATION)
├── commands/
│   └── tcsetup.onboard.md
├── package.json
└── README.md
```

**New files to create:**
- `packages/tcsetup/src/yaml-merge.js` - YAML merging utility module
- `packages/tcsetup/tests/yaml-merge.test.js` - Unit tests for merging logic
- `packages/tcsetup/tests/integration.test.js` - Integration tests with sample customize.yaml files

**Structure Decision**: Single package modification. Introducing a new `yaml-merge.js` module that handles intelligent YAML merging with deduplication. The `updater.js` will be modified to use this module instead of simple text appending. Tests use Node.js built-in test runner.

---

## Execution Summary

### Phase 0: Complete ✓

**Generated artifacts**:
- `/specs/016-fix-tcsetup-update/research.md` - All unknowns resolved; technical approach established
  - Root cause analysis (appendable YAML handling)
  - Customize.yaml structure documented
  - Merge strategy decided (deep equality for arrays, recursive merge for objects)
  - Edge cases and handling specified
  - Testing strategy outlined

### Phase 1: Complete ✓

**Generated artifacts**:
- `/specs/016-fix-tcsetup-update/data-model.md` - Complete data model and merge algorithm
  - Core entities: YAMLConfiguration, Section, Marker, MergeResult, MergeChangelog
  - Merge algorithms for arrays (with deduplication) and objects (recursive merge)
  - State transitions and validation rules
  - API contracts (mergeYAML, arrays, objects, deepEqual, etc.)
  - Usage examples

- `/specs/016-fix-tcsetup-update/contracts/yaml-merge-api.md` - Full API specification
  - Function signatures for mergeYAML and helpers
  - Parameter and return type definitions
  - Invariants and performance requirements
  - Integration points with existing tools
  - Testing requirements

- `/specs/016-fix-tcsetup-update/quickstart.md` - Implementation guide
  - Problem explanation and solution overview
  - File locations (new and modified)
  - Step-by-step implementation instructions
  - Example usage (before/after)
  - Testing procedures
  - Common pitfalls

### Phase 2: Ready for Implementation

Phase 2 will use `/speckit.tasks` command to generate specific implementation tasks based on this design.

---

## Next Steps

1. Review and approve the three design documents (research, data-model, contracts)
2. Use `/speckit.tasks` to generate Phase 2 implementation tasks
3. Implement `packages/tcsetup/src/yaml-merge.js` with full test coverage
4. Modify updater files in agreement-system and feature-lifecycle
5. Run integration tests to verify all success criteria (SC-001 through SC-004)

## Complexity Tracking

No constitution violations. No complexity justification needed.

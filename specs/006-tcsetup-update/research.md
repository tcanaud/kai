# Research: tcsetup update command

**Feature**: 006-tcsetup-update | **Date**: 2026-02-18

## R1: CLI Routing Pattern

**Decision**: Use `switch(command)` on `argv[2]` with cases for `init`, `update`, `help`, and `default`.

**Rationale**: All other TC stack packages (adr-system, agreement-system, feature-lifecycle) use this exact pattern. Consistency across the toolchain makes maintenance easier and reduces cognitive load.

**Alternatives considered**:
- Commander.js or yargs: Rejected — violates zero-dependency constraint (conv-001).
- Subcommand via separate bin entries: Rejected — adds npm complexity, breaks `npx tcsetup` backward compatibility.

**Reference**: `packages/adr-system/bin/cli.js` lines 30-47 — canonical switch/case implementation.

## R2: Installer Extraction Pattern

**Decision**: Extract current init logic from `bin/cli.js` into `src/installer.js` as an `export function install(flags = [])`.

**Rationale**: Matches the pattern in `packages/adr-system/src/installer.js`. Separating CLI routing from business logic keeps `bin/cli.js` focused on argument parsing and dispatch.

**Alternatives considered**:
- Keep everything in `bin/cli.js` with functions: Rejected — deviates from established package structure, harder to test individual modules.
- Dynamic import: Rejected — unnecessary complexity for a simple function export.

**Reference**: `packages/adr-system/src/installer.js` — exports `install(flags)`.

## R3: Sub-Tool Detection Strategy

**Decision**: Use `existsSync` to check for marker directories. Build a detection map (array of objects) with `name`, `marker`, `pkg`, and `cmd` fields.

**Rationale**: Marker directories are already the established convention. Each TC tool creates its marker on init. Detection is fast, reliable, and requires no configuration.

**Detection map**:
| Tool | Marker | Package | Update Command |
|------|--------|---------|----------------|
| ADR System | `.adr` | `adr-system` | `npx adr-system update` |
| Agreement System | `.agreements` | `agreement-system` | `npx agreement-system update` |
| Feature Lifecycle | `.features` | `feature-lifecycle` | `npx feature-lifecycle update` |
| Mermaid Workbench | `_bmad/modules/mermaid-workbench` OR `.bmad/modules/mermaid-workbench` | `mermaid-workbench` | `npx mermaid-workbench init` |

**Alternatives considered**:
- Read package.json dependencies: Rejected — packages might be installed globally or via npx without being in dependencies.
- Config file listing installed tools: Rejected — adds state management, marker detection is simpler and already proven.

## R4: npm Update Strategy

**Decision**: Run `npm install <pkg>@latest` for each detected tool's package. Execute as a single command with all detected packages to minimize npm overhead.

**Rationale**: `npm install <pkg>@latest` updates or installs the package to the latest version. Grouping all packages in one command is faster than individual installs.

**Alternatives considered**:
- `npm update`: Rejected — only updates within semver range of existing entry, does not jump to latest major.
- `npm install` without `@latest`: Rejected — may not update if version already satisfies semver range.

## R5: Error Handling Strategy

**Decision**: Use try/catch per step with continue-on-error. Log errors with the tool name and continue to the next tool.

**Rationale**: Matches the existing pattern in `bin/cli.js` (lines 83-89). Users expect partial success — a network failure for one package should not block updating others.

**Alternatives considered**:
- Fail-fast (exit on first error): Rejected — too brittle for a multi-tool orchestrator.
- Collect errors and report at end: Considered but unnecessary complexity — logging immediately is sufficient.

## R6: Default Command Behavior

**Decision**: When no subcommand is provided (`argv[2]` is `undefined`), run the `init` sequence for backward compatibility.

**Rationale**: Existing documentation and muscle memory depend on `npx tcsetup` running init. The `default` case in the switch handles this.

**Alternatives considered**:
- Show help on empty command: Rejected — breaks backward compatibility for existing users.
- Require explicit `init` subcommand: Rejected — same reason.

**Reference**: `packages/adr-system/bin/cli.js` line 40 — `case undefined:` shows help, but tcsetup should run init for backward compat.

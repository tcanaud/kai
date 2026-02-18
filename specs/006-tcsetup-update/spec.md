# Feature Specification: tcsetup update command

**Feature Branch**: `006-tcsetup-update`
**Created**: 2026-02-18
**Status**: Draft
**Input**: User description: "Add an `npx tcsetup update` command that updates all TC stack packages and refreshes sub-tool commands/templates for already-onboarded projects"

## User Scenarios & Testing

### User Story 1 - Full Update of All TC Tools (Priority: P1)

A developer working on a project that was onboarded with the full TC stack (all tools installed) wants to get the latest versions of all packages and refresh all command files and templates. They run `npx tcsetup update` and all four TC stack packages are updated to their latest versions, each sub-tool's commands and templates are refreshed, and tcsetup's own command files are updated in the project.

**Why this priority**: This is the primary use case — most users will have all tools installed and need a single command to bring everything up to date. Without this, users must manually update each package and tool individually.

**Independent Test**: Can be fully tested by running `npx tcsetup update` in a fully onboarded project and verifying that all packages are updated and all command/template files are refreshed.

**Acceptance Scenarios**:

1. **Given** a project onboarded with all TC tools, **When** the user runs `npx tcsetup update`, **Then** all four TC stack packages (adr-system, agreement-system, feature-lifecycle, mermaid-workbench) are updated to their latest versions.
2. **Given** a project onboarded with all TC tools, **When** the user runs `npx tcsetup update`, **Then** each detected sub-tool's update command is executed (or idempotent init for mermaid-workbench), refreshing commands and templates.
3. **Given** a project onboarded with all TC tools, **When** the user runs `npx tcsetup update`, **Then** tcsetup's own command files (`tcsetup.onboard.md` and `feature.workflow.md`) are refreshed in `.claude/commands/`.

---

### User Story 2 - Partial Update (Selective Tools Installed) (Priority: P1)

A developer working on a project where only some TC tools were installed during onboarding (e.g., `--skip-adr` was used) runs `npx tcsetup update`. The system detects which tools are actually installed by checking for their marker directories, and only updates the tools that are present. Skipped tools are not touched.

**Why this priority**: Equally critical as full update — projects frequently have partial installations. The update command must correctly detect installed tools to avoid errors from attempting to update absent tools.

**Independent Test**: Can be fully tested by running `npx tcsetup update` in a project where some tools were skipped during init, then verifying only installed tools are updated.

**Acceptance Scenarios**:

1. **Given** a project where adr-system was skipped (no `.adr/` directory), **When** the user runs `npx tcsetup update`, **Then** adr-system is not updated and no error is shown for its absence.
2. **Given** a project with only agreement-system and feature-lifecycle installed, **When** the user runs `npx tcsetup update`, **Then** only those two packages are updated via npm and only their update commands are called.

---

### User Story 3 - Backward-Compatible CLI (Priority: P1)

A developer who has been using `npx tcsetup` (with no subcommand) to onboard projects expects the same behavior to continue working after the CLI is updated with the new `update` subcommand. Running `npx tcsetup` without arguments still performs the full init/onboarding sequence as before.

**Why this priority**: Breaking backward compatibility would disrupt existing workflows and documentation. The CLI refactor must preserve the existing default behavior.

**Independent Test**: Can be fully tested by running `npx tcsetup` (no arguments) and verifying the full init sequence runs identically to the pre-refactor behavior.

**Acceptance Scenarios**:

1. **Given** a new project, **When** the user runs `npx tcsetup` with no subcommand, **Then** the full onboarding/init sequence runs exactly as before the CLI refactor.
2. **Given** the updated CLI, **When** the user runs `npx tcsetup init`, **Then** the same onboarding/init sequence runs.

---

### User Story 4 - Error Resilience During Update (Priority: P2)

A developer runs `npx tcsetup update` but encounters a failure with one of the sub-tool updates (e.g., network issue during npm install, or one sub-tool's update script fails). The update process logs the error clearly but continues updating the remaining tools, ensuring a single failure does not block the entire update.

**Why this priority**: Real-world updates frequently encounter partial failures (network issues, package registry problems). Resilience ensures the user gets as much value as possible from a single update run.

**Independent Test**: Can be tested by simulating a failure in one sub-tool's update (e.g., temporarily making it unavailable) and verifying the remaining tools still update successfully.

**Acceptance Scenarios**:

1. **Given** a sub-tool update fails during `npx tcsetup update`, **When** the failure occurs, **Then** the error is logged with a clear message identifying the failed tool, and the remaining tools continue to update.
2. **Given** the npm install step fails for one package, **When** the user runs `npx tcsetup update`, **Then** the error is logged and sub-tool updates for successfully installed packages still proceed.

---

### User Story 5 - Help Text Shows Update Command (Priority: P3)

A developer runs `npx tcsetup help` (or `npx tcsetup --help`) to see available commands. The help output clearly lists both the `init` and `update` subcommands with short descriptions of what each does.

**Why this priority**: Discoverability is important for new commands, but this is lower priority because the command can be used without help text.

**Independent Test**: Can be tested by running `npx tcsetup help` and verifying the output lists `init`, `update`, and `help` commands with descriptions.

**Acceptance Scenarios**:

1. **Given** the updated CLI, **When** the user runs `npx tcsetup help`, **Then** the output lists `init`, `update`, and `help` subcommands with descriptions.
2. **Given** the updated CLI, **When** the user runs `npx tcsetup` with an unrecognized subcommand, **Then** a helpful error message is shown along with usage information.

---

### Edge Cases

- What happens when the user runs `npx tcsetup update` in a project that was never onboarded (no marker directories exist)? The command should detect no installed tools, log a message indicating nothing to update, and exit gracefully.
- What happens when mermaid-workbench's marker directory uses the alternate path (`.bmad/modules/mermaid-workbench` instead of `_bmad/modules/mermaid-workbench`)? Both paths should be checked during detection.
- What happens when a sub-tool package is already at the latest version? The npm install command should complete without error (no-op), and the sub-tool update should still run to refresh commands/templates.
- What happens when the `.claude/commands/` directory does not exist? It should be created before copying tcsetup's own command files.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST provide an `update` subcommand accessible via `npx tcsetup update`.
- **FR-002**: The system MUST detect which TC stack tools are installed by checking for their marker directories (`.adr/`, `.agreements/`, `.features/`, `_bmad/modules/mermaid-workbench/` or `.bmad/modules/mermaid-workbench/`).
- **FR-003**: The system MUST update npm packages to their latest versions only for detected (installed) tools.
- **FR-004**: The system MUST call each detected tool's update subcommand after package update (or idempotent init for mermaid-workbench).
- **FR-005**: The system MUST refresh tcsetup's own command files (`tcsetup.onboard.md`, `feature.workflow.md`) in `.claude/commands/` during update.
- **FR-006**: The system MUST preserve backward compatibility — running `npx tcsetup` with no subcommand MUST execute the existing init/onboarding sequence.
- **FR-007**: The system MUST implement CLI command routing with support for `init`, `update`, and `help` subcommands.
- **FR-008**: The system MUST continue updating remaining tools when one tool's update fails, logging errors clearly.
- **FR-009**: The system MUST display help text listing all available subcommands when `help` is invoked or an unrecognized command is used.
- **FR-010**: The system MUST NOT update tools that are not installed in the project (no marker directory = skip).
- **FR-011**: The system MUST use only Node.js built-in modules (zero runtime dependencies).
- **FR-012**: The system MUST only refresh generated/template files during update — user data, configurations, and indexes MUST NOT be modified.

### Key Entities

- **TC Stack Tool**: A sub-tool in the TC ecosystem (adr-system, agreement-system, feature-lifecycle, mermaid-workbench), each identified by a marker directory and having an update (or idempotent init) command.
- **Marker Directory**: A filesystem directory whose existence indicates a specific TC tool is installed in the project (e.g., `.adr/` for adr-system).
- **Command File**: A markdown file in `.claude/commands/` that provides Claude Code with slash command instructions.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can update all installed TC stack tools with a single command (`npx tcsetup update`) instead of running 4+ separate commands.
- **SC-002**: Projects with partial tool installations receive correct selective updates — only installed tools are updated, with zero errors for absent tools.
- **SC-003**: Existing onboarding workflows (`npx tcsetup` with no arguments) continue to work identically after the CLI refactor.
- **SC-004**: When a sub-tool update fails, the remaining tools still complete their updates successfully — a single failure does not cascade.
- **SC-005**: The update command completes without introducing any new runtime dependencies beyond Node.js built-ins.

## Assumptions

- All four sub-tools (adr-system, agreement-system, feature-lifecycle, mermaid-workbench) maintain their existing update (or idempotent init) subcommand contracts.
- The npm registry is reachable when running the update command. If not, the npm install step will fail and the error will be logged.
- mermaid-workbench's `init` command remains idempotent and safe to re-run as a substitute for a dedicated `update` subcommand.
- The project has npm initialized (a `package.json` exists) since it was previously onboarded.
- BMAD (`bmad-method`) and Spec Kit (`specify`) are external tools with their own lifecycles and are intentionally excluded from the update scope.

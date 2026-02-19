# Feature Specification: Playbook CLI Commands (Status & List)

**Feature Branch**: `015-cli-commands`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "Add two new CLI commands to the @tcanaud/playbook package: (1) `npx @tcanaud/playbook status` - Display status of all currently running playbook sessions, (2) `npx @tcanaud/playbook list` - List all playbook sessions. Both commands should support JSON output and a polished terminal-friendly default output."

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Monitor Running Sessions (Priority: P1)

A DevOps engineer is executing multiple playbook sessions and needs to quickly check which sessions are currently running and their status without interrupting execution or navigating file systems.

**Why this priority**: This is the core value proposition of the status command - enabling real-time visibility into active playbook execution, essential for session management and troubleshooting.

**Independent Test**: Can be fully tested by running `npx @tcanaud/playbook status` with multiple active sessions and verifying that all running sessions are displayed with their current status.

**Acceptance Scenarios**:

1. **Given** one playbook session is currently running, **When** the user runs `npx @tcanaud/playbook status`, **Then** the terminal displays the session ID, creation time, current status, and any relevant progress information in a human-readable format
2. **Given** multiple playbook sessions are running simultaneously, **When** the user runs `npx @tcanaud/playbook status`, **Then** all sessions are displayed with clear visual separation
3. **Given** no playbook sessions are running, **When** the user runs `npx @tcanaud/playbook status`, **Then** the command displays a clear message indicating no active sessions

---

### User Story 2 - Retrieve Session List for Automation (Priority: P1)

A CI/CD system needs to programmatically query which playbook sessions exist (completed or running) and parse the output reliably for downstream automation, such as aggregating results or triggering notifications.

**Why this priority**: JSON output is critical for system integration and automation, enabling programmatic access to session data without terminal UI concerns.

**Independent Test**: Can be fully tested by running `npx @tcanaud/playbook list --json` and verifying the output is valid JSON that can be parsed and contains expected fields for each session.

**Acceptance Scenarios**:

1. **Given** multiple playbook sessions exist (running, completed, or failed), **When** the user runs `npx @tcanaud/playbook list --json`, **Then** the output is valid JSON containing an array of session objects with consistent schema
2. **Given** the list command is executed with JSON output, **When** parsing the JSON, **Then** each session object contains at minimum: session ID, creation timestamp, and final status
3. **Given** no sessions exist in the system, **When** the user runs `npx @tcanaud/playbook list --json`, **Then** valid empty JSON (empty array) is returned

---

### User Story 3 - Browse Historical Sessions (Priority: P2)

A user wants to view all playbook sessions (both running and completed) in a human-readable format to understand execution history, find a specific session, or review past results without switching to a different tool.

**Why this priority**: The list command provides historical visibility complementing the real-time status view. While important for user experience, it's secondary to the immediate monitoring need.

**Independent Test**: Can be fully tested by running `npx @tcanaud/playbook list` and verifying that all sessions (completed and running) are displayed in a readable format with distinguishable status indicators.

**Acceptance Scenarios**:

1. **Given** multiple playbook sessions with different statuses exist, **When** the user runs `npx @tcanaud/playbook list`, **Then** all sessions are displayed in a table or list format with clear status indicators (running, completed, failed)
2. **Given** sessions have varying timestamps, **When** `npx @tcanaud/playbook list` is executed, **Then** output is sorted chronologically (most recent first) for easy scanning

---

### User Story 4 - Terminal-Friendly Output Formatting (Priority: P2)

A user values a polished, visually clear terminal experience that makes session information easy to scan at a glance, with appropriate use of spacing, colors, and alignment without requiring specialized tools to parse.

**Why this priority**: User experience with terminal output is important for adoption and ease of use, but the core functionality (data retrieval and JSON output) is more critical.

**Independent Test**: Can be fully tested by running both commands in their default (non-JSON) mode and verifying the output is well-formatted, readable, and doesn't produce parsing errors.

**Acceptance Scenarios**:

1. **Given** the status or list command is executed without `--json` flag, **When** output is displayed, **Then** formatting uses clear alignment, readable spacing, and consistent field labels
2. **Given** terminal output is produced, **When** viewed in a standard terminal (80+ character width), **Then** content is fully visible without horizontal scrolling for typical session counts

### Edge Cases

- What happens when session files are corrupted or unreadable?
- How does the system handle sessions with missing or incomplete metadata?
- What should be displayed if a session is partially created (missing journal file)?
- How does the command handle permissions issues accessing session directories?
- What happens if session directories don't exist yet (first-time use)?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST provide an `npx @tcanaud/playbook status` command that displays all currently running playbook sessions
- **FR-002**: System MUST provide an `npx @tcanaud/playbook list` command that displays all playbook sessions (running and completed)
- **FR-003**: System MUST support a `--json` flag on both commands that outputs results in valid JSON format
- **FR-004**: System MUST display session ID for each session in both human-readable and JSON formats
- **FR-005**: System MUST display session creation timestamp for each session in both formats
- **FR-006**: System MUST display current session status (running, completed, failed) in both formats
- **FR-007**: System MUST provide clear visual distinction between running and completed sessions in human-readable output
- **FR-008**: System MUST handle the case where no sessions exist gracefully, displaying an appropriate message or empty result
- **FR-009**: System MUST read session data from the `.playbooks/sessions/` directory structure without requiring external dependencies
- **FR-010**: System MUST maintain consistent JSON schema across multiple invocations of the list command
- **FR-011**: Human-readable output MUST be formatted for readability in standard terminal widths (80+ characters)
- **FR-012**: System MUST sort sessions chronologically in human-readable list output (most recent first)

### Key Entities

- **Session**: Represents a playbook execution instance with ID, creation timestamp, execution journal, status, and metadata
- **Session Status**: One of running, completed, or failed states
- **Session ID**: Unique identifier for a playbook session instance

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: Both commands execute and complete in under 1 second regardless of session count (up to 100 sessions)
- **SC-002**: JSON output can be parsed by standard JSON tools without errors
- **SC-003**: Human-readable output is fully visible in an 80-character terminal width for typical use cases (5-10 sessions)
- **SC-004**: Commands correctly identify and report status for 100% of active sessions
- **SC-005**: Users can identify session status from human-readable output without external tools or documentation
- **SC-006**: No runtime dependencies required beyond Node.js built-ins (`node:` protocol imports only)

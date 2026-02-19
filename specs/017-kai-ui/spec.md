# Feature Specification: Kai UI

**Feature Branch**: `017-kai-ui`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "Kai UI - cyberpunk web IDE for kai governance stack"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Launch Kai UI from Project Root (Priority: P1)

The kai creator runs a single command from any kai-enabled project root. The application starts a local web server and automatically opens the browser. A cyberpunk-themed dark interface appears with a session sidebar on the left and a main content area. The interface is immediately usable — no configuration, no login, no setup steps.

**Why this priority**: This is the entry point to the entire product. Without a working launcher, nothing else functions. It validates the core delivery mechanism.

**Independent Test**: Can be fully tested by running `npx kai-ui` from a kai project root and verifying the browser opens with the styled interface.

**Acceptance Scenarios**:

1. **Given** the user is in a kai-enabled project root (contains `.features/` directory), **When** they run `npx kai-ui`, **Then** a local web server starts and the default browser opens on `localhost:3000` displaying the cyberpunk dark interface.
2. **Given** the application is launching, **When** the server is ready, **Then** the browser opens automatically within 5 seconds of the command being run.
3. **Given** the browser has opened, **When** the page loads, **Then** the user sees a dark-themed interface with neon accent colors (cyan, magenta, violet), monospace typography for code content, and a session sidebar.

---

### User Story 2 - Create a New Worktree Session (Priority: P1)

From the session sidebar, the user clicks "New Session". They select a playbook and provide a feature name. The application executes the session creation command in the background. A new session appears in the sidebar. The user clicks into it and sees five styled placeholder panels arranged in a multi-panel layout.

**Why this priority**: Session creation is the primary user action in the MVP. It validates the integration with the existing playbook system and proves the panel architecture works.

**Independent Test**: Can be fully tested by creating a session through the UI and verifying the playbook start command executes and the session appears with all five panels.

**Acceptance Scenarios**:

1. **Given** the user is on the main interface, **When** they click "New Session", **Then** they are presented with a form to select a playbook and enter a feature name.
2. **Given** the user has filled in the session form with a valid playbook and feature name, **When** they submit the form, **Then** the application executes `npx @tcanaud/playbook start {playbook} {feature}` and shows progress feedback.
3. **Given** the session creation command completes successfully, **When** the session is ready, **Then** it appears in the sidebar and the user can click into it to see five styled placeholder panels.
4. **Given** the session creation command fails, **When** an error occurs, **Then** the user sees a clear error message with the command output.

---

### User Story 3 - View and Switch Between Sessions (Priority: P2)

The user has multiple worktree sessions running. The sidebar lists all active sessions. Clicking a session switches the main content area to display that session's five-panel view. Switching is instant — no loading screens, no delays.

**Why this priority**: Multi-session support is the core value proposition of the unified interface. Without session switching, the user has no advantage over separate terminal windows.

**Independent Test**: Can be fully tested by creating two sessions and clicking between them, verifying each displays its own panel view.

**Acceptance Scenarios**:

1. **Given** multiple sessions exist, **When** the user views the sidebar, **Then** all active sessions are listed with their names.
2. **Given** the user is viewing one session, **When** they click a different session in the sidebar, **Then** the main content area switches to display the selected session's panels within 100ms.
3. **Given** the user switches between sessions, **When** they return to a previous session, **Then** the panel state is preserved as they left it.

---

### User Story 4 - Five-Panel Session View with Cyberpunk Design (Priority: P1)

Each session displays five distinct panel slots in a multi-panel layout: terminal, code editor, playbook dashboard, AI chat, and AI assistant overlay. In the MVP, all panels show styled placeholder content that matches the cyberpunk aesthetic. The placeholders clearly indicate what each panel will become in future versions. Interactive elements (buttons, separators, active panels) display glow effects.

**Why this priority**: The panel system is the architectural foundation. Getting the layout, styling, and component interface right in the MVP ensures future panel implementations can be plugged in without refactoring.

**Independent Test**: Can be fully tested by opening a session and verifying all five panels render with correct styling, placeholder content, and responsive behavior.

**Acceptance Scenarios**:

1. **Given** the user opens a session, **When** the session view loads, **Then** five distinct panel areas are visible: terminal, code editor, playbook dashboard, AI chat, and AI assistant overlay.
2. **Given** the panels are displayed, **When** the user inspects the styling, **Then** each panel uses the cyberpunk dark theme with neon accents, glow effects on interactive elements, and monospace typography for code-related content.
3. **Given** the panels are displayed, **When** the user looks at placeholder content, **Then** each panel clearly identifies what it will become (e.g., "Terminal — xterm.js + tmux integration coming in V1.1").
4. **Given** the panels are displayed on desktop, **When** the user drags a panel separator, **Then** the panels resize fluidly.

---

### User Story 5 - Responsive Layout (Desktop and Mobile) (Priority: P2)

On desktop viewports (≥1024px), the interface shows the full sidebar alongside the multi-panel session view. On mobile viewports (<1024px), the sidebar collapses into a hamburger menu and panels stack vertically. The mobile view is read-friendly for quick status checks — no complex interactions needed.

**Why this priority**: Mobile support enables quick status checks away from the desk, and responsive design from day one prevents expensive layout refactoring later.

**Independent Test**: Can be fully tested by resizing the browser window and verifying the layout transitions between desktop and mobile modes.

**Acceptance Scenarios**:

1. **Given** the user is on a desktop viewport (≥1024px), **When** the page loads, **Then** the sidebar is visible alongside the multi-panel session view.
2. **Given** the user is on a mobile viewport (<1024px), **When** the page loads, **Then** the sidebar is hidden behind a hamburger menu icon and panels are stacked vertically.
3. **Given** the user is on mobile, **When** they tap the hamburger menu, **Then** the sidebar slides in as an overlay showing the session list.
4. **Given** the user resizes the browser from desktop to mobile width, **When** the viewport crosses 1024px, **Then** the layout transitions smoothly without jank.

---

### Edge Cases

- What happens when the user runs `npx kai-ui` outside a kai-enabled project? The application displays a clear error message explaining it must be run from a kai project root.
- What happens when `npx @tcanaud/playbook start` fails (e.g., invalid playbook name)? The UI captures stderr and displays the error to the user.
- What happens when the user creates a session with a feature name that already exists? The playbook command handles this — the UI relays its response.
- What happens when no sessions exist? The sidebar shows an empty state with a prompt to create the first session.
- What happens when the browser is closed and reopened? The sidebar lists existing sessions (read from filesystem on load).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST launch via `npx kai-ui` from a kai-enabled project root, starting a local web server on `localhost:3000`
- **FR-002**: System MUST detect the project root and verify kai directory structure exists (`.features/` directory present)
- **FR-003**: System MUST open the default browser automatically when the server is ready
- **FR-004**: System MUST display a session sidebar listing all active worktree sessions
- **FR-005**: System MUST allow the user to create a new worktree session by selecting a playbook and providing a feature name
- **FR-006**: System MUST execute `npx @tcanaud/playbook start {playbook} {feature}` to create worktree sessions and provide feedback on progress and errors
- **FR-007**: System MUST allow the user to switch between sessions with a single click, updating the main content area
- **FR-008**: System MUST render a multi-panel layout within each session view with 5 distinct panel slots (terminal, code editor, playbook dashboard, AI chat, AI assistant overlay)
- **FR-009**: System MUST allow the user to resize panels within the session view via draggable separators
- **FR-010**: System MUST render a cyberpunk dark theme with neon accent colors (cyan, magenta, violet), glow effects on interactive elements, and monospace typography for code content
- **FR-011**: System MUST display styled placeholder content in each panel that identifies the future functionality
- **FR-012**: System MUST adapt layout between desktop (≥1024px: sidebar + panels) and mobile (<1024px: hamburger menu + stacked panels)
- **FR-013**: System MUST use a pluggable panel component interface so that each placeholder can be replaced with a real implementation without affecting other panels or the layout
- **FR-014**: System MUST read existing worktree sessions from the filesystem on load to populate the sidebar
- **FR-015**: System MUST display a clear error message when launched outside a kai-enabled project root

### Key Entities

- **Session**: Represents a worktree session — has a name, associated playbook, feature name, and creation timestamp. Maps to a git worktree created by the playbook system.
- **Panel**: A UI component slot within a session view — has a type (terminal, editor, playbook, chat, assistant), content component, and resize state. Each panel implements a standard component interface.
- **Playbook**: A workflow template selectable during session creation — read from the available playbooks in the project.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Application launches and opens the browser within 5 seconds of running the command
- **SC-002**: All 5 placeholder panels render correctly within each session view with cyberpunk styling
- **SC-003**: Session creation via the UI successfully triggers the playbook start command and produces a new session in the sidebar
- **SC-004**: Panel layout is usable on both desktop (≥1024px) and mobile (<1024px) viewports
- **SC-005**: Switching between sessions completes in under 100ms with no visible loading state
- **SC-006**: Each panel can be independently replaced with a real implementation by swapping a single component — no layout changes needed
- **SC-007**: The skeleton is architecturally sound enough to support incremental panel implementation across V1.1–V1.5 without refactoring the layout system

## Assumptions

- The user always runs `npx kai-ui` from a kai-enabled project root (`.features/` directory exists)
- Only one user accesses the application at a time (single-user, local-only)
- No authentication or authorization is needed — ever
- The playbook system (`npx @tcanaud/playbook start`) is already installed and functional
- The zero-deps philosophy is explicitly waived for this package — npm dependencies are acceptable
- The package lives in `packages/kai-ui/` as a git submodule following kai convention
- No deployment, CDN, or SEO considerations — local dev tool only
- Session persistence beyond browser refresh is handled by the playbook/tmux system, not by the UI itself in the MVP

## Scope Boundaries

**In Scope (MVP)**:
- CLI launcher (`npx kai-ui`)
- Cyberpunk dark UI design system
- Session sidebar with list and creation
- Five styled placeholder panels per session
- Pluggable panel architecture
- Responsive layout (desktop + mobile)

**Out of Scope (MVP)**:
- Functional xterm.js + tmux terminal (V1.1)
- Functional code-server integration (V1.2)
- Playbook dashboard reading `.playbooks/` sessions (V1.3)
- AI chat functionality (V1.4)
- AI assistant overlay functionality (V1.5)
- `.kaiui/` state persistence (V2.0+)
- Any kai file reading (`.features/`, `.agreements/`, etc.)
- Database or external service integration

# Tasks: Kai UI

**Input**: Design documents from `specs/017-kai-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.md, quickstart.md

**Tests**: Not requested — test tasks omitted.

**Organization**: Tasks grouped by user story. All file paths relative to `packages/kai-ui/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the kai-ui package, initialize Next.js, configure tooling

- [x] T001 Create GitHub repo `tcanaud/kai-ui` and register as git submodule at `packages/kai-ui/`
- [x] T002 Initialize Next.js 14+ project with TypeScript, App Router, Tailwind CSS in `packages/kai-ui/`
- [x] T003 Install and initialize shadcn/ui with dark theme defaults in `packages/kai-ui/`
- [x] T004 [P] Install Lucide React icons package in `packages/kai-ui/`
- [x] T005 [P] Add JetBrains Mono font files to `packages/kai-ui/public/fonts/` and configure in `packages/kai-ui/src/app/layout.tsx`
- [x] T006 Create CLI entry point `packages/kai-ui/bin/cli.js` — validates project root (checks `.features/`), starts Next.js dev server, opens default browser

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cyberpunk design system and shared types that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Define cyberpunk CSS variables (neon cyan `#00f0ff`, magenta `#ff00ff`, violet `#8b5cf6`, dark backgrounds `#0a0a0f`/`#111118`/`#1a1a2e`) and glow utility classes in `packages/kai-ui/src/app/globals.css`
- [x] T008 [P] Create shared TypeScript types (`Session`, `Panel`, `PanelProps`, `Playbook`, `PanelType` enum) in `packages/kai-ui/src/app/lib/types.ts`
- [x] T009 [P] Configure shadcn/ui theme overrides for cyberpunk palette in `packages/kai-ui/tailwind.config.ts` and `packages/kai-ui/components.json`
- [x] T010 Create root layout with dark background, font loading (JetBrains Mono + system sans), and metadata in `packages/kai-ui/src/app/layout.tsx`

**Checkpoint**: Foundation ready — cyberpunk design system configured, types defined

---

## Phase 3: User Story 1 — Launch Kai UI from Project Root (Priority: P1) 🎯 MVP

**Goal**: `npx kai-ui` starts a local server and opens a cyberpunk-themed interface with a session sidebar

**Independent Test**: Run `npx kai-ui` from a kai project root → browser opens → dark themed interface with sidebar visible

### Implementation for User Story 1

- [x] T011 [US1] Implement project root validation logic (check `.features/` directory exists) in `packages/kai-ui/bin/cli.js`
- [x] T012 [US1] Implement Next.js dev server launcher with auto browser-open (platform-aware: `open` on macOS, `xdg-open` on Linux) in `packages/kai-ui/bin/cli.js`
- [x] T013 [US1] Create the main page layout skeleton with sidebar placeholder and main content area in `packages/kai-ui/src/app/page.tsx`
- [x] T014 [US1] Make `packages/kai-ui/bin/cli.js` executable and configure `"bin"` entry in `packages/kai-ui/package.json`

**Checkpoint**: `npx kai-ui` opens browser with styled empty shell

---

## Phase 4: User Story 4 — Five-Panel Session View with Cyberpunk Design (Priority: P1)

**Goal**: Each session displays 5 styled placeholder panels with cyberpunk aesthetic and resizable layout

**Independent Test**: Open a session → 5 panels visible with neon styling, glow effects, placeholder content, draggable separators

### Implementation for User Story 4

- [x] T015 [P] [US4] Create `PanelSlot` wrapper component implementing `PanelProps` interface in `packages/kai-ui/src/app/components/panels/panel-slot.tsx`
- [x] T016 [P] [US4] Create terminal placeholder panel with "xterm.js + tmux — V1.1" label in `packages/kai-ui/src/app/components/panels/terminal-placeholder.tsx`
- [x] T017 [P] [US4] Create editor placeholder panel with "code-server — V1.2" label in `packages/kai-ui/src/app/components/panels/editor-placeholder.tsx`
- [x] T018 [P] [US4] Create playbook placeholder panel with "Playbook Dashboard — V1.3" label in `packages/kai-ui/src/app/components/panels/playbook-placeholder.tsx`
- [x] T019 [P] [US4] Create chat placeholder panel with "AI Chat — V1.4" label in `packages/kai-ui/src/app/components/panels/chat-placeholder.tsx`
- [x] T020 [P] [US4] Create assistant placeholder panel with "AI Assistant — V1.5" label in `packages/kai-ui/src/app/components/panels/assistant-placeholder.tsx`
- [x] T021 [US4] Create `PanelLayout` component — multi-panel grid with draggable separators, renders all 5 panel slots in `packages/kai-ui/src/app/components/panels/panel-layout.tsx`

**Checkpoint**: Panel layout renders 5 styled placeholders with glow effects and resizable separators

---

## Phase 5: User Story 2 — Create a New Worktree Session (Priority: P1)

**Goal**: User clicks "New Session" → selects playbook + feature → session created via `npx @tcanaud/playbook start` → appears in sidebar with 5 panels

**Independent Test**: Click "New Session" → fill form → submit → session appears in sidebar → click into it → 5 panels visible

### Implementation for User Story 2

- [x] T022 [P] [US2] Implement `GET /api/sessions` route — reads `.playbooks/sessions/` directory, parses `session.yaml` files in `packages/kai-ui/src/app/api/sessions/route.ts`
- [x] T023 [P] [US2] Implement `POST /api/sessions` route — executes `npx @tcanaud/playbook start {playbook} {feature}`, returns session data or error in `packages/kai-ui/src/app/api/sessions/route.ts`
- [x] T024 [P] [US2] Implement `GET /api/playbooks` route — reads `.playbooks/_index.yaml` or scans `.playbooks/playbooks/*.yaml` in `packages/kai-ui/src/app/api/playbooks/route.ts`
- [x] T025 [US2] Implement session read/create client-side helpers in `packages/kai-ui/src/app/lib/sessions.ts`
- [x] T026 [US2] Create `SessionSidebar` component — lists sessions, "New Session" button in `packages/kai-ui/src/app/components/sidebar/session-sidebar.tsx`
- [x] T027 [P] [US2] Create `SessionItem` component — individual session entry in sidebar in `packages/kai-ui/src/app/components/sidebar/session-item.tsx`
- [x] T028 [US2] Create `NewSessionDialog` component — playbook select + feature name form with loading/error states in `packages/kai-ui/src/app/components/sidebar/new-session-dialog.tsx`
- [x] T029 [US2] Integrate sidebar + panel layout in main page — clicking a session shows its 5-panel view in `packages/kai-ui/src/app/page.tsx`
- [x] T030 [US2] Add empty state to sidebar when no sessions exist — prompt to create first session in `packages/kai-ui/src/app/components/sidebar/session-sidebar.tsx`

**Checkpoint**: Full session creation flow works end-to-end — sidebar lists sessions, new sessions created via UI

---

## Phase 6: User Story 3 — View and Switch Between Sessions (Priority: P2)

**Goal**: Multiple sessions in sidebar, clicking switches the main panel view instantly

**Independent Test**: Create 2 sessions → click between them → each shows its own panel view, switching < 100ms

### Implementation for User Story 3

- [x] T031 [US3] Add active session state management (selected session context) in `packages/kai-ui/src/app/page.tsx`
- [x] T032 [US3] Implement instant session switching — update `SessionItem` with active/selected styling (neon glow border) in `packages/kai-ui/src/app/components/sidebar/session-item.tsx`
- [x] T033 [US3] Preserve panel state per session when switching (store resize positions in React state keyed by session ID) in `packages/kai-ui/src/app/components/panels/panel-layout.tsx`

**Checkpoint**: Multi-session switching works instantly with state preserved

---

## Phase 7: User Story 5 — Responsive Layout (Priority: P2)

**Goal**: Desktop shows sidebar + panels side by side. Mobile (< 1024px) has hamburger menu + stacked panels

**Independent Test**: Resize browser across 1024px breakpoint → layout transitions smoothly between desktop and mobile modes

### Implementation for User Story 5

- [x] T034 [P] [US5] Create `MobileNav` component — hamburger icon, slide-in sidebar overlay in `packages/kai-ui/src/app/components/layout/mobile-nav.tsx`
- [x] T035 [US5] Create `ResponsiveShell` component — switches between desktop (sidebar + panels) and mobile (hamburger + stacked panels) at 1024px breakpoint in `packages/kai-ui/src/app/components/layout/responsive-shell.tsx`
- [x] T036 [US5] Add mobile panel stacking layout — panels render vertically on mobile in `packages/kai-ui/src/app/components/panels/panel-layout.tsx`
- [x] T037 [US5] Integrate `ResponsiveShell` as the main layout wrapper in `packages/kai-ui/src/app/page.tsx`

**Checkpoint**: Layout is usable on desktop and mobile viewports

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Error handling, edge cases, final touches

- [x] T038 Add error boundary for session creation failures — display command stderr in `packages/kai-ui/src/app/components/sidebar/new-session-dialog.tsx`
- [x] T039 Add error page when launched outside kai project root — styled error with instructions in `packages/kai-ui/src/app/page.tsx`
- [x] T040 [P] Configure `packages/kai-ui/package.json` for npm publishing — `@tcanaud/kai-ui`, `"bin"`, `"files"`, `"engines"`, `"repository"`
- [x] T041 [P] Create `.github/workflows/publish.yml` for trusted publishing in `packages/kai-ui/.github/workflows/publish.yml`
- [x] T042 Run quickstart.md validation — verify `npx @tcanaud/kai-ui` works end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — CLI launcher + empty shell
- **US4 (Phase 4)**: Depends on Foundational — panel components (no dependency on US1 sidebar)
- **US2 (Phase 5)**: Depends on US1 (page skeleton) + US4 (panel layout) — session management
- **US3 (Phase 6)**: Depends on US2 — multi-session switching
- **US5 (Phase 7)**: Depends on US2 — responsive wrapper around existing layout
- **Polish (Phase 8)**: Depends on all user stories

### User Story Dependencies

```
Phase 1 (Setup)
  └── Phase 2 (Foundational)
        ├── Phase 3 (US1: Launch) ──┐
        │                           ├── Phase 5 (US2: Sessions) ── Phase 6 (US3: Switching)
        └── Phase 4 (US4: Panels) ──┘                          └── Phase 7 (US5: Responsive)
                                                                         │
                                                                   Phase 8 (Polish)
```

### Parallel Opportunities

- **Phase 1**: T004 and T005 can run in parallel
- **Phase 2**: T008 and T009 can run in parallel
- **Phase 3 + Phase 4**: US1 (launcher/page) and US4 (panel components) can run in parallel after Foundational
- **Phase 4**: T015–T020 (all 6 placeholder panels) can run in parallel
- **Phase 5**: T022, T023, T024 (API routes) can run in parallel
- **Phase 7**: T034 can run in parallel with T035
- **Phase 8**: T040 and T041 can run in parallel

---

## Parallel Example: User Story 4 (Panel Components)

```bash
# Launch all placeholder panels in parallel (different files, no dependencies):
T015: Create PanelSlot wrapper in panels/panel-slot.tsx
T016: Create terminal placeholder in panels/terminal-placeholder.tsx
T017: Create editor placeholder in panels/editor-placeholder.tsx
T018: Create playbook placeholder in panels/playbook-placeholder.tsx
T019: Create chat placeholder in panels/chat-placeholder.tsx
T020: Create assistant placeholder in panels/assistant-placeholder.tsx

# Then sequentially:
T021: Create PanelLayout grid that assembles all panels
```

---

## Implementation Strategy

### MVP First (US1 + US4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US1 — `npx kai-ui` opens styled shell
4. Complete Phase 4: US4 — 5 styled placeholder panels render
5. **STOP and VALIDATE**: Interface launches, panels visible with cyberpunk styling

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 + US4 → Launcher + Panels (visual skeleton)
3. US2 → Session creation + sidebar (functional MVP)
4. US3 → Multi-session switching
5. US5 → Responsive layout
6. Polish → Error handling, npm publishing

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All paths relative to `packages/kai-ui/`
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently

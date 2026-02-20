# Implementation Plan: Kai UI

**Branch**: `017-kai-ui` | **Date**: 2026-02-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/017-kai-ui/spec.md`

## Summary

Kai UI is a local-only Next.js web application launched via `npx kai-ui` that provides a cyberpunk-themed unified interface for the kai governance stack. The MVP delivers a fully styled skeleton with session management (creating worktree sessions via `npx @tcanaud/playbook start`), five placeholder panels per session, and responsive desktop/mobile layout. The package lives in `packages/kai-ui/` as a git submodule.

## Technical Context

**Language/Version**: TypeScript (Next.js 14+ with App Router), Node.js >= 18.0.0
**Primary Dependencies**: Next.js, React, shadcn/ui, Tailwind CSS, Lucide React (icons)
**Storage**: Filesystem only — reads `.playbooks/sessions/` for session state, no database
**Testing**: Vitest for unit tests, Playwright for E2E (future)
**Target Platform**: localhost (Chrome/Chromium primary, Safari best-effort)
**Project Type**: Web application (Next.js SPA)
**Performance Goals**: Cold start < 5s, page load < 1s, panel switch < 100ms
**Constraints**: Single user, local-only, no auth, no deployment
**Scale/Scope**: 1 user, ~10 screens (sidebar + 5 panel types + session creation + empty states + mobile variants)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution file is unfilled (template only) — no gates to evaluate. Project philosophy notes:

| Dogma | Status | Note |
|-------|--------|------|
| Git is the database | **Pass** | Sessions read from filesystem, no external DB |
| Drift detection | **N/A** | UI tool, no drift surface |
| Zero dependencies | **Waived** | PRD explicitly waives this for kai-ui (Next.js + shadcn/ui require npm deps) |
| Interface is prose | **Extended** | kai-ui adds a visual interface alongside existing CLI commands |
| Convention before code | **Pass** | Full BMAD + SpecKit workflow completed before implementation |

**Complexity justification for zero-deps waiver**: A web application with component library, styling system, and dev server cannot reasonably be built with zero dependencies. The PRD explicitly acknowledges this trade-off.

## Project Structure

### Documentation (this feature)

```text
specs/017-kai-ui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api.md           # API route contracts
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
packages/kai-ui/
├── bin/
│   └── cli.js                  # npx kai-ui entry point (starts Next.js + opens browser)
├── package.json                # @tcanaud/kai-ui
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
├── postcss.config.js
├── src/
│   └── app/
│       ├── layout.tsx          # Root layout with cyberpunk theme + fonts
│       ├── page.tsx            # Main page — sidebar + session view
│       ├── globals.css         # Tailwind + cyberpunk CSS variables + glow utilities
│       ├── components/
│       │   ├── sidebar/
│       │   │   ├── session-sidebar.tsx      # Session list + new session button
│       │   │   ├── session-item.tsx         # Individual session in sidebar
│       │   │   └── new-session-dialog.tsx   # Playbook + feature name form
│       │   ├── panels/
│       │   │   ├── panel-layout.tsx         # Multi-panel container with resizers
│       │   │   ├── panel-slot.tsx           # Generic panel wrapper (pluggable interface)
│       │   │   ├── terminal-placeholder.tsx
│       │   │   ├── editor-placeholder.tsx
│       │   │   ├── playbook-placeholder.tsx
│       │   │   ├── chat-placeholder.tsx
│       │   │   └── assistant-placeholder.tsx
│       │   ├── ui/                          # shadcn/ui components (auto-generated)
│       │   └── layout/
│       │       ├── mobile-nav.tsx           # Hamburger menu for mobile
│       │       └── responsive-shell.tsx     # Desktop/mobile layout switcher
│       ├── lib/
│       │   ├── sessions.ts                  # Session read/create logic
│       │   └── types.ts                     # Shared TypeScript types
│       └── api/
│           └── sessions/
│               └── route.ts                 # POST: create session, GET: list sessions
├── public/
│   └── fonts/                               # Monospace font files (JetBrains Mono or similar)
└── .github/
    └── workflows/
        └── publish.yml
```

**Structure Decision**: Next.js App Router structure within `packages/kai-ui/`. The `src/app/` directory follows Next.js conventions. Components are organized by domain (sidebar, panels, layout, ui). API routes handle session management server-side.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| npm dependencies (Next.js, React, shadcn/ui, Tailwind) | Web application with component library requires a framework + styling system | Zero-deps approach is impossible for a web IDE — no reasonable alternative exists for rendering a multi-panel UI with responsive design |

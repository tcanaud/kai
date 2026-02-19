---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish]
classification:
  projectType: web_app
  domain: general
  complexity: low
  projectContext: brownfield
inputDocuments:
  - ".bmad_output/planning-artifacts/017-kai-ui/product-brief-kai-2026-02-19.md"
  - ".knowledge/guides/project-philosophy.md"
  - ".knowledge/snapshot.md"
  - ".knowledge/guides/create-new-package.md"
workflowType: 'prd'
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 3
---

# Product Requirements Document - kai UI

**Author:** tcanaud
**Date:** 2026-02-19

## Executive Summary

Kai UI is a local web IDE that surfaces the kai governance stack through a unified visual interface. It targets a single user — the kai creator — who currently operates 7 subsystems (ADR, Agreements, Features, Knowledge, BMAD, SpecKit, QA) and 16+ features entirely through terminal commands and Claude Code slash commands. The product eliminates context-switching between Ghostty, VS Code, and CLI sessions by consolidating terminal access, code editing, playbook management, and AI conversation into a single browser-based environment with persistent worktree sessions.

Launched via `npx kai-ui` from any kai-enabled project root, it opens a Next.js application on `localhost:3000`. Each worktree session embeds five panels — terminal (xterm.js + tmux), code editor (code-server), playbook dashboard, AI chat, and AI assistant overlay. The MVP ships a fully styled cyberpunk skeleton with placeholder panels and functional session creation via `npx @tcanaud/playbook start`.

### What Makes This Special

Kai UI is the only development environment built natively for the kai governance stack. It reads `.features/`, `.playbooks/`, `specs/`, `.agreements/` directly from the filesystem, with no database and no sync layer. Terminal sessions are backed by tmux with deterministic session IDs, so a browser refresh restores the exact terminal state. The cyberpunk aesthetic (neon cyan/magenta/violet on dark) is a deliberate design choice: a purpose-built control surface for an AI-driven development workflow.

## Project Classification

- **Project Type:** Web application (Next.js SPA, local dev server)
- **Domain:** Developer tooling (general)
- **Complexity:** Low — single user, no auth, no compliance, local-only
- **Project Context:** Brownfield — new `packages/kai-ui` in existing kai monorepo

## Success Criteria

### User Success

- **Flow state preservation**: Working sessions are never interrupted by tool-switching — terminal, editor, playbooks, and AI are in the same view
- **Zero external tool launches**: A full working day completed without opening Ghostty, VS Code, or standalone Claude Code for kai work
- **Instant context recovery**: Browser refresh or next-day return restores the exact session state (tmux persistence)

### Business Success

N/A — Personal productivity tool. No revenue, no user growth, no business metrics. Success = daily personal adoption.

### Technical Success

- `npx kai-ui` launches in < 5 seconds and opens browser automatically
- All 5 placeholder panels render correctly on desktop and mobile
- Session creation via `npx @tcanaud/playbook start` works end-to-end from the UI
- Panel layout is responsive and usable on both desktop and mobile viewports
- Architecture supports incremental panel replacement (placeholder → real implementation) without refactoring

### Measurable Outcomes

| Outcome | Target | Timeframe |
|---------|--------|-----------|
| Daily usage as primary dev tool | 100% of working days | After V1.1 (functional terminal) |
| External terminal opens for kai work | 0 per day | After V1.1 |
| MVP skeleton complete | All panels render with D.A. | MVP |
| Session creation works | End-to-end from UI | MVP |

## User Journeys

### Journey 1: First Launch — "Let's see this thing"

**Thibaud** just finished building the MVP. He runs `npx kai-ui` from the kai project root. The browser opens on `localhost:3000`. A dark cyberpunk interface fills the screen — neon accents, monospace typography, the session sidebar is empty. He clicks "New Session", selects a playbook and feature, the UI triggers `npx @tcanaud/playbook start`. A new worktree session appears in the sidebar. He clicks into it — five panels light up with styled placeholders. The skeleton works. Time to build the real thing.

### Journey 2: Daily Work — "Flow state"

**Thibaud** starts his day. Opens browser, `localhost:3000` is already bookmarked. Three worktree sessions from yesterday are in the sidebar — tmux kept them alive. He clicks into `017-kai-ui`, the terminal panel shows his last command, the code editor is open on the file he was editing, the playbook dashboard shows task progress. He works for hours without touching Ghostty or VS Code. Context switches between worktrees are one click. End of day, he closes the browser. Everything will be there tomorrow.

### Journey 3: New Feature Kickoff — "Spin up a worktree"

**Thibaud** gets an idea for a new feature. From the session sidebar, he clicks "New Session", picks the `feature-full` playbook, types the feature name. The UI runs `npx @tcanaud/playbook start feature-full 018-new-idea`. A new worktree session appears. He's immediately inside the new context — isolated worktree, fresh terminal, ready to go. The main branch worktree stays untouched in the sidebar.

### Journey 4: Mobile Check — "Quick glance on the go"

**Thibaud** is away from his desk. He opens kai-ui on his phone. The responsive layout adapts — sidebar collapses into a hamburger menu, panels stack vertically. He checks the playbook dashboard to see which tasks are done. Quick glance, no interaction needed. Back to his desk later for real work.

### Journey Requirements Summary

| Journey | Capabilities Revealed |
|---------|----------------------|
| First Launch | `npx kai-ui` launcher, session creation UI, playbook/feature selection, panel rendering |
| Daily Work | Session persistence (tmux), session list, one-click context switch, panel state |
| New Feature Kickoff | Session creation with playbook + feature args, worktree isolation, instant context |
| Mobile Check | Responsive layout, collapsible sidebar, stacked panels, read-only usability |

## Web Application Specific Requirements

### Project-Type Overview

Local-only Next.js SPA served on `localhost:3000`. No deployment, no CDN, no SEO, no public-facing concerns. Runs as a dev server launched via `npx kai-ui`, accessed exclusively by a single user on the same machine.

### Technical Architecture

- **Framework**: Next.js 14+ with App Router, shadcn/ui component library, Tailwind CSS
- **Rendering**: Client-side SPA — no SSR/SSG needed (local-only, no SEO)
- **Real-time**: WebSocket support required for future xterm.js terminal integration (MVP: placeholder only)
- **State management**: React state + context — no external state library needed for MVP
- **Backend**: Next.js API routes for session management and `npx @tcanaud/playbook start` execution

### Browser Support

| Browser | Support Level |
|---------|--------------|
| Chrome/Chromium | Primary — full support |
| Safari | Best-effort |
| Others | Not targeted |

### Responsive Design

- **Desktop (≥1024px)**: Full layout — sidebar + multi-panel session view
- **Mobile (<1024px)**: Collapsible sidebar (hamburger), vertically stacked panels, read-friendly

### Implementation Considerations

- Package lives in `packages/kai-ui/` as a git submodule (follows kai convention)
- `npx kai-ui` is the entry point — `bin/cli.js` starts the Next.js dev server and opens browser
- No build/deploy pipeline needed — local dev tool only
- Zero-deps philosophy is **explicitly waived** for this package (Next.js + shadcn/ui + Tailwind require npm dependencies)

## Project Scoping & Phased Development

### MVP Strategy

**Approach:** Experience MVP — ship a fully styled, architecturally sound skeleton that looks and feels like the final product but with placeholder panels. Validate layout, session management, and cyberpunk D.A. before investing in panel implementations.

**Resource:** Solo developer (tcanaud).

### Phase 1 — MVP

**Journeys supported:** First Launch, New Feature Kickoff, Mobile Check

**Must-have capabilities:**
1. `npx kai-ui` launcher (bin/cli.js → Next.js dev server → browser open)
2. Cyberpunk Dark UI design system (theme, typography, glow effects, color palette)
3. Session sidebar with list + "New Session" button
4. Session creation executing `npx @tcanaud/playbook start {playbook} {feature}`
5. Per-session view with 5 styled placeholder panels
6. Pluggable panel architecture (component interface for future real implementations)
7. Responsive layout (desktop sidebar + panels, mobile hamburger + stacked)

### Phase 2 — Growth (V1.1–V1.5)

- V1.1: Functional xterm.js + tmux terminal with deterministic session IDs
- V1.2: Code-server integration in worktree context
- V1.3: Playbook dashboard reading `.playbooks/` sessions
- V1.4: AI chat interface (conversational threads)
- V1.5: AI assistant overlay across all views

### Phase 3 — Expansion (V2.0+)

- Full kai-native IDE reading `.features/`, `.agreements/`, `specs/`
- `.kaiui/` state persistence
- Theme customization
- Multi-project support

### Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Cold start too slow | Next.js dev server is fast locally; measure and optimize if needed |
| Panel architecture not pluggable | Define clean component interface upfront; each panel is a React component with standard props |
| Solo developer bandwidth | MVP is deliberately minimal (placeholders only), built incrementally |
| Scope creep into panel implementations | Strict MVP boundary — no functional panels in Phase 1 |

## Functional Requirements

### Application Lifecycle

- FR1: User can launch the application via `npx kai-ui` from any kai-enabled project root
- FR2: Application can detect the project root and resolve kai directory structure (`.features/`, `.playbooks/`, `specs/`, etc.)
- FR3: Application can start a local web server and open the default browser automatically

### Session Management

- FR4: User can view a list of all active worktree sessions in a sidebar
- FR5: User can create a new worktree session by selecting a playbook and providing a feature name
- FR6: Application can execute `npx @tcanaud/playbook start {playbook} {feature}` to create a worktree session
- FR7: User can switch between worktree sessions with a single click
- FR8: User can select an active session to display its panel view

### Panel System

- FR9: Application can display a multi-panel layout within each session view
- FR10: Each session view can render 5 distinct panel slots (terminal, code editor, playbook dashboard, AI chat, AI assistant overlay)
- FR11: User can resize panels within the session view
- FR12: User can switch between panels on smaller viewports
- FR13: Each panel can be independently replaced with a real implementation without affecting other panels

### Design System

- FR14: Application can render a cyberpunk dark theme with neon accent colors (cyan, magenta, violet)
- FR15: Application can display glow effects on interactive elements (buttons, separators, active panels)
- FR16: Application can use monospace typography for code-related content
- FR17: Application can adapt layout between desktop (sidebar + panels) and mobile (hamburger menu + stacked panels)

### Placeholder Panels (MVP)

- FR18: Terminal panel can display a styled placeholder indicating future xterm.js + tmux integration
- FR19: Code editor panel can display a styled placeholder indicating future code-server integration
- FR20: Playbook dashboard panel can display a styled placeholder indicating future playbook session viewer
- FR21: AI chat panel can display a styled placeholder indicating future conversational AI interface
- FR22: AI assistant overlay can display a styled placeholder indicating future hover-accessible AI helper

### Responsive Layout

- FR23: User can access full sidebar + multi-panel layout on desktop viewports (≥1024px)
- FR24: User can access collapsed sidebar via hamburger menu on mobile viewports (<1024px)
- FR25: User can view vertically stacked panels on mobile viewports

## Non-Functional Requirements

### Performance

- NFR1: `npx kai-ui` cold start completes in < 5 seconds (server start + browser open)
- NFR2: Page load on localhost completes in < 1 second
- NFR3: Session creation (including `playbook start` execution) completes in < 3 seconds
- NFR4: Panel switching and sidebar navigation respond in < 100ms
- NFR5: Responsive layout transitions (resize) are fluid with no visible jank

### Integration

- NFR6: Application executes `npx @tcanaud/playbook start` as a child process and captures stdout/stderr for status feedback
- NFR7: Application reads worktree session state from the filesystem (`.playbooks/sessions/`) without caching (always fresh)
- NFR8: Panel component interface is stable and documented — replacing a placeholder with a real implementation requires only swapping the component, no layout changes
- NFR9: Future xterm.js integration requires WebSocket support from the Next.js server (architecture must not preclude this)

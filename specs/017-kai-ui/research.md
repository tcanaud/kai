# Research: Kai UI

**Feature**: 017-kai-ui | **Date**: 2026-02-19

## R1: Next.js App Router for Local-Only SPA

**Decision**: Use Next.js 14+ with App Router in SPA mode (client-side rendering only)

**Rationale**: Next.js provides the fastest path to a working React application with built-in API routes, file-based routing, and TypeScript support. App Router is the current standard. Since this is local-only, SSR/SSG is unnecessary — all pages use `"use client"` directives.

**Alternatives considered**:
- Vite + React: Lighter, but no built-in API routes — would need Express or similar for session management
- Remix: Overkill for local-only tool, SSR-focused
- Plain React: No dev server, no API routes, more manual setup

## R2: shadcn/ui + Tailwind CSS for Cyberpunk Design System

**Decision**: Use shadcn/ui as the component library with Tailwind CSS for styling. Customize the theme with cyberpunk color palette (cyan/magenta/violet on dark backgrounds) and glow effect utilities.

**Rationale**: shadcn/ui components are copy-pasted into the project (not an npm dependency at runtime), making them fully customizable. Tailwind's utility classes enable rapid iteration on the cyberpunk aesthetic. Custom CSS variables define the neon color palette; `box-shadow` utilities create glow effects.

**Alternatives considered**:
- Radix + custom CSS: More work, shadcn/ui already wraps Radix
- Material UI: Wrong aesthetic, hard to customize for cyberpunk
- Chakra UI: Decent theming but heavier, less control over glow effects

## R3: Panel Architecture — Pluggable Component Interface

**Decision**: Each panel slot accepts a React component that implements a `PanelProps` interface. MVP panels are placeholder components. Replacing a placeholder with a real implementation means swapping the component import — no layout changes needed.

**Rationale**: The MVP is a skeleton. The entire point is that V1.1–V1.5 replace placeholders one by one. A clean component interface makes this possible without touching the layout system.

**Interface**:
```typescript
interface PanelProps {
  sessionId: string;
  isActive: boolean;
  onResize?: (width: number, height: number) => void;
}
```

**Alternatives considered**:
- iframe-based panels: Too heavy, cross-origin issues with code-server later
- Web Components: Unnecessary abstraction for a React app
- Plugin system with dynamic imports: Over-engineered for MVP

## R4: Session Management via Filesystem

**Decision**: Sessions are read from `.playbooks/sessions/` directory on the filesystem. New sessions are created by executing `npx @tcanaud/playbook start {playbook} {feature}` as a child process from a Next.js API route.

**Rationale**: Aligns with kai's "git is the database" philosophy. No separate state store. The playbook system already manages worktree creation — the UI is a thin wrapper.

**Alternatives considered**:
- SQLite for session state: Violates file-based philosophy
- In-memory session store: Lost on server restart
- `.kaiui/` custom state: Out of scope for MVP

## R5: CLI Launcher (`bin/cli.js`)

**Decision**: `bin/cli.js` validates the project root (checks for `.features/`), starts the Next.js dev server, and opens the default browser using `node:child_process`. The package is published as `@tcanaud/kai-ui` on npm.

**Rationale**: Follows kai's CLI entry point convention (conv-002). The launcher is a thin wrapper — Next.js handles the actual serving. Browser opening uses platform-specific `open` commands (macOS: `open`, Linux: `xdg-open`).

**Alternatives considered**:
- Electron wrapper: Massively over-engineered for a local web tool
- Custom HTTP server: Why rebuild what Next.js provides?

## R6: Responsive Layout Strategy

**Decision**: CSS-based responsive layout using Tailwind breakpoints. Desktop (≥1024px): sidebar visible + multi-panel grid. Mobile (<1024px): sidebar in hamburger overlay + vertically stacked panels. Panel resizing on desktop via CSS `resize` or a lightweight splitter.

**Rationale**: Pure CSS approach with Tailwind breakpoints is the simplest path. No JavaScript layout engine needed. The mobile layout stacks panels vertically — simple and readable for status checks.

**Alternatives considered**:
- react-resizable-panels: Good option for panel resizing, may adopt if CSS resize feels clunky
- CSS Grid with `fr` units: Good for initial layout, may need JS for drag-to-resize
- Allotment/react-split-pane: Dependencies for panel splitting — evaluate if simpler approaches fall short

## R7: Monospace Typography

**Decision**: Use JetBrains Mono (self-hosted in `public/fonts/`) as the monospace font for code content. System sans-serif for UI labels and navigation.

**Rationale**: JetBrains Mono is open source, widely used in developer tools, and has excellent readability. Self-hosting avoids external font CDN calls (local-only tool).

**Alternatives considered**:
- Fira Code: Good but JetBrains Mono has better ligature support
- System monospace stack: Inconsistent across platforms
- Berkeley Mono: Paid license

# Quickstart: Kai UI

**Feature**: 017-kai-ui | **Date**: 2026-02-19

## Prerequisites

- Node.js >= 18.0.0
- A kai-enabled project (has `.features/` directory)
- `@tcanaud/playbook` installed (for session creation)

## Development Setup

```bash
# Navigate to the package
cd packages/kai-ui

# Install dependencies
npm install

# Start the dev server
npm run dev
```

The application opens at `http://localhost:3000`.

## User-Facing Launch

```bash
# From any kai-enabled project root
npx @tcanaud/kai-ui
```

This validates the project root, starts the Next.js dev server, and opens the browser.

## Key Directories

| Path | Purpose |
|------|---------|
| `packages/kai-ui/` | Package root (git submodule) |
| `packages/kai-ui/bin/cli.js` | CLI entry point (`npx kai-ui`) |
| `packages/kai-ui/src/app/` | Next.js App Router pages and layouts |
| `packages/kai-ui/src/app/components/` | React components (sidebar, panels, layout) |
| `packages/kai-ui/src/app/api/` | Next.js API routes (session management) |
| `.playbooks/sessions/` | Session data source (read by API routes) |
| `.playbooks/playbooks/` | Available playbooks (read by API routes) |

## Architecture Notes

- **No database** — all data read from filesystem (`.playbooks/`)
- **No auth** — single user, local only
- **Pluggable panels** — each panel implements `PanelProps` interface, MVP uses placeholders
- **Cyberpunk theme** — CSS variables in `globals.css` define the color palette and glow effects

# kai Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-02-18

## Active Technologies
- File-based — YAML + Markdown in `.knowledge/` directory, tracked in gi (007-knowledge-system)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + Zero runtime dependencies — installer/updater package + Claude Code slash command templates (008-product-manager)
- File-based — `.product/` directory tree with YAML frontmatter + Markdown body files (008-product-manager)
- File-based — `.qa/` directory tree with YAML + Markdown artifacts, versioned in gi (009-qa-system)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports). External tool dependency: GitHub CLI (`gh`) for PR creation and merge detection. (010-feature-lifecycle-v2)
- File-based — YAML + Markdown in `.features/`, `.qa/`, `.product/`, `.agreements/`, `specs/` directories (010-feature-lifecycle-v2)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (`node:` protocol imports only). External tool dependencies: Git CLI, GitHub CLI (`gh`) for PR steps only, Claude Code CLI. (012-playbook-supervisor)
- File-based — `.playbooks/sessions/{id}/` with `session.yaml` + `journal.yaml`, git-tracked. (012-playbook-supervisor)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 (for the `@tcanaud/playbook` package changes only — installer/updater). The slash command itself is a Markdown prompt executed by Claude Code. + None — zero runtime dependencies (`node:` protocol imports only). The slash command template relies on Claude Code's built-in capabilities (file reading, writing, Bash tool for `npx @tcanaud/playbook check`). (013-playbook-create)
- File-based — generated playbooks written to `.playbooks/playbooks/{name}.yaml`, index updated at `.playbooks/_index.yaml`. (013-playbook-create)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None -- zero runtime dependencies (`node:` protocol imports only) (014-playbook-step-model)
- File-based -- `.playbooks/playbooks/*.yaml` (playbook definitions), `.playbooks/sessions/` (session state) (014-playbook-step-model)
- TypeScript (Next.js 14+ with App Router), Node.js >= 18.0.0 + Next.js, React, shadcn/ui, Tailwind CSS, Lucide React (icons) (017-kai-ui)
- Filesystem only — reads `.playbooks/sessions/` for session state, no database (017-kai-ui)

- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports) (006-tcsetup-update)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Node.js ESM (`"type": "module"`), Node >= 18.0.0

## Code Style

Node.js ESM (`"type": "module"`), Node >= 18.0.0: Follow standard conventions

## Recent Changes
- 017-kai-ui: Added TypeScript (Next.js 14+ with App Router), Node.js >= 18.0.0 + Next.js, React, shadcn/ui, Tailwind CSS, Lucide React (icons)
- 014-playbook-step-model: Added Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None -- zero runtime dependencies (`node:` protocol imports only)
- 013-playbook-create: Added Node.js ESM (`"type": "module"`), Node >= 18.0.0 (for the `@tcanaud/playbook` package changes only — installer/updater). The slash command itself is a Markdown prompt executed by Claude Code. + None — zero runtime dependencies (`node:` protocol imports only). The slash command template relies on Claude Code's built-in capabilities (file reading, writing, Bash tool for `npx @tcanaud/playbook check`).


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

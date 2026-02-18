# kai Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-02-18

## Active Technologies
- File-based — YAML + Markdown in `.knowledge/` directory, tracked in gi (007-knowledge-system)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + Zero runtime dependencies — installer/updater package + Claude Code slash command templates (008-product-manager)
- File-based — `.product/` directory tree with YAML frontmatter + Markdown body files (008-product-manager)
- File-based — `.qa/` directory tree with YAML + Markdown artifacts, versioned in gi (009-qa-system)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports). External tool dependency: GitHub CLI (`gh`) for PR creation and merge detection. (010-feature-lifecycle-v2)
- File-based — YAML + Markdown in `.features/`, `.qa/`, `.product/`, `.agreements/`, `specs/` directories (010-feature-lifecycle-v2)

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
- 010-feature-lifecycle-v2: Added Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports). External tool dependency: GitHub CLI (`gh`) for PR creation and merge detection.
- 009-qa-system: Added Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports)
- 008-product-manager: Added Node.js ESM installer/updater package + 6 Claude Code slash command templates + `.product/` filesystem-as-state


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

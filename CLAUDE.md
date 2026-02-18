# kai Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-02-18

## Active Technologies
- File-based — YAML + Markdown in `.knowledge/` directory, tracked in gi (007-knowledge-system)
- Node.js ESM (`"type": "module"`), Node >= 18.0.0 + Zero runtime dependencies — installer/updater package + Claude Code slash command templates (008-product-manager)
- File-based — `.product/` directory tree with YAML frontmatter + Markdown body files (008-product-manager)

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
- 008-product-manager: Added Node.js ESM installer/updater package + 6 Claude Code slash command templates + `.product/` filesystem-as-state
- 007-knowledge-system: Added Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports)

- 006-tcsetup-update: Added Node.js ESM (`"type": "module"`), Node >= 18.0.0 + None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

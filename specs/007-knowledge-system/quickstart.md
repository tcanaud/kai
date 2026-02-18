# Quickstart: 007-knowledge-system

**Date**: 2026-02-18
**Branch**: `007-knowledge-system`

## Setup

```bash
# From kai repo root, install the package locally
npm install ./packages/knowledge-system

# Initialize the knowledge directory
npx @tcanaud/knowledge-system init

# Generate initial snapshot and index from existing artifacts
npx @tcanaud/knowledge-system refresh
```

## Directory Created

```
.knowledge/
├── config.yaml          # Edit to customize source paths and thresholds
├── index.yaml           # Auto-generated — do not edit manually
├── architecture.md      # Edit this — your project's macro overview
├── snapshot.md          # Auto-generated — do not edit manually
└── guides/              # Create guides here
```

## Core Workflow

### Query knowledge

```
/k how do I release a package?
```

Returns an assembled answer with sources tagged VERIFIED or STALE.

### Create a guide

```
/knowledge.create "How to add a new package"
```

Creates a guide skeleton in `.knowledge/guides/` with proper frontmatter.

### Refresh index and snapshot

```
/knowledge.refresh
```

Regenerates `snapshot.md` and `index.yaml` from current project artifacts.

### Check guide freshness

```
/knowledge.check
```

Reports which guides are VERIFIED and which are STALE.

## CLI Commands

| Command | Description |
|---------|-------------|
| `npx @tcanaud/knowledge-system init` | Scaffold `.knowledge/` directory |
| `npx @tcanaud/knowledge-system update` | Refresh command templates |
| `npx @tcanaud/knowledge-system refresh` | Regenerate snapshot + index |
| `npx @tcanaud/knowledge-system check` | Verify guide freshness |
| `npx @tcanaud/knowledge-system help` | Show help |

## Claude Code Commands

| Command | Description |
|---------|-------------|
| `/k <question>` | Query knowledge base with verified answers |
| `/knowledge.refresh` | Refresh snapshot and index |
| `/knowledge.check` | Check all guides for freshness |
| `/knowledge.create <topic>` | Create a new knowledge guide |

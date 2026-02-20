# Quickstart: @tcanaud/kai-product

**Feature**: 018-cli-kai-product | **Date**: 2026-02-20

This guide covers how to set up, run, and test the `@tcanaud/kai-product` package during development.

---

## Repository Setup

The package lives at `packages/kai-product/` in the kai monorepo.

```bash
# From the repo root
cd /path/to/kai

# Verify the package exists
ls packages/kai-product/
```

---

## Package Initialization

```bash
cd packages/kai-product

# No npm install needed — zero runtime dependencies
# Verify entry point works
node bin/cli.js help
```

Expected output:
```
kai-product — Atomic CLI for kai product operations.

Usage:
  npx @tcanaud/kai-product init       Scaffold .product/ directory and install slash commands
  npx @tcanaud/kai-product update     Refresh slash commands
  npx @tcanaud/kai-product reindex    Regenerate index.yaml from filesystem scan
  npx @tcanaud/kai-product move       Move backlog item(s) to a new status
  npx @tcanaud/kai-product check      Check product directory integrity
  npx @tcanaud/kai-product promote    Promote a backlog item to a feature
  npx @tcanaud/kai-product triage     Triage new feedbacks
  npx @tcanaud/kai-product help       Show this help
```

---

## Running Tests

```bash
# From packages/kai-product/
node --test tests/unit/yaml-parser.test.js
node --test tests/unit/scanner.test.js
node --test tests/unit/index-writer.test.js

# Integration tests
node --test tests/integration/reindex.test.js
node --test tests/integration/move.test.js
node --test tests/integration/check.test.js
node --test tests/integration/promote.test.js
node --test tests/integration/triage.test.js

# Run all tests at once
node --test tests/**/*.test.js
```

---

## Usage Against the Live .product/ Directory

```bash
# From the repo root (so .product/ is found via cwd)

# Regenerate the index from filesystem
node packages/kai-product/bin/cli.js reindex

# Move a backlog item
node packages/kai-product/bin/cli.js move BL-007 done

# Bulk move
node packages/kai-product/bin/cli.js move BL-001,BL-002,BL-003 done

# Check integrity
node packages/kai-product/bin/cli.js check

# Check with JSON output
node packages/kai-product/bin/cli.js check --json

# Promote a backlog to a feature
node packages/kai-product/bin/cli.js promote BL-007

# Get triage plan (read-only, outputs JSON)
node packages/kai-product/bin/cli.js triage --plan

# Apply a triage plan (after AI annotation)
node packages/kai-product/bin/cli.js triage --apply /tmp/triage-plan.json
```

---

## Creating a Test Fixture

For integration tests, use `node:os` `tmpdir()` to create isolated fixtures:

```js
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

function createFixture() {
  const root = mkdtempSync(join(tmpdir(), "kai-product-test-"));
  const product = join(root, ".product");

  // Create directory structure
  for (const status of ["new", "triaged", "excluded", "resolved"]) {
    mkdirSync(join(product, "feedbacks", status), { recursive: true });
  }
  for (const status of ["open", "in-progress", "done", "promoted", "cancelled"]) {
    mkdirSync(join(product, "backlogs", status), { recursive: true });
  }

  // Seed a backlog file
  writeFileSync(join(product, "backlogs", "open", "BL-001.md"), `---
id: "BL-001"
title: "Test backlog item"
status: "open"
category: "new-feature"
priority: "high"
created: "2026-02-20"
updated: "2026-02-20"
owner: ""
feedbacks: []
features: []
tags: []
promotion:
  promoted_date: ""
  feature_id: ""
cancellation:
  cancelled_date: ""
  reason: ""
---

Test body.
`);

  return { root, product };
}
```

---

## Key Module Interfaces

### `src/scanner.js`

```js
// Scan .product/ and return all entities
scanProduct(productDir: string): Promise<{
  feedbacks: Feedback[],
  backlogs: Backlog[]
}>

// Find a specific backlog by ID (searches all status subdirs)
findBacklog(productDir: string, id: string): Promise<Backlog | null>

// Find a specific feedback by ID
findFeedback(productDir: string, id: string): Promise<Feedback | null>
```

### `src/yaml-parser.js`

```js
// Parse a .md file with YAML frontmatter + body
parseFrontmatter(fileContent: string): { frontmatter: object, body: string }

// Serialize frontmatter back to YAML string (for writing)
serializeFrontmatter(frontmatter: object): string
```

### `src/index-writer.js`

```js
// Regenerate index.yaml from scanned data
writeIndex(productDir: string, feedbacks: Feedback[], backlogs: Backlog[]): Promise<void>
```

### `src/commands/move.js`

```js
// Main entry point for move command
move(args: string[], options: { productDir?: string }): Promise<void>
// args[0]: comma-separated IDs, args[1]: target status
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KAI_PRODUCT_DIR` | `{cwd}/.product` | Override the product directory path (useful for testing) |

---

## Publishing

The package follows `@tcanaud/playbook` trusted publishing via GitHub Actions. No manual `npm publish` needed.

```bash
# Bump version in packages/kai-product/package.json
# Commit and push — CI handles npm publish
```

---

## Slash Commands (installed by `init`)

After running `kai-product init` in a kai project, the following slash commands become available in Claude Code:

| Command | Description |
|---------|-------------|
| `/product.reindex` | Regenerate index.yaml |
| `/product.move` | Move backlog items |
| `/product.check` | Check integrity |
| `/product.promote` | Promote backlog to feature |
| `/product.triage` | AI-assisted triage of new feedbacks |

These are Markdown prompt templates stored in `.claude/commands/` that invoke the CLI via Bash tool calls.

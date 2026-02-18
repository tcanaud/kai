# Implementation Plan: Verified Knowledge System

**Branch**: `007-knowledge-system` | **Date**: 2026-02-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/007-knowledge-system/spec.md`

## Summary

A verified knowledge system that applies the Agreement pattern to project documentation. Three-layer architecture (stable architecture.md / semi-stable guides / volatile snapshot), with freshness verification via git log timestamps and watched_paths. CLI handles deterministic operations (init, update, refresh, check); Claude Code commands handle AI-dependent workflows (semantic query `/k`, guide creation).

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports)
**Storage**: File-based — YAML + Markdown in `.knowledge/` directory, tracked in git
**Testing**: Node.js built-in test runner (`node --test`)
**Target Platform**: CLI (npx) + Claude Code slash commands
**Project Type**: Single package (git submodule in kai monorepo)
**Performance Goals**: `refresh` and `check` complete in under 2 seconds for projects with <50 guides
**Constraints**: Zero runtime dependencies (conv-001), file-based artifacts (conv-003), Claude Code as primary AI interface (conv-005)
**Scale/Scope**: ~10-50 guides per project, 5-20 conventions, 5-20 ADRs, 5-20 features

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is in template state (not yet customized for kai). Applying kai conventions as effective constitution:

| Gate | Status | Evidence |
|------|--------|----------|
| conv-001: ESM + zero deps | PASS | Only `node:` built-in imports |
| conv-002: CLI entry structure | PASS | `bin/cli.js` switch/case router |
| conv-003: File-based artifacts | PASS | All state in `.knowledge/` as YAML/Markdown |
| conv-004: Submodule package | PASS | `packages/knowledge-system/` as git submodule |
| conv-005: Claude Code commands | PASS | 4 slash commands as markdown templates |
| conv-006: Trusted publishing | PASS | Same GitHub Actions OIDC pattern |

No violations. No complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/007-knowledge-system/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research findings
├── data-model.md        # Entity definitions and schemas
├── quickstart.md        # Setup and usage guide
├── contracts/
│   └── cli.md           # CLI interface contract
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
packages/knowledge-system/
├── bin/
│   └── cli.js                  # CLI router: init, update, refresh, check, help
├── src/
│   ├── initializer.js          # Scaffold .knowledge/ directory
│   ├── updater.js              # Refresh command templates only
│   ├── refresher.js            # Regenerate snapshot.md + rebuild index.yaml
│   ├── checker.js              # Verify guide freshness via git log
│   ├── detect.js               # Detect environment (BMAD, SpecKit, etc.)
│   ├── config.js               # Read .knowledge/config.yaml
│   ├── frontmatter.js          # Parse YAML frontmatter from markdown
│   └── scanners/
│       ├── index.js            # Export all scanners
│       ├── guides.js           # Scan .knowledge/guides/*.md
│       ├── conventions.js      # Scan .agreements/conv-* for conventions
│       ├── adrs.js             # Scan .adr/ for ADR summaries
│       └── features.js         # Scan .features/ for feature dashboard
├── templates/
│   ├── core/
│   │   ├── config.yaml         # Default configuration template
│   │   ├── index.yaml          # Empty index template
│   │   ├── architecture.md     # Scaffold for human-curated overview
│   │   └── guide.tpl.md        # Guide template with frontmatter
│   └── commands/
│       ├── k.md                # /k query command
│       ├── knowledge.refresh.md
│       ├── knowledge.check.md
│       └── knowledge.create.md
├── tests/
│   ├── initializer.test.js
│   ├── refresher.test.js
│   ├── checker.test.js
│   ├── frontmatter.test.js
│   └── scanners/
│       ├── guides.test.js
│       ├── conventions.test.js
│       ├── adrs.test.js
│       └── features.test.js
└── package.json
```

**Structure Decision**: Single package following the established kai submodule pattern. Source organized by responsibility: CLI routing → orchestrators (initializer, updater, refresher, checker) → shared utilities (detect, config, frontmatter) → scanners. This mirrors feature-lifecycle's structure.

## Design Decisions

### D1: CLI Subcommands

The CLI exposes 5 subcommands beyond the standard init/update/help:

| Command | Type | Description |
|---------|------|-------------|
| `init` | Standard | Scaffold `.knowledge/` |
| `update` | Standard | Refresh command templates |
| `refresh` | New | Regenerate snapshot + index |
| `check` | New | Verify guide freshness |
| `help` | Standard | Show help |

`refresh` and `check` are CLI (not just Claude commands) because they are deterministic and testable. Claude commands wrap them for convenience.

### D2: Scanner Architecture

Four scanners, each reading one artifact source:

| Scanner | Source | Extracts |
|---------|--------|----------|
| `guides.js` | `.knowledge/guides/*.md` | id, title, path, topics, last_verified, watched_paths |
| `conventions.js` | `.agreements/conv-*/agreement.yaml` | id, title, path, intent (as summary) |
| `adrs.js` | `.adr/{global,domain,local}/*.md` | id, title, path, status |
| `features.js` | `.features/*/feature.yaml` | id, title, path, stage |

Each scanner returns an array of entries with uniform shape: `{ id, title, path, summary, topics, status }`.

### D3: Freshness Check Algorithm

```
For each guide in .knowledge/guides/:
  1. Parse YAML frontmatter
  2. If no watched_paths → status = "unknown"
  3. For each path in watched_paths:
     a. If path doesn't exist → stale (deleted)
     b. Run: git log -1 --format=%aI -- <path>
     c. If last_modified > last_verified → stale (modified)
  4. For each ref in references.conventions/adrs:
     a. If referenced artifact doesn't exist → stale (orphaned ref)
     b. If ADR status is "superseded" → stale (superseded ref)
  5. If any stale signal → status = "stale" with details
  6. Otherwise → status = "verified"
```

### D4: Snapshot Template

```markdown
# Project Snapshot

> Auto-generated by knowledge-system refresh. Do not edit.
> Generated: {timestamp}

## Active Conventions

| ID | Title |
|----|-------|
| conv-001 | ESM-only, zero runtime dependencies |
| ... | ... |

## Architecture Decisions

| ID | Title | Status |
|----|-------|--------|
| 20260218-esm-only-zero-deps | ESM-only with zero runtime deps | accepted |
| ... | ... | ... |

## Feature Dashboard

| ID | Title | Stage |
|----|-------|-------|
| 001-adr-system | Architecture Decision Records | release |
| ... | ... | ... |

## Technology Stack

- **Runtime**: Node.js >= 18.0.0 (ESM)
- **Dependencies**: Zero runtime dependencies
- **Package Manager**: npm workspaces
- **Repository**: Git submodule monorepo
```

### D5: `/k` Command Design

The `/k` slash command is a Claude Code prompt template that:

1. Reads `.knowledge/index.yaml` to get the full catalog
2. Matches the user's question against entry titles, summaries, and topics
3. Identifies the most relevant sources (guides first, then conventions/ADRs)
4. For each relevant guide: reads the file, checks freshness inline
5. Assembles an answer with:
   - Synthesized response from multiple sources
   - Source citations with VERIFIED/STALE tags
   - Warning if any source is stale
   - Suggestion to create a guide if no relevant sources found

The intelligence is in Claude's semantic matching — the index just provides the catalog.

### D6: `/knowledge.create` Command Design

The `/knowledge.create` slash command:

1. Takes a topic as argument
2. Generates a slug from the topic (e.g., "How to release a package" → `release-package`)
3. Checks if a guide with that slug already exists
4. Creates guide from template with pre-populated frontmatter
5. AI fills in the content body based on the topic and project context
6. Sets `last_verified` to current date
7. Suggests relevant `watched_paths` based on the topic and files explored

## Integration Points

### tcsetup Integration

- **installer.js**: Add step `{ name: "Knowledge System", flag: "--skip-knowledge", cmd: "npx @tcanaud/knowledge-system init" }`
- **updater.js**: Add tool `{ name: "Knowledge System", marker: ".knowledge", pkg: "@tcanaud/knowledge-system", cmd: "npx @tcanaud/knowledge-system update" }`
- **cli.js**: Update help text with `--skip-knowledge` flag

### Post-install Hook

After `tcsetup init` or `tcsetup update` runs knowledge-system, the updater should also call `refresh` to populate the initial snapshot:

```
npx @tcanaud/knowledge-system update && npx @tcanaud/knowledge-system refresh
```

### Read-only Access Pattern

The knowledge system reads from but never writes to:
- `.agreements/` (conventions + feature agreements)
- `.adr/` (architecture decision records)
- `.features/` (feature lifecycle manifests)
- `specs/` (SpecKit artifacts — for tech stack extraction)

## Constitution Re-check (Post-Design)

| Gate | Status | Evidence |
|------|--------|----------|
| conv-001: ESM + zero deps | PASS | All imports use `node:` prefix. No package.json dependencies. |
| conv-002: CLI entry structure | PASS | `bin/cli.js` with switch/case routing 5 subcommands |
| conv-003: File-based artifacts | PASS | All state in `.knowledge/` as YAML/Markdown files |
| conv-004: Submodule package | PASS | `packages/knowledge-system/` with own git repo |
| conv-005: Claude Code commands | PASS | 4 command templates: k.md, knowledge.refresh.md, knowledge.check.md, knowledge.create.md |
| conv-006: Trusted publishing | PASS | Same GitHub Actions OIDC pattern as other packages |

All gates pass. No violations to justify.

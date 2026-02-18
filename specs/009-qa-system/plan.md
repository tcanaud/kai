# Implementation Plan: QA System

**Branch**: `009-qa-system` | **Date**: 2026-02-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/009-qa-system/spec.md`

## Summary

The QA System closes the kai governance loop by generating executable test scripts from `spec.md` acceptance criteria and `agreement.yaml` interfaces, then executing them to produce a binary PASS/FAIL verdict. The implementation follows the established kai two-layer architecture: an npm package (`@tcanaud/qa-system`) providing installer, updater, and detect modules, paired with Claude Code slash command templates (`/qa.plan`, `/qa.run`, `/qa.check`) that are the sole interface. Test scripts are real file artifacts stored in `.qa/{feature}/scripts/`, indexed by `_index.yaml` with SHA-256 checksums for freshness tracking. Non-blocking findings flow into `.product/inbox/` using the product-manager feedback schema.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None — zero runtime dependencies (Node.js built-ins only via `node:` protocol imports)
**Storage**: File-based — `.qa/` directory tree with YAML + Markdown artifacts, versioned in git
**Testing**: `node --test` for package unit tests; generated test scripts adapt to target project's stack (discovered via `.knowledge/`)
**Target Platform**: CLI — npm package + Claude Code slash commands
**Project Type**: npm package (kai ecosystem module)
**Performance Goals**: First `/qa.plan` → `/qa.run` → verdict in a single Claude Code session
**Constraints**: Zero runtime dependencies; generated artifacts must be git-friendly (text-only, < 100KB each); freshness detection via SHA-256 checksums
**Scale/Scope**: 1-20 features per project, 5-30 test scripts per feature, 1 developer running QA at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution is not yet ratified (template only). Checking against established kai conventions instead:

| Convention | Rule | Status |
|-----------|------|--------|
| conv-001-esm-zero-deps | `"type": "module"` + zero runtime dependencies | PASS — Node.js built-ins only |
| conv-002-cli-entry-structure | `bin/cli.js` with switch/case dispatch to init/update/help | PASS — follows product-manager pattern |
| conv-004-submodule-packages | Independent git repo, submodule at `packages/qa-system/` | PASS — standard kai package |
| conv-005-claude-commands | Slash commands as `.md` files with YAML frontmatter | PASS — 3 commands: qa.plan, qa.run, qa.check |
| Git is the database | All state in git-tracked files | PASS — `.qa/` artifacts are plain text files |
| Prose interface | Claude Code slash commands as primary interface | PASS — no programmatic API |

**Gate result: PASS** — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/009-qa-system/
├── plan.md              # This file
├── research.md          # Phase 0: Decision rationale
├── data-model.md        # Phase 1: Entity schemas
├── quickstart.md        # Phase 1: Setup + usage guide
├── contracts/           # Phase 1: Interface contracts
│   ├── qa.plan.md       # /qa.plan command contract
│   ├── qa.run.md        # /qa.run command contract
│   └── qa.check.md      # /qa.check command contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2: Actionable tasks (created by /speckit.tasks)
```

### Source Code (repository root)

```text
packages/qa-system/
├── bin/
│   └── cli.js                    # Entry point: init | update | help
├── src/
│   ├── installer.js              # Scaffold .qa/, install commands
│   ├── updater.js                # Update commands + templates only
│   └── detect.js                 # Detect .qa/, .features/, .agreements/ presence
├── templates/
│   ├── core/
│   │   └── index.yaml            # _index.yaml template for .qa/{feature}/
│   └── commands/
│       ├── qa.plan.md            # /qa.plan slash command template
│       ├── qa.run.md             # /qa.run slash command template
│       └── qa.check.md           # /qa.check slash command template
├── .github/
│   └── workflows/
│       └── publish.yml           # npm trusted publishing (OIDC)
├── package.json
└── README.md
```

### Installed Output (target project)

```text
.qa/                              # Created by `npx @tcanaud/qa-system init`
├── {feature}/                    # One directory per feature (created by /qa.plan)
│   ├── _index.yaml               # Script-to-criterion mapping + checksums
│   └── scripts/                  # Generated test scripts
│       ├── test-{criterion}.sh   # Shell scripts (or .js, adapted to project)
│       └── ...
.claude/commands/
├── qa.plan.md                    # Installed by init/update
├── qa.run.md
└── qa.check.md
```

**Structure Decision**: Standard kai package layout (matching product-manager and knowledge-system). The `.qa/` directory is the sole user-facing artifact store. Per-feature subdirectories keep test plans isolated. The package itself contains only the installer/updater/detect modules and command templates — the slash commands drive all test generation and execution.

## Design Decisions

### D1: Slash Command Architecture — Three Commands

The QA system exposes exactly three slash commands:

| Command | Purpose | Reads | Writes |
|---------|---------|-------|--------|
| `/qa.plan {feature}` | Generate test scripts from spec + agreement | `.knowledge/`, `spec.md`, `agreement.yaml`, source code | `.qa/{feature}/scripts/`, `.qa/{feature}/_index.yaml` |
| `/qa.run {feature}` | Execute scripts, produce verdict | `.qa/{feature}/`, source code | stdout (verdict), `.product/inbox/` (findings) |
| `/qa.check` | Freshness scan across all features | `.qa/*/_index.yaml`, `spec.md`, `agreement.yaml` | stdout (report) |

**Rationale**: Mirrors the PRD's API surface exactly. Three distinct responsibilities with no overlap. Each command is stateless — reads filesystem, acts, writes results.

### D2: _index.yaml as Single Source of Truth

Each feature's test plan is anchored by `_index.yaml`, which stores:
- Script-to-criterion mappings (which script verifies which acceptance scenario)
- Source checksums (SHA-256 of `spec.md` and `agreement.yaml` at generation time)
- Generation timestamp
- Script metadata (filename, criterion reference, type)

**Rationale**: A single file provides both the traceability chain (reviewer reads this to understand coverage) and freshness tracking (checksums compared before execution). Avoids splitting metadata across multiple files.

**Alternatives rejected**:
- Embedded metadata in each script (comments/headers) — hard to scan cross-feature, unreliable to parse
- Separate checksums file — splits related data, two files to keep in sync

### D3: Freshness = SHA-256 Checksum Comparison

Before `/qa.run` executes, it computes SHA-256 of current `spec.md` and `agreement.yaml`, then compares against checksums stored in `_index.yaml`. Any mismatch → stale → refuse to run.

`/qa.check` performs the same comparison across all features for a batch freshness report.

**Rationale**: Simple, deterministic, zero-dependency. SHA-256 is available via `node:crypto`. Binary match/mismatch — no ambiguity.

**Accepted limitation**: Trivial changes (whitespace, comments) trigger false stale warnings. Accepted for MVP — content-aware diffing is a v2 optimization.

### D4: Script Generation — Claude Code as the Generator

The slash command `/qa.plan` is a Claude Code prompt template. When executed, Claude Code:
1. Reads `.knowledge/` to understand the project
2. Reads `spec.md` acceptance criteria
3. Reads `agreement.yaml` interfaces (if present)
4. Explores source code (entry points, modules)
5. Writes test scripts adapted to the project's conventions

The package does NOT contain script generation logic in Node.js. The slash command prompt IS the generation engine.

**Rationale**: Leverages Claude Code's ability to understand codebases and write idiomatic code. No need to build a template engine — the AI model IS the template engine, guided by `.knowledge/` context.

**Alternatives rejected**:
- Template-based generation (Mustache/EJS) — produces generic boilerplate, cannot adapt to project conventions
- AST-based generation — too complex, single-project assumption, fragile

### D5: Finding Deposit Format

Non-blocking findings from `/qa.run` are deposited in `.product/inbox/` as Markdown files with YAML frontmatter matching the product-manager feedback schema:

```yaml
---
id: "auto-assigned-by-product.intake"
title: "QA Finding: {brief description}"
category: "optimization"  # or "bug", "evolution"
source: "qa-system"
created: "{timestamp}"
linked_to:
  features: ["{feature-id}"]
---

**Test Script**: `.qa/{feature}/scripts/{script-name}`
**Criterion**: {acceptance criterion text}
**Result**: {observation}
**Severity**: non-blocking

{detailed description}
```

**Rationale**: Uses the existing product-manager format so `/product.triage` can process findings without modification. The `source: "qa-system"` field allows filtering QA-originated feedback.

### D6: Package Installer — Minimal Scaffold

The installer (`npx @tcanaud/qa-system init`) creates:
1. `.qa/` root directory (if not exists)
2. Copies slash command templates to `.claude/commands/`

It does NOT create per-feature directories — those are created by `/qa.plan` when the developer first generates a test plan for a feature.

**Rationale**: Minimizes upfront setup. The developer should not need to decide which features to QA at install time. Per-feature directories are created on demand.

### D7: No Results Directory in MVP

The PRD deferred structured `results/` persistence to Phase 2. In MVP, `/qa.run` outputs the verdict to stdout. The `_index.yaml` is not updated with run results.

**Rationale**: Follows the PRD's explicit MVP scoping. Stdout output is sufficient for the developer's immediate needs. Persistent results are a v1.1 feature.

## Integration Points

### tcsetup Integration

After qa-system is published, add entries to:

**`packages/tcsetup/src/installer.js`** — steps array:
```javascript
{ name: "QA System", flag: "--skip-qa", cmd: "npx @tcanaud/qa-system init --yes" }
```

**`packages/tcsetup/src/updater.js`** — TOOLS array:
```javascript
{ name: "QA System", marker: ".qa", pkg: "@tcanaud/qa-system", cmd: "npx @tcanaud/qa-system update" }
```

### product-manager Integration

`/qa.run` deposits findings in `.product/inbox/` using the feedback schema. No code changes needed in product-manager — the file format IS the integration contract.

### agreement-system Integration

`/qa.plan` reads `agreement.yaml` to generate interface compliance tests. `/qa.plan` prompt instructs Claude Code to run `/agreement.check {feature}` as a preliminary step. No code changes needed — the agreement files ARE the integration contract.

### knowledge-system Integration

`/qa.plan` reads `.knowledge/guides/` to understand project conventions. A new guide `qa-system.md` should be created in `.knowledge/guides/` documenting QA conventions for the project. No code changes needed in knowledge-system.

## Constitution Re-check (Post-Design)

| Convention | Status | Notes |
|-----------|--------|-------|
| conv-001-esm-zero-deps | PASS | Package uses `node:` imports only; SHA-256 via `node:crypto` |
| conv-002-cli-entry-structure | PASS | `bin/cli.js` → init/update/help dispatch |
| conv-004-submodule-packages | PASS | `packages/qa-system/` as git submodule |
| conv-005-claude-commands | PASS | 3 commands: qa.plan.md, qa.run.md, qa.check.md |
| Git is the database | PASS | `.qa/` artifacts are plain text, git-versioned |
| Prose interface | PASS | No programmatic API — slash commands only |

**Gate result: PASS** — design introduces no violations.

## Complexity Tracking

No violations to justify. The design follows established patterns with no deviations from kai conventions.

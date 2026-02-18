# Implementation Plan: kai Product Manager Module

**Branch**: `008-product-manager` | **Date**: 2026-02-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-product-manager/spec.md`

## Summary

The Product Manager module adds a `.product/` directory — the 8th dotfile in the kai governance stack — containing a file-based feedback intake system, AI-powered semantic triage, backlog management, and a feature promotion pipeline. The implementation has two layers:

1. **npm package** (`packages/product-manager/`) — an ESM-only, zero-dependency installer/updater that creates the `.product/` directory structure, copies templates, and installs the 6 slash commands. Follows the exact pattern of every other kai package (see `.knowledge/guides/create-new-package.md`).
2. **6 Claude Code slash commands** (`.claude/commands/product.*.md`) — Markdown prompt templates that Claude Code executes. These ARE the runtime — no binary, no process, no server.

The filesystem IS the state machine: directories represent statuses, `git mv` is a state transition, and `ls` is a query.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0 for the installer; Markdown for the slash commands
**Primary Dependencies**: Zero runtime dependencies — Node.js built-ins only via `node:` protocol imports
**Storage**: File-based — `.product/` directory tree with YAML frontmatter + Markdown body files
**Testing**: Manual validation via command execution + `/product.check` as self-testing mechanism
**Target Platform**: Any project using the kai governance stack with Claude Code
**Project Type**: npm package (installer/updater) + Claude Code slash command templates
**Performance Goals**: Dashboard < 5 seconds for 200 feedbacks; triage handles 30 items in a single session
**Constraints**: Zero runtime dependencies; all artifacts human-readable; git-native (every change is a diff)
**Scale/Scope**: Up to 200 feedbacks, 50 backlogs, 999 items per ID type (FB-xxx, BL-xxx)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution is not yet formalized, but the kai dogmas (from `.knowledge/guides/project-philosophy.md`) serve as the governing principles:

| Dogma | Status | Notes |
|-------|--------|-------|
| Git is the database | PASS | All state is files in git. `.product/` is a directory tree. |
| Drift is the enemy | PASS | `/product.check` implements drift detection for feedbacks and backlogs. |
| Zero dependencies | PASS | Installer uses `node:` built-ins only. Commands are Markdown templates. |
| The interface is prose | PASS | Claude Code slash commands (`.claude/commands/product.*.md`) are the UI. |
| Convention before code | PASS | Directory-as-status convention. Templates define schemas. No config.yaml needed. |

**Gate result: PASS** — no violations, no justifications needed.

## Project Structure

### Documentation (this feature)

```text
specs/008-product-manager/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── product.intake.md
│   ├── product.triage.md
│   ├── product.backlog.md
│   ├── product.promote.md
│   ├── product.check.md
│   └── product.dashboard.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
packages/product-manager/
├── bin/
│   └── cli.js                   # Entry point: npx product-manager init|update|help
├── src/
│   ├── installer.js             # init: create .product/, copy templates, install commands
│   ├── updater.js               # update: refresh commands/templates, preserve user data
│   ├── detect.js                # detect(.product/) marker directory presence
│   └── config.js                # read/generate config if needed (regex-based YAML)
├── templates/
│   ├── commands/                # Slash command templates (installed to .claude/commands/)
│   │   ├── product.intake.md
│   │   ├── product.triage.md
│   │   ├── product.backlog.md
│   │   ├── product.promote.md
│   │   ├── product.check.md
│   │   └── product.dashboard.md
│   └── core/                    # Directory structure + artifact templates
│       ├── feedback.tpl.md      # Feedback YAML frontmatter schema
│       ├── backlog.tpl.md       # Backlog item YAML frontmatter schema
│       └── index.yaml           # Initial empty index
├── package.json                 # ESM, zero deps, bin: product-manager
├── .github/
│   └── workflows/
│       └── publish.yml          # Trusted publishing via GitHub Actions
└── README.md
```

### Installed Output (target project)

```text
.claude/commands/
├── product.intake.md
├── product.triage.md
├── product.backlog.md
├── product.promote.md
├── product.check.md
└── product.dashboard.md

.product/
├── index.yaml               # Centralized index (feedbacks + backlogs registry)
├── _templates/
│   ├── feedback.tpl.md      # Feedback YAML frontmatter schema template
│   └── backlog.tpl.md       # Backlog item YAML frontmatter schema template
├── inbox/                   # Staging area for external tool drops
├── feedbacks/
│   ├── new/                 # Unprocessed feedbacks
│   ├── triaged/             # Analyzed, linked to backlog
│   ├── excluded/            # Rejected with reason
│   └── resolved/            # Problem solved
└── backlogs/
    ├── open/                # Planned, not started
    ├── in-progress/         # Being worked on
    ├── done/                # Completed
    ├── promoted/            # Became a full feature
    └── cancelled/           # Dropped
```

**Structure Decision**: Two-layer architecture following the kai package pattern. The npm package (`packages/product-manager/`) is the installer/updater — it scaffolds `.product/` and copies command templates. The slash commands (`.claude/commands/product.*.md`) are the runtime — Claude Code interprets them to operate on the filesystem. This is identical to how `adr-system`, `agreement-system`, `feature-lifecycle`, and `knowledge-system` packages work.

### tcsetup Integration

The package registers with tcsetup for unified installation:

**tcsetup installer.js** — add to `steps` array:
```js
{ name: "Product Manager", flag: "--skip-product", cmd: "npx product-manager init --yes" }
```

**tcsetup updater.js** — add to `TOOLS` array:
```js
{ name: "Product Manager", marker: ".product", pkg: "product-manager", cmd: "npx product-manager update" }
```

**tcsetup bin/cli.js** — add `--skip-product` to HELP text.

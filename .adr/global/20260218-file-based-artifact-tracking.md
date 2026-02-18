---
status: "accepted"
date: "2026-02-18"
deciders: "Thibaud Canaud"
tags: "architecture, state-management, artifacts"
scope:
  level: "global"
  domain: ""
  applies_to: ["**"]
relations:
  supersedes: []
  amends: []
  constrained_by:
    - "20260218-use-adr-system.md"
  related:
    - "20260218-claude-code-as-primary-ai-interface.md"
references:
  features:
    - "001-adr-system"
    - "002-agreement-system"
    - "003-feature-lifecycle"
    - "004-mermaid-workbench"
    - "005-tcsetup"
  agreements:
    - "conv-003-file-based-artifacts"
  speckit_research: []
---

# File-Based Artifact Tracking

## Context and Problem Statement

The kai toolchain manages several types of development artifacts: architecture decisions (ADRs), feature agreements, feature lifecycle state, and diagrams. We need to decide where and how this state is stored. The toolchain is designed for AI-assisted development workflows where agents need to read and write project state.

## Decision Drivers

- AI agents (Claude Code) must be able to read and write artifacts using standard file I/O
- All state changes must be visible in git diffs and pull requests
- No external service dependencies — the toolchain must work offline and in any environment
- Artifacts must be human-readable without special tooling
- Cross-referencing between artifact types (ADR references agreement, feature references ADR) must be possible

## Considered Options

- YAML/Markdown files in dotfile directories, versioned in git
- SQLite database in the repo
- External service (Notion, Confluence, or a custom API)
- JSON files in a single state directory

## Decision Outcome

Chosen option: "YAML/Markdown files in dotfile directories, versioned in git", because it makes all state transparent, diffable, and directly accessible to both humans and AI agents. Dotfile directories (.adr/, .agreements/, .features/) keep toolchain state visually separated from application code.

### Positive Consequences

- Every state change produces a git diff — full audit trail via version control
- AI agents read/write artifacts with standard file operations, no API integration needed
- Works fully offline with no external dependencies
- YAML and Markdown are universally understood formats
- Dotfile convention (.adr/, .agreements/, .features/) keeps toolchain state out of the way
- Cross-references are simple relative paths between files

### Negative Consequences

- No query engine — finding artifacts requires file scanning (glob + grep)
- Concurrent edits to the same YAML file can cause merge conflicts
- No schema validation at rest — malformed YAML is only caught when a tool reads it
- Index files (.agreements/index.yaml, .features/index.yaml) can drift from actual files on disk
- Large projects with many features could accumulate hundreds of artifact files

## Links

- Convention: [conv-003-file-based-artifacts](../../.agreements/conv-003-file-based-artifacts/agreement.yaml)
- Related: [Use Architecture Decision Records](20260218-use-adr-system.md) (constrains the ADR format within this file-based model)
- Related: [Claude Code as Primary AI Interface](20260218-claude-code-as-primary-ai-interface.md) (file-based model enables agent read/write)

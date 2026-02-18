---
status: "accepted"
date: "2026-02-18"
deciders: "Thibaud Canaud"
tags: "architecture, ai, developer-experience"
scope:
  level: "global"
  domain: ""
  applies_to: ["**"]
relations:
  supersedes: []
  amends: []
  constrained_by: []
  related:
    - "20260218-file-based-artifact-tracking.md"
references:
  features:
    - "001-adr-system"
    - "002-agreement-system"
    - "003-feature-lifecycle"
    - "004-mermaid-workbench"
    - "005-tcsetup"
  agreements:
    - "conv-005-claude-commands"
  speckit_research: []
---

# Claude Code as Primary AI Interface

## Context and Problem Statement

The kai toolchain needs a user interface for day-to-day development workflows: creating ADRs, checking agreement drift, tracking feature status, generating diagrams. We need to decide whether to build a custom UI, a traditional CLI with rich interactive prompts, or leverage an existing AI coding assistant.

## Decision Drivers

- The toolchain workflows are inherently language-heavy (writing decisions, defining agreements, describing features)
- AI assistants excel at generating structured content from natural-language prompts
- Building and maintaining a custom UI or rich CLI is costly for a small toolchain
- Claude Code already has file read/write capabilities and runs in the developer's terminal
- Slash commands (.claude/commands/*.md) provide a zero-code extension mechanism

## Considered Options

- Claude Code slash commands as the primary interface
- Custom interactive CLI (inquirer/prompts-based wizard)
- VS Code extension with webview panels
- Web-based dashboard application

## Decision Outcome

Chosen option: "Claude Code slash commands as the primary interface", because it leverages an AI assistant that can understand context, generate structured artifacts, and interact with the file-based state model directly. The slash command mechanism requires only Markdown prompt templates — no application code to build or maintain.

### Positive Consequences

- Zero application code for the user interface — commands are Markdown templates
- AI can understand project context and generate high-quality structured content
- Natural-language interaction is ideal for writing decisions, agreements, and feature descriptions
- Slash commands are discoverable (tab completion in Claude Code) and self-documenting
- Each package extends the command palette independently — composable toolchain

### Negative Consequences

- Hard dependency on Claude Code as the AI runtime — no fallback for non-Claude users
- Prompt templates are less deterministic than programmatic CLIs — output quality depends on the model
- No offline capability for the AI-assisted workflows (requires Claude API access)
- Debugging prompt issues is harder than debugging code
- Users without Claude Code access must manually create/edit YAML and Markdown files

## Links

- Convention: [conv-005-claude-commands](../../.agreements/conv-005-claude-commands/agreement.yaml)
- Related: [File-Based Artifact Tracking](20260218-file-based-artifact-tracking.md) (file-based model is what makes agent read/write possible)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)

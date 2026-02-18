# Data Model: tcsetup update command

**Feature**: 006-tcsetup-update | **Date**: 2026-02-18

## Entities

### ToolDefinition

Represents a TC stack sub-tool that tcsetup can detect and update.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Human-readable tool name (e.g., "ADR System") |
| marker | string or string[] | Filesystem path(s) to check for tool presence |
| pkg | string | npm package name (e.g., "adr-system") |
| cmd | string | Shell command to run for updating the tool |

**Validation rules**:
- `marker` must be a relative path from project root
- `pkg` must be a valid npm package name
- `cmd` must be a valid shell command

**Instances** (hardcoded array):

```
[
  { name: "ADR System",        marker: ".adr",                                          pkg: "adr-system",        cmd: "npx adr-system update" }
  { name: "Agreement System",  marker: ".agreements",                                   pkg: "agreement-system",  cmd: "npx agreement-system update" }
  { name: "Feature Lifecycle", marker: ".features",                                     pkg: "feature-lifecycle",  cmd: "npx feature-lifecycle update" }
  { name: "Mermaid Workbench", marker: ["_bmad/modules/mermaid-workbench", ".bmad/modules/mermaid-workbench"], pkg: "mermaid-workbench", cmd: "npx mermaid-workbench init" }
]
```

### CommandFile

Represents a Claude Code command file that tcsetup manages.

| Field | Type | Description |
|-------|------|-------------|
| filename | string | Name of the command file (e.g., "tcsetup.onboard.md") |
| source | string | Path relative to package root (`commands/`) |
| destination | string | Path relative to project root (`.claude/commands/`) |

**Instances** (hardcoded array):

```
[
  { filename: "tcsetup.onboard.md",  source: "commands/tcsetup.onboard.md",  destination: ".claude/commands/tcsetup.onboard.md" }
  { filename: "feature.workflow.md", source: "commands/feature.workflow.md", destination: ".claude/commands/feature.workflow.md" }
]
```

## Relationships

- **ToolDefinition → Marker Directory**: One-to-one (or one-to-many for mermaid-workbench). Existence of marker directory means tool is installed.
- **ToolDefinition → npm package**: One-to-one. Package is updated via `npm install {pkg}@latest`.
- **CommandFile → Project**: tcsetup copies its own command files to the project's `.claude/commands/` directory during both init and update.

## State Transitions

This feature has no persistent state. All state is derived from the filesystem at runtime:
- Tool installed? → marker directory exists
- Tool updated? → `npm install` and sub-tool update command succeed
- Commands refreshed? → files copied from package to project

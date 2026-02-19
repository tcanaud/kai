# Implementation Plan: /playbook.create Command for Custom Playbook Generation

**Branch**: `013-playbook-create` | **Date**: 2026-02-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-playbook-create/spec.md`

## Summary

The `/playbook.create` command is a new Claude Code slash command that generates custom playbooks adapted to the project where it runs. Given a free-text intention from the developer, it performs deep project analysis (detecting installed kai tools, scanning available slash commands, reading existing playbook patterns), then generates a valid playbook YAML file that uses only verified commands, follows project conventions, and passes the playbook validator. The command is delivered as a slash command template (`.claude/commands/playbook.create.md`) installed by the existing `@tcanaud/playbook` package, with no new runtime code — all generation logic is AI-driven within the Claude Code session.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0 (for the `@tcanaud/playbook` package changes only — installer/updater). The slash command itself is a Markdown prompt executed by Claude Code.
**Primary Dependencies**: None — zero runtime dependencies (`node:` protocol imports only). The slash command template relies on Claude Code's built-in capabilities (file reading, writing, Bash tool for `npx @tcanaud/playbook check`).
**Storage**: File-based — generated playbooks written to `.playbooks/playbooks/{name}.yaml`, index updated at `.playbooks/_index.yaml`.
**Testing**: `npx @tcanaud/playbook check` for schema validation of generated output. Manual validation via `/playbook.test` slash command for end-to-end testing.
**Target Platform**: Claude Code TUI — slash command interaction.
**Project Type**: Extension to existing `@tcanaud/playbook` package (new slash command template + installer/updater changes).
**Performance Goals**: N/A — interactive AI session, not a hot path.
**Constraints**: Generated playbooks must conform to the strict playbook schema (fixed vocabulary for autonomy, error_policy, conditions, escalation_triggers). Only slash commands verified to exist in `.claude/commands/` may be referenced. No feature-specific hardcoded values.
**Scale/Scope**: Single slash command. Generates one playbook per invocation.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is currently a template (unfilled). Checking against **established kai conventions** from snapshot and project philosophy instead:

| Convention | Status | Notes |
|-----------|--------|-------|
| conv-001: ESM-Only, Zero Deps | PASS | No new runtime dependencies. Slash command template is pure Markdown. Package changes (installer/updater) use only `node:` imports. |
| conv-002: Uniform CLI Entry Point | PASS | No new CLI command — existing `init`/`update` commands updated to include the new template. |
| conv-003: File-Based Artifacts | PASS | Generated playbooks are YAML files in `.playbooks/playbooks/`. Index is YAML file at `.playbooks/_index.yaml`. |
| conv-004: Submodule Package Isolation | PASS | Changes confined to existing `@tcanaud/playbook` package. No new package. |
| conv-005: Claude Code Slash Commands | PASS | `/playbook.create` follows the `{namespace}.{command}.md` convention. |
| conv-006: Trusted Publishing | PASS | Package update follows existing GitHub Actions workflow. |

| ADR | Status | Notes |
|-----|--------|-------|
| ESM-Only Zero Deps | PASS | No runtime dependencies added. |
| File-Based Artifact Tracking | PASS | Playbooks and index = files in git. |
| Git Submodule Monorepo | PASS | Changes in `packages/playbook` submodule. |
| Claude Code as Primary AI Interface | PASS | Slash command is the entire UI. Generation is AI-driven. |

No violations. No complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/013-playbook-create/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── playbook-create-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
packages/playbook/
├── bin/
│   └── cli.js                     # (existing, unchanged)
├── src/
│   ├── installer.js               # MODIFIED: add playbook.create.md to command installation
│   ├── updater.js                 # MODIFIED: add playbook.create.md to command update list
│   ├── detect.js                  # (existing, unchanged)
│   ├── validator.js               # (existing, unchanged)
│   ├── session.js                 # (existing, unchanged)
│   ├── worktree.js                # (existing, unchanged)
│   └── yaml-parser.js             # (existing, unchanged)
├── templates/
│   ├── commands/
│   │   ├── playbook.run.md        # (existing, unchanged)
│   │   ├── playbook.resume.md     # (existing, unchanged)
│   │   └── playbook.create.md     # NEW: /playbook.create slash command template
│   ├── core/
│   │   ├── _index.yaml            # (existing, unchanged)
│   │   └── playbook.tpl.yaml      # (existing, unchanged)
│   └── playbooks/
│       ├── auto-feature.yaml      # (existing, unchanged)
│       ├── auto-validate.yaml     # (existing, unchanged)
│       └── intention-to-pr.yaml   # (existing, unchanged)
├── tests/
│   ├── yaml-parser.test.js        # (existing, unchanged)
│   └── playbook-create.test.js    # NEW: tests for the generated output validation
├── package.json                   # MODIFIED: version bump
├── LICENSE
└── README.md                      # MODIFIED: document /playbook.create
```

**Installed artifacts** (after `npx @tcanaud/playbook init` or `update`):

```text
.claude/commands/
├── playbook.run.md                # (existing)
├── playbook.resume.md             # (existing)
├── playbook.test.md               # (existing)
└── playbook.create.md             # NEW: /playbook.create slash command
```

**Structure Decision**: No new package. The `/playbook.create` command is a slash command template (Markdown file) distributed by the existing `@tcanaud/playbook` package. All generation logic lives in the prompt — Claude Code performs the project analysis, intention parsing, YAML generation, validation, and file writing within the conversation. The only code changes are adding the template to the installer/updater file lists and writing the slash command prompt itself.

## Research Findings

### R1: Architecture — Slash Command Prompt vs. Node.js Code

**Decision**: The `/playbook.create` command is a **slash command prompt** (Markdown file), not Node.js code.

**Rationale**: Playbook generation requires understanding natural language intentions, analyzing project context, making design decisions about step ordering and autonomy levels, and engaging in interactive refinement with the developer. These are AI capabilities, not deterministic algorithms. The same pattern was established by the playbook supervisor (`/playbook.run`): the slash command prompt instructs Claude Code to follow a specific protocol.

The slash command prompt will instruct the AI to:
1. Scan the project structure using Bash and Read tools
2. Build a project context model
3. Parse the user's intention
4. Generate playbook YAML conforming to the schema
5. Validate via `npx @tcanaud/playbook check`
6. Present to user and iterate
7. Write to disk and update index

**Alternatives considered**:
- Node.js code that generates playbook YAML programmatically: rejected — cannot interpret natural language intentions, cannot make contextual decisions about autonomy levels, cannot engage in interactive refinement.
- Hybrid (Node.js project scanner + AI generation): rejected — unnecessary complexity. Claude Code can scan the project directly using its tools.

### R2: Project Analysis Strategy

**Decision**: The slash command performs project analysis in a structured sequence, building a "Project Context" as internal working state (not persisted).

**Analysis steps**:
1. **Tool Detection**: Check for marker directories (`.adr/`, `.agreements/`, `.features/`, `.knowledge/`, `.qa/`, `.product/`, `specs/`, `_bmad/`, `.playbooks/`)
2. **Command Discovery**: List all files in `.claude/commands/`, extract namespace.command patterns
3. **Existing Playbook Analysis**: Read all `.playbooks/playbooks/*.yaml`, extract patterns (autonomy conventions per command type, condition usage, error policy preferences, naming style)
4. **Convention Reading**: Scan `.knowledge/`, `CLAUDE.md` for project conventions and technology stack
5. **Available Conditions**: Filter the condition vocabulary based on which tools are installed (e.g., `qa_plan_exists` only if `.qa/` exists)

**Rationale**: Deep analysis is what differentiates this from a template copy. The project context model enables the AI to make informed decisions about which commands to include, which conditions to use, and which autonomy levels to assign.

### R3: Intention Parsing and Clarification

**Decision**: Free-text intention parsed by AI with up to 3 clarification questions before generating a first draft.

**Clarification triggers** (when to ask):
- Intention is fewer than 10 words and lacks specific action verbs (too vague)
- Intention references a workflow without a clear starting point or outcome
- Intention uses ambiguous terms that could map to multiple command sequences

**Clarification questions** (limited to 3):
1. "What triggers this workflow?" (starting condition)
2. "What is the expected outcome?" (success criteria)
3. "Which steps should require human approval?" (autonomy preferences)

**Rationale**: The spec requires max 3 clarification questions (FR-008). The AI should generate a first draft quickly and iterate, rather than interrogating the developer.

### R4: Playbook YAML Generation Strategy

**Decision**: Generate YAML as a string following the exact format of existing playbooks, then validate with `npx @tcanaud/playbook check`.

**Generation rules**:
1. **Name**: Derive lowercase slug from intention (e.g., "deploy hotfixes for critical bugs" -> `critical-hotfix-deploy`). Pattern: `[a-z0-9-]+`.
2. **Steps**: Map intention actions to available slash commands. Only commands verified in `.claude/commands/` may be used.
3. **Autonomy**: Follow patterns from existing playbooks. Default heuristics:
   - Validation/analysis steps: `auto`
   - Implementation steps: `auto` or `gate_on_breaking`
   - PR creation: `gate_always`
   - Destructive/irreversible steps: `gate_always`
4. **Conditions**: Use only conditions whose backing tools are installed.
5. **Error policies**: Follow existing playbook patterns. Default heuristics:
   - Critical steps (spec, plan): `stop`
   - Implementation: `retry_once`
   - Validation gates: `gate`
   - Final steps (PR): `stop`
6. **Arguments**: Always declare `feature` as required if any step references feature-specific artifacts. Use `{{arg}}` interpolation — never hardcode values.

**Validation loop**: After generating, run `npx @tcanaud/playbook check {file}` via Bash tool. If violations are found, fix and re-validate. This guarantees SC-002 (100% of generated playbooks pass the validator).

### R5: Interactive Refinement Protocol

**Decision**: After initial generation, present the playbook with rationale annotations and accept modification requests in a loop.

**Protocol**:
1. Display generated YAML with inline comments explaining each step choice
2. Ask: "Would you like to modify this playbook? (describe changes or 'done' to save)"
3. On modification request: update YAML, re-validate, re-present
4. On "done": write to disk, update index

**Modification types supported** (FR-022):
- Add step: user describes the action, AI maps to command and inserts at correct position
- Remove step: AI removes and warns about broken condition dependencies (FR-024)
- Change autonomy: direct update
- Change error policy: direct update
- Reorder steps: AI reorders and adjusts conditions
- Change name: re-validate slug pattern

### R6: Naming Conflict Resolution

**Decision**: Check for existing playbook with same name before writing. Offer overwrite / rename / cancel.

**Implementation**: Before writing, check if `.playbooks/playbooks/{name}.yaml` exists. If yes:
1. Report: "A playbook named '{name}' already exists."
2. Offer options: (1) Overwrite, (2) Choose a different name, (3) Cancel
3. If rename: prompt for new name, validate slug pattern, re-check for conflicts

### R7: Index Update Strategy

**Decision**: Regenerate index from filesystem if missing/corrupted, then add new entry.

**Implementation**:
1. Read `.playbooks/_index.yaml`
2. If file missing or parse error: scan `.playbooks/playbooks/*.yaml`, rebuild index
3. Add new entry with name, relative file path, description, step count
4. Update `generated` timestamp
5. Write back to `.playbooks/_index.yaml`

**Rationale**: The spec requires regeneration on corruption (FR-027). The filesystem-as-truth approach is consistent with kai's file-based philosophy.

## Data Model

See [data-model.md](./data-model.md) for complete entity definitions.

Key entities:
- **Project Context** (ephemeral, built during analysis): installed tools, available commands, existing playbook patterns, conventions, usable conditions
- **Generated Playbook** (output): YAML file conforming to the playbook schema at `.playbooks/playbooks/{name}.yaml`
- **Playbook Index** (updated): YAML file at `.playbooks/_index.yaml` with new entry

## Contracts

See [contracts/playbook-create-contract.md](./contracts/playbook-create-contract.md) for the complete contract.

### Slash Command Interface

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/playbook.create` | `$ARGUMENTS` (free-text intention) | Analyze project, generate playbook from intention, validate, refine interactively, write to disk |

### Input/Output Contract

**Input**: Free-text intention string (e.g., "validate and deploy a hotfix for critical bugs")

**Output**:
1. Generated playbook YAML file at `.playbooks/playbooks/{name}.yaml`
2. Updated index at `.playbooks/_index.yaml`
3. Validation report (pass/fail from `npx @tcanaud/playbook check`)

### Validation Contract

Generated playbooks must pass `npx @tcanaud/playbook check` with zero violations. This guarantees:
- All required top-level fields present (name, description, version, args, steps)
- Name matches `[a-z0-9-]+`
- At least one step
- Per step: id, command, autonomy, error_policy present
- Enum values from allowed vocabulary
- `{{arg}}` references match declared args
- Step IDs unique within playbook

## Quickstart

After implementation:

```bash
# 1. Update the playbook system to get the new command
npx @tcanaud/playbook update

# 2. In Claude Code, create a playbook from an intention:
/playbook.create validate and deploy a hotfix for critical bugs

# 3. Review the generated playbook, request modifications if needed

# 4. Validate the generated playbook independently:
npx @tcanaud/playbook check .playbooks/playbooks/critical-hotfix-deploy.yaml

# 5. Run the generated playbook:
/playbook.run critical-hotfix-deploy 013-my-feature
```

## Complexity Tracking

No constitution violations detected — no complexity tracking required.

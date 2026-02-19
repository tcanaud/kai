# Implementation Plan: Playbook Supervisor

**Branch**: `012-playbook-supervisor` | **Date**: 2026-02-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-playbook-supervisor/spec.md`

## Summary

The Playbook Supervisor is a new `@tcanaud/playbook` npm package that introduces YAML-driven orchestration for kai's feature workflow. A `/playbook.run` slash command reads a playbook definition, creates a persistent session, and delegates each step to a Task subagent with fresh context — while a `/playbook.resume` command enables crash recovery via git worktree detection and journal-based state. The package follows kai's established conventions: ESM-only, zero runtime dependencies, `node:` protocol imports, file-based state, and git as the database.

## Technical Context

**Language/Version**: Node.js ESM (`"type": "module"`), Node >= 18.0.0
**Primary Dependencies**: None — zero runtime dependencies (`node:` protocol imports only). External tool dependencies: Git CLI, GitHub CLI (`gh`) for PR steps only, Claude Code CLI.
**Storage**: File-based — `.playbooks/sessions/{id}/` with `session.yaml` + `journal.yaml`, git-tracked.
**Testing**: Node.js built-in `node:test` + `node:assert`
**Target Platform**: CLI — runs inside Claude Code TUI via slash commands + standalone via `npx`
**Project Type**: Single package (npm package with CLI entry point + slash command templates)
**Performance Goals**: N/A — orchestration layer, not a hot path. Steps execute sequentially via Task subagents.
**Constraints**: YAML parsing via regex only (no YAML library — kai convention). All playbook vocabulary (autonomy levels, error policies, escalation triggers, conditions) is a closed set — no free-text.
**Scale/Scope**: 2 built-in playbooks (auto-feature, auto-validate), extensible via user-authored YAML. Session count unbounded (unique IDs, no index bottleneck).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is currently a template (unfilled). Checking against **established kai conventions** from snapshot and project philosophy instead:

| Convention | Status | Notes |
|-----------|--------|-------|
| conv-001: ESM-Only, Zero Deps | PASS | Package uses only `node:` protocol imports |
| conv-002: Uniform CLI Entry Point | PASS | `bin/cli.js` with switch/case router |
| conv-003: File-Based Artifacts | PASS | Sessions stored as YAML files in `.playbooks/` |
| conv-004: Submodule Package Isolation | PASS | New `@tcanaud/playbook` package, independent git repo |
| conv-005: Claude Code Slash Commands | PASS | `/playbook.run` and `/playbook.resume` as `.claude/commands/*.md` |
| conv-006: Trusted Publishing | PASS | Standard GitHub Actions workflow |

| ADR | Status | Notes |
|-----|--------|-------|
| ESM-Only Zero Deps | PASS | No runtime dependencies |
| File-Based Artifact Tracking | PASS | Sessions, journals, playbooks = files in git |
| Git Submodule Monorepo | PASS | Package in `packages/playbook` |
| Claude Code as Primary AI Interface | PASS | Slash commands are the UI |

No violations. No complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/012-playbook-supervisor/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── playbook-schema.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
packages/playbook/
├── bin/
│   └── cli.js                     # CLI entry point: init, update, start, check, help
├── src/
│   ├── installer.js               # `init` — scaffold .playbooks/, copy templates
│   ├── updater.js                 # `update` — refresh slash commands only
│   ├── detect.js                  # Detect .playbooks/, .claude/commands/, git state
│   ├── validator.js               # `check` — validate playbook YAML against schema
│   ├── session.js                 # Session creation, ID generation, manifest/journal I/O
│   ├── worktree.js                # `start` — git worktree creation + session init
│   └── yaml-parser.js             # Regex-based YAML parser for playbook files
├── templates/
│   ├── commands/
│   │   ├── playbook.run.md        # /playbook.run slash command (supervisor prompt)
│   │   └── playbook.resume.md     # /playbook.resume slash command
│   ├── core/
│   │   ├── _index.yaml            # Playbook index template
│   │   └── playbook.tpl.yaml      # Commented template playbook
│   └── playbooks/
│       ├── auto-feature.yaml      # Built-in: plan → tasks → agreement → implement → QA → PR
│       └── auto-validate.yaml     # Built-in: qa.plan → qa.run
├── tests/
│   ├── validator.test.js          # Schema validation tests
│   ├── session.test.js            # Session creation/resume tests
│   ├── yaml-parser.test.js        # YAML parsing tests
│   └── worktree.test.js           # Worktree creation tests
├── package.json
├── LICENSE
└── README.md
```

**Installed artifacts** (after `npx @tcanaud/playbook init`):

```text
.playbooks/
├── _index.yaml                    # Index of available playbooks
├── playbooks/
│   ├── auto-feature.yaml          # Built-in playbook
│   ├── auto-validate.yaml         # Built-in playbook
│   └── playbook.tpl.yaml          # Template for custom playbooks
├── sessions/                      # Runtime — created per playbook run
│   └── {timestamp}-{3char}/
│       ├── session.yaml           # Session manifest
│       └── journal.yaml           # Step-by-step execution log
└── templates/                     # Reserved for future use

.claude/commands/
├── playbook.run.md                # /playbook.run slash command
└── playbook.resume.md             # /playbook.resume slash command
```

**Structure Decision**: Single package following the established kai pattern (see `@tcanaud/product-manager`, `@tcanaud/qa-system`). The package ships CLI commands (`init`, `update`, `start`, `check`) and slash command templates. The supervisor logic lives entirely in the `/playbook.run` slash command prompt — it orchestrates via Claude Code's Task tool, not via Node.js code. The Node.js code handles scaffolding, validation, worktree creation, and session file I/O.

## Research Findings

### R1: Supervisor Architecture — Prompt vs. Code

**Decision**: The supervisor is a **slash command prompt**, not Node.js code.

**Rationale**: The supervisor must call Claude Code's Task tool to delegate steps as subagents. The Task tool is only available inside Claude Code's conversation context. A Node.js process cannot invoke Task subagents. Therefore, the orchestration loop (read playbook → evaluate precondition → delegate step → evaluate postcondition → log journal → decide next) must execute as a Claude Code slash command that instructs the AI to follow the playbook.

**Alternatives considered**:
- Node.js orchestrator calling `claude` CLI in subprocess → rejected: no Task tool access, no gate interaction in TUI
- MCP server → rejected: over-engineering, no existing pattern in kai

### R2: YAML Parsing Strategy

**Decision**: Regex-based parser specialized for the playbook schema.

**Rationale**: kai convention (conv-001, ADR esm-only-zero-deps) forbids runtime dependencies. The playbook schema is a fixed, known structure — not arbitrary YAML. A targeted regex parser that understands the specific fields (steps, autonomy, conditions, etc.) is more reliable than a general-purpose regex YAML parser.

**Approach**: The parser validates structure during parsing — invalid fields are rejected at parse time. The `check` command uses the same parser, so validation and execution share one code path.

**Alternatives considered**:
- General-purpose regex YAML parser → rejected: fragile on edge cases, harder to maintain
- JSON format for playbooks → rejected: YAML is more readable for the target use case (declarative step definitions with comments)

### R3: Session ID Generation

**Decision**: `{YYYYMMDD}-{3-char-random}` format (e.g., `20260219-a7k`).

**Rationale**: Timestamp prefix enables chronological ordering by `ls`. 3-character alphanumeric suffix provides ~46,000 combinations per day — sufficient for a solo/small-team tool. Collision check: if directory exists, regenerate suffix (max 3 retries).

**Alternatives considered**:
- UUID → rejected: too long for directory names, not human-readable
- Sequential counter → rejected: requires centralized state, breaks in worktree parallelism

### R4: Worktree Session Discovery for `/playbook.resume`

**Decision**: Use `git worktree list` to identify current worktree, then scan `.playbooks/sessions/` for the most recent session with status `in_progress`.

**Rationale**: The resume command must be argumentless. The worktree path encodes no session info — sessions are discovered by scanning the sessions directory for the latest in-progress manifest. In a worktree, `.playbooks/` is shared (same git tree), so the supervisor reads all sessions and picks the one matching the current working context.

**Approach**:
1. Check if current directory is a git worktree via `git rev-parse --show-toplevel` and `git worktree list`
2. Scan `.playbooks/sessions/*/session.yaml` for `status: in_progress`
3. If multiple in-progress sessions exist: pick the most recent by timestamp prefix in session ID
4. If no in-progress session: report "no active session found"

### R5: Precondition/Postcondition Vocabulary

**Decision**: Fixed vocabulary of artifact checks, each mapping to a filesystem glob pattern.

| Condition ID | Check | Glob Pattern |
|-------------|-------|-------------|
| `spec_exists` | Spec file present | `specs/{feature}/spec.md` |
| `plan_exists` | Plan file present | `specs/{feature}/plan.md` |
| `tasks_exists` | Tasks file present | `specs/{feature}/tasks.md` |
| `agreement_exists` | Agreement created | `.agreements/{feature}/agreement.yaml` |
| `agreement_pass` | Agreement check passes | `.agreements/{feature}/check-report.md` contains `verdict: PASS` |
| `qa_plan_exists` | QA plan present | `.qa/{feature}/test-plan.md` |
| `qa_verdict_pass` | QA verdict is PASS | `.qa/{feature}/verdict.md` contains `verdict: PASS` |
| `pr_created` | PR exists for branch | `gh pr list --head {branch} --json number` returns non-empty |

**Rationale**: A closed vocabulary ensures deterministic evaluation. Every condition resolves to a boolean via filesystem check or command output. No free-text conditions — the playbook cannot express checks the supervisor doesn't know how to evaluate.

### R6: Parallel Phase Execution

**Decision**: Parallel phases use multiple Task tool calls in a single message.

**Rationale**: Claude Code's Task tool supports concurrent calls when included in the same message. The supervisor prompt instructs the AI: "For parallel phase, call all step subagents in a single message." The supervisor awaits all results before continuing.

**Constraint**: The maximum number of concurrent Task calls is bounded by Claude Code's implementation. Playbooks should keep parallel phases to 2-3 steps.

## Data Model

### Playbook Definition (`playbook.yaml`)

```yaml
name: "auto-feature"
description: "Full feature workflow from plan to PR"
version: "1.0"

args:
  - name: "feature"
    description: "Feature branch name (e.g., 012-playbook-supervisor)"
    required: true

steps:
  - id: "plan"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    preconditions:
      - "spec_exists"
    postconditions:
      - "plan_exists"
    error_policy: "stop"
    escalation_triggers: []

  - id: "tasks"
    command: "/speckit.tasks"
    args: ""
    autonomy: "auto"
    preconditions:
      - "plan_exists"
    postconditions:
      - "tasks_exists"
    error_policy: "stop"
    escalation_triggers: []

  - id: "agreement"
    command: "/agreement.create"
    args: "{{feature}}"
    autonomy: "auto"
    preconditions:
      - "tasks_exists"
    postconditions:
      - "agreement_exists"
    error_policy: "gate"
    escalation_triggers:
      - "subagent_error"

  - id: "implement"
    command: "/speckit.implement"
    args: ""
    autonomy: "auto"
    preconditions:
      - "agreement_exists"
    postconditions: []
    error_policy: "retry_once"
    escalation_triggers:
      - "postcondition_fail"
      - "subagent_error"

  - id: "agreement-check"
    command: "/agreement.check"
    args: "{{feature}}"
    autonomy: "gate_on_breaking"
    preconditions: []
    postconditions:
      - "agreement_pass"
    error_policy: "gate"
    escalation_triggers:
      - "agreement_breaking"

  - id: "qa-plan"
    command: "/qa.plan"
    args: "{{feature}}"
    autonomy: "auto"
    preconditions:
      - "agreement_pass"
    postconditions:
      - "qa_plan_exists"
    error_policy: "stop"
    escalation_triggers: []

  - id: "qa-run"
    command: "/qa.run"
    args: "{{feature}}"
    autonomy: "auto"
    preconditions:
      - "qa_plan_exists"
    postconditions:
      - "qa_verdict_pass"
    error_policy: "gate"
    escalation_triggers:
      - "verdict_fail"

  - id: "pr"
    command: "/feature.pr"
    args: "{{feature}}"
    autonomy: "gate_always"
    preconditions:
      - "qa_verdict_pass"
    postconditions:
      - "pr_created"
    error_policy: "stop"
    escalation_triggers: []
```

### Session Manifest (`session.yaml`)

```yaml
session_id: "20260219-a7k"
playbook: "auto-feature"
feature: "012-playbook-supervisor"
args:
  feature: "012-playbook-supervisor"
status: "in_progress"           # pending | in_progress | completed | failed | aborted
started_at: "2026-02-19T14:30:00Z"
completed_at: ""
current_step: "implement"
worktree: "../kai-session-20260219-a7k"   # empty if not using worktree
```

### Session Journal (`journal.yaml`)

```yaml
entries:
  - step_id: "plan"
    status: "done"              # done | failed | skipped | in_progress
    decision: "auto"            # auto | gate | escalated | skipped
    started_at: "2026-02-19T14:30:00Z"
    completed_at: "2026-02-19T14:31:15Z"
    duration_seconds: 75
    trigger: ""
    human_response: ""
    error: ""

  - step_id: "tasks"
    status: "done"
    decision: "auto"
    started_at: "2026-02-19T14:31:16Z"
    completed_at: "2026-02-19T14:31:50Z"
    duration_seconds: 34
    trigger: ""
    human_response: ""
    error: ""

  - step_id: "implement"
    status: "done"
    decision: "escalated"
    started_at: "2026-02-19T14:31:51Z"
    completed_at: "2026-02-19T14:43:00Z"
    duration_seconds: 669
    trigger: "postcondition_fail"
    human_response: "fixed test, continue"
    error: "test X failed after implementation"
```

### Playbook Index (`_index.yaml`)

```yaml
generated: "2026-02-19T14:00:00Z"
playbooks:
  - name: "auto-feature"
    file: "playbooks/auto-feature.yaml"
    description: "Full feature workflow from plan to PR"
    steps: 8
  - name: "auto-validate"
    file: "playbooks/auto-validate.yaml"
    description: "QA validation: plan and run"
    steps: 2
```

## Contracts

### CLI Commands (`npx @tcanaud/playbook`)

| Command | Arguments | Description | Exit Codes |
|---------|-----------|-------------|------------|
| `init` | `[--yes]` | Scaffold `.playbooks/` + install slash commands | 0=success, 1=error |
| `update` | | Refresh slash commands + playbook templates (not sessions) | 0=success, 1=no `.playbooks/` |
| `start` | `{playbook} {feature}` | Create session + git worktree + print instructions | 0=success, 1=dirty tree, 2=worktree error |
| `check` | `{file}` | Validate playbook YAML against schema | 0=valid, 1=invalid (prints violations) |
| `help` | | Show usage | 0 |

### Slash Commands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/playbook.run` | `{playbook} {feature}` | Launch supervisor: create session, execute steps, log journal |
| `/playbook.resume` | (none) | Auto-detect session, resume from last incomplete step |

### Playbook Schema (Fixed Vocabulary)

| Field | Type | Allowed Values |
|-------|------|---------------|
| `autonomy` | enum | `auto`, `gate_on_breaking`, `gate_always`, `skip` |
| `error_policy` | enum | `stop`, `retry_once`, `gate` |
| `escalation_triggers[]` | enum | `postcondition_fail`, `verdict_fail`, `agreement_breaking`, `subagent_error` |
| `preconditions[]` | enum | `spec_exists`, `plan_exists`, `tasks_exists`, `agreement_exists`, `agreement_pass`, `qa_plan_exists`, `qa_verdict_pass`, `pr_created` |
| `postconditions[]` | enum | Same as preconditions |

### Session Status Lifecycle

```
pending → in_progress → completed
                     → failed
                     → aborted
```

### Journal Entry Status

```
in_progress → done
            → failed
            → skipped (for autonomy: skip)
```

## Quickstart

After implementation:

```bash
# 1. Install the playbook system
npx @tcanaud/playbook init

# 2. Validate built-in playbooks
npx @tcanaud/playbook check .playbooks/playbooks/auto-feature.yaml
npx @tcanaud/playbook check .playbooks/playbooks/auto-validate.yaml

# 3. Run a feature workflow (in Claude Code TUI)
/playbook.run auto-feature 012-playbook-supervisor

# 4. Resume after crash
/playbook.resume

# 5. Parallel execution via worktree
npx @tcanaud/playbook start auto-feature 013-another-feature
# → Follow printed instructions to open Claude Code in the new worktree

# 6. Create a custom playbook
cp .playbooks/playbooks/playbook.tpl.yaml .playbooks/playbooks/my-workflow.yaml
# Edit the file, then validate:
npx @tcanaud/playbook check .playbooks/playbooks/my-workflow.yaml
```

## Complexity Tracking

No constitution violations detected — no complexity tracking required.

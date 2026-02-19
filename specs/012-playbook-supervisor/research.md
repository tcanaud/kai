# Research: Playbook Supervisor

**Branch**: `012-playbook-supervisor` | **Date**: 2026-02-19

## R1: Supervisor Architecture — Prompt vs. Code

**Decision**: The supervisor is a slash command prompt, not Node.js code.

**Rationale**: The supervisor must call Claude Code's Task tool to delegate steps as subagents. The Task tool is only available inside Claude Code's conversation context. A Node.js process cannot invoke Task subagents. Therefore, the orchestration loop (read playbook → evaluate precondition → delegate step → evaluate postcondition → log journal → decide next) must execute as a Claude Code slash command that instructs the AI to follow the playbook.

**Alternatives considered**:
- Node.js orchestrator calling `claude` CLI in subprocess → rejected: no Task tool access, no gate interaction in TUI, process management complexity
- MCP server → rejected: over-engineering, no existing pattern in kai, adds dependency

**Implications**:
- The `/playbook.run` slash command will be a comprehensive Markdown prompt (~200-300 lines) that instructs Claude Code how to orchestrate
- The Node.js package handles scaffolding, validation, worktree creation, and session file I/O — not orchestration
- Session state (journal, manifest) is read/written by Claude Code using Read/Write tools during the slash command execution

## R2: YAML Parsing Strategy

**Decision**: Regex-based parser specialized for the playbook schema.

**Rationale**: kai convention (conv-001, ADR esm-only-zero-deps) forbids runtime dependencies. The playbook schema is a fixed, known structure — not arbitrary YAML. A targeted regex parser that understands the specific fields is more reliable than a general-purpose regex YAML parser.

**Approach**:
- Parse top-level scalar fields (name, description, version) via simple key-value regex
- Parse `args` array via indentation-based block parsing
- Parse `steps` array via indentation-based block parsing with known field names
- Validate field values against the fixed vocabulary enums during parsing
- The `check` command uses the same parser — validation and execution share one code path

**Alternatives considered**:
- General-purpose regex YAML parser → rejected: fragile on edge cases, harder to maintain
- JSON format → rejected: YAML is more readable for declarative step definitions with comments
- TOML → rejected: no existing kai convention, less familiar to target users

## R3: Session ID Generation

**Decision**: `{YYYYMMDD}-{3-char-random}` format (e.g., `20260219-a7k`).

**Rationale**: Timestamp prefix enables chronological ordering by `ls`. 3-character lowercase alphanumeric suffix provides ~46,656 combinations per day (36^3). Collision handling: if directory exists, regenerate suffix (max 3 retries).

**Character set**: `a-z0-9` (36 chars). No uppercase to avoid case-sensitivity issues on macOS/Windows filesystems.

**Alternatives considered**:
- UUID → rejected: too long for directory names, not human-readable
- Sequential counter → rejected: requires centralized state, breaks in worktree parallelism
- Timestamp-only (second precision) → rejected: collisions possible if two sessions start in same second

## R4: Worktree Session Discovery for `/playbook.resume`

**Decision**: Scan `.playbooks/sessions/` for the most recent session with status `in_progress`.

**Approach**:
1. Run `git rev-parse --show-toplevel` to find the repo root (works in worktrees)
2. Scan `.playbooks/sessions/*/session.yaml` for `status: in_progress`
3. If multiple in-progress sessions: pick the most recent by timestamp prefix in session ID
4. If no in-progress session: report "no active session found"
5. Read the journal to determine the last completed step and resume from the next one

**Edge cases**:
- Worktree was deleted but session still marked in_progress → session directory has stale manifest, user must manually mark as aborted
- Multiple in-progress sessions in parallel worktrees → each worktree scans the same sessions dir, but the supervisor should only resume sessions whose worktree path matches the current working directory

**Refinement**: Store the worktree path (or `main` for non-worktree) in `session.yaml`. On resume, filter sessions by matching worktree path to avoid cross-session interference.

## R5: Precondition/Postcondition Vocabulary

**Decision**: Fixed vocabulary of artifact checks, each mapping to a filesystem glob or command.

| Condition ID | Check Description | Evaluation |
|-------------|-------------------|-----------|
| `spec_exists` | Spec file present | `existsSync(specs/{feature}/spec.md)` |
| `plan_exists` | Plan file present | `existsSync(specs/{feature}/plan.md)` |
| `tasks_exists` | Tasks file present | `existsSync(specs/{feature}/tasks.md)` |
| `agreement_exists` | Agreement created | `existsSync(.agreements/{feature}/agreement.yaml)` |
| `agreement_pass` | Agreement check passes | Read `.agreements/{feature}/check-report.md`, scan for `verdict: PASS` |
| `qa_plan_exists` | QA plan present | `existsSync(.qa/{feature}/test-plan.md)` |
| `qa_verdict_pass` | QA verdict is PASS | Read `.qa/{feature}/verdict.md`, scan for `verdict: PASS` |
| `pr_created` | PR exists for branch | `gh pr list --head {branch} --json number` returns non-empty |

**Design choice**: The `pr_created` condition is the only one requiring an external command (`gh`). All others are pure filesystem checks. This aligns with NFR7 from the PRD: "GitHub CLI is required only for PR-related steps."

## R6: Parallel Phase Execution

**Decision**: Parallel phases use multiple Task tool calls in a single message.

**Rationale**: Claude Code's Task tool supports concurrent calls when included in the same message. The supervisor prompt instructs: "For a parallel phase, launch all step subagents in a single message using multiple Task tool calls."

**Constraints**:
- Maximum concurrent Task calls is bounded by Claude Code's implementation
- Playbooks should keep parallel phases to 2-3 steps
- Both built-in playbooks (auto-feature, auto-validate) are sequential — parallel phases are a capability for custom playbooks

**Error handling in parallel**: If any step in a parallel phase fails, the supervisor waits for all other steps to complete, then applies the error policy of the failed step. If multiple steps fail, the most severe error policy takes precedence (`stop` > `gate` > `retry_once`).

## R7: Slash Command Prompt Design

**Decision**: The `/playbook.run` slash command is a structured Markdown prompt that instructs Claude Code to follow a deterministic orchestration loop.

**Structure**:
1. **Preamble**: Explain role (supervisor), constraints (same commands as manual, no bypass)
2. **Initialization**: Read playbook YAML, resolve args, create session, write manifest
3. **Orchestration loop**: For each step — check precondition, check autonomy level, delegate via Task, check postcondition, write journal entry, handle error policy, check escalation triggers
4. **Gate protocol**: When halting at a gate, present context + question, wait for user response, record in journal
5. **Completion**: Write final manifest status, report summary

**Key design constraint**: The prompt must be self-contained. The supervisor has no memory between turns except what it reads from session files. This makes it inherently re-entrant — resume is just "read journal, find last step, continue."

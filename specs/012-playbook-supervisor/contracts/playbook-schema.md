# Playbook Schema Contract

**Version**: 1.0 | **Date**: 2026-02-19

## Playbook YAML Schema

### Top-Level Structure

```yaml
# Required fields
name: string              # [a-z0-9-]+, unique identifier
description: string       # Human-readable purpose
version: string           # Semantic version (e.g., "1.0")

# Required sections
args:                      # Declared parameters (array, may be empty)
  - name: string           # Argument name, referenced as {{name}} in step args
    description: string    # Purpose
    required: boolean      # true | false

steps:                     # Ordered workflow steps (array, min 1)
  - id: string             # [a-z0-9-]+, unique within playbook
    command: string         # Slash command (e.g., "/speckit.plan")
    args: string            # Optional, supports {{arg}} interpolation
    autonomy: enum          # auto | gate_on_breaking | gate_always | skip
    preconditions: [enum]   # Optional list of condition checks
    postconditions: [enum]  # Optional list of condition checks
    error_policy: enum      # stop | retry_once | gate
    escalation_triggers: [enum]  # Optional list of triggers
    parallel_group: string  # Optional, groups steps for concurrent execution
```

### Enums

#### Autonomy Levels

| Value | Behavior |
|-------|----------|
| `auto` | Execute without human interaction |
| `gate_on_breaking` | Gate only when a breaking change is detected |
| `gate_always` | Always halt for human decision |
| `skip` | Skip execution, log as skipped |

#### Error Policies

| Value | Behavior |
|-------|----------|
| `stop` | Halt all execution, mark session as failed |
| `retry_once` | Re-execute the step once; if still fails, apply `stop` |
| `gate` | Escalate to human decision with failure context |

#### Escalation Triggers

| Value | Fires When |
|-------|-----------|
| `postcondition_fail` | Any postcondition fails after step execution |
| `verdict_fail` | QA verdict file contains FAIL |
| `agreement_breaking` | Agreement check detects breaking changes |
| `subagent_error` | Task subagent returns error or crashes |

#### Conditions (Pre/Post)

| Value | Filesystem Check |
|-------|-----------------|
| `spec_exists` | `specs/{feature}/spec.md` exists |
| `plan_exists` | `specs/{feature}/plan.md` exists |
| `tasks_exists` | `specs/{feature}/tasks.md` exists |
| `agreement_exists` | `.agreements/{feature}/agreement.yaml` exists |
| `agreement_pass` | `.agreements/{feature}/check-report.md` contains `verdict: PASS` |
| `qa_plan_exists` | `.qa/{feature}/test-plan.md` exists |
| `qa_verdict_pass` | `.qa/{feature}/verdict.md` contains `verdict: PASS` |
| `pr_created` | `gh pr list --head {branch} --json number` returns non-empty |

## CLI Contract

### `npx @tcanaud/playbook init [--yes]`

**Input**: Optional `--yes` flag to skip confirmation prompts.

**Behavior**:
1. Create `.playbooks/` directory structure
2. Copy built-in playbooks to `.playbooks/playbooks/`
3. Copy template playbook to `.playbooks/playbooks/`
4. Generate `_index.yaml`
5. Install slash commands to `.claude/commands/`

**Output**: Console log of each created file/directory.

**Exit codes**: 0 (success), 1 (error).

**Idempotency**: Safe to re-run. Overwrites templates and commands, preserves user sessions and custom playbooks.

### `npx @tcanaud/playbook update`

**Input**: None.

**Behavior**:
1. Verify `.playbooks/` exists (exit 1 if not)
2. Overwrite built-in playbooks and template
3. Overwrite slash command templates
4. Regenerate `_index.yaml`
5. Never modify sessions/ or user-created playbook files

**Output**: Console log of updated files.

**Exit codes**: 0 (success), 1 (`.playbooks/` not found).

### `npx @tcanaud/playbook check {file}`

**Input**: Path to a playbook YAML file.

**Behavior**:
1. Parse the YAML using the regex-based parser
2. Validate all fields against the schema
3. Check enum values against allowed vocabulary
4. Verify step IDs are unique
5. Verify referenced args exist in the args declaration

**Output on success**: `✓ {file} is valid`

**Output on failure**: List of violations:
```
✗ {file} has {N} violation(s):
  - step "foo": autonomy "auto_always" is not valid (allowed: auto, gate_on_breaking, gate_always, skip)
  - step "bar": missing required field "command"
  - step "baz": precondition "magic_exists" is not a known condition
```

**Exit codes**: 0 (valid), 1 (invalid or parse error).

### `npx @tcanaud/playbook start {playbook} {feature}`

**Input**: Playbook name and feature branch name.

**Behavior**:
1. Verify git working tree is clean (`git status --porcelain` is empty)
2. Verify the playbook exists in `.playbooks/playbooks/{playbook}.yaml`
3. Generate session ID (`{YYYYMMDD}-{3char}`)
4. Create session directory `.playbooks/sessions/{id}/`
5. Write initial `session.yaml` with status `pending`
6. Write empty `journal.yaml`
7. Run `git worktree add ../kai-session-{id} {current-branch}`
8. Print instructions:
   ```
   ✓ Session {id} created
   ✓ Worktree created at ../kai-session-{id}
   → Run: cd ../kai-session-{id} && claude
   → Then type: /playbook.run {playbook} {feature}
   ```

**Exit codes**: 0 (success), 1 (dirty working tree), 2 (worktree creation failed).

## Slash Command Contract

### `/playbook.run {playbook} {feature}`

**Input**: Playbook name and feature branch name (via `$ARGUMENTS`).

**Behavior** (executed by Claude Code as a prompt):
1. Parse arguments: extract playbook name and feature
2. Read playbook YAML from `.playbooks/playbooks/{playbook}.yaml`
3. Look for existing in-progress session for this playbook+feature; if found, resume it. Otherwise create new session.
4. For each step in order:
   a. Check preconditions (Read files, check existence)
   b. Evaluate autonomy level
   c. If `skip`: log skipped entry, continue
   d. If `auto`: delegate to Task subagent, evaluate postconditions
   e. If `gate_always`: halt, present context, wait for user
   f. If `gate_on_breaking`: check for breaking changes, gate only if found
   g. Write journal entry after each step
   h. On failure: apply error policy (stop/retry_once/gate)
   i. On escalation trigger: promote to gate
5. On completion: update session status, report summary

**Output**: Step-by-step progress in TUI, halts at gates, final summary.

### `/playbook.resume`

**Input**: None (argumentless).

**Behavior** (executed by Claude Code as a prompt):
1. Find repo root via `git rev-parse --show-toplevel`
2. Scan `.playbooks/sessions/*/session.yaml` for `status: in_progress`
3. If multiple: pick most recent by session ID timestamp
4. Read journal to find last completed step
5. Check postcondition of last in-progress step (if any)
6. Resume execution from the appropriate step
7. Continue with same orchestration loop as `/playbook.run`

**Output**: Same as `/playbook.run` from the resume point.

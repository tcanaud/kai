# Data Model: Playbook Supervisor

**Branch**: `012-playbook-supervisor` | **Date**: 2026-02-19

## Entities

### Playbook

A declarative definition of an ordered workflow. Stored as a YAML file in `.playbooks/playbooks/`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Unique identifier (e.g., `auto-feature`) |
| `description` | string | yes | Human-readable purpose |
| `version` | string | yes | Schema version (e.g., `1.0`) |
| `args` | Arg[] | yes | Declared arguments the playbook accepts |
| `steps` | Step[] | yes | Ordered list of workflow steps (min 1) |

### Arg

A declared parameter that the playbook accepts at invocation.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Argument name, referenced as `{{name}}` in step args |
| `description` | string | yes | Human-readable purpose |
| `required` | boolean | yes | Whether the argument must be provided |

### Step

A single unit of work within a playbook.

| Field | Type | Required | Allowed Values | Description |
|-------|------|----------|----------------|-------------|
| `id` | string | yes | `[a-z0-9-]+` | Unique within playbook |
| `command` | string | yes | Any slash command | The command to execute |
| `args` | string | no | Free text with `{{arg}}` interpolation | Arguments passed to the command |
| `autonomy` | enum | yes | `auto`, `gate_on_breaking`, `gate_always`, `skip` | Decision mode |
| `preconditions` | Condition[] | no | See Condition enum | Must all pass before execution |
| `postconditions` | Condition[] | no | See Condition enum | Must all pass after execution |
| `error_policy` | enum | yes | `stop`, `retry_once`, `gate` | Behavior on failure |
| `escalation_triggers` | Trigger[] | no | See Trigger enum | Conditions that promote auto → gate |
| `parallel_group` | string | no | Group name | Steps with same group execute concurrently |

### Condition (enum)

Fixed vocabulary of artifact checks.

| Value | Evaluates To | Filesystem Check |
|-------|-------------|-----------------|
| `spec_exists` | Spec file present | `specs/{feature}/spec.md` |
| `plan_exists` | Plan file present | `specs/{feature}/plan.md` |
| `tasks_exists` | Tasks file present | `specs/{feature}/tasks.md` |
| `agreement_exists` | Agreement YAML present | `.agreements/{feature}/agreement.yaml` |
| `agreement_pass` | Agreement check passed | `.agreements/{feature}/check-report.md` → `verdict: PASS` |
| `qa_plan_exists` | QA plan present | `.qa/{feature}/test-plan.md` |
| `qa_verdict_pass` | QA verdict passed | `.qa/{feature}/verdict.md` → `verdict: PASS` |
| `pr_created` | PR exists for branch | `gh pr list --head {branch}` → non-empty |

### Trigger (enum)

Fixed vocabulary of escalation triggers.

| Value | Fires When |
|-------|-----------|
| `postcondition_fail` | A postcondition check fails after step execution |
| `verdict_fail` | QA verdict is FAIL |
| `agreement_breaking` | Agreement check detects a breaking change |
| `subagent_error` | Task subagent returns an error or crashes |

### Session

A runtime instance of a playbook execution. Stored in `.playbooks/sessions/{id}/`.

**Manifest** (`session.yaml`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `session_id` | string | yes | `{YYYYMMDD}-{3char}` format |
| `playbook` | string | yes | Playbook name |
| `feature` | string | yes | Feature branch name |
| `args` | map | yes | Resolved argument values |
| `status` | enum | yes | `pending`, `in_progress`, `completed`, `failed`, `aborted` |
| `started_at` | ISO 8601 | yes | Session start timestamp |
| `completed_at` | ISO 8601 | no | Session completion timestamp |
| `current_step` | string | no | ID of the step currently executing |
| `worktree` | string | no | Relative path to worktree directory (empty if main) |

**Journal** (`journal.yaml`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `entries` | Entry[] | yes | Ordered list of step execution records |

### Journal Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `step_id` | string | yes | References Step.id |
| `status` | enum | yes | `done`, `failed`, `skipped`, `in_progress` |
| `decision` | enum | yes | `auto`, `gate`, `escalated`, `skipped` |
| `started_at` | ISO 8601 | yes | Step start timestamp |
| `completed_at` | ISO 8601 | no | Step completion timestamp |
| `duration_seconds` | number | no | Computed from timestamps |
| `trigger` | string | no | Escalation trigger that fired (if any) |
| `human_response` | string | no | Developer's response at a gate |
| `error` | string | no | Error message if step failed |

### Playbook Index

Central registry at `.playbooks/_index.yaml`.

| Field | Type | Description |
|-------|------|-------------|
| `generated` | ISO 8601 | Last index generation timestamp |
| `playbooks` | IndexEntry[] | List of registered playbooks |

**Index Entry**:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Playbook name |
| `file` | string | Relative path to playbook YAML |
| `description` | string | From playbook definition |
| `steps` | number | Step count |

## Relationships

```
Playbook 1──* Step
Step *──* Condition (preconditions)
Step *──* Condition (postconditions)
Step *──* Trigger (escalation_triggers)
Playbook 1──* Arg

Session ──1 Playbook (by name)
Session 1──1 Journal
Journal 1──* Entry
Entry ──1 Step (by step_id)
```

## State Transitions

### Session Status

```
pending ──start──→ in_progress ──all steps done──→ completed
                              ──step fails (stop policy)──→ failed
                              ──user aborts at gate──→ aborted
                              ──crash──→ in_progress (resumed via /playbook.resume)
```

### Journal Entry Status

```
(new) ──step starts──→ in_progress ──step succeeds──→ done
                                   ──step fails──→ failed
      ──autonomy=skip──→ skipped
```

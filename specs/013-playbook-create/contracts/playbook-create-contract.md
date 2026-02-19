# Contract: /playbook.create Slash Command

**Feature**: 013-playbook-create | **Date**: 2026-02-19

## Slash Command Interface

### `/playbook.create`

**Input**: `$ARGUMENTS` — free-text intention describing the desired workflow.

**Invocation**: `/playbook.create {intention}`

**Examples**:
```
/playbook.create validate and deploy a hotfix for critical bugs
/playbook.create code review workflow for external contributions
/playbook.create end-to-end feature development with QA
```

## Protocol Phases

### Phase 1: Project Analysis

**Trigger**: Command invocation.
**Actions**:
1. Detect installed kai tools by checking marker directories
2. Scan `.claude/commands/` for available slash commands
3. Read existing playbooks from `.playbooks/playbooks/*.yaml`
4. Read project conventions from `.knowledge/snapshot.md` and `CLAUDE.md`
5. Build filtered condition vocabulary

**Output**: Internal Project Context (not persisted).

**Error conditions**:
- `.playbooks/` directory missing: STOP. Report "Playbook system not installed. Run `npx @tcanaud/playbook init` first."
- `.claude/commands/` missing: WARN. Proceed with empty command list.

### Phase 2: Intention Parsing

**Trigger**: Project analysis complete.
**Input**: `$ARGUMENTS` free-text string.

**Actions**:
1. Extract action keywords from intention
2. Map keywords to available slash commands
3. Determine if clarification is needed

**Clarification trigger conditions**:
- Fewer than 3 mappable action keywords
- No clear start/end to the workflow
- Ambiguous terms that map to multiple commands

**Clarification protocol** (max 3 questions):
1. "What triggers this workflow?" (starting condition)
2. "What is the expected outcome?" (success criteria)
3. "Which steps should require human approval?" (autonomy preferences)

**Output**: Ordered list of (command, intent) pairs.

**Error conditions**:
- Empty intention: ASK for intention.
- Single-action intention: SUGGEST running the command directly. OFFER to create playbook if developer insists.

### Phase 3: Playbook Generation

**Trigger**: Intention parsed (possibly after clarification).

**Actions**:
1. Generate playbook name: derive lowercase slug from intention, pattern `[a-z0-9-]+`
2. Generate description: human-readable summary of the workflow
3. Declare arguments: `feature` (required) by default; additional args based on intention
4. Generate steps in sequence:
   - Map each action to a slash command
   - Assign step ID (lowercase slug)
   - Assign autonomy level (from existing patterns or heuristics)
   - Assign preconditions/postconditions (from usable conditions, following dependency chains)
   - Assign error policy (from existing patterns or heuristics)
   - Assign escalation triggers (from existing patterns or heuristics)
   - Assign args with `{{arg}}` interpolation (never hardcoded values)
5. Format as YAML string

**Output**: YAML string.

**Constraints**:
- Only commands verified in `.claude/commands/` may be referenced
- Only conditions from the usable set may be used
- No hardcoded feature-specific values
- All `{{arg}}` references must match declared args

### Phase 4: Validation

**Trigger**: YAML string generated.

**Actions**:
1. Write YAML to target file path `.playbooks/playbooks/{name}.yaml`
2. Run `npx @tcanaud/playbook check .playbooks/playbooks/{name}.yaml`
3. Parse output for violations

**On success**: Proceed to Phase 5.
**On failure**: Fix violations in YAML, rewrite, re-validate (max 3 attempts).

**Output**: Validated playbook file on disk.

### Phase 5: Presentation and Refinement

**Trigger**: Validation passes.

**Actions**:
1. Present playbook to developer with per-step rationale:
   ```
   Generated playbook: {name}

   Step 1: {id} — {command}
     Autonomy: {level} (because: {rationale})
     Error policy: {policy} (because: {rationale})
     Preconditions: {conditions}
     Postconditions: {conditions}

   Step 2: ...
   ```
2. Ask: "Would you like to modify this playbook, or save it as-is?"
3. If modification requested:
   - Apply modification
   - Re-validate via `npx @tcanaud/playbook check`
   - Re-present
   - Repeat
4. If "done" / "save" / "looks good":
   - Proceed to Phase 6

**Supported modifications**:
- Add step (describe action, AI maps to command and inserts)
- Remove step (with dependency warning per FR-024)
- Change autonomy level
- Change error policy
- Reorder steps
- Change name
- Change description
- Add/remove arguments

### Phase 6: Conflict Check and Persistence

**Trigger**: Developer approves playbook.

**Actions**:
1. Check if `.playbooks/playbooks/{name}.yaml` already exists (from a previous playbook, not this session's validation writes)
2. If conflict detected:
   - Report: "A playbook named '{name}' already exists."
   - Offer: (1) Overwrite, (2) Rename, (3) Cancel
   - If rename: prompt for new name, validate slug pattern, re-check
   - If cancel: delete the written file, report cancellation, END
3. Write final playbook to `.playbooks/playbooks/{name}.yaml` (or confirm overwrite)
4. Update `.playbooks/_index.yaml`:
   - Read existing index
   - If missing/corrupted: rebuild from filesystem scan
   - Add/update entry for new playbook
   - Write back

**Output**:
- Playbook file at `.playbooks/playbooks/{name}.yaml`
- Updated index at `.playbooks/_index.yaml`

**Report**:
```
Playbook created successfully!

  File: .playbooks/playbooks/{name}.yaml
  Steps: {count}

  Run with: /playbook.run {name} {feature}
  Validate: npx @tcanaud/playbook check .playbooks/playbooks/{name}.yaml
```

## Playbook Schema (Reference)

The generated playbook must conform to this schema (enforced by `npx @tcanaud/playbook check`):

### Top-level fields (all required)

| Field | Type | Constraint |
|-------|------|-----------|
| `name` | string | `[a-z0-9-]+` |
| `description` | string | Non-empty |
| `version` | string | Currently "1.0" |
| `args` | array | May be empty `[]` |
| `steps` | array | Min 1 element |

### Arg fields (all required per arg)

| Field | Type | Constraint |
|-------|------|-----------|
| `name` | string | Non-empty |
| `description` | string | Non-empty |
| `required` | boolean | `true` or `false` |

### Step fields

| Field | Type | Required | Constraint |
|-------|------|----------|-----------|
| `id` | string | Yes | `[a-z0-9-]+`, unique within playbook |
| `command` | string | Yes | Slash command path (e.g., `/speckit.plan`) |
| `args` | string | No | Supports `{{arg}}` interpolation |
| `autonomy` | enum | Yes | `auto`, `gate_on_breaking`, `gate_always`, `skip` |
| `preconditions` | string[] | No | Subset of condition vocabulary |
| `postconditions` | string[] | No | Subset of condition vocabulary |
| `error_policy` | enum | Yes | `stop`, `retry_once`, `gate` |
| `escalation_triggers` | string[] | No | Subset of trigger vocabulary |
| `parallel_group` | string | No | Group name for concurrent execution |

### Condition Vocabulary

| Value | Artifact Check |
|-------|---------------|
| `spec_exists` | `specs/{feature}/spec.md` exists |
| `plan_exists` | `specs/{feature}/plan.md` exists |
| `tasks_exists` | `specs/{feature}/tasks.md` exists |
| `agreement_exists` | `.agreements/{feature}/agreement.yaml` exists |
| `agreement_pass` | `.agreements/{feature}/check-report.md` verdict: PASS |
| `qa_plan_exists` | `.qa/{feature}/test-plan.md` exists |
| `qa_verdict_pass` | `.qa/{feature}/verdict.yaml` verdict: PASS |
| `pr_created` | `gh pr list --head {branch}` returns non-empty |

### Escalation Trigger Vocabulary

| Value | Fires When |
|-------|-----------|
| `postcondition_fail` | Any postcondition fails after step execution |
| `verdict_fail` | QA verdict file contains FAIL |
| `agreement_breaking` | Agreement check detects breaking changes |
| `subagent_error` | Task subagent returns error or crashes |

## Package Changes Contract

### `installer.js` — Modified

**Current** `commandFiles` array:
```javascript
const commandFiles = ["playbook.run.md", "playbook.resume.md"];
```

**Updated**:
```javascript
const commandFiles = ["playbook.run.md", "playbook.resume.md", "playbook.create.md"];
```

### `updater.js` — Modified

Same change: add `"playbook.create.md"` to the command files list.

### `package.json` — Modified

```json
{
  "version": "1.2.0"
}
```

### New file: `templates/commands/playbook.create.md`

The slash command template. See the implementation tasks for the full content specification.

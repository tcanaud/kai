# Data Model: /playbook.create Command

**Feature**: 013-playbook-create | **Date**: 2026-02-19

## Entities

### 1. Project Context (Ephemeral)

Built at the start of each `/playbook.create` invocation. Not persisted.

```yaml
# Internal working model — not written to disk
project_context:
  installed_tools:
    - name: "adr-system"
      marker: ".adr/"
      detected: true
    - name: "agreement-system"
      marker: ".agreements/"
      detected: true
    - name: "feature-lifecycle"
      marker: ".features/"
      detected: true
    - name: "knowledge-system"
      marker: ".knowledge/"
      detected: true
    - name: "qa-system"
      marker: ".qa/"
      detected: true
    - name: "product-manager"
      marker: ".product/"
      detected: true
    - name: "speckit"
      marker: "specs/"
      detected: true
    - name: "bmad"
      marker: "_bmad/"
      detected: true
    - name: "playbook"
      marker: ".playbooks/"
      detected: true

  available_commands:
    # Dot-separated commands (primary — used in playbook steps)
    - name: "/speckit.plan"
      file: "speckit.plan.md"
      namespace: "speckit"
    - name: "/speckit.tasks"
      file: "speckit.tasks.md"
      namespace: "speckit"
    - name: "/agreement.create"
      file: "agreement.create.md"
      namespace: "agreement"
    # ... (all dot-separated commands from .claude/commands/)

    # Hyphen-separated commands (secondary — BMAD agents/workflows)
    - name: "/bmad-bmm-code-review"
      file: "bmad-bmm-code-review.md"
      namespace: "bmad"
    # ... (listed but typically not included in generated playbook steps)

  usable_conditions:
    - "spec_exists"        # requires: specs/
    - "plan_exists"        # requires: specs/
    - "tasks_exists"       # requires: specs/
    - "agreement_exists"   # requires: .agreements/
    - "agreement_pass"     # requires: .agreements/
    - "qa_plan_exists"     # requires: .qa/
    - "qa_verdict_pass"    # requires: .qa/
    - "pr_created"         # requires: gh CLI

  existing_patterns:
    autonomy_defaults:
      "/speckit.plan": "auto"
      "/speckit.tasks": "auto"
      "/agreement.create": "auto"
      "/speckit.implement": "auto"
      "/agreement.check": "gate_on_breaking"
      "/qa.plan": "auto"
      "/qa.run": "auto"
      "/feature.pr": "gate_always"
      "/product.intake": "auto"
      "/product.triage": "auto"
      "/product.promote": "gate_always"
    error_policy_defaults:
      "/speckit.plan": "stop"
      "/speckit.tasks": "stop"
      "/agreement.create": "gate"
      "/speckit.implement": "retry_once"
      "/agreement.check": "gate"
      "/qa.plan": "stop"
      "/qa.run": "gate"
      "/feature.pr": "stop"
    escalation_defaults:
      "/agreement.create": ["subagent_error"]
      "/speckit.implement": ["postcondition_fail", "subagent_error"]
      "/agreement.check": ["agreement_breaking"]
      "/qa.run": ["verdict_fail"]

  conventions:
    naming: "lowercase-slug"           # [a-z0-9-]+
    step_id_pattern: "lowercase-slug"  # [a-z0-9-]+
    technology_stack: "Node.js ESM, zero deps"
```

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `installed_tools` | `Tool[]` | Detected kai tools with marker directory and presence flag |
| `available_commands` | `Command[]` | All slash commands found in `.claude/commands/` |
| `usable_conditions` | `string[]` | Subset of condition vocabulary applicable to this project |
| `existing_patterns` | `PatternMap` | Autonomy, error_policy, escalation defaults extracted from existing playbooks |
| `conventions` | `ConventionMap` | Naming conventions, technology stack from project docs |

### 2. Generated Playbook (Persistent)

Output artifact conforming to the playbook schema. Written to `.playbooks/playbooks/{name}.yaml`.

```yaml
name: "{slug}"                    # [a-z0-9-]+ derived from intention
description: "{human-readable}"   # Summary of what the playbook does
version: "1.0"                    # Always "1.0" for new playbooks

args:                              # Declared arguments
  - name: "feature"               # Most playbooks need this
    description: "Feature branch name (e.g., 013-my-feature)"
    required: true
  - name: "{custom_arg}"          # Additional args if needed
    description: "{arg_purpose}"
    required: true|false

steps:                             # Ordered list of workflow steps
  - id: "{step-slug}"             # Unique [a-z0-9-]+ identifier
    command: "/{namespace.command}" # Must exist in .claude/commands/
    args: "{{feature}}"            # Argument interpolation
    autonomy: "auto"               # auto|gate_on_breaking|gate_always|skip
    preconditions:                 # Only from usable_conditions
      - "spec_exists"
    postconditions:                # Only from usable_conditions
      - "plan_exists"
    error_policy: "stop"           # stop|retry_once|gate
    escalation_triggers: []        # postcondition_fail|verdict_fail|agreement_breaking|subagent_error
```

**Validation rules**:
| Rule | Enforcement |
|------|-------------|
| Name matches `[a-z0-9-]+` | Validator pattern check |
| At least 1 step | Validator cardinality check |
| Step IDs unique | Validator uniqueness check |
| Step IDs match `[a-z0-9-]+` | Validator pattern check |
| Autonomy in allowed set | Validator + parser enum check |
| Error policy in allowed set | Validator + parser enum check |
| Conditions in allowed set | Validator + parser enum check |
| Escalation triggers in allowed set | Validator + parser enum check |
| `{{arg}}` references match declared args | Validator referential integrity check |
| Commands exist in `.claude/commands/` | Generation-time check (not in validator) |
| No hardcoded feature values | Generation-time check (AI enforced) |

### 3. Playbook Index Entry (Persistent — Appended)

Added to `.playbooks/_index.yaml` after playbook creation.

```yaml
# Entry added to the playbooks[] list
- name: "{playbook-name}"
  file: "playbooks/{playbook-name}.yaml"
  description: "{playbook-description}"
  steps: {step_count}
```

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Playbook name (matches `name` in the playbook file) |
| `file` | `string` | Relative path from `.playbooks/` to the playbook file |
| `description` | `string` | Human-readable description (matches `description` in the playbook file) |
| `steps` | `integer` | Number of steps in the playbook |

### 4. Intention (Ephemeral — Input)

Free-text string provided by the user. Consumed during generation, not persisted.

```text
"validate and deploy a hotfix for critical bugs"
```

**Properties**:
- No format constraints (natural language)
- May be vague (triggers clarification)
- May reference unavailable tools (triggers warning)
- May describe a single action (triggers suggestion to run command directly)

## Relationships

```
Intention (input)
    |
    v
Project Context (ephemeral, built from filesystem scan)
    |
    v
Generated Playbook (persistent, written to .playbooks/playbooks/{name}.yaml)
    |
    v
Playbook Index (persistent, entry appended to .playbooks/_index.yaml)
```

## State Transitions

The `/playbook.create` command itself does not have persistent state. The interaction follows this flow:

```
START
  |
  v
PROJECT_ANALYSIS ──> scanning filesystem, building Project Context
  |
  v
INTENTION_PARSING ──> extracting actions from free-text
  |                  (may loop to CLARIFICATION up to 3 times)
  v
CLARIFICATION ──> asking up to 3 questions (optional)
  |
  v
GENERATION ──> producing YAML string
  |
  v
VALIDATION ──> running `npx @tcanaud/playbook check`
  |           (loops back to GENERATION on failure)
  v
PRESENTATION ──> showing playbook with rationale to user
  |
  v
REFINEMENT ──> user requests modifications (optional, loops)
  |           (each modification -> VALIDATION -> PRESENTATION)
  v
CONFLICT_CHECK ──> checking for existing playbook with same name
  |              (may offer rename/overwrite/cancel)
  v
PERSISTENCE ──> writing playbook file + updating index
  |
  v
END ──> report success with file path
```

# Data Model: Playbook Step Model Selection

**Feature**: `014-playbook-step-model` | **Date**: 2026-02-19

## Entities

### PlaybookStep (modified)

A single unit of work in a playbook definition. This entity gains one new optional field.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | string | yes | -- | Unique step identifier, pattern `[a-z0-9-]+` |
| `command` | string | yes | -- | Slash command to execute |
| `args` | string | no | `""` | Arguments with `{{arg}}` interpolation |
| `autonomy` | enum | yes | -- | Decision mode: `auto`, `gate_on_breaking`, `gate_always`, `skip` |
| `preconditions` | string[] | no | `[]` | Artifact checks before execution |
| `postconditions` | string[] | no | `[]` | Artifact checks after execution |
| `error_policy` | enum | yes | -- | Failure behavior: `stop`, `retry_once`, `gate` |
| `escalation_triggers` | string[] | no | `[]` | Triggers for escalation |
| `parallel_group` | string | no | `null` | Concurrent execution group |
| **`model`** | **enum** | **no** | **`null`** | **AI model tier override: `opus`, `sonnet`, `haiku`. When `null`, session default applies.** |

**Validation rules**:
- `model` is optional. When absent or empty string, stored as `null`.
- When present, must be one of: `"opus"`, `"sonnet"`, `"haiku"` (case-sensitive).
- Invalid values cause a parse error (in `yaml-parser.js`) or validation violation (in `validator.js`).

### ModelIdentifier (new value type)

A closed set of allowed AI model tier names.

| Value | Description |
|-------|-------------|
| `"opus"` | Most capable model, best for complex reasoning |
| `"sonnet"` | Balanced model, good for most tasks |
| `"haiku"` | Fastest model, best for simple/routine tasks |

**Defined in**: Constant sets in both `yaml-parser.js` (`ALLOWED_MODELS`) and `validator.js` (`MODEL_VALUES`).

**Extension point**: Adding a new model requires updating both constants. No other code changes needed.

## Relationships

```text
Playbook 1---* PlaybookStep
PlaybookStep *---0..1 ModelIdentifier
```

- A Playbook contains one or more PlaybookSteps.
- Each PlaybookStep optionally references one ModelIdentifier.
- ModelIdentifier is a value type (enum), not a separate entity.

## State Transitions

No new state transitions. The `model` field is a static configuration property read at parse time and consumed at delegation time. It does not change during execution.

## Internal Representation

In `_emptyStep()` factory (yaml-parser.js):

```javascript
function _emptyStep() {
  return {
    id: null,
    command: null,
    args: "",
    autonomy: null,
    preconditions: [],
    postconditions: [],
    error_policy: null,
    escalation_triggers: [],
    parallel_group: null,
    model: null,          // NEW: AI model override
  };
}
```

## YAML Representation

```yaml
steps:
  - id: "plan"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "opus"          # NEW: optional model override
    preconditions:
      - "spec_exists"
    postconditions:
      - "plan_exists"
    error_policy: "stop"
    escalation_triggers: []
```

When omitted:

```yaml
steps:
  - id: "simple-check"
    command: "/some.check"
    autonomy: "auto"
    error_policy: "stop"
    # model not specified -> session default applies
```

# Contract: Playbook Step Schema — Model Field

**Feature**: `014-playbook-step-model` | **Date**: 2026-02-19

## Overview

This contract defines the interface changes for adding the optional `model` field to the playbook step schema. It covers the parser output, validator behavior, and supervisor delegation protocol.

## 1. Parser Contract (`yaml-parser.js`)

### `parsePlaybook(content) -> Playbook`

**Changed**: The `Step` object in the returned `steps[]` array now includes a `model` field.

#### Step Object Shape (after change)

```typescript
interface Step {
  id: string;              // required, pattern [a-z0-9-]+
  command: string;         // required
  args: string;            // default ""
  autonomy: string;        // required, enum
  preconditions: string[]; // default []
  postconditions: string[];// default []
  error_policy: string;    // required, enum
  escalation_triggers: string[]; // default []
  parallel_group: string | null; // default null
  model: string | null;    // NEW: default null, enum when present
}
```

#### Allowed `model` values

```typescript
const ALLOWED_MODELS = new Set(["opus", "sonnet", "haiku"]);
```

#### Behavior

| Input YAML | Parsed `model` value |
|------------|---------------------|
| `model: "opus"` | `"opus"` |
| `model: sonnet` | `"sonnet"` |
| `model: "haiku"` | `"haiku"` |
| `model: ""` | `null` |
| (field absent) | `null` |
| `model: "invalid"` | Throws Error: `model "invalid" is not valid (allowed: opus, sonnet, haiku)` |
| `model: "Sonnet"` | Throws Error: `model "Sonnet" is not valid (allowed: opus, sonnet, haiku)` |

#### Backward compatibility

- Existing YAML without `model` fields parses identically to before, with `model: null` added to each step object.
- No existing fields are modified or removed.

## 2. Validator Contract (`validator.js`)

### `check(args)` CLI behavior

**Changed**: Per-step validation now includes model enum check.

#### New validation rule

For each step, if `step.model` is a non-null, non-empty string:
- If not in `MODEL_VALUES`: push violation `step "{id}": model "{value}" is not valid (allowed: opus, sonnet, haiku)`

#### Validation constant

```javascript
const MODEL_VALUES = ["opus", "sonnet", "haiku"];
```

#### Unchanged behavior

- `step.model === null` (absent field): no violation
- Valid model values: no violation
- All other existing validations remain unchanged

## 3. Supervisor Delegation Contract (`playbook.run.md`)

### Step delegation via Task tool

**Changed**: When a step has a non-null `model` value, the supervisor passes it as the `model` parameter in the Task tool call.

#### Delegation with model

```
Task tool call:
  prompt: "Execute {command} for feature {feature}. Use the Skill tool to invoke the slash command."
  model: "{step.model}"     # only when step.model is not null
```

#### Delegation without model (unchanged)

```
Task tool call:
  prompt: "Execute {command} for feature {feature}. Use the Skill tool to invoke the slash command."
  # no model parameter — session default applies
```

## 4. Template Contract (`playbook.tpl.yaml`)

### Schema Reference comments

**Changed**: Add `model` field documentation to the step fields section.

```yaml
# steps (required, min 1):
#   - id:                  Unique within playbook [a-z0-9-]+
#     command:             Slash command to execute (e.g., "/speckit.plan")
#     args:                Optional — supports {{arg}} interpolation
#     autonomy:            Decision mode (see below)
#     model:               Optional — AI model override (see below)    # NEW
#     preconditions:       Optional list of artifact checks (see below)
#     postconditions:      Optional list of artifact checks (see below)
#     error_policy:        Behavior on failure (see below)
#     escalation_triggers: Optional list of triggers (see below)
#     parallel_group:      Optional — steps with same group run concurrently
```

New section:

```yaml
# -- Model Values ------------------------------------------
#   opus             Most capable model (complex reasoning, specifications)
#   sonnet           Balanced model (general-purpose tasks)
#   haiku            Fastest model (simple checks, validations)
#   (omit field)     Use session default model
```

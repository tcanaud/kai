# Feature Specification: Playbook Step Model Selection

**Feature Branch**: `014-playbook-step-model`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "Adding a `model` property to playbook step definitions so each step can specify which AI model to use (opus, sonnet, haiku). When no model is specified, it should use the session default."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Specify Model Per Step in a Playbook (Priority: P1)

A playbook author wants to assign a specific AI model to individual steps in a playbook definition. Some steps require deep reasoning (e.g., specification writing, complex implementation) and benefit from a more capable model, while other steps are routine (e.g., file checks, simple validations) and can use a faster, cheaper model. The author adds an optional `model` field to any step where they want to override the default model.

**Why this priority**: This is the core capability of the feature. Without per-step model assignment, the entire feature has no value. It enables cost optimization and performance tuning at the workflow level.

**Independent Test**: Can be fully tested by creating a playbook YAML with `model` fields on some steps, validating it passes schema checks, and verifying the supervisor passes the correct model when delegating each step.

**Acceptance Scenarios**:

1. **Given** a playbook with a step that has `model: "sonnet"`, **When** the playbook is validated, **Then** validation passes without errors.
2. **Given** a playbook with a step that has `model: "opus"`, **When** the supervisor executes that step, **Then** the Task subagent is launched with the specified model.
3. **Given** a playbook with a step that has no `model` field, **When** the supervisor executes that step, **Then** the Task subagent uses the session default model (no model override is applied).
4. **Given** a playbook with steps using different models (e.g., step 1 uses "opus", step 2 uses "haiku"), **When** the supervisor runs the playbook, **Then** each step uses its own specified model independently.

---

### User Story 2 - Validate Model Values in Playbook Schema (Priority: P2)

A playbook author mistypes or uses an unsupported model name in a step definition. The playbook validation tool (`npx @tcanaud/playbook check`) catches the invalid model value and reports a clear error message, preventing the playbook from being used until corrected.

**Why this priority**: Validation prevents runtime failures during playbook execution. Without it, an invalid model name would only surface when the supervisor tries to delegate the step, wasting time and causing confusing errors.

**Independent Test**: Can be fully tested by running the check command against playbook files with valid and invalid model values, verifying correct acceptance and rejection.

**Acceptance Scenarios**:

1. **Given** a playbook with `model: "invalid-model"` on a step, **When** the user runs the validation tool, **Then** the tool reports a violation identifying the invalid model value and listing the allowed values.
2. **Given** a playbook with `model: "sonnet"` on a step, **When** the user runs the validation tool, **Then** validation passes without model-related errors.
3. **Given** a playbook with no `model` field on any step, **When** the user runs the validation tool, **Then** validation passes (the field is optional).

---

### User Story 3 - Create Playbook with Model Hints (Priority: P3)

A user creating a new playbook via the `/playbook.create` command can optionally specify model preferences for steps. The playbook template and creation flow support the `model` field, and the generated playbook may include model annotations on steps where the system determines a specific model would be beneficial.

**Why this priority**: This enhances the creation experience but is not essential. Users can always manually add model fields after creation. The core value is delivered by P1 and P2.

**Independent Test**: Can be fully tested by running the playbook creation command and verifying the generated YAML includes valid `model` fields where appropriate, and that the template documentation references the new field.

**Acceptance Scenarios**:

1. **Given** the playbook template file, **When** a user views the schema reference comments, **Then** the `model` field is documented with its allowed values and optional nature.
2. **Given** a user creates a playbook via `/playbook.create`, **When** the playbook is generated, **Then** any `model` fields included in the output use valid model values.

---

### Edge Cases

- What happens when a step specifies a model that is valid in the schema but not available in the current environment? The supervisor should attempt to use the model; if the underlying tool rejects it, the step fails and the error policy applies as normal.
- What happens when the same playbook is run in different environments where model availability varies? The playbook definition remains portable; model availability is a runtime concern handled by the execution environment, not the playbook schema.
- What happens when a `model` field contains an empty string? The system should treat an empty string the same as an absent field (use session default), or the validator should reject empty strings as invalid.
- What happens when a future model name needs to be added? The allowed model values list should be maintained in a single location so adding a new model requires changing only one place in the codebase.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The playbook step schema MUST support an optional `model` field that specifies which AI model to use for that step.
- **FR-002**: The allowed values for the `model` field MUST include at minimum: "opus", "sonnet", and "haiku".
- **FR-003**: When a step omits the `model` field, the system MUST use the session default model (no override applied).
- **FR-004**: The playbook validator MUST accept steps with a valid `model` value without reporting errors.
- **FR-005**: The playbook validator MUST reject steps with an invalid `model` value and report a clear violation message listing the allowed values.
- **FR-006**: The playbook validator MUST accept steps with no `model` field (the field is optional).
- **FR-007**: The playbook supervisor MUST pass the step's `model` value to the Task subagent when delegating execution of a step that specifies a model.
- **FR-008**: The playbook supervisor MUST NOT pass a model override to the Task subagent when delegating execution of a step that does not specify a model.
- **FR-009**: The playbook YAML parser MUST parse the `model` field from step definitions and include it in the parsed step object.
- **FR-010**: The playbook template file MUST document the `model` field in its schema reference comments, including allowed values and optional nature.
- **FR-011**: Existing playbooks without any `model` fields MUST continue to validate and execute without modification (full backward compatibility).
- **FR-012**: The `model` field value MUST be treated as case-sensitive (e.g., "Sonnet" is invalid; "sonnet" is valid).

### Key Entities

- **Playbook Step**: A single unit of work in a playbook. Gains a new optional `model` property (string) alongside existing properties like `id`, `command`, `args`, `autonomy`, `error_policy`, etc. When present, `model` indicates which AI model the supervisor should use when delegating this step.
- **Model Identifier**: A string value from a closed set of allowed model names ("opus", "sonnet", "haiku"). Represents the AI model tier to be used for step execution. The set may be extended in future versions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of existing playbooks (without `model` fields) continue to pass validation and execute correctly after the change is deployed.
- **SC-002**: A playbook author can add a `model` field to any step and have it validated and respected during execution on first attempt, without consulting external documentation beyond the playbook template comments.
- **SC-003**: Invalid model values are caught at validation time (before execution), preventing 100% of model-related runtime errors that would otherwise occur during playbook execution.
- **SC-004**: The model override is correctly applied to every step that specifies one, verified by the supervisor passing the correct model parameter in 100% of delegated steps.

## Assumptions

- The session default model behavior already exists and does not need to be changed. This feature only adds an override mechanism.
- The Task tool used by the supervisor supports a model parameter or equivalent mechanism for specifying which model to use. If not, the supervisor documentation will need to describe how to pass the model hint.
- The set of allowed model names ("opus", "sonnet", "haiku") is sufficient for current needs. The design should make it straightforward to add new model names in the future by updating a single constant or list.
- An empty `model` string is treated as equivalent to the field being absent (session default applies). The validator may optionally reject empty strings to enforce explicit intent.

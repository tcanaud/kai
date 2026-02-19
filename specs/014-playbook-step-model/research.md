# Research: Playbook Step Model Selection

**Feature**: `014-playbook-step-model` | **Date**: 2026-02-19

## Research Questions

### R1: How does the custom YAML parser handle new step fields?

**Decision**: Add `model` as a recognized scalar field in `_applyStepField()` within `yaml-parser.js`, alongside existing fields like `id`, `command`, `args`, `autonomy`, `parallel_group`, and `error_policy`. Add a corresponding `ALLOWED_MODELS` constant set.

**Rationale**: The parser uses a strict whitelist approach -- unknown step fields throw an error (`"unknown step field"`). The `model` field must be added to the switch statement in `_applyStepField()` and validated against an enum set (same pattern as `autonomy` and `error_policy`). The `_emptyStep()` factory must include `model: null` as the default.

**Alternatives considered**:
- Allow arbitrary extra fields (rejected: breaks the strict schema design, would weaken validation)
- Parse model as a list field (rejected: a step uses exactly one model, scalar is correct)

### R2: How does the validator handle enum validation for step fields?

**Decision**: Add a `MODEL_VALUES` constant array in `validator.js` and validate `step.model` in the per-step validation loop, following the exact pattern used for `autonomy` and `error_policy`.

**Rationale**: The validator independently declares its own allowed-value arrays (separate from the parser) for human-readable error messages. The existing pattern for enum fields is: if value exists and is not in the allowed set, push a violation message. This is the correct approach for `model`.

**Alternatives considered**:
- Shared enum constants between parser and validator (rejected: the codebase explicitly maintains independent constants for decoupling, as noted in the validator source comments)

### R3: How does the supervisor pass configuration to Task subagents?

**Decision**: Update the supervisor prompt (`playbook.run.md`) in section 5c "Delegate to Task Subagent" to include the step's `model` value in the Task tool invocation. When `model` is present, add a `model` parameter to the Task tool call.

**Rationale**: The supervisor is a Markdown prompt executed by Claude Code, not programmatic code. It instructs Claude to use the "Task tool" for delegation. The prompt currently says "Launch a subagent with `subagent_type: 'general-purpose'`". Adding model selection means extending this instruction to include the model parameter when the step defines one. The Claude Code Task tool supports a `model` parameter.

**Alternatives considered**:
- Embed model in the subagent prompt text rather than as a Task tool parameter (rejected: the Task tool has a dedicated model parameter; using it is the correct mechanism)
- Modify the session.js code to track model per step (rejected: session tracks execution state, not playbook schema; the model comes from the parsed playbook step at runtime)

### R4: What model identifiers should be allowed?

**Decision**: Allow `"opus"`, `"sonnet"`, and `"haiku"` as the initial set. Maintain the set in a single constant in each file (`ALLOWED_MODELS` in `yaml-parser.js`, `MODEL_VALUES` in `validator.js`).

**Rationale**: These three map to the Claude model tiers. The spec explicitly states these three as the minimum. The single-constant pattern makes future additions straightforward (change one line per file).

**Alternatives considered**:
- Use full model IDs like `"claude-sonnet-4-20250514"` (rejected: verbose, ties to specific versions, the short names are what the Task tool accepts)
- Allow arbitrary strings and validate at runtime only (rejected: spec requires schema-level validation with clear error messages)

### R5: How should empty string model values be handled?

**Decision**: Treat empty string `model: ""` as equivalent to the field being absent (use session default). The parser will set `model` to `null` when it encounters an empty string. The validator will not flag `null` model as a violation.

**Rationale**: The spec notes "An empty model string is treated as equivalent to the field being absent." This is consistent with how `args` defaults to empty string, and `parallel_group` defaults to null. Using `null` as the internal representation for "not specified" is the established pattern in `_emptyStep()`.

**Alternatives considered**:
- Reject empty strings in the validator (rejected: spec prefers silent fallback to session default)
- Keep empty string as-is and check for both null and "" everywhere (rejected: normalizing to null in the parser is cleaner)

### R6: How should the playbook template be updated?

**Decision**: Add `model` to the Schema Reference comments in `playbook.tpl.yaml` under the step fields section. Add it as a documented optional field with its allowed values.

**Rationale**: FR-010 requires the template to document the model field. The template already has a comprehensive Schema Reference comment block that documents all step fields, autonomy levels, error policies, etc. Adding `model` follows the same pattern.

**Alternatives considered**:
- Add model to the example step in the template body (rejected: adding it to a single example step might suggest it's required; documenting it in the schema reference is sufficient)

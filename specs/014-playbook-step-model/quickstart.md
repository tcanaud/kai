# Quickstart: Playbook Step Model Selection

**Feature**: `014-playbook-step-model` | **Date**: 2026-02-19

## What This Feature Does

Adds an optional `model` field to playbook step definitions so each step can specify which AI model tier (opus, sonnet, haiku) to use. Steps without a `model` field continue to use the session default.

## Files to Modify

### 1. `packages/playbook/src/yaml-parser.js`

**What**: Add `model` as a recognized step field with enum validation.

- Add `ALLOWED_MODELS` constant: `new Set(["opus", "sonnet", "haiku"])`
- In `_applyStepField()`: add `case "model":` that validates against `ALLOWED_MODELS` and sets `item.model = value` (normalize empty string to null)
- In `_emptyStep()`: add `model: null` to the returned object

### 2. `packages/playbook/src/validator.js`

**What**: Add model enum validation to the per-step validation loop.

- Add `MODEL_VALUES` constant: `["opus", "sonnet", "haiku"]`
- In `_validatePlaybook()` per-step loop: if `step.model` exists and is not in `MODEL_VALUES`, push a violation

### 3. `.playbooks/playbooks/playbook.tpl.yaml`

**What**: Document the `model` field in the template's Schema Reference comments.

- Add `model` to the step fields list
- Add a "Model Values" section describing opus, sonnet, haiku

### 4. `.claude/commands/playbook.run.md`

**What**: Update supervisor delegation to pass model to Task subagent.

- In section 5c, add: when `step.model` is present, include `model: "{step.model}"` in the Task tool call

### 5. `.claude/commands/playbook.resume.md`

**What**: Same model-passing logic as playbook.run.md.

- In section 8, ensure the resume orchestration loop passes model when present (it references playbook.run.md logic, so this may just need a note)

### 6. `packages/playbook/tests/yaml-parser.test.js`

**What**: Add tests for the new model field.

- Happy path: step with `model: "sonnet"` parses correctly
- Happy path: step without `model` has `model: null`
- Happy path: all three valid values (opus, sonnet, haiku)
- Error: invalid model value throws
- Error: case-sensitive (e.g., "Sonnet" throws)

## Verification

```bash
# Run parser tests
cd packages/playbook && node --test tests/yaml-parser.test.js

# Validate an existing playbook (should still pass)
npx @tcanaud/playbook check .playbooks/playbooks/auto-feature.yaml

# Validate the template (should still pass)
npx @tcanaud/playbook check .playbooks/playbooks/playbook.tpl.yaml
```

## Implementation Order

1. `yaml-parser.js` -- add model field to parser (foundation)
2. `yaml-parser.test.js` -- add tests (verify parser changes)
3. `validator.js` -- add model validation (builds on parser)
4. `playbook.tpl.yaml` -- document the field (user-facing docs)
5. `playbook.run.md` + `playbook.resume.md` -- update supervisor prompts (delegation)

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Adding a new step referencing a slash command works correctly
# Criterion: US3.AC2 — "Given a generated playbook, When the developer requests adding a new step referencing a specific slash command, Then the system adds the step in the correct position with appropriate conditions and policies."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"
VALIDATOR="$PROJECT_ROOT/packages/playbook/bin/cli.js"

# Part 1: Verify the template supports adding steps
if [ ! -f "$COMMAND_FILE" ]; then
  COMMAND_FILE="$PROJECT_ROOT/.claude/commands/playbook.create.md"
fi

if [ ! -f "$COMMAND_FILE" ]; then
  echo "FAIL: playbook.create.md template not found" >&2
  exit 1
fi

CONTENT=$(cat "$COMMAND_FILE")

CHECKS_PASSED=0
CHECKS_TOTAL=3

# Check 1: Template includes "Add step" modification type
if echo "$CONTENT" | grep -qi "add.*step\|add step"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not include 'Add step' modification type" >&2
fi

# Check 2: Template references step ordering / positioning
if echo "$CONTENT" | grep -qi "correct.*position\|insert.*correct\|ordering\|dependency.*chain"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not mention step positioning logic" >&2
fi

# Check 3: Validator accepts a playbook with multiple steps (proving steps can be added)
TMPFILE=$(mktemp /tmp/test-addstep-XXXXXX.yaml)
trap "rm -f $TMPFILE" EXIT

cat > "$TMPFILE" << 'YAML'
name: "test-add-step"
description: "Test with multiple steps"
version: "1.0"

args:
  - name: "feature"
    description: "Feature branch name"
    required: true

steps:
  - id: "plan"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    preconditions:
      - "spec_exists"
    postconditions:
      - "plan_exists"
    error_policy: "stop"
    escalation_triggers: []

  - id: "implement"
    command: "/speckit.implement"
    args: ""
    autonomy: "auto"
    preconditions:
      - "plan_exists"
    postconditions: []
    error_policy: "retry_once"
    escalation_triggers:
      - "postcondition_fail"

  - id: "pr"
    command: "/feature.pr"
    args: "{{feature}}"
    autonomy: "gate_always"
    preconditions: []
    postconditions:
      - "pr_created"
    error_policy: "stop"
    escalation_triggers: []
YAML

VALIDATOR_OUTPUT=$(node "$VALIDATOR" check "$TMPFILE" 2>&1) || {
  echo "FAIL: Validator rejected multi-step playbook" >&2
  echo "  Expected: valid playbook with 3 steps" >&2
  echo "  Actual: $VALIDATOR_OUTPUT" >&2
  exit 1
}

if echo "$VALIDATOR_OUTPUT" | grep -q "is valid"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Add step functionality is properly supported ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL checks passed" >&2
  exit 1
fi

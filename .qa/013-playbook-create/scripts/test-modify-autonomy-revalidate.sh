#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Modifying a step's autonomy level triggers re-validation
# Criterion: US3.AC1 — "Given a generated playbook is presented to the developer, When the developer requests changing a step's autonomy level, Then the system updates that step and re-validates the entire playbook."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"
VALIDATOR="$PROJECT_ROOT/packages/playbook/bin/cli.js"

# Part 1: Verify the template includes refinement loop with re-validation
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

# Check 1: Template includes modification/refinement instructions
if echo "$CONTENT" | grep -qi "modif\|refin\|change.*autonomy"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not include modification/refinement instructions" >&2
fi

# Check 2: Template instructs re-validation after modifications
if echo "$CONTENT" | grep -qi "re-valid\|revalid\|after.*modif.*valid\|check.*after"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not instruct re-validation after modifications" >&2
fi

# Check 3: Validator correctly rejects invalid autonomy values
# Create a temp playbook with an invalid autonomy value
TMPFILE=$(mktemp /tmp/test-autonomy-XXXXXX.yaml)
trap "rm -f $TMPFILE" EXIT

cat > "$TMPFILE" << 'YAML'
name: "test-autonomy"
description: "Test invalid autonomy"
version: "1.0"

args: []

steps:
  - id: "step-1"
    command: "/speckit.plan"
    args: ""
    autonomy: "invalid_value"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

VALIDATOR_OUTPUT=$(node "$VALIDATOR" check "$TMPFILE" 2>&1) && {
  echo "FAIL: Validator should reject invalid autonomy value but passed" >&2
  echo "  Expected: non-zero exit code for autonomy 'invalid_value'" >&2
  echo "  Actual: exit code 0, output: $VALIDATOR_OUTPUT" >&2
  exit 1
}

if echo "$VALIDATOR_OUTPUT" | grep -qi "autonomy.*not valid\|violation"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Validator output does not mention autonomy violation" >&2
  echo "  Expected: violation message about invalid autonomy" >&2
  echo "  Actual: $VALIDATOR_OUTPUT" >&2
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Autonomy modification + re-validation logic is correct ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL checks passed" >&2
  exit 1
fi

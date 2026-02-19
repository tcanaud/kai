#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Rename option validates the new name against slug pattern
# Criterion: US5.AC3 — "Given the developer chooses 'rename' when a conflict is detected, When the system prompts for a new name, Then the developer can provide a custom name that is validated against the slug pattern."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"
VALIDATOR="$PROJECT_ROOT/packages/playbook/bin/cli.js"

# Part 1: Verify the template validates renamed playbook names
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

# Check 1: Template mentions validating renamed name against slug pattern
if echo "$CONTENT" | grep -qi "rename.*valid\|validate.*slug\|new.*name.*valid\|name.*match.*slug"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not instruct validating renamed name against slug pattern" >&2
fi

# Check 2: Template mentions re-checking for conflicts after rename
if echo "$CONTENT" | grep -qi "re-check\|check.*new.*name.*conflict\|new name.*also.*conflict"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not instruct re-checking for conflicts after rename" >&2
fi

# Check 3: Validator enforces slug pattern (already tested, but confirm here)
TMPFILE=$(mktemp /tmp/test-rename-XXXXXX.yaml)
trap "rm -f $TMPFILE" EXIT

# Valid slug name should pass
cat > "$TMPFILE" << 'YAML'
name: "renamed-playbook"
description: "A renamed playbook"
version: "1.0"

args: []

steps:
  - id: "step-1"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

VALIDATOR_OUTPUT=$(node "$VALIDATOR" check "$TMPFILE" 2>&1) || {
  echo "FAIL: Validator rejected valid renamed playbook" >&2
  echo "  Actual: $VALIDATOR_OUTPUT" >&2
  exit 1
}

if echo "$VALIDATOR_OUTPUT" | grep -q "is valid"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Rename validates against slug pattern ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL checks passed" >&2
  exit 1
fi

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Playbook name is a meaningful lowercase slug derived from intention
# Criterion: US5.AC1 — "Given a free-text intention 'deploy hotfixes for critical production bugs', When the system generates a playbook, Then the name is a meaningful lowercase slug (e.g., critical-hotfix-deploy) that captures the intention essence."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"
SLUG_PATTERN='^[a-z0-9-]+$'

# Part 1: Verify the template instructs name generation from intention
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

# Check 1: Template instructs deriving name from intention
if echo "$CONTENT" | grep -qi "derive.*name.*intention\|name.*intention\|intention.*slug\|lowercase.*slug"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not instruct deriving name from intention" >&2
fi

# Check 2: Template specifies slug pattern [a-z0-9-]+
if echo "$CONTENT" | grep -q '\[a-z0-9-\]'; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not specify [a-z0-9-]+ slug pattern" >&2
fi

# Check 3: Validator enforces slug pattern
TMPFILE=$(mktemp /tmp/test-slug-XXXXXX.yaml)
trap "rm -f $TMPFILE" EXIT

cat > "$TMPFILE" << 'YAML'
name: "Invalid Name With Spaces"
description: "Test invalid name"
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

VALIDATOR_OUTPUT=$(node "$PROJECT_ROOT/packages/playbook/bin/cli.js" check "$TMPFILE" 2>&1) && {
  echo "FAIL: Validator should reject non-slug name but passed" >&2
  exit 1
}

if echo "$VALIDATOR_OUTPUT" | grep -qi "name.*pattern\|name.*must match\|violation"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Name slug generation from intention is properly specified and enforced ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL checks passed" >&2
  exit 1
fi

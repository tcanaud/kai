#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Naming conflict detection when a playbook with the same name already exists
# Criterion: US5.AC2 — "Given a playbook named critical-hotfix-deploy already exists, When the developer attempts to create a playbook with the same derived name, Then the system warns about the conflict and offers: overwrite, rename, or cancel."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"

# Verify the template contains conflict detection and resolution logic
if [ ! -f "$COMMAND_FILE" ]; then
  COMMAND_FILE="$PROJECT_ROOT/.claude/commands/playbook.create.md"
fi

if [ ! -f "$COMMAND_FILE" ]; then
  echo "FAIL: playbook.create.md template not found" >&2
  exit 1
fi

CONTENT=$(cat "$COMMAND_FILE")

CHECKS_PASSED=0
CHECKS_TOTAL=4

# Check 1: Template checks for existing playbook with same name
if echo "$CONTENT" | grep -qi "already.*exist\|conflict.*detect\|name.*exist"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not check for existing playbook with same name" >&2
fi

# Check 2: Template offers overwrite option
if echo "$CONTENT" | grep -qi "overwrite"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not offer overwrite option" >&2
fi

# Check 3: Template offers rename option
if echo "$CONTENT" | grep -qi "rename"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not offer rename option" >&2
fi

# Check 4: Template offers cancel option
if echo "$CONTENT" | grep -qi "cancel"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not offer cancel option" >&2
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Conflict detection with overwrite/rename/cancel is properly specified ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL checks passed" >&2
  exit 1
fi

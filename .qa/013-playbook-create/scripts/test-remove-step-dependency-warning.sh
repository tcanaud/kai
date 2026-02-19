#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Removing a step warns about broken dependency conditions
# Criterion: US3.AC3 — "Given a generated playbook, When the developer requests removing a step, Then the system removes it and adjusts any dependent conditions (e.g., if a removed step's postcondition was another step's precondition, warn the user about the broken dependency)."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"

# Verify the template contains dependency warning logic for step removal
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

# Check 1: Template includes "Remove step" modification type
if echo "$CONTENT" | grep -qi "remove.*step\|remove step"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not include 'Remove step' modification type" >&2
fi

# Check 2: Template warns about broken dependencies when removing steps
if echo "$CONTENT" | grep -qi "broken.*depend\|postcondition.*precondition\|warn.*remov"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not include dependency warning on step removal" >&2
fi

# Check 3: Template mentions postcondition-to-precondition relationship
if echo "$CONTENT" | grep -qi "postcondition.*another.*precondition\|removed.*step.*condition"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not explain postcondition-to-precondition relationship" >&2
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Step removal with dependency warning is properly specified ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL checks passed" >&2
  exit 1
fi

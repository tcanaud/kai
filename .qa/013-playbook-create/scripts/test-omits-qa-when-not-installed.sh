#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: System omits QA steps when QA system is not installed
# Criterion: US2.AC1 — "Given a project where the QA system is not installed (no .qa/ directory), When the system generates a playbook that could include QA steps, Then it omits QA-related steps and does not reference QA conditions."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"

# This test verifies the command template contains usable condition filtering
# logic that ties conditions to tool detection (e.g., qa_plan_exists requires .qa/)

if [ ! -f "$COMMAND_FILE" ]; then
  echo "FAIL: playbook.create.md template not found" >&2
  exit 1
fi

CONTENT=$(cat "$COMMAND_FILE")

CHECKS_PASSED=0
CHECKS_TOTAL=3

# Check 1: Template references condition filtering based on installed tools
if echo "$CONTENT" | grep -qi "usable.*condition\|condition.*filter\|requires.*tool"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not contain condition filtering based on installed tools" >&2
fi

# Check 2: Template associates qa_plan_exists/qa_verdict_pass with QA System
if echo "$CONTENT" | grep -q "qa_plan_exists.*QA\|qa_verdict_pass.*QA"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not associate QA conditions with QA System installation" >&2
fi

# Check 3: Template mentions checking .qa/ directory for QA system detection
if echo "$CONTENT" | grep -q '\.qa/'; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not reference .qa/ directory for QA system detection" >&2
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Template includes QA tool detection and condition filtering ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL QA-filtering checks passed" >&2
  exit 1
fi

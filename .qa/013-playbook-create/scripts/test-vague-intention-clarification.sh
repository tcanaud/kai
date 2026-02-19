#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Vague intention triggers clarifying questions before generation
# Criterion: US1.AC4 — "Given the developer provides a vague intention like 'I want to ship features faster', When the system processes the intention, Then it asks clarifying questions to narrow the workflow scope before generating the playbook."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/.claude/commands/playbook.create.md"

# This test verifies the command template contains the vagueness detection logic
# Since /playbook.create is a slash command (Markdown prompt), we verify the
# template includes clarification instructions

if [ ! -f "$COMMAND_FILE" ]; then
  # Check in package templates
  COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"
fi

if [ ! -f "$COMMAND_FILE" ]; then
  echo "FAIL: playbook.create.md command template not found" >&2
  echo "  Expected: .claude/commands/playbook.create.md or packages/playbook/templates/commands/playbook.create.md" >&2
  echo "  Actual: file not found" >&2
  exit 1
fi

CONTENT=$(cat "$COMMAND_FILE")

# Verify the template contains vagueness detection instructions
CHECKS_PASSED=0
CHECKS_TOTAL=3

# Check 1: Template mentions clarification or vagueness
if echo "$CONTENT" | grep -qi "clarif\|vague\|narrow"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not contain vagueness detection logic" >&2
  echo "  Expected: references to 'clarification', 'vague', or 'narrow'" >&2
fi

# Check 2: Template limits clarification questions (max 3)
if echo "$CONTENT" | grep -qi "at most 3\|max.*3.*question\|3 question"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not limit clarification to max 3 questions" >&2
  echo "  Expected: reference to limiting clarification to 3 questions" >&2
fi

# Check 3: Template includes sample clarification questions
if echo "$CONTENT" | grep -qi "trigger\|expected outcome\|human approval"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not include sample clarification questions" >&2
  echo "  Expected: clarification question examples about triggers, outcomes, approvals" >&2
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Vague intention clarification logic present in command template ($CHECKS_PASSED/$CHECKS_TOTAL checks)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL vagueness-related checks passed" >&2
  exit 1
fi

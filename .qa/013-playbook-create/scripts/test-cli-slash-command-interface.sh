#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: CLI slash command accepts free-text intention and outputs validated playbook YAML
# Criterion: IF1 — "Claude Code slash command — accepts free-text intention, outputs validated playbook YAML"
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Verify the slash command template exists and is properly structured
CHECKS_PASSED=0
CHECKS_TOTAL=5

# Check 1: Command template exists in package templates
TEMPLATE_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"
if [ -f "$TEMPLATE_FILE" ]; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: playbook.create.md not found in packages/playbook/templates/commands/" >&2
fi

# Check 2: Template accepts $ARGUMENTS (free-text intention)
if [ -f "$TEMPLATE_FILE" ]; then
  if grep -q '\$ARGUMENTS' "$TEMPLATE_FILE"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "FAIL: Template does not reference \$ARGUMENTS for free-text intention" >&2
  fi
fi

# Check 3: Template instructs producing a YAML playbook file
if [ -f "$TEMPLATE_FILE" ]; then
  if grep -qi "playbook.*yaml\|yaml.*file\|\.playbooks/playbooks/" "$TEMPLATE_FILE"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "FAIL: Template does not instruct producing a YAML playbook file" >&2
  fi
fi

# Check 4: Template instructs running the validator
if [ -f "$TEMPLATE_FILE" ]; then
  if grep -qi "playbook check\|validator\|validate" "$TEMPLATE_FILE"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "FAIL: Template does not instruct running the validator" >&2
  fi
fi

# Check 5: installer.js includes playbook.create.md in command files
INSTALLER="$PROJECT_ROOT/packages/playbook/src/installer.js"
if [ -f "$INSTALLER" ]; then
  if grep -q 'playbook.create.md' "$INSTALLER"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "FAIL: installer.js does not include playbook.create.md in command files" >&2
  fi
else
  echo "FAIL: installer.js not found" >&2
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: CLI slash command interface is properly implemented ($CHECKS_PASSED/$CHECKS_TOTAL)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL interface checks passed" >&2
  exit 1
fi

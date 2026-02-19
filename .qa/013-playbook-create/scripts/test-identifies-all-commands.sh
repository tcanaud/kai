#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: System identifies all available slash commands and uses only valid commands
# Criterion: US2.AC4 — "Given a project with multiple installed kai tools, When the system analyzes the project, Then it identifies all available slash commands and uses only valid commands in the generated playbook."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"

# Part 1: Verify .claude/commands/ scanning is instructed in the template
if [ ! -f "$COMMAND_FILE" ]; then
  COMMAND_FILE="$PROJECT_ROOT/.claude/commands/playbook.create.md"
fi

if [ ! -f "$COMMAND_FILE" ]; then
  echo "FAIL: playbook.create.md not found" >&2
  exit 1
fi

CONTENT=$(cat "$COMMAND_FILE")

CHECKS_PASSED=0
CHECKS_TOTAL=3

# Check 1: Template instructs scanning .claude/commands/
if echo "$CONTENT" | grep -q '\.claude/commands/'; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not instruct scanning .claude/commands/" >&2
fi

# Check 2: Template instructs using only verified/existing commands
if echo "$CONTENT" | grep -qi "verified.*exist\|exist.*project\|only.*command.*exist\|must.*exist"; then
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo "FAIL: Template does not enforce using only existing commands" >&2
fi

# Check 3: Commands directory actually has commands
if [ -d "$COMMANDS_DIR" ]; then
  CMD_COUNT=$(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CMD_COUNT" -gt 0 ]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo "FAIL: .claude/commands/ exists but has no .md files" >&2
  fi
else
  echo "FAIL: .claude/commands/ directory does not exist" >&2
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "PASS: Command discovery is properly configured ($CMD_COUNT commands found, template enforces verification)"
  exit 0
else
  echo "FAIL: Only $CHECKS_PASSED/$CHECKS_TOTAL command discovery checks passed" >&2
  exit 1
fi

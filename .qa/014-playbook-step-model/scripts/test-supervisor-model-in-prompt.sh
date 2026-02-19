#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Supervisor prompt documents model selection behavior for Task delegation
# Criterion: US1.AC2+US1.AC3 — "The playbook supervisor MUST pass the step's model value to the Task subagent when present, and MUST NOT pass a model override when absent."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SUPERVISOR="$PROJECT_ROOT/.claude/commands/playbook.run.md"

if [ ! -f "$SUPERVISOR" ]; then
  echo "FAIL: Supervisor prompt not found" >&2
  echo "  Expected: $SUPERVISOR exists" >&2
  exit 1
fi

CONTENT=$(cat "$SUPERVISOR")
FAILED=0

# Check that the supervisor prompt mentions model selection for Task delegation
if ! echo "$CONTENT" | grep -qi "model"; then
  echo "FAIL: Supervisor prompt does not mention model selection" >&2
  echo "  Expected: prompt contains model selection instructions" >&2
  FAILED=1
fi

# Check that it mentions passing model to Task tool
if ! echo "$CONTENT" | grep -qi "model.*task\|task.*model"; then
  echo "FAIL: Supervisor prompt does not connect model to Task tool" >&2
  echo "  Expected: prompt mentions passing model to Task tool" >&2
  FAILED=1
fi

# Check that it mentions null/absent model means session default
if ! echo "$CONTENT" | grep -qi "null\|absent\|omit\|default"; then
  echo "FAIL: Supervisor prompt does not address absent model (session default)" >&2
  echo "  Expected: prompt mentions session default when model is null/absent" >&2
  FAILED=1
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: Supervisor prompt documents model selection for Task delegation"
  exit 0
else
  exit 1
fi

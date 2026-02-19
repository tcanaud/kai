#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Step with a valid model value passes validation
# Criterion: US1.AC1 — "Given a playbook with a step that has model: 'sonnet', When the playbook is validated, Then validation passes without errors."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$PROJECT_ROOT/packages/playbook/bin/cli.js"
TMPFILE="$(mktemp /tmp/qa-014-XXXXXX.yaml)"
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" <<'YAML'
name: "test-valid-model"
description: "Test playbook with valid model on a step"
version: "1.0"

args: []

steps:
  - id: "step-with-sonnet"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "sonnet"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

OUTPUT=$(node "$CLI" check "$TMPFILE" 2>&1) || {
  echo "FAIL: Playbook with model: 'sonnet' should pass validation" >&2
  echo "  Expected: validation passes (exit 0)" >&2
  echo "  Actual: $OUTPUT" >&2
  exit 1
}

if echo "$OUTPUT" | grep -q "is valid"; then
  echo "PASS: Playbook with model: 'sonnet' passes validation without errors"
  exit 0
else
  echo "FAIL: Validator output does not confirm validity" >&2
  echo "  Expected: output containing 'is valid'" >&2
  echo "  Actual: $OUTPUT" >&2
  exit 1
fi

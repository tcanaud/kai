#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Playbook with no model field on any step passes validation
# Criterion: US2.AC3 — "Given a playbook with no model field on any step, When the user runs the validation tool, Then validation passes (the field is optional)."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$PROJECT_ROOT/packages/playbook/bin/cli.js"
TMPFILE="$(mktemp /tmp/qa-014-XXXXXX.yaml)"
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" <<'YAML'
name: "test-no-model-field"
description: "Playbook with no model field on any step"
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
  - id: "step-2"
    command: "/speckit.implement"
    args: ""
    autonomy: "auto"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

OUTPUT=$(node "$CLI" check "$TMPFILE" 2>&1) || {
  echo "FAIL: Playbook without model fields should pass validation" >&2
  echo "  Expected: validation passes (exit 0)" >&2
  echo "  Actual: $OUTPUT" >&2
  exit 1
}

if echo "$OUTPUT" | grep -q "is valid"; then
  echo "PASS: Playbook with no model fields passes validation (field is optional)"
  exit 0
else
  echo "FAIL: Validator output does not confirm validity" >&2
  echo "  Expected: output containing 'is valid'" >&2
  echo "  Actual: $OUTPUT" >&2
  exit 1
fi

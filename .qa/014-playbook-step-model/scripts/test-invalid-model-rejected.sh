#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Invalid model value is rejected by the validator with clear error
# Criterion: US2.AC1 — "Given a playbook with model: 'invalid-model' on a step, When the user runs the validation tool, Then the tool reports a violation identifying the invalid model value and listing the allowed values."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$PROJECT_ROOT/packages/playbook/bin/cli.js"
TMPFILE="$(mktemp /tmp/qa-014-XXXXXX.yaml)"
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" <<'YAML'
name: "test-invalid-model"
description: "Playbook with invalid model value"
version: "1.0"

args: []

steps:
  - id: "bad-step"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "invalid-model"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

OUTPUT=$(node "$CLI" check "$TMPFILE" 2>&1) && {
  echo "FAIL: Validation should have failed for model: 'invalid-model'" >&2
  echo "  Expected: non-zero exit code (validation failure)" >&2
  echo "  Actual: exit 0 with output: $OUTPUT" >&2
  exit 1
}

# Check that the error message mentions the invalid model and lists allowed values
if echo "$OUTPUT" | grep -qi "invalid-model" && echo "$OUTPUT" | grep -qi "opus"; then
  echo "PASS: Invalid model 'invalid-model' rejected with violation listing allowed values"
  exit 0
else
  echo "FAIL: Error message does not properly identify the invalid model or list allowed values" >&2
  echo "  Expected: message mentioning 'invalid-model' and listing allowed values (opus, sonnet, haiku)" >&2
  echo "  Actual: $OUTPUT" >&2
  exit 1
fi

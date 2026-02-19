#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Valid model value produces no model-related validation errors
# Criterion: US2.AC2 — "Given a playbook with model: 'sonnet' on a step, When the user runs the validation tool, Then validation passes without model-related errors."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$PROJECT_ROOT/packages/playbook/bin/cli.js"
TMPFILE="$(mktemp /tmp/qa-014-XXXXXX.yaml)"
trap 'rm -f "$TMPFILE"' EXIT

# Test all three valid model values
for MODEL in opus sonnet haiku; do
  cat > "$TMPFILE" <<YAML
name: "test-model-${MODEL}"
description: "Test with model ${MODEL}"
version: "1.0"

args: []

steps:
  - id: "step-1"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "${MODEL}"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

  OUTPUT=$(node "$CLI" check "$TMPFILE" 2>&1) || {
    echo "FAIL: Model '${MODEL}' should be valid but validation failed" >&2
    echo "  Expected: validation passes for model '${MODEL}'" >&2
    echo "  Actual: $OUTPUT" >&2
    exit 1
  }

  if ! echo "$OUTPUT" | grep -q "is valid"; then
    echo "FAIL: Validator did not confirm validity for model '${MODEL}'" >&2
    echo "  Expected: 'is valid' in output" >&2
    echo "  Actual: $OUTPUT" >&2
    exit 1
  fi
done

echo "PASS: All valid model values (opus, sonnet, haiku) pass validation without errors"
exit 0

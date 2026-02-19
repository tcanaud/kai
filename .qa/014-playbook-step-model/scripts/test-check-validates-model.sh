#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: npx @tcanaud/playbook check validates model values and rejects invalid ones
# Criterion: IF2 — "Validates model field values; rejects invalid models with violation message."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$PROJECT_ROOT/packages/playbook/bin/cli.js"
TMPFILE="$(mktemp /tmp/qa-014-XXXXXX.yaml)"
trap 'rm -f "$TMPFILE"' EXIT

FAILED=0

# Test 1: Valid model accepted
cat > "$TMPFILE" <<'YAML'
name: "test-check-valid"
description: "Valid model"
version: "1.0"

args: []

steps:
  - id: "step-1"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "opus"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

OUTPUT=$(node "$CLI" check "$TMPFILE" 2>&1) || {
  echo "FAIL: Valid model 'opus' should be accepted" >&2
  echo "  Expected: exit 0" >&2
  echo "  Actual: $OUTPUT" >&2
  FAILED=1
}

# Test 2: Invalid model rejected with violation message
cat > "$TMPFILE" <<'YAML'
name: "test-check-invalid"
description: "Invalid model"
version: "1.0"

args: []

steps:
  - id: "step-1"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "gpt4"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

OUTPUT=$(node "$CLI" check "$TMPFILE" 2>&1) && {
  echo "FAIL: Invalid model 'gpt4' should be rejected" >&2
  echo "  Expected: non-zero exit code" >&2
  echo "  Actual: exit 0 with output: $OUTPUT" >&2
  FAILED=1
}

# Verify the violation message is informative
if ! echo "$OUTPUT" | grep -qi "gpt4"; then
  echo "FAIL: Violation message should mention the invalid value 'gpt4'" >&2
  echo "  Expected: message containing 'gpt4'" >&2
  echo "  Actual: $OUTPUT" >&2
  FAILED=1
fi

# Test 3: Case sensitivity — "Sonnet" (capital S) should be rejected
cat > "$TMPFILE" <<'YAML'
name: "test-check-case"
description: "Case-sensitive model"
version: "1.0"

args: []

steps:
  - id: "step-1"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "Sonnet"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

OUTPUT=$(node "$CLI" check "$TMPFILE" 2>&1) && {
  echo "FAIL: Model 'Sonnet' (capital S) should be rejected (case-sensitive)" >&2
  echo "  Expected: non-zero exit code" >&2
  echo "  Actual: exit 0 with output: $OUTPUT" >&2
  FAILED=1
}

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: check command validates model values and rejects invalid ones with violation messages"
  exit 0
else
  exit 1
fi

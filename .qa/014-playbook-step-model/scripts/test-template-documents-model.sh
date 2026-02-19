#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Playbook template documents the model field with allowed values
# Criterion: US3.AC1 — "Given the playbook template file, When a user views the schema reference comments, Then the model field is documented with its allowed values and optional nature."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TEMPLATE="$PROJECT_ROOT/.playbooks/playbooks/playbook.tpl.yaml"

if [ ! -f "$TEMPLATE" ]; then
  echo "FAIL: Playbook template not found" >&2
  echo "  Expected: file exists at $TEMPLATE" >&2
  echo "  Actual: file not found" >&2
  exit 1
fi

CONTENT=$(cat "$TEMPLATE")
FAILED=0

# Check that 'model' is mentioned in the schema reference
if ! echo "$CONTENT" | grep -q "model:"; then
  echo "FAIL: Template does not document the 'model' field" >&2
  echo "  Expected: 'model:' appears in schema reference comments" >&2
  FAILED=1
fi

# Check that allowed values are listed
for VALUE in opus sonnet haiku; do
  if ! echo "$CONTENT" | grep -q "$VALUE"; then
    echo "FAIL: Template does not list allowed model value '$VALUE'" >&2
    echo "  Expected: '$VALUE' appears in template documentation" >&2
    FAILED=1
  fi
done

# Check that optional nature is indicated
if ! echo "$CONTENT" | grep -qi "optional\|omit"; then
  echo "FAIL: Template does not indicate model field is optional" >&2
  echo "  Expected: documentation mentions 'optional' or 'omit'" >&2
  FAILED=1
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: Template documents model field with allowed values and optional nature"
  exit 0
else
  exit 1
fi

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Existing playbooks without model fields still validate and execute
# Criterion: US3.AC2 — "Given a user creates a playbook via /playbook.create, When the playbook is generated, Then any model fields included in the output use valid model values."
# Also covers: FR-011 — existing playbooks without model fields MUST continue to validate
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$PROJECT_ROOT/packages/playbook/bin/cli.js"
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"

shopt -s nullglob
playbooks=("$PLAYBOOKS_DIR"/*.yaml)
shopt -u nullglob

if [ ${#playbooks[@]} -eq 0 ]; then
  echo "SKIP: No playbooks found in $PLAYBOOKS_DIR" >&2
  exit 0
fi

FAILED=0
CHECKED=0

for pb in "${playbooks[@]}"; do
  name="$(basename "$pb")"
  [ "$name" = "playbook.tpl.yaml" ] && continue

  CHECKED=$((CHECKED + 1))
  OUTPUT=$(node "$CLI" check "$pb" 2>&1) || {
    echo "FAIL: Existing playbook '$name' does not pass validation" >&2
    echo "  Expected: validation passes (backward compatibility)" >&2
    echo "  Actual: $OUTPUT" >&2
    FAILED=1
    continue
  }

  if ! echo "$OUTPUT" | grep -q "is valid"; then
    echo "FAIL: Validator did not confirm validity for '$name'" >&2
    echo "  Expected: 'is valid' in output" >&2
    echo "  Actual: $OUTPUT" >&2
    FAILED=1
  fi
done

if [ "$CHECKED" -eq 0 ]; then
  echo "SKIP: No non-template playbooks found to validate" >&2
  exit 0
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All $CHECKED existing playbooks validate successfully (backward compatible)"
  exit 0
else
  exit 1
fi

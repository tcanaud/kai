#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Generated playbook passes the playbook validator with zero violations
# Criterion: US1.AC3 — "Given a generated playbook file, When running the playbook validator, Then the playbook passes validation with zero violations."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
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
  OUTPUT=$(node "$PROJECT_ROOT/packages/playbook/bin/cli.js" check "$pb" 2>&1) || {
    echo "FAIL: Playbook '$name' has validation violations" >&2
    echo "  Expected: is valid (zero violations)" >&2
    echo "  Actual: $OUTPUT" >&2
    FAILED=1
    continue
  }

  if ! echo "$OUTPUT" | grep -q "is valid"; then
    echo "FAIL: Playbook '$name' validator output does not contain 'is valid'" >&2
    echo "  Expected: output containing 'is valid'" >&2
    echo "  Actual: $OUTPUT" >&2
    FAILED=1
  fi
done

if [ "$CHECKED" -eq 0 ]; then
  echo "SKIP: No non-template playbooks found to validate" >&2
  exit 0
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All $CHECKED playbooks pass validator with zero violations"
  exit 0
else
  exit 1
fi

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Each step has valid autonomy level, conditions from allowed vocabulary, and valid error policy
# Criterion: US1.AC2 — "Given the developer provides an intention, When the system generates the playbook, Then each step has an appropriate autonomy level (e.g., validation steps are auto, PR creation is gate_always), meaningful pre/postconditions from the allowed vocabulary, and a sensible error policy."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Run the existing unit tests that validate autonomy, error_policy, conditions, and escalation triggers
cd "$PROJECT_ROOT/packages/playbook"

# The playbook-create.test.js already validates all enum values for generated playbooks
OUTPUT=$(node --test tests/playbook-create.test.js 2>&1) || {
  echo "FAIL: Playbook create tests failed — step autonomy/policy validation errors" >&2
  echo "Expected: All tests pass with valid autonomy, error_policy, conditions, escalation_triggers" >&2
  echo "Actual output:" >&2
  echo "$OUTPUT" >&2
  exit 1
}

# Additionally verify that existing playbooks in the project have PR steps gated
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"
shopt -s nullglob
playbooks=("$PLAYBOOKS_DIR"/*.yaml)
shopt -u nullglob

for pb in "${playbooks[@]}"; do
  name="$(basename "$pb")"
  [ "$name" = "playbook.tpl.yaml" ] && continue

  # Check if playbook has a PR step — if so, it should be gate_always
  IN_PR_STEP=0
  while IFS= read -r line; do
    if [[ "$line" =~ command:.*feature\.pr ]]; then
      IN_PR_STEP=1
    elif [ "$IN_PR_STEP" -eq 1 ] && [[ "$line" =~ autonomy:\ *\"([^\"]+)\" ]]; then
      autonomy="${BASH_REMATCH[1]}"
      if [ "$autonomy" != "gate_always" ]; then
        echo "FAIL: Playbook '$name' has PR step with autonomy '$autonomy' instead of 'gate_always'" >&2
        exit 1
      fi
      IN_PR_STEP=0
    elif [ "$IN_PR_STEP" -eq 1 ] && [[ "$line" =~ ^[[:space:]]*-\ id: ]]; then
      # Moved to next step without finding autonomy
      IN_PR_STEP=0
    fi
  done < "$pb"
done

echo "PASS: All steps have valid autonomy levels, conditions, and error policies"
exit 0

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Feature-specific references use {{feature}} argument interpolation
# Criterion: US4.AC1 — "Given the developer requests a playbook for a workflow that involves feature-specific artifacts, When the system generates the playbook, Then all feature-specific references use {{feature}} argument interpolation, never hardcoded values."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Run the unit tests that validate {{arg}} referential integrity and no hardcoded values
cd "$PROJECT_ROOT/packages/playbook"
OUTPUT=$(node --test tests/playbook-create.test.js 2>&1) || {
  echo "FAIL: playbook-create tests failed — arg interpolation or hardcoded value issues" >&2
  echo "  Actual: $OUTPUT" >&2
  exit 1
}

# Verify all existing playbooks use {{feature}} where feature is declared
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"
shopt -s nullglob
playbooks=("$PLAYBOOKS_DIR"/*.yaml)
shopt -u nullglob

FAILED=0

for pb in "${playbooks[@]}"; do
  name="$(basename "$pb")"
  [ "$name" = "playbook.tpl.yaml" ] && continue

  # Check if playbook declares a feature arg
  if grep -q 'name:.*"feature"' "$pb" || grep -q "name:.*'feature'" "$pb"; then
    # If it declares feature arg, verify args fields use {{feature}} not hardcoded values
    # Look for args: lines with literal branch-like patterns
    if grep -E 'args:.*\b[0-9]{3}-[a-z]' "$pb"; then
      echo "FAIL: Playbook '$name' has hardcoded feature reference in step args" >&2
      echo "  Expected: {{feature}} interpolation" >&2
      FAILED=1
    fi
  fi
done

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All playbooks use {{feature}} interpolation — no hardcoded feature values"
  exit 0
else
  exit 1
fi

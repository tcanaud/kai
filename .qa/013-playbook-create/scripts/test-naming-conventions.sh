#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Playbook names follow lowercase slug convention consistent with existing playbooks
# Criterion: US2.AC3 — "Given a project with documented conventions in .knowledge/, When the system generates a playbook, Then the playbook name follows the project's naming conventions (lowercase slug, consistent with existing playbook names)."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"
SLUG_PATTERN='^[a-z0-9-]+$'

shopt -s nullglob
playbooks=("$PLAYBOOKS_DIR"/*.yaml)
shopt -u nullglob

if [ ${#playbooks[@]} -eq 0 ]; then
  echo "SKIP: No playbooks found" >&2
  exit 0
fi

FAILED=0
CHECKED=0

for pb in "${playbooks[@]}"; do
  name="$(basename "$pb")"
  [ "$name" = "playbook.tpl.yaml" ] && continue
  CHECKED=$((CHECKED + 1))

  # Extract the name field from the YAML
  pb_name=$(grep -m1 '^name:' "$pb" | sed 's/^name:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/')

  if [ -z "$pb_name" ]; then
    echo "FAIL: Playbook '$name' has no name field" >&2
    FAILED=1
    continue
  fi

  if ! echo "$pb_name" | grep -qE "$SLUG_PATTERN"; then
    echo "FAIL: Playbook name '$pb_name' in '$name' does not match [a-z0-9-]+" >&2
    echo "  Expected: lowercase slug matching $SLUG_PATTERN" >&2
    echo "  Actual: '$pb_name'" >&2
    FAILED=1
  fi
done

if [ "$CHECKED" -eq 0 ]; then
  echo "SKIP: No non-template playbooks found" >&2
  exit 0
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All $CHECKED playbook names follow lowercase slug convention [a-z0-9-]+"
  exit 0
else
  exit 1
fi

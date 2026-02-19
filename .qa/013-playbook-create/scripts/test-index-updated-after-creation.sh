#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Playbook index is updated with the new entry after playbook creation
# Criterion: US3.AC4 — "Given the developer approves the final playbook, When the system writes it to disk, Then the playbook index (.playbooks/_index.yaml) is updated to include the new playbook entry."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
INDEX_FILE="$PROJECT_ROOT/.playbooks/_index.yaml"
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"

# Check that _index.yaml exists
if [ ! -f "$INDEX_FILE" ]; then
  echo "FAIL: Playbook index not found at $INDEX_FILE" >&2
  exit 1
fi

INDEX_CONTENT=$(cat "$INDEX_FILE")

# For each non-template playbook, verify it has an entry in the index
shopt -s nullglob
playbooks=("$PLAYBOOKS_DIR"/*.yaml)
shopt -u nullglob

FAILED=0
CHECKED=0

for pb in "${playbooks[@]}"; do
  fname="$(basename "$pb")"
  [ "$fname" = "playbook.tpl.yaml" ] && continue
  CHECKED=$((CHECKED + 1))

  # Extract playbook name from the YAML file
  pb_name=$(grep -m1 '^name:' "$pb" | sed 's/^name:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/')

  if [ -z "$pb_name" ]; then
    echo "FAIL: Could not extract name from $fname" >&2
    FAILED=1
    continue
  fi

  # Check if this name appears in the index
  if ! echo "$INDEX_CONTENT" | grep -q "$pb_name"; then
    echo "FAIL: Playbook '$pb_name' ($fname) not found in _index.yaml" >&2
    echo "  Expected: entry for '$pb_name' in .playbooks/_index.yaml" >&2
    FAILED=1
  fi
done

if [ "$CHECKED" -eq 0 ]; then
  echo "SKIP: No non-template playbooks to check" >&2
  exit 0
fi

# Also verify the template instructs index update
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"
if [ ! -f "$COMMAND_FILE" ]; then
  COMMAND_FILE="$PROJECT_ROOT/.claude/commands/playbook.create.md"
fi

if [ -f "$COMMAND_FILE" ]; then
  if ! grep -qi "_index.yaml\|index.*update\|update.*index" "$COMMAND_FILE"; then
    echo "FAIL: Template does not instruct updating _index.yaml" >&2
    FAILED=1
  fi
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All $CHECKED playbooks have entries in _index.yaml"
  exit 0
else
  exit 1
fi

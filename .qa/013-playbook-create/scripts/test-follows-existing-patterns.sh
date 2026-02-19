#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Generated playbooks follow existing pattern conventions (e.g., gate_always for PR)
# Criterion: US2.AC2 — "Given a project where existing playbooks always use gate_always for PR creation, When the system generates a new playbook that includes a PR step, Then it follows the same pattern and sets the PR step to gate_always."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"
COMMAND_FILE="$PROJECT_ROOT/packages/playbook/templates/commands/playbook.create.md"

# Part 1: Verify existing playbooks follow the pattern (gate_always for PR)
shopt -s nullglob
playbooks=("$PLAYBOOKS_DIR"/*.yaml)
shopt -u nullglob

PR_STEPS_FOUND=0
PR_STEPS_GATED=0

for pb in "${playbooks[@]}"; do
  name="$(basename "$pb")"
  [ "$name" = "playbook.tpl.yaml" ] && continue

  NEXT_IS_PR=0
  while IFS= read -r line; do
    if [[ "$line" =~ command:.*feature\.pr ]]; then
      PR_STEPS_FOUND=$((PR_STEPS_FOUND + 1))
      NEXT_IS_PR=1
    elif [ "$NEXT_IS_PR" -eq 1 ] && [[ "$line" =~ autonomy:\ *\"gate_always\" ]]; then
      PR_STEPS_GATED=$((PR_STEPS_GATED + 1))
      NEXT_IS_PR=0
    elif [ "$NEXT_IS_PR" -eq 1 ] && [[ "$line" =~ autonomy: ]]; then
      echo "FAIL: Playbook '$name' has PR step without gate_always" >&2
      NEXT_IS_PR=0
    fi
  done < "$pb"
done

if [ "$PR_STEPS_FOUND" -gt 0 ] && [ "$PR_STEPS_FOUND" -ne "$PR_STEPS_GATED" ]; then
  echo "FAIL: Not all PR steps use gate_always ($PR_STEPS_GATED/$PR_STEPS_FOUND)" >&2
  exit 1
fi

# Part 2: Verify the command template instructs pattern extraction
if [ ! -f "$COMMAND_FILE" ]; then
  COMMAND_FILE="$PROJECT_ROOT/.claude/commands/playbook.create.md"
fi

if [ -f "$COMMAND_FILE" ]; then
  CONTENT=$(cat "$COMMAND_FILE")
  if echo "$CONTENT" | grep -qi "existing.*playbook.*pattern\|pattern.*extract"; then
    echo "PASS: Existing patterns are followed (PR gate_always: $PR_STEPS_GATED/$PR_STEPS_FOUND) and template instructs pattern extraction"
    exit 0
  else
    echo "FAIL: Template does not instruct extraction of patterns from existing playbooks" >&2
    exit 1
  fi
else
  echo "PASS: Existing patterns are followed (PR gate_always: $PR_STEPS_GATED/$PR_STEPS_FOUND)"
  exit 0
fi

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Generated playbook references only commands that exist in the project
# Criterion: US1.AC1 — "Given a project with kai installed and multiple slash commands available, When the developer runs /playbook.create with 'validate and deploy a hotfix for critical bugs', Then the system produces a valid playbook YAML file in .playbooks/playbooks/ with steps referencing only commands that exist in the project."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"

# Collect all existing playbooks (excluding template)
shopt -s nullglob
playbooks=("$PLAYBOOKS_DIR"/*.yaml)
shopt -u nullglob

if [ ${#playbooks[@]} -eq 0 ]; then
  echo "SKIP: No playbooks found in $PLAYBOOKS_DIR" >&2
  exit 0
fi

# Build list of available slash commands from .claude/commands/
AVAILABLE_COMMANDS=""
if [ -d "$COMMANDS_DIR" ]; then
  for cmd_file in "$COMMANDS_DIR"/*.md; do
    basename_no_ext="$(basename "$cmd_file" .md)"
    AVAILABLE_COMMANDS="$AVAILABLE_COMMANDS /$basename_no_ext "
  done
fi

FAILED=0

for pb in "${playbooks[@]}"; do
  name="$(basename "$pb")"
  # Skip the template
  if [ "$name" = "playbook.tpl.yaml" ]; then
    continue
  fi

  # Extract command lines from the playbook
  while IFS= read -r line; do
    # Match lines like: command: "/speckit.plan"
    if [[ "$line" =~ command:\ *\"(/[^\"]+)\" ]]; then
      cmd="${BASH_REMATCH[1]}"
      # Convert slash command to expected filename: /speckit.plan -> speckit.plan
      cmd_file="${cmd#/}"
      if [[ "$AVAILABLE_COMMANDS" != *" $cmd "* ]]; then
        echo "FAIL: Playbook '$name' references command '$cmd' which does not exist in .claude/commands/" >&2
        echo "  Expected: .claude/commands/${cmd_file}.md" >&2
        echo "  Actual: file not found" >&2
        FAILED=1
      fi
    fi
  done < "$pb"
done

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All playbooks reference only existing slash commands"
  exit 0
else
  exit 1
fi

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: No step references a specific feature ID, branch name, or feature-specific file path
# Criterion: US4.AC2 — "Given a generated playbook, When inspecting its content, Then no step references a specific feature ID, branch name, file path with a feature number, or any other feature-specific value."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"

# Patterns that indicate hardcoded feature-specific values
# (mirrors the patterns in playbook-create.test.js)
HARDCODED_PATTERNS=(
  '[0-9]{3}-[a-z]'            # branch-like: 013-my-feature
  'specs/[0-9]{3}'            # hardcoded spec paths
  '\.agreements/[0-9]{3}'     # hardcoded agreement paths
  '\.qa/[0-9]{3}'             # hardcoded QA paths
  '\.features/[0-9]{3}'       # hardcoded feature paths
)

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

  CONTENT=$(cat "$pb")

  for pattern in "${HARDCODED_PATTERNS[@]}"; do
    # Exclude description fields (which may legitimately contain examples like "013-my-feature")
    # Only check step-level fields: command, args, preconditions, postconditions
    STEP_CONTENT=$(echo "$CONTENT" | grep -E '^\s*(command|args|preconditions|postconditions|escalation_triggers|id|error_policy|autonomy):' || true)

    if echo "$STEP_CONTENT" | grep -qE "$pattern"; then
      echo "FAIL: Playbook '$name' contains hardcoded feature-specific value matching pattern '$pattern'" >&2
      echo "  Expected: No feature-specific hardcoded values in step fields" >&2
      FAILED=1
    fi
  done
done

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All $CHECKED playbooks contain no hardcoded feature-specific values in step fields"
  exit 0
else
  exit 1
fi

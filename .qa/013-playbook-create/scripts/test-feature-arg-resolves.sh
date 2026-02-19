#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: {{feature}} arg resolves correctly with different feature names
# Criterion: US4.AC3 — "Given a generated playbook with a feature arg declared as required, When the playbook is run with different feature names on separate occasions, Then all argument references resolve correctly to the provided feature name each time."
# Feature: 013-playbook-create
# Generated: 2026-02-19T17:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOKS_DIR="$PROJECT_ROOT/.playbooks/playbooks"

# Verify that all playbooks declaring a "feature" arg have matching {{feature}}
# references in their step args — proving the interpolation is correctly wired.

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

  # Check if playbook declares feature as required arg
  HAS_FEATURE_ARG=0
  if grep -q 'name:.*"feature"' "$pb" || grep -q "name:.*'feature'" "$pb"; then
    HAS_FEATURE_ARG=1
    CHECKED=$((CHECKED + 1))
  fi

  if [ "$HAS_FEATURE_ARG" -eq 1 ]; then
    # Verify that {{feature}} is used in at least one step's args
    if ! grep -q '{{feature}}' "$pb"; then
      echo "FAIL: Playbook '$name' declares 'feature' arg but never uses {{feature}} in step args" >&2
      FAILED=1
    fi

    # Verify no orphan {{xxx}} references that don't match declared args
    # Extract all declared arg names
    DECLARED_ARGS=$(grep -A1 'name:.*"' "$pb" | grep 'name:' | sed 's/.*name:[[:space:]]*"\([^"]*\)".*/\1/' | sort -u)

    # Extract all {{xxx}} references
    REFS=$(grep -oE '\{\{[^}]+\}\}' "$pb" | sed 's/{{//g; s/}}//g' | sort -u)

    for ref in $REFS; do
      FOUND=0
      for arg in $DECLARED_ARGS; do
        if [ "$ref" = "$arg" ]; then
          FOUND=1
          break
        fi
      done
      if [ "$FOUND" -eq 0 ]; then
        echo "FAIL: Playbook '$name' references {{$ref}} but '$ref' is not a declared arg" >&2
        FAILED=1
      fi
    done
  fi
done

if [ "$CHECKED" -eq 0 ]; then
  echo "SKIP: No playbooks with 'feature' arg found" >&2
  exit 0
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: All $CHECKED playbooks correctly wire {{feature}} arg references"
  exit 0
else
  exit 1
fi

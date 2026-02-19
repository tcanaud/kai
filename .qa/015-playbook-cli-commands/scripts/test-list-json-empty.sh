#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: List command returns empty JSON array when no sessions
# Criterion: US2.AC3 — "Given no sessions exist in the system, When the user runs node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list --json, Then valid empty JSON (empty array) is returned"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories (empty)
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Do NOT create any sessions

# Run the list command with --json
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list --json 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Verify output is valid empty JSON array
if [ "$OUTPUT" != "[]" ]; then
  echo "FAIL: Output is not empty JSON array"
  echo "Expected: []"
  echo "Got: $OUTPUT"
  exit 1
fi

exit 0

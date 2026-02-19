#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Status command handles no running sessions gracefully
# Criterion: US1.AC3 — "Given no playbook sessions are running, When the user runs node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status, Then the command displays a clear message indicating no active sessions"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories (but empty)
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Do NOT create any sessions

# Run the status command
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Verify output indicates no sessions
if echo "$OUTPUT" | grep -q -E "(No.*session|no.*session|not found|empty)"; then
  exit 0
else
  echo "FAIL: Output does not indicate no sessions"
  echo "Expected: message indicating no active sessions"
  echo "Got: $OUTPUT"
  exit 1
fi

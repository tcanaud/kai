#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Terminal output is fully visible in 80+ character width
# Criterion: US4.AC2 — "Given terminal output is produced, When viewed in a standard terminal (80+ character width), Then content is fully visible without horizontal scrolling for typical session counts"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories with multiple sessions
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create 10 test sessions (typical use case)
for i in {1..10}; do
  SESSION_ID="20260219-$(printf '%03d' $i)"
  SESSION_DIR="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID"
  mkdir -p "$SESSION_DIR"
  cat > "$SESSION_DIR/session.yaml" << EOF
session_id: "$SESSION_ID"
playbook: "test-playbook-$i"
feature: "test-feature-$i"
args: {}
status: "running"
started_at: "2026-02-19T1${i}:00:00.000Z"
completed_at: ""
current_step: ""
worktree: ""
EOF
  echo "entries: []" > "$SESSION_DIR/journal.yaml"
done

# Run the list command
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Check that the longest line doesn't exceed 80 characters
MAX_LINE_LENGTH=$(echo "$OUTPUT" | awk '{ print length }' | sort -rn | head -1)

if [ "$MAX_LINE_LENGTH" -gt 80 ]; then
  echo "FAIL: Output exceeds 80 character width"
  echo "Expected: all lines <= 80 characters"
  echo "Got: maximum line length = $MAX_LINE_LENGTH characters"
  echo "Output:"
  echo "$OUTPUT"
  exit 1
fi

exit 0

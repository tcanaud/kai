#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Status command displays single running session
# Criterion: US1.AC1 — "Given one playbook session is currently running, When the user runs npx @tcanaud/playbook status, Then the terminal displays the session ID, creation time, current status, and any relevant progress information in a human-readable format"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create a test session directory
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create a running session
SESSION_ID="20260219-abc"
SESSION_DIR="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"

# Write session.yaml with running status
cat > "$SESSION_DIR/session.yaml" << 'EOF'
session_id: "20260219-abc"
playbook: "test-playbook"
feature: "test-feature"
args: {}
status: "running"
started_at: "2026-02-19T10:00:00.000Z"
completed_at: ""
current_step: ""
worktree: ""
EOF

# Write empty journal
echo "entries: []" > "$SESSION_DIR/journal.yaml"

# Run the status command (use node directly with full path to CLI to avoid npx lookup issues)
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Verify output contains session ID
if echo "$OUTPUT" | grep -q "20260219-abc"; then
  # Verify output contains status indicator
  if echo "$OUTPUT" | grep -q -E "(Running|running|→)"; then
    # Verify timestamp format
    if echo "$OUTPUT" | grep -q "2026-02-19"; then
      exit 0
    else
      echo "FAIL: Output missing timestamp"
      echo "Expected: timestamp in format 2026-02-19"
      echo "Got: $OUTPUT"
      exit 1
    fi
  else
    echo "FAIL: Output missing status indicator"
    echo "Expected: 'Running' or similar status"
    echo "Got: $OUTPUT"
    exit 1
  fi
else
  echo "FAIL: Output missing session ID"
  echo "Expected: session ID '20260219-abc'"
  echo "Got: $OUTPUT"
  exit 1
fi

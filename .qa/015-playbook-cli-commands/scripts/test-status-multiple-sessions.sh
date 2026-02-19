#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Status command displays multiple running sessions
# Criterion: US1.AC2 — "Given multiple playbook sessions are running simultaneously, When the user runs node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status, Then all sessions are displayed with clear visual separation"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create first running session
SESSION_ID1="20260219-abc"
SESSION_DIR1="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID1"
mkdir -p "$SESSION_DIR1"
cat > "$SESSION_DIR1/session.yaml" << 'EOF'
session_id: "20260219-abc"
playbook: "test-playbook-1"
feature: "test-feature-1"
args: {}
status: "running"
started_at: "2026-02-19T10:00:00.000Z"
completed_at: ""
current_step: ""
worktree: ""
EOF
echo "entries: []" > "$SESSION_DIR1/journal.yaml"

# Create second running session
SESSION_ID2="20260219-xyz"
SESSION_DIR2="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID2"
mkdir -p "$SESSION_DIR2"
cat > "$SESSION_DIR2/session.yaml" << 'EOF'
session_id: "20260219-xyz"
playbook: "test-playbook-2"
feature: "test-feature-2"
args: {}
status: "in_progress"
started_at: "2026-02-19T09:30:00.000Z"
completed_at: ""
current_step: ""
worktree: ""
EOF
echo "entries: []" > "$SESSION_DIR2/journal.yaml"

# Run the status command
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Verify both session IDs are in output
if ! echo "$OUTPUT" | grep -q "20260219-abc"; then
  echo "FAIL: Output missing first session ID"
  echo "Expected: session ID '20260219-abc'"
  echo "Got: $OUTPUT"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "20260219-xyz"; then
  echo "FAIL: Output missing second session ID"
  echo "Expected: session ID '20260219-xyz'"
  echo "Got: $OUTPUT"
  exit 1
fi

# Verify clear visual separation (look for newlines or table structure)
LINE_COUNT=$(echo "$OUTPUT" | wc -l)
if [ "$LINE_COUNT" -lt 3 ]; then
  echo "FAIL: Output lacks clear visual separation"
  echo "Expected: multiple lines showing table structure"
  echo "Got: $OUTPUT"
  exit 1
fi

exit 0

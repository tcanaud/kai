#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: List command displays all sessions with different statuses
# Criterion: US3.AC1 — "Given multiple playbook sessions with different statuses exist, When the user runs node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list, Then all sessions are displayed in a table or list format with clear status indicators (running, completed, failed)"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create a running session
SESSION_ID1="20260219-abc"
SESSION_DIR1="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID1"
mkdir -p "$SESSION_DIR1"
cat > "$SESSION_DIR1/session.yaml" << 'EOF'
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
echo "entries: []" > "$SESSION_DIR1/journal.yaml"

# Create a completed session
SESSION_ID2="20260219-def"
SESSION_DIR2="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID2"
mkdir -p "$SESSION_DIR2"
cat > "$SESSION_DIR2/session.yaml" << 'EOF'
session_id: "20260219-def"
playbook: "test-playbook"
feature: "test-feature"
args: {}
status: "completed"
started_at: "2026-02-19T09:00:00.000Z"
completed_at: "2026-02-19T09:05:00.000Z"
current_step: ""
worktree: ""
EOF
echo "entries: []" > "$SESSION_DIR2/journal.yaml"

# Create a failed session
SESSION_ID3="20260219-ghi"
SESSION_DIR3="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID3"
mkdir -p "$SESSION_DIR3"
cat > "$SESSION_DIR3/session.yaml" << 'EOF'
session_id: "20260219-ghi"
playbook: "test-playbook"
feature: "test-feature"
args: {}
status: "failed"
started_at: "2026-02-19T08:00:00.000Z"
completed_at: "2026-02-19T08:05:00.000Z"
current_step: ""
worktree: ""
EOF
echo "entries: []" > "$SESSION_DIR3/journal.yaml"

# Run the list command (without --json)
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Verify all three sessions are in output
if ! echo "$OUTPUT" | grep -q "20260219-abc"; then
  echo "FAIL: Output missing running session"
  echo "Got: $OUTPUT"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "20260219-def"; then
  echo "FAIL: Output missing completed session"
  echo "Got: $OUTPUT"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "20260219-ghi"; then
  echo "FAIL: Output missing failed session"
  echo "Got: $OUTPUT"
  exit 1
fi

# Verify status indicators are present
if ! echo "$OUTPUT" | grep -q -E "(Running|Completed|Failed|running|completed|failed|→|✓|✗)"; then
  echo "FAIL: Output missing status indicators"
  echo "Got: $OUTPUT"
  exit 1
fi

exit 0

#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: List command sorts sessions chronologically (most recent first)
# Criterion: US3.AC2 — "Given sessions have varying timestamps, When node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list is executed, Then output is sorted chronologically (most recent first) for easy scanning"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create older session (20260218-xyz)
SESSION_ID1="20260218-xyz"
SESSION_DIR1="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID1"
mkdir -p "$SESSION_DIR1"
cat > "$SESSION_DIR1/session.yaml" << 'EOF'
session_id: "20260218-xyz"
playbook: "test-playbook"
feature: "test-feature"
args: {}
status: "completed"
started_at: "2026-02-18T10:00:00.000Z"
completed_at: "2026-02-18T10:05:00.000Z"
current_step: ""
worktree: ""
EOF
echo "entries: []" > "$SESSION_DIR1/journal.yaml"

# Create newer session (20260219-abc)
SESSION_ID2="20260219-abc"
SESSION_DIR2="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID2"
mkdir -p "$SESSION_DIR2"
cat > "$SESSION_DIR2/session.yaml" << 'EOF'
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
echo "entries: []" > "$SESSION_DIR2/journal.yaml"

# Create middle session (20260219-def) - created after the date changes
SESSION_ID3="20260219-def"
SESSION_DIR3="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID3"
mkdir -p "$SESSION_DIR3"
cat > "$SESSION_DIR3/session.yaml" << 'EOF'
session_id: "20260219-def"
playbook: "test-playbook"
feature: "test-feature"
args: {}
status: "completed"
started_at: "2026-02-19T09:30:00.000Z"
completed_at: "2026-02-19T09:35:00.000Z"
current_step: ""
worktree: ""
EOF
echo "entries: []" > "$SESSION_DIR3/journal.yaml"

# Run the list command
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Extract the order of session IDs from the output
# Most recent (20260219-abc) should appear first, then 20260219-def, then 20260218-xyz
LINE1=$(echo "$OUTPUT" | grep "20260219-abc" | head -1)
LINE2=$(echo "$OUTPUT" | grep "20260219-def" | head -1)
LINE3=$(echo "$OUTPUT" | grep "20260218-xyz" | head -1)

if [ -z "$LINE1" ] || [ -z "$LINE2" ] || [ -z "$LINE3" ]; then
  echo "FAIL: Not all sessions found in output"
  echo "Got: $OUTPUT"
  exit 1
fi

# Get line numbers to verify order (most recent first)
LINE_NUM1=$(echo "$OUTPUT" | grep -n "20260219-abc" | head -1 | cut -d: -f1)
LINE_NUM2=$(echo "$OUTPUT" | grep -n "20260219-def" | head -1 | cut -d: -f1)
LINE_NUM3=$(echo "$OUTPUT" | grep -n "20260218-xyz" | head -1 | cut -d: -f1)

# Most recent should have smallest line number (appears first)
if [ "$LINE_NUM1" -gt "$LINE_NUM2" ] || [ "$LINE_NUM2" -gt "$LINE_NUM3" ]; then
  echo "FAIL: Sessions not sorted by most recent first"
  echo "Expected order: 20260219-abc, 20260219-def, 20260218-xyz"
  echo "Got: $OUTPUT"
  exit 1
fi

exit 0

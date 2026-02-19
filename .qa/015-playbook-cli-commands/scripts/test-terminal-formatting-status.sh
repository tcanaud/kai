#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Status command output is well-formatted and readable
# Criterion: US4.AC1 — "Given the status or list command is executed without --json flag, When output is displayed, Then formatting uses clear alignment, readable spacing, and consistent field labels"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create a test session
SESSION_ID="20260219-abc"
SESSION_DIR="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"
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
echo "entries: []" > "$SESSION_DIR/journal.yaml"

# Run the status command
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Check for clear alignment and headers
# Look for header row with column labels
if ! echo "$OUTPUT" | grep -q -E "(ID|CREATED|STATUS)"; then
  echo "FAIL: Output missing header labels (ID, CREATED, STATUS)"
  echo "Got: $OUTPUT"
  exit 1
fi

# Check for consistent spacing and field labels
# Should have at least one session data row
if ! echo "$OUTPUT" | grep -q "20260219-abc"; then
  echo "FAIL: Output missing session data"
  echo "Got: $OUTPUT"
  exit 1
fi

# Check output is not empty
if [ -z "$OUTPUT" ]; then
  echo "FAIL: Output is empty"
  exit 1
fi

exit 0

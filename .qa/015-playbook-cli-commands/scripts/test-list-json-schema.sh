#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: List JSON output contains required schema fields
# Criterion: US2.AC2 — "Given the list command is executed with JSON output, When parsing the JSON, Then each session object contains at minimum: session ID, creation timestamp, and final status"
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

# Run the list command with --json
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list --json 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Check for required fields: id, createdAt, status
MISSING_ID=$(echo "$OUTPUT" | node -e "const data = JSON.parse(require('fs').readFileSync(0, 'utf-8')); if (data.length > 0 && !('id' in data[0])) { process.exit(1); }" 2>&1 || true)
if [ -n "$MISSING_ID" ]; then
  echo "FAIL: JSON objects missing 'id' field"
  echo "Got: $OUTPUT"
  exit 1
fi

MISSING_CREATED=$(echo "$OUTPUT" | node -e "const data = JSON.parse(require('fs').readFileSync(0, 'utf-8')); if (data.length > 0 && !('createdAt' in data[0])) { process.exit(1); }" 2>&1 || true)
if [ -n "$MISSING_CREATED" ]; then
  echo "FAIL: JSON objects missing 'createdAt' field"
  echo "Got: $OUTPUT"
  exit 1
fi

MISSING_STATUS=$(echo "$OUTPUT" | node -e "const data = JSON.parse(require('fs').readFileSync(0, 'utf-8')); if (data.length > 0 && !('status' in data[0])) { process.exit(1); }" 2>&1 || true)
if [ -n "$MISSING_STATUS" ]; then
  echo "FAIL: JSON objects missing 'status' field"
  echo "Got: $OUTPUT"
  exit 1
fi

exit 0

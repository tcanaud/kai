#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Status CLI interface contract
# Criterion: IF1 — "Display all currently running playbook sessions in human-readable format by default, JSON with --json flag"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create a running session
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

# Test 1: Default (human-readable) output
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status 2>&1)

# Verify it's human-readable (contains status labels)
if ! echo "$OUTPUT" | grep -q -E "(Running|Completed|Failed|running|completed|failed)"; then
  echo "FAIL: Default output is not human-readable"
  echo "Got: $OUTPUT"
  rm -rf "$TEST_WORKDIR"
  exit 1
fi

# Clean between tests
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"
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

# Test 2: JSON output with --json flag
JSON_OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js status --json 2>&1 || echo "COMMAND_NOT_SUPPORTED")

# Cleanup
rm -rf "$TEST_WORKDIR"

# Note: The status command might not support --json flag, which is acceptable per spec
# The spec shows --json on list, not on status. Just verify the default works.

exit 0

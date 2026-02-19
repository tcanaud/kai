#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: List CLI interface contract
# Criterion: IF2 — "Display all playbook sessions (running and completed) in human-readable format by default, JSON with --json flag"
# Feature: 015-playbook-cli-commands
# Generated: 2026-02-19T00:00:00Z
# ──────────────────────────────────────────────────────

set -e

# Setup: Create test session directories
TEST_WORKDIR="${TMPDIR:-/tmp}/kai-playbook-test-workdir"
rm -rf "$TEST_WORKDIR"
mkdir -p "$TEST_WORKDIR/.playbooks/sessions"

# Create test sessions
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

# Test 1: Default (human-readable) output
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list 2>&1)

# Verify both sessions are present
if ! echo "$OUTPUT" | grep -q "20260219-abc"; then
  echo "FAIL: Default output missing running session"
  echo "Got: $OUTPUT"
  rm -rf "$TEST_WORKDIR"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "20260219-def"; then
  echo "FAIL: Default output missing completed session"
  echo "Got: $OUTPUT"
  rm -rf "$TEST_WORKDIR"
  exit 1
fi

# Verify it's human-readable (contains status labels)
if ! echo "$OUTPUT" | grep -q -E "(Running|Completed|Failed|running|completed|failed)"; then
  echo "FAIL: Default output is not human-readable"
  echo "Got: $OUTPUT"
  rm -rf "$TEST_WORKDIR"
  exit 1
fi

# Test 2: JSON output with --json flag
JSON_OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list --json 2>&1)

# Verify JSON is valid
if ! echo "$JSON_OUTPUT" | node -e "try { JSON.parse(require('fs').readFileSync(0, 'utf-8')); process.exit(0); } catch(e) { process.exit(1); }"; then
  echo "FAIL: JSON output is not valid JSON"
  echo "Got: $JSON_OUTPUT"
  rm -rf "$TEST_WORKDIR"
  exit 1
fi

# Cleanup
rm -rf "$TEST_WORKDIR"

exit 0

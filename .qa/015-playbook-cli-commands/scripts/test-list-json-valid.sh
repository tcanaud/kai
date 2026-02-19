#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: List command with --json outputs valid JSON
# Criterion: US2.AC1 — "Given multiple playbook sessions exist (running, completed, or failed), When the user runs node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list --json, Then the output is valid JSON containing an array of session objects with consistent schema"
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
SESSION_ID2="20260218-xyz"
SESSION_DIR2="$TEST_WORKDIR/.playbooks/sessions/$SESSION_ID2"
mkdir -p "$SESSION_DIR2"
cat > "$SESSION_DIR2/session.yaml" << 'EOF'
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
echo "entries: []" > "$SESSION_DIR2/journal.yaml"

# Run the list command with --json
OUTPUT=$(cd "$TEST_WORKDIR" && node /Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/playbook/bin/cli.js list --json 2>&1)

# Cleanup
rm -rf "$TEST_WORKDIR"

# Verify output is valid JSON
if ! echo "$OUTPUT" | node -e "try { JSON.parse(require('fs').readFileSync(0, 'utf-8')); process.exit(0); } catch(e) { process.exit(1); }"; then
  echo "FAIL: Output is not valid JSON"
  echo "Got: $OUTPUT"
  exit 1
fi

# Verify output is an array
if ! echo "$OUTPUT" | grep -q "^\["; then
  echo "FAIL: JSON output is not an array"
  echo "Got: $OUTPUT"
  exit 1
fi

# Verify array has at least 2 elements
ELEMENT_COUNT=$(echo "$OUTPUT" | node -e "console.log(JSON.parse(require('fs').readFileSync(0, 'utf-8')).length)")
if [ "$ELEMENT_COUNT" -lt 2 ]; then
  echo "FAIL: JSON array should have at least 2 sessions"
  echo "Expected: at least 2 elements"
  echo "Got: $ELEMENT_COUNT elements"
  exit 1
fi

exit 0

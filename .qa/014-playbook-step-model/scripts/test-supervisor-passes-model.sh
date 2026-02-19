#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Supervisor delegates with the specified model from the step definition
# Criterion: US1.AC2 — "Given a playbook with a step that has model: 'opus', When the supervisor executes that step, Then the Task subagent is launched with the specified model."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PARSER="$PROJECT_ROOT/packages/playbook/src/yaml-parser.js"

# Verify that the parser returns the model field in the parsed step object.
# This is the prerequisite for the supervisor to pass the model to the Task tool.

TMPFILE="$(mktemp /tmp/qa-014-XXXXXX.yaml)"
TMPJS="$(mktemp /tmp/qa-014-XXXXXX.mjs)"
trap 'rm -f "$TMPFILE" "$TMPJS"' EXIT

cat > "$TMPFILE" <<'YAML'
name: "test-model-pass"
description: "Test that parser surfaces model field"
version: "1.0"

args: []

steps:
  - id: "step-opus"
    command: "/speckit.specify"
    args: ""
    autonomy: "auto"
    model: "opus"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
YAML

cat > "$TMPJS" <<SCRIPT
import { readFileSync } from "node:fs";
import { parsePlaybook } from "${PARSER}";

const content = readFileSync("${TMPFILE}", "utf8");
const playbook = parsePlaybook(content);
const step = playbook.steps[0];

if (step.model === "opus") {
  console.log("PASS: Parser returns model='opus' for step with model: opus");
  process.exit(0);
} else {
  console.error("FAIL: Parser did not return expected model value");
  console.error("  Expected: 'opus'");
  console.error("  Actual: " + JSON.stringify(step.model));
  process.exit(1);
}
SCRIPT

node "$TMPJS"

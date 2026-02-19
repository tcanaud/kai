#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Steps with different models each preserve their own model value
# Criterion: US1.AC4 — "Given a playbook with steps using different models (e.g., step 1 uses 'opus', step 2 uses 'haiku'), When the supervisor runs the playbook, Then each step uses its own specified model independently."
# Feature: 014-playbook-step-model
# Generated: 2026-02-19T22:00:00Z
# ──────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PARSER="$PROJECT_ROOT/packages/playbook/src/yaml-parser.js"

TMPFILE="$(mktemp /tmp/qa-014-XXXXXX.yaml)"
TMPJS="$(mktemp /tmp/qa-014-XXXXXX.mjs)"
trap 'rm -f "$TMPFILE" "$TMPJS"' EXIT

cat > "$TMPFILE" <<'YAML'
name: "test-multi-model"
description: "Test different models on different steps"
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
  - id: "step-haiku"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "haiku"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
  - id: "step-default"
    command: "/speckit.implement"
    args: ""
    autonomy: "auto"
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

const expected = [
  { id: "step-opus", model: "opus" },
  { id: "step-haiku", model: "haiku" },
  { id: "step-default", model: null },
];

let failed = false;
for (let i = 0; i < expected.length; i++) {
  const step = playbook.steps[i];
  const exp = expected[i];
  if (step.model !== exp.model) {
    console.error("FAIL: Step '" + exp.id + "' has wrong model");
    console.error("  Expected: " + JSON.stringify(exp.model));
    console.error("  Actual: " + JSON.stringify(step.model));
    failed = true;
  }
}

if (failed) {
  process.exit(1);
} else {
  console.log("PASS: Each step preserves its own model value independently");
  process.exit(0);
}
SCRIPT

node "$TMPJS"

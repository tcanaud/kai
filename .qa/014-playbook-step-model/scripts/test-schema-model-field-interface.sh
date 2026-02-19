#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: steps[].model schema interface — optional string, allowed values, null when absent
# Criterion: IF1 — "Optional string field on step; allowed values: opus, sonnet, haiku; null when absent."
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
name: "test-interface"
description: "Test model field interface contract"
version: "1.0"

args: []

steps:
  - id: "with-model"
    command: "/speckit.plan"
    args: ""
    autonomy: "auto"
    model: "haiku"
    preconditions: []
    postconditions: []
    error_policy: "stop"
    escalation_triggers: []
  - id: "without-model"
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

let failed = false;

// Check: model is a string when present
const stepWith = playbook.steps[0];
if (typeof stepWith.model !== "string") {
  console.error("FAIL: model should be a string when specified");
  console.error("  Expected: typeof string");
  console.error("  Actual: " + typeof stepWith.model);
  failed = true;
}
if (stepWith.model !== "haiku") {
  console.error("FAIL: model value should be 'haiku'");
  console.error("  Expected: 'haiku'");
  console.error("  Actual: " + JSON.stringify(stepWith.model));
  failed = true;
}

// Check: model is null when absent
const stepWithout = playbook.steps[1];
if (stepWithout.model !== null) {
  console.error("FAIL: model should be null when absent");
  console.error("  Expected: null");
  console.error("  Actual: " + JSON.stringify(stepWithout.model));
  failed = true;
}

// Check: model field exists in the step object (part of the schema)
if (!("model" in stepWith) || !("model" in stepWithout)) {
  console.error("FAIL: 'model' key should be present in step object even when null");
  console.error("  Expected: 'model' key exists in both steps");
  failed = true;
}

if (failed) {
  process.exit(1);
} else {
  console.log("PASS: model field is optional string (string when present, null when absent)");
  process.exit(0);
}
SCRIPT

node "$TMPJS"

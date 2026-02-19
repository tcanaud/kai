#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Step without model field uses session default (model is null)
# Criterion: US1.AC3 — "Given a playbook with a step that has no model field, When the supervisor executes that step, Then the Task subagent uses the session default model (no model override is applied)."
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
name: "test-no-model"
description: "Test step without model field"
version: "1.0"

args: []

steps:
  - id: "step-no-model"
    command: "/speckit.plan"
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
const step = playbook.steps[0];

if (step.model === null) {
  console.log("PASS: Step without model field has model=null (session default applies)");
  process.exit(0);
} else {
  console.error("FAIL: Step without model field should have model=null");
  console.error("  Expected: null");
  console.error("  Actual: " + JSON.stringify(step.model));
  process.exit(1);
}
SCRIPT

node "$TMPJS"

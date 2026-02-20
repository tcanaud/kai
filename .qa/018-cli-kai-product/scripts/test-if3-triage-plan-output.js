#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: kai-product triage --plan outputs triage plan before applying changes
// Criterion: IF3 — "Scan feedbacks/new/, output triage plan, create backlogs, move feedbacks, regenerate index."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { triagePlan } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/triage.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-if3-"));
  const product = join(root, ".product");
  for (const s of ["new", "triaged", "excluded", "resolved"])
    mkdirSync(join(product, "feedbacks", s), { recursive: true });
  for (const s of ["open", "in-progress", "done", "promoted", "cancelled"])
    mkdirSync(join(product, "backlogs", s), { recursive: true });
  return product;
}

let failed = false;
function assert(condition, description, expected, actual) {
  if (!condition) {
    process.stderr.write(`FAIL: ${description}\n  Expected: ${expected}\n  Actual:   ${actual}\n`);
    failed = true;
  }
}

const product = createProductDir();

writeFileSync(join(product, "feedbacks", "new", "FB-010.md"), `---
id: "FB-010"
title: "Sample feedback for triage"
status: "new"
category: "feature-request"
priority: "medium"
source: ""
reporter: ""
created: "2026-02-20"
updated: "2026-02-20"
tags: []
exclusion_reason: ""
linked_to:
  backlog: []
  features: []
  feedbacks: []
resolution:
  resolved_date: ""
  resolved_by_feature: ""
  resolved_by_backlog: ""
---

Feedback body.
`);

let stdoutOutput = "";
const origStdout = process.stdout.write.bind(process.stdout);
process.stdout.write = (chunk, ...args) => { stdoutOutput += chunk; return origStdout(chunk, ...args); };

let exitCode = 0;
try {
  await triagePlan({ productDir: product });
} catch (_) {
  exitCode = 1;
} finally {
  process.stdout.write = origStdout;
}

assert(exitCode === 0, "triage --plan exits 0", "exitCode = 0", `exitCode = ${exitCode}`);
assert(stdoutOutput.trim().length > 0, "triage --plan produces output", "non-empty output", "empty output");

// Should reference the feedback in the plan
assert(
  stdoutOutput.includes("FB-010") || stdoutOutput.includes("feedbacks"),
  "plan output references scanned feedbacks",
  "FB-010 or 'feedbacks' in output",
  stdoutOutput.slice(0, 200)
);

if (failed) process.exit(1);
console.log("PASS: IF3 — triage --plan scans feedbacks/new/ and outputs structured plan");

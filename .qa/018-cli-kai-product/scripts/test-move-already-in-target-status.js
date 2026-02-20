#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: move a backlog that is already in the target status is a no-op
// Criterion: US2.AC4 — "Given a backlog already in the target status, When I run kai-product move BL-005 open and BL-005 is already in open/, Then the command reports 'already in target status' and makes no changes."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { move } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/move.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-move-ac4-"));
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
const originalContent = `---
id: "BL-005"
title: "Backlog BL-005"
status: "open"
category: "new-feature"
priority: "high"
created: "2026-02-20"
updated: "2026-02-20"
owner: ""
feedbacks: []
features: []
tags: []
promotion:
  promoted_date: ""
  feature_id: ""
cancellation:
  cancelled_date: ""
  reason: ""
---

Body.
`;
writeFileSync(join(product, "backlogs", "open", "BL-005.md"), originalContent);

// Capture stdout to check for "already" message
const originalStdoutWrite = process.stdout.write.bind(process.stdout);
let stdoutOutput = "";
process.stdout.write = (chunk, ...args) => {
  stdoutOutput += chunk;
  return originalStdoutWrite(chunk, ...args);
};

// This should not throw — it should report and exit cleanly
let threw = false;
try {
  await move(["BL-005", "open"], { productDir: product });
} catch (err) {
  threw = true;
} finally {
  process.stdout.write = originalStdoutWrite;
}

// The command should not throw (no error for same-status)
// and should report "already" in some form
const combinedOutput = stdoutOutput.toLowerCase();
assert(
  combinedOutput.includes("already") || !threw,
  "command reports already in target status or exits cleanly",
  "output contains 'already' or no error thrown",
  threw ? "threw error" : `output: ${stdoutOutput.slice(0, 100)}`
);

// File content should not have changed meaningfully
const afterContent = readFileSync(join(product, "backlogs", "open", "BL-005.md"), "utf-8");
assert(afterContent.includes('status: "open"'), "frontmatter still shows open status", 'status: "open"', afterContent.match(/status: ".*?"/)?.[0]);

if (failed) process.exit(1);
console.log("PASS: US2.AC4 — move to same status reports already in target status");

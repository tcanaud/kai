#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: check reports no issues and exits 0 on a fully consistent .product/ directory
// Criterion: US3.AC4 — "Given a fully consistent .product/ directory, When I run kai-product check, Then the command reports no issues and exits with success."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { reindex } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/reindex.js";
import { check } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/check.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-check-ac4-"));
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

// Write a consistent feedback
writeFileSync(join(product, "feedbacks", "triaged", "FB-001.md"), `---
id: "FB-001"
title: "Consistent feedback"
status: "triaged"
category: "bug"
priority: "medium"
source: ""
reporter: ""
created: "2026-02-20"
updated: "2026-02-20"
tags: []
exclusion_reason: ""
linked_to:
  backlog: ["BL-001"]
  features: []
  feedbacks: []
resolution:
  resolved_date: ""
  resolved_by_feature: ""
  resolved_by_backlog: ""
---

Body.
`);

// Write a consistent backlog
writeFileSync(join(product, "backlogs", "open", "BL-001.md"), `---
id: "BL-001"
title: "Consistent backlog"
status: "open"
category: "new-feature"
priority: "high"
created: "2026-02-20"
updated: "2026-02-20"
owner: ""
feedbacks: ["FB-001"]
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
`);

// First reindex to make index.yaml consistent
await reindex({ productDir: product });

let exitCode = 0;
let stdoutOutput = "";
const origStdout = process.stdout.write.bind(process.stdout);
process.stdout.write = (chunk, ...args) => { stdoutOutput += chunk; return origStdout(chunk, ...args); };

try {
  await check({ productDir: product, json: false });
} catch (_) {
  exitCode = 1;
} finally {
  process.stdout.write = origStdout;
}

assert(exitCode === 0, "check exits with code 0 on consistent product dir", "exitCode = 0", `exitCode = ${exitCode}`);

const outputLower = stdoutOutput.toLowerCase();
const reportsClean = outputLower.includes("no issue") || outputLower.includes("clean") || outputLower.includes("ok") || outputLower.includes("pass") || outputLower.includes("0 issue");
assert(reportsClean, "output reports no issues", "output contains 'no issues'/'clean'/'ok'/'pass'", stdoutOutput.slice(0, 200));

if (failed) process.exit(1);
console.log("PASS: US3.AC4 — check reports no issues on consistent .product/ directory");

#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: check reports index desync when index.yaml is out of date with files
// Criterion: US3.AC5 — "Given an index.yaml that is out of sync with files, When I run kai-product check, Then an index desync issue is reported."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { check } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/check.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-check-ac5-"));
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

// Write a stale index claiming 0 feedbacks
writeFileSync(join(product, "index.yaml"), `product_version: "1.0"
feedbacks:
  total: 0
  by_status:
    new: 0
    triaged: 0
    excluded: 0
    resolved: 0
backlogs:
  total: 0
  by_status:
    open: 0
    in-progress: 0
    done: 0
    promoted: 0
    cancelled: 0
`);

// But actually one feedback exists
writeFileSync(join(product, "feedbacks", "new", "FB-001.md"), `---
id: "FB-001"
title: "Unlisted feedback"
status: "new"
category: "bug"
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

Body.
`);

let stdoutOutput = "";
let stderrOutput = "";
const origStdout = process.stdout.write.bind(process.stdout);
const origStderr = process.stderr.write.bind(process.stderr);
process.stdout.write = (chunk, ...args) => { stdoutOutput += chunk; return origStdout(chunk, ...args); };
process.stderr.write = (chunk, ...args) => { stderrOutput += chunk; return origStderr(chunk, ...args); };

try {
  await check({ productDir: product, json: false });
} catch (_) {
  // non-zero exit is acceptable
} finally {
  process.stdout.write = origStdout;
  process.stderr.write = origStderr;
}

const allOutput = (stdoutOutput + stderrOutput).toLowerCase();
const hasIndexDesync =
  allOutput.includes("index") && (allOutput.includes("desync") || allOutput.includes("out of sync") || allOutput.includes("mismatch") || allOutput.includes("stale"));

assert(hasIndexDesync, "check reports index desync when index is stale", "output mentions index desync/out of sync/stale", `output: ${(stdoutOutput + stderrOutput).slice(0, 200)}`);

if (failed) process.exit(1);
console.log("PASS: US3.AC5 — check detects index desync");

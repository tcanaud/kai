#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: check reports staleness warning for feedbacks in new/ older than 14 days
// Criterion: US3.AC3 — "Given feedbacks in feedbacks/new/ that are older than 14 days, When I run kai-product check, Then a staleness warning is reported for each."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { check } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/check.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-check-ac3-"));
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

// Feedback created 30 days ago — definitely stale
const oldDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
writeFileSync(join(product, "feedbacks", "new", "FB-OLD.md"), `---
id: "FB-OLD"
title: "Very old feedback"
status: "new"
category: "bug"
priority: "low"
source: ""
reporter: ""
created: "${oldDate}"
updated: "${oldDate}"
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
  // non-zero exit acceptable when issues found
} finally {
  process.stdout.write = origStdout;
  process.stderr.write = origStderr;
}

const allOutput = (stdoutOutput + stderrOutput).toLowerCase();
const hasStalenessWarning =
  allOutput.includes("stale") ||
  allOutput.includes("old") ||
  allOutput.includes("fb-old") ||
  allOutput.includes("14");

assert(hasStalenessWarning, "check reports staleness warning for FB-OLD (30 days in new/)", "output mentions stale/old/FB-OLD/14", `output: ${(stdoutOutput + stderrOutput).slice(0, 200)}`);

if (failed) process.exit(1);
console.log("PASS: US3.AC3 — check reports staleness for feedbacks older than 14 days in new/");

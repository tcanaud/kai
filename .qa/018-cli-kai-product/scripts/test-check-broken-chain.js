#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: check reports broken chain when feedback links to nonexistent backlog
// Criterion: US3.AC2 — "Given a feedback linking to a backlog ID that does not exist, When I run kai-product check, Then a broken chain warning is reported."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { check } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/check.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-check-ac2-"));
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

// Feedback links to BL-999 which does not exist
writeFileSync(join(product, "feedbacks", "triaged", "FB-001.md"), `---
id: "FB-001"
title: "Feedback with broken link"
status: "triaged"
category: "bug"
priority: "high"
source: ""
reporter: ""
created: "2026-02-20"
updated: "2026-02-20"
tags: []
exclusion_reason: ""
linked_to:
  backlog: ["BL-999"]
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
  // non-zero exit is acceptable when issues found
} finally {
  process.stdout.write = origStdout;
  process.stderr.write = origStderr;
}

const allOutput = (stdoutOutput + stderrOutput).toLowerCase();
const hasBrokenChain =
  allOutput.includes("broken") ||
  allOutput.includes("chain") ||
  allOutput.includes("bl-999") ||
  allOutput.includes("fb-001");

assert(hasBrokenChain, "check reports broken traceability chain for FB-001 → BL-999", "output mentions broken chain, BL-999, or FB-001", `output: ${(stdoutOutput + stderrOutput).slice(0, 200)}`);

if (failed) process.exit(1);
console.log("PASS: US3.AC2 — check detects broken traceability chain");

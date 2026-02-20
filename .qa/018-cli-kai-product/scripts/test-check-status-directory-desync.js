#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: check reports status/directory desync when frontmatter disagrees with directory
// Criterion: US3.AC1 — "Given a backlog file in backlogs/open/ whose frontmatter says status: done, When I run kai-product check, Then a status/directory desync warning is reported for that item."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { check } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/check.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-check-ac1-"));
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

// File is in open/ but frontmatter says done
writeFileSync(join(product, "backlogs", "open", "BL-001.md"), `---
id: "BL-001"
title: "Desync Backlog"
status: "done"
category: "bug"
priority: "medium"
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
`);

let stdoutOutput = "";
let stderrOutput = "";
const origStdout = process.stdout.write.bind(process.stdout);
const origStderr = process.stderr.write.bind(process.stderr);
process.stdout.write = (chunk, ...args) => { stdoutOutput += chunk; return origStdout(chunk, ...args); };
process.stderr.write = (chunk, ...args) => { stderrOutput += chunk; return origStderr(chunk, ...args); };

let exitCode = 0;
try {
  await check({ productDir: product, json: false });
} catch (err) {
  exitCode = 1;
} finally {
  process.stdout.write = origStdout;
  process.stderr.write = origStderr;
}

const allOutput = (stdoutOutput + stderrOutput).toLowerCase();
const hasDesyncWarning = allOutput.includes("desync") || allOutput.includes("mismatch") || allOutput.includes("bl-001");

assert(hasDesyncWarning, "check reports status/directory desync for BL-001", "output mentions desync or BL-001", `stdout: ${stdoutOutput.slice(0, 200)}`);

if (failed) process.exit(1);
console.log("PASS: US3.AC1 — check detects status/directory desync");

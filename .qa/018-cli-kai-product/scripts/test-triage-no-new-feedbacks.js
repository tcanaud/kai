#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: triage with no new feedbacks reports no work to do and exits cleanly
// Criterion: US5.AC4 — "Given no new feedbacks in feedbacks/new/, When I run kai-product triage, Then the command reports 'No new feedbacks to triage' and exits cleanly."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { triagePlan } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/triage.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-triage-ac4-"));
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
// feedbacks/new/ is empty

let exitCode = 0;
let stdoutOutput = "";
let stderrOutput = "";
const origStdout = process.stdout.write.bind(process.stdout);
const origStderr = process.stderr.write.bind(process.stderr);
process.stdout.write = (chunk, ...args) => { stdoutOutput += chunk; return origStdout(chunk, ...args); };
process.stderr.write = (chunk, ...args) => { stderrOutput += chunk; return origStderr(chunk, ...args); };

try {
  await triagePlan({ productDir: product });
} catch (_) {
  exitCode = 1;
} finally {
  process.stdout.write = origStdout;
  process.stderr.write = origStderr;
}

assert(exitCode === 0, "triage exits 0 when no new feedbacks", "exitCode = 0", `exitCode = ${exitCode}`);

const allOutput = (stdoutOutput + stderrOutput).toLowerCase();
const reportsEmpty =
  allOutput.includes("no new") ||
  allOutput.includes("nothing") ||
  allOutput.includes("empty") ||
  // Or valid JSON with empty feedbacks
  allOutput.includes('"feedbacks": []') ||
  allOutput.includes('"total": 0');

assert(reportsEmpty, "output reports no new feedbacks to triage", "output contains 'no new'/'nothing'/'empty'", `output: ${(stdoutOutput + stderrOutput).slice(0, 200)}`);

if (failed) process.exit(1);
console.log("PASS: US5.AC4 — triage with no new feedbacks reports nothing to do and exits cleanly");

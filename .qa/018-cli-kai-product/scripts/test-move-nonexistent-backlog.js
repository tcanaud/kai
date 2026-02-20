#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: move a nonexistent backlog exits with error and no files modified
// Criterion: US2.AC3 — "Given a backlog ID that does not exist, When I run kai-product move BL-999 done, Then the command exits with a clear error message identifying the missing item and no files are modified."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { move } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/move.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-move-ac3-"));
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
// BL-999 does not exist

let threw = false;
let errorMessage = "";
try {
  await move(["BL-999", "done"], { productDir: product });
} catch (err) {
  threw = true;
  errorMessage = err.message || String(err);
}

assert(threw, "command throws/rejects for nonexistent BL-999", "error thrown", threw ? "threw" : "did not throw");
assert(
  errorMessage.toLowerCase().includes("bl-999") || errorMessage.toLowerCase().includes("not found"),
  "error message identifies missing item",
  "message contains BL-999 or 'not found'",
  errorMessage
);

// No files should have been created in done/
const doneDir = join(product, "backlogs", "done", "BL-999.md");
assert(!existsSync(doneDir), "no file created for BL-999", "BL-999.md absent", existsSync(doneDir) ? "present" : "absent");

if (failed) process.exit(1);
console.log("PASS: US2.AC3 — move of nonexistent backlog exits with clear error, no files modified");

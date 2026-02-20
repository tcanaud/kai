#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: kai-product check --json outputs machine-readable JSON
// Criterion: IF5 — "Detect and report integrity issues; machine-readable JSON output with --json flag."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { reindex } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/reindex.js";
import { check } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/check.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-if5-"));
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
await reindex({ productDir: product });

let stdoutOutput = "";
const origStdout = process.stdout.write.bind(process.stdout);
process.stdout.write = (chunk, ...args) => { stdoutOutput += chunk; return origStdout(chunk, ...args); };

try {
  await check({ productDir: product, json: true });
} catch (_) {
  // non-zero exit is OK
} finally {
  process.stdout.write = origStdout;
}

assert(stdoutOutput.trim().length > 0, "check --json produces output", "non-empty output", "empty");

let parsed;
try {
  parsed = JSON.parse(stdoutOutput);
} catch (err) {
  process.stderr.write(`FAIL: check --json output is not valid JSON\n  Expected: valid JSON\n  Actual:   ${stdoutOutput.slice(0, 200)}\n`);
  failed = true;
}

if (parsed !== undefined) {
  const hasIssues = "issues" in parsed || "errors" in parsed || "warnings" in parsed || "checks" in parsed || Array.isArray(parsed);
  assert(hasIssues, "JSON output has structured issues/checks field", "issues/errors/warnings/checks key", Object.keys(parsed || {}).join(", "));
}

if (failed) process.exit(1);
console.log("PASS: IF5 — check --json produces valid machine-readable JSON output");

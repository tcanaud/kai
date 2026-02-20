#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: reindex on empty .product/ produces all-zero counts
// Criterion: US1.AC3 — "Given an empty .product/ directory structure with no feedbacks or backlogs, When I run kai-product reindex, Then an index.yaml is generated with all counts at zero."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { reindex } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/reindex.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-reindex-ac3-"));
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
// Empty — no files placed

await reindex({ productDir: product });

const content = readFileSync(join(product, "index.yaml"), "utf-8");

assert(content.includes("total: 0"), "feedback total = 0", "total: 0", content.match(/total: \d+/)?.[0]);
assert(content.includes('product_version: "1.0"'), "index.yaml has valid product_version", 'product_version: "1.0"', "(in content)");

if (failed) process.exit(1);
console.log("PASS: US1.AC3 — reindex on empty .product/ generates all-zero counts");

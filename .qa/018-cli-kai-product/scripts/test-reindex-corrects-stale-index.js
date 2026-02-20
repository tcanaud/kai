#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: reindex overwrites stale index.yaml with correct data
// Criterion: US1.AC2 — "Given an index.yaml that is out of sync with the actual files (stale entries, missing entries), When I run kai-product reindex, Then the index is corrected to match filesystem reality."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { reindex } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/reindex.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-reindex-ac2-"));
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

// Write a stale index that claims many feedbacks/backlogs
writeFileSync(join(product, "index.yaml"), `product_version: "1.0"
feedbacks:
  total: 999
  by_status:
    new: 500
    triaged: 499
backlogs:
  total: 100
`);

// Only one real feedback on disk
writeFileSync(join(product, "feedbacks", "new", "FB-001.md"), `---
id: "FB-001"
title: "Real feedback"
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

await reindex({ productDir: product });

const content = readFileSync(join(product, "index.yaml"), "utf-8");

assert(!content.includes("999"), "stale feedback count 999 is gone", "no '999'", content.includes("999") ? "still contains 999" : "OK");
assert(content.includes("total: 1"), "correct total = 1 feedback", "total: 1", content.match(/total: \d+/)?.[0]);
assert(content.includes("FB-001"), "FB-001 listed in fresh index", "FB-001 present", "(in content)");

if (failed) process.exit(1);
console.log("PASS: US1.AC2 — reindex corrects stale index to match filesystem reality");

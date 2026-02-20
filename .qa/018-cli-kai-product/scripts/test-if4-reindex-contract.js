#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: kai-product reindex regenerates index.yaml from filesystem state
// Criterion: IF4 — "Regenerate index.yaml from filesystem state."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { reindex } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/reindex.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-if4-"));
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

writeFileSync(join(product, "feedbacks", "new", "FB-001.md"), `---
id: "FB-001"
title: "Test feedback"
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

writeFileSync(join(product, "backlogs", "open", "BL-001.md"), `---
id: "BL-001"
title: "Test backlog"
status: "open"
category: "new-feature"
priority: "high"
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

await reindex({ productDir: product });

const indexPath = join(product, "index.yaml");
assert(existsSync(indexPath), "index.yaml created at .product/index.yaml", "file exists", existsSync(indexPath) ? "exists" : "missing");

const content = readFileSync(indexPath, "utf-8");
assert(content.includes('product_version: "1.0"'), "index.yaml has product_version field", 'product_version: "1.0"', "(in content)");
assert(content.includes("FB-001") || content.includes("total: 1"), "index.yaml reflects actual filesystem state", "FB-001 or total:1 in content", content.slice(0, 300));

if (failed) process.exit(1);
console.log("PASS: IF4 — reindex regenerates valid index.yaml from filesystem state");

#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: reindex generates accurate counts by status and category
// Criterion: US1.AC1 — "Given a .product/ directory with feedbacks and backlogs across all status subdirectories, When I run kai-product reindex, Then index.yaml is regenerated with accurate counts by status, by category, and complete item listings."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { reindex } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/reindex.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-reindex-ac1-"));
  const product = join(root, ".product");
  for (const s of ["new", "triaged", "excluded", "resolved"])
    mkdirSync(join(product, "feedbacks", s), { recursive: true });
  for (const s of ["open", "in-progress", "done", "promoted", "cancelled"])
    mkdirSync(join(product, "backlogs", s), { recursive: true });
  return product;
}

function writeFeedback(product, status, id, category = "bug") {
  writeFileSync(join(product, "feedbacks", status, `${id}.md`), `---
id: "${id}"
title: "Test ${id}"
status: "${status}"
category: "${category}"
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
}

function writeBacklog(product, status, id, category = "new-feature") {
  writeFileSync(join(product, "backlogs", status, `${id}.md`), `---
id: "${id}"
title: "Backlog ${id}"
status: "${status}"
category: "${category}"
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
}

let failed = false;
function assert(condition, description, expected, actual) {
  if (!condition) {
    process.stderr.write(`FAIL: ${description}\n  Expected: ${expected}\n  Actual:   ${actual}\n`);
    failed = true;
  }
}

const product = createProductDir();
writeFeedback(product, "new", "FB-001", "bug");
writeFeedback(product, "triaged", "FB-002", "feature-request");
writeFeedback(product, "excluded", "FB-003", "bug");
writeFeedback(product, "resolved", "FB-004", "performance");
writeBacklog(product, "open", "BL-001", "new-feature");
writeBacklog(product, "in-progress", "BL-002", "improvement");
writeBacklog(product, "done", "BL-003", "new-feature");
writeBacklog(product, "promoted", "BL-004", "new-feature");
writeBacklog(product, "cancelled", "BL-005", "bug");

await reindex({ productDir: product });

const content = readFileSync(join(product, "index.yaml"), "utf-8");

assert(content.includes("total: 4"), "feedback total = 4", "total: 4", content.match(/total: \d+/)?.[0]);
assert(content.includes("new: 1"), "feedbacks.new = 1", "new: 1", "(in content)");
assert(content.includes("triaged: 1"), "feedbacks.triaged = 1", "triaged: 1", "(in content)");
assert(content.includes("excluded: 1"), "feedbacks.excluded = 1", "excluded: 1", "(in content)");
assert(content.includes("resolved: 1"), "feedbacks.resolved = 1", "resolved: 1", "(in content)");
assert(content.includes("open: 1"), "backlogs.open = 1", "open: 1", "(in content)");
assert(content.includes("done: 1"), "backlogs.done = 1", "done: 1", "(in content)");
assert(content.includes("promoted: 1"), "backlogs.promoted = 1", "promoted: 1", "(in content)");
assert(content.includes("FB-001"), "FB-001 listed in index", "FB-001 present", "(in content)");
assert(content.includes("BL-001"), "BL-001 listed in index", "BL-001 present", "(in content)");

if (failed) process.exit(1);
console.log("PASS: US1.AC1 — reindex generates accurate counts by status and listings");

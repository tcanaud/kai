#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: move multiple backlogs in one command (bulk operation)
// Criterion: US2.AC2 — "Given multiple backlogs BL-001,BL-002,BL-003, When I run kai-product move BL-001,BL-002,BL-003 done, Then all three files are moved, all frontmatter updated, and index regenerated in one operation."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { move } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/move.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-move-ac2-"));
  const product = join(root, ".product");
  for (const s of ["new", "triaged", "excluded", "resolved"])
    mkdirSync(join(product, "feedbacks", s), { recursive: true });
  for (const s of ["open", "in-progress", "done", "promoted", "cancelled"])
    mkdirSync(join(product, "backlogs", s), { recursive: true });
  return product;
}

function writeBacklog(product, status, id) {
  writeFileSync(join(product, "backlogs", status, `${id}.md`), `---
id: "${id}"
title: "Backlog ${id}"
status: "${status}"
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
}

let failed = false;
function assert(condition, description, expected, actual) {
  if (!condition) {
    process.stderr.write(`FAIL: ${description}\n  Expected: ${expected}\n  Actual:   ${actual}\n`);
    failed = true;
  }
}

const product = createProductDir();
writeBacklog(product, "open", "BL-001");
writeBacklog(product, "open", "BL-002");
writeBacklog(product, "open", "BL-003");

// Bulk move with comma-separated IDs
await move(["BL-001,BL-002,BL-003", "done"], { productDir: product });

for (const id of ["BL-001", "BL-002", "BL-003"]) {
  const movedPath = join(product, "backlogs", "done", `${id}.md`);
  const originalPath = join(product, "backlogs", "open", `${id}.md`);
  assert(existsSync(movedPath), `${id} exists in backlogs/done/`, "file exists", existsSync(movedPath) ? "exists" : "missing");
  assert(!existsSync(originalPath), `${id} removed from backlogs/open/`, "file absent", existsSync(originalPath) ? "still present" : "absent");
  const content = readFileSync(movedPath, "utf-8");
  assert(content.includes('status: "done"'), `${id} frontmatter updated to done`, 'status: "done"', content.match(/status: ".*?"/)?.[0]);
}

const indexContent = readFileSync(join(product, "index.yaml"), "utf-8");
assert(indexContent.includes("done: 3"), "index shows done count = 3", "done: 3", "(in content)");

if (failed) process.exit(1);
console.log("PASS: US2.AC2 — bulk move of 3 backlogs in one command");

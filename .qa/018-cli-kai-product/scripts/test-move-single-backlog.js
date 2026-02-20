#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: move single backlog to new status updates file and frontmatter
// Criterion: US2.AC1 — "Given a backlog BL-005 in backlogs/open/, When I run kai-product move BL-005 in-progress, Then the file is moved to backlogs/in-progress/, its frontmatter status is updated to in-progress, and index.yaml is regenerated."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { move } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/move.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-move-ac1-"));
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

writeFileSync(join(product, "backlogs", "open", "BL-005.md"), `---
id: "BL-005"
title: "Backlog BL-005"
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

await move(["BL-005", "in-progress"], { productDir: product });

const movedPath = join(product, "backlogs", "in-progress", "BL-005.md");
const originalPath = join(product, "backlogs", "open", "BL-005.md");

assert(existsSync(movedPath), "BL-005.md exists in backlogs/in-progress/", "file exists", existsSync(movedPath) ? "exists" : "missing");
assert(!existsSync(originalPath), "BL-005.md removed from backlogs/open/", "file absent", existsSync(originalPath) ? "still present" : "absent");

const content = readFileSync(movedPath, "utf-8");
assert(content.includes('status: "in-progress"'), "frontmatter status updated to in-progress", 'status: "in-progress"', content.match(/status: ".*?"/)?.[0]);

const indexPath = join(product, "index.yaml");
assert(existsSync(indexPath), "index.yaml regenerated after move", "file exists", existsSync(indexPath) ? "exists" : "missing");

const indexContent = readFileSync(indexPath, "utf-8");
assert(indexContent.includes("in-progress: 1"), "index shows in-progress count = 1", "in-progress: 1", "(in content)");

if (failed) process.exit(1);
console.log("PASS: US2.AC1 — move single backlog updates file location, frontmatter, and index");

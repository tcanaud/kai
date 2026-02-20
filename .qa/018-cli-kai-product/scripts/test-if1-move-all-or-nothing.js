#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: kai-product move enforces all-or-nothing semantics (invalid ID in bulk cancels all)
// Criterion: IF1 — "Move one or more backlog items to a new status; all-or-nothing semantics."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { move } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/move.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-if1-"));
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

writeFileSync(join(product, "backlogs", "open", "BL-001.md"), `---
id: "BL-001"
title: "Valid backlog"
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
// BL-INVALID does not exist

let threw = false;
try {
  // Mix of valid (BL-001) and invalid (BL-INVALID) — should fail and NOT move BL-001
  await move(["BL-001,BL-INVALID", "done"], { productDir: product });
} catch (_) {
  threw = true;
}

assert(threw, "bulk move with invalid ID throws error", "error thrown", threw ? "threw" : "did not throw");

// BL-001 should NOT have been moved (all-or-nothing)
assert(existsSync(join(product, "backlogs", "open", "BL-001.md")), "BL-001 still in open/ (not moved due to invalid ID)", "file in open/", existsSync(join(product, "backlogs", "open", "BL-001.md")) ? "present" : "missing");
assert(!existsSync(join(product, "backlogs", "done", "BL-001.md")), "BL-001 NOT in done/ (rollback)", "file absent from done/", existsSync(join(product, "backlogs", "done", "BL-001.md")) ? "present (WRONG)" : "absent");

if (failed) process.exit(1);
console.log("PASS: IF1 — move all-or-nothing: invalid ID in bulk cancels entire operation");

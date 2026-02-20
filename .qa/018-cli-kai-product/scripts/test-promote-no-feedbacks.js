#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: promote succeeds when backlog has no linked feedbacks
// Criterion: US4.AC3 — "Given a backlog with no linked feedbacks, When I run kai-product promote BL-010, Then the promotion still succeeds (feedbacks are optional), creating the feature YAML and updating the backlog."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { promote } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/promote.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-promote-ac3-"));
  const product = join(root, ".product");
  for (const s of ["new", "triaged", "excluded", "resolved"])
    mkdirSync(join(product, "feedbacks", s), { recursive: true });
  for (const s of ["open", "in-progress", "done", "promoted", "cancelled"])
    mkdirSync(join(product, "backlogs", s), { recursive: true });
  mkdirSync(join(root, ".features"), { recursive: true });
  return { root, product };
}

let failed = false;
function assert(condition, description, expected, actual) {
  if (!condition) {
    process.stderr.write(`FAIL: ${description}\n  Expected: ${expected}\n  Actual:   ${actual}\n`);
    failed = true;
  }
}

const { root, product } = createProductDir();

// BL-010 with no linked feedbacks
writeFileSync(join(product, "backlogs", "open", "BL-010.md"), `---
id: "BL-010"
title: "Standalone backlog"
status: "open"
category: "improvement"
priority: "medium"
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

const featuresDir = join(root, ".features");

await promote(["BL-010"], { productDir: product, featuresDir });

// Feature YAML should be created
const featureFiles = readdirSync(featuresDir).filter(f => f.endsWith(".yaml"));
assert(featureFiles.length > 0, "feature YAML created even with no feedbacks", ">0 yaml files", `${featureFiles.length} files`);

// BL-010 should be in promoted/
assert(existsSync(join(product, "backlogs", "promoted", "BL-010.md")), "BL-010 moved to promoted/", "file exists", "missing");
assert(!existsSync(join(product, "backlogs", "open", "BL-010.md")), "BL-010 removed from open/", "file absent", "still present");

const backlogContent = readFileSync(join(product, "backlogs", "promoted", "BL-010.md"), "utf-8");
assert(backlogContent.includes('status: "promoted"'), "BL-010 status updated to promoted", 'status: "promoted"', backlogContent.match(/status: ".*?"/)?.[0]);

if (failed) process.exit(1);
console.log("PASS: US4.AC3 — promote with no linked feedbacks still succeeds");

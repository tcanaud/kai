#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: kai-product promote performs the full promotion chain atomically
// Criterion: IF2 — "Promote a backlog to a feature; create feature YAML, update backlog + feedbacks, regenerate indexes."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { promote } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/promote.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-if2-"));
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
const featuresDir = join(root, ".features");

writeFileSync(join(product, "backlogs", "open", "BL-020.md"), `---
id: "BL-020"
title: "Contract Test Backlog"
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

await promote(["BL-020"], { productDir: product, featuresDir });

// Contract: feature YAML created
const featureFiles = readdirSync(featuresDir).filter(f => f.endsWith(".yaml"));
assert(featureFiles.length > 0, "feature YAML created in .features/", ">0 yaml files", `${featureFiles.length} files`);

// Contract: backlog moved to promoted
assert(existsSync(join(product, "backlogs", "promoted", "BL-020.md")), "BL-020 moved to promoted/", "exists", "missing");

// Contract: index regenerated
assert(existsSync(join(product, "index.yaml")), "index.yaml exists after promote", "exists", "missing");

if (failed) process.exit(1);
console.log("PASS: IF2 — promote contract: feature YAML created, backlog moved, indexes regenerated");

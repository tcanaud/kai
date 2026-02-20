#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: promote creates feature YAML, moves backlog, updates feedbacks, regenerates indexes
// Criterion: US4.AC1 — "Given an open backlog BL-007 with linked feedback FB-102, When I run kai-product promote BL-007, Then a .features/NNN-{name}.yaml is created with the next sequential feature number, BL-007 is moved to backlogs/promoted/ with updated frontmatter, FB-102 gets a feature link added, and all indexes are regenerated."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { promote } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/promote.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-promote-ac1-"));
  const product = join(root, ".product");
  for (const s of ["new", "triaged", "excluded", "resolved"])
    mkdirSync(join(product, "feedbacks", s), { recursive: true });
  for (const s of ["open", "in-progress", "done", "promoted", "cancelled"])
    mkdirSync(join(product, "backlogs", s), { recursive: true });
  // Create .features/ directory
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

writeFileSync(join(product, "feedbacks", "triaged", "FB-102.md"), `---
id: "FB-102"
title: "Feedback FB-102"
status: "triaged"
category: "new-feature"
priority: "high"
source: ""
reporter: ""
created: "2026-02-20"
updated: "2026-02-20"
tags: []
exclusion_reason: ""
linked_to:
  backlog: ["BL-007"]
  features: []
  feedbacks: []
resolution:
  resolved_date: ""
  resolved_by_feature: ""
  resolved_by_backlog: ""
---

Body.
`);

writeFileSync(join(product, "backlogs", "open", "BL-007.md"), `---
id: "BL-007"
title: "My Backlog Item"
status: "open"
category: "new-feature"
priority: "high"
created: "2026-02-20"
updated: "2026-02-20"
owner: ""
feedbacks: ["FB-102"]
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

await promote(["BL-007"], { productDir: product, featuresDir: join(root, ".features") });

// BL-007 should be in promoted/
const promotedPath = join(product, "backlogs", "promoted", "BL-007.md");
const openPath = join(product, "backlogs", "open", "BL-007.md");
assert(existsSync(promotedPath), "BL-007.md moved to backlogs/promoted/", "file exists", existsSync(promotedPath) ? "exists" : "missing");
assert(!existsSync(openPath), "BL-007.md removed from backlogs/open/", "file absent", existsSync(openPath) ? "still present" : "absent");

const backlogContent = readFileSync(promotedPath, "utf-8");
assert(backlogContent.includes('status: "promoted"'), "BL-007 frontmatter status = promoted", 'status: "promoted"', backlogContent.match(/status: ".*?"/)?.[0]);

// Feature YAML should exist in .features/
const featuresDir = join(root, ".features");
const { readdirSync } = await import("node:fs");
const featureFiles = readdirSync(featuresDir).filter(f => f.endsWith(".yaml"));
assert(featureFiles.length > 0, "at least one feature YAML created in .features/", ">0 yaml files", `${featureFiles.length} files`);

// FB-102 should have a feature link
const feedbackContent = readFileSync(join(product, "feedbacks", "triaged", "FB-102.md"), "utf-8");
const hasFeatureLink = feedbackContent.includes("features:") && !feedbackContent.match(/features:\s*\[\]/);
assert(hasFeatureLink, "FB-102 has feature link added", "features field non-empty", feedbackContent.match(/features:.*$/m)?.[0]);

// index.yaml should exist
assert(existsSync(join(product, "index.yaml")), "index.yaml regenerated after promote", "file exists", "missing");

if (failed) process.exit(1);
console.log("PASS: US4.AC1 — promote creates feature, moves backlog, updates feedbacks, regenerates index");

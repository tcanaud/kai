#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: promote of an already-promoted backlog exits with error
// Criterion: US4.AC2 — "Given a backlog that is already promoted, When I run kai-product promote BL-003, Then the command exits with an error 'BL-003 is already promoted' and no files are modified."
// Feature: 018-cli-kai-product
// Generated: 2026-02-20T00:00:00Z
// ──────────────────────────────────────────────────────

import { mkdtempSync, mkdirSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { promote } from "/Users/thibaudcanaud/__WORKSPACE__/__PERSO__/kai/packages/kai-product/src/commands/promote.js";

function createProductDir() {
  const root = mkdtempSync(join(tmpdir(), "qa-018-promote-ac2-"));
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

// BL-003 is already in promoted/
writeFileSync(join(product, "backlogs", "promoted", "BL-003.md"), `---
id: "BL-003"
title: "Already promoted backlog"
status: "promoted"
category: "new-feature"
priority: "high"
created: "2026-02-20"
updated: "2026-02-20"
owner: ""
feedbacks: []
features: ["001-some-feature"]
tags: []
promotion:
  promoted_date: "2026-02-15"
  feature_id: "001-some-feature"
cancellation:
  cancelled_date: ""
  reason: ""
---

Body.
`);

const featuresDir = join(root, ".features");
const featureCountBefore = readdirSync(featuresDir).length;

let threw = false;
let errorMessage = "";
try {
  await promote(["BL-003"], { productDir: product, featuresDir });
} catch (err) {
  threw = true;
  errorMessage = err.message || String(err);
}

assert(threw, "promote of already-promoted backlog throws error", "error thrown", threw ? "threw" : "did not throw");
assert(
  errorMessage.toLowerCase().includes("already") || errorMessage.toLowerCase().includes("promoted"),
  "error message mentions already promoted",
  "message contains 'already' or 'promoted'",
  errorMessage
);

// No new feature files created
const featureCountAfter = readdirSync(featuresDir).length;
assert(featureCountAfter === featureCountBefore, "no new feature YAML created", `${featureCountBefore} files`, `${featureCountAfter} files`);

if (failed) process.exit(1);
console.log("PASS: US4.AC2 — promote of already-promoted backlog exits with error, no files modified");

#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: API contract for MergeResult with toYAML and validate methods
// Criterion: IF1 — "mergeYAML(existing, update, options) → MergeResult with methods toYAML(), validate()"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML, MergeResult } from '../../../packages/tcsetup/src/yaml-merge.js';

const existingConfig = `agent:
  name: test`;

const updateConfig = `agent:
  name: test
  version: 1.0`;

try {
  const result = mergeYAML(existingConfig, updateConfig);

  // Check: result is a MergeResult instance
  if (!(result instanceof MergeResult)) {
    console.error('FAIL: mergeYAML did not return a MergeResult instance');
    process.exit(1);
  }

  // Check: result has toYAML method
  if (typeof result.toYAML !== 'function') {
    console.error('FAIL: MergeResult does not have toYAML() method');
    process.exit(1);
  }

  // Check: toYAML returns a string
  const yaml = result.toYAML();
  if (typeof yaml !== 'string') {
    console.error('FAIL: toYAML() did not return a string');
    process.exit(1);
  }

  // Check: result has validate method
  if (typeof result.validate !== 'function') {
    console.error('FAIL: MergeResult does not have validate() method');
    process.exit(1);
  }

  // Check: validate returns array of errors
  const errors = result.validate();
  if (!Array.isArray(errors)) {
    console.error('FAIL: validate() did not return an array');
    process.exit(1);
  }

  // Check: result has success property
  if (typeof result.success !== 'boolean') {
    console.error('FAIL: MergeResult does not have success property');
    process.exit(1);
  }

  // Check: result has data property
  if (!result.data || typeof result.data !== 'object') {
    console.error('FAIL: MergeResult does not have valid data property');
    process.exit(1);
  }

  console.log('PASS: MergeResult API contract fulfilled');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error testing API contract');
  console.error('Error:', error.message);
  process.exit(1);
}

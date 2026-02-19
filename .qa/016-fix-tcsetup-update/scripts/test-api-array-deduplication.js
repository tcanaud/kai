#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: API contract for array deduplication
// Criterion: IF2 — "mergeYAML.arrays(existing, update) - Deduplicates two arrays using deep equality check"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { deduplicateArrays } from '../../../packages/tcsetup/src/yaml-merge.js';

try {
  const existing = [
    { id: 1, name: 'item1' },
    { id: 2, name: 'item2' }
  ];

  const update = [
    { id: 1, name: 'item1' },  // Duplicate
    { id: 2, name: 'item2' },  // Duplicate
    { id: 3, name: 'item3' }   // New
  ];

  const { result, deduped } = deduplicateArrays(existing, update);

  // Check: function returns object with result and deduped
  if (!Array.isArray(result)) {
    console.error('FAIL: deduplicateArrays did not return result array');
    process.exit(1);
  }

  if (typeof deduped !== 'number') {
    console.error('FAIL: deduplicateArrays did not return deduped count');
    process.exit(1);
  }

  // Check: deduplication worked
  if (result.length !== 3) {
    console.error(`FAIL: Expected 3 items after dedup, got ${result.length}`);
    process.exit(1);
  }

  if (deduped !== 2) {
    console.error(`FAIL: Expected 2 deduplicated items, got ${deduped}`);
    process.exit(1);
  }

  // Check: items are correct
  const hasItem1 = result.some(item => item.id === 1 && item.name === 'item1');
  const hasItem3 = result.some(item => item.id === 3 && item.name === 'item3');

  if (!hasItem1 || !hasItem3) {
    console.error('FAIL: Deduplication resulted in missing items');
    process.exit(1);
  }

  // Check: uses deep equality (not just reference equality)
  const existing2 = [{ value: 'test' }];
  const update2 = [{ value: 'test' }, { value: 'new' }];
  const { result: result2, deduped: deduped2 } = deduplicateArrays(existing2, update2);

  if (deduped2 !== 1) {
    console.error('FAIL: Deep equality check not working for object comparison');
    process.exit(1);
  }

  console.log('PASS: Array deduplication API contract fulfilled');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error testing array deduplication API');
  console.error('Error:', error.message);
  process.exit(1);
}

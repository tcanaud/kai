#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: API contract for object merging
// Criterion: IF3 — "mergeYAML.objects(existing, update) - Recursively merges two objects, preserving existing keys and adding new ones"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeObjects } from '../../../packages/tcsetup/src/yaml-merge.js';

try {
  // Test: adds new keys
  const existing1 = { a: 1 };
  const update1 = { b: 2 };
  const result1 = mergeObjects(existing1, update1);

  if (result1.a !== 1 || result1.b !== 2) {
    console.error('FAIL: New keys not added correctly');
    process.exit(1);
  }

  // Test: preserves existing keys
  const existing2 = { a: 1, b: 2 };
  const update2 = { b: 999 };  // Try to overwrite
  const result2 = mergeObjects(existing2, update2);

  if (result2.b !== 2) {
    console.error('FAIL: Existing key was overwritten instead of preserved');
    process.exit(1);
  }

  // Test: recursive object merging
  const existing3 = {
    config: {
      database: { host: 'localhost' },
      custom: 'value'
    }
  };
  const update3 = {
    config: {
      database: { port: 5432 }
    }
  };
  const result3 = mergeObjects(existing3, update3);

  if (result3.config.database.host !== 'localhost') {
    console.error('FAIL: Recursive merge did not preserve nested value');
    process.exit(1);
  }

  if (result3.config.database.port !== 5432) {
    console.error('FAIL: Recursive merge did not add new nested value');
    process.exit(1);
  }

  if (result3.config.custom !== 'value') {
    console.error('FAIL: Recursive merge did not preserve sibling value');
    process.exit(1);
  }

  // Test: array handling within objects
  const existing4 = { items: [1, 2] };
  const update4 = { items: [2, 3] };
  const result4 = mergeObjects(existing4, update4);

  if (!Array.isArray(result4.items)) {
    console.error('FAIL: Array not handled in object merge');
    process.exit(1);
  }

  console.log('PASS: Object merging API contract fulfilled');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error testing object merging API');
  console.error('Error:', error.message);
  process.exit(1);
}

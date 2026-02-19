#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: API contract for deep equality checking
// Criterion: IF4 — "mergeYAML.deepEqual(a, b) - Tests deep equality between two values for deduplication"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { deepEqual } from '../../../packages/tcsetup/src/yaml-merge.js';

try {
  // Test: primitive equality
  if (!deepEqual(5, 5)) {
    console.error('FAIL: Primitives with same value should be equal');
    process.exit(1);
  }

  if (deepEqual(5, 6)) {
    console.error('FAIL: Primitives with different values should not be equal');
    process.exit(1);
  }

  // Test: string equality
  if (!deepEqual('hello', 'hello')) {
    console.error('FAIL: Strings should be equal when same');
    process.exit(1);
  }

  // Test: array equality
  if (!deepEqual([1, 2, 3], [1, 2, 3])) {
    console.error('FAIL: Arrays with same elements should be equal');
    process.exit(1);
  }

  if (deepEqual([1, 2, 3], [1, 2, 4])) {
    console.error('FAIL: Arrays with different elements should not be equal');
    process.exit(1);
  }

  // Test: object equality
  if (!deepEqual({ a: 1, b: 2 }, { a: 1, b: 2 })) {
    console.error('FAIL: Objects with same keys/values should be equal');
    process.exit(1);
  }

  if (deepEqual({ a: 1 }, { a: 1, b: 2 })) {
    console.error('FAIL: Objects with different keys should not be equal');
    process.exit(1);
  }

  // Test: nested object equality
  const nested1 = { config: { db: { host: 'localhost', port: 5432 } } };
  const nested2 = { config: { db: { host: 'localhost', port: 5432 } } };
  if (!deepEqual(nested1, nested2)) {
    console.error('FAIL: Nested objects with same structure should be equal');
    process.exit(1);
  }

  // Test: array of objects equality
  const arr1 = [{ id: 1, name: 'test' }, { id: 2, name: 'test2' }];
  const arr2 = [{ id: 1, name: 'test' }, { id: 2, name: 'test2' }];
  if (!deepEqual(arr1, arr2)) {
    console.error('FAIL: Arrays of objects with same content should be equal');
    process.exit(1);
  }

  // Test: null and undefined
  if (deepEqual(null, undefined)) {
    console.error('FAIL: null and undefined should not be equal');
    process.exit(1);
  }

  if (!deepEqual(null, null)) {
    console.error('FAIL: null should equal null');
    process.exit(1);
  }

  console.log('PASS: Deep equality API contract fulfilled');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error testing deep equality API');
  console.error('Error:', error.message);
  process.exit(1);
}

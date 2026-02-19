#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: Deduplication of corrupted files with duplicates
// Criterion: US1.AC3 — "Given a project where customize.yaml files have been previously corrupted with duplicates, When user runs `npx tcsetup update`, Then the duplicates are intelligently merged/deduplicated into a single copy"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

// Simulate a corrupted file with duplicate memories
const corruptedConfig = `agent:
  name: test
  version: 1.0
memories:
  - id: mem1
    text: Original
  - id: mem1
    text: Original
  - id: mem2
    text: Second`;

const updateConfig = `agent:
  name: test
  version: 1.0
memories:
  - id: mem1
    text: Original
  - id: mem2
    text: Second
  - id: mem3
    text: Third`;

try {
  const result = mergeYAML(corruptedConfig, updateConfig);

  if (!result.success) {
    console.error('FAIL: Merge operation failed');
    console.error('Errors:', result.errors.join(', '));
    process.exit(1);
  }

  // Check: should deduplicate mem1
  const mem1Count = result.data.memories.filter(m => m.id === 'mem1').length;
  if (mem1Count !== 1) {
    console.error(`FAIL: Expected mem1 deduplicated to 1 copy, but found ${mem1Count}`);
    process.exit(1);
  }

  // Check: should have all unique memories
  const expectedCount = 3; // mem1, mem2, mem3
  if (result.data.memories.length !== expectedCount) {
    console.error(`FAIL: Expected ${expectedCount} unique memories, but found ${result.data.memories.length}`);
    process.exit(1);
  }

  console.log('PASS: Corrupted file with duplicates successfully deduplicated');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: No duplication of configuration after update
// Criterion: US1.AC1 — "Given a project with BMAD installed and custom memories/menu items in core-bmad-master.customize.yaml, When user runs `npx tcsetup update`, Then the customize.yaml file contains the same configuration as before with no duplication"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

const existingConfig = `agent:
  name: core-bmad-master
  version: 1.0
memories:
  - id: mem1
    text: Custom memory
menu:
  - label: Deploy
    command: deploy`;

const updateConfig = `agent:
  name: core-bmad-master
  version: 1.0
memories:
  - id: mem1
    text: Custom memory
  - id: mem2
    text: New memory
menu:
  - label: Deploy
    command: deploy`;

try {
  const result = mergeYAML(existingConfig, updateConfig);

  if (!result.success) {
    console.error('FAIL: Merge operation failed');
    console.error('Errors:', result.errors.join(', '));
    process.exit(1);
  }

  // Check: memories should have no duplicates
  const memoryCount = result.data.memories.filter(m => m.id === 'mem1').length;
  if (memoryCount !== 1) {
    console.error(`FAIL: Expected 1 memory with id mem1, but found ${memoryCount}`);
    process.exit(1);
  }

  // Check: menu items should have no duplicates
  const deployCount = result.data.menu.filter(m => m.label === 'Deploy').length;
  if (deployCount !== 1) {
    console.error(`FAIL: Expected 1 menu item "Deploy", but found ${deployCount}`);
    process.exit(1);
  }

  // Check: total memories should be 2 (original + new)
  if (result.data.memories.length !== 2) {
    console.error(`FAIL: Expected 2 memories, but found ${result.data.memories.length}`);
    process.exit(1);
  }

  console.log('PASS: No duplication found after update');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

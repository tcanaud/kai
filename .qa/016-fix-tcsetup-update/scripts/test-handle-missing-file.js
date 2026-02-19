#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: Handle missing customize.yaml file gracefully
// Criterion: US3.AC1 — "Given a customize.yaml file is missing, When update runs, Then the file is created with default/new content if needed, or skipped gracefully"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

const existingConfig = '';  // Empty/missing file

const updateConfig = `agent:
  name: test
  version: 1.0
memories:
  - id: mem1
    text: Initial`;

try {
  const result = mergeYAML(existingConfig, updateConfig);

  if (!result.success) {
    console.error('FAIL: Merge operation failed when existing file is empty');
    console.error('Errors:', result.errors.join(', '));
    process.exit(1);
  }

  // Check: should create content from update
  if (!result.data.agent || result.data.agent.name !== 'test') {
    console.error('FAIL: Content was not created from update');
    process.exit(1);
  }

  // Check: should handle empty file gracefully
  if (!Array.isArray(result.data.memories) || result.data.memories.length !== 1) {
    console.error('FAIL: Memories were not created correctly');
    process.exit(1);
  }

  // Check: output should be valid YAML
  const yaml = result.toYAML();
  if (!yaml || typeof yaml !== 'string' || yaml.length === 0) {
    console.error('FAIL: Generated YAML is invalid');
    process.exit(1);
  }

  console.log('PASS: Missing file handled gracefully');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

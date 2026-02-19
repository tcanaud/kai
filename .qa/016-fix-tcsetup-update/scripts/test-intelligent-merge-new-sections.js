#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: Intelligent merge adds new sections without duplicating existing
// Criterion: US2.AC1 — "Given a customize.yaml with existing configuration, When an update needs to add new sections, Then those sections are added without duplicating existing content"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

const existingConfig = `agent:
  name: test
  version: 1.0
  custom_value: preserved
memories:
  - id: mem1
    text: Original`;

const updateConfig = `agent:
  name: test
  version: 1.0
  custom_value: preserved
memories:
  - id: mem1
    text: Original
new_section:
  key: value
  enabled: true`;

try {
  const result = mergeYAML(existingConfig, updateConfig);

  if (!result.success) {
    console.error('FAIL: Merge operation failed');
    console.error('Errors:', result.errors.join(', '));
    process.exit(1);
  }

  // Check: new_section should be added
  if (!result.data.new_section) {
    console.error('FAIL: new_section was not added');
    process.exit(1);
  }

  // Check: new_section should have correct content
  if (result.data.new_section.key !== 'value' || result.data.new_section.enabled !== true) {
    console.error('FAIL: new_section has incorrect content');
    process.exit(1);
  }

  // Check: existing content preserved
  if (result.data.agent.custom_value !== 'preserved') {
    console.error('FAIL: existing custom_value was not preserved');
    process.exit(1);
  }

  // Check: no duplication in memories
  if (result.data.memories.length !== 1) {
    console.error(`FAIL: Expected 1 memory, but found ${result.data.memories.length}`);
    process.exit(1);
  }

  console.log('PASS: New sections added without duplicating existing content');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

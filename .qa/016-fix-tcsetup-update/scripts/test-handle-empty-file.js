#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: Handle empty or comment-only YAML file
// Criterion: US3.AC3 — "Given a customize.yaml file is empty or has only comments, When update runs, Then new configuration is added correctly"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

const emptyFileWithComments = `# This is a comment
# File is mostly comments
# Config will be added`;

const updateConfig = `agent:
  name: test
  version: 1.0
settings:
  enabled: true`;

try {
  const result = mergeYAML(emptyFileWithComments, updateConfig);

  if (!result.success) {
    console.error('FAIL: Merge operation failed on empty/comment file');
    console.error('Errors:', result.errors.join(', '));
    process.exit(1);
  }

  // Check: should add new configuration
  if (!result.data.agent || result.data.agent.name !== 'test') {
    console.error('FAIL: New configuration was not added to comment-only file');
    process.exit(1);
  }

  // Check: should have settings
  if (!result.data.settings || result.data.settings.enabled !== true) {
    console.error('FAIL: Settings were not added correctly');
    process.exit(1);
  }

  // Check: output should be valid
  const yaml = result.toYAML();
  if (!yaml || typeof yaml !== 'string') {
    console.error('FAIL: Generated YAML is invalid');
    process.exit(1);
  }

  console.log('PASS: Empty or comment-only file handled correctly');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

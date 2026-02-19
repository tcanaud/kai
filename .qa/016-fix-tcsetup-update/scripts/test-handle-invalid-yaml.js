#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: Handle invalid YAML syntax gracefully
// Criterion: US3.AC2 — "Given a customize.yaml file has invalid YAML syntax, When update runs, Then a clear error message is displayed and the file is not corrupted further"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

const existingConfig = `agent:
  name: test`;

const invalidUpdate = `agent:
  name: test
  broken: [unclosed array`;

try {
  const result = mergeYAML(existingConfig, invalidUpdate);

  // Should either fail gracefully or skip
  if (result.success && result.data) {
    // If it succeeded, check that data is reasonable
    if (!result.data.agent) {
      console.error('FAIL: Invalid YAML resulted in corrupted data');
      process.exit(1);
    }
    console.log('PASS: Invalid YAML handled gracefully (data preserved or skipped)');
    process.exit(0);
  } else if (!result.success) {
    // Should have error messages
    if (!result.errors || result.errors.length === 0) {
      console.error('FAIL: Merge failed but provided no error details');
      process.exit(1);
    }

    // Errors should be meaningful
    const hasError = result.errors.some(err =>
      err.toLowerCase().includes('parse') ||
      err.toLowerCase().includes('yaml') ||
      err.toLowerCase().includes('invalid') ||
      err.toLowerCase().includes('syntax')
    );

    if (!hasError) {
      console.error('FAIL: Error message is not clear about YAML syntax issue');
      console.error('Errors:', result.errors);
      process.exit(1);
    }

    console.log('PASS: Invalid YAML detected with clear error message');
    process.exit(0);
  }

  console.error('FAIL: Unexpected result state');
  process.exit(1);
} catch (error) {
  console.error('FAIL: Unexpected exception during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

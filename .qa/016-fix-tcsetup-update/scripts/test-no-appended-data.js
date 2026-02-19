#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: No appended data to configuration after update
// Criterion: US1.AC2 — "Given a project with BMAD installed and custom settings in bmm-pm.customize.yaml, When user runs `npx tcsetup update`, Then the customize.yaml file contents remain unchanged with no appended data"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

const existingConfig = `agent:
  name: bmm-pm
  version: 1.0
  persona: Product Manager
persona:
  role: PM
  skills:
    primary: strategy
    secondary: execution`;

const sameUpdateConfig = `agent:
  name: bmm-pm
  version: 1.0
  persona: Product Manager
persona:
  role: PM
  skills:
    primary: strategy
    secondary: execution`;

try {
  const result = mergeYAML(existingConfig, sameUpdateConfig);

  if (!result.success) {
    console.error('FAIL: Merge operation failed');
    console.error('Errors:', result.errors.join(', '));
    process.exit(1);
  }

  // Serialize and compare
  const resultYAML = result.toYAML();

  // Count occurrences of key identifiers
  const strategyCount = (resultYAML.match(/strategy/g) || []).length;
  const executionCount = (resultYAML.match(/execution/g) || []).length;
  const pmCount = (resultYAML.match(/PM/g) || []).length;

  // Each should appear only once
  if (strategyCount !== 1) {
    console.error(`FAIL: 'strategy' appears ${strategyCount} times, expected 1`);
    process.exit(1);
  }

  if (executionCount !== 1) {
    console.error(`FAIL: 'execution' appears ${executionCount} times, expected 1`);
    process.exit(1);
  }

  if (pmCount !== 1) {
    console.error(`FAIL: 'PM' appears ${pmCount} times, expected 1`);
    process.exit(1);
  }

  console.log('PASS: No appended data found after update');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

#!/usr/bin/env node
// ──────────────────────────────────────────────────────
// Test: Preserve existing configuration that should not be modified
// Criterion: US2.AC2 — "Given a customize.yaml with existing configuration that should not be modified, When an update runs, Then existing configuration is preserved as-is"
// Feature: 016-fix-tcsetup-update
// Generated: 2026-02-19T00:00:00Z
// ──────────────────────────────────────────────────────

import { mergeYAML } from '../../../packages/tcsetup/src/yaml-merge.js';

const existingConfig = `agent:
  name: test
  version: 1.0
  custom_field: user_defined
persona:
  role: Manager
  department: Engineering
preferences:
  timeout: 300
  debug: true`;

const updateConfig = `agent:
  name: test
  version: 1.0
  custom_field: user_defined
persona:
  role: Manager
  department: Engineering
preferences:
  timeout: 300
  debug: true
  new_option: false`;

try {
  const result = mergeYAML(existingConfig, updateConfig);

  if (!result.success) {
    console.error('FAIL: Merge operation failed');
    console.error('Errors:', result.errors.join(', '));
    process.exit(1);
  }

  // Check: agent section preserved
  if (result.data.agent.version !== '1.0' || result.data.agent.custom_field !== 'user_defined') {
    console.error('FAIL: Agent section was modified');
    process.exit(1);
  }

  // Check: persona section preserved
  if (result.data.persona.role !== 'Manager' || result.data.persona.department !== 'Engineering') {
    console.error('FAIL: Persona section was modified');
    process.exit(1);
  }

  // Check: existing preferences preserved
  if (result.data.preferences.timeout !== 300 || result.data.preferences.debug !== true) {
    console.error('FAIL: Existing preferences were modified');
    process.exit(1);
  }

  // Check: new preference added
  if (result.data.preferences.new_option !== false) {
    console.error('FAIL: New preference was not added');
    process.exit(1);
  }

  console.log('PASS: Existing configuration preserved correctly');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Unexpected error during merge');
  console.error('Error:', error.message);
  process.exit(1);
}

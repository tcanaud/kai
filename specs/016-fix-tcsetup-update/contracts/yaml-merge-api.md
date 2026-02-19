# Contract: YAML Merge API

**Module**: `packages/tcsetup/src/yaml-merge.js` | **Date**: 2026-02-19

## Overview

This contract defines the public API for YAML configuration merging with deduplication. The module provides functions to intelligently merge YAML configurations while preserving user customizations and eliminating duplicates.

## Exports

### mergeYAML(existing, update, options)

Main merge function that combines two YAML configuration strings.

**Signature**:
```typescript
function mergeYAML(
  existing: string,
  update: string,
  options?: MergeOptions
): MergeResult
```

**Parameters**:
- `existing: string` - Current customize.yaml content (may be empty, null, or undefined)
- `update: string` - New configuration from tool update (required, non-empty)
- `options?: MergeOptions` - Optional merge configuration (see below)

**Returns**:
- `MergeResult` object (see data-model.md for structure)

**Behavior**:
- Returns result immediately (no exceptions thrown)
- All errors captured in `result.errors` array
- Preserves input strings (does not modify parameters)
- Handles empty/null existing gracefully (treats as starting from scratch)

**Example**:
```javascript
const result = mergeYAML(existingYAML, updateYAML);
if (result.success) {
  console.log(result.toYAML());
} else {
  console.error("Merge failed:", result.errors);
}
```

**Error Handling**:
- Invalid YAML syntax → `result.success = false`
- Missing parameters → `result.success = false`
- Cannot parse sections → logged in `result.errors`, attempt continues

---

### mergeYAML.arrays(existing, update)

Deduplicates two arrays by appending non-duplicate items from `update` to `existing`.

**Signature**:
```typescript
function mergeYAML.arrays(
  existing: Array<any>,
  update: Array<any>
): Array<any>
```

**Parameters**:
- `existing: Array` - Current array (may be empty)
- `update: Array` - New items to merge in

**Returns**:
- Merged array with duplicates removed

**Algorithm**:
- Preserves order: existing items first, new items appended
- Uses deep equality check (recursive comparison)
- Null/undefined items treated as regular values

**Example**:
```javascript
const existing = [{ id: 1, name: "Item A" }];
const update = [{ id: 1, name: "Item A" }, { id: 2, name: "Item B" }];
const result = mergeYAML.arrays(existing, update);
// Result: [{ id: 1, name: "Item A" }, { id: 2, name: "Item B" }]
```

---

### mergeYAML.objects(existing, update)

Recursively merges two objects, preserving existing keys and adding new ones.

**Signature**:
```typescript
function mergeYAML.objects(
  existing: object,
  update: object
): object
```

**Parameters**:
- `existing: object` - Current object (may be empty)
- `update: object` - New keys/values to add

**Returns**:
- Merged object combining both inputs

**Behavior**:
- All keys from both objects present in result
- Existing keys keep their values (not overwritten)
- New keys added from update
- Nested objects recursively merged
- Arrays within objects use `mergeYAML.arrays` logic

**Example**:
```javascript
const existing = { name: "Config", custom: "value" };
const update = { name: "Config", version: "1.0" };
const result = mergeYAML.objects(existing, update);
// Result: { name: "Config", custom: "value", version: "1.0" }
```

---

### mergeYAML.deepEqual(a, b)

Tests deep equality between two values (used for deduplication).

**Signature**:
```typescript
function mergeYAML.deepEqual(a: any, b: any): boolean
```

**Parameters**:
- `a: any` - First value
- `b: any` - Second value

**Returns**:
- `true` if values are deeply equal, `false` otherwise

**Behavior**:
- Recursively compares objects and arrays
- Order matters (arrays must have items in same order)
- Null and undefined are different
- Different types are not equal

**Example**:
```javascript
deepEqual({ id: 1 }, { id: 1 });  // true
deepEqual([1, 2], [1, 2]);        // true
deepEqual([1, 2], [2, 1]);        // false
deepEqual(null, undefined);        // false
```

---

### mergeYAML.parseYAML(content)

Parses YAML string into structured configuration object.

**Signature**:
```typescript
function mergeYAML.parseYAML(content: string): YAMLConfiguration
```

**Parameters**:
- `content: string` - YAML file content (may be empty or comments-only)

**Returns**:
- `YAMLConfiguration` object (see data-model.md)

**Behavior**:
- Tolerates empty files (returns empty config)
- Preserves comments and formatting metadata
- Extracts tool markers (# Agent Customization, etc.)
- Captures line numbers for each section

**Example**:
```javascript
const config = mergeYAML.parseYAML(yamlContent);
config.sections.forEach((section, name) => {
  console.log(`${name}: ${section.type}`);
});
```

---

### mergeYAML.serializeYAML(config)

Converts parsed configuration back to YAML text.

**Signature**:
```typescript
function mergeYAML.serializeYAML(config: YAMLConfiguration): string
```

**Parameters**:
- `config: YAMLConfiguration` - Parsed configuration object

**Returns**:
- YAML-formatted string ready for file writing

**Behavior**:
- Preserves markers and comments
- Maintains standard YAML formatting (2-space indents)
- Produces valid, parseable YAML output
- Validates output before returning (throws on invalid)

---

### mergeYAML.validate(yaml)

Validates that a YAML string is syntactically and semantically correct.

**Signature**:
```typescript
function mergeYAML.validate(yaml: string): Array<string>
```

**Parameters**:
- `yaml: string` - YAML content to validate

**Returns**:
- Array of error strings (empty if valid)

**Checks**:
- Valid YAML syntax
- All sections are objects or arrays
- No duplicate keys in objects
- No invalid values

**Example**:
```javascript
const errors = mergeYAML.validate(yaml);
if (errors.length > 0) {
  console.error("Invalid YAML:", errors);
}
```

---

## Types

### MergeOptions

Configuration options for merge operation.

```typescript
interface MergeOptions {
  // Preserve original file if merge encounters errors
  // Default: true
  preserveOnError?: boolean;

  // Tool identifier for marker detection
  // Default: auto-detect from markers
  toolId?: string;

  // Array deduplication strategy
  // "deep-equal" = recursively compare all fields
  // "key-based" = compare by specific key (if present)
  // Default: "deep-equal"
  deduplicateBy?: "deep-equal" | "key-based";

  // Which key to use for key-based deduplication
  // Default: "id"
  deduplicateKey?: string;
}
```

---

### MergeResult

Result of a merge operation.

```typescript
interface MergeResult {
  success: boolean;
  merged: YAMLConfiguration;
  warnings: string[];
  errors: string[];
  changelog: MergeChangelog;

  toYAML(): string;
  validate(): string[];
}
```

See data-model.md for detailed structure.

---

## Invariants

1. **No Data Loss**: Merge always preserves user customizations and existing content
2. **Idempotency**: Running merge twice with same update produces same result as running once
3. **YAML Validity**: Output is always valid YAML (or merge fails before serialization)
4. **Deduplication Soundness**: No duplicates in output arrays for equivalent items
5. **Marker Preservation**: Tool-specific markers remain after merge
6. **Order Preservation**: Array order is preserved (existing → new)

---

## Performance Requirements

- Merge operation on <500 line YAML: < 100ms
- Parse + serialize roundtrip: < 50ms
- Memory usage: < 10MB for typical customize.yaml files
- No external process spawning (pure JavaScript)

---

## Testing Requirements

See `/specs/016-fix-tcsetup-update/tests/` for test files.

**Must pass**:
- Unit tests for each function
- Integration tests with real customize.yaml files
- Edge case tests (empty files, invalid YAML, etc.)
- Idempotency tests (merge twice = merge once)
- Deduplication correctness tests

---

## Integration Points

This module is used by:

1. `/packages/agreement-system/src/updater.js` (via tcsetup)
2. `/packages/feature-lifecycle/src/updater.js` (via tcsetup)
3. `/packages/tcsetup/src/updater.js` (orchestrates the above)

**Usage pattern**:
```javascript
import { mergeYAML } from "../../tcsetup/src/yaml-merge.js";

// Instead of:
writeFileSync(destPath, existing.trimEnd() + "\n\n" + snippet);

// Use:
const result = mergeYAML(existing, snippet);
if (result.success) {
  writeFileSync(destPath, result.toYAML());
}
```

---

## Backward Compatibility

- No breaking changes to existing tools
- Can be adopted incrementally by each tool
- Graceful fallback if module not found (though not recommended)

---

## Future Extensions

- Configuration hook system (allow custom merge strategies)
- Marker validation (ensure well-formed markers)
- Format preservation (maintain user's indentation style)
- Three-way merge support (merge new update + existing + base version)

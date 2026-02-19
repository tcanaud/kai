# Quickstart: YAML Configuration Merging

**For**: Developers implementing 016-fix-tcsetup-update | **Date**: 2026-02-19

## What This Feature Does

When developers run `npx tcsetup update`, their configuration files (customize.yaml) get updated with new tool configurations. This feature ensures:

✓ **No duplicates** - Running update twice doesn't double-add configuration
✓ **Preserves customizations** - User edits to memories, menu items, persona settings stay intact
✓ **Merges intelligently** - New tool features are added cleanly without corrupting file structure
✓ **Handles edge cases** - Missing files, invalid YAML, empty configs all work gracefully

## The Problem

Currently, tools like `agreement-system` and `feature-lifecycle` blindly append configuration snippets to customize.yaml:

```javascript
// OLD (BROKEN) - Just concatenates strings
writeFileSync(destPath, existing.trimEnd() + "\n\n" + snippet);
```

**Result**: Running update twice corrupts the file with duplicate sections.

## The Solution

Create a smart YAML merge module that:
1. Parses YAML properly (not just string manipulation)
2. Deduplicates arrays (memories, menu items)
3. Merges objects intelligently (preserves existing keys)
4. Validates output before writing
5. Handles errors gracefully

## File Locations

### New Files to Create

```
packages/tcsetup/src/
└── yaml-merge.js          ← Main merge logic (320-400 lines)

packages/tcsetup/tests/
├── yaml-merge.test.js     ← Unit tests
├── integration.test.js    ← Integration tests
└── fixtures/
    ├── customize-empty.yaml
    ├── customize-with-memories.yaml
    └── customize-corrupted.yaml
```

### Files to Modify

```
packages/agreement-system/src/updater.js     ← Use mergeYAML() instead of append
packages/feature-lifecycle/src/updater.js    ← Use mergeYAML() instead of append
```

## Implementation Steps

### Step 1: Create yaml-merge.js Module

**Purpose**: Export the merge functions

**Key exports**:
```javascript
export function mergeYAML(existing, update, options = {})
export function mergeYAML.arrays(existing, update)
export function mergeYAML.objects(existing, update)
export function mergeYAML.deepEqual(a, b)
export function mergeYAML.parseYAML(content)
export function mergeYAML.serializeYAML(config)
export function mergeYAML.validate(yaml)
```

**Structure**:
1. Parse YAML strings into objects
2. Merge at section level (agent, memories, menu, etc.)
3. For arrays: deduplicate by deep equality
4. For objects: merge keys recursively
5. Serialize back to YAML
6. Validate output
7. Return result with changelog

**Key algorithms**:
- Deep equality check for deduplication
- Recursive object merge preserving existing keys
- YAML-to-object conversion without external libraries

### Step 2: Write Unit Tests

**Test file**: `packages/tcsetup/tests/yaml-merge.test.js`

**Test categories**:

1. **Array deduplication**:
   - Duplicate simple items: `[1, 2] + [1, 2, 3]` → `[1, 2, 3]`
   - Duplicate objects: `[{id:1}] + [{id:1}, {id:2}]` → `[{id:1}, {id:2}]`
   - Order preservation: existing items stay first

2. **Object merging**:
   - New keys added: `{a:1} + {b:2}` → `{a:1, b:2}`
   - Existing keys preserved: `{a:1} + {a:2, b:3}` → `{a:1, b:3}`
   - Nested merge: `{x:{a:1}} + {x:{b:2}}` → `{x:{a:1, b:2}}`

3. **Deep equality**:
   - Simple values: `1 === 1`, `"a" === "a"`
   - Objects: `{a:1} === {a:1}` (field-wise comparison)
   - Arrays: `[1,2] === [1,2]`, but `[1,2] !== [2,1]`
   - Null vs undefined: different

4. **Edge cases**:
   - Empty existing: `"" + snippet` → snippet content
   - Empty update: `existing + ""` → unchanged
   - Invalid YAML: proper error handling
   - Comments preserved: `# Comment\ndata:` → comment stays

### Step 3: Write Integration Tests

**Test file**: `packages/tcsetup/tests/integration.test.js`

**Scenarios**:
1. Simulate `npx tcsetup update` twice on same project
   - Run merge first time: add tool section to customize.yaml
   - Run merge second time: should be idempotent (no duplicates)
   - Verify: file content identical both times

2. Test with real tool templates
   - Use actual `templates/bmad/core-bmad-master.customize.yaml` from agreement-system
   - Use actual `templates/bmad/bmm-pm.customize.yaml` from feature-lifecycle
   - Verify merged result is valid YAML

3. Test with corrupted files
   - Create customize.yaml with duplicates
   - Merge with fresh update
   - Verify duplicates removed, no data loss

### Step 4: Modify agreement-system Updater

**File**: `packages/agreement-system/src/updater.js`

**Change**:
```javascript
// OLD (line 87)
writeFileSync(destPath, existing.trimEnd() + "\n\n" + snippet);

// NEW
import { mergeYAML } from "../../tcsetup/src/yaml-merge.js";

const result = mergeYAML(existing, snippet);
if (result.success) {
  writeFileSync(destPath, result.toYAML());
  console.log(`    update ${file} (merged)`);
} else {
  console.error(`    error: ${file} - ${result.errors[0]}`);
}
```

### Step 5: Modify feature-lifecycle Updater

**File**: `packages/feature-lifecycle/src/updater.js`

**Change**:
```javascript
// OLD (line 86)
writeFileSync(destPath, existing.trimEnd() + "\n\n" + snippet);

// NEW
import { mergeYAML } from "../../tcsetup/src/yaml-merge.js";

const result = mergeYAML(existing, snippet);
if (result.success) {
  writeFileSync(destPath, result.toYAML());
  console.log(`    update ${file} (merged)`);
} else {
  console.error(`    error: ${file} - ${result.errors[0]}`);
}
```

## Example Usage

### Before (Broken)
```javascript
const existing = `
agent:
  name: bmm-pm

memories:
  - id: mem1
    text: "User's custom memory"
`;

const update = `
agent:
  name: bmm-pm

memories:
  - id: mem1
    text: "User's custom memory"
  - id: mem2
    text: "New tool memory"
`;

// OLD: Just concatenates
result = existing.trimEnd() + "\n\n" + update;
// Result: FILE IS CORRUPTED WITH DUPLICATES!
```

### After (Fixed)
```javascript
import { mergeYAML } from "./yaml-merge.js";

const result = mergeYAML(existing, update);

if (result.success) {
  console.log(result.toYAML());
  // Result:
  // agent:
  //   name: bmm-pm
  // memories:
  //   - id: mem1
  //     text: "User's custom memory"
  //   - id: mem2
  //     text: "New tool memory"
}
```

## Key Design Decisions

### Why Deep Equality for Arrays?
- Handles complex objects (memories with nested data)
- Exact deduplication (no false positives)
- Alternative (key-based) insufficient for some items

### Why No External YAML Library?
- Project requirement: zero runtime dependencies
- Node.js built-ins sufficient for customize.yaml structure
- Keeps code lightweight and predictable

### Why Preserve Existing Keys in Objects?
- User customizations important
- New tool features added without overwriting user settings
- Aligns with real-world use cases

### Why Continue on Error?
- Robustness: one file error shouldn't block all updates
- Developer experience: can fix one file and re-run
- Alternative (fail fast) too disruptive

## Testing Your Implementation

```bash
# Run unit tests
node --test packages/tcsetup/tests/yaml-merge.test.js

# Run integration tests
node --test packages/tcsetup/tests/integration.test.js

# Manual test: simulate actual update
cd /tmp/test-project
npx tcsetup        # Initial setup
npx tcsetup update # First update (with new logic)
npx tcsetup update # Second update (should be idempotent)
# Verify customize.yaml unchanged between last two steps
```

## Success Criteria

- ✓ SC-001: Running `npx tcsetup update` twice produces identical files
- ✓ SC-002: 100% of customize.yaml files contain no duplicate sections after update
- ✓ SC-003: Custom configuration values preserved exactly as set before update
- ✓ SC-004: All YAML files maintain valid syntax after update

## Common Pitfalls

1. **Don't just check `if (array.includes(item))`**
   - Won't work for object items (reference equality)
   - Use `deepEqual()` instead

2. **Don't replace entire objects**
   - `{a:1} + {b:2}` should be `{a:1, b:2}`, not just `{b:2}`
   - Merge keys, don't overwrite

3. **Don't preserve formatting/comments**
   - Out of scope (per spec assumptions)
   - Standardize to 2-space indents

4. **Don't handle YAML merge keys or anchors**
   - Customize files don't use these features
   - Simplify to basic YAML structure

## Next: Phase 2 (Implementation)

Once design is approved:
1. Create `/speckit.tasks` with specific implementation tasks
2. Implement yaml-merge.js with full test coverage
3. Modify updater files in agreement-system and feature-lifecycle
4. Run full integration suite to verify all success criteria
5. Create PR and merge to main

# Research: Fix tcsetup Update Configuration Merging

**Date**: 2026-02-19 | **Feature**: 016-fix-tcsetup-update

## Overview

This document consolidates findings from research into the tcsetup update configuration merging problem and establishes the technical approach for implementing intelligent YAML merging with deduplication.

## Key Findings

### 1. Root Cause Analysis

**Problem**: Configuration files get corrupted through blind text appending

**Locations where appending occurs**:
- `/packages/agreement-system/src/updater.js` (line 87)
- `/packages/feature-lifecycle/src/updater.js` (lines 86)
- `/packages/tcsetup/src/updater.js` doesn't directly modify YAML but orchestrates these tools

**Current behavior**:
```javascript
// Problem code in agreement-system/src/updater.js
writeFileSync(destPath, existing.trimEnd() + "\n\n" + snippet);
```

This blindly appends the new configuration section without:
1. Checking if equivalent content already exists
2. Deduplicating array items (memories, menu)
3. Merging object keys
4. Handling YAML syntax validation

### 2. Customize.yaml Structure

**Typical customize.yaml sections** (from BMAD configuration):
```yaml
# Agent Configuration
agent:
  name: bmm-pm
  version: "1.0"

# Memories/Knowledge
memories:
  - id: memory-1
    content: "..."
  - id: memory-2
    content: "..."

# Menu Items
menu:
  - label: "Item 1"
    action: "do_something"

# Persona Settings
persona:
  style: "formal"
  voice: "professional"

# System Sections (added by sub-tools)
# Agent Customization (from agreement-system)
# Feature Lifecycle Tracker (from feature-lifecycle)
```

**Key characteristics**:
- Multiple independent sections separated by comments
- Array fields (memories, menu) should deduplicate by content
- Object fields should merge keys without duplication
- Each system adds its own marked section (comment-based markers)

### 3. Current Marker Strategy

Two systems use comment-based markers to identify their sections:

**agreement-system**: Uses marker `# Agent Customization`
- Attempts to find and replace its section
- Falls back to appending if marker not found
- Can fail if multiple sections exist

**feature-lifecycle**: Uses marker `# Feature Lifecycle Tracker`
- Replaces from marker to EOF (assumes it's last)
- Falls back to appending
- Problem: doesn't preserve other systems' content after its marker

**Shared issue**: Neither tool implements proper YAML-aware merging. They manipulate text instead of data structures.

### 4. YAML Parsing & Merging Approach

**Decision**: Create a dedicated YAML merge utility module

**Why not use existing npm packages?**
- Zero runtime dependencies requirement (per CLAUDE.md)
- Can use built-in Node.js capabilities (fs, path)
- YAML files here are simple enough for custom parser

**Implementation approach**:
1. Parse YAML using built-in JavaScript (no external deps)
2. Implement recursive merge with:
   - Array deduplication (by deep equality or content hash)
   - Object merging (preserving both old and new keys)
   - Type validation (ensure arrays stay arrays, objects stay objects)
3. Preserve comments and formatting where possible (non-critical)
4. Validate output YAML before writing

**Libraries considered**:
- `js-yaml`: Would violate zero-dependency requirement ✗
- `yaml`: Would violate zero-dependency requirement ✗
- Custom parser: Aligns with project guidelines, maintains control ✓

### 5. Deduplication Logic

**For arrays (memories, menu)**:
- Deduplicate by deep equality of objects
- For simple values, deduplicate by value
- Order should be preserved (existing items first, new items appended)
- Test case: Running update twice should not double-add items

**For objects (agent, persona, critical_actions)**:
- Merge keys recursively
- New keys are added; existing keys use new values if provided
- No key deletion (preserve user customizations)

**Example**:
```javascript
// Input: existing config
memories: [{ id: "mem1", text: "Keep this" }]

// Input: new config from tool update
memories: [{ id: "mem1", text: "Keep this" }, { id: "mem2", text: "Add this" }]

// Output: merged (deduplicated)
memories: [{ id: "mem1", text: "Keep this" }, { id: "mem2", text: "Add this" }]
```

### 6. Edge Cases & Handling

**Case 1: Missing customize.yaml file**
- Decision: Create it with new content (don't fail)
- Rationale: User may be running update after manual deletion

**Case 2: Empty or comments-only customize.yaml**
- Decision: Write new content as-is
- Rationale: User hasn't configured yet; this is first-time setup

**Case 3: Invalid YAML syntax**
- Decision: Log error, skip file, continue with other files
- Rationale: Don't corrupt further; user needs to fix manually
- Note: This is out of scope per spec (OoS-Conflicting values)

**Case 4: Previously corrupted with duplicates**
- Decision: Merge intelligently; duplicates are deduplicated
- Rationale: Aligns with SC-001 success criteria

**Case 5: User manually edited customize.yaml**
- Decision: Merge preserves user edits; new tool sections added cleanly
- Rationale: Maximize compatibility; preserve customizations

### 7. Testing Strategy

**Unit tests** (`tests/yaml-merge.test.js`):
- Test merge of simple objects
- Test deduplication of arrays
- Test edge cases (empty objects, null values, nested structures)
- Test preservation of non-conflicting keys
- Test invalid YAML handling

**Integration tests** (`tests/integration.test.js`):
- Simulate running `npx tcsetup update` twice
- Verify no duplication occurs on second run
- Test with real customize.yaml templates from agreement-system and feature-lifecycle
- Verify file syntax remains valid YAML

**Test fixtures**:
- Sample customize.yaml files in `tests/fixtures/`
- Templates from agreement-system and feature-lifecycle BMAD configs

### 8. Implementation Plan

**Phase 0 (Research)** - COMPLETE
- Identified root cause and locations
- Documented customize.yaml structure
- Established merge strategy
- Defined edge cases

**Phase 1 (Design & Contracts)** - NEXT
- Create yaml-merge.js API contract
- Design merge function signatures
- Define error handling contract
- Document quickstart for implementation

**Phase 2 (Implementation)** - FOLLOWS PHASE 1
- Create `packages/tcsetup/src/yaml-merge.js`
- Create tests for yaml-merge.js
- Modify agreement-system/src/updater.js to use merge instead of append
- Modify feature-lifecycle/src/updater.js to use merge instead of append
- Update tcsetup orchestration if needed
- Verify all success criteria met

## Decision Summary

| Decision | Rationale | Alternatives Rejected |
|----------|-----------|----------------------|
| Create dedicated yaml-merge.js module | Keeps concern isolated; reusable for other tools | Inline merging in each updater (scattered logic) |
| Zero runtime dependencies | Per project guidelines (CLAUDE.md) | Using js-yaml (violates constraint) |
| Deep equality for array dedup | Handles complex objects (memories with nested data) | Key-based dedup (insufficient for menu items) |
| Comment-based markers remain | Minimal change to existing code; other tools may use same pattern | Refactor all marker strategies (larger scope) |
| Intelligent merge (not overwrite) | Preserves user customizations; enables feature additions | Simple replace (loses user edits) |
| Continue on error (skip file) | Robustness; prevent one file error from blocking all updates | Fail fast (disrupts developer workflow) |

## Next Steps

1. Phase 1: Generate data-model.md documenting the merge algorithm details
2. Phase 1: Create API contract for yaml-merge.js function signatures
3. Phase 1: Generate quickstart.md with usage examples
4. Phase 2: Create tasks for implementation (via /speckit.tasks command)

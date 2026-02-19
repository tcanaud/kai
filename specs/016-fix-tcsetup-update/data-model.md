# Data Model: Configuration Merging

**Feature**: 016-fix-tcsetup-update | **Date**: 2026-02-19

## Core Entities

### YAMLConfiguration

Represents the structure of a customize.yaml configuration file.

**Fields**:
- `sections: Map<string, Section>` - Named sections of the configuration (agent, memories, menu, persona, critical_actions, prompts, and tool-specific sections)
- `comments: Map<string, string>` - Leading comments preserved from original file
- `markers: Map<string, Marker>` - Tool-specific markers (e.g., "# Agent Customization") with their line ranges
- `raw: string` - Original file content (for preserve-on-error)

**Relationships**:
- `Section` - Each section contains typed data (objects or arrays)

**Validation rules**:
- Must be valid YAML parseable
- Each section must be either an object or array (not mixed in same section)
- Comments preceding sections should be preserved
- Markers must be on their own line with format `# Section Name`

---

### Section

Represents a top-level section within the configuration (agent, memories, menu, etc.).

**Fields**:
- `name: string` - Section identifier (e.g., "memories", "menu", "agent")
- `type: "object" | "array"` - The data type of this section
- `value: object | Array<any>` - The actual configuration data
- `leadingComment: string | null` - Comment lines preceding this section
- `lineNumber: number` - Starting line in original file (for tracking)

**Relationships**:
- Part of `YAMLConfiguration`
- `value` may contain nested sections

**Validation rules**:
- Section names are lowercase alphanumeric + underscore
- Array sections preserve order
- Object sections may have any string keys
- null/undefined values are allowed (represent absence of configuration)

---

### Marker

Represents a tool-specific section marker with boundaries.

**Fields**:
- `name: string` - Marker text (e.g., "Agent Customization", "Feature Lifecycle Tracker")
- `startLine: number` - Line where marker comment appears
- `endLine: number | null` - Last line of this marker's content (null = EOF or next marker)
- `toolId: string` - Which tool owns this section ("agreement-system", "feature-lifecycle", etc.)
- `content: string` - The marked section content

**Relationships**:
- References section in `YAMLConfiguration`

**Validation rules**:
- Markers must be on their own line starting with `#`
- Each tool should have at most one marker per file
- Markers cannot overlap
- Markers should be preserved during merges

---

## Merge Algorithm

### MergeResult

Output of a merge operation.

**Fields**:
- `success: boolean` - Whether merge completed without errors
- `merged: YAMLConfiguration` - The merged configuration
- `warnings: Array<string>` - Non-fatal issues encountered (dedup skipped, format lost, etc.)
- `errors: Array<string>` - Fatal issues (invalid YAML, etc.)
- `changelog: MergeChangelog` - Detailed record of what changed

**Methods**:
- `toYAML(): string` - Serialize merged config back to YAML text
- `validate(): Array<string>` - Validate merged output (returns errors if any)

---

### MergeChangelog

Tracks what happened during merge for observability.

**Fields**:
- `added: Array<{section, items}>` - What new content was added
- `deduplicated: Array<{section, count}>` - How many duplicates were removed
- `preserved: Array<string>` - What user customizations were kept
- `merged: Array<{section, keys}>` - What object keys were merged

**Example**:
```json
{
  "added": [
    { "section": "memories", "items": ["new_memory_id"] }
  ],
  "deduplicated": [
    { "section": "menu", "count": 2 }
  ],
  "preserved": [
    "memories[0]",
    "persona.custom_field"
  ],
  "merged": [
    { "section": "agent", "keys": ["version", "name"] }
  ]
}
```

---

## Merge Strategies

### For Arrays (memories, menu, etc.)

**Algorithm**:
1. Parse existing array items from existing file
2. Parse new array items from update snippet
3. For each new item:
   - Check if deep-equal to any existing item
   - If found, skip (already present)
   - If not found, append to existing array
4. Preserve order: existing items first, new items appended

**Deep equality check**:
- Recursively compare all fields
- Order matters for arrays within items
- Null and undefined are treated as different from absent

**Example**:
```javascript
// Existing
memories: [
  { id: "mem1", text: "Original" }
]

// Update
memories: [
  { id: "mem1", text: "Original" },
  { id: "mem2", text: "New" }
]

// Result (mem1 deduplicated)
memories: [
  { id: "mem1", text: "Original" },
  { id: "mem2", text: "New" }
]
```

---

### For Objects (agent, persona, critical_actions, etc.)

**Algorithm**:
1. Parse existing object keys/values
2. Parse new object keys/values
3. Merge:
   - Keep all existing keys
   - Add new keys from update
   - For conflicting keys: new value overwrites (tool updates should be applied)
4. Preserve order: existing keys first, new keys appended

**Special case - nested objects**:
- Recursively merge nested objects (don't replace entire object, merge fields)
- Arrays within objects use array dedup strategy

**Example**:
```javascript
// Existing
agent: {
  name: "bmm-pm",
  custom_field: "user_value"
}

// Update
agent: {
  name: "bmm-pm",
  version: "1.0"
}

// Result
agent: {
  name: "bmm-pm",
  custom_field: "user_value",
  version: "1.0"
}
```

---

### For Marker Sections

**Algorithm**:
1. Identify existing marker section (if present)
2. If marker exists with endLine < EOF:
   - Replace only that section
   - Preserve content before and after
3. If marker exists extending to EOF:
   - Replace from marker to EOF
   - (This is the feature-lifecycle current behavior)
4. If marker not found:
   - Append new marker section with content
5. Use intelligent merge (not simple text replacement) when handling marker content

**Rationale**:
- Each tool maintains its own section via markers
- Preserves other tools' content
- Cleaner than mixing all content into one section

---

## State Transitions

### YAMLConfiguration Lifecycle

```
Initial (file on disk)
    ↓
Parse (parse YAML + extract markers)
    ↓
Validate (ensure structure is sound)
    ↓
Merge (combine with new content)
    ↓
Validate Output (ensure merged result is valid)
    ↓
Serialize (convert back to YAML text)
    ↓
Write (save to disk)
```

---

## Validation Rules

### Parse Time
- ✓ File must exist or be creatable
- ✓ File must be valid YAML (or empty/comments-only)
- ✓ Sections must be objects or arrays, not mixed

### Merge Time
- ✓ New content must also be valid YAML
- ✓ Merge should not lose user customizations
- ✓ Deduplication must be exact (deep equality)
- ✓ Tool markers must remain distinct

### Serialize Time
- ✓ Output must be valid YAML
- ✓ All existing keys from both configs present (unless explicitly removed)
- ✓ No key duplicates in object sections
- ✓ No array value duplicates in array sections

---

## API Contracts

### mergeYAML(existing: string, update: string): MergeResult

Merges two YAML configuration strings.

**Parameters**:
- `existing: string` - Current customize.yaml content (or empty string)
- `update: string` - New content from tool update

**Returns**: `MergeResult` object with merged config

**Throws**: Never (errors captured in result.errors)

**Example**:
```javascript
const result = mergeYAML(existingYAML, updateYAML);
if (result.success) {
  writeFileSync(path, result.toYAML());
} else {
  console.error("Merge failed:", result.errors);
}
```

---

### parseYAML(content: string): YAMLConfiguration

Parses YAML string into structured object.

**Parameters**:
- `content: string` - YAML file content

**Returns**: `YAMLConfiguration` object

**Throws**: Never (errors in result.errors)

---

### deduplicateArrays(existing: Array, update: Array): Array

Deduplicates array by appending non-duplicate items from update.

**Parameters**:
- `existing: Array` - Current array (may be empty)
- `update: Array` - New items to merge in

**Returns**: Deduplicated array with existing items first

**Algorithm**: Deep equality check on each item

---

### mergeObjects(existing: object, update: object): object

Recursively merges objects without overwriting existing keys.

**Parameters**:
- `existing: object` - Current object (may be empty)
- `update: object` - New keys/values to merge

**Returns**: Merged object

**Behavior**: Existing keys preserved, new keys added, nested objects recursively merged

---

## Error Handling

**Types of errors**:
1. **Parse error**: Invalid YAML syntax
   - Action: Log error, mark result as failed, keep original file

2. **Merge conflict**: Contradictory key values (not auto-resolvable)
   - Action: Log warning, prefer new value, note in changelog

3. **File I/O error**: Cannot read/write file
   - Action: Log error, skip this file, continue

4. **Validation error**: Output YAML invalid
   - Action: Log error, do not write, keep original file

---

## Usage Example

```javascript
import { mergeYAML } from "./yaml-merge.js";

const existingContent = readFileSync("customize.yaml", "utf-8");
const updateContent = readFileSync("bmad/template.yaml", "utf-8");

const result = mergeYAML(existingContent, updateContent);

if (result.success) {
  writeFileSync("customize.yaml", result.toYAML());
  console.log("Merged successfully!");
  console.log("Changes:", result.changelog);
} else {
  console.error("Merge failed:", result.errors);
}
```

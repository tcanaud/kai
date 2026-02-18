# Task: Generate Mermaid Diagram

> **Module**: mermaid-workbench
> **Contract**: specs/002-mermaid-workbench/contracts/task-generate.yaml
> **Execution**: Launch via Claude Code Task tool (subagent_type: general-purpose)

## Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | string | yes | Natural language description of the diagram to generate |
| `type` | enum | yes | `flowchart` \| `state` \| `architecture` \| `sequence` |
| `layer` | enum | yes | `L0` \| `L1` \| `L2` |
| `parent` | string | L1/L2 | Parent reference: `<diagram-id>#<node-id>` |
| `feature` | string | yes | Feature identifier (`xxx-feature-name`) |
| `diagram_id` | string | no | Custom diagram ID (auto-generated from description if omitted) |

---

## Step 1: Validate Input Parameters

### Type Validation

Check that `type` is one of the supported types. If not, return an error:

```
ERROR: Unsupported diagram type "{type}".
Supported types: flowchart, state, architecture, sequence
```

### Layer Validation

Check that `layer` is one of: `L0`, `L1`, `L2`. If not, return an error:

```
ERROR: Unsupported layer "{layer}".
Supported layers: L0, L1, L2
```

### Parent Validation

- If `layer` is `L1` or `L2` and `parent` is not provided:
  ```
  ERROR: Layer {layer} requires a parent parameter.
  Format: <diagram-id>#<node-id>
  Example: system-architecture#auth-service
  ```
- If `parent` is provided, validate the format matches `<diagram-id>#<node-id>` (must contain exactly one `#`).
- If `layer` is `L0` and `parent` is provided, ignore it (L0 diagrams have no parent).

### Parent Existence Validation

When `parent` is specified:

1. Parse `parent` into `parent_diagram_id` and `parent_node_id` (split on `#`)
2. Resolve parent file path: `.bmad_output/mermaid/<feature>/L*-<parent_diagram_id>.mmd`
3. **Verify parent file exists** on disk. If not found:
   ```
   ERROR: Parent diagram "{parent_diagram_id}" not found in feature "{feature}".
   Searched: .bmad_output/mermaid/<feature>/L*-<parent_diagram_id>.mmd
   ```
4. **Read parent file** and verify that `parent_node_id` exists in the Mermaid content (search for the node ID in the diagram syntax). If not found:
   ```
   ERROR: Node "{parent_node_id}" not found in parent diagram "{parent_diagram_id}".
   Available nodes: [list node IDs found in parent]
   ```

---

## Step 2: Load Module Configuration

Read `_bmad/modules/mermaid-workbench/config.yaml` to confirm:
- `output_path` (default: `.bmad_output/mermaid/`)
- `naming_convention` (default: `L{n}-{id}.mmd`)

---

## Step 3: Load Template

Read the appropriate template from `_bmad/modules/mermaid-workbench/templates/<type>.md`.

Use the template's conventions (node shapes, link styles, direction) to guide diagram generation.

---

## Step 4: Resolve Output Path

1. Build feature directory: `<output_path>/<feature>/`
2. Create the directory if it does not exist
3. Generate `diagram_id` if not provided:
   - Extract key words from description
   - Convert to kebab-case
   - Ensure unique within feature
4. Build filename: `L{layer_number}-{diagram_id}.mmd`
   - Layer number: L0 → 0, L1 → 1, L2 → 2
5. Full path: `<feature_directory>/<filename>`

---

## Step 5: Generate Diagram Content

Using the loaded template and the natural language description:

1. **Choose the Mermaid directive** from the template (e.g., `flowchart TD`, `stateDiagram-v2`)
2. **Generate Mermaid syntax** following the template conventions:
   - Use the node shapes specified for the diagram type
   - Use the link styles specified for the diagram type
   - Follow naming conventions (kebab-case IDs, descriptive labels)
3. **The generated Mermaid MUST be syntactically valid** — parsable by Mermaid.js

---

## Step 6: Write .mmd File

Write the file with YAML frontmatter followed by Mermaid content:

```
---
id: {diagram_id}
title: {generated_title}
type: {type}
layer: {layer}
parent: {parent}          # Only if layer is L1 or L2
children: []              # Empty initially
feature: {feature}
---

{mermaid_content}
```

- Frontmatter is delimited by `---`
- A blank line separates frontmatter from Mermaid content
- `parent` field is omitted for L0 diagrams
- `children` starts as an empty list

---

## Step 7: Update Parent Diagram (if parent specified)

When `parent` is specified (L1/L2 diagrams):

### 7a: Add click directive to parent

Read the parent `.mmd` file and add a `click` directive for drill-down navigation:

```mermaid
click <parent_node_id> "./<new_filename>" "Drill down to <title>"
```

Insert the `click` directive at the end of the Mermaid content in the parent file (before any trailing blank lines).

### 7b: Update parent frontmatter

Add the new diagram's `id` to the parent's `children` list in the frontmatter:

```yaml
children:
  - existing-child
  - {new_diagram_id}    # ← add this
```

### 7c: Write updated parent file

Write the modified parent file back to disk, preserving all existing content.

---

## Step 8: Create or Update _index.yaml

### Read existing index

Read `.bmad_output/mermaid/<feature>/_index.yaml` if it exists.

**IMPORTANT**: Read the index JUST BEFORE writing to minimize stale data (per research.md R3).

### Create new index (if not exists)

```yaml
feature: {feature}
created: {today_date}
updated: {today_date}
diagrams:
  L0: []
  L1: []
  L2: []
```

### Add new entry

Add the new diagram entry under the appropriate layer:

```yaml
- id: {diagram_id}
  file: {filename}
  type: {type}
  title: {title}
  drills_from: {parent}    # Only for L1/L2
```

- `drills_from` is only included for L1 and L2 entries
- Update the `updated` date to today

### Write index

Write the complete `_index.yaml` back to disk.

---

## Step 9: Return Result

Return the structured output:

```yaml
status: success
file: {absolute_path_to_mmd_file}
index_updated: true
```

If any error occurred during execution:

```yaml
status: error
file: null
index_updated: false
error_message: "{description of the error}"
```

---

## Listing Diagrams (Reference)

To display the diagram tree for a feature, an agent can read `_index.yaml` and format the output as follows:

```
<feature>/
  L0: <id> (<type>) — <title>
  └── L1: <id> (<type>) — <title> [drills from <parent_id>#<node_id>]
      └── L2: <id> (<type>) — <title> [drills from <parent_id>#<node_id>]
```

Read the `diagrams` section of `_index.yaml`, iterate through L0, L1, L2 entries, and display them with indentation. Use `drills_from` to show the relationship chain.

---

## Concurrency & Stateless Operation

### Stateless Execution

- This task MUST read the current `_index.yaml` from disk at execution time — never cache
- Each invocation is fully independent — no assumptions about prior state
- The task reads all necessary state from the filesystem

### Concurrency Safety

- Each Task generates a unique `.mmd` file (different filename) — no write conflicts on diagram files
- The `_index.yaml` follows a read-then-write strategy (per research.md R3)
- In rare concurrent cases (two Tasks write the index simultaneously), last-writer-wins — the `.mmd` files still exist on disk
- A future validation command (Growth phase) can reconcile the index with the filesystem

### Parallel Execution

- This task is designed to be launched via the Task tool
- Multiple generate-diagram tasks on different diagrams can run concurrently
- The calling agent should use `subagent_type: general-purpose` when launching via Task tool

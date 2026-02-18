# Task: Update Existing Mermaid Diagram

> **Module**: mermaid-workbench
> **Contract**: specs/002-mermaid-workbench/contracts/task-generate.yaml (update section)
> **Execution**: Launch via Claude Code Task tool (subagent_type: general-purpose)

## Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `diagram_id` | string | yes | ID of the diagram to update |
| `feature` | string | yes | Feature identifier (`xxx-feature-name`) |
| `instructions` | string | yes | Natural language instructions for the modification |

---

## Step 1: Resolve File Path

1. Build feature directory: `.bmad_output/mermaid/<feature>/`
2. Search for the diagram file matching pattern `L*-<diagram_id>.mmd` in the feature directory
3. If multiple matches found, use the exact match on `diagram_id`
4. If no file found:
   ```
   ERROR: Diagram "{diagram_id}" not found in feature "{feature}".
   Searched: .bmad_output/mermaid/<feature>/L*-<diagram_id>.mmd
   ```

---

## Step 2: Read Existing File

1. Read the complete `.mmd` file
2. **Separate frontmatter from Mermaid content**:
   - Frontmatter: everything between the first `---` and second `---`
   - Mermaid content: everything after the second `---` (and blank line)
3. Parse frontmatter YAML to extract: id, title, type, layer, parent, children, feature

---

## Step 3: Load Template

Read the template for the diagram's type from `_bmad/modules/mermaid-workbench/templates/<type>.md`.

Use the template conventions to guide the modification while maintaining consistency with the original diagram style.

---

## Step 4: Apply Modifications

Using the natural language `instructions` and the loaded template:

1. **Modify the Mermaid content** according to the instructions
2. **Preserve all existing click directives** — these are drill-down links to child diagrams
3. **Preserve the diagram structure** — only add/modify/remove what the instructions specify
4. **Maintain valid Mermaid syntax** at all times

### Preservation Rules

- **NEVER remove** existing `click` directives (they link to child diagrams)
- **NEVER modify** node IDs that are referenced by child diagrams (check `children` in frontmatter)
- **NEVER change** the Mermaid directive type (e.g., don't change `flowchart TD` to `stateDiagram-v2`)
- **Preserve** subgraph structure unless explicitly asked to modify it

---

## Step 5: Preserve Frontmatter

The frontmatter MUST remain intact after update:

- `id`: unchanged
- `title`: update ONLY if the instructions explicitly change the diagram's purpose
- `type`: unchanged
- `layer`: unchanged
- `parent`: unchanged
- `children`: unchanged
- `feature`: unchanged

---

## Step 6: Write Updated File

Reassemble and write the file:

```
---
{preserved_frontmatter}
---

{modified_mermaid_content}
```

---

## Step 7: Update _index.yaml (conditional)

Only update `_index.yaml` if metadata changed (specifically the `title` field):

1. Read current `_index.yaml`
2. Find the entry matching `diagram_id` in the appropriate layer
3. Update the `title` field if it changed
4. Update the `updated` date
5. Write back to disk

If no metadata changed, skip this step.

---

## Step 8: Return Result

```yaml
status: success
file: {absolute_path_to_updated_mmd_file}
index_updated: true|false    # true only if title changed
```

If any error occurred:

```yaml
status: error
file: null
index_updated: false
error_message: "{description of the error}"
```

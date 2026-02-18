# Contract: /product.promote

**Type**: Claude Code slash command (CLI interface)
**File**: `.claude/commands/product.promote.md`

## Interface

**Command**: `/product.promote BL-xxx`

**Arguments**:
- `$ARGUMENTS` (required): Backlog ID to promote (e.g., `BL-001`)

**Preconditions**:
- `.product/` directory exists
- The specified backlog item exists in `backlogs/open/` or `backlogs/in-progress/`
- `.features/` directory exists with `config.yaml`, `index.yaml`, and `_templates/feature.tpl.yaml`

**Postconditions**:
- Backlog file moved to `.product/backlogs/promoted/`
- Backlog frontmatter updated: `status: promoted`, `promotion.promoted_date`, `promotion.feature_id`
- New feature YAML created in `.features/`
- `.features/index.yaml` updated with new feature entry
- `.product/index.yaml` updated
- Linked feedbacks updated with feature reference in `linked_to.features[]`

## Behavior

### Step 1: Validate backlog

- Find backlog file in `backlogs/open/` or `backlogs/in-progress/`
- If not found → ERROR

### Step 2: Determine feature identity

- Read `.features/index.yaml` to find the highest existing feature number
- Assign next number (e.g., if highest is 008 → new is 009)
- Derive feature name from backlog title (kebab-case, e.g., "Search performance" → `search-performance`)
- Feature ID = `{NNN}-{name}` (e.g., `009-search-performance`)

### Step 3: Create feature entry

- Copy `.features/_templates/feature.tpl.yaml` to `.features/{feature_id}.yaml`
- Replace template placeholders:
  - `{{feature_id}}` → feature ID
  - `{{title}}` → backlog title (title case)
  - `{{owner}}` → backlog owner or `default_owner` from `.features/config.yaml`
  - `{{date}}` → today's date
  - `{{timestamp}}` → current timestamp
- Set `workflow_path: "full"` (promoted features use full method)

### Step 4: Update feature index

- Add new feature to `.features/index.yaml`:
  - `id`, `title`, `status: active`, `stage: ideation`, `progress: 0.0`, `health: HEALTHY`

### Step 5: Update backlog

- Move backlog file to `backlogs/promoted/`
- Update frontmatter: `status: promoted`, `promotion.promoted_date: today`, `promotion.feature_id: {feature_id}`
- Add feature ID to `features[]` array

### Step 6: Update linked feedbacks

- For each feedback ID in the backlog's `feedbacks[]`:
  - Read the feedback file
  - Add the feature ID to `linked_to.features[]`
  - Write the updated feedback

### Step 7: Update product index

- Update `.product/index.yaml` with the status change

## Output

```markdown
## Promotion Complete

**Backlog**: BL-001 → promoted
**Feature**: 009-search-performance created

### Traceability Chain
```
FB-001 ──→ BL-001 ──→ 009-search-performance
FB-004 ──→ BL-001 ──→ 009-search-performance
```

### Next Steps

1. Run `/feature.workflow 009-search-performance` to start the feature pipeline
2. The feature begins at **ideation** stage — proceed through Brief → PRD → Spec → Tasks → Code
```

## Error cases

- `$ARGUMENTS` is empty → ERROR: "Backlog ID required. Usage: `/product.promote BL-xxx`"
- Backlog not found → ERROR: "Backlog {id} not found."
- Backlog already promoted → ERROR: "Backlog {id} is already promoted (feature: {feature_id})."
- Backlog in `done/` or `cancelled/` → ERROR: "Cannot promote a {status} backlog. Only open or in-progress backlogs can be promoted."

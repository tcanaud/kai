# Contract: /product.backlog

**Type**: Claude Code slash command (CLI interface)
**File**: `.claude/commands/product.backlog.md`

## Interface

**Command**: `/product.backlog [BL-xxx]`

**Arguments**:
- `$ARGUMENTS` (optional): Specific backlog ID (e.g., `BL-001`). If empty, lists all backlogs.

**Preconditions**:
- `.product/` directory exists

**Postconditions**:
- Read-only command — no files modified

## Behavior

### Mode 1: List all backlogs (no argument)

1. Read `.product/index.yaml` for cached backlog data (or scan filesystem if index missing)
2. Group backlogs by status directory
3. Display summary table

**Output**:

```markdown
## Product Backlog

**Total**: {count} items

### Open ({count})

| ID | Title | Priority | Feedbacks | Created |
|----|-------|----------|-----------|---------|
| BL-001 | Search performance on large repos | high | 2 | 2026-02-18 |
| BL-004 | Mobile layout broken | medium | 1 | 2026-02-20 |

### In Progress ({count})

| ID | Title | Priority | Owner | Created |
|----|-------|----------|-------|---------|
| BL-002 | Form submission crash | critical | tcanaud | 2026-02-18 |

### Promoted ({count})

| ID | Title | Feature | Promoted |
|----|-------|---------|----------|
| BL-003 | Auth flow improvement | 009-auth-flow | 2026-02-25 |

### Done ({count})
(none)

### Cancelled ({count})
(none)
```

### Mode 2: Backlog detail (BL-xxx argument)

1. Find the backlog file across all status directories
2. Read its full content (frontmatter + body)
3. For each linked feedback ID, read the feedback's title and current status
4. Display detail view

**Output**:

```markdown
## BL-001: Search performance on large repositories

**Status**: open | **Priority**: high | **Category**: optimization
**Created**: 2026-02-18 | **Owner**: tcanaud
**Tags**: search, performance

### Linked Feedbacks

| ID | Title | Status | Created |
|----|-------|--------|---------|
| FB-001 | Search takes 40 seconds on large repos | triaged | 2026-02-18 |
| FB-004 | Search unusable with 10k+ files | triaged | 2026-02-19 |

### Description

{backlog body content}
```

## Error cases

- `BL-xxx` not found in any status directory → ERROR: "Backlog item {id} not found."
- No backlogs exist → INFO: "No backlog items. Run `/product.triage` to create backlogs from feedbacks."

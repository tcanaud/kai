# Contract: /product.triage

**Type**: Claude Code slash command (CLI interface)
**File**: `.claude/commands/product.triage.md`

## Interface

**Command**: `/product.triage [--supervised]`

**Arguments**:
- `$ARGUMENTS` (optional): `--supervised` flag to enable human-in-the-loop confirmation for each action. Default: autonomous mode.

**Preconditions**:
- `.product/` directory exists
- At least one feedback exists in `.product/feedbacks/new/`

**Postconditions**:
- All feedbacks in `feedbacks/new/` are processed (moved to `triaged/` or `excluded/`)
- Zero or more backlog items created in `backlogs/open/`
- Feedback frontmatter updated with backlog links
- `.product/index.yaml` updated

## Behavior

### Step 1: Read all feedbacks

- Read all files in `.product/feedbacks/new/`
- Read all files in `.product/feedbacks/resolved/` (for regression/duplicate detection)
- Read all files in `.product/feedbacks/triaged/` (for existing context)

### Step 2: Semantic analysis

For each new feedback, perform:

a. **Clustering**: Group new feedbacks that describe the same problem/request, even with different phrasings. Use semantic understanding, not keyword matching.

b. **Resolved comparison**: Compare each new feedback against resolved feedbacks:
   - If semantically similar to a resolved feedback:
     - Find the resolution chain: resolved feedback → backlog → feature
     - Read the feature's `.features/xxx.yaml` to get `lifecycle.stage` and `lifecycle.stage_since`
     - If feedback `created` date > feature `stage_since` date (feature was released BEFORE feedback was created) → **REGRESSION**
     - If feedback `created` date <= feature `stage_since` date → **DUPLICATE-RESOLVED**

c. **Category assignment**: Propose or reassign categories for each feedback.

### Step 3: Propose actions

Present a triage plan:

```markdown
## Triage Proposal

### Group 1: Search performance (2 feedbacks)
- FB-001: "Search takes 40 seconds on large repos"
- FB-004: "Search unusable with 10k+ files"
**Action**: Create backlog BL-001 "Search performance on large repositories" (optimization, high)

### Group 2: Standalone
- FB-002: "App crashes on form submit"
**Action**: Create backlog BL-002 "Form submission crash" (critical-bug, critical)

### Excluded
- FB-003: "Would be nice to change colors"
**Action**: Move to excluded/ (reason: noise — not actionable without further context)

### Regression detected
- FB-005: Similar to resolved FB-001 (resolved by feature 009-search-perf, released 2026-03-01)
  FB-005 created: 2026-03-15 — AFTER release
**Action**: Create backlog BL-003 "Search performance regression" (critical-bug, critical, tag: regression)
```

### Step 4: Execute actions

**Autonomous mode** (default):
- Execute all proposed actions immediately
- Move feedbacks to appropriate directories
- Create backlog files
- Update all frontmatter links

**Supervised mode** (`--supervised`):
- Present each proposed action individually
- Wait for user confirmation (accept/reject/modify) before executing
- Skip rejected actions

### Step 5: Update index

- Update `.product/index.yaml` with all changes

## Output

```markdown
## Triage Complete

**Processed**: {count} feedbacks
**Created**: {count} backlog item(s)
**Excluded**: {count} feedback(s)
**Regressions**: {count} detected

| Feedback | Action | Result |
|----------|--------|--------|
| FB-001 | Grouped → BL-001 | triaged/ |
| FB-004 | Grouped → BL-001 | triaged/ |
| FB-002 | Standalone → BL-002 | triaged/ |
| FB-003 | Excluded (noise) | excluded/ |
| FB-005 | Regression → BL-003 | triaged/ |

**Next**: Review backlogs with `/product.backlog` or promote with `/product.promote BL-xxx`.
```

## Error cases

- No feedbacks in `feedbacks/new/` → INFO: "No new feedbacks to triage."
- `.product/` does not exist → ERROR: "Product directory not initialized."
- More than 30 feedbacks in `new/` → WARN: "Large batch ({count} feedbacks). Processing first 30; re-run for remainder."

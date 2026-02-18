# Contract: /feature.resolve

**Command**: `/feature.resolve {feature}`
**Type**: Claude Code slash command template (Markdown)
**Location**: `packages/feature-lifecycle/templates/commands/feature.resolve.md`
**Installed to**: `.claude/commands/feature.resolve.md`

## Purpose

Close the governance chain after a PR is merged. Transitions the feature to "release", linked backlogs to "done", and originating feedbacks to "resolved" in a single atomic operation.

## Interface

```
/feature.resolve {feature}
```

**Input**: `$ARGUMENTS` — feature ID (e.g., `010-feature-lifecycle-v2`)

**Output**: Resolution report listing all state transitions, or error message.

## Execution Flow

### Step 1: Prerequisite Checks

| Check | How | Failure message |
|-------|-----|----------------|
| Feature exists | `.features/{FEATURE}.yaml` exists | "Feature not found: {FEATURE}" |
| Not already released | `lifecycle.stage != "release"` | "Feature already released: {FEATURE}" |
| `gh` installed | `command -v gh > /dev/null 2>&1` | "GitHub CLI required for merge detection" |
| `gh` authenticated | `gh auth status > /dev/null 2>&1` | "GitHub CLI not authenticated" |
| PR is merged | `gh pr list --head "{BRANCH}" --state merged --json number --jq 'length'` > 0 | "PR for branch `{BRANCH}` is not yet merged. Merge the PR on GitHub first." |

**Branch resolution**: The branch name is the feature ID (e.g., `010-feature-lifecycle-v2`). If the current git branch matches, use it. Otherwise, use the feature ID as the branch name.

### Step 2: Collect Linked Artifacts

**Linked backlogs**: Scan `.product/backlogs/*/BL-*.md` for files where `features` array contains `{FEATURE}`. Collect file paths and current status.

**Originating feedbacks**: Scan `.product/feedbacks/*/FB-*.md` for files where `linked_to.features` array contains `{FEATURE}`. Collect file paths and current status.

**If `.product/` does not exist**: Skip backlog and feedback transitions. Only transition the feature stage.

### Step 3: Validate All Transitions (Pre-flight)

Before any file is modified, validate ALL transitions will succeed:

| Validation | Check |
|-----------|-------|
| Feature YAML writable | File exists and is not read-only |
| Backlog destination exists | `.product/backlogs/done/` directory exists (create if missing) |
| Feedback destination exists | `.product/feedbacks/resolved/` directory exists (create if missing) |
| Each backlog file accessible | File exists and is readable |
| Each feedback file accessible | File exists and is readable |
| No destination conflicts | No file with same name exists in target directory |

**If any validation fails**: Stop immediately. Report all validation errors. No files are modified.

### Step 4: Apply Transitions (Atomic)

Apply in this order (feature YAML last as commit record):

**4a. Transition backlogs** (for each linked backlog):
1. Read current file content
2. Update frontmatter: `status: "done"`, `updated: "{today}"`
3. Write updated content to `.product/backlogs/done/{BL-xxx}.md`
4. Remove original file from source directory

**4b. Transition feedbacks** (for each linked feedback):
1. Read current file content
2. Update frontmatter:
   - `status: "resolved"`
   - `updated: "{today}"`
   - `resolution.resolved_date: "{today}"`
   - `resolution.resolved_by_feature: "{FEATURE}"`
3. Write updated content to `.product/feedbacks/resolved/{FB-xxx}.md`
4. Remove original file from source directory

**4c. Update product index**:
1. Re-scan `.product/` directories to recompute counts
2. Rewrite `.product/index.yaml`

**4d. Transition feature** (LAST):
1. Read current `.features/{FEATURE}.yaml`
2. Update:
   - `lifecycle.stage: "release"`
   - `lifecycle.stage_since: "{today}"`
   - `lifecycle.progress: 1.0`
   - `lifecycle.manual_override: "release"`
   - `updated: "{today}"`
3. Write updated feature YAML

**If any step fails after mutations have started**: Attempt best-effort rollback of completed steps. Report which transitions succeeded and which failed.

### Step 5: Update Feature Index

Update `.features/index.yaml`:
- Set the feature's `stage` to `"release"` and `progress` to `1.0`

### Step 6: Report

On success:
```markdown
## Lifecycle Resolution Complete: {FEATURE}

**Feature**: {feature_id} — {title}
**Stage**: release
**Date**: {today}

### Transitions Applied

| Type | ID | From | To |
|------|----|------|----|
| Feature | {feature_id} | test | release |
| Backlog | BL-001 | open | done |
| Backlog | BL-002 | in-progress | done |
| Feedback | FB-003 | triaged | resolved |
| Feedback | FB-005 | triaged | resolved |
| Feedback | FB-008 | new | resolved |

**Total**: 1 feature + {N} backlogs + {M} feedbacks

### Governance Chain Closed

Specification → Agreement → QA → PR → Release ✓

### Next Steps

- Verify on GitHub: PR is merged
- Run `/feature.list` to see updated dashboard
- Run `/product.dashboard` to see updated product metrics
```

On validation failure:
```markdown
## Resolution Blocked: {FEATURE}

The following issues prevent lifecycle resolution:

{list of validation errors}
```

On partial failure (mid-transition):
```markdown
## Resolution Partially Failed: {FEATURE}

Some transitions succeeded before the failure:

### Completed
{list of completed transitions}

### Failed
{error description}

### Recovery
{instructions for manual recovery}
```

## Idempotency

Running `/feature.resolve` on a feature that is already in "release" stage returns a message: "Feature already released: {FEATURE}" without error.

Running `/feature.resolve` when some backlogs are already "done" or feedbacks already "resolved": those transitions are skipped gracefully. Only pending transitions are applied.

## Error Handling

| Condition | Behavior |
|-----------|----------|
| PR not merged | Clear message: "PR not yet merged" |
| Feature already released | Informational: "Already released" |
| `.product/` not installed | Only transition feature stage; skip backlogs/feedbacks |
| Backlog file locked/missing | Validation failure: list specific file |
| Partial failure | Report completed + failed transitions with recovery steps |

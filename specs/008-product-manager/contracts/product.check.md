# Contract: /product.check

**Type**: Claude Code slash command (CLI interface)
**File**: `.claude/commands/product.check.md`

## Interface

**Command**: `/product.check`

**Arguments**: None

**Preconditions**:
- `.product/` directory exists

**Postconditions**:
- Read-only command — no files modified (except `index.yaml` rebuild if desync detected)
- Findings report displayed to user

## Behavior

### Check 1: Status/directory desync

For each feedback file in all `feedbacks/` subdirectories:
- Read the `status` field from frontmatter
- Compare against the directory name the file resides in
- If mismatch → finding: `STATUS_DESYNC` (severity: WARNING)

For each backlog file in all `backlogs/` subdirectories:
- Same check as above

### Check 2: Stale feedbacks

For each feedback in `feedbacks/new/`:
- Read `created` date
- If `today - created > 14 days` → finding: `STALE_FEEDBACK` (severity: WARNING)

### Check 3: Orphaned backlogs

For each backlog in any status directory:
- Read `feedbacks[]` array
- For each listed feedback ID, verify the file exists in any `feedbacks/` subdirectory
- If ALL listed feedbacks are missing → finding: `ORPHANED_BACKLOG` (severity: WARNING)
- If SOME listed feedbacks are missing → finding: `PARTIAL_ORPHAN` (severity: INFO)

### Check 4: Broken traceability chains

For each feedback with non-empty `linked_to.backlog[]`:
- Verify each referenced backlog ID exists in any `backlogs/` subdirectory
- If not found → finding: `BROKEN_CHAIN_FB_TO_BL` (severity: ERROR)

For each backlog with non-empty `features[]`:
- Verify each referenced feature ID exists as `.features/{feature_id}.yaml`
- If not found → finding: `BROKEN_CHAIN_BL_TO_FEAT` (severity: ERROR)

### Check 5: Index consistency

- Compare `index.yaml` counts and items against actual filesystem state
- If mismatch → finding: `INDEX_DESYNC` (severity: WARNING)
- Auto-rebuild index if desync detected

### Check 6: ID uniqueness

- Scan all feedback files for duplicate `id` fields
- Scan all backlog files for duplicate `id` fields
- If duplicates found → finding: `DUPLICATE_ID` (severity: ERROR)

## Output

```markdown
## Product Health Check

**Date**: 2026-02-18
**Scanned**: {feedback_count} feedbacks, {backlog_count} backlogs

### Summary

| Severity | Count |
|----------|-------|
| ERROR | {count} |
| WARNING | {count} |
| INFO | {count} |

### Findings

#### FINDING-001 [WARNING] STATUS_DESYNC
- **File**: `.product/feedbacks/triaged/FB-003.md`
- **Expected status**: triaged (from directory)
- **Actual status**: new (from frontmatter)
- **Fix**: Update frontmatter `status` to "triaged"

#### FINDING-002 [WARNING] STALE_FEEDBACK
- **File**: `.product/feedbacks/new/FB-007.md`
- **Created**: 2026-02-01 (17 days ago)
- **Fix**: Run `/product.triage` to process stale feedbacks

#### FINDING-003 [ERROR] BROKEN_CHAIN_FB_TO_BL
- **File**: `.product/feedbacks/triaged/FB-004.md`
- **References**: BL-099 (does not exist)
- **Fix**: Remove broken reference or create the missing backlog

### Verdict

**PASS** — No errors found. {warning_count} warning(s) to review.
or
**FAIL** — {error_count} error(s) require action.
```

## Error cases

- `.product/` does not exist → ERROR: "Product directory not initialized."
- Empty `.product/` (no feedbacks, no backlogs) → INFO: "Product directory is empty. No checks to perform."

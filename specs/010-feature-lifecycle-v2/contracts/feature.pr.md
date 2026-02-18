# Contract: /feature.pr

**Command**: `/feature.pr {feature}`
**Type**: Claude Code slash command template (Markdown)
**Location**: `packages/feature-lifecycle/templates/commands/feature.pr.md`
**Installed to**: `.claude/commands/feature.pr.md`

## Purpose

Create a GitHub pull request with a body containing the complete governance lineage for a feature. Enforces mechanical prerequisites before proceeding.

## Interface

```
/feature.pr {feature}
```

**Input**: `$ARGUMENTS` — feature ID (e.g., `010-feature-lifecycle-v2`)

**Output**: PR URL on success, or error message listing unmet prerequisites.

## Execution Flow

### Step 1: Prerequisite Checks

All checks must pass before PR creation proceeds. If any fail, the command stops and lists all failures.

| Check | How | Failure message |
|-------|-----|----------------|
| `gh` installed | `command -v gh > /dev/null 2>&1` | "GitHub CLI (`gh`) is not installed. Install: https://cli.github.com" |
| `gh` authenticated | `gh auth status > /dev/null 2>&1` | "GitHub CLI is not authenticated. Run: `gh auth login`" |
| Feature exists | `.features/{FEATURE}.yaml` exists | "Feature not found: {FEATURE}" |
| Tasks 100% | `tasks_done == tasks_total AND tasks_total > 0` | "Implementation incomplete: {done}/{total} tasks done" |
| QA PASS | `.qa/{FEATURE}/verdict.yaml` has `verdict: "PASS"` | "QA not passed. Run `/qa.run {FEATURE}` first" |
| QA fresh | `spec_sha256` matches current spec.md | "QA verdict is stale. Re-run `/qa.plan` then `/qa.run`" |
| Agreement Check PASS | `.agreements/{FEATURE}/check-report.md` verdict is PASS, OR no check-report.md exists and agreement.yaml exists | "Agreement check failed. Run `/agreement.doctor {FEATURE}` to generate fix tasks" |
| No duplicate PR | `gh pr list --head "{BRANCH}" --state open` returns empty | "PR already exists: {existing_url}" |

**Agreement check logic**:
- If `check-report.md` exists → read verdict (PASS/FAIL)
- If `check-report.md` does not exist AND `agreement.yaml` exists → treat as PASS (check hasn't been run yet but agreement exists)
- If `agreement.yaml` does not exist → treat as PASS for backward compatibility

### Step 2: Gather Traceability Data

| Data | Source | Fallback |
|------|--------|----------|
| Specification | `specs/{FEATURE}/spec.md` | Required (always exists at this point) |
| Agreement | `.agreements/{FEATURE}/agreement.yaml` | "N/A" if missing |
| QA Results | `.qa/{FEATURE}/verdict.yaml` → `passed`, `total`, `verdict` | Required (checked in Step 1) |
| Agreement Check | `.agreements/{FEATURE}/check-report.md` → verdict | "PASS (no report)" if missing |
| Originating Feedbacks | Scan `.product/feedbacks/*/FB-*.md` where `linked_to.features` contains `{FEATURE}` | "N/A" if none found or `.product/` missing |
| Linked Backlogs | Scan `.product/backlogs/*/BL-*.md` where `features` contains `{FEATURE}` | "N/A" if none found or `.product/` missing |
| Diff Summary | `git diff --stat main...HEAD` | "N/A" if git fails |

### Step 3: Assemble PR Body

```markdown
## {feature_id}: {title}

### Governance Lineage

| Artifact | Status | Link |
|----------|--------|------|
| Specification | Present | `specs/{feature_id}/spec.md` |
| Agreement | {Present/N/A} | `.agreements/{feature_id}/agreement.yaml` |
| QA Results | **{PASS}** — {passed}/{total} checks | `.qa/{feature_id}/verdict.yaml` |
| Agreement Check | **{PASS}** | `.agreements/{feature_id}/check-report.md` |

### Originating Feedbacks

| ID | Title | Status |
|----|-------|--------|
| FB-001 | {title} | {status} |
| ... | ... | ... |

_or "N/A — no feedbacks linked to this feature"_

### Linked Backlogs

| ID | Title | Status |
|----|-------|--------|
| BL-001 | {title} | {status} |
| ... | ... | ... |

_or "N/A — no backlogs linked to this feature"_

### Diff Summary

```
{git diff --stat output}
```
```

### Step 4: Create PR

```bash
gh pr create \
  --title "feat({feature_id}): {title}" \
  --base main \
  --body-file - <<'EOF'
{assembled PR body}
EOF
```

**Title format**: `feat({feature_id}): {title}` (e.g., `feat(010-feature-lifecycle-v2): Feature Lifecycle V2`)

### Step 5: Report

On success:
```markdown
## PR Created

**URL**: {pr_url}
**Title**: feat({feature_id}): {title}
**Base**: main ← {branch}

### Next Steps

- Review the PR on GitHub
- After merge, run `/feature.resolve {FEATURE}` to close the governance chain
```

On failure (any prerequisite not met):
```markdown
## PR Creation Blocked

The following prerequisites are not met:

{list of failing checks with remediation instructions}
```

## Error Handling

| Condition | Behavior |
|-----------|----------|
| `gh` not installed | Clear error: "Install GitHub CLI: https://cli.github.com" |
| `gh` not authenticated | Clear error: "Run: `gh auth login`" |
| `gh pr create` fails | Display stderr from `gh` command |
| Network error | Display `gh` error message |
| PR already exists | Display existing PR URL, do not create duplicate |
| Missing optional artifacts | "N/A" in PR body (FR-013) |

## Non-Goals

- Does not push the branch (assumes branch is already pushed)
- Does not set reviewers, labels, or milestones (developer sets these on GitHub)
- Does not auto-merge
- Does not update feature stage (that happens via `/feature.resolve` after merge)

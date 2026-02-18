# Data Model: Feature Lifecycle V2

**Feature**: 010-feature-lifecycle-v2
**Date**: 2026-02-18

## Entities

### 1. QA Verdict (NEW)

**Location**: `.qa/{feature_id}/verdict.yaml`
**Owner**: feature-lifecycle-v2 workflow layer (not the QA system)
**Purpose**: Persist QA run results for workflow gate evaluation

```yaml
# .qa/{feature_id}/verdict.yaml
feature_id: "010-feature-lifecycle-v2"
verdict: "PASS"                        # PASS | FAIL
run_at: "2026-02-18T21:00:00Z"        # ISO 8601
passed: 10                             # scripts that exited 0
failed: 0                              # scripts that exited non-zero
total: 10                              # total scripts executed
spec_sha256: "a1b2c3d4..."            # SHA-256 of spec.md at run time (freshness)
agreement_sha256: "f6e5d4c3..."       # SHA-256 of agreement.yaml at run time (or null)
failures: []                           # populated on FAIL
```

**Failure entry schema** (when `verdict: "FAIL"`):
```yaml
failures:
  - script: "test-freshness-detection.sh"
    criterion_ref: "US2.AC4"
    assertion: "SHA checksum recalculated when agreement.yaml changes"
    expected: "Stale detection triggers"
    actual: "Checksum comparison returned 'current' despite file change"
```

**Validation rules**:
- `verdict` must be `"PASS"` or `"FAIL"`
- `total` must equal `passed + failed`
- `spec_sha256` must be a 64-character hex string
- If `verdict == "FAIL"`, `failures` must be non-empty
- If `verdict == "PASS"`, `failures` must be empty

**Freshness detection**:
- Compute current SHA-256 of `specs/{feature_id}/spec.md`
- If current SHA-256 != `spec_sha256` in verdict.yaml → verdict is **stale**
- Stale verdicts are treated as `pending` (QA re-run required)

---

### 2. Feature YAML (EXTENDED)

**Location**: `.features/{feature_id}.yaml`
**Changes**: No schema changes needed. The existing `lifecycle.stage`, `lifecycle.manual_override`, and `artifacts.agreement.check` fields are sufficient. The `release` stage transition is triggered by post-merge resolution setting `manual_override: "release"`.

**New artifact scanning (consumed by `/feature.status`)**:
The existing scanners compute `artifacts.speckit.tasks_done` and `artifacts.speckit.tasks_total`. V2 adds QA verdict awareness, but this is read by the workflow command (slash template), not by the Node.js scanners. No feature YAML schema change required.

---

### 3. Workflow Dependency Chain (EXTENDED)

**Not a file entity** — computed at runtime by `/feature.workflow`. Extended from existing 11 steps (Full Method) to 15 steps.

**New steps appended after existing step 11**:

| Step | Name | Gate | Artifact Key | Command |
|------|------|------|-------------|---------|
| 12 | QA Plan | Gate C (tasks 100%) | `qa.plan_exists` | `/qa.plan {FEATURE}` |
| 13 | QA Run | qa.plan_exists | `qa.verdict` | `/qa.run {FEATURE}` |
| 14 | Agreement Check | tasks >= 50% | `agreement.check` | `/agreement.check {FEATURE}` |
| — | **Gate D** | qa.verdict == PASS AND agreement.check == PASS | — | — |
| 15 | PR Creation | Gate D | `pr.url` | `/feature.pr {FEATURE}` |
| 16 | Post-Merge | pr.merged | `lifecycle == release` | `/feature.resolve {FEATURE}` |

**New artifact detection keys**:

| Key | Source | Detection |
|-----|--------|-----------|
| `qa.plan_exists` | `.qa/{FEATURE}/_index.yaml` | File exists |
| `qa.verdict` | `.qa/{FEATURE}/verdict.yaml` | Read `verdict` field; check freshness via `spec_sha256` |
| `qa.verdict_fresh` | Computed | `spec_sha256` in verdict.yaml matches current SHA-256 of spec.md |
| `agreement.check` | `.agreements/{FEATURE}/check-report.md` | Read verdict line; "PASS" or "FAIL" |
| `pr.url` | `gh pr list --head {BRANCH} --state open` | JSON `url` field |
| `pr.merged` | `gh pr list --head {BRANCH} --state merged` | JSON array length > 0 |

---

### 4. PR Body Template (NEW)

**Not a persistent entity** — assembled at PR creation time and passed to `gh pr create`.

**Structure**:
```markdown
## Feature: {feature_id} — {title}

### Governance Lineage

| Artifact | Link |
|----------|------|
| Specification | `specs/{feature_id}/spec.md` |
| Agreement | `.agreements/{feature_id}/agreement.yaml` |
| QA Results | {passed}/{total} checks passed ({verdict}) |
| Agreement Check | {check_verdict} |

### Originating Feedbacks

{table of feedbacks from .product/feedbacks/ linked to this feature, or "N/A"}

### Linked Backlogs

{table of backlogs from .product/backlogs/ linked to this feature, or "N/A"}

### Diff Summary

{git diff --stat main...HEAD summary}
```

**Assembly rules**:
- Specification and agreement links are relative paths from repo root
- QA results summary is extracted from `.qa/{feature_id}/verdict.yaml`
- Agreement check verdict from `.agreements/{feature_id}/check-report.md` (or "PASS" if no report and agreement exists)
- Feedbacks: scan `.product/feedbacks/*/FB-*.md` where `linked_to.features` contains `{feature_id}`
- Backlogs: scan `.product/backlogs/*/BL-*.md` where `features` contains `{feature_id}`
- Missing optional artifacts (feedbacks, backlogs) produce "N/A", not errors (FR-013)
- Diff summary: `git diff --stat main...HEAD`

---

### 5. QA FAIL Backlog (NEW, auto-generated)

**Location**: `.product/backlogs/open/BL-{next_id}.md`
**Owner**: Created automatically by `/feature.workflow` when QA verdict is FAIL
**Schema**: Uses existing backlog template with specific field values.

```yaml
---
id: "BL-{next_id}"
title: "QA FAIL: {feature_id} — {count} failing checks"
status: "open"
category: "critical-bug"
priority: "critical"
created: "{today}"
updated: "{today}"
owner: "{default_owner}"
feedbacks: []
features: ["{feature_id}"]
tags: ["qa-fail", "auto-generated"]
promotion:
  promoted_date: ""
  feature_id: ""
cancellation:
  cancelled_date: ""
  reason: ""
---

## QA FAIL Report

**Feature**: {feature_id}
**QA Run**: {run_at}
**Result**: {passed}/{total} passed, {failed} failed

### Failing Checks

{for each failure in verdict.yaml:}
#### {criterion_ref}: {assertion}

- **Script**: `.qa/{feature_id}/scripts/{script}`
- **Expected**: {expected}
- **Actual**: {actual}

### Resolution Path

1. Fix the failing checks in the implementation
2. Re-run `/qa.run {feature_id}`
3. Verify verdict changes to PASS
4. Continue with `/feature.workflow {feature_id}`
```

**Validation**: Same as existing backlog schema. The `features` field links back to the source feature (reverse traceability). The `feedbacks` array is empty (this backlog originates from QA, not from user feedback).

---

## Entity Relationships

```
.features/{id}.yaml ─────────────────── specs/{id}/spec.md
         │                                      │
         │ lifecycle.stage                      │ acceptance criteria
         │                                      ↓
         │                              .qa/{id}/_index.yaml (QA plan)
         │                                      │
         │                                      ↓
         │                              .qa/{id}/verdict.yaml (QA verdict)
         │                                      │
         │                              ┌───────┴───────┐
         │                              │ PASS          │ FAIL
         │                              ↓               ↓
         │                     Gate D satisfied    .product/backlogs/open/BL-xxx.md
         │                              │               │ (auto-generated)
         │                              ↓               │
         │                     /feature.pr              ↓
         │                       (GitHub PR)       Fix cycle → re-run QA
         │                              │
         │                              ↓
         │                     PR merged on GitHub
         │                              │
         │                              ↓
         │                     /feature.resolve
         │                              │
         ↓                              ↓
  stage: "release"    .product/backlogs/done/ + .product/feedbacks/resolved/
```

## State Transitions

### Feature Stage Transition (Release)

```
"test" ──(/feature.resolve)──→ "release"
```

**Trigger**: Post-merge resolution after PR merge confirmed
**Mechanism**: Set `lifecycle.manual_override: "release"` and `lifecycle.stage: "release"`
**Reversibility**: Not reversible through normal workflow (manual edit only)

### Backlog Status Transition (Done)

```
"open" or "in-progress" ──(/feature.resolve)──→ "done"
```

**Trigger**: Post-merge resolution
**Mechanism**: Move file from current status dir to `backlogs/done/`, update frontmatter `status: "done"`

### Feedback Status Transition (Resolved)

```
"new" or "triaged" ──(/feature.resolve)──→ "resolved"
```

**Trigger**: Post-merge resolution
**Mechanism**: Move file to `feedbacks/resolved/`, update frontmatter `status: "resolved"`, populate `resolution` block

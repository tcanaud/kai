# Contract: /product.dashboard

**Type**: Claude Code slash command (CLI interface)
**File**: `.claude/commands/product.dashboard.md`

## Interface

**Command**: `/product.dashboard [--json]`

**Arguments**:
- `$ARGUMENTS` (optional): `--json` flag to output structured JSON instead of Markdown.

**Preconditions**:
- `.product/` directory exists

**Postconditions**:
- Read-only command — no files modified
- Dashboard report displayed to user

## Behavior

### Step 1: Gather data

- Read `.product/index.yaml` for cached data
- If index missing or stale, scan filesystem directly:
  - Count files in each `feedbacks/` subdirectory
  - Count files in each `backlogs/` subdirectory
  - Read each feedback's `category` field for distribution
  - Read each backlog's `priority` field

### Step 2: Compute metrics

- **Feedback-to-backlog rate**: count of feedbacks with non-empty `linked_to.backlog[]` / total non-excluded feedbacks
- **Backlog-to-feature rate**: count of promoted backlogs / total backlogs
- **Resolution rate**: count of resolved feedbacks / total feedbacks

### Step 3: Identify warnings

- Any feedbacks in `new/` older than 14 days → stale warning
- Any backlogs with `priority: critical` → critical bug alert
- Any findings from last `/product.check` run (if check-report exists)

## Output (Markdown, default)

```markdown
## Product Dashboard

**Last updated**: 2026-02-18

### Feedbacks

| Status | Count |
|--------|-------|
| New | 3 |
| Triaged | 12 |
| Excluded | 4 |
| Resolved | 8 |
| **Total** | **27** |

### Backlogs

| Status | Count |
|--------|-------|
| Open | 5 |
| In Progress | 2 |
| Done | 1 |
| Promoted | 3 |
| Cancelled | 0 |
| **Total** | **11** |

### Categories

| Category | Count | % |
|----------|-------|---|
| critical-bug | 2 | 7% |
| bug | 8 | 30% |
| optimization | 9 | 33% |
| evolution | 5 | 19% |
| new-feature | 3 | 11% |

### Conversion Metrics

| Metric | Value |
|--------|-------|
| Feedback → Backlog | 42% |
| Backlog → Feature | 27% |
| Resolution rate | 30% |

### Warnings

- {warning_icon} **3 stale feedbacks** in `new/` (oldest: 18 days) — run `/product.triage`
- {warning_icon} **1 critical bug** in backlogs — BL-007 "Data loss on concurrent save"
```

## Output (JSON, --json flag)

```json
{
  "updated": "2026-02-18T12:00:00Z",
  "feedbacks": {
    "total": 27,
    "new": 3,
    "triaged": 12,
    "excluded": 4,
    "resolved": 8
  },
  "backlogs": {
    "total": 11,
    "open": 5,
    "in_progress": 2,
    "done": 1,
    "promoted": 3,
    "cancelled": 0
  },
  "categories": {
    "critical-bug": 2,
    "bug": 8,
    "optimization": 9,
    "evolution": 5,
    "new-feature": 3
  },
  "metrics": {
    "feedback_to_backlog_rate": 0.42,
    "backlog_to_feature_rate": 0.27,
    "resolution_rate": 0.30
  },
  "warnings": [
    { "type": "stale_feedbacks", "count": 3, "oldest_days": 18 },
    { "type": "critical_bug", "id": "BL-007", "title": "Data loss on concurrent save" }
  ]
}
```

## Error cases

- `.product/` does not exist → ERROR: "Product directory not initialized."
- Empty `.product/` → display dashboard with all zeros and a note: "No feedbacks or backlogs yet. Start with `/product.intake`."

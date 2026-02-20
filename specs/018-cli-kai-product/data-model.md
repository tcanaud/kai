# Data Model: @tcanaud/kai-product

**Phase**: 1 | **Feature**: 018-cli-kai-product | **Date**: 2026-02-20

## Entities

### Feedback

A product feedback item submitted by a user or operator. Stored as a Markdown file with YAML frontmatter.

**File location**: `.product/feedbacks/{status}/FB-{NNN}.md`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `id` | string | yes | Pattern: `FB-\d+` |
| `title` | string | yes | Non-empty |
| `status` | enum | yes | `new \| triaged \| excluded \| resolved` |
| `category` | enum | yes | `critical-bug \| bug \| optimization \| evolution \| new-feature` |
| `priority` | enum\|null | no | `low \| medium \| high \| null` |
| `source` | string | no | Free text |
| `reporter` | string | no | Free text |
| `created` | date | yes | `YYYY-MM-DD` |
| `updated` | date | yes | `YYYY-MM-DD` |
| `tags` | string[] | no | Default: `[]` |
| `exclusion_reason` | string | no | Default: `""` |
| `linked_to.backlog` | string[] | no | Each item: `BL-\d+` |
| `linked_to.features` | string[] | no | Each item: `\d+-[\w-]+` |
| `linked_to.feedbacks` | string[] | no | Each item: `FB-\d+` |
| `resolution.resolved_date` | string | no | `YYYY-MM-DD \| ""` |
| `resolution.resolved_by_feature` | string | no | Feature ID or `""` |
| `resolution.resolved_by_backlog` | string | no | Backlog ID or `""` |

**State transitions**:
```
new → triaged (triage command)
new → excluded (triage command)
triaged → resolved (manual / future command)
```

**Invariant**: The file MUST reside in the directory matching its `status` field. Violation is detected by `check` (status/directory desync).

---

### Backlog

A prioritized work item derived from one or more feedbacks. Stored as a Markdown file with YAML frontmatter.

**File location**: `.product/backlogs/{status}/BL-{NNN}.md`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `id` | string | yes | Pattern: `BL-\d+` |
| `title` | string | yes | Non-empty |
| `status` | enum | yes | `open \| in-progress \| done \| promoted \| cancelled` |
| `category` | enum | yes | `critical-bug \| bug \| optimization \| evolution \| new-feature` |
| `priority` | enum | yes | `low \| medium \| high` |
| `created` | date | yes | `YYYY-MM-DD` |
| `updated` | date | yes | `YYYY-MM-DD` |
| `owner` | string | no | Free text |
| `feedbacks` | string[] | no | Each item: `FB-\d+` |
| `features` | string[] | no | Each item: `\d+-[\w-]+` |
| `tags` | string[] | no | Default: `[]` |
| `promotion.promoted_date` | string | no | `YYYY-MM-DD \| ""` |
| `promotion.feature_id` | string | no | Feature ID or `""` |
| `cancellation.cancelled_date` | string | no | `YYYY-MM-DD \| ""` |
| `cancellation.reason` | string | no | Free text or `""` |

**State transitions**:
```
open → in-progress  (move command)
open → done         (move command)
open → promoted     (promote command)
open → cancelled    (move command)
in-progress → done  (move command)
in-progress → promoted (promote command)
in-progress → cancelled (move command)
done → open         (move command — reopening)
```

**Invariant**: File MUST reside in the directory matching its `status` field. Violation is detected by `check`.

---

### Feature

A kai feature registered in `.features/`, created during promotion. The `promote` command creates this file.

**File location**: `.features/{NNN}-{slug}.yaml`

| Field | Type | Notes |
|-------|------|-------|
| `feature_version` | string | Always `"1.0"` |
| `feature_id` | string | `"{NNN}-{slug}"` |
| `title` | string | Derived from backlog title |
| `status` | string | Always `"active"` on creation |
| `owner` | string | From backlog `owner` field |
| `created` | date | Today's date |
| `updated` | date | Today's date |
| `depends_on` | string[] | Default: `[]` |
| `tags` | string[] | From backlog `tags` |
| `lifecycle.stage` | string | Always `"ideation"` on creation |
| `lifecycle.progress` | float | Always `0.0` on creation |

**Feature number assignment**:
1. Scan `.features/` for files matching `\d+-*.yaml`
2. Scan `specs/` for directories matching `\d+-*`
3. Extract numeric prefix from each
4. `next_number = max(all_found) + 1`, zero-padded to 3 digits

---

### Index

A computed summary file regenerated after every mutation command.

**File location**: `.product/index.yaml`

```yaml
product_version: "1.0"
updated: "{ISO8601_TIMESTAMP}"
feedbacks:
  total: {int}
  by_status:
    new: {int}
    triaged: {int}
    excluded: {int}
    resolved: {int}
  by_category:
    critical-bug: {int}
    bug: {int}
    optimization: {int}
    evolution: {int}
    new-feature: {int}
  items:
    - id: "{FB-NNN}"
      title: "{string}"
      status: "{enum}"
      category: "{enum}"
      priority: "{enum|null}"
      created: "{YYYY-MM-DD}"
backlogs:
  total: {int}
  by_status:
    open: {int}
    in-progress: {int}
    done: {int}
    promoted: {int}
    cancelled: {int}
  items:
    - id: "{BL-NNN}"
      title: "{string}"
      status: "{enum}"
      category: "{enum}"
      priority: "{enum}"
      created: "{YYYY-MM-DD}"
metrics:
  feedback_to_backlog_rate: {float}
  backlog_to_feature_rate: {float}
```

**Generation algorithm** (`reindex`):
1. Walk `.product/feedbacks/{status}/` for each valid status
2. Walk `.product/backlogs/{status}/` for each valid status
3. Parse frontmatter of each file
4. Aggregate counts by status and category
5. Sort items by ID numerically
6. Compute metrics: `feedback_to_backlog_rate = triaged_count / total_feedbacks` (0 if total = 0), `backlog_to_feature_rate = promoted_count / total_backlogs` (0 if total = 0)
7. Write `index.yaml` atomically (write to temp file, rename)

---

## Internal Data Structures (JavaScript)

```js
// Feedback object (parsed from frontmatter)
{
  id: "FB-102",
  title: "...",
  status: "triaged",        // enum
  category: "new-feature",  // enum
  priority: "high",         // enum | null
  created: "2026-02-20",
  updated: "2026-02-20",
  tags: [],
  exclusion_reason: "",
  linked_to: {
    backlog: ["BL-007"],
    features: ["018-..."],
    feedbacks: []
  },
  resolution: {
    resolved_date: "",
    resolved_by_feature: "",
    resolved_by_backlog: ""
  },
  _filePath: "/abs/path/to/file.md",  // runtime only, not serialized
  _body: "markdown body text"          // runtime only, not serialized
}

// Backlog object (parsed from frontmatter)
{
  id: "BL-007",
  title: "...",
  status: "open",
  category: "new-feature",
  priority: "high",
  created: "2026-02-20",
  updated: "2026-02-20",
  owner: "Thibaud Canaud",
  feedbacks: ["FB-102"],
  features: [],
  tags: [],
  promotion: { promoted_date: "", feature_id: "" },
  cancellation: { cancelled_date: "", reason: "" },
  _filePath: "/abs/path/to/file.md",
  _body: "markdown body text"
}

// Triage plan (JSON handed off between slash command and CLI)
{
  version: "1.0",
  generated_at: "2026-02-20T10:00:00Z",
  feedbacks: [
    { id: "FB-NNN", title: "...", created: "YYYY-MM-DD" }
  ],
  plan: [
    {
      action: "create_backlog",       // or "link_existing" | "exclude"
      backlog_title: "...",           // for create_backlog
      backlog_id: "BL-NNN",          // for link_existing
      feedback_ids: ["FB-NNN"],
      priority: "high",
      category: "new-feature",
      regression: false,
      notes: "..."
    }
  ]
}
```

---

## Validation Rules Summary

| Rule | Source |
|------|--------|
| Backlog status must be one of: `open`, `in-progress`, `done`, `promoted`, `cancelled` | FR-002, FR-007 |
| Feedback status must be one of: `new`, `triaged`, `excluded`, `resolved` | FR-006, FR-007 |
| Bulk move: all IDs must exist before any file is moved | FR-009 |
| Promote: backlog must not already have status `promoted` | US2.S2 |
| Move: if target status == current status, report "already in target status", no change | US2.S4 |
| Malformed YAML frontmatter: report error with file path, skip file, continue | Edge Cases |
| Missing `.product/` directory: clear error with setup instructions | Edge Cases |
| Concurrent move collision: second command fails gracefully (file not found at source) | Edge Cases |

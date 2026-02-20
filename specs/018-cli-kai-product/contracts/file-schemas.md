# File Schemas Contract: @tcanaud/kai-product

**Feature**: 018-cli-kai-product | **Date**: 2026-02-20

This document defines the exact file formats that `@tcanaud/kai-product` reads and writes. All schemas are validated by the internal `yaml-parser.js` module.

---

## Feedback File Schema

**Path pattern**: `.product/feedbacks/{status}/FB-{NNN}.md`

**Valid status directories**: `new/`, `triaged/`, `excluded/`, `resolved/`

**Canonical template**:
```markdown
---
id: "FB-{NNN}"
title: "{string}"
status: "{new|triaged|excluded|resolved}"
category: "{critical-bug|bug|optimization|evolution|new-feature}"
priority: "{low|medium|high}"
source: "{string}"
reporter: "{string}"
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
tags: []
exclusion_reason: ""
linked_to:
  backlog:
    - "BL-{NNN}"
  features:
    - "{NNN}-{slug}"
  feedbacks: []
resolution:
  resolved_date: ""
  resolved_by_feature: ""
  resolved_by_backlog: ""
---

{Markdown body — free text}
```

**Parsing rules**:
- Frontmatter delimited by `---` on its own line
- `priority` may be `null` (serialized as empty string or omitted)
- `tags`, `linked_to.backlog`, `linked_to.features`, `linked_to.feedbacks` are YAML block lists (may be empty `[]`)
- Unknown fields are preserved on write (round-trip safe)

**Fields mutated by commands**:

| Command | Fields Modified |
|---------|----------------|
| `triage --apply` | `status`, `updated`, `linked_to.backlog[]` (add), `linked_to.features[]` (add), `exclusion_reason` |
| `promote` | `linked_to.features[]` (add), `updated` |

---

## Backlog File Schema

**Path pattern**: `.product/backlogs/{status}/BL-{NNN}.md`

**Valid status directories**: `open/`, `in-progress/`, `done/`, `promoted/`, `cancelled/`

**Canonical template**:
```markdown
---
id: "BL-{NNN}"
title: "{string}"
status: "{open|in-progress|done|promoted|cancelled}"
category: "{critical-bug|bug|optimization|evolution|new-feature}"
priority: "{low|medium|high}"
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
owner: "{string}"
feedbacks:
  - "FB-{NNN}"
features:
  - "{NNN}-{slug}"
tags: []
promotion:
  promoted_date: ""
  feature_id: ""
cancellation:
  cancelled_date: ""
  reason: ""
---

{Markdown body — free text}
```

**Fields mutated by commands**:

| Command | Fields Modified |
|---------|----------------|
| `move` | `status`, `updated` (file also relocated to new directory) |
| `promote` | `status` → `"promoted"`, `updated`, `promotion.promoted_date`, `promotion.feature_id`, `features[]` (add) |
| `triage --apply` | `feedbacks[]` (add), `updated` (for `link_existing` action) |

---

## Feature YAML Schema

**Path pattern**: `.features/{NNN}-{slug}.yaml`

**Created by**: `promote` command

**Canonical template** (matching existing `.features/*.yaml` format):
```yaml
feature_version: "1.0"

# ── Identity ──────────────────────────────────────────
feature_id: "{NNN}-{slug}"
title: "{Backlog title}"
status: "active"
owner: "{Backlog owner}"
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"

# ── Dependencies ──────────────────────────────────────
depends_on: []
tags: []

# ── Lifecycle (computed) ──────────────────────────────
lifecycle:
  stage: "ideation"
  stage_since: "{YYYY-MM-DD}"
  progress: 0.0
  manual_override: null
  retroactive: false

# ── Artifacts (computed from scan) ────────────────────
artifacts:
  bmad:
    prd: false
    architecture: false
    epics: false
  speckit:
    spec: false
    plan: false
    research: false
    tasks: false
    contracts: false
    tasks_done: 0
    tasks_total: 0
  agreement:
    exists: false
    status: ""
    check: "NOT_APPLICABLE"
  adr:
    count: 0
    ids: []
  mermaid:
    count: 0
    layers:
      L0: 0
      L1: 0
      L2: 0

# ── Health (computed) ─────────────────────────────────
health:
  overall: "HEALTHY"
  agreement: "NOT_APPLICABLE"
  spec_completeness: 0.0
  task_progress: 0.0
  adr_coverage: 0
  diagram_coverage: 0
  warnings: []

# ── Regression Detection ─────────────────────────────
last_scan:
  timestamp: "{ISO8601}"
  stage: "ideation"
  artifacts_snapshot:
    bmad_prd: false
    speckit_spec: false
    speckit_plan: false
    speckit_tasks: false
    agreement_exists: false

# ── Conventions ───────────────────────────────────────
conventions:
  - "conv-001-esm-zero-deps"
  - "conv-002-cli-entry-structure"
  - "conv-003-file-based-artifacts"
```

**Slug generation rules**:
- Source: backlog `title` field
- Lowercase
- Replace spaces and special characters with hyphens
- Collapse multiple hyphens to one
- Truncate to 60 characters
- Strip leading/trailing hyphens

---

## Index File Schema

**Path**: `.product/index.yaml`

**Written by**: `reindex`, `move`, `promote`, `triage --apply`

**Full schema**:
```yaml
product_version: "1.0"
updated: "{ISO8601_TIMESTAMP}"

feedbacks:
  total: {integer}
  by_status:
    new: {integer}
    triaged: {integer}
    excluded: {integer}
    resolved: {integer}
  by_category:
    critical-bug: {integer}
    bug: {integer}
    optimization: {integer}
    evolution: {integer}
    new-feature: {integer}
  items:
    - id: "{FB-NNN}"
      title: "{string}"
      status: "{enum}"
      category: "{enum}"
      priority: "{enum|null}"
      created: "{YYYY-MM-DD}"

backlogs:
  total: {integer}
  by_status:
    open: {integer}
    in-progress: {integer}
    done: {integer}
    promoted: {integer}
    cancelled: {integer}
  items:
    - id: "{BL-NNN}"
      title: "{string}"
      status: "{enum}"
      category: "{enum}"
      priority: "{enum}"
      created: "{YYYY-MM-DD}"

metrics:
  feedback_to_backlog_rate: {float, 2 decimal places}
  backlog_to_feature_rate: {float, 2 decimal places}
```

**Sorting**: Items sorted by numeric ID (FB-1 < FB-2 < FB-10, not lexicographic).

**Atomic write**: Written to `index.yaml.tmp` then renamed to `index.yaml` to prevent partial reads.

---

## Triage Plan File Schema

**Type**: JSON (not YAML)

**Created by**: Slash command (AI-annotated from `triage --plan` output)

**Consumed by**: `kai-product triage --apply <file>`

```json
{
  "version": "1.0",
  "plan": [
    {
      "action": "create_backlog",
      "backlog_title": "string (required)",
      "feedback_ids": ["FB-NNN"],
      "priority": "low|medium|high",
      "category": "critical-bug|bug|optimization|evolution|new-feature",
      "owner": "string (optional)",
      "regression": false,
      "notes": "string (optional)"
    },
    {
      "action": "link_existing",
      "backlog_id": "BL-NNN",
      "feedback_ids": ["FB-NNN"]
    },
    {
      "action": "exclude",
      "feedback_ids": ["FB-NNN"],
      "reason": "string (required)"
    }
  ]
}
```

**Validation rules** (checked before any file is modified):
- `version` must be `"1.0"`
- Each `feedback_id` must exist in `feedbacks/new/`
- Each `backlog_id` (for `link_existing`) must exist in `backlogs/`
- No feedback ID may appear in more than one plan entry
- `backlog_title` required for `create_backlog`
- `reason` required for `exclude`

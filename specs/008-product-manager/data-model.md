# Data Model: kai Product Manager Module

**Feature**: 008-product-manager
**Date**: 2026-02-18

## Entities

### Feedback

A structured record of user input captured through the intake process.

**Identity**: `FB-xxx` (zero-padded 3-digit sequential ID, e.g., FB-001, FB-042)

**Schema (YAML frontmatter)**:

```yaml
---
id: "FB-001"
title: "Login crashes on Safari"
status: "new"                    # new | triaged | excluded | resolved
category: "bug"                  # critical-bug | bug | optimization | evolution | new-feature
priority: null                   # null | low | medium | high | critical
source: "user"                   # user | internal | automated | external
reporter: "tcanaud"
created: "2026-02-18"
updated: "2026-02-18"
tags: ["auth", "safari", "crash"]
exclusion_reason: ""             # populated when status = excluded (e.g., "duplicate-resolved", "noise", "out-of-scope")
linked_to:
  backlog: []                    # BL-xxx IDs this feedback contributed to
  features: []                   # feature IDs (via backlog promotion chain)
  feedbacks: []                  # related feedback IDs (grouping)
resolution:
  resolved_date: ""              # populated when status = resolved
  resolved_by_feature: ""        # feature ID that resolved this
  resolved_by_backlog: ""        # backlog ID in the chain
---
```

**Body**: Free-text Markdown description of the feedback — the original user complaint, context, reproduction steps, or any supporting detail.

**Status transitions (directory-based)**:

```
feedbacks/new/       → feedbacks/triaged/     (via /product.triage)
feedbacks/new/       → feedbacks/excluded/    (via /product.triage — duplicate, noise, out-of-scope)
feedbacks/triaged/   → feedbacks/resolved/    (manual or when linked feature ships)
feedbacks/new/       → feedbacks/excluded/    (via /product.triage — DUPLICATE-RESOLVED)
```

**Validation rules**:
- `id` must be unique across all status directories
- `status` must match the directory the file resides in
- `category` must be one of the 5 predefined values
- `created` must be a valid ISO date
- If `status` is `excluded`, `exclusion_reason` must be non-empty
- If `status` is `resolved`, `resolution.resolved_date` must be non-empty

---

### Backlog Item

An actionable work item aggregating one or more feedbacks.

**Identity**: `BL-xxx` (zero-padded 3-digit sequential ID, e.g., BL-001, BL-015)

**Schema (YAML frontmatter)**:

```yaml
---
id: "BL-001"
title: "Improve authentication flow"
status: "open"                   # open | in-progress | done | promoted | cancelled
category: "optimization"        # critical-bug | bug | optimization | evolution | new-feature
priority: "high"                 # low | medium | high | critical
created: "2026-02-18"
updated: "2026-02-18"
owner: "tcanaud"
feedbacks: ["FB-001", "FB-003"]  # source feedbacks (bidirectional link)
features: []                     # feature IDs if promoted
tags: ["auth", "ux"]
promotion:
  promoted_date: ""              # populated when status = promoted
  feature_id: ""                 # the feature created from this backlog
cancellation:
  cancelled_date: ""             # populated when status = cancelled
  reason: ""                     # why it was cancelled
---
```

**Body**: Free-text Markdown description synthesizing the linked feedbacks into an actionable work item — problem statement, proposed scope, and any notes from the triage process.

**Status transitions (directory-based)**:

```
backlogs/open/         → backlogs/in-progress/    (manual)
backlogs/open/         → backlogs/promoted/        (via /product.promote)
backlogs/open/         → backlogs/cancelled/       (manual)
backlogs/in-progress/  → backlogs/done/            (manual)
backlogs/in-progress/  → backlogs/promoted/        (via /product.promote)
backlogs/in-progress/  → backlogs/cancelled/       (manual)
```

**Validation rules**:
- `id` must be unique across all status directories
- `status` must match the directory the file resides in
- `feedbacks` must contain at least one valid feedback ID
- If `status` is `promoted`, `promotion.feature_id` must be non-empty
- If `status` is `cancelled`, `cancellation.reason` must be non-empty

---

### Index

Centralized registry of all feedbacks and backlogs. Performance cache — filesystem is authoritative.

**Schema (`index.yaml`)**:

```yaml
product_version: "1.0"
updated: "2026-02-18T12:00:00Z"

feedbacks:
  total: 12
  by_status:
    new: 3
    triaged: 5
    excluded: 2
    resolved: 2
  by_category:
    critical-bug: 1
    bug: 3
    optimization: 4
    evolution: 2
    new-feature: 2
  items:
    - id: "FB-001"
      title: "Login crashes on Safari"
      status: "new"
      category: "bug"
      priority: null
      created: "2026-02-18"
    # ... one entry per feedback

backlogs:
  total: 4
  by_status:
    open: 2
    in-progress: 1
    done: 0
    promoted: 1
    cancelled: 0
  items:
    - id: "BL-001"
      title: "Improve authentication flow"
      status: "open"
      priority: "high"
      feedbacks_count: 2
      created: "2026-02-18"
    # ... one entry per backlog

metrics:
  feedback_to_backlog_rate: 0.42    # triaged feedbacks that became backlogs / total triaged
  backlog_to_feature_rate: 0.25     # promoted backlogs / total backlogs
```

---

### Inbox File

Raw/unstructured feedback dropped by external tools or users. No schema enforced — the intake command processes these into structured feedbacks.

**Expected format** (advisory, not enforced):

```markdown
---
source: "external"          # optional: helps /product.intake set the source field
reporter: "colleague-name"  # optional: preserved in the structured feedback
timestamp: "2026-02-18"     # optional: preserved as created date
---

The actual feedback content goes here. Can be any format — a Slack message export,
a copy-pasted email, a bullet list, or just a plain paragraph.
```

If no YAML frontmatter is present, the intake command infers metadata from the content.

## Relationships

```
Inbox File ──(processed by /product.intake)──→ Feedback (new/)
                                                  │
                                                  │ grouped by /product.triage
                                                  ▼
                                              Backlog Item (open/)
                                                  │
                                                  │ promoted by /product.promote
                                                  ▼
                                              Feature (.features/xxx.yaml)
                                                  │
                                                  │ reaches release stage
                                                  ▼
                                              Feedback (resolved/)
```

**Bidirectional links**:
- Feedback → Backlog: `linked_to.backlog[]` in feedback frontmatter
- Backlog → Feedback: `feedbacks[]` in backlog frontmatter
- Backlog → Feature: `features[]` and `promotion.feature_id` in backlog frontmatter
- Feedback → Feature: `linked_to.features[]` in feedback frontmatter (transitive, via backlog)

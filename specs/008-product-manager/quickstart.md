# Quickstart: kai Product Manager Module

**Feature**: 008-product-manager
**Date**: 2026-02-18

## Prerequisites

- A project using the kai governance stack (`.features/`, `.agreements/`, etc.)
- Claude Code installed and configured
- Git repository initialized
- Node.js >= 18.0.0

## Installation

### Via tcsetup (recommended)

```bash
npx tcsetup init
# Product Manager is included in the standard installation
```

Or if the project already has tcsetup:

```bash
npx tcsetup update
```

### Standalone

```bash
npx product-manager init
```

This creates:
- `.product/` directory with all subdirectories (`inbox/`, `feedbacks/{new,triaged,excluded,resolved}/`, `backlogs/{open,in-progress,done,promoted,cancelled}/`)
- `.product/_templates/feedback.tpl.md` and `backlog.tpl.md`
- `.product/index.yaml` (empty initial index)
- `.claude/commands/product.{intake,triage,backlog,promote,check,dashboard}.md`

### Updating

```bash
npx product-manager update
```

Refreshes slash command templates and artifact templates without touching user data (feedbacks, backlogs, index).

## Artifact Templates

### Feedback schema (`_templates/feedback.tpl.md`)

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
tags: []
exclusion_reason: ""
linked_to:
  backlog: []
  features: []
  feedbacks: []
resolution:
  resolved_date: ""
  resolved_by_feature: ""
  resolved_by_backlog: ""
---
```

### Backlog schema (`_templates/backlog.tpl.md`)

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
feedbacks: []
features: []
tags: []
promotion:
  promoted_date: ""
  feature_id: ""
cancellation:
  cancelled_date: ""
  reason: ""
---
```

## Usage

### Capture feedback

```
/product.intake Users report search takes 40 seconds on large repos
```

### Drop external feedback

Place a file in `.product/inbox/`, then:

```
/product.intake
```

### Triage accumulated feedbacks

```
/product.triage                 # autonomous mode
/product.triage --supervised    # confirm each action
```

### Browse backlogs

```
/product.backlog                # list all
/product.backlog BL-001         # detail view
```

### Promote to feature

```
/product.promote BL-001
```

Then continue with:

```
/feature.workflow 009-search-performance
```

### Check health

```
/product.check
```

### View dashboard

```
/product.dashboard              # Markdown output
/product.dashboard --json       # JSON output
```

## The Complete Loop

```
User complaint
  → /product.intake "search is slow"
    → .product/feedbacks/new/FB-001.md

  → /product.triage
    → .product/feedbacks/triaged/FB-001.md
    → .product/backlogs/open/BL-001.md

  → /product.promote BL-001
    → .product/backlogs/promoted/BL-001.md
    → .features/009-search-perf.yaml

  → /feature.workflow 009-search-perf
    → Brief → PRD → Spec → Tasks → Code → Release

  → (manual) move FB-001.md to feedbacks/resolved/
    → Full traceability: FB-001 → BL-001 → feature 009 → release
```

## Verification

After installation, verify with:

```
ls .product/feedbacks/new/      # should be empty
ls .product/backlogs/open/      # should be empty
/product.dashboard              # should show all zeros
/product.check                  # should report zero findings
```

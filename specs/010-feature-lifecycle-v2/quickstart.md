# Quickstart: Feature Lifecycle V2

**Feature**: 010-feature-lifecycle-v2

## Prerequisites

- kai feature-lifecycle package installed (`npx feature-lifecycle init`)
- kai QA system installed (`npx @tcanaud/qa-system init`)
- kai agreement system installed (`npx agreement-system init`)
- GitHub CLI installed and authenticated (`gh auth login`)
- Optional: kai product-manager installed (`npx @tcanaud/product-manager init`)

## What's New in V2

V2 extends the feature workflow dashboard with four new capabilities after implementation:

1. **QA Integration** — `/feature.workflow` shows QA plan and run as steps, evaluates Gate D
2. **PR Creation** — `/feature.pr {feature}` creates GitHub PRs with full governance traceability
3. **Post-Merge Resolution** — `/feature.resolve {feature}` closes the governance chain
4. **QA FAIL Recovery** — Automatic backlog generation and fix cycle routing on QA failure

## Installation

V2 is delivered as an update to the feature-lifecycle package:

```bash
npx feature-lifecycle update
```

This installs two new slash commands:
- `.claude/commands/feature.pr.md`
- `.claude/commands/feature.resolve.md`

And updates the existing:
- `.claude/commands/feature.workflow.md` (extended with QA/PR/resolve steps)

## The V2 Endgame Path

After all implementation tasks are done:

```
/feature.workflow {feature}
    → Dashboard shows Gate C-V2 satisfied (tasks 100%)
    → Proposes: /qa.plan {feature}

/qa.plan {feature}
    → Generates test scripts in .qa/{feature}/scripts/

/feature.workflow {feature}
    → Proposes: /qa.run {feature}

/qa.run {feature}
    → Executes scripts, outputs verdict

/feature.workflow {feature}
    → If QA PASS + Agreement Check PASS → Gate D satisfied
    → Proposes: /feature.pr {feature}

/feature.pr {feature}
    → Creates GitHub PR with traceability body
    → Developer reviews and merges on GitHub

/feature.resolve {feature}
    → Detects merge, transitions to release
    → Closes all linked backlogs and feedbacks
```

## Commands

### /feature.workflow {feature} (updated)

The dashboard now shows additional steps after implementation:

```
| # | Step | Status | Artifact |
|---|------|--------|----------|
| ...existing steps... |
|   | GATE C-V2 | pass | All tasks done |
| 12 | QA Plan | done | .qa/{feature}/_index.yaml |
| 13 | QA Run | PASS | verdict.yaml |
| 14 | Agreement Check | PASS | check-report.md |
|   | GATE D | pass | QA PASS + Agreement PASS |
| 15 | PR Creation | done | https://github.com/.../pull/42 |
| 16 | Post-Merge | pending | — |
```

### /feature.pr {feature} (new)

Creates a GitHub PR with the complete governance lineage in the body:

```bash
# Prerequisites enforced:
# - All tasks done
# - QA verdict: PASS (and fresh)
# - Agreement check: PASS
# - No duplicate PR exists

/feature.pr 010-feature-lifecycle-v2

# Output: PR URL
# PR body contains: spec link, agreement link, QA summary,
# agreement check verdict, feedbacks, backlogs, diff summary
```

### /feature.resolve {feature} (new)

Closes the governance chain after PR merge:

```bash
# Prerequisites enforced:
# - PR is merged on GitHub

/feature.resolve 010-feature-lifecycle-v2

# Transitions:
# - Feature stage → "release"
# - Linked backlogs → "done"
# - Originating feedbacks → "resolved"
```

## QA FAIL Recovery

When QA returns FAIL, the workflow routes automatically:

```
/qa.run {feature}
    → FAIL verdict (2 checks failed)

/feature.workflow {feature}
    → Detects FAIL
    → Auto-generates critical backlog in .product/backlogs/open/
    → Proposes fix path:
        1. Fix failing checks
        2. Re-run /qa.run {feature}
        3. Continue workflow
```

If the product-manager system is not installed, the workflow displays the failing checks directly and suggests manual resolution.

## Backward Compatibility

Existing features (001-009) continue to work:

- QA/PR/resolve steps appear as `skip` in the dashboard
- Gate D is auto-satisfied (no QA required)
- No errors, no regressions
- Features can opt into the V2 path by running `/qa.plan {feature}`

## File Artifacts

| File | Created By | Purpose |
|------|-----------|---------|
| `.qa/{feature}/verdict.yaml` | `/feature.workflow` after `/qa.run` | Persist QA verdict for gate evaluation |
| `.product/backlogs/open/BL-xxx.md` | `/feature.workflow` on QA FAIL | Auto-generated critical backlog |
| GitHub PR | `/feature.pr` | Traceable pull request |

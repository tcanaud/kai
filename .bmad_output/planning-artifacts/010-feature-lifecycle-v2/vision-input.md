# 010-feature-lifecycle-v2 — Vision Input

> Context document for BMAD product brief creation.
> Written: 2026-02-18
> Depends on: 009-qa-system

## Problem

After a feature is implemented and QA passes, there's no automated way to:
1. Trigger the QA flow from the feature workflow
2. Create a PR with full traceability
3. Move the feature lifecycle to "release" after merge

The developer must manually create PRs, manually track which features are ready, and manually update lifecycle stages. This breaks the "convention before code" principle.

## Solution: Feature Lifecycle V2

Two new capabilities added to the existing feature-lifecycle package:

### 1. QA Integration in Workflow

`/feature.workflow` gains a new step after Implementation:

```
Full Method (updated):
  Brief → PRD → Spec → Plan → Tasks → Agreement → Implement
    → QA Plan → QA Run → PR → Release

Gate additions:
  GATE C (updated): tasks >= 100% → unlocks QA
  GATE D (new): QA PASS + agreement.check PASS → unlocks PR
```

The workflow router shows QA status in the progress dashboard and proposes `/qa.plan` then `/qa.run` as next actions when implementation is complete.

### 2. PR Creation with Traceability

New command: `/feature.pr {feature}`

Prerequisites (all must be true):
- QA verdict: PASS
- Agreement check: PASS
- All tasks: done

The PR body is auto-generated with full traceability:
```markdown
## Feature: 009-qa-system — QA System

### Traceability
- **Spec**: specs/009-qa-system/spec.md
- **Agreement**: .agreements/009-qa-system/agreement.yaml
- **QA**: .qa/009-qa-system/test-results.md (PASS — 12/12 checks)
- **Agreement Check**: PASS

### Feedbacks originated from
- FB-001: "need automated testing"
- FB-003: "can't verify feature works before merge"

### Backlog
- BL-001: "QA automation system"

### Changes
{git diff main...HEAD summary}
```

After PR creation, the feature lifecycle stage moves to "release" (or a new "pr-review" stage).

### 3. Post-merge Lifecycle Update

When the PR is merged (detected via `gh pr view` or manual trigger):
- Feature stage → "release"
- Linked backlogs → "done"
- Linked feedbacks → "resolved"
- The full chain is closed

## Commands

| Command | What it does |
|---------|-------------|
| `/feature.pr {feature}` | Create GitHub PR with traceability (requires QA PASS + agreement PASS) |
| `/feature.workflow` (updated) | Now includes QA and PR steps in the dependency chain |

## Constraints

- This is an evolution of the existing feature-lifecycle package, not a new package
- Must be backward-compatible (features without QA still work)
- PR creation uses `gh` CLI (GitHub CLI)
- The responsibility chain is mechanical: QA gates decide, not humans (for the PASS/FAIL verdict)
- Human review happens at PR level (the last gate)

# 009-qa-system — Vision Input

> Context document for BMAD product brief creation.
> Written: 2026-02-18

## Problem

The kai governance loop is open-ended after implementation. A developer runs `/speckit.implement`, tasks get checked off, but there's no automated verification that the feature actually works as specified. No feedback loop back into product. No gate before PR creation.

Today's loop:
```
Feedback → Triage → Backlog → Feature → Brief → Spec → Tasks → Agreement → Implement → ???
```

The `???` is the gap. Nothing validates that acceptance criteria are met. Nothing feeds implementation discoveries back into the product pipeline.

## Solution: QA System

A file-based, reproducible QA system that:

1. **Generates test plans** from existing spec.md + agreement.yaml (not from thin air — from the promises already made)
2. **Executes verifications** via Claude Code and produces a binary PASS/FAIL verdict
3. **Feeds non-blocking findings** back into `.product/inbox/` as structured feedback

### Architecture

```
.qa/
├── {feature}/
│   ├── test-plan.md          ← Generated from spec.md + agreement.yaml
│   ├── test-results.md       ← Verdict from last run (PASS/FAIL + details)
│   └── findings/             ← Individual non-blocking discoveries
│       └── QF-001.md         ← Drift, improvement, edge case → goes to .product/inbox/
└── _templates/
```

### Freshness Tracking (solves "outdated tests" problem)

Test plans store source checksums in frontmatter:
```yaml
generated_from:
  spec: { path: "specs/009/spec.md", sha: "a3f2c1" }
  agreement: { path: ".agreements/009/agreement.yaml", sha: "b7d4e2" }
  tasks: { path: "specs/009/tasks.md", sha: "c9e1f5" }
status: current  # current | stale
```

`/qa.check` compares stored SHA vs current SHA. If diverged → `stale` → must regenerate before running. Same pattern as knowledge-system freshness tracking.

### Strict Separation: Blocking vs Non-blocking

- **Blocking** = acceptance criterion from spec.md not satisfied → FAIL, dev must fix
- **Non-blocking** = drift, improvement, edge case → `.product/inbox/` as feedback for future cycles

This prevents infinite loops. The QA verdict is mechanical: criteria pass or they don't. Observations go to product backlog.

### Commands

| Command | What it does |
|---------|-------------|
| `/qa.plan {feature}` | Generate test plan from spec.md + agreement.yaml |
| `/qa.run {feature}` | Execute test plan, produce PASS/FAIL verdict |
| `/qa.check` | Check test plan freshness across all features |

### Closed Loop

```
/qa.run 009-qa-system
  → PASS: all acceptance criteria met
  → 2 non-blocking findings → .product/inbox/qa-009-*.md
    → /product.triage picks them up in next cycle
```

## Constraints

- Zero runtime dependencies (node: protocol only)
- File-based artifacts (Markdown + YAML frontmatter)
- Git submodule package pattern (like all kai packages)
- Claude Code slash commands as interface
- Test plans are reproducible — anyone can re-run `/qa.run` and get the same verdict

## Relationship to 010-feature-lifecycle-v2

009 provides the QA engine. 010 integrates it into the feature workflow:
- `/feature.workflow` adds QA as a gate after implementation
- `/feature.pr` creates GitHub PR only when QA PASS + agreement.check PASS
- The full loop closes: implement → QA → PR → merge → release

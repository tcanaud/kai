---
stepsCompleted: [1, 2, 3, 4, 5, 6]
workflowComplete: true
inputDocuments:
  - ".bmad_output/planning-artifacts/010-feature-lifecycle-v2/vision-input.md"
  - ".knowledge/architecture.md"
  - ".knowledge/snapshot.md"
  - ".knowledge/guides/project-philosophy.md"
date: "2026-02-18"
author: "tcanaud"
---

# Product Brief: kai — Feature Lifecycle V2

<!-- Content will be appended sequentially through collaborative workflow steps -->

## Executive Summary

Feature Lifecycle V2 extends kai's governance workflow beyond implementation into the verification-and-release corridor. Today, the feature workflow ends after task implementation — QA triggering, PR creation with traceability, and post-merge state updates are all manual, time-consuming, and error-prone. V2 closes this gap by adding mechanical QA gating, traceable PR generation, and automated post-merge lifecycle resolution to the existing feature workflow. The user focuses on vision and strategy at the top of the funnel; the system handles the deterministic endgame.

---

## Core Vision

### Problem Statement

After a feature's implementation tasks reach 100% completion, the kai governance workflow drops the developer into a manual void. Three critical steps — triggering QA, creating a PR with full traceability links, and updating lifecycle state after merge — must be performed by hand. This breaks the "convention before code" principle that governs every other phase of the feature lifecycle.

### Problem Impact

- **Time cost**: Each feature release requires significant manual ceremony (QA orchestration, PR body composition, state file updates across feedbacks, backlogs, and feature YAML)
- **Error risk**: Manual steps lead to forgotten state updates, incomplete traceability in PRs, and lifecycle stages that drift from reality
- **Broken automation chain**: The workflow is automated from Brief through Implementation, then suddenly manual for the final mile — the highest-stakes phase where mistakes ship to production

### Why Existing Solutions Fall Short

The current feature workflow (`/feature.workflow`) provides a dependency chain from Brief to Implementation with gates and artifact detection. But it stops at task completion. There is no:
1. QA step in the workflow dependency chain — QA commands exist (`/qa.plan`, `/qa.run`) but are disconnected from the feature workflow router
2. PR creation with traceability — developers manually compose PR bodies without systematic links to specs, agreements, QA results, feedbacks, or backlogs
3. Post-merge lifecycle closure — after merge, feature stage, linked backlogs, and originating feedbacks must be manually updated

The tools exist in isolation. V2 connects them into a single mechanical chain.

### Proposed Solution

Extend the existing feature-lifecycle package with three capabilities:

1. **QA Integration in Workflow** — Add QA Plan and QA Run as steps in the `/feature.workflow` dependency chain. Gate C requires 100% task completion to unlock QA. A new Gate D requires QA PASS + Agreement Check PASS to unlock PR creation.

2. **PR Creation with Traceability** (`/feature.pr`) — New command that auto-generates a GitHub PR with full governance traceability: spec, agreement, QA results, agreement check verdict, originating feedbacks, and linked backlogs. Prerequisites are mechanical: QA PASS, Agreement PASS, all tasks done.

3. **Post-merge Lifecycle Resolution** — After PR merge, automatically transition: feature stage → "release", linked backlogs → "done", originating feedbacks → "resolved". The full governance chain closes cleanly.

### Key Differentiators

- **Mechanical endgame**: The system decides readiness through deterministic gates (QA PASS, Agreement PASS), not human judgment. Human review happens only at the PR level — the last gate.
- **Full-chain traceability**: Every PR carries its complete lineage — from feedback to backlog to spec to agreement to QA verdict. No manual composition.
- **Backward compatible**: Features without QA still work. The new steps are additive to the existing dependency chain.
- **Convention before code, all the way through**: The governance rail now extends from ideation to release. The developer's high-value work is at the beginning; the system handles the deterministic resolution.

## Target Users

### Primary Users

**Persona: The Solo Governance Maintainer**

- **Profile**: A solo developer managing a kai-powered project with multiple features in active pipeline (5-10+ simultaneous features at various lifecycle stages)
- **Context**: Uses Claude Code as primary interface. Masters the full kai governance stack — BMAD for product vision, SpecKit for specs/plans/tasks, Agreements for drift detection, QA for verification
- **Motivation**: Spend maximum time on high-value strategic work (vision, architecture decisions, specification) and minimum time on mechanical endgame operations (QA triggering, PR composition, state file updates)
- **Current pain**: After implementation completes, the automated rail stops. Each feature requires manual QA orchestration, manual PR body composition with traceability links, and manual lifecycle state updates across feature YAML, backlogs, and feedbacks. With 10 features in pipeline, this manual overhead compounds — errors and omissions become inevitable
- **Success vision**: Run `/feature.workflow`, see the next mechanical step, execute it, repeat. The system handles the deterministic parts; the developer never touches a state file by hand after implementation

### Secondary Users

N/A for V2 scope. Future scope includes automated PR validation for non-breaking changes, which would introduce a "reviewer" role. Out of scope for this iteration.

### User Journey

1. **Existing workflow (unchanged)**: Developer uses `/feature.workflow` to navigate Brief → PRD → Spec → Plan → Tasks → Agreement → Implement
2. **New V2 corridor**: Once all tasks are done, `/feature.workflow` proposes QA Plan → QA Run as next steps
3. **Gate checkpoint**: System mechanically verifies QA PASS + Agreement Check PASS — no human judgment needed
4. **PR creation**: `/feature.pr` generates a fully-traced PR in one command — developer reviews the output, not composes it
5. **Post-merge closure**: After merge, feature stage → "release", backlogs → "done", feedbacks → "resolved". The governance chain is closed. Developer moves to the next feature in the pipeline
6. **Value moment**: The developer realizes they shipped a feature from QA to release without editing a single state file by hand

## Success Metrics

### User Success

- **Bug-free V1 delivery**: The workflow produces a first version of the feature that is stable enough for real-world integration testing — no forgotten steps, no missing artifacts, no broken state
- **Zero manual state management**: After implementation tasks reach 100%, the developer never edits a feature YAML, backlog, or feedback file by hand. The system handles all state transitions mechanically
- **Guided flow without memory burden**: The developer does not need to remember what comes next. `/feature.workflow` always knows the current state and proposes the exact next action

### Business Objectives

- **Complete workflow coverage**: The governance rail extends unbroken from ideation to release. No phase requires the developer to exit the workflow and operate manually
- **Zero forgotten steps**: Every feature that passes through the V2 workflow has QA executed, agreement checked, PR created with full traceability, and lifecycle properly closed post-merge
- **Self-proving delivery**: Feature 010-feature-lifecycle-v2 is itself delivered through the V2 workflow, serving as both the product and its own validation

### Key Performance Indicators

| KPI | Target | Measurement |
|-----|--------|-------------|
| Workflow step coverage | ideation → release with zero manual gaps | `/feature.workflow` dependency chain completeness |
| State file manual edits post-implementation | 0 | No hand-edited YAML after tasks hit 100% |
| PR traceability completeness | 100% of PRs link spec, agreement, QA, feedbacks | PR body content inspection |
| Post-merge chain closure | All linked artifacts updated | Feature stage + backlogs + feedbacks transitioned |
| Self-delivery | Feature 010 delivered via its own V2 workflow | `/feature.status 010` shows "release" |

## MVP Scope

### Core Features

**1. QA Integration in Workflow**
- Extend `/feature.workflow` dependency chain with QA Plan and QA Run steps after Implementation
- Update Gate C: tasks must reach 100% completion to unlock QA
- Add Gate D: QA PASS + Agreement Check PASS to unlock PR creation
- Display QA status in the progress dashboard
- Propose `/qa.plan` then `/qa.run` as next actions when implementation is complete

**2. PR Creation with Traceability (`/feature.pr`)**
- New command: `/feature.pr {feature}`
- Prerequisites enforced mechanically: QA PASS, Agreement Check PASS, all tasks done
- Auto-generated PR body with full traceability: spec, agreement, QA results, agreement check verdict, originating feedbacks, linked backlogs, git diff summary
- Uses `gh` CLI for GitHub PR creation

**3. Post-merge Lifecycle Resolution**
- Detect PR merge (via `gh pr view` or manual trigger)
- Transition feature stage → "release"
- Transition linked backlogs → "done"
- Transition originating feedbacks → "resolved"
- Full governance chain closure in one operation

### Out of Scope for MVP

- **Auto-merge for non-breaking changes** — Future capability where PRs without breaking changes skip human review. Deferred to a later iteration
- **Multi-reviewer workflows** — No reviewer role or approval chains. Human review happens natively on GitHub
- **CI/CD integration** — No GitHub Actions or webhook triggers. All operations are on-demand via slash commands

### MVP Success Criteria

- Feature 010-feature-lifecycle-v2 is delivered through its own V2 workflow (self-proving)
- `/feature.workflow` guides from implementation completion to release with zero manual state edits
- Every PR created via `/feature.pr` carries complete traceability links
- Post-merge closure updates all linked artifacts without manual intervention
- Existing features without QA continue to work through the workflow (backward compatibility)

### Future Vision

- **Auto-merge gate**: For non-breaking changes, skip human PR review entirely — the system decides based on QA + agreement + diff analysis
- **Batch release**: Ship multiple features in a single PR when their dependency graphs align
- **Release notes generation**: Auto-generate changelog from the traceability chain of all features in a release
- **Cross-feature dependency awareness**: Gate a feature's PR on dependent features being released first

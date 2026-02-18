---
stepsCompleted: ["step-01-init", "step-02-discovery", "step-02b-vision", "step-02c-executive-summary", "step-03-success", "step-04-journeys", "step-05-domain-skipped", "step-06-innovation-skipped", "step-07-project-type", "step-08-scoping", "step-09-functional", "step-10-nonfunctional", "step-11-polish"]
classification:
  projectType: "developer_tool"
  domain: "general"
  complexity: "low"
  projectContext: "brownfield"
inputDocuments:
  - ".bmad_output/planning-artifacts/010-feature-lifecycle-v2/product-brief-kai-2026-02-18.md"
  - ".bmad_output/planning-artifacts/010-feature-lifecycle-v2/vision-input.md"
  - ".knowledge/guides/project-philosophy.md"
  - ".knowledge/snapshot.md"
workflowType: 'prd'
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 2
---

# Product Requirements Document - kai (Feature Lifecycle V2)

**Author:** tcanaud
**Date:** 2026-02-18

## Executive Summary

Feature Lifecycle V2 completes kai's governance rail from ideation to release. Today, `/feature.workflow` guides the developer through Brief → PRD → Spec → Plan → Tasks → Agreement → Implement, then stops. The final mile — QA verification, PR creation, and post-merge state closure — is manual, error-prone, and disconnected from the workflow router. V2 adds three capabilities to the existing `feature-lifecycle` package: QA integration in the workflow dependency chain, PR creation with full governance traceability (`/feature.pr`), and automated post-merge lifecycle resolution. Gates are mechanical: QA PASS + Agreement Check PASS unlock PR creation. Human judgment enters only at the PR review level.

This is the natural successor to 009-qa-system, which delivered automated verification. V2 connects that verification to the workflow router and extends it through release. The developer's high-value work stays at the top of the funnel (vision, strategy, specification). The system handles the deterministic endgame.

### What Makes This Special

Intelligence and concision. The workflow knows exactly where every feature stands, proposes exactly the next action, and executes with minimum friction. No dashboard, no external service, no configuration ceremony. The governance rail is a continuous, mechanical chain where each phase pours into the next — not a toolkit of disconnected commands. This is the "convention before code" philosophy carried to its logical conclusion: the system cannot lie about readiness because readiness is computed from artifacts, not declared.

## Project Classification

- **Project Type:** Developer tool — Node.js ESM package providing Claude Code slash commands
- **Domain:** Project governance / developer tooling
- **Complexity:** Low — file I/O and command orchestration, no external protocols or compliance
- **Project Context:** Brownfield — extends the existing `feature-lifecycle` package with 3 new capabilities. Backward compatible: features without QA continue to work

## Success Criteria

### User Success

- **Guided endgame**: After tasks reach 100%, `/feature.workflow` proposes QA → PR → Release as next steps without the developer needing to remember the sequence
- **Zero manual state edits**: No hand-editing of feature YAML, backlog files, or feedback files after implementation. All state transitions are mechanical
- **Bug-free V1**: The workflow produces a feature version stable enough for real-world integration testing — no forgotten artifacts, no broken state files

### Business Success

- **Self-proving delivery**: Feature 010-feature-lifecycle-v2 is delivered through its own V2 workflow. The product is its own proof of concept
- **Complete rail coverage**: The governance workflow covers ideation → release with zero manual gaps. Every feature that enters the rail exits with full traceability
- **Zero forgotten steps**: 100% of features processed through V2 have QA executed, agreement checked, PR created with traceability, and lifecycle closed post-merge

### Technical Success

- **Backward compatibility**: Existing features without QA artifacts continue to work through `/feature.workflow` without errors or regressions
- **It works**: No performance requirements, no size constraints. The system scans artifacts, generates PR bodies, and updates state files. Correctness is the only bar

### Measurable Outcomes

| Outcome | Target | Verification |
|---------|--------|-------------|
| Manual state edits post-implementation | 0 | No hand-edited YAML after tasks hit 100% |
| PR traceability links | 100% complete | Every `/feature.pr` output links spec, agreement, QA, feedbacks, backlogs |
| Post-merge closure | All artifacts updated | Feature → release, backlogs → done, feedbacks → resolved |
| Backward compat | No regressions | Existing features (001-009) still work through workflow |
| Self-delivery | Feature 010 ships via V2 | `/feature.status 010` shows "release" |

## Product Scope

### MVP Strategy

**Approach:** Problem-solving MVP — deliver the complete governance rail from implementation to release. The three capabilities are indissociable; partial delivery doesn't solve the problem.
**Resources:** Solo developer. Slash command templates (Markdown) + file I/O logic in the existing `feature-lifecycle` package.

### MVP Features (Phase 1)

1. **QA integration in `/feature.workflow`** — QA Plan + QA Run steps in dependency chain. Gate C: tasks 100%. Gate D: QA PASS + Agreement Check PASS
2. **`/feature.pr {feature}`** — PR creation with full traceability body. Prerequisites: QA PASS, Agreement PASS, all tasks done. Uses `gh` CLI
3. **Post-merge lifecycle resolution** — Feature stage → release, backlogs → done, feedbacks → resolved. Triggered via `gh pr view` or manual
4. **QA FAIL → governance loop** — Auto-generate critical backlog from QA findings via product-manager, redirect workflow through backlog → spec → tasks → implementation → QA

All four are indissociable. No partial delivery.

**Core User Journeys Supported:**
- Journey 1 (Happy Path): Full rail — tasks 100% → QA → PR → post-merge
- Journey 2 (QA FAIL Loop): Governance loop via product-manager
- Journey 3 (Agreement Drift): Repair cycle integration
- Journey 4 (Backward Compat): Graceful degradation for existing features

### Growth Features (Phase 2)

- **Auto-merge gate**: Non-breaking changes skip human PR review. System decides based on QA + agreement + diff analysis

### Vision (Phase 3)

- **Batch release**: Multiple features in a single PR when dependency graphs align
- **Release notes generation**: Auto-generated changelog from traceability chain
- **Cross-feature dependency awareness**: Gate a feature's PR on dependent features being released first

### Risk Mitigation

**Technical Risk:** The QA FAIL → product-manager loop connects two systems (`.qa/` → `.product/`) for the first time. Mitigation: implement this path last, after the happy path is proven. If it proves too complex, degrade gracefully — the developer can manually create the backlog from QA findings.

**Resource Risk:** Solo developer. Build in complexity order: (1) workflow chain update — lowest risk, template changes; (2) `/feature.pr` — medium, file reading + `gh` CLI; (3) post-merge + QA FAIL loop — highest, cross-system state transitions. Early value from step 1.

## User Journeys

### Journey 1: The Happy Path — Feature 010 Ships Itself

**Opening Scene**: The developer finishes implementing feature-lifecycle-v2. Tasks: 12/12 done. Runs `/feature.workflow 010`.

**Rising Action**: Dashboard shows Gate C satisfied (tasks 100%). Next step: QA Plan. Runs `/qa.plan 010`, then `/qa.run 010`. All 12 checks pass. Gate D satisfied: QA PASS + Agreement Check PASS. Next step: PR.

**Climax**: Runs `/feature.pr 010`. The system generates a PR with the complete body — spec, agreement, QA results (PASS — 12/12), originating feedbacks, linked backlogs, diff summary. Reviews the PR on GitHub. Merge.

**Resolution**: Post-merge, the system automatically transitions: feature 010 → "release", linked backlogs → "done", feedbacks → "resolved". `/feature.status 010` confirms. The feature shipped itself. Zero state files touched by hand.

### Journey 2: QA FAIL — The Governance Loop

**Opening Scene**: A feature has all tasks done. The developer runs `/qa.run`. Verdict: FAIL — 2 checks fail on uncovered edge cases.

**Rising Action**: Gate D stays blocked (QA ≠ PASS). The workflow detects the FAIL and triggers the product-manager mechanism: a critical backlog is auto-generated in `.product/` with the QA findings as source. The workflow redirects to the backlog → spec update → tasks → implementation → QA path.

**Climax**: The developer fixes the edge cases, new tasks reach done, re-runs `/qa.run`. This time: PASS — 14/14 checks (12 original + 2 fixes). Gate D opens.

**Resolution**: The governance loop worked mechanically. The developer didn't have to decide what to do after the FAIL — the system routed automatically via the product-manager. The critical backlog carries traceability from FAIL to fix.

### Journey 3: Agreement Check FAIL — Drift Recovery

**Opening Scene**: QA passes, but `/agreement.check` returns FAIL — code has drifted from the interfaces declared in the agreement.

**Rising Action**: Gate D stays blocked (Agreement ≠ PASS). The workflow proposes `/agreement.doctor` which generates corrective tasks in tasks.md. The developer runs `/speckit.implement` to execute corrections.

**Climax**: After correction, `/agreement.check` returns PASS. Combined with QA PASS, Gate D opens. The workflow proposes `/feature.pr`.

**Resolution**: The standard repair cycle (check → doctor → implement → check) integrates naturally into the V2 workflow. No special procedure — same mechanism as any drift recovery.

### Journey 4: Backward Compatibility — Feature 007 Without QA

**Opening Scene**: Feature 007-knowledge-system is in "test" stage with all tasks done. The developer runs `/feature.workflow 007` after the V2 update.

**Rising Action**: The V2 workflow detects that 007 has no QA artifacts. The new steps (QA Plan, QA Run, PR) appear in the dashboard as optional steps, not blocking.

**Climax**: The developer can choose to follow the new rail (create QA plan, run QA, then PR) or continue manually as before. The workflow adapts — it proposes new steps without imposing them.

**Resolution**: No existing feature is broken. The V2 workflow enriches without constraining. Features that want the complete rail get it. Others continue as before.

### Journey Requirements Summary

| Journey | Capabilities Revealed |
|---------|----------------------|
| Happy Path | QA steps in workflow chain, Gate C/D evaluation, `/feature.pr` command, post-merge lifecycle resolution |
| QA FAIL Loop | Product-manager integration (auto-backlog from QA findings), governance loop (backlog → spec → tasks → impl → QA), intelligent gate re-evaluation |
| Agreement Drift | Integration of existing repair cycle (doctor → implement → check) into V2 workflow |
| Backward Compat | Optional QA steps detection, graceful degradation for features without QA artifacts |

## Developer Tool Specific Requirements

### Project-Type Overview

Extension of the existing `feature-lifecycle` npm package. Installed via `npx tcsetup`, operated via Claude Code slash commands. Zero runtime dependencies, Node.js ESM only (>= 18).

### Technical Architecture Considerations

- **Runtime**: Node.js ESM (`"type": "module"`), imports via `node:` protocol only
- **Zero dependencies**: Regex-based YAML parsing, no external libraries. Conforms to ADR `20260218-esm-only-zero-deps`
- **Interface**: Claude Code slash commands (`.claude/commands/*.md`). New template: `/feature.pr`
- **State**: File-based. YAML + Markdown in `.features/`, `.agreements/`, `.qa/`, `.product/`, `specs/`
- **External CLI**: `gh` (GitHub CLI) for PR creation and merge detection

### Command Surface

| Command | Type | Description |
|---------|------|-------------|
| `/feature.workflow` | Updated | Extended dependency chain with QA + PR + post-merge steps |
| `/feature.pr {feature}` | New | Create GitHub PR with full traceability body |
| `/feature.workflow` (post-merge) | Updated | Post-merge lifecycle resolution triggers |

### Installation & Distribution

- Distributed as part of `feature-lifecycle` npm package
- Installed/updated via `npx tcsetup` (detects `.features/` marker directory)
- No migration needed — new steps are additive to existing workflow
- Backward compatible — features without QA artifacts skip new steps gracefully

### Implementation Considerations

- `/feature.pr` template reads from multiple artifact directories (`.features/`, `.agreements/`, `.qa/`, `.product/`, `specs/`) to compose the PR body
- Post-merge detection relies on `gh pr view --json state` — requires `gh` CLI authenticated
- The QA FAIL → product-manager loop requires reading `.qa/` findings and writing to `.product/backlogs/`
- Gate evaluation logic lives in the `/feature.workflow` slash command template (Markdown prompt)

## Functional Requirements

### Workflow Chain Management

- FR1: Developer can see QA Plan, QA Run, PR, and Post-Merge as steps in the `/feature.workflow` progress dashboard
- FR2: Developer can see Gate C status (tasks 100% required) in the workflow dashboard
- FR3: Developer can see Gate D status (QA PASS + Agreement Check PASS required) in the workflow dashboard
- FR4: System can evaluate Gate C by computing task completion from `tasks.md` checkboxes
- FR5: System can evaluate Gate D by reading QA verdict and agreement check verdict from their respective artifact files
- FR6: System can propose the correct next action based on the current gate and artifact state

### QA Verification Integration

- FR7: Developer can trigger `/qa.plan` as a workflow-proposed next step when Gate C is satisfied
- FR8: Developer can trigger `/qa.run` as a workflow-proposed next step when QA plan exists
- FR9: System can read QA verdict (PASS/FAIL) from `.qa/{feature}/test-results.md`
- FR10: System can display QA status (PASS/FAIL/pending) in the workflow progress dashboard

### PR Creation & Traceability

- FR11: Developer can create a GitHub PR with full traceability by running `/feature.pr {feature}`
- FR12: System can enforce prerequisites before PR creation (QA PASS, Agreement Check PASS, all tasks done)
- FR13: System can compose a PR body containing: spec link, agreement link, QA results summary, agreement check verdict, originating feedbacks, linked backlogs, git diff summary
- FR14: System can read originating feedbacks and linked backlogs from `.product/` and `.features/` artifacts
- FR15: System can create the PR via `gh pr create` with the composed body

### Post-Merge Lifecycle Resolution

- FR16: Developer can trigger post-merge resolution after PR is merged
- FR17: System can detect PR merge status via `gh pr view --json state`
- FR18: System can transition feature stage to "release" in `.features/{feature}.yaml`
- FR19: System can transition linked backlogs to "done" in `.product/backlogs/`
- FR20: System can transition originating feedbacks to "resolved" in `.product/feedbacks/`

### Governance Loop (QA FAIL Recovery)

- FR21: System can detect QA FAIL verdict and propose recovery action in the workflow
- FR22: System can auto-generate a critical backlog in `.product/backlogs/` from QA FAIL findings
- FR23: System can redirect the workflow to the backlog → spec → tasks → implementation → QA path after a FAIL
- FR24: System can re-evaluate gates after the governance loop completes (QA re-run)

### Backward Compatibility

- FR25: System can detect features without QA artifacts and display QA steps as optional in the dashboard
- FR26: Developer can use `/feature.workflow` on existing features (001-009) without errors or regressions
- FR27: System can skip QA-related gates for features that predate the V2 workflow

## Non-Functional Requirements

### Integration

- NFR1: System requires `gh` CLI installed and authenticated to create PRs and detect merge status
- NFR2: System must fail gracefully with a clear error message if `gh` CLI is not available or not authenticated
- NFR3: All artifact reads (`.features/`, `.agreements/`, `.qa/`, `.product/`, `specs/`) use filesystem scanning only — no external dependencies

### Correctness

- NFR4: State transitions must be all-or-nothing — if post-merge resolution fails midway, no partial state updates are left behind
- NFR5: Gate evaluation must always re-scan artifacts at query time — never rely on cached or stale state
- NFR6: PR body composition must include all traceability links that exist — missing optional artifacts (feedbacks, backlogs) result in "N/A", not errors

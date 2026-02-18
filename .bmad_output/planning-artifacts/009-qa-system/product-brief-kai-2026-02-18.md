---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments:
  - ".bmad_output/planning-artifacts/009-qa-system/vision-input.md"
  - ".knowledge/guides/project-philosophy.md"
  - ".knowledge/guides/create-new-package.md"
date: 2026-02-18
author: tcanaud
---

# Product Brief: kai — QA System (009)

## Executive Summary

The kai governance loop currently ends at implementation. After `/speckit.implement` completes tasks, there is no automated verification that acceptance criteria are met, no feedback loop back into the product pipeline, and no gate before code reaches main. The QA System closes this gap.

It is a file-based, reproducible testing system that generates executable test scripts from existing specifications and agreements. Tests are real artifacts — shell scripts, JS files, or whatever fits the project — stored in `.qa/`, versioned in git, and traceable back to the acceptance criteria they verify. When tests discover non-blocking issues, those findings flow automatically into `.product/inbox/` with full context (test script paths, execution results), giving the next actor in the loop everything they need to understand and act.

The QA System does not replace `/agreement.check` — it calls it and builds on top of it. Agreement check verifies interface contracts; QA verifies that the feature works end-to-end from the user's perspective.

---

## Core Vision

### Problem Statement

After a feature is implemented in kai, there is no systematic way to verify that it works as specified. The developer marks tasks as done, but nothing validates that acceptance criteria from `spec.md` are satisfied or that the code matches the promises in `agreement.yaml`. The only verification available is `/agreement.check`, which is limited to interface-level drift detection — it does not test behavior.

This creates a trust gap: the system tracks what was promised and what was built, but not whether what was built actually works.

### Problem Impact

- Features ship without verified acceptance criteria — regressions go undetected
- No feedback loop from verification back to product — discoveries during testing are lost
- Developers must manually verify each criterion — error-prone and unreproducible
- No traceable evidence of what was tested — impossible to audit quality after the fact

### Why Existing Solutions Fall Short

Traditional test frameworks (jest, pytest, vitest) solve a different problem — they test code units, not product promises. They require manual test authoring disconnected from the governance pipeline. CI/CD test suites don't know about spec.md, agreement.yaml, or feature lifecycle stages. They can't feed findings back into `.product/inbox/`. And they don't consult `.knowledge/` to understand the project's testing conventions.

`/agreement.check` is closer but only detects interface drift (removed endpoints, changed schemas). It doesn't verify that a CLI command actually produces the right output, or that a workflow completes end-to-end.

### Proposed Solution

A new kai module (`@tcanaud/qa-system`) that:

1. **Reads the project's knowledge base** (`.knowledge/`) to understand the development environment, testing conventions, and technical stack before writing any test
2. **Generates executable test scripts** from `spec.md` acceptance criteria and `agreement.yaml` interfaces — scripts adapted to the project, not generic boilerplate
3. **Persists tests as git-versioned artifacts** in `.qa/{feature}/scripts/` — reusable across QA cycles, refinable over time
4. **Executes tests and produces a binary verdict** (PASS/FAIL) with per-script granularity
5. **Feeds non-blocking findings** into `.product/inbox/` with traceable links to test scripts and results
6. **Tracks freshness** — detects when specs or agreements change and flags test plans as stale

### Key Differentiators

- **Governance-native**: tests are derived from specs and agreements, not written in isolation
- **Project-aware**: consults `.knowledge/` to produce idiomatic, relevant tests
- **Self-feeding**: findings flow into the product pipeline automatically
- **Reproducible**: scripts are artifacts — anyone can re-run `/qa.run` and get the same verdict
- **Incremental**: first pass generates tests, subsequent passes refine them

## Target Users

### Primary Users

**The Feature Developer ("Alex")**

Alex is a solo developer or tech lead working on a kai-governed project. After implementing a feature through `/speckit.implement`, Alex needs confidence that the acceptance criteria are met before creating a PR. Today, Alex manually spot-checks behavior — running CLI commands, eyeballing output, comparing against the spec. This is slow, unreproducible, and leaves no trace.

With the QA System, Alex runs `/qa.plan 009-qa-system` once to generate executable test scripts, then `/qa.run 009-qa-system` to get a binary verdict. If tests pass, Alex proceeds to PR creation knowing that every acceptance criterion has been mechanically verified. If tests fail, the failure output points to exactly which criterion broke and in which script — no guessing.

**Key motivations:**
- Ship features with confidence, not hope
- Have reproducible evidence that the feature works
- Get actionable feedback when something breaks — not just "FAIL" but "this script, this assertion, this expected vs actual"
- Not spend time writing test infrastructure from scratch — the QA system generates it from artifacts that already exist

### Secondary Users

**The Reviewer/Contributor ("Sam")**

Sam joins a project mid-flight or reviews a PR from Alex. Sam doesn't know the codebase intimately but needs to understand what was verified and how. Sam reads `.qa/{feature}/scripts/` to see the actual test logic, `_index.yaml` to understand which spec criteria each test covers, and `results/` to see what passed or failed.

When a QA finding becomes a feedback in `.product/inbox/`, Sam (or any future developer) can follow the traceability chain: feedback → test script → test result → acceptance criterion → spec.md. Full context without asking anyone.

**Key motivations:**
- Understand what was tested without reading the entire codebase
- Trust that the PR has been mechanically verified
- Have enough context to act on findings without tribal knowledge

## Success Metrics

### User Success
- **Coverage rate**: % of acceptance criteria in spec.md that have a corresponding test script in `.qa/{feature}/scripts/` — target: 100% on first `/qa.plan`
- **Verdict reliability**: when `/qa.run` says PASS, zero regressions discovered post-merge — target: <5% false positive rate
- **Feedback actionability**: every non-blocking finding deposited in `.product/inbox/` includes script path + result link — target: 100% traceability

### Business Objectives
- **Loop closure**: the kai governance loop has no open ends — every feature that passes through the workflow gets mechanically verified before reaching main
- **Adoption friction**: a developer can go from `/speckit.implement` done → `/qa.plan` → `/qa.run` → verdict in a single session with no manual setup
- **Incremental value**: first `/qa.plan` produces useful tests immediately — no "configure your test framework" step

### Key Performance Indicators

| KPI | Measurement | Target |
|-----|-------------|--------|
| Criteria coverage | test scripts / acceptance criteria | 100% |
| Freshness accuracy | stale detections match actual spec changes | 100% |
| Finding-to-feedback rate | findings deposited / findings discovered | 100% |
| Re-run stability | same scripts, same code → same verdict | 100% |
| Time to first verdict | from `/qa.plan` to first PASS/FAIL | < 1 session |

---

## MVP Scope

### Core Features (MVP)

**F1 — `/qa.plan {feature}`**
Generates executable test scripts from `spec.md` acceptance criteria and `agreement.yaml` interfaces. Before writing any script, the system:
1. Consults `.knowledge/` to understand the project's dev environment, testing conventions, and tech stack
2. Runs `/agreement.check {feature}` and incorporates results
3. Explores the codebase to understand existing patterns and entry points (playground phase)
4. Writes scripts adapted to the project — not generic boilerplate

Scripts are stored in `.qa/{feature}/scripts/`, indexed in `.qa/{feature}/_index.yaml` with per-criterion traceability and source checksums for freshness tracking.

**F2 — `/qa.run {feature}`**
Executes all test scripts for a feature and produces a binary PASS/FAIL verdict with per-script granularity. On completion:
- **Blocking failures** (acceptance criterion not satisfied) → FAIL verdict, developer must fix
- **Non-blocking findings** (drift, improvement, edge case) → deposited in `.product/inbox/` as structured feedback with test script path and execution results

Results are persisted in `.qa/{feature}/results/` for auditability.

**F3 — `/qa.check`**
Checks test plan freshness across all features by comparing stored checksums (`spec.md` SHA, `agreement.yaml` SHA) against current file hashes. Flags stale test plans that need regeneration before `/qa.run` can be trusted.

**F4 — Package `@tcanaud/qa-system`**
A new kai module following the established git submodule pattern: zero runtime dependencies, `node:` protocol imports only, Claude Code slash commands as interface, file-based artifacts (Markdown + YAML frontmatter).

### Out of Scope (MVP)

- **Integration QA** — cross-feature or full-system test suites (deferred to v2)
- **CI/CD integration** — automated QA runs in pipelines (future)
- **Coverage visualization** — dashboards or reports beyond the text-based verdict
- **Auto-fix** — automatically correcting code when tests fail
- **Custom test templates** — user-defined test scaffolding (the system generates from knowledge + spec)

### MVP Success Criteria

1. `/qa.plan` generates at least one executable test script per acceptance criterion in `spec.md`
2. `/qa.run` produces a deterministic PASS/FAIL verdict — same scripts + same code = same result
3. Non-blocking findings are deposited in `.product/inbox/` with script path and result link
4. `/qa.check` correctly detects stale test plans when `spec.md` or `agreement.yaml` changes
5. A developer can go from `/speckit.implement` done → `/qa.plan` → `/qa.run` → verdict with no manual test setup

### Future Vision

- **Integration QA (v2)**: cross-feature test suites that verify feature combinations and system-wide behavior
- **CI gate**: `/qa.run` as a required check in CI pipelines before merge
- **Test evolution tracking**: version test scripts alongside code, track which criteria changed between QA cycles
- **QA dashboard**: visual overview of test coverage, freshness status, and historical verdict trends across all features

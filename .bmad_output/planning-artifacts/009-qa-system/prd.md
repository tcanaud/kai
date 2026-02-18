---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain-skipped, step-06-innovation-skipped, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish]
inputDocuments:
  - ".bmad_output/planning-artifacts/009-qa-system/product-brief-kai-2026-02-18.md"
  - ".bmad_output/planning-artifacts/009-qa-system/vision-input.md"
  - ".knowledge/guides/project-philosophy.md"
  - ".knowledge/guides/create-new-package.md"
workflowType: 'prd'
date: 2026-02-18
author: tcanaud
classification:
  projectType: developer_tool
  domain: general
  complexity: medium
  projectContext: brownfield
---

# Product Requirements Document — kai QA System (009)

**Author:** tcanaud
**Date:** 2026-02-18

## Executive Summary

The kai governance pipeline tracks features from feedback through specification, agreement, and implementation — but stops at "tasks done." Nothing mechanically verifies that acceptance criteria from `spec.md` are satisfied, that behavior matches the promises in `agreement.yaml`, or that implementation discoveries feed back into the product pipeline. The QA System (`@tcanaud/qa-system`) closes this gap.

It generates executable test scripts — shell scripts, JS files, or whatever fits the target project — directly from existing specifications and agreements. Before writing any test, it consults the project's `.knowledge/` base to understand the development environment, testing conventions, and tech stack. Scripts are stored as git-versioned artifacts in `.qa/{feature}/`, reusable across QA cycles and refinable over time. `/qa.run` produces a binary PASS/FAIL verdict with per-script granularity: blocking failures stop the developer, non-blocking findings (drift, improvements, edge cases) flow automatically into `.product/inbox/` with full traceability.

The primary user is the feature developer who needs confidence that acceptance criteria are met before PR creation. The secondary user is the reviewer who needs to understand what was verified, how, and with what results — without tribal knowledge.

### What Makes This Special

The QA System is not another test framework. Traditional testing tools (jest, pytest, vitest) test code units disconnected from the governance pipeline — they don't know about `spec.md`, `agreement.yaml`, or feature lifecycle stages. The QA System is **governance-native**: tests are derived from the promises already made in the pipeline, not written in isolation.

Three differentiators set it apart:
1. **Project-aware**: consults `.knowledge/` to produce idiomatic, relevant tests adapted to each project's stack and conventions — not generic boilerplate
2. **Self-feeding**: non-blocking findings flow into `.product/inbox/` automatically, closing the feedback loop without manual intervention
3. **Artifact-based**: test scripts are real files — versioned, reproducible, auditable. First `/qa.plan` produces useful tests immediately with zero framework setup

The core insight: trust in a governance system requires mechanical verification. kai currently says "here's what was promised and built" but not "and it works." The QA System adds that missing proof.

## Project Classification

- **Project Type:** Developer Tool — npm package exposing Claude Code slash commands (`/qa.plan`, `/qa.run`, `/qa.check`)
- **Domain:** General — software development governance tooling, no industry-specific compliance
- **Complexity:** Medium — integration with 8 existing kai modules, knowledge-aware test generation, freshness tracking via checksums, automated feedback pipeline
- **Project Context:** Brownfield — new module integrating into an established ecosystem with proven conventions (git submodule pattern, `node:` protocol imports, file-based artifacts)

## Success Criteria

### User Success

- **Criteria coverage**: every acceptance criterion in `spec.md` has a corresponding executable test script in `.qa/{feature}/scripts/` after first `/qa.plan` — target: 100%
- **Verdict confidence**: when `/qa.run` says PASS, zero regressions are discovered post-merge — target: <5% false positive rate
- **Time to verdict**: a developer goes from `/speckit.implement` done → `/qa.plan` → `/qa.run` → PASS/FAIL in a single session with no manual setup
- **Failure actionability**: when a test fails, the output identifies the exact script, assertion, and expected-vs-actual — no guessing required
- **Feedback traceability**: every non-blocking finding deposited in `.product/inbox/` includes the test script path, execution result, and link to the acceptance criterion it relates to — target: 100%

### Business Success

- **Loop closure**: the kai governance loop has no open ends — every feature that passes through the workflow gets mechanically verified before reaching main
- **Zero adoption friction**: no "configure your test framework" step. First `/qa.plan` produces useful, executable tests immediately
- **Incremental refinement**: test scripts improve across QA cycles without starting from scratch — second `/qa.plan` on the same feature refines existing scripts rather than regenerating

### Technical Success

- **Deterministic verdicts**: same scripts + same code = same PASS/FAIL result — `/qa.run` is reproducible
- **Freshness accuracy**: `/qa.check` correctly detects 100% of stale test plans when `spec.md` or `agreement.yaml` changes (checksum comparison)
- **Zero runtime dependencies**: package follows kai convention — `node:` protocol imports only, no third-party dependencies
- **Ecosystem integration**: `/qa.run` calls `/agreement.check` and incorporates results; findings flow to `.product/inbox/` using product-manager's existing format

### Measurable Outcomes

| Outcome | Metric | Target |
|---------|--------|--------|
| Criteria coverage | test scripts / acceptance criteria | 100% |
| Freshness detection | stale detections matching actual spec changes | 100% |
| Finding-to-feedback | findings deposited / findings discovered | 100% |
| Re-run stability | identical verdicts on identical inputs | 100% |
| Time to first verdict | `/qa.plan` → first PASS/FAIL | < 1 session |
| False positive rate | regressions found post-PASS | < 5% |

## User Journeys

### Journey 1 — Alex: First QA Run (Success Path)

Alex finishes implementing `009-qa-system` via `/speckit.implement`. All tasks are checked off in `tasks.md`, but there is no mechanical proof that acceptance criteria from `spec.md` are satisfied. He runs `/feature.workflow 009-qa-system` — the dashboard shows QA as the next step.

**`/qa.plan 009-qa-system`** — The system loads `spec.md` and `agreement.yaml`, runs `/agreement.check` in the background, then consults `.knowledge/` to discover the project uses Node.js ESM, tests run via shell scripts, and the convention is `node:test` for assertions. After a playground phase (exploring source code, CLI entry points), it generates 12 test scripts in `.qa/009-qa-system/scripts/`, a `_index.yaml` mapping each script to an acceptance criterion, and stores source checksums.

**`/qa.run 009-qa-system`** — All 12 scripts execute. 10 pass. 2 fail: `test-freshness-detection.sh` (SHA checksum not recalculated when `agreement.yaml` changes) and `test-finding-deposit.sh` (finding missing the `script_path` field). Verdict: **FAIL** with a clear report — script, assertion, expected vs actual.

Alex fixes both bugs, reruns `/qa.run 009-qa-system`. 12/12 PASS. One non-blocking finding is deposited in `.product/inbox/`: "edge case — `/qa.check` does not handle the case where `.qa/{feature}/` does not exist yet." Alex is ready for PR creation.

**Capabilities revealed**: knowledge consultation, script generation, script execution, verdict reporting, finding deposit, freshness tracking

### Journey 2 — Alex: Stale Tests (Edge Case)

Three weeks after `009-qa-system` ships, Alex modifies `spec.md` to add a new acceptance criterion. He runs `/qa.run 009-qa-system` — the system detects that `_index.yaml` stores a different SHA than the current `spec.md`. It refuses to execute: **"Test plan is stale. Run `/qa.plan 009-qa-system` to regenerate."**

Alex runs `/qa.plan`. The system detects 12 existing scripts. It does not delete them — it keeps them as a base, adds a 13th script for the new criterion, and updates `_index.yaml` with new checksums. `/qa.run` passes. Confidence intact.

**Capabilities revealed**: freshness detection, incremental script generation, stale plan rejection

### Journey 3 — Sam: PR Review (Reviewer Path)

Sam receives Alex's PR for `009-qa-system`. He does not know the code intimately, but the PR body points to `.qa/009-qa-system/`. Sam opens `_index.yaml`: he sees the list of 12 scripts, each mapped to an acceptance criterion from `spec.md`. He opens `results/`: last run PASS, 12/12, with timestamp.

Sam spot-checks one script — `test-cli-qa-plan.sh`. The script installs the package in a temp directory, executes `/qa.plan` on a test feature, and verifies that scripts are generated. It is readable and reproducible. Sam can rerun `./test-cli-qa-plan.sh` locally to verify.

He also sees a finding deposited in `.product/inbox/` linked to the run. He understands the full context without asking anyone. Approve.

**Capabilities revealed**: result persistence, traceability chain (script → criterion → spec), script readability, local re-run

### Journey 4 — Alex: QA Check Across Features (Operations)

The kai project now has 5 features with `.qa/` directories. Alex wants to know if test plans are up to date before a global release. He runs `/qa.check`.

The system scans all `_index.yaml` files, compares stored checksums with current files. Result:
- `007-knowledge-system`: **current** ✓
- `008-product-manager`: **stale** — `spec.md` changed
- `009-qa-system`: **current** ✓
- `010-feature-lifecycle-v2`: **current** ✓
- `011-ci-integration`: **stale** — `agreement.yaml` changed

Alex knows exactly what to regenerate. Two `/qa.plan` runs and it is resolved.

**Capabilities revealed**: cross-feature freshness scan, batch status reporting

### Journey Requirements Summary

| Capability | Journeys | Priority |
|-----------|----------|----------|
| Knowledge base consultation (`.knowledge/`) | J1 | MVP |
| Script generation from spec + agreement | J1, J2 | MVP |
| Script execution with per-script verdict | J1 | MVP |
| PASS/FAIL binary verdict | J1 | MVP |
| Failure detail (script, assertion, expected/actual) | J1 | MVP |
| Non-blocking finding deposit to `.product/inbox/` | J1, J3 | MVP |
| Freshness tracking via checksums | J2, J4 | MVP |
| Stale plan rejection (refuse to run) | J2 | MVP |
| Incremental script refinement | J2 | MVP |
| Result persistence in `results/` | J3 | MVP |
| Traceability index (`_index.yaml`) | J1, J3 | MVP |
| Cross-feature freshness scan (`/qa.check`) | J4 | MVP |

## Developer Tool Specific Requirements

### Project-Type Overview

The QA System is a kai ecosystem package that exposes its functionality exclusively through Claude Code slash commands. It is not a traditional CLI tool or library with a programmatic API — it is an AI-native developer tool where the interface is natural language commands processed by Claude Code, backed by file-based artifacts.

### Language & Runtime

| Aspect | Detail |
|--------|--------|
| Package runtime | Node.js ESM (>= 18.0.0), `"type": "module"` |
| Dependencies | Zero runtime — `node:` protocol imports only |
| Generated test scripts | Adapt to target project's stack (discovered via `.knowledge/`) |
| Script languages | Shell (bash), JavaScript (node:test), or whatever the project uses |

The package itself is pure Node.js. The test scripts it generates are project-aware — a Rust project gets different scripts than a Node.js project, guided by `.knowledge/` consultation.

### Installation & Distribution

| Method | Detail |
|--------|--------|
| Distribution | git submodule under `packages/qa-system/` |
| npm scope | `@tcanaud/qa-system` |
| Install command | `npx @tcanaud/qa-system install` |
| Update command | `npx @tcanaud/qa-system update` |
| Artifacts installed | Slash command templates to `.claude/commands/` |

Follows the established kai package pattern: installer copies command templates, no runtime process.

### API Surface (Slash Commands)

| Command | Input | Output | Side Effects |
|---------|-------|--------|-------------|
| `/qa.plan {feature}` | feature ID | Test scripts in `.qa/{feature}/scripts/`, `_index.yaml` | Reads `.knowledge/`, `spec.md`, `agreement.yaml`; runs `/agreement.check` |
| `/qa.run {feature}` | feature ID | PASS/FAIL verdict, `results/` | Deposits non-blocking findings in `.product/inbox/` |
| `/qa.check` | (none) | Freshness report across all features | Read-only |

No programmatic API. No exported functions. The slash commands ARE the interface.

### Documentation Strategy

| Artifact | Purpose |
|----------|---------|
| Slash command prompts | Self-documenting — the prompt template IS the documentation |
| `.knowledge/` guide | `qa-system.md` — conventions for QA in kai projects |
| `_index.yaml` | Per-feature test plan with traceability metadata |
| `results/` | Per-run verdict with script-level detail |

No separate docs site, no API reference. The tool is self-describing through its file artifacts.

### Implementation Considerations

- **No migration guide needed** — this is a new capability, not a replacement for an existing one
- **No code examples in traditional sense** — the tool generates scripts, it doesn't expose a library for users to call
- **Backward compatibility** — projects without `.qa/` directories work normally; QA is opt-in per feature
- **File format stability** — `_index.yaml` and `results/` formats are the implicit contract; changes require versioning

## Product Scope

### MVP Strategy & Philosophy

**MVP Approach:** Problem-solving MVP — deliver the minimum that closes the governance loop gap. If a developer can run `/qa.plan` then `/qa.run` and get a trustworthy PASS/FAIL verdict, the core problem is solved.

**Resource Requirements:** Solo developer (the kai project pattern). No team coordination overhead. The package follows established conventions — structure, installer, command templates — reducing scaffolding work.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
- J1 — First QA Run (success path): full `/qa.plan` → `/qa.run` → verdict cycle
- J2 — Stale Tests (edge case): freshness detection and incremental regeneration
- J4 — QA Check (operations): cross-feature freshness scan

**Must-Have Capabilities:**

| # | Capability | Rationale |
|---|-----------|-----------|
| 1 | `.knowledge/` consultation before script generation | Without this, scripts are generic boilerplate — not the differentiator |
| 2 | Script generation from `spec.md` + `agreement.yaml` | Core value — governance-native tests |
| 3 | Script execution with per-script PASS/FAIL | The verdict mechanism |
| 4 | Binary aggregate verdict (PASS/FAIL) | Gate for PR creation (010 integration) |
| 5 | Failure detail (script, assertion, expected/actual) | Actionable failures — not just "FAIL" |
| 6 | Finding deposit to `.product/inbox/` | Self-feeding loop closure |
| 7 | `_index.yaml` with traceability + checksums | Freshness tracking + auditability |
| 8 | Stale plan detection and rejection | Prevents running outdated tests |
| 9 | Cross-feature `/qa.check` | Operational hygiene |
| 10 | Package scaffolding (installer, update, commands) | Distribution mechanism |

**Explicitly NOT in MVP:**
- Incremental script refinement (J2 detail) — first version can regenerate entirely; refinement is a v1.1 optimization
- Result persistence in structured `results/` directory — first version can output to stdout; persistence is v1.1

### Post-MVP Features

**Phase 2 (Growth):**
- Incremental script refinement — detect existing scripts, keep passing ones, regenerate only failing/new
- Structured `results/` persistence — timestamped result files for audit trail
- Verdict history — track PASS/FAIL trends per feature
- Test refinement UX — guided flow when specs change

**Phase 3 (Expansion):**
- Integration QA (v2) — cross-feature test suites
- CI gate — `/qa.run` as required CI check
- Test evolution tracking — diff between QA cycles
- QA dashboard — visual coverage and verdicts

### Risk Mitigation Strategy

**Technical Risks:**
- *Script generation quality depends on Claude Code's understanding of the target project* — Mitigation: `.knowledge/` consultation + playground phase gives Claude maximum context before writing scripts. If generation quality is poor, the scripts are visible artifacts that users can manually refine.
- *Freshness tracking via SHA may produce false stale warnings on trivial spec changes (whitespace, comments)* — Mitigation: accept this for MVP. Content-aware diffing is a v2 optimization.

**Market Risks:**
- *Developers may not trust AI-generated test scripts* — Mitigation: scripts are transparent, readable artifacts. Users can inspect, modify, and re-run them. The system produces evidence, not magic.
- *The value is unclear if the project doesn't use kai governance* — Mitigation: this is intentionally kai-ecosystem-only. Not a general-purpose tool.

**Resource Risks:**
- *Solo developer project — bus factor of 1* — Mitigation: all kai packages follow the same pattern. Any developer familiar with one package can maintain another.
- *Scope creep from "just one more feature"* — Mitigation: the Must-Have table above is the boundary. Anything not in it waits for Phase 2.

## Functional Requirements

### Test Plan Generation

- **FR1**: Developer can generate executable test scripts for a feature by running `/qa.plan {feature}`
- **FR2**: The system can read `.knowledge/` guides to discover the target project's development environment, testing conventions, and tech stack before generating any script
- **FR3**: The system can run `/agreement.check {feature}` and incorporate its results into the test planning context
- **FR4**: The system can explore the target codebase (entry points, CLI commands, module structure) during a playground phase before writing scripts
- **FR5**: The system can read `spec.md` acceptance criteria and generate at least one test script per criterion
- **FR6**: The system can read `agreement.yaml` interfaces and generate test scripts that verify interface compliance
- **FR7**: Developer can find all generated scripts in `.qa/{feature}/scripts/` as executable files (shell, JS, or project-appropriate format)
- **FR8**: The system can produce a `_index.yaml` file that maps each script to the acceptance criterion it verifies

### Freshness Tracking

- **FR9**: The system can store checksums (SHA) of source files (`spec.md`, `agreement.yaml`) in `_index.yaml` at generation time
- **FR10**: The system can compare stored checksums against current file hashes to determine if a test plan is stale
- **FR11**: The system can refuse to execute a stale test plan and direct the developer to regenerate via `/qa.plan`
- **FR12**: Developer can check freshness across all features by running `/qa.check`
- **FR13**: The system can report per-feature freshness status (current/stale) with the specific source file that changed

### Test Execution & Verdict

- **FR14**: Developer can execute all test scripts for a feature by running `/qa.run {feature}`
- **FR15**: The system can execute each script independently and capture its PASS/FAIL result
- **FR16**: The system can produce a binary aggregate verdict (PASS if all scripts pass, FAIL if any script fails)
- **FR17**: The system can report per-script results including script name, status, and failure details (assertion, expected vs actual)

### Finding Management

- **FR18**: The system can distinguish blocking failures (acceptance criterion not met) from non-blocking findings (drift, improvement, edge case)
- **FR19**: The system can deposit non-blocking findings as structured feedback files in `.product/inbox/`
- **FR20**: Each deposited finding can include the test script path, execution result, and link to the related acceptance criterion
- **FR21**: Deposited findings can follow the product-manager feedback format so `/product.triage` can process them

### Traceability & Auditability

- **FR22**: Reviewer can read `_index.yaml` to understand which acceptance criteria are covered by which scripts
- **FR23**: Reviewer can read any test script and understand what it verifies without external context
- **FR24**: Reviewer can follow the traceability chain: finding → script → result → criterion → spec.md

### Package Lifecycle

- **FR25**: Developer can install the QA system into a kai project via `npx @tcanaud/qa-system install`
- **FR26**: The installer can copy slash command templates to `.claude/commands/`
- **FR27**: Developer can update the QA system via `npx @tcanaud/qa-system update`
- **FR28**: The package can operate with zero runtime dependencies (`node:` protocol imports only)

## Non-Functional Requirements

### Reproducibility

- **NFR1**: Given identical test scripts and identical code state, `/qa.run` must produce the same PASS/FAIL verdict on every execution
- **NFR2**: Test scripts must be self-contained — executable by any developer with access to the repository, without environment-specific setup beyond what `.knowledge/` documents
- **NFR3**: `_index.yaml` checksums must use a deterministic hash algorithm (SHA-256) producing identical hashes for identical file content regardless of platform

### Integration Compatibility

- **NFR4**: `/qa.plan` must read `.knowledge/` without modifying any knowledge files
- **NFR5**: `/qa.run` must call `/agreement.check` without modifying any agreement files
- **NFR6**: Findings deposited in `.product/inbox/` must conform to the product-manager feedback YAML frontmatter schema (fields: `id`, `title`, `category`, `source`, `created`, `linked_to`)
- **NFR7**: The `.qa/` directory structure must not conflict with any existing kai artifact directories (`.agreements/`, `.features/`, `.knowledge/`, `.product/`, `.adr/`)

### Ecosystem Conventions

- **NFR8**: Package must use `node:` protocol imports exclusively — zero third-party runtime dependencies
- **NFR9**: Package must follow the kai installer pattern: `install` copies command templates, `update` replaces them, no persistent runtime process
- **NFR10**: All generated artifacts (scripts, `_index.yaml`, results) must be valid for git version control — no binary blobs, no files exceeding 100KB
- **NFR11**: Command templates must be compatible with Claude Code's slash command loading mechanism

### Graceful Degradation

- **NFR12**: If `.knowledge/` is empty or missing, `/qa.plan` must still generate tests (less project-specific, but functional)
- **NFR13**: If `/agreement.check` fails or no agreement exists, `/qa.plan` must still proceed using `spec.md` alone
- **NFR14**: If `.product/` directory does not exist, `/qa.run` must still produce a verdict but skip finding deposit (with a warning)

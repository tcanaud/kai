# Research: QA System (009)

**Feature**: 009-qa-system | **Date**: 2026-02-18

## R1: Two-Layer Architecture (Package + Slash Commands)

**Decision**: Follow the established kai pattern — an npm package (`@tcanaud/qa-system`) handles installation and template management, while Claude Code slash commands handle all runtime behavior (test generation, execution, freshness checking).

**Rationale**: Every kai module since 006 uses this pattern. The package is a delivery mechanism (installer/updater); the slash commands are the interface. This means the "test generation engine" is Claude Code itself — guided by the prompt template and `.knowledge/` context. No custom generation logic needed in Node.js.

**Alternatives considered**:
- Monolithic CLI with programmatic test generation — rejected because it would require building a template engine, AST manipulation, or code generation pipeline. Claude Code already does this better by understanding the codebase directly.
- Pure slash commands without npm package — rejected because it eliminates the standardized install/update mechanism and makes distribution inconsistent with other kai modules.

## R2: Filesystem Layout for `.qa/`

**Decision**: Flat per-feature structure: `.qa/{feature}/scripts/` for scripts, `.qa/{feature}/_index.yaml` for metadata. No status-based subdirectories.

**Rationale**: Unlike `.product/` (which uses status-based directories like `feedbacks/new/`, `feedbacks/triaged/`), test scripts don't transition through statuses. A script exists or it doesn't. The `_index.yaml` file provides all the metadata needed. Simpler is better — no directory moves, no state machine.

**Alternatives considered**:
- Status-based directories (`.qa/{feature}/scripts/passing/`, `.qa/{feature}/scripts/failing/`) — rejected because script status is a property of the last run, not of the script file. Moving files between directories on every run is fragile and adds complexity.
- Central scripts directory (`.qa/scripts/{feature}/`) — rejected because it separates scripts from their index, making per-feature operations harder.

## R3: _index.yaml Schema Design

**Decision**: Single YAML file per feature containing: generation metadata (timestamp, generator version), source checksums (SHA-256 of spec.md and agreement.yaml), and a scripts array with per-script entries (filename, criterion reference, criterion text, type).

**Rationale**: One file captures everything a reviewer or tool needs. Checksums enable freshness checks. Criterion references enable traceability. The array structure supports iteration and counting.

**Alternatives considered**:
- JSON format — rejected because YAML is the kai standard for structured metadata (all other modules use YAML frontmatter or pure YAML).
- Multiple metadata files (checksums.yaml, mappings.yaml) — rejected because it splits related data and requires multiple reads for any operation.

## R4: Checksum Algorithm — SHA-256

**Decision**: Use SHA-256 via `node:crypto` for all freshness tracking checksums.

**Rationale**: Available natively in Node.js (zero dependencies). Deterministic across platforms. Collision probability negligible. Matches the NFR3 requirement from the PRD.

**Alternatives considered**:
- MD5 — rejected because it's cryptographically broken (though collision resistance isn't critical here, SHA-256 costs the same and is the better default).
- Content-aware hashing (strip whitespace/comments before hashing) — rejected for MVP. Adds parsing complexity and language-specific logic. Accept false stale warnings on trivial changes.

## R5: Finding Deposit Strategy

**Decision**: Deposit non-blocking findings as Markdown files with YAML frontmatter in `.product/inbox/`, using the product-manager feedback schema. The `/qa.run` command writes findings directly — no intermediary.

**Rationale**: The product-manager already monitors `.product/inbox/` and `/product.triage` processes it. By conforming to the existing schema, QA findings enter the feedback pipeline with zero changes to product-manager. The `source: "qa-system"` field enables filtering.

**Alternatives considered**:
- Custom finding format in `.qa/{feature}/findings/` — rejected because it creates a parallel feedback system that doesn't integrate with the product pipeline. The whole point is loop closure.
- API call to product-manager — rejected because there is no API. Product-manager uses filesystem-as-state.

## R6: Script Generation Strategy

**Decision**: The `/qa.plan` slash command prompt instructs Claude Code to generate scripts through a multi-phase process: (1) read `.knowledge/` for project context, (2) read spec.md and agreement.yaml, (3) explore the codebase, (4) generate one script per acceptance criterion, (5) write `_index.yaml`.

**Rationale**: Claude Code is the generation engine. The prompt template encodes the process, not code logic. This leverages Claude Code's ability to read project files, understand conventions, and write idiomatic test code. No template engine can match this adaptability.

**Alternatives considered**:
- Template-based generation with placeholders — rejected because it produces generic boilerplate. A shell script template with `{{ASSERTION}}` placeholders cannot understand that a Node.js project should use `node:test` while a Rust project should use `cargo test`.
- Rule-based generation (if Node → use node:test, if Rust → use cargo test) — rejected because the rule set would be incomplete and brittle. `.knowledge/` consultation via Claude Code is more flexible.

## R7: Stale Plan Rejection Behavior

**Decision**: When `/qa.run` detects a stale test plan (checksum mismatch), it refuses to execute and prints a message directing the developer to run `/qa.plan {feature}` to regenerate. Hard stop, no bypass.

**Rationale**: Running stale tests against changed specs gives false confidence. The verdict would be meaningless because it verifies outdated criteria. A hard stop forces regeneration, ensuring the verdict always matches the current spec.

**Alternatives considered**:
- Warning but continue — rejected because it undermines the trust guarantee. If the system warns but runs anyway, developers will ignore warnings.
- Auto-regenerate on stale detection — rejected for MVP. Auto-regeneration is a UX optimization that adds complexity (what if regeneration fails? what about partial changes?). Explicit `/qa.plan` invocation keeps the developer in control.

## R8: Installer Scope — Minimal Scaffold

**Decision**: The installer creates only the `.qa/` root directory and installs slash command templates. It does NOT create per-feature directories, index files, or scaffolding templates.

**Rationale**: Per-feature directories are created by `/qa.plan` when the developer first generates a test plan. Pre-creating directories for features that may never be QA'd adds clutter. The installer's job is to make the commands available — the commands do the work.

**Alternatives considered**:
- Full scaffold with per-feature directories for all registered features — rejected because features may not be ready for QA. Scaffolding should happen on demand.
- No installer at all (commands are manually placed) — rejected because it breaks the kai convention of package-managed command installation.

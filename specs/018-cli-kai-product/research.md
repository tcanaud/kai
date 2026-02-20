# Research: CLI Atomique @tcanaud/kai-product

**Phase**: 0 | **Feature**: 018-cli-kai-product | **Date**: 2026-02-20

## Research Questions Resolved

All items from Technical Context were deterministic given the existing codebase. No external research was required — findings come from direct inspection of `/packages/playbook/` and the `.product/` directory.

---

## Decision 1: Package Structure

**Decision**: Standalone package `packages/kai-product/` in the monorepo, following the `@tcanaud/playbook` package layout exactly.

**Rationale**: The spec (FR-014) mandates the `@tcanaud/playbook` pattern (`init` / `update`). Inspecting `/packages/playbook/` confirms the exact layout: `bin/cli.js` router, `src/` modules, `templates/` for slash commands. A separate package avoids coupling to playbook's session/worktree logic and allows independent versioning and publishing.

**Alternatives considered**:
- Integrating into `@tcanaud/playbook`: Rejected — would add product domain knowledge to a workflow orchestration package, coupling unrelated concerns and complicating the playbook package's single responsibility.
- Monolithic single-file script: Rejected — five commands + shared parser + tests would make a single file unmanageable and untestable.

---

## Decision 2: YAML Frontmatter Parsing Strategy

**Decision**: Regex-based custom parser (same approach as `packages/playbook/src/yaml-parser.js`), specialized for the `.product/` schema vocabulary.

**Rationale**: The zero-dependency constraint (FR-013) forbids `js-yaml` or any npm parser. The existing `yaml-parser.js` in `@tcanaud/playbook` demonstrates a proven, production-ready regex-based approach that handles the known vocabulary (key-value scalars, block lists, inline lists). The `.product/` schema is similarly closed-set and well-defined.

**Frontmatter parsing approach**:
1. Split on `---` delimiters to extract frontmatter block
2. Parse key: value lines with regex `matchKeyValue`
3. Parse list items with regex `matchListItem`
4. Handle nested objects (e.g., `linked_to.backlog[]`) with indent tracking

**Alternatives considered**:
- Using `node:vm` to evaluate YAML as JS: Rejected — unsafe and incorrect
- Shipping a vendored copy of `js-yaml`: Rejected — violates zero-dependency spirit and adds maintenance burden
- Using the existing playbook `yaml-parser.js` directly: Rejected — it is tightly coupled to the playbook schema (validates autonomy values, step fields, etc.); a shared generic parser would require significant refactoring of that module

---

## Decision 3: index.yaml Generation

**Decision**: Full-scan regeneration on every mutation. The `reindex` command is also called internally by `move`, `promote`, and `triage` as their final step (FR-008).

**Rationale**: The `.product/index.yaml` structure observed in the live file:
```yaml
product_version: "1.0"
updated: "2026-02-20T00:00:00Z"
feedbacks:
  total: 7
  by_status: { new: 0, triaged: 7, excluded: 0, resolved: 0 }
  by_category: { ... }
  items: [{ id, title, status, category, priority, created }]
backlogs:
  total: 7
  by_status: { open: 0, in-progress: 0, done: 0, promoted: 7, cancelled: 0 }
  items: [{ id, title, status, category, priority, created }]
metrics:
  feedback_to_backlog_rate: 1.0
  backlog_to_feature_rate: 1.0
```
Full-scan is correct-by-construction and eliminates incremental update bugs. With < 1000 files, full directory scan completes in < 100ms.

**Alternatives considered**:
- Incremental index updates (patch only changed entries): Rejected — error-prone, complex, and given small dataset size provides no meaningful performance benefit
- Storing index in-memory only: Rejected — index.yaml is a first-class product artifact used by slash commands and the kai-ui

---

## Decision 4: Feature Number Assignment (promote command)

**Decision**: Scan both `.features/` directory files AND `specs/` directory names to find the highest existing feature number, then use `highest + 1`.

**Rationale**: Inspecting the live repo shows `.features/` contains `001-adr-system.yaml` through `018-cli-atomique-kai-product-pour-operations-produit.yaml`. The `specs/` directory contains numbered directories too (`specs/018-cli-kai-product/`). The spec edge case explicitly mentions: "scans all existing feature numbers and uses the next available one." Scanning both sources prevents collisions.

**Feature ID format**: `{NNN}-{slug}` where NNN is zero-padded to 3 digits and slug is derived from the backlog title (lowercase, hyphens, truncated to ~50 chars).

**Alternatives considered**:
- Scanning only `.features/`: Rejected — spec directory numbering (e.g. `specs/018-*`) could create collision if a spec was created but no feature YAML yet
- Sequential from a counter file: Rejected — adds a new state artifact; filesystem scanning is self-healing

---

## Decision 5: Triage Command Architecture

**Decision**: The `triage` command is a data pipeline that (1) reads all `feedbacks/new/` files, (2) outputs a structured JSON triage plan to stdout, then (3) applies the plan (create backlogs, move feedbacks, regenerate index). The AI semantic clustering step is NOT in the CLI — per the spec assumption: "The triage command's semantic clustering will be performed by the calling Claude Code slash command."

**Rationale**: The spec is explicit (Assumption section): the CLI handles file operations and data transformations; the slash command handles AI-powered decisions. The CLI's role in triage is:
1. **Plan output** (FR-012): Emit the list of new feedbacks as JSON for the slash command to annotate with clusters/assignments
2. **Plan application**: Accept a JSON plan (via stdin or file arg) and apply it atomically

**Implementation**: Two-phase invocation:
- `kai-product triage --plan` → outputs JSON list of new feedbacks to stdout (read-only)
- `kai-product triage --apply {plan-file}` → reads JSON plan, creates backlogs, moves feedbacks, regenerates index

**Alternatives considered**:
- Single-phase triage that guesses clusters heuristically: Rejected — the spec assigns clustering responsibility to the AI slash command, not the CLI
- Streaming interactive protocol: Rejected — adds complexity; file-based plan handoff is simpler and testable

---

## Decision 6: Error Handling and Exit Codes

**Decision**: Structured errors to stderr with context (file path, ID, reason). Exit 0 on success, exit 1 on any error. For `check` with `--json`, errors are included in the JSON output structure (not stderr) so machine consumers can parse them.

**Pattern from existing packages**: `@tcanaud/playbook/bin/cli.js` uses `process.on("unhandledRejection")` as a global catch-all. Same pattern adopted.

---

## Decision 7: Testing Strategy

**Decision**: Node.js native test runner (`node:test` + `node:assert`), no test framework dependency. Integration tests use `node:fs/promises` to create temporary `.product/` fixture directories in `os.tmpdir()`, run command functions directly (not via CLI subprocess), and assert filesystem state.

**Rationale**: Zero-dependency constraint applies to dev dependencies as well (following the established pattern — `@tcanaud/playbook` has no `devDependencies` in its `package.json`). Native test runner available since Node 18.

**Alternatives considered**:
- Jest / Vitest: Rejected — adds devDependencies, contradicts zero-dep pattern
- Shell-based tests: Rejected — harder to set up isolated fixtures, no structured assertions

---

## File Schema Summary (from live data inspection)

### Feedback file (`.product/feedbacks/{status}/FB-NNN.md`)
```yaml
---
id: "FB-NNN"
title: "..."
status: "new|triaged|excluded|resolved"
category: "critical-bug|bug|optimization|evolution|new-feature"
priority: "low|medium|high|null"
source: "user"
reporter: "..."
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
tags: []
exclusion_reason: ""
linked_to:
  backlog: ["BL-NNN"]
  features: ["NNN-slug"]
  feedbacks: []
resolution:
  resolved_date: ""
  resolved_by_feature: ""
  resolved_by_backlog: ""
---
Body text
```

### Backlog file (`.product/backlogs/{status}/BL-NNN.md`)
```yaml
---
id: "BL-NNN"
title: "..."
status: "open|in-progress|done|promoted|cancelled"
category: "..."
priority: "low|medium|high"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
owner: "..."
feedbacks: ["FB-NNN"]
features: ["NNN-slug"]
tags: []
promotion:
  promoted_date: ""
  feature_id: ""
cancellation:
  cancelled_date: ""
  reason: ""
---
Body text
```

### Valid Status Values
- Feedback: `new`, `triaged`, `excluded`, `resolved`
- Backlog: `open`, `in-progress`, `done`, `promoted`, `cancelled`

# Feature Specification: CLI Atomique @tcanaud/kai-product Pour Opérations Produit

**Feature Branch**: `018-cli-kai-product`
**Created**: 2026-02-20
**Status**: Draft
**Input**: User description: "Créer un package CLI @tcanaud/kai-product exposant des commandes atomiques pour les opérations produit courantes, éliminant la plomberie multi-tool-call actuelle"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reindex Product Data (Priority: P1)

As a product operator, I want to regenerate the product index from the actual filesystem state so that the index always reflects reality and I never need to manually maintain it.

**Why this priority**: The index is the foundation for every other operation. If the index is wrong, all other commands produce incorrect results. This is also the simplest command to implement and validates the core file-scanning infrastructure.

**Independent Test**: Can be fully tested by creating a `.product/` directory with known files, running `reindex`, and verifying the generated `index.yaml` matches the expected counts and items.

**Acceptance Scenarios**:

1. **Given** a `.product/` directory with feedbacks and backlogs across all status subdirectories, **When** I run `kai-product reindex`, **Then** `index.yaml` is regenerated with accurate counts by status, by category, and complete item listings.
2. **Given** an `index.yaml` that is out of sync with the actual files (stale entries, missing entries), **When** I run `kai-product reindex`, **Then** the index is corrected to match filesystem reality.
3. **Given** an empty `.product/` directory structure with no feedbacks or backlogs, **When** I run `kai-product reindex`, **Then** an `index.yaml` is generated with all counts at zero.

---

### User Story 2 - Move Backlogs Between Statuses (Priority: P1)

As a product operator, I want to move one or more backlog items to a new status in a single command so that status transitions are atomic, consistent, and fast.

**Why this priority**: Moving items between statuses is the most frequent product operation. Currently it requires multiple file reads, edits, and moves. This is the highest-impact command for reducing tool call overhead.

**Independent Test**: Can be fully tested by placing backlog files in a status directory, running `move`, and verifying files are relocated, frontmatter is updated, and index is regenerated.

**Acceptance Scenarios**:

1. **Given** a backlog `BL-005` in `backlogs/open/`, **When** I run `kai-product move BL-005 in-progress`, **Then** the file is moved to `backlogs/in-progress/`, its frontmatter `status` is updated to `in-progress`, and `index.yaml` is regenerated.
2. **Given** multiple backlogs `BL-001,BL-002,BL-003`, **When** I run `kai-product move BL-001,BL-002,BL-003 done`, **Then** all three files are moved, all frontmatter updated, and index regenerated in one operation.
3. **Given** a backlog ID that does not exist, **When** I run `kai-product move BL-999 done`, **Then** the command exits with a clear error message identifying the missing item and no files are modified.
4. **Given** a backlog already in the target status, **When** I run `kai-product move BL-005 open` and BL-005 is already in `open/`, **Then** the command reports "already in target status" and makes no changes.

---

### User Story 3 - Check Product Integrity (Priority: P2)

As a product operator, I want to run an integrity check that detects all consistency issues so that I can trust the product data and fix problems before they cascade.

**Why this priority**: Integrity checking is essential for confidence in the data, but it's read-only and non-blocking. It supports all other operations by validating their preconditions and postconditions.

**Independent Test**: Can be fully tested by seeding a `.product/` directory with known integrity issues (status desync, orphans, broken links) and verifying the command reports each one.

**Acceptance Scenarios**:

1. **Given** a backlog file in `backlogs/open/` whose frontmatter says `status: done`, **When** I run `kai-product check`, **Then** a status/directory desync warning is reported for that item.
2. **Given** a feedback linking to a backlog ID that does not exist, **When** I run `kai-product check`, **Then** a broken chain warning is reported.
3. **Given** feedbacks in `feedbacks/new/` that are older than 14 days, **When** I run `kai-product check`, **Then** a staleness warning is reported for each.
4. **Given** a fully consistent `.product/` directory, **When** I run `kai-product check`, **Then** the command reports no issues and exits with success.
5. **Given** an `index.yaml` that is out of sync with files, **When** I run `kai-product check`, **Then** an index desync issue is reported.

---

### User Story 4 - Promote Backlog to Feature (Priority: P2)

As a product operator, I want to promote a backlog item to a full kai feature in a single command so that the entire promotion chain (feature YAML creation, backlog status update, feedback link updates, index regeneration) happens atomically.

**Why this priority**: Promotion is a complex multi-step operation that currently requires 5-10 tool calls. Automating it eliminates the most error-prone manual workflow.

**Independent Test**: Can be fully tested by creating a backlog with linked feedbacks, running `promote`, and verifying the feature YAML exists, backlog is moved to `promoted/`, feedbacks are updated, and both product and feature indexes are regenerated.

**Acceptance Scenarios**:

1. **Given** an open backlog `BL-007` with linked feedback `FB-102`, **When** I run `kai-product promote BL-007`, **Then** a `.features/NNN-{name}.yaml` is created with the next sequential feature number, `BL-007` is moved to `backlogs/promoted/` with updated frontmatter, `FB-102` gets a feature link added, and all indexes are regenerated.
2. **Given** a backlog that is already promoted, **When** I run `kai-product promote BL-003`, **Then** the command exits with an error "BL-003 is already promoted" and no files are modified.
3. **Given** a backlog with no linked feedbacks, **When** I run `kai-product promote BL-010`, **Then** the promotion still succeeds (feedbacks are optional), creating the feature YAML and updating the backlog.

---

### User Story 5 - Triage New Feedbacks (Priority: P3)

As a product operator, I want to scan all new feedbacks, cluster them semantically, detect duplicates and regressions, and create backlog items automatically so that the triage workflow is a single command instead of an interactive multi-step AI session.

**Why this priority**: Triage is the most AI-intensive operation. It benefits greatly from being a single CLI invocation but is less frequent than move/promote. It also depends on the other commands (reindex, move) working correctly.

**Independent Test**: Can be fully tested by placing feedback files in `feedbacks/new/`, running `triage`, and verifying feedbacks are moved to `triaged/` or `excluded/`, backlogs are created in `backlogs/open/`, and the index is regenerated.

**Acceptance Scenarios**:

1. **Given** three new feedbacks in `feedbacks/new/` describing related issues, **When** I run `kai-product triage`, **Then** related feedbacks are grouped together, a single backlog item is created for the group in `backlogs/open/`, feedbacks are moved to `feedbacks/triaged/` with backlog links, and the index is regenerated.
2. **Given** a new feedback that duplicates an existing triaged feedback, **When** I run `kai-product triage`, **Then** the duplicate is detected, linked to the existing backlog, and moved to `feedbacks/triaged/` without creating a new backlog.
3. **Given** a new feedback describing a regression against a resolved feature, **When** I run `kai-product triage`, **Then** the regression is flagged with a warning and a new high-priority backlog is created.
4. **Given** no new feedbacks in `feedbacks/new/`, **When** I run `kai-product triage`, **Then** the command reports "No new feedbacks to triage" and exits cleanly.

---

### Edge Cases

- What happens when the `.product/` directory does not exist? The command reports a clear error with setup instructions.
- What happens when a file has malformed YAML frontmatter? The command reports a parse error with the file path and line number, skips the file, and continues processing.
- What happens when two commands run concurrently and both try to move the same file? The second command fails gracefully since the file no longer exists at the source path.
- What happens when the next feature number conflicts with an existing feature? The command scans all existing feature numbers and uses the next available one.
- What happens when a bulk move contains a mix of valid and invalid IDs? The command reports errors for invalid IDs and does not process any items (all-or-nothing).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST expose five subcommands: `move`, `promote`, `triage`, `reindex`, and `check`.
- **FR-002**: The `move` command MUST accept one or more backlog IDs (comma-separated) and a target status, relocate files to the correct directory, update frontmatter, and regenerate the index.
- **FR-003**: The `promote` command MUST accept a backlog ID and perform the full promotion chain: create feature YAML, move backlog to `promoted/`, update linked feedbacks, and regenerate all indexes.
- **FR-004**: The `triage` command MUST scan `feedbacks/new/`, output a structured triage plan (clusters, duplicates, regressions), and apply it: create backlogs, move feedbacks, update links, regenerate index.
- **FR-005**: The `reindex` command MUST regenerate `index.yaml` by scanning all files in the `.product/` directory tree, producing accurate counts and item listings.
- **FR-006**: The `check` command MUST detect and report: status/directory desyncs, stale feedbacks (14+ days in new/), orphaned backlogs (no linked feedbacks), broken traceability chains (FB to BL to Feature), and index desyncs.
- **FR-007**: All commands MUST validate inputs before making any filesystem changes (fail-fast).
- **FR-008**: All mutating commands MUST regenerate `index.yaml` as their final step.
- **FR-009**: The `move` command MUST support bulk operations via comma-separated IDs with all-or-nothing semantics (validate all before moving any).
- **FR-010**: The CLI MUST exit with code 0 on success and non-zero on failure, with structured error messages on stderr.
- **FR-011**: The `check` command MUST produce machine-readable output (JSON) when invoked with a `--json` flag, for integration with slash commands.
- **FR-012**: The `triage` command MUST output the triage plan before applying changes, allowing the calling slash command to present it for review.
- **FR-013**: The CLI MUST operate without any runtime dependencies beyond Node.js built-ins, following the established zero-dependency pattern.
- **FR-014**: The package MUST follow the existing `@tcanaud/playbook` pattern: `init` for first setup, `update` for refreshing commands/templates.

### Key Entities

- **Feedback**: A product feedback item with an ID (FB-NNN), status, category, priority, and links to backlogs and features. Lives in `.product/feedbacks/{status}/`.
- **Backlog**: A prioritized work item derived from feedbacks, with an ID (BL-NNN), status, category, and links to feedbacks and features. Lives in `.product/backlogs/{status}/`.
- **Feature**: A kai feature registered in `.features/`, with a sequential number and short name. Created during promotion.
- **Index**: A computed YAML file (`index.yaml`) summarizing counts, statuses, and item listings across all feedbacks and backlogs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Any single product operation (move, promote, reindex, check) completes in one CLI invocation instead of the current 5-10 tool calls.
- **SC-002**: Bulk move of 10 backlog items completes in under 5 seconds.
- **SC-003**: The `reindex` command produces an `index.yaml` identical to what a manual full scan would produce, with zero discrepancies.
- **SC-004**: The `check` command detects 100% of seeded integrity issues in test fixtures (status desyncs, orphans, broken chains, stale feedbacks, index desyncs).
- **SC-005**: The `promote` command produces the same end-state (feature YAML, moved backlog, updated feedbacks, regenerated indexes) as the current multi-step `/product.promote` slash command.
- **SC-006**: All commands operate with zero runtime dependencies beyond Node.js built-ins.
- **SC-007**: Token cost per product operation is reduced by at least 80% compared to the current slash-command-driven multi-tool-call approach.

## Assumptions

- The `.product/` directory structure follows the established convention with `feedbacks/{new,triaged,excluded,resolved}/` and `backlogs/{open,in-progress,done,promoted,cancelled}/` subdirectories.
- YAML frontmatter parsing follows the existing `---` delimiter convention used throughout the codebase.
- Feature numbering is sequential and determined by scanning existing `.features/` entries and specs directories.
- The triage command's semantic clustering will be performed by the calling Claude Code slash command (which has AI capabilities), not by the CLI itself. The CLI handles the file operations and data transformations; the slash command handles AI-powered decisions.
- Valid backlog statuses are: `open`, `in-progress`, `done`, `promoted`, `cancelled`.
- Valid feedback statuses are: `new`, `triaged`, `excluded`, `resolved`.

# Feature Specification: kai Product Manager Module

**Feature Branch**: `008-product-manager`
**Created**: 2026-02-18
**Status**: Draft
**Input**: User description: "kai Product Manager module — file-based feedback intake, AI semantic triage, backlog management, and feature promotion pipeline"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture Feedback (Priority: P1)

A project owner receives a complaint from a user: "search is unusable on large repos." Instead of letting it disappear in a chat thread, the owner runs a single command with a text description. The system creates a structured feedback entry — auto-assigns a sequential ID (FB-001), proposes a category (e.g. `optimization`), records the source and reporter, and places it in the "new" intake area. The owner can also drop raw files into an inbox staging area; when they run the intake command, all inbox files are processed into structured feedbacks and the inbox is cleaned up.

**Why this priority**: Without feedback capture, no other part of the system can function. This is the entry point for the entire pipeline.

**Independent Test**: Can be fully tested by running the intake command with a text description and verifying a structured feedback file appears with correct metadata. Delivers immediate value: feedback is no longer lost.

**Acceptance Scenarios**:

1. **Given** a project with the `.product/` directory initialized, **When** the owner runs the intake command with a free-text description, **Then** a new feedback file is created in the "new" area with a sequential ID, proposed category, source metadata, and the description as body content.
2. **Given** one or more raw files exist in the inbox staging area, **When** the owner runs the intake command, **Then** each inbox file is converted into a structured feedback in the "new" area, preserving source metadata (reporter, source type, original timestamp), and the inbox files are removed after successful processing.
3. **Given** feedbacks FB-001 through FB-005 already exist, **When** a new feedback is created, **Then** it receives ID FB-006 (next sequential number).
4. **Given** a feedback about a crash, **When** the system analyzes the content, **Then** it proposes a category from the predefined set (`critical-bug`, `bug`, `optimization`, `evolution`, `new-feature`).

---

### User Story 2 - Triage Feedback with AI Semantic Clustering (Priority: P1)

After several feedbacks have accumulated, the owner runs a triage command. The system reads all new feedbacks and performs semantic analysis — grouping related items (even when phrased differently), detecting duplicates, and proposing batch actions. For each group, it proposes creating a backlog item. It also compares new feedbacks against previously resolved feedbacks: if a new feedback is semantically similar to one that was already resolved by a shipped feature, the system determines whether this is a regression (feedback arrived after the fix shipped) or a duplicate of already-resolved work (feedback predates the fix). The owner can operate in autonomous mode (system executes all decisions) or supervised mode (each action requires confirmation).

**Why this priority**: Triage is the core intelligence of the system — it transforms raw feedback into actionable work. Without it, feedbacks just accumulate without producing value.

**Independent Test**: Can be tested by creating 5+ feedbacks with varying phrasings about overlapping topics, running triage, and verifying the system groups related items together and proposes meaningful backlogs. Delivers the "aha moment": connections the owner would never have made manually.

**Acceptance Scenarios**:

1. **Given** 5 feedbacks in the "new" area where 2 describe the same problem in different words, **When** the triage command runs, **Then** the system groups those 2 feedbacks together and proposes a single backlog item linking both.
2. **Given** a new feedback semantically similar to a resolved feedback whose linked feature shipped on March 1, and the new feedback was created on March 15, **When** triage runs, **Then** the system classifies it as a REGRESSION and creates a critical-priority backlog item.
3. **Given** a new feedback semantically similar to a resolved feedback whose linked feature shipped on March 1, and the new feedback was created on February 20, **When** triage runs, **Then** the system classifies it as DUPLICATE-RESOLVED and moves it to the "excluded" area with the reason and traceability links.
4. **Given** triage runs in autonomous mode, **When** all decisions are made, **Then** feedbacks move from "new" to "triaged" or "excluded," and backlog items are created — all without human confirmation prompts.
5. **Given** triage runs in supervised mode, **When** each grouping or classification is proposed, **Then** the system pauses for human confirmation before executing the action.
6. **Given** a feedback that is clearly noise (unrelated to the project), **When** triage runs, **Then** it is moved to "excluded" with an exclusion reason.

---

### User Story 3 - Promote Backlog to Feature (Priority: P1)

A backlog item has accumulated enough evidence (multiple linked feedbacks, clear user need) that the owner decides to turn it into a full feature. Running the promotion command creates a new feature entry in the project's feature lifecycle system, moves the backlog to "promoted" status, and preserves all traceability links (backlog to feature, backlog to feedbacks). The owner is then directed to continue with the standard feature workflow pipeline.

**Why this priority**: Promotion is the bridge from product management to engineering execution. Without it, the feedback pipeline is a dead end.

**Independent Test**: Can be tested by promoting a backlog item and verifying a feature entry is created with correct traceability links. Delivers value by connecting user signals to engineering work.

**Acceptance Scenarios**:

1. **Given** a backlog item BL-001 in "open" status with feedbacks FB-001 and FB-003 linked, **When** the owner runs the promote command for BL-001, **Then** a new feature entry is created with the next available feature number, the backlog moves to "promoted" status, and bidirectional traceability links are preserved (feature references BL-001; BL-001 references the feature).
2. **Given** the highest existing feature number is 008, **When** a backlog is promoted, **Then** the new feature is assigned number 009.
3. **Given** a backlog item has been promoted, **When** the owner views the promoted backlog, **Then** it contains a reference to the created feature and instructions to continue with the feature workflow.

---

### User Story 4 - View Product Dashboard (Priority: P2)

The owner runs a dashboard command to get a quick pulse on product health. The dashboard shows: feedbacks grouped by status (new, triaged, excluded, resolved), backlogs grouped by status (open, in-progress, done, promoted, cancelled), category distribution across all feedbacks, conversion metrics (feedback-to-backlog ratio, backlog-to-feature promotion rate), and active warnings (stale feedbacks, drift findings, critical bugs). The output can also be exported as structured data for scripting.

**Why this priority**: The dashboard provides visibility into the overall product health. Important but not required for the core feedback-to-feature loop.

**Independent Test**: Can be tested by creating feedbacks and backlogs in various statuses and verifying the dashboard displays correct counts, distributions, and conversion metrics.

**Acceptance Scenarios**:

1. **Given** feedbacks exist across all status areas and backlogs in various statuses, **When** the dashboard command runs, **Then** it displays a summary grouped by status with correct counts.
2. **Given** 10 feedbacks where 4 became backlogs, **When** the dashboard shows conversion metrics, **Then** it displays a 40% feedback-to-backlog conversion rate.
3. **Given** the dashboard command is run with a structured data export flag, **When** the output is produced, **Then** it is valid structured data containing all dashboard metrics.

---

### User Story 5 - Detect Drift and Integrity Issues (Priority: P2)

The owner periodically runs a health check command to detect inconsistencies: feedbacks whose recorded status doesn't match their directory location, stale feedbacks sitting in "new" too long, orphaned backlogs with no linked feedbacks, and broken traceability chains (feedbacks referencing non-existent backlogs, backlogs referencing non-existent features). Each finding includes a severity level, description, and suggested corrective action.

**Why this priority**: Drift detection maintains system integrity over time. Essential for long-term trust in the system, but the core pipeline can function without it initially.

**Independent Test**: Can be tested by deliberately introducing desync (moving a file without updating its metadata) and verifying the check command detects and reports the issue.

**Acceptance Scenarios**:

1. **Given** a feedback file is in the "triaged" directory but its metadata says "new," **When** the check command runs, **Then** it reports a status/directory desync finding with a suggested fix.
2. **Given** a feedback has been in the "new" area for more than 2 weeks, **When** the check command runs, **Then** it reports a stale feedback warning.
3. **Given** a backlog references feedbacks FB-010 and FB-011 but FB-011 does not exist, **When** the check command runs, **Then** it reports a broken traceability chain.
4. **Given** the system is fully consistent, **When** the check command runs, **Then** it reports zero findings.

---

### User Story 6 - Browse and Manage Backlog (Priority: P2)

The owner can view all backlog items grouped by status, or drill into a specific backlog item to see its details including linked feedbacks, priority, tags, and any linked features. This provides the management layer between raw feedback and feature promotion.

**Why this priority**: Backlog visibility supports informed promotion decisions. Useful but not strictly required — the owner could browse files directly.

**Independent Test**: Can be tested by creating backlog items in different statuses and verifying the listing command displays them correctly grouped, and the detail view shows all linked entities.

**Acceptance Scenarios**:

1. **Given** backlogs exist in "open," "in-progress," and "promoted" statuses, **When** the backlog listing command runs without arguments, **Then** it displays all backlogs grouped by status.
2. **Given** backlog BL-003 has linked feedbacks FB-002 and FB-007, **When** the backlog detail command runs for BL-003, **Then** it shows the backlog details including both linked feedbacks with their titles and statuses.

---

### Edge Cases

- What happens when the inbox contains a file with no recognizable content (empty or binary)?
  - The system skips the file, logs a warning, and leaves it in the inbox for manual review.
- What happens when two feedbacks are created simultaneously and compete for the same sequential ID?
  - IDs are assigned by scanning the filesystem at intake time; sequential processing prevents conflicts.
- What happens when a promoted backlog's linked feature is deleted from the feature system?
  - The check command detects the broken traceability chain and reports it as a finding.
- What happens when triage encounters a feedback similar to multiple resolved feedbacks linked to different features?
  - The system compares against the most recent resolution and reports the match with full context for the owner to confirm.
- What happens when the index file becomes corrupted or out of sync?
  - The index can be rebuilt from the filesystem state. The filesystem (directories + file metadata) is always authoritative; the index is a performance cache.

## Requirements *(mandatory)*

### Functional Requirements

**Feedback Intake**

- **FR-001**: System MUST create a structured feedback from a free-text description provided directly to the intake command
- **FR-002**: System MUST process all files in the inbox staging area and convert each into a structured feedback
- **FR-003**: System MUST auto-assign sequential feedback IDs (FB-001, FB-002, ...) by scanning existing feedbacks
- **FR-004**: System MUST propose a category for each feedback from the predefined set: `critical-bug`, `bug`, `optimization`, `evolution`, `new-feature`
- **FR-005**: System MUST preserve source metadata (reporter, source type, original timestamp) from inbox files
- **FR-006**: System MUST remove processed files from the inbox after successful intake

**Semantic Triage**

- **FR-007**: System MUST read all feedbacks in the "new" area and perform semantic clustering to identify related items
- **FR-008**: System MUST detect duplicate feedbacks based on semantic similarity, not keyword matching
- **FR-009**: System MUST compare new feedbacks against resolved feedbacks to detect similarity
- **FR-010**: System MUST determine if a similar-to-resolved feedback is a regression or a duplicate by comparing the feedback creation date against the linked feature's release date
- **FR-011**: System MUST classify post-release similar feedbacks as REGRESSION and create a critical-priority backlog
- **FR-012**: System MUST classify pre-release similar feedbacks as DUPLICATE-RESOLVED and move them to the "excluded" area with reason and traceability links
- **FR-013**: System MUST propose batch actions (group, exclude, create backlog) for all new feedbacks in a single triage session
- **FR-014**: System MUST support autonomous mode (default) where all triage decisions are executed without confirmation
- **FR-015**: System MUST support supervised mode where each triage action requires human confirmation before execution
- **FR-016**: System MUST move triaged feedbacks from "new" to "triaged" status
- **FR-017**: System MUST move excluded feedbacks from "new" to "excluded" status with an exclusion reason
- **FR-018**: System MUST create backlog items from grouped feedbacks with bidirectional traceability links

**Backlog Management**

- **FR-019**: Users MUST be able to list all backlog items grouped by status
- **FR-020**: Users MUST be able to view detail for a specific backlog item including linked feedbacks
- **FR-021**: System MUST auto-assign sequential backlog IDs (BL-001, BL-002, ...) by scanning existing backlogs

**Feature Promotion**

- **FR-022**: Users MUST be able to promote a backlog item to a project feature by specifying its ID
- **FR-023**: System MUST create a feature entry for the promoted backlog with the next available feature number
- **FR-024**: System MUST move the promoted backlog to "promoted" status
- **FR-025**: System MUST preserve bidirectional traceability links during promotion (backlog to feature, backlog to feedbacks)

**Drift Detection**

- **FR-026**: System MUST detect feedbacks whose recorded status does not match their directory location
- **FR-027**: System MUST detect backlog items whose recorded status does not match their directory location
- **FR-028**: System MUST detect stale feedbacks (in "new" status beyond a reasonable age threshold)
- **FR-029**: System MUST detect orphaned backlogs (backlogs with no linked feedbacks)
- **FR-030**: System MUST detect broken traceability chains (feedbacks linked to non-existent backlogs, backlogs linked to non-existent features)
- **FR-031**: System MUST report findings with severity level, description, and suggested corrective action

**Dashboard and Visibility**

- **FR-032**: Users MUST be able to view a summary of all feedbacks grouped by status
- **FR-033**: Users MUST be able to view a summary of all backlogs grouped by status
- **FR-034**: Users MUST be able to view category distribution across all feedbacks
- **FR-035**: Users MUST be able to view conversion metrics (feedback-to-backlog ratio, backlog-to-feature promotion rate)
- **FR-036**: Users MUST be able to view active warnings (stale feedbacks, drift findings, critical bugs)
- **FR-037**: Users MUST be able to export dashboard output as structured data for scripting integration

**Index Management**

- **FR-038**: System MUST maintain a centralized index that reflects the current state of all feedbacks and backlogs
- **FR-039**: System MUST update the index after every command execution
- **FR-040**: System MUST be able to rebuild the index from filesystem state if it becomes desynced

### Key Entities

- **Feedback**: A structured record of user input — has an ID (FB-xxx), title, status, priority, category, source, reporter, tags, and links to related backlogs and features. Status is determined by directory location (new, triaged, excluded, resolved).
- **Backlog Item**: An actionable work item aggregating one or more feedbacks — has an ID (BL-xxx), title, status, priority, owner, tags, and links to source feedbacks and promoted features. Status is determined by directory location (open, in-progress, done, promoted, cancelled).
- **Index**: A centralized registry of all feedbacks and backlogs with metadata, serving as a performance cache. The filesystem is authoritative; the index is derived.
- **Inbox**: A staging area where external tools or users deposit raw/unstructured feedback files before they are processed into structured feedbacks.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A feedback can complete the entire lifecycle (new to resolved) with intact traceability links at every step, from original user input to shipped resolution
- **SC-002**: The triage system groups semantically related feedbacks together — confirmed as meaningful by the user (not just keyword matches)
- **SC-003**: The dashboard provides a complete product health overview in under 5 seconds for repositories with up to 200 feedbacks
- **SC-004**: Drift detection produces actionable findings with at least 90% accuracy (no false positives)
- **SC-005**: The centralized index accurately reflects the filesystem state after every command execution — zero desync
- **SC-006**: At least 40% of triaged feedbacks result in backlog items over the first month of use
- **SC-007**: At least 20% of backlog items are promoted to full features over the first quarter of use
- **SC-008**: The system correctly distinguishes regressions from duplicates using temporal comparison (feedback date vs. feature release date) with 100% accuracy on deterministic cases
- **SC-009**: All artifacts are human-readable without specialized tooling — browsable and editable using standard text editors and file browsers
- **SC-010**: The complete system operates with zero runtime dependencies — all commands are prompt templates, no packages required

## Assumptions

- The project already uses the kai governance stack (feature lifecycle, agreements, ADR, etc.)
- A `.product/` directory will be the 8th dotfile directory in the kai governance stack
- The predefined category set (`critical-bug`, `bug`, `optimization`, `evolution`, `new-feature`) is sufficient for MVP; extensibility is a post-MVP concern
- Single-user operation is the primary use case; multi-user coordination is out of scope for MVP
- The filesystem-as-state model (directories as statuses) scales adequately for up to 200 feedbacks and 50 backlogs
- Sequential IDs (FB-xxx, BL-xxx) support up to 999 items per type, which is sufficient for single-project use
- The "stale feedback" threshold for drift detection defaults to a reasonable period (e.g. 2 weeks in "new" status)
- Automatic resolution (moving feedbacks to "resolved" when a linked feature ships) is a v2 feature; MVP requires manual resolution or a dedicated resolve command

## Scope Boundaries

**In scope (MVP):**
- 6 commands: intake, triage, backlog, promote, check, dashboard
- Filesystem-as-state pattern for both feedbacks and backlogs
- AI semantic clustering and duplicate/regression detection
- Bidirectional traceability (feedback to backlog to feature)
- Centralized index with rebuild capability
- Autonomous and supervised triage modes

**Out of scope (post-MVP):**
- Automatic resolution on feature release (v2)
- Periodic review reports (v2)
- tcsetup integration for automated installation (v2)
- Knowledge system integration (post-MVP)
- External tool bridges (webhooks, Slack bots, form processors) (v3)
- Priority scoring algorithms (v2)
- Backlog item dependency tracking (v2)
- Cross-project feedback aggregation (v3)

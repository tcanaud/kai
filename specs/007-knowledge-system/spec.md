# Feature Specification: Verified Knowledge System

**Feature Branch**: `007-knowledge-system`
**Created**: 2026-02-18
**Status**: Draft
**Input**: User description: "Verified knowledge system for AI agent onboarding — knowledge as agreements with freshness verification, three-layer architecture (stable/semi-stable/volatile), and a `/k` query command that returns assembled answers with provenance and verification status"

## User Scenarios & Testing

### User Story 1 - Query the Knowledge Base (Priority: P1)

A developer (or AI agent) working on a kai-managed project needs to understand how something works or how to accomplish a task. They run `/k how do I release a package?` and receive an assembled answer drawn from multiple knowledge sources (guides, conventions, ADRs, feature manifests), with each source cited and tagged as either VERIFIED (still accurate) or STALE (underlying files changed since last verification).

**Why this priority**: This is the primary interface of the entire knowledge system. Without a query mechanism that returns verified, sourced answers, the rest of the system has no consumer. This single story delivers the core value proposition: "ask a question, get a trustworthy answer."

**Independent Test**: Can be fully tested by initializing a `.knowledge/` directory with at least one guide and an index, running `/k` with a question that matches the guide's domain, and verifying the response includes the guide content, source citation, and correct verification status.

**Acceptance Scenarios**:

1. **Given** a project with a `.knowledge/` directory containing an index and at least one guide, **When** the user runs `/k how do I release a package?`, **Then** the system returns an assembled answer with source citations and a verification status for each source.
2. **Given** a guide whose watched_paths have been modified since `last_verified`, **When** the user queries a topic covered by that guide, **Then** the source is tagged STALE with a warning indicating which paths changed.
3. **Given** a query that matches multiple knowledge artifacts (guide + ADR + convention), **When** the user runs `/k`, **Then** all relevant sources are included in the response, ordered by relevance.
4. **Given** a query that matches no knowledge artifacts, **When** the user runs `/k`, **Then** the system reports that no relevant knowledge was found and suggests creating a guide or checking available topics.

---

### User Story 2 - Refresh Knowledge Snapshot and Index (Priority: P1)

A developer has just released a new feature or updated conventions/ADRs. They run `/knowledge.refresh` to regenerate the volatile snapshot (aggregated view of all conventions, ADRs, features, tech stack) and recompute the knowledge index that maps concepts and file paths to relevant artifacts.

**Why this priority**: The snapshot and index are the foundation that makes `/k` queries fast and accurate. Without a refresh mechanism, the knowledge base becomes stale immediately after any project change. This is equally critical as the query itself.

**Independent Test**: Can be fully tested by running `/knowledge.refresh` in a project with existing ADRs, conventions, features, and guides, then verifying that `snapshot.md` contains current data and `index.yaml` maps concepts to the correct artifacts.

**Acceptance Scenarios**:

1. **Given** a project with ADRs, conventions, feature manifests, and guides, **When** the user runs `/knowledge.refresh`, **Then** `snapshot.md` is regenerated with current summaries of all active conventions, ADR titles, feature statuses, and tech stack info.
2. **Given** a project with guides containing `references` fields pointing to conventions and ADRs, **When** the user runs `/knowledge.refresh`, **Then** `index.yaml` is recomputed with concept-to-artifact mappings derived from guide metadata, ADR references, and convention scopes.
3. **Given** the user runs `/knowledge.refresh` after adding a new ADR, **When** the refresh completes, **Then** the new ADR appears in both `snapshot.md` and `index.yaml`.

---

### User Story 3 - Check Knowledge Freshness (Priority: P2)

A developer wants to ensure all knowledge guides are still accurate before onboarding a new team member or starting a new sprint. They run `/knowledge.check` which scans all guides, compares each guide's `watched_paths` against git history since `last_verified`, and produces a report listing which guides are VERIFIED (no changes to watched paths) and which are STALE (watched paths modified).

**Why this priority**: This is the "drift detection" mechanism — the killer differentiator. Without it, guides silently become outdated like any wiki. However, it requires guides and the index to exist first (Stories 1-2), making it P2.

**Independent Test**: Can be fully tested by creating a guide with watched_paths, modifying one of the watched files, running `/knowledge.check`, and verifying the guide is reported as STALE with details of what changed.

**Acceptance Scenarios**:

1. **Given** a guide with `watched_paths` pointing to files that have not changed since `last_verified`, **When** the user runs `/knowledge.check`, **Then** the guide is reported as VERIFIED.
2. **Given** a guide with `watched_paths` pointing to files that were modified after `last_verified`, **When** the user runs `/knowledge.check`, **Then** the guide is reported as STALE with the list of changed paths and their last modification dates.
3. **Given** a guide whose referenced convention or ADR has been superseded, **When** the user runs `/knowledge.check`, **Then** the guide is reported as STALE with a note about the superseded reference.
4. **Given** all guides pass freshness checks, **When** `/knowledge.check` completes, **Then** an overall HEALTHY status is reported.

---

### User Story 4 - Create a Knowledge Guide (Priority: P2)

A developer has just figured out a non-obvious process (e.g., how to debug agreement drift, how to add a new package to the monorepo) and wants to capture that knowledge for future agents and team members. They run `/knowledge.create "debug agreement drift"` and the system creates a new guide with proper frontmatter (id, title, last_verified, references, watched_paths), a content skeleton, and registers it in the index.

**Why this priority**: The system needs a way to grow its knowledge base. Without guide creation, the system is limited to whatever was set up initially. However, it requires the knowledge directory structure to exist first.

**Independent Test**: Can be fully tested by running `/knowledge.create` with a topic, verifying the guide file is created with proper frontmatter, and confirming it appears in `index.yaml` after a refresh.

**Acceptance Scenarios**:

1. **Given** a project with an initialized `.knowledge/` directory, **When** the user runs `/knowledge.create "debug agreement drift"`, **Then** a new guide file is created in `.knowledge/guides/` with proper YAML frontmatter including id, title, created date, last_verified date, and empty references and watched_paths fields.
2. **Given** the guide is created, **When** the user or AI fills in the content and watched_paths, **Then** the guide is immediately queryable via `/k` after a refresh.
3. **Given** the user provides a topic that matches an existing guide's id, **When** they run `/knowledge.create`, **Then** the system warns that a guide with that topic already exists and offers to open it for editing instead.

---

### User Story 5 - Initialize Knowledge Directory (Priority: P1)

A developer onboarding a project onto the knowledge system (or running `tcsetup init`/`tcsetup update` for the first time after this feature exists) needs the `.knowledge/` directory structure created with default configuration, an empty index, and a starter `architecture.md`. They run the initialization command and the knowledge directory is scaffolded.

**Why this priority**: Nothing else works without the directory structure. This is the bootstrap step that enables all other stories. Part of tcsetup integration.

**Independent Test**: Can be fully tested by running the init command in a project without `.knowledge/` and verifying the directory structure is created with config.yaml, index.yaml, architecture.md scaffold, and guides/ directory.

**Acceptance Scenarios**:

1. **Given** a project without a `.knowledge/` directory, **When** the knowledge system is initialized, **Then** the following structure is created: `.knowledge/index.yaml`, `.knowledge/config.yaml`, `.knowledge/architecture.md` (scaffold), `.knowledge/snapshot.md` (empty or initial), `.knowledge/guides/` directory.
2. **Given** a project that already has a `.knowledge/` directory, **When** initialization runs again, **Then** existing content is preserved — only missing structural files are added.
3. **Given** initialization completes, **When** the user runs `/knowledge.refresh`, **Then** the snapshot is populated from existing project artifacts (ADRs, conventions, features).

---

### User Story 6 - Knowledge Capture After Exploration (Priority: P3)

After an AI agent spends significant effort exploring the codebase to answer a question or solve a problem, the system suggests capturing that exploration as a reusable knowledge guide. The agent can accept the suggestion and a pre-populated guide is created from the exploration findings.

**Why this priority**: This is the "learning loop" that makes the knowledge base grow organically. Important for long-term value but not required for initial launch. Also requires guide creation (Story 4) to work.

**Independent Test**: Can be tested by simulating an exploration session, triggering the capture suggestion, accepting it, and verifying a guide is created with relevant content and watched_paths.

**Acceptance Scenarios**:

1. **Given** an AI agent has explored multiple files to answer a question, **When** the exploration concludes, **Then** the system suggests creating a knowledge guide from the findings.
2. **Given** the user accepts the capture suggestion, **When** the guide is created, **Then** it includes a summary of the findings, references to the explored artifacts, and watched_paths derived from the files that were read.
3. **Given** the user declines the capture suggestion, **When** they decline, **Then** no guide is created and no data is persisted.

---

### Edge Cases

- What happens when `/k` is run in a project with no `.knowledge/` directory? The system should report that the knowledge system is not initialized and suggest running initialization.
- What happens when a guide's `watched_paths` reference a file that has been deleted? The guide should be flagged as STALE with a note that the watched file no longer exists.
- What happens when `/knowledge.refresh` is run but no ADRs, conventions, or features exist yet? The snapshot should be generated with empty sections, not fail.
- What happens when `index.yaml` references a guide that has been manually deleted from disk? The refresh should detect the orphan entry and remove it from the index.
- What happens when two guides cover overlapping topics? The `/k` query should return both, ranked by relevance, letting the user see both perspectives.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST provide a `/k <question>` command that queries the knowledge base and returns assembled answers with source citations and verification status (VERIFIED or STALE).
- **FR-002**: The system MUST provide a `/knowledge.refresh` command that regenerates `snapshot.md` from existing project artifacts and recomputes `index.yaml` concept-to-artifact mappings.
- **FR-003**: The system MUST provide a `/knowledge.check` command that scans all guides and reports freshness status by comparing `watched_paths` against git history since `last_verified`.
- **FR-004**: The system MUST provide a `/knowledge.create` command that creates a new guide with proper YAML frontmatter and registers it in the knowledge index.
- **FR-005**: The system MUST store all knowledge artifacts in a `.knowledge/` directory at the project root, using YAML and Markdown formats.
- **FR-006**: The system MUST maintain an `index.yaml` file that maps concepts, keywords, and file paths to relevant knowledge artifacts (guides, ADRs, conventions, features).
- **FR-007**: The system MUST maintain a `config.yaml` file with configurable freshness thresholds, artifact source paths, and snapshot generation rules.
- **FR-008**: Each guide MUST have YAML frontmatter containing: id, title, last_verified date, references (to conventions, ADRs, features), and watched_paths.
- **FR-009**: The system MUST detect guide staleness by comparing `watched_paths` file modification timestamps (via git log) against the guide's `last_verified` date.
- **FR-010**: The system MUST generate a `snapshot.md` that aggregates current summaries of active conventions, ADR titles and statuses, feature dashboard, and technology stack.
- **FR-011**: The system MUST provide initialization that scaffolds the `.knowledge/` directory with default config, empty index, starter architecture.md, and guides directory.
- **FR-012**: The system MUST integrate with tcsetup — initialization during `tcsetup init` and refresh during `tcsetup update`.
- **FR-013**: The system MUST use only Node.js built-in modules (zero runtime dependencies).
- **FR-014**: The system MUST NOT modify source artifacts it reads from (`.agreements/`, `.adr/`, `.features/`, `specs/`). It is read-only with respect to other systems.
- **FR-015**: The system MUST support an `architecture.md` file that is human-curated and never auto-modified by the system.
- **FR-016**: The system MUST provide an update command that refreshes its own command templates without modifying user-created guides or architecture.md.

### Key Entities

- **Knowledge Guide**: A Markdown file in `.knowledge/guides/` with YAML frontmatter (id, title, last_verified, references, watched_paths) and prose content explaining a process, pattern, or concept. Analogous to an agreement — a promise between documentation and code reality.
- **Knowledge Index**: A YAML file (`index.yaml`) that maps concepts, keywords, and file paths to relevant knowledge artifacts. The routing table that makes queries efficient.
- **Knowledge Snapshot**: An auto-generated Markdown file (`snapshot.md`) that aggregates volatile project state — current conventions, ADR summaries, feature dashboard, tech stack. Regenerated on every refresh.
- **Architecture Overview**: A human-curated Markdown file (`architecture.md`) providing the stable macro view of the project ecosystem. Rarely modified, never auto-generated.
- **Knowledge Config**: A YAML file (`config.yaml`) defining freshness thresholds, source directories to scan, and snapshot generation rules.

## Success Criteria

### Measurable Outcomes

- **SC-001**: An AI agent can understand the project's architecture, conventions, and current state by reading 3 files or fewer (CLAUDE.md + snapshot.md + architecture.md), without needing to scan dozens of individual artifact files.
- **SC-002**: Every knowledge guide has a verifiable freshness status — users can determine at a glance whether a guide's content is still accurate or potentially outdated.
- **SC-003**: Stale guides are detected within one `/knowledge.check` run after any watched file changes, with zero false negatives (a changed watched_path always triggers STALE).
- **SC-004**: New project knowledge (how-tos, patterns, decisions) can be captured as a guide in under 2 minutes via `/knowledge.create`.
- **SC-005**: The knowledge system operates with zero runtime dependencies, consistent with the project's ESM-only, zero-deps convention.
- **SC-006**: The snapshot accurately reflects current project state — running `/knowledge.refresh` after any artifact change produces an updated snapshot within a single command invocation.

## Assumptions

- The project has been onboarded with the TC stack (at minimum, the `.knowledge/` directory can exist independently, but value increases with other TC tools installed).
- Git is available and git log can be used to determine file modification history for freshness checks.
- The AI agent (Claude Code) processes slash commands and can read/write files in the `.knowledge/` directory.
- Existing artifact directories (`.adr/`, `.agreements/`, `.features/`, `specs/`) follow the established kai conventions for file naming and YAML structure.
- The `architecture.md` file is maintained by a human; the system never auto-generates or modifies it. Only initialization creates a scaffold.
- Guides are expected to be relatively concise (focused on a single topic/process). The system is not designed for long-form documentation or tutorials.

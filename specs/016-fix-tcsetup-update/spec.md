# Feature Specification: Fix tcsetup Update Configuration Merging

**Feature Branch**: `001-fix-tcsetup-merge`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "016-fix-tcsetup-update"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run tcsetup Update Without Data Loss (Priority: P1)

A developer runs `npx tcsetup update` to fetch the latest versions of all installed TC tools and expects their custom BMAD agent configurations to remain intact with no duplication or corruption.

**Why this priority**: This is the primary use case that is currently broken. Developers cannot safely update their tools because configuration data gets appended multiple times, corrupting the files.

**Independent Test**: Can be fully tested by running `npx tcsetup update` in a project with BMAD installed, then verifying that configuration files contain exactly one copy of each configuration section with no duplicates.

**Acceptance Scenarios**:

1. **Given** a project with BMAD installed and custom memories/menu items in core-bmad-master.customize.yaml, **When** user runs `npx tcsetup update`, **Then** the customize.yaml file contains the same configuration as before with no duplication
2. **Given** a project with BMAD installed and custom settings in bmm-pm.customize.yaml, **When** user runs `npx tcsetup update`, **Then** the customize.yaml file contents remain unchanged with no appended data
3. **Given** a project where customize.yaml files have been previously corrupted with duplicates, **When** user runs `npx tcsetup update`, **Then** the duplicates are intelligently merged/deduplicated into a single copy

---

### User Story 2 - Intelligently Merge Configuration Updates (Priority: P2)

When a tool updates and needs to add new configuration sections to customize.yaml files, the update process intelligently merges the changes rather than blindly appending.

**Why this priority**: Enables future tool updates to safely modify configuration files without causing corruption, and supports adding new features to existing installations without data loss.

**Independent Test**: Can be fully tested by creating a test scenario where the updater needs to add a new configuration section to an existing customize.yaml file, verifying the result contains both old and new content correctly merged.

**Acceptance Scenarios**:

1. **Given** a customize.yaml with existing configuration, **When** an update needs to add new sections, **Then** those sections are added without duplicating existing content
2. **Given** a customize.yaml with existing configuration that should not be modified, **When** an update runs, **Then** existing configuration is preserved as-is

---

### User Story 3 - Handle Edge Cases in Configuration Files (Priority: P3)

The update process handles various edge cases gracefully including missing files, partial configurations, and invalid YAML.

**Why this priority**: Ensures robustness and prevents cryptic errors when developers have unusual configurations or partially updated setups.

**Independent Test**: Can be fully tested by creating various edge case scenarios (empty files, missing files, invalid YAML, etc.) and verifying the updater handles each gracefully.

**Acceptance Scenarios**:

1. **Given** a customize.yaml file is missing, **When** update runs, **Then** the file is created with default/new content if needed, or skipped gracefully
2. **Given** a customize.yaml file has invalid YAML syntax, **When** update runs, **Then** a clear error message is displayed and the file is not corrupted further
3. **Given** a customize.yaml file is empty or has only comments, **When** update runs, **Then** new configuration is added correctly

---

### Edge Cases

- What happens when a customize.yaml file has been corrupted with multiple copies of the same sections?
- How does the system handle files that have been manually edited with unexpected structures?
- What occurs if the tool update introduces a conflicting configuration key with an existing custom value?
- How are comments and formatting in YAML files preserved during merging?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect when configuration files have duplicate sections and deduplicate them during update
- **FR-002**: System MUST preserve existing custom configuration values when running updates
- **FR-003**: System MUST implement intelligent merging for YAML configuration files instead of blind appending
- **FR-004**: System MUST handle arrays in YAML (like the `menu` and `memories` lists) by deduplicating based on content rather than appending duplicates
- **FR-005**: System MUST validate YAML syntax before writing to configuration files to prevent corruption
- **FR-006**: System MUST provide clear error messages when configuration merging encounters conflicts or issues
- **FR-007**: System MUST support both adding new configuration sections and updating existing ones without creating duplicates
- **FR-008**: System MUST maintain YAML structure and formatting conventions (comments, indentation, key ordering)

### Key Entities

- **YAML Configuration File**: Represents a customize.yaml file with typed sections (agent, persona, critical_actions, memories, menu, prompts). Contains both base configuration and custom overrides.
- **Configuration Section**: A named block within the YAML file (e.g., "memories", "menu", "agent") that may contain nested data or lists.
- **Merge Strategy**: The algorithm used to combine existing configuration with new/updated configuration, including deduplication logic for arrays and intelligent merging of objects.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `npx tcsetup update` twice consecutively on the same project results in identical configuration files (no accumulation of duplicates)
- **SC-002**: 100% of customize.yaml files in BMAD projects contain no duplicate configuration sections after running update
- **SC-003**: Custom configuration values (memories, menu items, persona settings) are preserved exactly as set before the update
- **SC-004**: All existing valid YAML files maintain valid YAML syntax after update (parseability verified)

## Assumptions

- The customize.yaml files follow a consistent YAML structure with predictable sections (agent, persona, critical_actions, memories, menu, prompts)
- Array items in memories and menu lists should be deduplicated by their complete content (not just by key)
- Updates should preserve user comments and formatting where possible
- The fix applies primarily to BMAD agent customization files but should work for any YAML merge scenario in tcsetup

## Out of Scope

- Merging PRD files or other product documentation
- Resolving conflicting values when the same key has different values in existing vs. new config (users would need to resolve manually or via clarification)
- Creating a general-purpose YAML merge library (focused on tcsetup's specific use case)

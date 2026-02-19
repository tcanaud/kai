# Feature Specification: /playbook.create Command for Custom Playbook Generation

**Feature Branch**: `013-playbook-create`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "Commande /playbook.create pour generer des playbooks adaptes au projet"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Custom Playbook from a Free-Text Intention (Priority: P1)

A developer working on a monorepo with a mature kai governance stack wants to standardize a recurring workflow they repeat manually: every time a critical bug is reported, they run QA validation, then agreement check, then hotfix implementation, then PR creation. Instead of remembering the sequence and typing each command, the developer runs `/playbook.create` with a free-text intention: "When a critical bug is reported, validate QA, check agreements, implement a fix, and create a PR."

The system first analyzes the project to understand its structure: which kai tools are installed (by detecting marker directories), which slash commands are available (by scanning `.claude/commands/`), what playbooks already exist, and what conventions the project follows. Based on this deep project understanding, the system generates a playbook YAML file that uses only commands that actually exist in the project, follows the project's naming conventions, and includes appropriate autonomy levels, conditions, and error policies for each step.

The developer reviews the generated playbook and finds it ready to use: step IDs are meaningful, conditions reference artifacts that exist in their project, and the structure follows the same schema as the built-in playbooks.

**Why this priority**: This is the core value proposition. Without the ability to generate a playbook from an intention, the feature has no reason to exist. Everything else (validation, refinement, project analysis) supports this.

**Independent Test**: Can be fully tested by running the command with a free-text intention in a project with kai installed, and verifying that the output is a valid playbook YAML file at `.playbooks/playbooks/{name}.yaml` that passes the playbook validator.

**Acceptance Scenarios**:

1. **Given** a project with kai installed and multiple slash commands available, **When** the developer runs `/playbook.create` with "validate and deploy a hotfix for critical bugs", **Then** the system produces a valid playbook YAML file in `.playbooks/playbooks/` with steps referencing only commands that exist in the project.
2. **Given** the developer provides an intention, **When** the system generates the playbook, **Then** each step has an appropriate autonomy level (e.g., validation steps are `auto`, PR creation is `gate_always`), meaningful pre/postconditions from the allowed vocabulary, and a sensible error policy.
3. **Given** a generated playbook file, **When** running the playbook validator, **Then** the playbook passes validation with zero violations.
4. **Given** the developer provides a vague intention like "I want to ship features faster", **When** the system processes the intention, **Then** it asks clarifying questions to narrow the workflow scope before generating the playbook.

---

### User Story 2 - Deep Project Analysis Before Generation (Priority: P1)

Before generating any YAML, the system performs a thorough analysis of the project it is installed on. It scans the entire project to build a context model: which kai tools are present, which slash commands are available, what the project's technology stack is, what existing playbooks do, what conventions are documented, and what the feature lifecycle looks like.

This analysis is not just a directory listing — the system reads existing playbooks to understand patterns (e.g., "this project always gates PR creation", "this project uses agreement checks after implementation"), reads convention documentation to understand naming rules, and reads the project philosophy to understand governance principles. The result is a playbook that feels native to the project, not a generic template.

**Why this priority**: Without deep project understanding, the generated playbook would be a generic template that the developer has to heavily customize. The analysis is what transforms the feature from "template copy" to "intelligent generation."

**Independent Test**: Can be tested by running the command on two different projects with different tool sets and verifying that the generated playbooks differ accordingly (e.g., a project without QA system should not have QA steps).

**Acceptance Scenarios**:

1. **Given** a project where the QA system is not installed (no `.qa/` directory), **When** the system generates a playbook that could include QA steps, **Then** it omits QA-related steps and does not reference QA conditions.
2. **Given** a project where existing playbooks always use `gate_always` for PR creation, **When** the system generates a new playbook that includes a PR step, **Then** it follows the same pattern and sets the PR step to `gate_always`.
3. **Given** a project with documented conventions in `.knowledge/`, **When** the system generates a playbook, **Then** the playbook name follows the project's naming conventions (lowercase slug, consistent with existing playbook names).
4. **Given** a project with multiple installed kai tools, **When** the system analyzes the project, **Then** it identifies all available slash commands and uses only valid commands in the generated playbook.

---

### User Story 3 - Interactive Refinement of Generated Playbook (Priority: P2)

After the system generates an initial playbook, the developer reviews it. The system presents the generated playbook with explanations for each step: why this command was chosen, why this autonomy level, why these conditions. If the developer wants changes — "make the agreement check step always gate instead of auto", "add a knowledge refresh step before implementation" — the system modifies the playbook accordingly and re-validates it.

The interaction continues until the developer is satisfied. At the end, the system writes the final playbook to disk and updates the playbook index.

**Why this priority**: Refinement turns a "good enough" generated playbook into a perfect one. The initial generation handles 80% of cases; refinement handles the remaining 20%.

**Independent Test**: Can be tested by generating a playbook, requesting a modification (e.g., change an autonomy level), and verifying the updated playbook reflects the change while remaining valid.

**Acceptance Scenarios**:

1. **Given** a generated playbook is presented to the developer, **When** the developer requests changing a step's autonomy level, **Then** the system updates that step and re-validates the entire playbook.
2. **Given** a generated playbook, **When** the developer requests adding a new step referencing a specific slash command, **Then** the system adds the step in the correct position with appropriate conditions and policies.
3. **Given** a generated playbook, **When** the developer requests removing a step, **Then** the system removes it and adjusts any dependent conditions (e.g., if a removed step's postcondition was another step's precondition, warn the user about the broken dependency).
4. **Given** the developer approves the final playbook, **When** the system writes it to disk, **Then** the playbook index (`.playbooks/_index.yaml`) is updated to include the new playbook entry.

---

### User Story 4 - Playbook Is Project-Adapted, Not Feature-Specific (Priority: P1)

A developer creates a playbook for "code review workflow for external contributions." The generated playbook describes a reusable process: run agreement check, review code, run QA, create PR. It does NOT reference a specific feature branch, a specific spec file, or a specific PR number. Instead, it uses `{{feature}}` argument interpolation where needed, making the playbook reusable for any feature that goes through this workflow.

The developer can later run this playbook with different feature names and it works identically each time.

**Why this priority**: A playbook tied to a specific feature is just a script. The value of playbooks is reusability across features and across time. This is a core design constraint, not a nice-to-have.

**Independent Test**: Can be tested by generating a playbook, then running it twice with different feature arguments, and verifying it works correctly both times without any hardcoded references.

**Acceptance Scenarios**:

1. **Given** the developer requests a playbook for a workflow that involves feature-specific artifacts, **When** the system generates the playbook, **Then** all feature-specific references use `{{feature}}` argument interpolation, never hardcoded values.
2. **Given** a generated playbook, **When** inspecting its content, **Then** no step references a specific feature ID, branch name, file path with a feature number, or any other feature-specific value.
3. **Given** a generated playbook with a `feature` arg declared as required, **When** the playbook is run with different feature names on separate occasions, **Then** all argument references resolve correctly to the provided feature name each time.

---

### User Story 5 - Playbook Name and Description Generation (Priority: P2)

The system generates not just the steps but also a meaningful name and description for the playbook. The name is derived from the intention (e.g., "critical-bug-hotfix" from "workflow for critical bug hotfixes") and follows the project's naming conventions (lowercase slug, `[a-z0-9-]+`). The description is a human-readable summary of what the playbook does.

If a playbook with the same name already exists, the system warns the developer and offers options: overwrite, rename, or cancel.

**Why this priority**: Good naming and conflict detection prevent confusion and accidental overwrites. Important for usability but not blocking for core functionality.

**Independent Test**: Can be tested by generating a playbook, verifying the name matches the slug pattern, then attempting to generate another with a conflicting name and verifying the conflict is detected.

**Acceptance Scenarios**:

1. **Given** a free-text intention "deploy hotfixes for critical production bugs", **When** the system generates a playbook, **Then** the name is a meaningful lowercase slug (e.g., `critical-hotfix-deploy`) that captures the intention essence.
2. **Given** a playbook named `critical-hotfix-deploy` already exists, **When** the developer attempts to create a playbook with the same derived name, **Then** the system warns about the conflict and offers: overwrite, rename, or cancel.
3. **Given** the developer chooses "rename" when a conflict is detected, **When** the system prompts for a new name, **Then** the developer can provide a custom name that is validated against the slug pattern.

---

### Edge Cases

- What happens when the project has no kai tools installed (bare repository with no marker directories)?
  - The system reports that no kai governance tools were detected, lists the available slash commands it found (if any), and asks whether the developer wants to proceed with a generic playbook or install kai first.
- What happens when the intention references a workflow that requires a command not available in the project?
  - The system explains which command is missing, suggests installing the relevant kai tool, and offers to generate the playbook with the missing step marked as `skip` until the tool is installed.
- What happens when the developer provides an intention that is too broad to map to a specific sequence of steps?
  - The system asks clarifying questions to narrow the scope: "What is the starting point of this workflow?", "What is the expected outcome?", "Which stages should be autonomous vs. require human approval?"
- What happens when the generated playbook would have zero steps (intention cannot be mapped to any available commands)?
  - The system explains that no available commands match the described workflow and suggests reformulating the intention or installing additional tools.
- What happens when the playbook index file is missing or corrupted?
  - The system regenerates the index from the filesystem (scanning `.playbooks/playbooks/*.yaml`) before adding the new entry, consistent with kai's filesystem-as-truth principle.
- What happens when the developer cancels the creation mid-interaction?
  - No files are written to disk. The system confirms cancellation and no cleanup is needed since nothing was persisted.

## Requirements *(mandatory)*

### Functional Requirements

**Project Analysis**

- **FR-001**: System MUST scan the project to detect installed kai tools by checking for marker directories (`.adr/`, `.agreements/`, `.features/`, `.knowledge/`, `.qa/`, `.product/`, `specs/`, `_bmad/`, `.playbooks/`).
- **FR-002**: System MUST scan `.claude/commands/` to identify all available slash commands in the project.
- **FR-003**: System MUST read existing playbooks from `.playbooks/playbooks/` to understand established patterns (autonomy conventions, condition usage, error policy preferences, naming conventions).
- **FR-004**: System MUST read project documentation (`.knowledge/`, `CLAUDE.md`, `.knowledge/snapshot.md`) to understand project conventions and technology stack.
- **FR-005**: System MUST determine which pre/postconditions from the allowed vocabulary are usable based on installed tools (e.g., `qa_plan_exists` is only usable if the QA system is installed).

**Intention Parsing**

- **FR-006**: System MUST accept a free-text intention as input describing the desired workflow.
- **FR-007**: System MUST extract key workflow concepts from the intention: starting trigger, sequence of actions, expected outcome, and any stated constraints (e.g., "always ask before deploying").
- **FR-008**: System MUST ask clarifying questions when the intention is too vague to map to a concrete sequence of steps, limited to at most 3 questions before generating a first draft.

**Playbook Generation**

- **FR-009**: System MUST generate a valid playbook YAML file conforming to the playbook schema (name, description, version, args, steps).
- **FR-010**: System MUST generate a lowercase slug name for the playbook derived from the intention that matches the pattern `[a-z0-9-]+`.
- **FR-011**: System MUST generate a human-readable description summarizing the playbook's purpose.
- **FR-012**: System MUST declare appropriate arguments (with `name`, `description`, `required` fields) based on the workflow needs, using `{{arg}}` interpolation in step args.
- **FR-013**: System MUST generate steps that reference only slash commands verified to exist in the project.
- **FR-014**: System MUST assign each step an autonomy level from the allowed vocabulary (`auto`, `gate_on_breaking`, `gate_always`, `skip`) appropriate to the step's nature and consistent with patterns observed in existing playbooks.
- **FR-015**: System MUST assign each step an error policy from the allowed vocabulary (`stop`, `retry_once`, `gate`) appropriate to the step's criticality.
- **FR-016**: System MUST assign preconditions and postconditions from the allowed vocabulary when applicable, ensuring only conditions whose required tools are installed are used.
- **FR-017**: System MUST assign escalation triggers from the allowed vocabulary when appropriate for the step type.
- **FR-018**: System MUST NOT include any feature-specific hardcoded values in the generated playbook; all feature-specific references MUST use argument interpolation.

**Conflict Detection**

- **FR-019**: System MUST check whether a playbook with the derived name already exists in `.playbooks/playbooks/` before writing.
- **FR-020**: System MUST offer the user three options when a naming conflict is detected: overwrite the existing playbook, choose a different name, or cancel creation.

**Interactive Refinement**

- **FR-021**: System MUST present the generated playbook to the user with explanations for each step choice (command selection, autonomy level rationale, condition rationale).
- **FR-022**: Users MUST be able to request modifications to the generated playbook (add steps, remove steps, change autonomy levels, change error policies, reorder steps).
- **FR-023**: System MUST re-validate the playbook after each modification to ensure it remains schema-compliant.
- **FR-024**: System MUST adjust dependent conditions when a step is removed (e.g., if a removed step's postcondition was another step's precondition, warn the user about the broken dependency).

**Persistence and Index Update**

- **FR-025**: System MUST write the final approved playbook to `.playbooks/playbooks/{name}.yaml`.
- **FR-026**: System MUST update the playbook index (`.playbooks/_index.yaml`) with the new playbook entry including name, file path, description, and step count.
- **FR-027**: System MUST regenerate the index from filesystem state if the index file is missing or appears corrupted before adding the new entry.

**Validation**

- **FR-028**: System MUST validate the generated playbook against the full playbook schema before writing to disk, equivalent to running the playbook validator.
- **FR-029**: System MUST report validation failures to the user and offer to fix them before saving.

### Key Entities

- **Intention**: A free-text description of a desired workflow provided by the user. Serves as the input seed for playbook generation. Does not persist as an artifact — it is consumed during the generation process.
- **Project Context**: The assembled knowledge about the project derived from scanning marker directories, available commands, existing playbooks, conventions, and documentation. Built fresh for each generation session. Informs every generation decision.
- **Generated Playbook**: The output YAML file conforming to the playbook schema. Contains name, description, version, arguments, and an ordered list of steps. Stored at `.playbooks/playbooks/{name}.yaml`.
- **Playbook Index**: The centralized registry at `.playbooks/_index.yaml` listing all available playbooks with their metadata. Updated after each playbook creation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can describe a workflow in plain language and receive a usable playbook within a single interaction session — no manual YAML editing required to get a working result.
- **SC-002**: 100% of generated playbooks pass the playbook validator on first generation, before any user refinement.
- **SC-003**: Generated playbooks reference only commands that exist in the target project — zero "command not found" errors when the playbook is executed.
- **SC-004**: Generated playbooks contain no hardcoded feature-specific values — all feature references use argument interpolation, confirmed by running the same playbook with two different feature names.
- **SC-005**: The project analysis correctly identifies at least 90% of installed kai tools and available slash commands, verified by comparing the analysis output against a manual inventory.
- **SC-006**: Generated playbooks follow the same patterns as the project's existing playbooks (autonomy conventions, condition usage, naming style) — verified by a developer reviewing the output and confirming it feels native to the project.
- **SC-007**: The system handles naming conflicts correctly in 100% of cases — no silent overwrites of existing playbooks.
- **SC-008**: The playbook index is accurate after every creation — the new entry appears with correct metadata, and existing entries are preserved.

## Assumptions

- The project has the playbook supervisor system installed (`.playbooks/` directory exists with at least the template and index).
- The user is operating within a Claude Code session where slash commands are available as the interaction interface.
- Slash commands referenced in playbooks are discoverable by scanning `.claude/commands/` — the filename convention `{namespace}.{command}.md` reliably indicates available commands.
- The playbook schema (version "1.0") is stable and will not change during the implementation of this feature.
- The allowed vocabularies for autonomy levels, error policies, escalation triggers, and conditions are fixed and match those defined in the playbook validator.
- The user's intention describes a repeatable workflow, not a one-time action. Single-action intentions (e.g., "run tests") are out of scope — the system should suggest running the command directly instead.
- The AI model executing the `/playbook.create` command has sufficient context window to analyze the project and generate the playbook in a single session.
- The playbook index format (`.playbooks/_index.yaml`) follows the structure observed in the existing index: a list of entries with `name`, `file`, `description`, and `steps` fields.

## Scope Boundaries

**In scope:**
- Single command `/playbook.create` as a Claude Code slash command
- Project analysis (tool detection, command scanning, pattern extraction)
- Intention parsing with limited clarification (max 3 questions)
- Playbook YAML generation conforming to the schema
- Naming conflict detection and resolution
- Interactive refinement loop
- Index update after creation
- Schema validation before persistence

**Out of scope:**
- Playbook versioning or migration (modifying existing playbooks to match schema updates)
- Playbook sharing across projects
- Playbook composition (combining multiple playbooks into one)
- Automatic playbook execution after creation
- Playbook performance optimization or step reordering based on execution metrics
- Integration with external workflow tools (CI/CD, issue trackers)
- Batch playbook creation from multiple intentions

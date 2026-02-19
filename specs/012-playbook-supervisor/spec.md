# Feature Specification: Playbook Supervisor — Autonomous Feature Loop

**Feature Branch**: `012-playbook-supervisor`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "012-superviseur-autonome-boucle-complete"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Spec to PR Without Manual Command Chaining (Priority: P1)

A developer has finished specifying a feature. Ahead of them: planning, task generation, agreement creation, implementation, agreement check, QA planning, QA execution, and PR creation — eight steps, eight context switches.

The developer launches a playbook run command with the "auto-feature" playbook and the feature branch name. The supervisor reads the playbook, creates a session, and begins executing steps. The first three steps (plan, tasks, agreement) run autonomously — the supervisor chains them without interruption. The developer switches to another task.

When the supervisor reaches implementation, a test breaks. Although the step was configured for autonomous execution, the postcondition failure triggers an escalation — the supervisor halts and presents a clear question: "Implementation done but test X fails. Fix and continue, or abort?" The developer fixes the test, responds "continue", and the supervisor resumes.

Agreement check, QA plan, and QA run chain automatically. QA passes. The final step (PR creation) is always gated — the supervisor halts with a summary: "PR ready. 8/8 steps done. Create PR?" The developer approves. PR created.

**Why this priority**: This is the core value proposition — transforming the developer from executor to decider. Without this end-to-end loop, the system has no reason to exist.

**Independent Test**: Can be fully tested by launching a playbook on a feature with a completed spec, and verifying that the supervisor chains steps, halts at gates, and produces the same artifacts as manual execution.

**Acceptance Scenarios**:

1. **Given** a feature with a completed spec, **When** the developer launches the auto-feature playbook, **Then** the supervisor executes at least 4 consecutive steps without human intervention before reaching a gate or completion.
2. **Given** a step configured for autonomous execution where a postcondition fails, **When** the supervisor evaluates the postcondition, **Then** it escalates to a human gate with a clear question describing the failure.
3. **Given** a step configured as "always gate", **When** the supervisor reaches that step, **Then** it halts and presents context and a question before proceeding.
4. **Given** a developer responds to a gate question, **When** the response indicates "continue", **Then** the supervisor resumes execution from the next step.
5. **Given** a completed playbook run, **When** comparing artifacts to those produced by manual slash command execution, **Then** the artifacts are identical.

---

### User Story 2 - Crash Recovery Without Data Loss (Priority: P2)

A developer launches a playbook. The supervisor chains four steps successfully. At the fifth step, execution crashes — network timeout, terminal closed, or any unexpected interruption.

The developer reopens a terminal, navigates to the working directory, launches the AI assistant, and types a resume command. The supervisor auto-detects the active session by querying the current git worktree, finds the session directory, reads the journal. Steps 1-4 are marked done, step 5 is in progress.

The supervisor checks the postcondition of step 5: if the expected artifact is present, it marks the step done and moves to step 6. If not, it re-runs step 5. No arguments needed, no data lost, no step unnecessarily re-executed.

**Why this priority**: Without crash recovery, the developer cannot trust the system with long-running workflows. Any interruption would require starting over, undermining the value of autonomous execution.

**Independent Test**: Can be tested by launching a playbook, manually interrupting it mid-execution, then running the resume command and verifying it continues from the correct step.

**Acceptance Scenarios**:

1. **Given** a session with steps 1-4 completed and step 5 in progress, **When** the developer runs the resume command without arguments, **Then** the supervisor identifies the correct session and resumes from step 5.
2. **Given** a crashed step whose postcondition artifact exists on disk, **When** resuming, **Then** the supervisor marks the step as done and advances to the next step without re-executing.
3. **Given** a crashed step whose postcondition artifact does not exist, **When** resuming, **Then** the supervisor re-runs the step from scratch.
4. **Given** a project directory that is a git worktree, **When** running the resume command, **Then** the supervisor auto-detects the session namespace from the worktree identity.

---

### User Story 3 - Audit Trail in Git (Priority: P3)

After a playbook completes, the developer opens a pull request. In the diff, a session journal file is visible. The journal records every step: status, decision type (auto or escalated), duration, and any human responses at gates.

A reviewer reads the journal and can trace every decision. If an escalation occurred, the trigger type and the developer's response are recorded. If a step took unusually long, the duration is visible. The journal provides free auditability — just read the file.

**Why this priority**: Traceability is a core kai principle. Without a journal, playbook runs are black boxes. The journal makes every autonomous decision and human intervention visible in code review.

**Independent Test**: Can be tested by completing a playbook run that includes at least one escalation, then verifying the session journal contains entries for every step with accurate status, timing, and human responses.

**Acceptance Scenarios**:

1. **Given** a completed playbook run, **When** inspecting the session directory, **Then** a journal file exists with one entry per step recording status, decision type, and duration.
2. **Given** a step that was escalated due to a postcondition failure, **When** reading the journal, **Then** the entry includes the trigger type and the developer's response text.
3. **Given** a session directory, **When** committing changes, **Then** the journal file is included in the git diff and is human-readable in PR review.

---

### User Story 4 - Parallel Features via Worktrees (Priority: P3)

A developer has an active playbook running for one feature. They also want to start a second feature in parallel. They run a CLI command that creates a new session with a dedicated git worktree in a sibling directory. The CLI prints instructions: navigate to the new directory, launch the AI assistant, and run the playbook.

The developer opens a second terminal, follows the instructions. Two playbooks run in parallel, each in its own worktree, each with its own isolated session. When both finish, session journals from both are in git with unique paths — no conflicts on merge.

**Why this priority**: Parallel execution multiplies the value of autonomous playbooks. Without worktree support, the developer is still limited to one feature at a time.

**Independent Test**: Can be tested by running the CLI start command twice with different features, verifying that two separate worktrees and sessions are created, and that both session directories have unique paths.

**Acceptance Scenarios**:

1. **Given** a clean git state, **When** running the CLI start command with a playbook and feature name, **Then** a new git worktree is created in a sibling directory and a session is initialized.
2. **Given** a dirty working tree, **When** running the CLI start command, **Then** the command fails with a clear error message explaining that a clean working tree is required.
3. **Given** two sessions created in separate worktrees, **When** both complete and are merged back, **Then** session directories have unique paths and produce no merge conflicts.

---

### User Story 5 - Playbook Validation Before Execution (Priority: P2)

A developer creates a custom playbook YAML file. Before running it, they want to verify it conforms to the schema. They run a CLI validation command pointing to their file. The validator checks that all steps reference valid commands, autonomy levels use the allowed vocabulary, error policies are valid, and pre/postconditions use the defined artifact check vocabulary.

If the playbook is valid, the command confirms success. If not, it lists each violation with the line and the issue.

**Why this priority**: Without validation, a malformed playbook would fail at runtime — potentially mid-execution after several steps have already run. Upfront validation prevents wasted work.

**Independent Test**: Can be tested by running the validator against both a valid playbook and an intentionally malformed one, verifying it accepts the valid file and rejects the invalid one with specific error messages.

**Acceptance Scenarios**:

1. **Given** a valid playbook YAML, **When** running the validation command, **Then** the command exits successfully with a confirmation message.
2. **Given** a playbook with an invalid autonomy level (e.g., "auto_always"), **When** running the validation command, **Then** the command reports the specific field and the allowed values.
3. **Given** a playbook missing a required field (e.g., step command), **When** running the validation command, **Then** the command reports the missing field.

---

### Edge Cases

- What happens when a playbook references a slash command that does not exist in the current project? The supervisor should report the error at the start before executing any steps.
- What happens when two sessions are created with the same timestamp and random ID? Session IDs must be unique — the system should retry ID generation if a collision occurs.
- What happens when the developer responds to a gate with an unrecognized answer? The supervisor should re-present the question with clearer options.
- What happens when a step's precondition requires an artifact from a previous step that was skipped? The supervisor should detect the unmet precondition and halt with an explanation.
- What happens when a parallel phase contains a step that fails while other parallel steps are still running? The supervisor should wait for all parallel steps to complete, then report all results before deciding on the error policy.
- What happens when the resume command is run in a directory that is not a git worktree and has no active session? The supervisor should report that no active session was found.
- What happens when a playbook has zero steps? The validator should reject it.

## Requirements *(mandatory)*

### Functional Requirements

#### Playbook Definition

- **FR-001**: Developer MUST be able to define a playbook as a structured file with ordered steps, each referencing a slash command to execute.
- **FR-002**: Developer MUST be able to assign one of four autonomy levels to each step: fully autonomous, gate only on breaking changes, always gate, or skip.
- **FR-003**: Developer MUST be able to declare preconditions per step using a fixed vocabulary of artifact checks (e.g., "spec exists", "plan exists", "tasks exist").
- **FR-004**: Developer MUST be able to declare postconditions per step using the same fixed vocabulary of artifact checks.
- **FR-005**: Developer MUST be able to assign one of three error policies per step: stop execution, retry once, or escalate to human gate.
- **FR-006**: Developer MUST be able to declare escalation triggers per step from a fixed vocabulary: postcondition failure, verdict failure, agreement breaking change, subagent error.
- **FR-007**: Developer MUST be able to declare parallel phases grouping multiple steps for simultaneous execution.
- **FR-008**: The system MUST provide a template playbook with commented documentation of all fields and allowed values.

#### Session Management

- **FR-009**: The supervisor MUST create a new session with a unique identifier at playbook start.
- **FR-010**: The session manifest MUST record the playbook name, arguments, start time, and current status.
- **FR-011**: The session journal MUST record each step's status, decision type (auto or escalated), duration, and any human responses.
- **FR-012**: Sessions MUST be stored in a predictable directory structure and be trackable in version control.
- **FR-013**: Developer MUST be able to resume a crashed session without providing any arguments — the system auto-detects the active session.
- **FR-014**: On resume, the supervisor MUST check the postcondition of the last in-progress step to determine whether to re-execute or advance.

#### Step Orchestration

- **FR-015**: The supervisor MUST delegate each step to a fresh execution context (no accumulated state from previous steps).
- **FR-016**: The supervisor MUST evaluate preconditions before executing each step and halt with an explanation if unmet.
- **FR-017**: The supervisor MUST evaluate postconditions after each step and proceed only if satisfied.
- **FR-018**: Steps in autonomous mode MUST execute without human interaction.
- **FR-019**: Steps marked as "skip" MUST be logged in the journal as skipped without execution.
- **FR-020**: Steps in a parallel phase MUST execute simultaneously, with the supervisor awaiting all completions before continuing to the next phase.
- **FR-021**: The supervisor MUST use the same slash commands as manual workflow execution — no bypass or shortcut.

#### Gate and Escalation

- **FR-022**: At an "always gate" step, the supervisor MUST halt and present context and a clear question before proceeding.
- **FR-023**: At a "gate on breaking" step, the supervisor MUST halt only when a breaking change is detected; otherwise it proceeds autonomously.
- **FR-024**: Developer MUST be able to respond to a gate, and the supervisor MUST resume execution based on the response.
- **FR-025**: When an escalation trigger fires on an autonomous step, the supervisor MUST promote it to a gate regardless of the step's configured autonomy level.
- **FR-026**: Every escalation event MUST be recorded in the journal with the trigger type and human response.

#### Error Handling

- **FR-027**: When a step with "stop" error policy fails, the supervisor MUST halt all execution and report the failure.
- **FR-028**: When a step with "retry once" error policy fails, the supervisor MUST retry exactly once before applying the next fallback action.
- **FR-029**: When a step with "gate" error policy fails, the supervisor MUST escalate to the developer with context about the failure.
- **FR-030**: On resume after crash, the supervisor MUST detect partially completed steps via postcondition checks and avoid unnecessary re-execution.

#### Worktree Management

- **FR-031**: Developer MUST be able to create a new session with a dedicated git worktree via a CLI command.
- **FR-032**: The CLI MUST validate git state (clean working tree) before creating a worktree and fail with a clear message if the state is dirty.
- **FR-033**: The CLI MUST print clear instructions for launching the AI assistant in the new worktree and starting the playbook.
- **FR-034**: Multiple playbook sessions MUST be able to run in parallel in separate worktrees without conflicts.

#### Validation and Scaffolding

- **FR-035**: Developer MUST be able to validate a playbook file against the strict schema before execution.
- **FR-036**: Validation MUST check that all autonomy levels, error policies, and escalation triggers use the allowed fixed vocabulary.
- **FR-037**: Validation MUST report specific violations with field references and allowed values.
- **FR-038**: Developer MUST be able to scaffold the playbook directory structure with an index, example playbooks, and template via a CLI command.
- **FR-039**: Developer MUST be able to refresh slash command templates without modifying existing playbooks or sessions.

#### Built-in Playbooks

- **FR-040**: The system MUST ship with an "auto-feature" playbook covering: plan, tasks, agreement, implement, agreement check, QA plan, QA run, PR creation.
- **FR-041**: The system MUST ship with an "auto-validate" playbook covering: QA plan, QA run — validating that the playbook format is generic and not coupled to the full feature workflow.

### Key Entities

- **Playbook**: A declarative definition of an ordered sequence of steps with autonomy levels, conditions, error policies, and escalation triggers. Identified by name, stored as a file in the playbooks directory.
- **Step**: A single unit of work within a playbook, referencing a slash command. Has an autonomy level, optional pre/postconditions, an error policy, and optional escalation triggers.
- **Session**: A runtime instance of a playbook execution. Has a unique ID, a manifest recording configuration, and a journal recording execution history. Stored in a dedicated directory.
- **Session Manifest**: Metadata about a session — which playbook, what arguments, when started, current status.
- **Session Journal**: Ordered log of step executions within a session — status, decision type, duration, human responses, escalation events.
- **Gate**: A point where the supervisor halts execution and requests human input. Can be structural (always gate) or dynamic (escalated from autonomous due to a trigger).
- **Escalation Trigger**: A condition that promotes an autonomous step to a gate. Fixed vocabulary: postcondition failure, verdict failure, agreement breaking change, subagent error.
- **Parallel Phase**: A group of steps configured to execute simultaneously, with the supervisor waiting for all to complete before advancing.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The auto-feature playbook completes a full run from plan to PR without the developer manually chaining commands — verified by session journal showing all steps executed in one session.
- **SC-002**: The supervisor chains at least 4 consecutive steps in autonomous mode without human intervention before reaching a gate — verified by journal entries with decision type "auto".
- **SC-003**: Artifacts produced by a playbook run are identical to those produced by manual slash command execution — verified by comparing outputs of both methods on the same feature.
- **SC-004**: A crashed session resumes correctly from the last incomplete step without re-executing completed steps — verified by interrupting a run, resuming, and checking the journal for no duplicate entries.
- **SC-005**: Developer attention per gate is under 30 seconds — the question is clear enough that the developer can respond immediately without needing to investigate context.
- **SC-006**: Playbook completion rate without unrecoverable crash exceeds 90% of runs — verified across at least 10 end-to-end runs.
- **SC-007**: The auto-validate playbook (QA plan + QA run) executes successfully, demonstrating that the playbook format supports workflows beyond the full feature loop.
- **SC-008**: Two playbook sessions run in parallel via separate git worktrees and both complete without conflicts — verified by merging both worktrees and checking for no path collisions in session directories.

## Assumptions

- The developer has already completed `/speckit.specify` (and optionally `/speckit.clarify`) before launching the auto-feature playbook. The playbook starts at the planning phase.
- Slash commands referenced in playbooks are idempotent or at minimum safe to re-run — if a step is re-executed on resume, the command produces correct results given the current artifact state.
- The developer's environment has git, the AI assistant CLI, and the project's CLI tools installed and accessible from the terminal.
- Session ID uniqueness is practically guaranteed by combining a timestamp with a random component — no centralized ID registry is needed.
- The AI assistant's Task tool provides sufficient context isolation between steps — each subagent starts with a fresh context window.
- Parallel step execution is bounded by the AI assistant's ability to run multiple Task subagents concurrently — the playbook system does not introduce its own parallelism mechanism.
- BMAD interactive steps (brief, PRD, architecture) are explicitly out of scope — they require sustained conversational interaction that is incompatible with autonomous execution.

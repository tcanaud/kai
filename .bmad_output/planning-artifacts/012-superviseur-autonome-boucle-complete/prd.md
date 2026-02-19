---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
classification:
  projectType: developer_tool
  domain: general
  complexity: medium
  projectContext: brownfield
inputDocuments:
  - .bmad_output/planning-artifacts/012-superviseur-autonome-boucle-complete/product-brief-kai-2026-02-18.md
  - .knowledge/architecture.md
  - .knowledge/snapshot.md
  - .knowledge/guides/project-philosophy.md
  - .knowledge/guides/commit-and-push.md
  - .knowledge/guides/create-new-package.md
  - .product/feedbacks/triaged/FB-002.md
  - .product/backlogs/promoted/BL-002.md
documentCounts:
  briefs: 1
  research: 0
  projectDocs: 6
  brainstorming: 0
workflowType: 'prd'
date: 2026-02-19
author: tcanaud
---

# Product Requirements Document — kai Playbook Supervisor

**Author:** tcanaud
**Date:** 2026-02-19

## Executive Summary

kai's feature workflow comprises 15+ steps from ideation to release, each triggered manually via slash commands. Between steps, developers must clear context, re-orient, and execute — a hard dependency on sustained focus that blocks all other work. The current `/feature.workflow` command correctly identifies the next action but cannot execute it. The developer remains the execution engine.

The Playbook Supervisor introduces an orchestration layer: YAML playbooks define step sequences with structural autonomy levels, deterministic pre/postconditions, error policies, escalation triggers, and parallel phases. A supervisor command (`/playbook.run`) reads the playbook, creates a persistent session with a git-tracked journal, delegates each step to a Task subagent with fresh context, and halts at declared gates for human decision. The developer shifts from executor to decider — responding only when the system needs a judgment call.

The first playbook — `auto-feature` — covers the post-specify feature workflow: plan, tasks, agreement, implement, agreement check, QA plan, QA run, PR. A second minimal playbook — `auto-validate` — covers QA only, validating the format's genericity. A new `@tcanaud/playbook` npm package provides both the `/playbook.run` slash command and an `npx @tcanaud/playbook start` CLI that automates git worktree creation for parallel playbook sessions.

### What Makes This Special

The supervisor uses the same slash commands as manual execution — no bypass, no shortcut. Every artifact, every gate, every traceability link remains intact. Governance is preserved by construction, not by discipline. Task subagents provide the equivalent of `/clear` between steps — context isolation is architectural, not behavioral.

The playbook system is fully deterministic at the structural level: autonomy levels (`auto`, `gate_on_breaking`, `gate_always`, `skip`), pre/postconditions, error policies (`stop`, `retry_once`, `gate`), and escalation triggers are a fixed vocabulary — playbooks compose from these building blocks, they cannot invent new ones. This ensures every playbook is predictable and every session journal is machine-readable. Sessions are persisted in `.playbooks/sessions/{timestamp}-{3-char-id}/` and tracked in git, enabling crash recovery via simple re-launch and full auditability of every decision.

## Project Classification

- **Project Type:** Developer Tool — CLI orchestration layer within Claude Code TUI
- **Domain:** General (project governance / developer productivity)
- **Complexity:** Medium — non-trivial orchestration with state management, re-entrance, and gate handling, but no external regulatory constraints
- **Project Context:** Brownfield — extends the existing kai governance stack, reuses established conventions (ESM, zero deps, file-based state, slash commands)

## Success Criteria

### User Success

| Criteria | Target | Measurement |
|----------|--------|-------------|
| Consecutive autonomous steps | >= 4 steps in `auto` mode without intervention | Step count in session journal |
| Developer attention per gate | < 30 sec per gate (clear question, direct answer) | Qualitative observation |
| Crash recovery | Re-running `/playbook.resume` resumes at correct step | Session journal read and current step identified |
| Delegation moment | Launch playbook, work on something else, return to gate or QA PASS | Manual MVP validation |

### Business Success

| Criteria | Target | Timeframe |
|----------|--------|-----------|
| First complete auto-feature run | 1 run spec→PR without manual command chaining | MVP |
| Second playbook functional | `auto-validate` (qa.plan → qa.run) validates generic format | MVP |
| Worktree multi-session | 2 playbooks running in parallel via worktrees | MVP |
| Custom playbooks created | >= 2 additional playbooks | 3 months post-MVP |

### Technical Success

| Criteria | Target |
|----------|--------|
| Artifact parity | 100% identical to manual workflow — same commands, same outputs |
| Structural determinism | Autonomy levels, pre/postconditions, error policies = fixed vocabulary, no free-text |
| Session journal | Every run produces a concise journal, git-trackable, readable by `/playbook.resume` for resume |
| Escalation | A trigger in `auto` mode correctly promotes to gate |
| Parallelism | Parallel phases execute N steps simultaneously and await completion |

### Measurable Outcomes

- Playbook completion rate without crash: > 90%
- Correct escalation rate (trigger → gate): 100% (deterministic)
- Artifact parity: 100% (empty diff between playbook output and manual output)
- Session journal present and readable after every run: 100%

## User Journeys

### Journey 1: Thibaud — "Spec to PR While I Work on Something Else"

Thibaud has just finished `/speckit.specify` for feature 013. The spec is solid, validated, ready. Ahead of him: plan, tasks, agreement, implement, agreement check, QA, PR — seven steps, seven context switches, an hour of sequential attention.

He types `/playbook.run auto-feature 013-...`. The supervisor starts, reads the playbook, creates the session. The first three steps (plan, tasks, agreement) are in `auto` mode — the supervisor chains them without interruption. Thibaud switches to another terminal to work on a bugfix.

Twenty minutes later, the supervisor reaches `speckit.implement`. The implementation generates code. The postcondition fails: a test breaks. The supervisor escalates — even though the step was `auto`, the `postcondition_fail` trigger forces a gate. The journal logs the escalation. Thibaud returns, reads the clear question in the TUI: "Implementation done but test X fails. Fix and continue, or abort?" He fixes the test, types "continue". The supervisor resumes.

Agreement check, QA plan, QA run chain automatically. QA PASS. The `feature.pr` step is `gate_always` — the supervisor halts and presents the summary: "PR ready. 8/8 steps done. Create PR?" Thibaud approves. PR created.

**Capabilities revealed**: Task subagent delegation, escalation on postcondition failure, gate interaction in TUI, session resume, journal logging.

### Journey 2: Thibaud — "Crash Recovery at Step 5"

Thibaud launches a playbook. The supervisor chains 4 steps. At the fifth, crash — network timeout, terminal closed.

He reopens a terminal, `cd` into the worktree (the directory is there, visible). Launches `claude`. Types `/playbook.resume`. The supervisor runs `git worktree list` to identify the current worktree, deduces the session namespace, and finds `20260219-a7k/`. Reads the journal: steps 1-4 done, step 5 in_progress. Checks the postcondition of step 5: artifact present? Yes → mark done, move to 6. No → re-run step 5.

No arguments needed, no data lost, no step unnecessarily re-executed.

**Capabilities revealed**: `/playbook.resume` command, git worktree identification, session auto-detection, journal-based resume, postcondition-driven state detection, idempotent restart.

### Journey 3: Reviewer — "What Happened During This Run?"

Thibaud opens a PR for feature 013. In the diff, he sees `.playbooks/sessions/20260219-a7k/journal.yaml`. He reads:

```yaml
- step: speckit.plan
  status: done
  decision: auto
  duration: 45s
- step: speckit.tasks
  status: done
  decision: auto
  duration: 30s
- step: speckit.implement
  status: done
  decision: escalated
  trigger: postcondition_fail
  human_response: "fixed test, continue"
  duration: 12m
```

Every decision is traceable. The escalation is visible. The human response is recorded. If anyone asks "why did implementation take 12 minutes?", the answer is in the journal. Free audit — just read the file.

**Capabilities revealed**: Journal as audit trail, git-tracked decisions, human responses recorded, traceability in PR review.

### Journey 4: Thibaud — "Parallel Features via Worktree"

Thibaud has an active playbook for 013. He also wants to launch feature 014. He types:

```bash
$ npx @tcanaud/playbook start auto-feature 014-new-thing
✓ Session 20260219-b3m created
✓ Worktree created at ../kai-session-20260219-b3m
→ Run: cd ../kai-session-20260219-b3m && claude
→ Then type: /playbook.run auto-feature 014-new-thing
```

He opens a second terminal, follows the instructions. Two playbooks run in parallel, each in its own worktree, each with its own session. When both finish, he merges the worktrees back into the main repo. Both session journals are in git.

**Capabilities revealed**: `npx @tcanaud/playbook start` CLI, worktree creation, session isolation, parallel execution.

### Journey Requirements Summary

| Capability | Journeys |
|-----------|----------|
| Task subagent delegation per step | 1, 2 |
| Autonomy levels (`auto`, `gate_always`) | 1 |
| Escalation on trigger (postcondition_fail) | 1, 2 |
| Gate interaction in TUI | 1 |
| Session persistence + journal | 1, 2, 3, 4 |
| `/playbook.resume` (argumentless, git worktree detection) | 2 |
| Journal as audit trail in git | 3 |
| `npx @tcanaud/playbook start` + worktree | 4 |
| Parallel sessions via worktrees | 4 |

## Product Scope & Phased Development

### MVP Strategy

**MVP Approach:** Problem-solving MVP — prove that the orchestration loop works end-to-end with one complete playbook run. The MVP is ambitious but self-contained: every deliverable is necessary for the first run to succeed.

**Resource:** Solo developer (tcanaud). Dense but feasible — the system reuses existing kai commands, it orchestrates rather than reimplements.

**New package: `@tcanaud/playbook`**

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:** J1 (spec to PR), J2 (crash recovery), J4 (parallel via worktree)

**Must-Have Capabilities:**

1. **Playbook YAML schema** — Autonomy levels, pre/postconditions, error policies, escalation triggers, parallel phases. Fixed vocabulary, no free-text.
2. **`npx @tcanaud/playbook check {file}`** — Schema validator. Validates playbook YAML against strict schema before execution.
3. **`/playbook.run {playbook} {args}`** — Supervisor: read playbook, create session, delegate steps to Task subagents, evaluate conditions, handle escalation, log journal.
4. **`/playbook.resume`** — Argumentless resume via git worktree detection + session journal.
5. **`npx @tcanaud/playbook start {playbook} {args}`** — Create session ID + git worktree + print instructions. Defensive: check git state before worktree creation.
6. **Persistent sessions** — `.playbooks/sessions/{timestamp}-{3-char-id}/` with `session.yaml` + `journal.yaml`. Git-tracked.
7. **Playbook `auto-feature`** — speckit.plan → speckit.tasks → agreement.create → speckit.implement → agreement.check → qa.plan → qa.run → feature.pr
8. **Playbook `auto-validate`** — qa.plan → qa.run. Validates format genericity.
9. **Template playbook** — `.playbooks/templates/playbook.tpl.yaml` — commented skeleton for custom playbooks.
10. **YAML index** — `.playbooks/_index.yaml`
11. **Documentation** — Knowledge guide `.knowledge/guides/playbook-authoring.md`

**Removed from MVP:** `/playbook.list`, `/playbook.status` (nice-to-have, not essential for first run)

### Phase 2 — Growth

- `/playbook.list` — list available playbooks
- `/playbook.status` — current session status
- Additional playbooks: `auto-hotfix`, `auto-intake`
- Composability: a playbook references another as sub-routine
- Option B for `npx @tcanaud/playbook start`: direct claude exec
- Run metrics: duration per step, success rate

### Phase 3 — Expansion

- Interactive playbook designer (`/playbook.create`)
- Team gate policies (`.playbooks/policies/`)
- Session history as retrospective tool
- Multi-feature concurrent runs in same TUI

### Risk Mitigation Strategy

| Risk | Severity | Mitigation |
|------|----------|------------|
| YAML parsing complexity | Medium | `npx @tcanaud/playbook check` validates against strict schema before execution. Schema designed to stay within regex parser capabilities. |
| Task subagent reliability | Medium | Accepted risk. Error policies (`retry_once`, `gate`) and escalation triggers provide recovery paths. Journal enables manual resume. |
| Worktree edge cases | Low | `npx @tcanaud/playbook start` checks git state (clean working tree, no conflicts) before `git worktree add`. Clear error messages on failure. |
| Ambitious MVP scope | Medium | All deliverables are necessary for first run. Non-essential commands (`list`, `status`) removed. System reuses existing kai commands — orchestration, not reimplementation. |

## Developer Tool Specific Requirements

### Command Surface (MVP)

| Command | Type | Purpose |
|---------|------|---------|
| `/playbook.run {playbook} {args}` | Slash command | Launch a playbook, create session, execute steps |
| `/playbook.resume` | Slash command | Resume crashed session (auto-detects via git worktree) |
| `npx @tcanaud/playbook start {playbook} {args}` | CLI | Create session ID + git worktree + print instructions |
| `npx @tcanaud/playbook check {file}` | CLI | Validate playbook YAML against strict schema |
| `npx @tcanaud/playbook init` | CLI | Scaffold `.playbooks/` directory with index, examples, and template |
| `npx @tcanaud/playbook update` | CLI | Refresh slash command templates |

### Runtime Requirements

- Node.js >= 18.0.0 (ESM)
- Zero runtime dependencies (`node:` protocol only)
- Git (for worktree operations)
- GitHub CLI `gh` (for PR-related steps only)
- Claude Code CLI (for slash command execution)

### Documentation

- **In-repo**: `README.md` in the `@tcanaud/playbook` package repo — full schema reference with field descriptions
- **Knowledge guide**: `.knowledge/guides/playbook-authoring.md` — how to create custom playbooks, with the fixed vocabulary reference
- **Template playbook**: `.playbooks/templates/playbook.tpl.yaml` — commented skeleton for custom playbooks

### Implementation Considerations

- YAML parsing via regex (no YAML library — kai convention)
- Session files must be writable during playbook execution and committable after
- Worktree creation uses `git worktree add` — requires clean working tree on target branch
- Slash commands are Markdown templates in `.claude/commands/` — installed by `npx @tcanaud/playbook init`
- `npx tcsetup` installs the playbook package alongside other kai tools

## Functional Requirements

### Playbook Definition

- FR1: Developer can define a playbook as a YAML file with ordered steps, each referencing a slash command
- FR2: Developer can assign an autonomy level (`auto`, `gate_on_breaking`, `gate_always`, `skip`) to each step in a playbook
- FR3: Developer can declare preconditions per step using a fixed vocabulary of artifact checks
- FR4: Developer can declare postconditions per step using a fixed vocabulary of artifact checks
- FR5: Developer can declare an error policy (`stop`, `retry_once`, `gate`) per step
- FR6: Developer can declare escalation triggers per step from a fixed vocabulary (`postcondition_fail`, `verdict_fail`, `agreement_breaking`, `subagent_error`)
- FR7: Developer can declare parallel phases grouping multiple steps for simultaneous execution
- FR8: Developer can validate a playbook YAML against the strict schema via `npx @tcanaud/playbook check {file}`
- FR9: Developer can copy a commented template playbook to create a new custom playbook
- FR10: System indexes all available playbooks in `.playbooks/_index.yaml`

### Session Management

- FR11: Supervisor creates a new session with a unique ID (`{timestamp}-{3-char-random}`) at playbook start
- FR12: Session manifest (`session.yaml`) records playbook name, arguments, start time, and status
- FR13: Session journal (`journal.yaml`) records each step's status, decision type, duration, and human responses
- FR14: Sessions are stored in `.playbooks/sessions/{id}/` and are git-trackable
- FR15: Developer can resume a crashed session via `/playbook.resume` without providing any arguments
- FR16: `/playbook.resume` identifies the active session by querying git worktree namespace

### Step Orchestration

- FR17: Supervisor delegates each step to a Task subagent with fresh context
- FR18: Supervisor evaluates preconditions before executing each step
- FR19: Supervisor evaluates postconditions after each step completes
- FR20: Supervisor executes steps in `auto` mode without human interaction
- FR21: Supervisor skips steps marked `skip` and logs the skip in the journal
- FR22: Supervisor executes parallel phase steps simultaneously and awaits all completions before continuing
- FR23: Supervisor uses the same slash commands as manual workflow execution — no bypass

### Gate & Escalation

- FR24: Supervisor halts at `gate_always` steps and presents context and a clear question in the TUI
- FR25: Supervisor halts at `gate_on_breaking` steps only when a breaking change is detected
- FR26: Developer can respond to a gate in the TUI and the supervisor resumes execution
- FR27: Supervisor escalates to a gate when an escalation trigger fires, even if the step was `auto`
- FR28: Escalation events are logged in the journal with trigger type and human response

### Error Handling

- FR29: Supervisor stops execution when a step's error policy is `stop` and the step fails
- FR30: Supervisor retries once when a step's error policy is `retry_once` and the step fails
- FR31: Supervisor escalates to a human gate when a step's error policy is `gate` and the step fails
- FR32: On resume after crash, supervisor detects partially completed steps via postcondition checks and avoids re-execution

### Worktree Management

- FR33: Developer can create a new session with a dedicated git worktree via `npx @tcanaud/playbook start {playbook} {args}`
- FR34: `npx @tcanaud/playbook start` validates git state (clean working tree) before creating a worktree
- FR35: `npx @tcanaud/playbook start` prints clear instructions for launching Claude Code in the worktree
- FR36: Multiple playbook sessions can run in parallel in separate worktrees

### Audit & Traceability

- FR37: Every step execution is logged in the session journal with status, decision type, and duration
- FR38: Every human gate response is recorded in the session journal
- FR39: Every escalation event is recorded in the session journal with trigger type
- FR40: Session journals are reviewable in git diffs and pull requests
- FR41: Playbook-produced artifacts are identical to those produced by manual slash command execution

### Installation & Documentation

- FR42: `npx @tcanaud/playbook init` scaffolds the `.playbooks/` directory with index, example playbooks, and template
- FR43: `npx @tcanaud/playbook update` refreshes slash command templates without modifying user playbooks or sessions
- FR44: A knowledge guide documents the playbook authoring process and fixed vocabulary reference

## Non-Functional Requirements

### Reliability

- NFR1: A crashed playbook session can be fully resumed by re-launching `/playbook.resume` — no data loss, no step re-execution if postcondition is satisfied
- NFR2: Session journal is written after each step completion — a crash mid-step loses at most the current step's work
- NFR3: `npx @tcanaud/playbook check` rejects any playbook YAML that does not conform to the strict schema — invalid playbooks never reach execution
- NFR4: Postcondition validation is deterministic — same filesystem state always produces the same pass/fail result

### Integration

- NFR5: All slash commands (`/playbook.run`, `/playbook.resume`) execute within Claude Code TUI using the Task tool for subagent delegation
- NFR6: Git operations (`worktree add`, `worktree list`) use standard git CLI — no library, no wrapper
- NFR7: GitHub CLI (`gh`) is required only for PR-related steps — playbooks without PR steps work without `gh`
- NFR8: Playbook system reads and writes only to `.playbooks/` directory and does not modify artifacts produced by other kai tools

### Compatibility

- NFR9: Package follows kai conventions — ESM-only, zero runtime dependencies, `node:` protocol imports, Node.js >= 18.0.0
- NFR10: YAML parsing uses the same regex-based approach as other kai packages — no YAML library
- NFR11: Any project with kai installed can adopt playbooks via `npx @tcanaud/playbook init` without modifying existing kai configuration
- NFR12: Playbook sessions produced in a git worktree can be merged back to the main branch without conflicts on `.playbooks/sessions/` (unique session IDs guarantee no path collision)

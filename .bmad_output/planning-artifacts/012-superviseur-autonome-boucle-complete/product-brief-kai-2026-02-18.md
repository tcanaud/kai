---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments:
  - .knowledge/snapshot.md
  - .knowledge/guides/project-philosophy.md
  - .knowledge/guides/commit-and-push.md
  - .knowledge/guides/create-new-package.md
  - .knowledge/index.yaml
  - .product/feedbacks/triaged/FB-002.md
  - .product/backlogs/promoted/BL-002.md
date: 2026-02-18
author: tcanaud
---

# Product Brief: kai

## Executive Summary

kai's feature workflow comprises 15+ steps from ideation to release, each triggered manually via slash commands. Between each step, developers must clear context and re-orient. This constant attention requirement means features only progress when the developer is actively driving — there is no delegation possible.

The Playbook Supervisor introduces a declarative orchestration layer: YAML playbooks define step sequences, autonomous decision rules, and human gates. A supervisor prompt executes within the Claude Code TUI, delegating each step to a Task subagent (ensuring clean context), making small decisions autonomously, and halting at gates for human approval. The first playbook — "auto-feature" — covers the post-clarify feature workflow (plan → tasks → agreement → implement → QA → PR).

---

## Core Vision

### Problem Statement

Developers using kai must manually chain 15+ slash commands to drive a feature from ideation to release. Each step requires: running `/feature.workflow` to identify the next action, clearing context with `/clear`, executing the command, then repeating. This creates a hard dependency on sustained developer focus — if attention shifts, the feature stalls.

### Problem Impact

- **Time cost**: Each context switch (clear → orient → execute) adds friction that compounds across 15 steps
- **Attention lock**: The developer cannot delegate feature progression to work on other tasks
- **Error-prone**: Manual sequencing risks skipping steps, missing gates, or losing context between phases
- **Bottleneck**: In a multi-feature project, only one feature progresses at a time because the developer is the orchestrator

### Why Existing Solutions Fall Short

The current `/feature.workflow` command is re-entrant and stateless — it correctly identifies the next step by scanning artifacts. But it is purely advisory: it tells you what to do, it does not do it. The developer remains the execution engine. There is no mechanism to chain commands, delegate decisions, or define when human intervention is truly needed vs. when the system can proceed autonomously.

### Proposed Solution

A **playbook system** built on three components:

1. **Playbook YAML** — A declarative file defining: ordered steps, the slash command for each step, autonomous decision rules (e.g., "choose Full workflow path"), and human gates (e.g., "stop before PR creation")
2. **Supervisor prompt** — A slash command (`/playbook.run`) that reads the playbook, scans current artifact state, and orchestrates execution within the Claude Code TUI
3. **Task subagent delegation** — Each step is executed by a Task subagent with fresh context (solving the context window problem), while the supervisor maintains a lightweight orchestration loop

The supervisor uses the **same slash commands** as manual execution — no bypass, no shortcut. Traceability and governance remain intact. At human gates, the supervisor halts and asks the developer in the TUI, preserving the interactive dialogue.

### Key Differentiators

- **Same commands, automated**: The playbook doesn't replace the workflow — it drives it. Every artifact is created through the same proven commands
- **Declarative gates**: Human intervention points are explicit in the YAML, not hardcoded. Different playbooks can have different gate policies
- **Context-fresh execution**: Task subagents provide the equivalent of `/clear` between each step — by design, not by discipline
- **TUI-native**: The supervisor runs in the developer's Claude Code session, preserving the ability to dialogue at gates
- **Playbook-as-convention**: The YAML format is a new kai convention — future playbooks can cover other loops (intake → triage → promote, or custom project workflows)

---

## Target Users

### Primary Users

**Thibaud — Solo Developer / Project Owner**

Developer who maintains one or more projects using the kai governance stack. Comfortable with Claude Code, slash commands, and the full feature workflow. Currently drives every feature manually through 15+ steps, clearing context between each phase.

- **Context**: Works alone or in a small team, manages multiple features in parallel
- **Pain**: Cannot delegate feature progression — must stay focused on the loop or nothing moves. Context switching between features is expensive
- **Current workaround**: `/feature.workflow` → `/clear` → execute command → repeat. Relies on memory and discipline to maintain sequencing
- **Success moment**: Launches `/playbook.run`, walks away to work on something else, comes back to find the feature at a human gate with a clear question waiting — or already at QA PASS

### Secondary Users

**Tech Lead — Playbook Designer**

Technical leader on a team adopting kai. Doesn't necessarily run playbooks daily, but defines the gate policies and step sequences for the team. Creates custom playbooks with stricter or looser gates depending on feature criticality.

- **Context**: Responsible for quality and governance across multiple developers
- **Value**: Encodes team policies (e.g., "always gate before PR on critical features", "skip agreement check on hotfixes") as declarative YAML rather than documentation nobody reads
- **Success moment**: A junior developer runs the same playbook and produces governance-compliant features without needing to understand the full workflow

### User Journey

1. **Discovery**: Developer already uses kai. Notices the playbook system after a `tcsetup update` or sees it in `/feature.workflow` output
2. **Onboarding**: Runs `/playbook.run {feature}` for the first time on a feature that already has a spec. Watches the supervisor chain steps automatically
3. **Core usage**: Launches a playbook, works on other tasks. Returns to TUI when a gate halts the supervisor. Answers the gate question, supervisor resumes
4. **Aha moment**: A feature goes from spec to QA PASS in one session without manual intervention between steps
5. **Long-term**: Creates custom playbooks for different feature types. The playbook YAML becomes part of the project's governance conventions

---

## Success Metrics

### User Success

| Metric | Baseline (manual) | Target | Measurement |
|--------|-------------------|--------|-------------|
| Steps automated per run | 0 | 3-4+ steps chained before human gate | Count of Task subagent completions per `/playbook.run` invocation |
| Time to first human gate | ~15 min (manual context switches) | < 3 min of developer attention | Elapsed time from `/playbook.run` to first gate halt |
| Artifact parity | N/A | 100% identical | Artifacts produced by playbook must be indistinguishable from manual execution |
| Playbook completion rate | N/A | > 90% runs complete without crash | Runs that reach either a human gate or final step without error |

### Business Objectives

- **Time recovery**: Developer reclaims the attention cycles between steps — the primary value is not speed but the ability to work on other tasks while the playbook progresses
- **Quality preservation**: No governance regression — every artifact, every gate, every traceability link remains intact because the supervisor uses the same commands
- **Convention adoption**: The playbook YAML format becomes a reusable kai convention, enabling future automation of other loops

### Key Performance Indicators

| KPI | Target | Timeframe |
|-----|--------|-----------|
| First playbook runs end-to-end (spec → QA) | 1 successful run | MVP |
| Steps executed without manual intervention | >= 4 consecutive steps | MVP |
| Supervisor crash/error rate | < 10% of runs | Post-MVP |
| Custom playbooks created by users | >= 2 distinct playbooks | 3 months |

---

## MVP Scope

### Core Features

1. **Playbook YAML schema** — Declarative format defining: ordered steps with command references, human gate declarations, autonomous decision rules, artifact preconditions per step
2. **Supervisor slash command (`/playbook.run`)** — Reads the playbook YAML, scans current artifact state (reusing `/feature.workflow` logic), orchestrates the execution loop via Task subagents, maintains lightweight state in the TUI conversation
3. **First playbook: `auto-feature`** — Covers the post-clarify feature workflow: `/speckit.plan` → `/speckit.tasks` → `/agreement.create` → `/speckit.implement` → `/agreement.check` → `/qa.plan` → `/qa.run`
4. **Human gate mechanism** — Supervisor halts at declared gates, presents context and a clear question in the TUI, resumes after user response
5. **Error handling** — On step failure, supervisor reports the error with context and stops. User follows the standard manual flow to resolve, then re-runs `/playbook.run` to continue from where it left off (re-entrant by artifact scan)

### Out of Scope for MVP

- Playbooks for other loops (intake → triage → promote, custom workflows)
- Playbook editor, validator, or linter
- BMAD interactive steps (brief, PRD, architecture) — too conversational for autonomous execution
- Automatic retry on step failure
- Parallel step execution
- Run metrics, reporting, or history tracking
- Multi-feature concurrent playbook runs

### MVP Success Criteria

| Criteria | Validation |
|----------|-----------|
| One full run completes | `auto-feature` playbook drives a feature from spec to QA verdict without manual command chaining |
| >= 4 consecutive autonomous steps | Supervisor chains plan → tasks → agreement → implement without human intervention |
| Artifact parity | Artifacts produced are identical to those from manual `/feature.workflow` execution |
| Gate interaction works | Supervisor halts, asks in TUI, resumes correctly after user input |
| Re-entrant on failure | After a crash or error, re-running `/playbook.run` resumes from the correct step |

### Future Vision

- **Playbook library**: Multiple playbooks for different workflows — `auto-feature`, `auto-hotfix` (quick flow, no agreement), `auto-intake` (feedback → triage → promote)
- **Composable steps**: Playbooks can reference other playbooks as sub-routines
- **Gate policies as conventions**: Team-level gate configurations stored in `.playbooks/policies/` and enforced via agreements
- **Run history**: Optional log of playbook executions for retrospectives and process improvement
- **Parallel orchestration**: Run multiple playbooks concurrently on different features

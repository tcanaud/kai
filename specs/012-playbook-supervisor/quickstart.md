# Quickstart: Playbook Supervisor

**Branch**: `012-playbook-supervisor` | **Date**: 2026-02-19

## Prerequisites

- Node.js >= 18.0.0
- Git
- Claude Code CLI
- GitHub CLI (`gh`) — only required for PR-related steps

## Installation

```bash
npx @tcanaud/playbook init
```

This creates:
- `.playbooks/` directory with built-in playbooks and template
- `.claude/commands/playbook.run.md` and `playbook.resume.md` slash commands

## Basic Usage

### Run a Full Feature Workflow

In Claude Code TUI, after finishing `/speckit.specify` and `/speckit.clarify`:

```
/playbook.run auto-feature 012-playbook-supervisor
```

The supervisor will:
1. Chain plan → tasks → agreement → implement → agreement check → QA plan → QA run → PR
2. Execute steps autonomously where configured
3. Halt at gates for your decision
4. Log every step in a session journal

### Resume After Interruption

If the terminal crashes or you close it mid-run:

```
/playbook.resume
```

No arguments needed — the supervisor auto-detects the active session.

### Run QA Only

```
/playbook.run auto-validate 012-playbook-supervisor
```

Runs just `qa.plan` → `qa.run` — useful for re-validating after fixes.

## Parallel Execution

Run two features simultaneously in separate worktrees:

```bash
# Terminal 1: already running a playbook for feature 012

# Terminal 2: start a parallel session for feature 013
npx @tcanaud/playbook start auto-feature 013-another-feature
# Follow the printed instructions
```

## Validate a Custom Playbook

```bash
npx @tcanaud/playbook check .playbooks/playbooks/my-workflow.yaml
```

## Create a Custom Playbook

```bash
cp .playbooks/playbooks/playbook.tpl.yaml .playbooks/playbooks/my-workflow.yaml
```

Edit the file — the template includes comments explaining every field and allowed values.

## Available Playbooks

| Playbook | Steps | Description |
|----------|-------|-------------|
| `auto-feature` | 8 | Full workflow: plan → tasks → agreement → implement → agreement check → QA plan → QA run → PR |
| `auto-validate` | 2 | QA only: QA plan → QA run |

## Session Files

After a run, session files are in `.playbooks/sessions/{id}/`:

- `session.yaml` — manifest (playbook, feature, status, timestamps)
- `journal.yaml` — step-by-step execution log (status, decision type, duration, human responses)

These files are git-tracked and appear in PR diffs for auditability.

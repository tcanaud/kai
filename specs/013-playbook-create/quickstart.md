# Quickstart: /playbook.create

**Feature**: 013-playbook-create | **Date**: 2026-02-19

## Prerequisites

- `@tcanaud/playbook` >= 1.2.0 installed in your project
- `.playbooks/` directory initialized (`npx @tcanaud/playbook init`)
- Claude Code session active

## Installation

```bash
# If already using @tcanaud/playbook, update to get the new command:
npx @tcanaud/playbook update

# If starting fresh:
npx @tcanaud/playbook init
```

This installs the `/playbook.create` slash command to `.claude/commands/playbook.create.md`.

## Usage

### Create a playbook from a free-text intention

In Claude Code, run:

```
/playbook.create validate and deploy a hotfix for critical bugs
```

The system will:
1. Analyze your project (installed tools, available commands, existing playbook patterns)
2. Map your intention to a sequence of slash commands
3. Generate a valid playbook YAML file
4. Present it for your review
5. Accept modifications if needed
6. Write the final playbook to `.playbooks/playbooks/{name}.yaml`
7. Update the playbook index

### Example output

For the intention "validate and deploy a hotfix for critical bugs", the system might generate:

```yaml
name: "critical-hotfix-deploy"
description: "Validate and deploy a hotfix for critical production bugs"
version: "1.0"

args:
  - name: "feature"
    description: "Feature branch name for the hotfix (e.g., 042-fix-login-crash)"
    required: true

steps:
  - id: "implement"
    command: "/speckit.implement"
    args: ""
    autonomy: "auto"
    preconditions: []
    postconditions: []
    error_policy: "retry_once"
    escalation_triggers:
      - "postcondition_fail"
      - "subagent_error"

  - id: "agreement-check"
    command: "/agreement.check"
    args: "{{feature}}"
    autonomy: "gate_on_breaking"
    preconditions: []
    postconditions:
      - "agreement_pass"
    error_policy: "gate"
    escalation_triggers:
      - "agreement_breaking"

  - id: "qa-plan"
    command: "/qa.plan"
    args: "{{feature}}"
    autonomy: "auto"
    preconditions:
      - "agreement_pass"
    postconditions:
      - "qa_plan_exists"
    error_policy: "stop"
    escalation_triggers: []

  - id: "qa-run"
    command: "/qa.run"
    args: "{{feature}}"
    autonomy: "auto"
    preconditions:
      - "qa_plan_exists"
    postconditions:
      - "qa_verdict_pass"
    error_policy: "gate"
    escalation_triggers:
      - "verdict_fail"

  - id: "pr"
    command: "/feature.pr"
    args: "{{feature}}"
    autonomy: "gate_always"
    preconditions:
      - "qa_verdict_pass"
    postconditions:
      - "pr_created"
    error_policy: "stop"
    escalation_triggers: []
```

### Validate the generated playbook

```bash
npx @tcanaud/playbook check .playbooks/playbooks/critical-hotfix-deploy.yaml
```

### Run the generated playbook

```
/playbook.run critical-hotfix-deploy 042-fix-login-crash
```

## Interactive Refinement

After the system generates the playbook, you can request modifications:

- "Change the PR step to auto" (modifies autonomy level)
- "Add a knowledge refresh step before implementation" (adds a step)
- "Remove the agreement check step" (removes with dependency warning)
- "Reorder: run QA before agreement check" (reorders steps)
- "Rename to hotfix-pipeline" (changes the playbook name)

Each modification is re-validated automatically. Say "done" or "save" when satisfied.

## Naming Conflicts

If a playbook with the same name already exists, the system will ask:
1. **Overwrite**: Replace the existing playbook
2. **Rename**: Choose a different name
3. **Cancel**: Abort creation (no files changed)

## Troubleshooting

### "Playbook system not installed"
Run `npx @tcanaud/playbook init` first.

### "No available commands match your intention"
Your intention may reference tools not installed in this project. Install the relevant kai packages or rephrase your intention to match available commands.

### "Command not found: /playbook.create"
Update the playbook package: `npx @tcanaud/playbook update`

### Generated playbook fails validation
This should not happen (the system validates before presenting). If it does, run `npx @tcanaud/playbook check {file}` to see violations, then modify the playbook manually or re-run `/playbook.create`.

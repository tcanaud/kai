# Research: /playbook.create Command

**Feature**: 013-playbook-create | **Date**: 2026-02-19

## R1: Slash Command vs. Code — Where Does Generation Logic Live?

**Decision**: Pure slash command prompt (`.claude/commands/playbook.create.md`).

**Rationale**: The core challenge — interpreting a free-text intention, mapping it to available commands, choosing appropriate autonomy levels, generating valid YAML — is fundamentally an AI task. A Node.js program cannot interpret "validate and deploy a hotfix for critical bugs" and produce a meaningful step sequence. The existing pattern in kai confirms this: `/playbook.run` (the supervisor) is also a slash command prompt, not Node.js code, because it needs Claude Code's Task tool for subagent delegation.

The only code change needed is in `installer.js` and `updater.js` to add `playbook.create.md` to the list of slash command templates that get copied to `.claude/commands/`.

**Alternatives considered**:
- Node.js code with template-based generation: Rejected. Cannot interpret natural language. Would produce rigid, template-like playbooks that miss the spec's core value proposition (SC-001: "usable playbook within a single interaction session").
- Hybrid approach (Node.js scanner + AI generator): Rejected. Claude Code can already scan the filesystem using its Read and Bash tools. Adding a Node.js scanner would duplicate capability and add maintenance burden.
- MCP server approach: Rejected. No existing pattern in kai. Over-engineering for a single slash command.

## R2: Project Analysis — What to Scan and How

**Decision**: Structured 5-phase project scan performed by the AI at the start of each `/playbook.create` invocation.

### Phase 1: Tool Detection

Scan for marker directories to identify installed kai tools:

| Marker Directory | Tool | Available Conditions |
|-----------------|------|---------------------|
| `.adr/` | ADR System | (none in playbook vocabulary) |
| `.agreements/` | Agreement System | `agreement_exists`, `agreement_pass` |
| `.features/` | Feature Lifecycle | (none directly, but implies feature workflow) |
| `.knowledge/` | Knowledge System | (none in playbook vocabulary) |
| `.qa/` | QA System | `qa_plan_exists`, `qa_verdict_pass` |
| `.product/` | Product Manager | (none in playbook vocabulary) |
| `specs/` | Speckit | `spec_exists`, `plan_exists`, `tasks_exists` |
| `_bmad/` | BMAD Framework | (none in playbook vocabulary) |
| `.playbooks/` | Playbook Supervisor | (meta — always present if this command is available) |

**Implementation**: Use Bash tool with `ls -d` to check each directory. Build a map of installed tools and their associated usable conditions.

### Phase 2: Command Discovery

List all `.claude/commands/*.md` files. Extract command names from filenames using the convention `{namespace}.{command}.md` -> `/{namespace}.{command}`.

**Key distinction**: Not all files follow the namespace.command pattern. Files like `bmad-agent-bmm-dev.md` use hyphens, not dots. The generator should focus on dot-separated names that correspond to executable commands (e.g., `/speckit.plan`, `/qa.run`, `/agreement.check`), while noting hyphenated BMAD entries as available but not typically used in playbook steps.

**Implementation**: Parse filenames, group by namespace, identify which commands are actionable in a playbook context.

### Phase 3: Existing Playbook Pattern Extraction

Read all `.playbooks/playbooks/*.yaml` (excluding `playbook.tpl.yaml` template). For each playbook, extract:

- **Autonomy patterns**: Which command types use which autonomy levels (e.g., PR creation -> `gate_always`, QA steps -> `auto`)
- **Condition chains**: How preconditions flow into postconditions across steps (e.g., `plan_exists` as postcondition of plan step, precondition of tasks step)
- **Error policy patterns**: Which step types use which policies (e.g., implementation -> `retry_once`, validation -> `gate`)
- **Naming conventions**: Slug format, step ID patterns (lowercase, hyphenated)
- **Escalation trigger usage**: Which triggers are paired with which step types

**Current patterns observed** from existing playbooks (`auto-feature`, `auto-validate`, `intention-to-pr`):

| Step Type | Autonomy | Error Policy | Escalation Triggers |
|-----------|----------|-------------|---------------------|
| `/speckit.plan` | `auto` | `stop` | `[]` |
| `/speckit.tasks` | `auto` | `stop` | `[]` |
| `/agreement.create` | `auto` | `gate` | `[subagent_error]` |
| `/speckit.implement` | `auto` | `retry_once` | `[postcondition_fail, subagent_error]` |
| `/agreement.check` | `gate_on_breaking` | `gate` | `[agreement_breaking]` |
| `/qa.plan` | `auto` | `stop` | `[]` |
| `/qa.run` | `auto` | `gate` or `stop` | `[verdict_fail]` or `[]` |
| `/feature.pr` | `gate_always` | `stop` | `[]` |
| `/product.intake` | `auto` | `gate` | `[subagent_error]` |
| `/product.triage` | `auto` | `gate` | `[subagent_error]` |
| `/product.promote` | `gate_always` | `gate` | `[subagent_error]` |
| `/speckit.specify` | `auto` | `gate` | `[postcondition_fail, subagent_error]` |

### Phase 4: Convention Reading

Read `.knowledge/snapshot.md` and `CLAUDE.md` for:
- Technology stack information
- Project naming conventions (lowercase slugs, `[a-z0-9-]+`)
- Governance philosophy (file-based, git-tracked)

### Phase 5: Usable Condition Filtering

Build the filtered condition set based on which tools are detected:

| Condition | Requires |
|-----------|----------|
| `spec_exists` | `specs/` directory |
| `plan_exists` | `specs/` directory |
| `tasks_exists` | `specs/` directory |
| `agreement_exists` | `.agreements/` directory |
| `agreement_pass` | `.agreements/` directory |
| `qa_plan_exists` | `.qa/` directory |
| `qa_verdict_pass` | `.qa/` directory |
| `pr_created` | `gh` CLI available |

## R3: Intention Parsing — From Free-Text to Step Sequence

**Decision**: AI-driven intention parsing with a structured mapping heuristic embedded in the slash command prompt.

**Approach**:
1. Extract action verbs and nouns from the intention
2. Map actions to available slash commands (command discovery from Phase 2)
3. Determine natural ordering based on dependency chains (e.g., spec before plan, plan before tasks)
4. Apply autonomy/error_policy heuristics based on existing playbook patterns

**Mapping heuristics** (embedded in the slash command prompt):

| Intention Keywords | Maps To |
|-------------------|---------|
| "specify", "spec", "requirements" | `/speckit.specify` |
| "plan", "design", "architect" | `/speckit.plan` |
| "tasks", "break down", "decompose" | `/speckit.tasks` |
| "agreement", "contract", "commit to" | `/agreement.create` |
| "implement", "build", "code", "develop" | `/speckit.implement` |
| "check agreement", "verify contract" | `/agreement.check` |
| "test", "QA", "validate", "verify" | `/qa.plan` + `/qa.run` |
| "PR", "pull request", "merge", "ship" | `/feature.pr` |
| "intake", "idea", "propose" | `/product.intake` |
| "triage", "prioritize" | `/product.triage` |
| "promote", "approve idea" | `/product.promote` |
| "review", "code review" | `/bmad-bmm-code-review` |
| "knowledge", "document", "refresh knowledge" | `/knowledge.refresh` |

**Vagueness detection**: If the intention contains fewer than 3 action-mappable keywords and no clear sequence (start -> end), trigger clarification questions.

## R4: YAML Output Format and Validation

**Decision**: Generate YAML as a formatted string matching the exact style of existing playbooks, then validate with `npx @tcanaud/playbook check`.

**Format conventions** (observed from existing playbooks):
- Top-level fields: `name`, `description`, `version`, `args`, `steps` in that order
- String values quoted with double quotes
- Lists use block style with `- ` prefix
- Empty lists use inline `[]` syntax
- Steps indented with 2 spaces under `steps:`
- Step fields in order: `id`, `command`, `args`, `autonomy`, `preconditions`, `postconditions`, `error_policy`, `escalation_triggers`
- Each step separated by a blank line for readability

**Validation cycle**:
1. Generate YAML string
2. Write to temporary location or the target file
3. Run `npx @tcanaud/playbook check {file}` via Bash tool
4. If violations reported: parse violation messages, fix YAML, repeat
5. Present validated playbook to user

This guarantees SC-002: 100% of generated playbooks pass validation on first generation.

## R5: Interactive Refinement — Conversation Protocol

**Decision**: Single-turn refinement loop with re-validation after each modification.

**Protocol**:
1. Present generated playbook with annotations (one-line comment per step explaining the rationale)
2. Ask if the developer wants modifications
3. Accept modification descriptions in natural language
4. Apply modifications to the YAML
5. Re-validate via `npx @tcanaud/playbook check`
6. If validation fails: fix automatically and re-present
7. Repeat until developer says "done" or "save"

**Dependency tracking for step removal** (FR-024):
When removing a step, check if its postconditions appear as preconditions in subsequent steps. If so, warn the developer before removing:
> "Step '{id}' produces postcondition '{cond}' which is required by step '{other_id}'. Removing it will break the dependency chain. Proceed anyway?"

## R6: Index Update — Idempotent and Recovery-Safe

**Decision**: Read-modify-write with filesystem recovery.

**Algorithm**:
1. Attempt to read `.playbooks/_index.yaml`
2. If file missing: scan `.playbooks/playbooks/*.yaml`, build fresh index
3. If file corrupted (parse error): same recovery — rebuild from filesystem
4. Check if entry for the new playbook already exists:
   - If yes (overwrite case): update the existing entry
   - If no: append new entry
5. Update `generated` timestamp to current ISO 8601
6. Write back to `.playbooks/_index.yaml`

**Index entry format** (from existing index):
```yaml
- name: "{playbook-name}"
  file: "playbooks/{playbook-name}.yaml"
  description: "{description}"
  steps: {step_count}
```

## R7: Edge Case Handling

**No kai tools installed (bare repo)**:
- Report: "No kai governance tools detected in this project."
- List any slash commands found in `.claude/commands/`
- Ask: "Would you like to proceed with a generic playbook using only the available commands, or install kai tools first?"

**Intention references unavailable command**:
- Explain which command is missing and which tool provides it
- Offer to generate the playbook with the missing step marked as `autonomy: "skip"` with a comment explaining it will be activated when the tool is installed

**Intention too broad**:
- Trigger clarification (max 3 questions per FR-008)
- Generate a first draft after clarifications, even if imperfect — refinement loop handles the rest

**Zero-step playbook (no mappable commands)**:
- Explain that no available commands match the intention
- Suggest reformulating or installing additional tools
- Do not create a file

**Missing/corrupted index**:
- Rebuild from filesystem (R6 recovery)

**Duplicate name**:
- Detect before writing
- Offer: overwrite / rename / cancel (FR-020)

**Single-action intention (e.g., "run tests")**:
- Suggest running the command directly instead of creating a playbook
- Offer to create a playbook anyway if the developer insists

## R8: Package Delivery — Installer/Updater Changes

**Decision**: Add `playbook.create.md` to the existing installer and updater file lists.

**Changes to `installer.js`**:
- Add `"playbook.create.md"` to the `commandFiles` array (currently `["playbook.run.md", "playbook.resume.md"]`)

**Changes to `updater.js`**:
- Same — add the new template to the update list

**Template location**: `packages/playbook/templates/commands/playbook.create.md`

**Version bump**: `package.json` version from `1.1.0` to `1.2.0` (minor — new feature, backward compatible).

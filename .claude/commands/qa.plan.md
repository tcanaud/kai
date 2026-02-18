# /qa.plan — Generate Test Plan from Specifications

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Purpose

Generate executable test scripts from a feature's `spec.md` acceptance criteria and `agreement.yaml` interfaces. Scripts are stored in `.qa/{feature}/scripts/`, indexed by `_index.yaml` with SHA-256 checksums for freshness tracking.

## Execution

### 0. Resolve feature identity

**If `$ARGUMENTS` is empty or missing:**
- ERROR: "Usage: /qa.plan {feature} — provide a feature ID (e.g., 009-qa-system)"
- STOP

Set `FEATURE` to the provided feature ID.

### 1. Precondition checks

Check these in order. STOP on the first ERROR:

1. `.qa/` directory exists?
   - NO → ERROR: "QA system not installed. Run `npx @tcanaud/qa-system init`."
2. `specs/{FEATURE}/spec.md` exists?
   - NO → ERROR: "No spec found at `specs/{FEATURE}/spec.md`. Run `/speckit.specify` first."

### 2. Context gathering (Phase 1)

**Read project knowledge** (adapt script generation to project conventions):
- Read all files in `.knowledge/guides/` — extract tech stack, test patterns, directory structure, conventions
- If `.knowledge/` is missing or empty: WARN "No .knowledge/ found. Generating generic scripts." — continue with defaults

**Read feature specification**:
- Read `specs/{FEATURE}/spec.md`
- Extract ALL acceptance scenarios (Given/When/Then blocks) from every User Story
- For each scenario, record:
  - `criterion_ref`: US{N}.AC{M} format (User Story number, Acceptance Criterion number within that story)
  - `criterion_text`: The full Given/When/Then text
  - `type`: "acceptance"

**Read agreement** (if exists):
- Check `.agreements/{FEATURE}/agreement.yaml`
- If exists: extract `interfaces` entries. For each interface, create an additional test criterion:
  - `criterion_ref`: "IF{N}" format (Interface 1, 2, 3...)
  - `criterion_text`: Derived from `contract` field
  - `type`: "interface"
- If not exists: WARN "No agreement found. Generating tests from spec.md only." — continue

**Run agreement check** (if agreement exists):
- Run `/agreement.check {FEATURE}` and note any drift findings
- If `/agreement.check` fails: WARN "Agreement check failed. Continuing with spec-only generation." — continue

**Explore source code**:
- Explore the feature's source code (entry points, CLI commands, modules, directory structure)
- Understand how the feature works in practice — this informs realistic test scripts

### 3. Script generation (Phase 2)

For EACH acceptance criterion and interface criterion identified in Phase 1, generate one executable test script.

**Script requirements**:

1. **Header comment** (MANDATORY for every script):
   ```bash
   #!/usr/bin/env bash
   # ──────────────────────────────────────────────────────
   # Test: {brief description of what this tests}
   # Criterion: {criterion_ref} — "{criterion_text}"
   # Feature: {FEATURE}
   # Generated: {ISO 8601 timestamp}
   # ──────────────────────────────────────────────────────
   ```

2. **Adapt to project conventions** (from `.knowledge/`):
   - Use the project's preferred test patterns and tools
   - Use appropriate language (bash, node, etc.) based on project conventions
   - Follow the project's naming and style conventions

3. **Self-contained execution**:
   - Each script must be executable independently
   - No external test harness required
   - Exit code 0 = PASS, non-zero = FAIL

4. **Failure output** (on non-zero exit):
   - Print assertion description
   - Print expected value
   - Print actual value
   - Use stderr for failure details

5. **Script naming**: `test-{descriptive-name}.sh` (or `.js`, adapted to project)

**Write all scripts** to `.qa/{FEATURE}/scripts/`:
- Create `.qa/{FEATURE}/scripts/` directory if it doesn't exist
- Write each script file
- Make scripts executable (chmod +x equivalent)

### 4. Index generation (Phase 3)

Compute SHA-256 checksums:
- Run `shasum -a 256 specs/{FEATURE}/spec.md` and extract the hash
- If agreement exists: run `shasum -a 256 .agreements/{FEATURE}/agreement.yaml` and extract the hash

Write `.qa/{FEATURE}/_index.yaml` with this exact schema:

```yaml
qa_version: "1.0"

feature_id: "{FEATURE}"
generated: "{ISO 8601 timestamp}"
generator: "qa.plan"

checksums:
  spec_md:
    path: "specs/{FEATURE}/spec.md"
    sha256: "{64-char hex hash}"
  agreement_yaml:
    path: ".agreements/{FEATURE}/agreement.yaml"
    sha256: "{64-char hex hash or null}"

scripts:
  - filename: "{script-filename}"
    criterion_ref: "{US#.AC# or IF#}"
    criterion_text: "{full Given/When/Then text}"
    type: "{acceptance or interface}"
  # ... one entry per script

total_scripts: {count}
by_type:
  acceptance: {count}
  interface: {count}
  edge_case: {count}
```

**Validation**: `total_scripts` MUST equal the length of `scripts` array. Every filename MUST correspond to a file in `scripts/`.

### 5. Report (Phase 4)

Output a Markdown summary:

```markdown
## QA Plan Generated: {FEATURE}

**Scripts**: {N} generated in `.qa/{FEATURE}/scripts/`
**Coverage**: {N}/{M} acceptance criteria covered
**Checksums**: spec.md ({first 8 chars of sha256}), agreement.yaml ({first 8 chars or "N/A"})

| # | Script | Criterion | Type |
|---|--------|-----------|------|
| 1 | test-{name}.sh | US1.AC1 | acceptance |
| 2 | test-{name}.sh | US1.AC2 | acceptance |
| ... | ... | ... | ... |

{warnings if any}
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `spec.md` not found | ERROR: "No spec found at specs/{FEATURE}/spec.md. Run /speckit.specify first." |
| `.qa/` not found | ERROR: "QA system not installed. Run npx @tcanaud/qa-system init." |
| No acceptance scenarios in spec | ERROR: "No acceptance scenarios found in spec.md. Spec must contain Given/When/Then scenarios." |
| `.knowledge/` missing or empty | WARN — proceed with generic scripts |
| `agreement.yaml` not found | WARN — proceed with spec-only tests |
| `/agreement.check` fails | WARN — continue with spec-only generation |

## Rules

- Generate ONE script per acceptance criterion — target 100% coverage
- Scripts MUST be self-contained and executable
- Scripts MUST have header comments with criterion reference for traceability
- `_index.yaml` MUST have valid checksums for freshness tracking
- NEVER modify `spec.md`, `agreement.yaml`, or `.knowledge/` — read-only access
- If `.qa/{FEATURE}/` already has scripts from a previous run, REPLACE them entirely (full regeneration for MVP)

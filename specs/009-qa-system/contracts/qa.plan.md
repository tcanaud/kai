# Contract: /qa.plan

**Type**: Claude Code slash command
**File**: `.claude/commands/qa.plan.md` (installed by `@tcanaud/qa-system`)

## Interface

```
/qa.plan {feature}
```

**Arguments**: `{feature}` — feature ID (e.g., `009-qa-system`)

**Preconditions**:
- `.qa/` directory exists (package installed)
- `specs/{feature}/spec.md` exists with acceptance scenarios
- Feature has been through `/speckit.specify` (spec is not a template)

**Postconditions**:
- `.qa/{feature}/scripts/` contains executable test scripts
- `.qa/{feature}/_index.yaml` contains script-to-criterion mappings and source checksums
- Each acceptance scenario from `spec.md` has at least one corresponding script

## Behavior

### Phase 1: Context Gathering

1. Read `.knowledge/guides/` to discover project conventions (tech stack, test patterns, directory structure)
2. Read `specs/{feature}/spec.md` — extract all acceptance scenarios (Given/When/Then)
3. Read `.agreements/{feature}/agreement.yaml` — extract interfaces (if exists; skip gracefully if not)
4. Run `/agreement.check {feature}` and note any drift findings (if agreement exists)
5. Explore source code relevant to the feature (entry points, modules, CLI commands)

### Phase 2: Script Generation

6. For each acceptance scenario, generate one executable test script:
   - Script language/format adapted to project conventions (from `.knowledge/`)
   - Header comment linking to the criterion (US#.AC# reference)
   - Self-contained — executable without external test harness
   - Exit code 0 = PASS, non-zero = FAIL
   - Failure output includes assertion description and expected vs actual
7. For each interface in `agreement.yaml`, generate interface compliance test scripts
8. Write scripts to `.qa/{feature}/scripts/` with executable permissions

### Phase 3: Index Generation

9. Compute SHA-256 checksums of `spec.md` and `agreement.yaml` (if present)
10. Write `_index.yaml` with:
    - Generation timestamp
    - Source checksums
    - Script-to-criterion mappings (filename, criterion_ref, criterion_text, type)
    - Total script count and by-type breakdown

### Phase 4: Report

11. Output summary: number of scripts generated, criteria covered, any warnings

## Output

```markdown
## QA Plan Generated: {feature}

**Scripts**: {N} generated in `.qa/{feature}/scripts/`
**Coverage**: {N}/{M} acceptance criteria covered
**Checksums**: spec.md ({sha256_short}), agreement.yaml ({sha256_short | "N/A"})

| # | Script | Criterion | Type |
|---|--------|-----------|------|
| 1 | test-{name}.sh | US1.AC1 | acceptance |
| 2 | test-{name}.sh | US1.AC2 | acceptance |
| ... | ... | ... | ... |

{warnings if any — e.g., "agreement.yaml not found, skipped interface tests"}
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `spec.md` not found | ERROR: "No spec found at specs/{feature}/spec.md. Run /speckit.specify first." |
| `.qa/` not found | ERROR: "QA system not installed. Run npx @tcanaud/qa-system init." |
| No acceptance scenarios in spec | ERROR: "No acceptance scenarios found in spec.md. Spec must contain Given/When/Then scenarios." |
| `.knowledge/` missing or empty | WARN: "No .knowledge/ found. Generating generic scripts." — proceed with defaults |
| `agreement.yaml` not found | WARN: "No agreement found. Generating tests from spec.md only." — proceed |
| `/agreement.check` fails | WARN: "Agreement check failed: {reason}. Continuing with spec-only generation." |

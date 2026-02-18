# Contract: /qa.run

**Type**: Claude Code slash command
**File**: `.claude/commands/qa.run.md` (installed by `@tcanaud/qa-system`)

## Interface

```
/qa.run {feature}
```

**Arguments**: `{feature}` — feature ID (e.g., `009-qa-system`)

**Preconditions**:
- `.qa/{feature}/_index.yaml` exists (test plan generated via `/qa.plan`)
- `.qa/{feature}/scripts/` contains executable test scripts
- Test plan is fresh (checksums match current source files)

**Postconditions**:
- Binary aggregate verdict: PASS (all scripts pass) or FAIL (any script fails)
- Per-script results reported with detail
- Non-blocking findings deposited in `.product/inbox/` (if `.product/` exists)

## Behavior

### Phase 1: Freshness Check

1. Read `.qa/{feature}/_index.yaml`
2. Compute SHA-256 of current `specs/{feature}/spec.md`
3. Compute SHA-256 of current `.agreements/{feature}/agreement.yaml` (if checksum stored)
4. Compare against stored checksums
5. If any mismatch → STALE: refuse to execute, direct to `/qa.plan {feature}`

### Phase 2: Script Execution

6. For each script in `_index.yaml`:
   - Execute the script (bash, node, or appropriate interpreter)
   - Capture exit code (0 = PASS, non-zero = FAIL)
   - Capture stdout/stderr for failure reporting
   - Record execution time
7. If a script fails to execute (syntax error, missing dependency):
   - Mark as FAIL with the execution error as failure detail
   - Continue executing remaining scripts (do not abort)

### Phase 3: Verdict

8. Compute aggregate verdict: PASS if all scripts exit 0, FAIL if any script exits non-zero
9. Output verdict report with per-script detail

### Phase 4: Finding Deposit

10. For non-blocking findings (identified by the command during execution analysis):
    - Create a Markdown file with YAML frontmatter in `.product/inbox/`
    - Include: title, category, source ("qa-system"), linked feature, test script path, criterion reference, observation
    - If `.product/` does not exist: warn and skip deposit

## Output

### On PASS

```markdown
## QA Verdict: {feature} — PASS

**Result**: 12/12 scripts passed
**Duration**: {total_time}

| # | Script | Status | Time |
|---|--------|--------|------|
| 1 | test-plan-generation-basic.sh | PASS | 1.2s |
| 2 | test-knowledge-consultation.sh | PASS | 0.8s |
| ... | ... | ... | ... |

{if findings deposited}
### Non-Blocking Findings

{N} finding(s) deposited in `.product/inbox/`:
- {finding title 1}
- {finding title 2}
```

### On FAIL

```markdown
## QA Verdict: {feature} — FAIL

**Result**: 10/12 scripts passed, 2 failed
**Duration**: {total_time}

| # | Script | Status | Time |
|---|--------|--------|------|
| 1 | test-plan-generation-basic.sh | PASS | 1.2s |
| ... | ... | ... | ... |
| 7 | test-freshness-detection.sh | **FAIL** | 0.5s |
| ... | ... | ... | ... |

### Failures

#### test-freshness-detection.sh (US2.AC4)

**Assertion**: SHA checksum recalculated when agreement.yaml changes
**Expected**: Stale detection triggers
**Actual**: Checksum comparison returned "current" despite file change
**Output**:
\`\`\`
{captured stderr/stdout}
\`\`\`
```

### On STALE

```markdown
## QA Verdict: {feature} — STALE

Test plan is outdated. Source files have changed since last `/qa.plan`:

| Source | Stored SHA | Current SHA |
|--------|-----------|-------------|
| spec.md | a1b2c3... | f6e5d4... |

**Run** `/qa.plan {feature}` to regenerate the test plan.
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `.qa/{feature}/` not found | ERROR: "No test plan for {feature}. Run /qa.plan {feature} first." |
| `_index.yaml` missing or invalid | ERROR: "Invalid test plan index. Run /qa.plan {feature} to regenerate." |
| Test plan stale | STALE verdict (see output above) — do not execute scripts |
| Script execution error (syntax) | Mark script as FAIL, report error, continue with next script |
| `.product/` not found | WARN: "No .product/ directory. Skipping finding deposit." — verdict still produced |
| All scripts missing from disk | ERROR: "Scripts listed in _index.yaml but not found on disk. Run /qa.plan {feature} to regenerate." |

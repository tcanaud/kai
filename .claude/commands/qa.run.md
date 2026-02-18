# /qa.run — Execute Tests and Produce Verdict

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Purpose

Execute all test scripts for a feature and produce a binary PASS/FAIL verdict. Non-blocking findings are deposited in `.product/inbox/` for the product pipeline.

## Execution

### 0. Resolve feature identity

**If `$ARGUMENTS` is empty or missing:**
- ERROR: "Usage: /qa.run {feature} — provide a feature ID (e.g., 009-qa-system)"
- STOP

Set `FEATURE` to the provided feature ID.

### 1. Precondition checks

Check these in order. STOP on the first ERROR:

1. `.qa/{FEATURE}/` directory exists?
   - NO → ERROR: "No test plan for {FEATURE}. Run `/qa.plan {FEATURE}` first."
2. `.qa/{FEATURE}/_index.yaml` exists and is valid YAML?
   - NO → ERROR: "Invalid test plan index. Run `/qa.plan {FEATURE}` to regenerate."
3. Scripts listed in `_index.yaml` exist on disk?
   - NO → ERROR: "Scripts listed in _index.yaml but not found on disk. Run `/qa.plan {FEATURE}` to regenerate."

### 2. Freshness check (Phase 1)

Read `.qa/{FEATURE}/_index.yaml` and extract stored checksums.

Compute current checksums:
- Run `shasum -a 256 specs/{FEATURE}/spec.md` — extract SHA-256
- If `checksums.agreement_yaml.sha256` is not null: run `shasum -a 256 .agreements/{FEATURE}/agreement.yaml` — extract SHA-256

Compare stored vs current:
- **If ANY mismatch** → output STALE verdict and STOP:

```markdown
## QA Verdict: {FEATURE} — STALE

Test plan is outdated. Source files have changed since last `/qa.plan`:

| Source | Stored SHA | Current SHA |
|--------|-----------|-------------|
| spec.md | {stored first 12 chars}... | {current first 12 chars}... |
| agreement.yaml | {stored first 12 chars}... | {current first 12 chars}... |

**Run** `/qa.plan {FEATURE}` to regenerate the test plan.
```

- Only show rows where checksums differ
- **Do NOT execute any scripts if stale**

- **If all match** → proceed to Phase 2

### 3. Script execution (Phase 2)

For each script listed in `_index.yaml` `scripts` array, in order:

1. Execute the script using the Bash tool:
   - Shell scripts: `bash .qa/{FEATURE}/scripts/{filename}`
   - JS scripts: `node .qa/{FEATURE}/scripts/{filename}`
   - Determine interpreter from file extension (`.sh` → bash, `.js` → node, `.mjs` → node)

2. Capture results:
   - **Exit code**: 0 = PASS, non-zero = FAIL
   - **stdout/stderr**: Capture for failure reporting
   - **Execution time**: Note approximate duration

3. **If a script fails to execute** (syntax error, missing dependency):
   - Mark as FAIL with the execution error as failure detail
   - **Continue** executing remaining scripts — do NOT abort the run

4. Record result per script:
   - `filename`, `criterion_ref`, `status` (PASS/FAIL), `exit_code`, `output` (on failure), `duration`

### 4. Verdict (Phase 3)

Compute aggregate verdict:
- **PASS**: ALL scripts exited 0
- **FAIL**: ANY script exited non-zero

**On PASS**, output:

```markdown
## QA Verdict: {FEATURE} — PASS

**Result**: {passed}/{total} scripts passed
**Duration**: {total_time}

| # | Script | Criterion | Status | Time |
|---|--------|-----------|--------|------|
| 1 | {filename} | {criterion_ref} | PASS | {time} |
| 2 | {filename} | {criterion_ref} | PASS | {time} |
| ... | ... | ... | ... | ... |
```

**On FAIL**, output:

```markdown
## QA Verdict: {FEATURE} — FAIL

**Result**: {passed}/{total} scripts passed, {failed} failed
**Duration**: {total_time}

| # | Script | Criterion | Status | Time |
|---|--------|-----------|--------|------|
| 1 | {filename} | {criterion_ref} | PASS | {time} |
| ... | ... | ... | ... | ... |
| N | {filename} | {criterion_ref} | **FAIL** | {time} |
| ... | ... | ... | ... | ... |

### Failures

#### {filename} ({criterion_ref})

**Assertion**: {what the script tested}
**Expected**: {expected behavior or value}
**Actual**: {what actually happened}
**Output**:
\`\`\`
{captured stdout/stderr}
\`\`\`
```

### 5. Finding deposit (Phase 4)

During the test execution analysis, you may identify non-blocking findings — observations that are not acceptance criteria failures but are worth capturing (drift, edge cases, improvement suggestions, patterns noticed).

For each non-blocking finding:

1. Check if `.product/` directory exists:
   - NO → WARN "No .product/ directory. Skipping finding deposit." — skip ALL deposits
   - YES → proceed

2. Create a finding file in `.product/inbox/`:

**Filename**: `qa-finding-{FEATURE}-{brief-slug}.md`

**Content**:
```markdown
---
title: "QA Finding: {brief description}"
category: "{bug|optimization|evolution|new-feature}"
source: "qa-system"
created: "{ISO 8601 timestamp}"
linked_to:
  features: ["{FEATURE}"]
  feedbacks: []
  backlog: []
---

**Test Script**: `.qa/{FEATURE}/scripts/{script-name}`
**Criterion**: {criterion_ref} — "{criterion_text}"
**Observation**: {what was observed}
**Severity**: non-blocking
**Suggestion**: {recommended action}
```

3. Report deposited findings at the end of the verdict:

```markdown
### Non-Blocking Findings

{N} finding(s) deposited in `.product/inbox/`:
- {finding title 1}
- {finding title 2}
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `.qa/{FEATURE}/` not found | ERROR: "No test plan for {FEATURE}. Run `/qa.plan {FEATURE}` first." |
| `_index.yaml` missing or invalid | ERROR: "Invalid test plan index. Run `/qa.plan {FEATURE}` to regenerate." |
| Test plan stale (checksum mismatch) | STALE verdict — do NOT execute scripts |
| Script execution error (syntax) | Mark script as FAIL, report error, continue with next script |
| `.product/` not found | WARN — skip finding deposit, still produce verdict |
| All scripts missing from disk | ERROR: "Scripts listed in _index.yaml but not found on disk. Run `/qa.plan {FEATURE}` to regenerate." |

## Rules

- NEVER execute scripts if the test plan is stale — freshness is mandatory
- ALWAYS continue executing remaining scripts after a failure — do not abort
- ALWAYS produce a verdict (PASS/FAIL/STALE) — never exit without one
- Finding deposits are best-effort — verdict is the primary output
- NEVER modify test scripts, `_index.yaml`, `spec.md`, or `agreement.yaml`
- Findings MUST follow the product-manager feedback schema so `/product.triage` can process them

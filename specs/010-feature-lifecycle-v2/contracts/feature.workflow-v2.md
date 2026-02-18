# Contract: /feature.workflow (V2 Extension)

**Command**: `/feature.workflow {feature}`
**Type**: Claude Code slash command template (Markdown)
**Location**: `packages/feature-lifecycle/templates/commands/feature.workflow.md`
**Installed to**: `.claude/commands/feature.workflow.md`

## Changes from V1

V2 extends the existing workflow command. All V1 behavior is preserved. Changes are additive.

### New Steps (Full Method)

Appended after existing step 11 (Feature Status):

| Step | Name | Requires | Artifact Key | Command |
|------|------|----------|-------------|---------|
| 12 | QA Plan | Gate C-V2 (tasks 100%) | `qa.plan_exists` | `/qa.plan {FEATURE}` |
| 13 | QA Run | qa.plan_exists | `qa.verdict` | `/qa.run {FEATURE}` |
| 14 | Agreement Check | tasks >= 50% (existing) | `agreement.check` | `/agreement.check {FEATURE}` |
| — | **Gate D** | qa.verdict == PASS AND agreement.check == PASS | — | — |
| 15 | PR Creation | Gate D | `pr.url` | `/feature.pr {FEATURE}` |
| 16 | Post-Merge | pr.merged | lifecycle == release | `/feature.resolve {FEATURE}` |

### New Steps (Quick Flow)

Appended after existing step 5 (Feature Status):

| Step | Name | Requires | Artifact Key | Command |
|------|------|----------|-------------|---------|
| 6 | QA Plan | tasks 100% | `qa.plan_exists` | `/qa.plan {FEATURE}` |
| 7 | QA Run | qa.plan_exists | `qa.verdict` | `/qa.run {FEATURE}` |
| — | **Gate D** | qa.verdict == PASS | — | — |
| 8 | PR Creation | Gate D | `pr.url` | `/feature.pr {FEATURE}` |
| 9 | Post-Merge | pr.merged | lifecycle == release | `/feature.resolve {FEATURE}` |

### New Gate Definitions

**Gate C-V2** (replaces existing Gate C for V2 features):
- `tasks_done == tasks_total AND tasks_total > 0`
- All implementation tasks must be complete before QA

**Gate D** (new):
- Full Method: `qa.verdict == "PASS" AND qa.verdict_fresh == true AND agreement.check == "PASS"`
- Quick Flow: `qa.verdict == "PASS" AND qa.verdict_fresh == true`
- QA verdict must be fresh (spec SHA-256 matches current spec.md)

### New Artifact Detection

| Key | Detection | Method |
|-----|-----------|--------|
| `qa.plan_exists` | `.qa/{FEATURE}/_index.yaml` exists | `existsSync()` |
| `qa.verdict` | `.qa/{FEATURE}/verdict.yaml` → `verdict` field | Read YAML, extract `verdict` |
| `qa.verdict_fresh` | `spec_sha256` in verdict.yaml == SHA-256 of current spec.md | Compute and compare |
| `pr.url` | `gh pr list --head "{BRANCH}" --state open --json url` | Parse JSON, extract first URL |
| `pr.merged` | `gh pr list --head "{BRANCH}" --state merged --json number` | Array length > 0 |

### QA FAIL Handling

When `verdict.yaml` exists and `verdict == "FAIL"`:

1. Gate D is blocked
2. The dashboard shows QA Run as **FAIL** (highlighted)
3. The workflow checks if a QA-FAIL backlog already exists for this feature:
   - Scan `.product/backlogs/open/BL-*.md` for `tags` containing `"qa-fail"` AND `features` containing `{FEATURE}`
4. If no QA-FAIL backlog exists and `.product/` is available:
   - Auto-generate a critical backlog from `verdict.yaml` failures
   - Update `.product/index.yaml`
5. If `.product/` is not installed:
   - Display FAIL findings to the developer
   - Suggest manual fix approach
6. Propose the fix path: fix implementation → re-run `/qa.run` → re-check workflow

### QA Stale Verdict Handling

When `verdict.yaml` exists but `spec_sha256` doesn't match current spec.md:

1. QA status shows as **stale** (not PASS, not FAIL)
2. Gate D is blocked
3. The workflow proposes: re-run `/qa.plan {FEATURE}` then `/qa.run {FEATURE}`

### Backward Compatibility

For features without QA artifacts (no `.qa/{FEATURE}/` directory):

1. Steps 12-16 (Full) / 6-9 (Quick) appear in the dashboard as `skip`
2. Gate D is auto-satisfied (no QA required)
3. The feature can reach "complete" status through the existing path
4. No errors, no warnings related to missing QA

Detection: if `.qa/{FEATURE}/_index.yaml` does NOT exist AND `.qa/{FEATURE}/verdict.yaml` does NOT exist → QA steps are `skip`.

### Updated Dashboard Format

```markdown
## Workflow: {FEATURE} — {title}

**Path**: {Full Method | Quick Flow} | **Stage**: {current lifecycle stage}
**Owner**: {owner} | **Next Step**: Step {N} — {step name}

### Progress — Full Method

| # | Step | Status | Artifact |
|---|------|--------|----------|
| 1 | Brief | {done/pending/current} | {file path or —} |
| ... | (existing steps 2-11) | ... | ... |
|   | **GATE C-V2** | {pass/blocked} | All tasks done |
| 12 | QA Plan | {done/pending/blocked/skip} | .qa/{FEATURE}/_index.yaml |
| 13 | QA Run | {done/FAIL/stale/pending/blocked/skip} | {PASS/FAIL/stale/—} |
| 14 | Agreement Check | {done/pending/blocked} | {PASS/FAIL/—} |
|   | **GATE D** | {pass/blocked/skip} | QA PASS + Agreement PASS |
| 15 | PR Creation | {done/pending/blocked/skip} | {PR URL or —} |
| 16 | Post-Merge | {done/pending/blocked/skip} | {release/—} |
```

**New status values**:
- `FAIL` — QA Run returned FAIL verdict (red highlight)
- `stale` — QA verdict exists but spec has changed since (yellow highlight)
- `skip` — Step not applicable for this feature (pre-V2 features)

### Input/Output

**Input**: `$ARGUMENTS` — feature name or ID (unchanged from V1)

**Output**: Markdown dashboard with progress table and next action proposal (extended with new steps)

### Error Handling

| Condition | Behavior |
|-----------|----------|
| `gh` not installed | PR/merge steps show as `blocked` with note: "GitHub CLI required" |
| `gh` not authenticated | PR/merge steps show as `blocked` with note: "Run `gh auth login`" |
| `.product/` not installed | QA FAIL backlog skipped with note; FAIL findings displayed directly |
| `.qa/` not installed | QA steps show as `skip` |

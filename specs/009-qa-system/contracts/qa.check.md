# Contract: /qa.check

**Type**: Claude Code slash command
**File**: `.claude/commands/qa.check.md` (installed by `@tcanaud/qa-system`)

## Interface

```
/qa.check
```

**Arguments**: None

**Preconditions**:
- `.qa/` directory exists (package installed)

**Postconditions**:
- Freshness report for all features with `.qa/` directories
- No files modified (read-only operation)

## Behavior

### Phase 1: Discovery

1. Scan `.qa/` for all subdirectories (each is a feature)
2. For each feature directory, check for `_index.yaml`
3. Skip directories without `_index.yaml` (report as "no test plan")

### Phase 2: Freshness Check

4. For each feature with `_index.yaml`:
   - Read stored checksums (spec.md SHA-256, agreement.yaml SHA-256)
   - Compute current SHA-256 of each source file
   - Compare: match = "current", mismatch = "stale" (identify which file changed)
   - If source file no longer exists: report as "source missing"

### Phase 3: Report

5. Output per-feature freshness report

## Output

```markdown
## QA Freshness Report

| Feature | Status | Details |
|---------|--------|---------|
| 007-knowledge-system | current | — |
| 008-product-manager | **stale** | spec.md changed |
| 009-qa-system | current | — |
| 010-feature-lifecycle-v2 | current | — |
| 011-ci-integration | **stale** | agreement.yaml changed |

**Summary**: 3 current, 2 stale

{if stale features exist}
### Action Required

Run `/qa.plan` for stale features:
- `/qa.plan 008-product-manager`
- `/qa.plan 011-ci-integration`
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `.qa/` not found | ERROR: "QA system not installed. Run npx @tcanaud/qa-system init." |
| `.qa/` empty (no features) | "No features with test plans found. Run /qa.plan {feature} to create one." |
| Feature directory without `_index.yaml` | Skip, report as "no test plan" in output |
| Source file referenced in checksum no longer exists | Report as "source missing" — suggests spec or agreement was deleted |
| `_index.yaml` is malformed YAML | Report as "invalid index" for that feature, continue with others |

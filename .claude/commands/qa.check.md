# /qa.check — Check Test Plan Freshness Across Features

## User Input

```text
$ARGUMENTS
```

## Purpose

Scan all features with `.qa/` directories and report whether their test plans are current (checksums match source files) or stale (source files have changed since last `/qa.plan`). This is a read-only operation — no files are modified.

## Execution

### 1. Precondition checks

1. `.qa/` directory exists?
   - NO → ERROR: "QA system not installed. Run `npx @tcanaud/qa-system init`."

### 2. Discovery (Phase 1)

Scan `.qa/` for all subdirectories. Each subdirectory is a feature.

For each feature directory:
- Check if `_index.yaml` exists
- If NO: record feature as `no_test_plan`
- If YES but malformed YAML: record feature as `invalid_index`
- If YES and valid: proceed to freshness check

If `.qa/` has no subdirectories:
- Output: "No features with test plans found. Run `/qa.plan {feature}` to create one."
- STOP

### 3. Freshness check (Phase 2)

For each feature with a valid `_index.yaml`:

1. Read stored checksums from `_index.yaml`:
   - `checksums.spec_md.path` and `checksums.spec_md.sha256`
   - `checksums.agreement_yaml.path` and `checksums.agreement_yaml.sha256`

2. Compute current checksums:
   - Run `shasum -a 256 {spec_md_path}` — extract SHA-256
   - If `agreement_yaml.sha256` is not null: run `shasum -a 256 {agreement_yaml_path}` — extract SHA-256

3. Compare:
   - **All match** → status: `current`
   - **Any mismatch** → status: `stale`, record which file(s) changed
   - **Source file missing** → status: `source_missing`, record which file

### 4. Report (Phase 3)

Output a Markdown freshness report:

```markdown
## QA Freshness Report

| Feature | Status | Details |
|---------|--------|---------|
| {feature-1} | current | — |
| {feature-2} | **stale** | spec.md changed |
| {feature-3} | **stale** | agreement.yaml changed |
| {feature-4} | current | — |
| {feature-5} | no test plan | — |
| {feature-6} | source missing | spec.md not found |
| {feature-7} | invalid index | _index.yaml parse error |

**Summary**: {N} current, {M} stale, {K} other
```

If any features are stale, add an action section:

```markdown
### Action Required

Run `/qa.plan` for stale features:
- `/qa.plan {stale-feature-1}`
- `/qa.plan {stale-feature-2}`
```

If all features are current:

```markdown
All test plans are up to date.
```

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `.qa/` not found | ERROR: "QA system not installed. Run `npx @tcanaud/qa-system init`." |
| `.qa/` empty (no features) | "No features with test plans found. Run `/qa.plan {feature}` to create one." |
| Feature directory without `_index.yaml` | Report as "no test plan" — not an error |
| Source file referenced in checksum not found | Report as "source missing" — suggests spec or agreement was deleted |
| `_index.yaml` is malformed YAML | Report as "invalid index" for that feature, continue with others |

## Rules

- This is a **read-only** operation — NEVER modify any files
- ALWAYS continue checking remaining features after an error in one feature
- Report ALL features, including those with issues — never silently skip
- Use `shasum -a 256` for checksum computation (available on macOS and Linux)

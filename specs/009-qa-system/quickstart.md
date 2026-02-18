# Quickstart: QA System (009)

**Feature**: 009-qa-system | **Date**: 2026-02-18

## Prerequisites

- Node.js >= 18.0.0
- A kai-governed project with:
  - `.features/` (feature lifecycle tracker installed)
  - `specs/{feature}/spec.md` (at least one feature specified)
  - `.claude/` (Claude Code configured)
- Recommended: `.knowledge/guides/` populated with project conventions
- Recommended: `.agreements/{feature}/agreement.yaml` for interface testing

## Installation

### Via tcsetup (recommended)

```bash
npx @tcanaud/tcsetup init
# QA System is installed automatically as part of the full stack
```

### Standalone

```bash
npx @tcanaud/qa-system init
```

This creates:
- `.qa/` root directory
- `.claude/commands/qa.plan.md`
- `.claude/commands/qa.run.md`
- `.claude/commands/qa.check.md`

### Updating

```bash
npx @tcanaud/qa-system update
```

Updates slash command templates without touching `.qa/` contents.

## Usage

### Generate a test plan

```
/qa.plan 009-qa-system
```

The system:
1. Reads `.knowledge/` to understand your project
2. Reads `specs/009-qa-system/spec.md` acceptance criteria
3. Reads `.agreements/009-qa-system/agreement.yaml` interfaces (if present)
4. Explores your source code
5. Generates executable test scripts in `.qa/009-qa-system/scripts/`
6. Writes `_index.yaml` with script-to-criterion mappings and checksums

### Run the tests

```
/qa.run 009-qa-system
```

The system:
1. Checks that the test plan is fresh (checksums match current files)
2. Executes each script independently
3. Reports per-script PASS/FAIL results
4. Produces a binary aggregate verdict
5. Deposits non-blocking findings in `.product/inbox/`

### Check freshness across features

```
/qa.check
```

Reports which features have current vs stale test plans.

## The Complete Loop

```
/speckit.implement          Developer completes implementation
        │
        ▼
/qa.plan {feature}          Generate test scripts from spec + agreement
        │
        ▼
/qa.run {feature}           Execute tests, get PASS/FAIL verdict
        │
    ┌───┴───┐
    │       │
  PASS    FAIL
    │       │
    │       └──→ Fix code, re-run /qa.run
    │
    ▼
  PR creation               Ready to merge with mechanical proof
    │
    ▼
  Non-blocking findings ──→ .product/inbox/ ──→ /product.triage
```

## Verification

After installation, verify the setup:

```bash
# Check .qa/ directory exists
ls -la .qa/

# Check commands are installed
ls .claude/commands/qa.*.md

# Expected output:
# .claude/commands/qa.check.md
# .claude/commands/qa.plan.md
# .claude/commands/qa.run.md
```

## Artifact Reference

| Artifact | Location | Created By |
|----------|----------|------------|
| Test scripts | `.qa/{feature}/scripts/` | `/qa.plan` |
| Test plan index | `.qa/{feature}/_index.yaml` | `/qa.plan` |
| QA findings | `.product/inbox/` | `/qa.run` |
| Command templates | `.claude/commands/qa.*.md` | `npx @tcanaud/qa-system init` |

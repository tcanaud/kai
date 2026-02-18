# Data Model: QA System (009)

**Feature**: 009-qa-system | **Date**: 2026-02-18

## Entities

### 1. Test Plan Index (`_index.yaml`)

The central metadata file for a feature's QA test plan. One per feature, stored at `.qa/{feature}/_index.yaml`.

**Identity**: Feature ID (matches the feature's directory name, e.g., `009-qa-system`)

**Schema**:

```yaml
qa_version: "1.0"

# ── Generation Metadata ──────────────────────────────
feature_id: "009-qa-system"
generated: "2026-02-18T15:00:00Z"
generator: "qa.plan"

# ── Source Checksums (freshness tracking) ─────────────
checksums:
  spec_md:
    path: "specs/009-qa-system/spec.md"
    sha256: "a1b2c3d4e5f6..."
  agreement_yaml:
    path: ".agreements/009-qa-system/agreement.yaml"
    sha256: "f6e5d4c3b2a1..."    # null if no agreement exists

# ── Script Mappings ───────────────────────────────────
scripts:
  - filename: "test-plan-generation-basic.sh"
    criterion_ref: "US1.AC1"
    criterion_text: "Given a feature with 5 acceptance criteria, When /qa.plan runs, Then 5 scripts are generated"
    type: "acceptance"           # acceptance | interface | edge-case
  - filename: "test-knowledge-consultation.sh"
    criterion_ref: "US1.AC2"
    criterion_text: "Given .knowledge/ guides describing Node.js, When /qa.plan generates, Then scripts use node:test"
    type: "acceptance"
  # ... one entry per script

# ── Summary ───────────────────────────────────────────
total_scripts: 12
by_type:
  acceptance: 10
  interface: 2
  edge_case: 0
```

**Validation rules**:
- `qa_version` must be `"1.0"`
- `feature_id` must match the parent directory name
- `checksums.spec_md.sha256` must be a valid SHA-256 hex string (64 chars)
- `checksums.agreement_yaml.sha256` may be `null` (no agreement)
- Each script entry must have `filename`, `criterion_ref`, `criterion_text`, `type`
- `filename` must correspond to an existing file in `scripts/`
- `total_scripts` must equal the length of `scripts` array

### 2. Test Script

An individual executable file that verifies one or more acceptance criteria. Stored in `.qa/{feature}/scripts/`.

**Identity**: Filename (e.g., `test-plan-generation-basic.sh`)

**Format**: Executable file (shell, JavaScript, or project-appropriate). The format is determined by `/qa.plan` based on `.knowledge/` consultation.

**Structure conventions** (enforced by the `/qa.plan` prompt):

```bash
#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Test: Plan generation produces scripts for all criteria
# Criterion: US1.AC1 — "Given a feature with 5 acceptance criteria..."
# Feature: 009-qa-system
# Generated: 2026-02-18T15:00:00Z
# ──────────────────────────────────────────────────────

set -euo pipefail

# ... test logic ...

# Exit 0 = PASS, non-zero = FAIL
```

**Conventions**:
- Header comment links to criterion (traceability)
- Self-contained — no external test harness required
- Exit code 0 = PASS, non-zero = FAIL
- Failure output includes assertion description and expected vs actual
- Scripts must be executable (`chmod +x`)

### 3. Finding (Feedback Deposit)

A non-blocking observation from a test run, deposited in `.product/inbox/` for the product pipeline.

**Identity**: Auto-assigned by `/product.intake` when triaged (not assigned at deposit time)

**Schema** (YAML frontmatter + Markdown body):

```yaml
---
title: "QA Finding: edge case in freshness detection"
category: "optimization"
source: "qa-system"
created: "2026-02-18T15:30:00Z"
linked_to:
  features: ["009-qa-system"]
  feedbacks: []
  backlog: []
---

**Test Script**: `.qa/009-qa-system/scripts/test-freshness-no-qa-dir.sh`
**Criterion**: US3.AC3 — "Given a feature with no .qa/ directory..."
**Observation**: /qa.check silently skips features without .qa/ but does not report them in the output
**Severity**: non-blocking
**Suggestion**: Add a "no test plan" status to the freshness report for features without .qa/
```

**Validation rules**:
- `title` must start with "QA Finding:"
- `category` must be one of: `bug`, `optimization`, `evolution`, `new-feature`, `critical-bug`
- `source` must be `"qa-system"`
- `linked_to.features` must contain the feature ID
- Body must include `Test Script`, `Criterion`, `Observation`, `Severity` fields

## Relationships

```
spec.md ──(acceptance criteria)──→ _index.yaml ──(maps to)──→ scripts/
                                       │
agreement.yaml ──(interfaces)──────────┘
                                       │
                                  ┌────┘
                                  ▼
                            /qa.run executes
                                  │
                          ┌───────┴───────┐
                          ▼               ▼
                    PASS verdict    FAIL verdict
                          │               │
                          │               └──→ developer fixes code
                          ▼
                   non-blocking findings
                          │
                          ▼
                  .product/inbox/ ──→ /product.triage
```

## Directory Lifecycle

```
After `npx @tcanaud/qa-system init`:
.qa/                              # Root directory (empty)

After first `/qa.plan 009-qa-system`:
.qa/
└── 009-qa-system/
    ├── _index.yaml               # Script-to-criterion mapping + checksums
    └── scripts/
        ├── test-plan-generation-basic.sh
        ├── test-knowledge-consultation.sh
        └── ... (one per criterion)

After `/qa.run 009-qa-system` (with non-blocking finding):
.product/inbox/
└── qa-finding-009-freshness-edge-case.md
```

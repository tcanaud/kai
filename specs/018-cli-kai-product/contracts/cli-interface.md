# CLI Interface Contract: @tcanaud/kai-product

**Package**: `@tcanaud/kai-product`
**Binary**: `kai-product` (via `bin` field in package.json)
**Invocation**: `npx @tcanaud/kai-product <command> [args] [flags]`

---

## Top-Level Commands

```
kai-product init              Scaffold .product/ directory and install slash commands
kai-product update            Refresh slash commands
kai-product reindex           Regenerate index.yaml from filesystem scan
kai-product move <ids> <status>   Move backlog item(s) to new status
kai-product check [--json]    Check product directory integrity
kai-product promote <id>      Promote backlog to feature
kai-product triage [--plan | --apply <file>]  Triage new feedbacks
kai-product help              Show this help
```

---

## Command: `reindex`

**Synopsis**: `kai-product reindex`

**Description**: Regenerates `index.yaml` by scanning all files in the `.product/` directory tree.

**Preconditions**: `.product/` directory must exist.

**Side effects**: Overwrites `.product/index.yaml`.

**Exit codes**:
- `0`: Index regenerated successfully
- `1`: `.product/` not found, or parse error

**Stdout example**:
```
Scanning .product/...
  feedbacks: 7 (new: 0, triaged: 7, excluded: 0, resolved: 0)
  backlogs:  7 (open: 0, in-progress: 0, done: 0, promoted: 7, cancelled: 0)
index.yaml updated.
```

**Stderr on error**:
```
Error: .product/ directory not found. Run `kai-product init` to set up.
```

---

## Command: `move`

**Synopsis**: `kai-product move <ids> <status>`

**Arguments**:
- `ids`: One or more backlog IDs, comma-separated (e.g., `BL-005` or `BL-001,BL-002,BL-003`)
- `status`: Target status — one of `open`, `in-progress`, `done`, `promoted`, `cancelled`

**Preconditions**: All IDs must exist in `.product/backlogs/`. Validated before any file is moved.

**Side effects**:
1. Files moved to `.product/backlogs/{status}/`
2. Frontmatter `status` and `updated` fields updated in each file
3. `index.yaml` regenerated

**All-or-nothing semantics**: If any ID is invalid or missing, NO files are moved.

**Exit codes**:
- `0`: All items moved successfully (or already at target status)
- `1`: One or more IDs not found, or invalid status

**Stdout examples**:
```
Moving BL-005 to done...
  BL-005: open → done ✓
Updating index.yaml... done
```

```
BL-005 is already in status 'open'. No changes made.
```

**Stderr on error**:
```
Error: BL-999 not found in .product/backlogs/
Validation failed. No files were moved.
```

---

## Command: `check`

**Synopsis**: `kai-product check [--json]`

**Flags**:
- `--json`: Output results as a JSON object to stdout (for machine consumption)

**Description**: Runs integrity checks on `.product/`:
1. **Status/directory desync**: File in `backlogs/open/` with frontmatter `status: done`
2. **Stale feedbacks**: Feedbacks in `feedbacks/new/` older than 14 days
3. **Broken traceability**: Feedbacks linking to non-existent backlog IDs, or backlogs linking to non-existent feedback IDs
4. **Orphaned backlogs**: Backlogs in `open/` with no linked feedbacks
5. **Index desync**: `index.yaml` counts differ from actual filesystem counts

**Exit codes**:
- `0`: No issues found
- `1`: One or more issues found (or `.product/` not found)

**Human-readable stdout (no --json)**:
```
Checking .product/ integrity...

  ✓ Status/directory sync: OK
  ✗ Stale feedbacks: 2 issues
    - FB-003: in feedbacks/new/ since 2026-02-01 (19 days)
    - FB-007: in feedbacks/new/ since 2026-02-03 (17 days)
  ✓ Traceability chains: OK
  ✓ Orphaned backlogs: none
  ✗ Index desync: 1 issue
    - index.yaml reports 5 backlogs but 6 found on disk

3 issues found. Run `kai-product reindex` to fix index desync.
```

**JSON stdout (--json)**:
```json
{
  "version": "1.0",
  "checked_at": "2026-02-20T10:00:00Z",
  "ok": false,
  "issues": [
    {
      "type": "stale_feedback",
      "severity": "warning",
      "id": "FB-003",
      "file": ".product/feedbacks/new/FB-003.md",
      "message": "Feedback in 'new' for 19 days (threshold: 14)",
      "days_stale": 19
    },
    {
      "type": "index_desync",
      "severity": "error",
      "message": "index.yaml reports 5 backlogs, 6 found on disk"
    }
  ],
  "summary": {
    "total_issues": 3,
    "warnings": 2,
    "errors": 1
  }
}
```

**Issue types** (for `--json` output):
| `type` | `severity` | Description |
|--------|------------|-------------|
| `status_dir_desync` | `error` | File location doesn't match frontmatter status |
| `stale_feedback` | `warning` | Feedback in `new/` for 14+ days |
| `broken_chain` | `error` | Link points to non-existent item |
| `orphaned_backlog` | `warning` | Open backlog with no linked feedbacks |
| `index_desync` | `error` | index.yaml counts don't match filesystem |

---

## Command: `promote`

**Synopsis**: `kai-product promote <id>`

**Arguments**:
- `id`: Backlog ID to promote (e.g., `BL-007`)

**Preconditions**: Backlog must exist and must NOT have status `promoted`.

**Side effects** (atomic sequence):
1. Determine next feature number (scan `.features/` + `specs/`)
2. Create `.features/{NNN}-{slug}.yaml` with `lifecycle.stage: "ideation"`
3. Move backlog file to `.product/backlogs/promoted/`
4. Update backlog frontmatter: `status: promoted`, `promotion.promoted_date`, `promotion.feature_id`, `updated`
5. For each linked feedback: add feature ID to `linked_to.features[]`, update `updated`
6. Regenerate `.product/index.yaml`

**Exit codes**:
- `0`: Promotion completed
- `1`: Backlog not found, already promoted, or next feature number conflicts

**Stdout example**:
```
Promoting BL-007...
  Next feature number: 019
  Feature ID: 019-cli-atomique-kai-product-pour-operations-produit
  Creating .features/019-cli-atomique-kai-product-pour-operations-produit.yaml... ✓
  Moving BL-007 to promoted/... ✓
  Updating FB-102 (linked feedback)... ✓
  Updating index.yaml... ✓

Promoted: BL-007 → 019-cli-atomique-kai-product-pour-operations-produit
```

**Stderr on error**:
```
Error: BL-003 is already promoted (feature: 018-cli-atomique-kai-product-pour-operations-produit)
```

---

## Command: `triage`

### Phase 1: Plan Output

**Synopsis**: `kai-product triage --plan`

**Description**: Reads all files in `feedbacks/new/` and outputs a JSON triage plan to stdout. No files are modified.

**Exit codes**:
- `0`: Plan output (even if no new feedbacks — outputs empty plan)
- `1`: Parse error or `.product/` not found

**Stdout (JSON)**:
```json
{
  "version": "1.0",
  "generated_at": "2026-02-20T10:00:00Z",
  "feedbacks": [
    {
      "id": "FB-NNN",
      "title": "...",
      "body": "...",
      "created": "YYYY-MM-DD",
      "days_old": 3
    }
  ],
  "plan": []
}
```

### Phase 2: Apply Plan

**Synopsis**: `kai-product triage --apply <plan-file>`

**Arguments**:
- `plan-file`: Path to a JSON plan file (produced by slash command after AI annotation of `--plan` output)

**Plan file schema**:
```json
{
  "version": "1.0",
  "plan": [
    {
      "action": "create_backlog",
      "backlog_title": "...",
      "feedback_ids": ["FB-NNN"],
      "priority": "high",
      "category": "new-feature",
      "regression": false,
      "notes": "optional notes"
    },
    {
      "action": "link_existing",
      "backlog_id": "BL-NNN",
      "feedback_ids": ["FB-NNN"]
    },
    {
      "action": "exclude",
      "feedback_ids": ["FB-NNN"],
      "reason": "duplicate / out of scope / ..."
    }
  ]
}
```

**Side effects** (for each plan entry):
- `create_backlog`: Determine next BL-NNN number, create `backlogs/open/BL-NNN.md`, move feedbacks to `feedbacks/triaged/`, update feedback frontmatter with backlog link
- `link_existing`: Update existing backlog's `feedbacks[]` list, move feedbacks to `feedbacks/triaged/`, update feedback frontmatter with backlog link
- `exclude`: Move feedbacks to `feedbacks/excluded/`, update frontmatter
- Final step: regenerate `index.yaml`

**Exit codes**:
- `0`: Plan applied
- `1`: Invalid plan, missing feedbacks, or file operation error

**Stdout example**:
```
Applying triage plan...
  create_backlog: "New auth bug" ← FB-010, FB-011 → BL-008 ✓
  link_existing: BL-005 ← FB-012 ✓
  exclude: FB-013 (duplicate) ✓
  Updating index.yaml... ✓

Triage complete: 3 feedbacks processed, 1 backlog created, 1 linked.
```

---

## Command: `init`

**Synopsis**: `kai-product init [--yes]`

**Description**: Scaffolds `.product/` directory structure and installs slash commands to `.claude/commands/`.

**Directory structure created**:
```
.product/
├── feedbacks/
│   ├── new/
│   ├── triaged/
│   ├── excluded/
│   └── resolved/
├── backlogs/
│   ├── open/
│   ├── in-progress/
│   ├── done/
│   ├── promoted/
│   └── cancelled/
└── index.yaml   (empty initial index)
```

**Slash commands installed** (to `.claude/commands/`):
- `product.move.md`
- `product.promote.md`
- `product.triage.md`
- `product.check.md`
- `product.reindex.md`

---

## Command: `update`

**Synopsis**: `kai-product update`

**Description**: Refreshes slash command templates without modifying existing `.product/` data.

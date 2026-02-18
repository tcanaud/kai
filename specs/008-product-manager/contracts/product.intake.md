# Contract: /product.intake

**Type**: Claude Code slash command (CLI interface)
**File**: `.claude/commands/product.intake.md`

## Interface

**Command**: `/product.intake [free-text description]`

**Arguments**:
- `$ARGUMENTS` (optional): Free-text description of the feedback. If empty, processes inbox files only.

**Preconditions**:
- `.product/` directory exists with the expected subdirectory structure
- `.product/_templates/feedback.tpl.md` exists

**Postconditions**:
- One or more feedback files created in `.product/feedbacks/new/`
- If inbox files were processed, they are removed from `.product/inbox/`
- `.product/index.yaml` is updated with new feedback entries

## Behavior

### Mode 1: Free-text intake (arguments provided)

1. Scan all `feedbacks/` subdirectories for highest existing FB-xxx number
2. Assign next sequential ID (e.g., FB-006)
3. Analyze content to propose a category from: `critical-bug`, `bug`, `optimization`, `evolution`, `new-feature`
4. Create feedback file at `.product/feedbacks/new/FB-006.md` using `feedback.tpl.md` template
5. Fill frontmatter: id, title (extracted from description), status=new, proposed category, source=user, reporter=owner, created=today
6. Body = the provided free-text description
7. Update `index.yaml`

### Mode 2: Inbox processing (no arguments or inbox has files)

1. List all files in `.product/inbox/`
2. For each file:
   a. Read content and optional YAML frontmatter
   b. Extract metadata: source, reporter, timestamp (from frontmatter or inferred)
   c. Assign next sequential FB-xxx ID
   d. Propose category from content analysis
   e. Create structured feedback in `.product/feedbacks/new/`
   f. Remove the processed inbox file
3. Update `index.yaml`

### Combined mode

If arguments are provided AND inbox has files, process both: create one feedback from the free-text AND process all inbox files.

## Output

```markdown
## Intake Complete

**Created**: {count} new feedback(s)

| ID | Title | Category | Source |
|----|-------|----------|--------|
| FB-006 | Login crashes on Safari | bug | user |
| FB-007 | Search too slow on large repos | optimization | external |

**Next**: Run `/product.triage` when ready to process new feedbacks.
```

## Error cases

- `.product/` does not exist → ERROR: "Product directory not initialized. Create `.product/` with the expected structure first."
- No arguments AND empty inbox → INFO: "No feedback to process. Provide a description or drop files in `.product/inbox/`."
- Inbox file is empty or binary → WARN: "Skipped {filename}: unrecognizable content. Left in inbox for manual review."

# /knowledge.check — Check Knowledge Freshness

## Execution

### 1. Run the check command

Execute:

```bash
npx knowledge-system check
```

This verifies freshness of all knowledge guides by comparing their `watched_paths` against git history.

### 2. Interpret the results

The command outputs a report with each guide's status:
- **VERIFIED**: All watched paths unchanged since last verification
- **STALE**: One or more watched paths modified since last verification
- **UNKNOWN**: No watched paths defined (freshness cannot be determined)

### 3. For STALE guides, suggest actions

For each stale guide, suggest one of:
1. **Update the guide content** to reflect the changes, then update `last_verified` in the frontmatter
2. **Re-verify the guide** — if the content is still accurate despite path changes, just update `last_verified`
3. **Delete the guide** if it's no longer relevant

### 4. For UNKNOWN guides, suggest improvement

Suggest adding `watched_paths` to the guide's frontmatter so freshness can be tracked.

## Rules

- This command is READ-ONLY except for running the CLI check
- Exit code 1 from the CLI means at least one guide is stale
- Always present the full report before suggesting actions

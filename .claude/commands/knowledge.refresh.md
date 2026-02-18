# /knowledge.refresh — Refresh Snapshot and Index

## Execution

### 1. Run the refresh command

Execute:

```bash
npx @tcanaud/knowledge-system refresh
```

This regenerates `.knowledge/snapshot.md` and `.knowledge/index.yaml` from current project artifacts (conventions, ADRs, features, guides).

### 2. Report results

After the command completes, read `.knowledge/index.yaml` and summarize what was found:
- Number of guides, conventions, ADRs, and features indexed
- Any guides marked as STALE

### 3. Suggest next steps

If there are stale guides, suggest running `/knowledge.check` for details.
If there are no guides yet, suggest `/knowledge.create` to start building the knowledge base.

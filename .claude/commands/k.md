# /k — Query the Knowledge Base

**Input**: `$ARGUMENTS` (a question in natural language)

## Execution

Follow these steps exactly:

### 1. Check prerequisites

Verify `.knowledge/` directory exists. If not, report:
> "Knowledge system not initialized. Run `/knowledge.refresh` or `npx knowledge-system init` first."

### 2. Read the knowledge index

Read `.knowledge/index.yaml` to get the full catalog of:
- **guides**: Knowledge guides with topics, summaries, and freshness status
- **conventions**: Active project conventions
- **adrs**: Architecture Decision Records
- **features**: Feature lifecycle entries

### 3. Match the question to relevant sources

Analyze the user's question (`$ARGUMENTS`) and find the most relevant entries from the index by matching against:
- Entry titles (strongest signal)
- Entry summaries
- Entry topics/keywords

**Prioritize in this order**: guides > conventions > ADRs > features

Select the **top 3-5 most relevant** sources.

### 4. Read and verify each source

For each relevant source:

1. **Read the file** at the path listed in the index entry
2. **For guides only** — check freshness:
   - Read the guide's YAML frontmatter for `last_verified` and `watched_paths`
   - For each `watched_paths` entry, run: `git log -1 --format=%aI -- <path>`
   - If any watched path was modified AFTER `last_verified` → tag as **STALE**
   - If no watched paths changed → tag as **VERIFIED**
   - If no watched_paths defined → tag as **UNKNOWN**
3. **For conventions and ADRs** — always tag as **VERIFIED** (they are authoritative)

### 5. Assemble the answer

Compose a clear, concise answer to the user's question, synthesizing information from all relevant sources. Then append a sources section:

```
## Sources

- VERIFIED  .knowledge/guides/release-package.md — "How to release a package"
- STALE     .knowledge/guides/add-feature.md — "How to add a feature"
  ⚠ watched_paths changed: .claude/commands/feature.workflow.md (2026-02-19)
- VERIFIED  .agreements/conv-006-trusted-publishing/agreement.yaml — "Trusted publishing convention"
```

### 6. Handle no results

If no relevant sources are found:
> "No relevant knowledge found for this question. Consider creating a guide with `/knowledge.create "$ARGUMENTS"`."

### 7. Suggest knowledge capture (if extensive exploration needed)

If you had to read **5 or more files beyond the index** to assemble the answer (indicating the knowledge was not pre-captured), add a suggestion:

> "💡 This answer required reading multiple source files. Consider capturing this knowledge as a reusable guide: `/knowledge.create "<suggested topic>"`"

## Rules

- This command is READ-ONLY — it does not modify any files
- Always cite sources with their verification status
- Prefer guide content over raw artifact content when both exist
- If a guide is STALE, still include its content but prominently warn the user
- Keep answers concise and actionable

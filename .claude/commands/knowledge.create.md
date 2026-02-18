# /knowledge.create — Create a Knowledge Guide

**Input**: `$ARGUMENTS` (topic or title for the new guide)

## Execution

### 1. Parse the topic

Extract the topic from `$ARGUMENTS`. If empty, ask the user what topic they want to document.

### 2. Generate a slug

Convert the topic to a URL-friendly slug:
- Lowercase
- Replace spaces and special characters with hyphens
- Remove consecutive hyphens
- Example: "How to release a package" → `release-package`

### 3. Check for duplicates

Check if `.knowledge/guides/<slug>.md` already exists.
- If it does, warn the user and offer to open it for editing instead
- If not, proceed to create

### 4. Read the guide template

Read `.knowledge/_templates/guide.tpl.md` for the frontmatter structure.

### 5. Create the guide

Write a new file at `.knowledge/guides/<slug>.md` with:

```yaml
---
id: <slug>
title: "<topic>"
created: "<today's date>"
last_verified: "<today's date>"
references:
  conventions: []
  adrs: []
  features: []
watched_paths: []
topics: [<derived keywords>]
---
```

Fill the body with:
- An **Overview** section describing the topic based on project context
- A **Steps** section with actionable instructions (if procedural)
- Relevant references to existing artifacts

### 6. Suggest watched_paths

Based on the topic and any files explored during content creation, suggest relevant `watched_paths` entries that would make the guide's freshness trackable. Add them to the frontmatter.

### 7. Suggest references

If the topic relates to known conventions, ADRs, or features, add them to the `references` section.

### 8. Remind about refresh

After creation, remind the user:
> "Guide created. Run `/knowledge.refresh` to update the index."

## Rules

- Always create guides in `.knowledge/guides/`
- Always include proper YAML frontmatter
- Set `last_verified` to today's date
- Keep guides concise and focused on a single topic
- Suggest watched_paths proactively — this is what makes the guide verifiable

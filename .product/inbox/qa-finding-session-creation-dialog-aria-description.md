---
title: "QA Finding: New Session dialog missing aria-describedby / Description"
category: "bug"
source: "qa-system"
created: "2026-02-20T09:48:00Z"
linked_to:
  features: []
  feedbacks: []
  backlog: []
---

**Test**: Session creation happy path — manual exploratory QA
**Observation**: The browser console emits two accessibility warnings when the "Create Session" dialog opens:
  `Warning: Missing \`Description\` or \`aria-describedby={undefined}\` for {DialogContent}.`
  This is a Radix UI / shadcn `DialogContent` that has no `<DialogDescription>` child and no `aria-describedby` attribute, which violates WCAG 2.1 criterion 4.1.2 (Name, Role, Value).
**Severity**: non-blocking
**Suggestion**: Add a `<DialogDescription>` element inside the `DialogContent` (can be visually hidden with `sr-only`) describing the purpose of the dialog, e.g. "Fill in the playbook and feature name to start a new session."

# API Contracts: Kai UI

**Feature**: 017-kai-ui | **Date**: 2026-02-19

All endpoints are Next.js API routes served on `localhost:3000`. No authentication.

## GET /api/sessions

List all active worktree sessions.

**Request**: No parameters.

**Response** (200):
```json
{
  "sessions": [
    {
      "id": "017-kai-ui",
      "name": "017-kai-ui",
      "playbook": "feature-full",
      "feature": "kai-ui",
      "createdAt": "2026-02-19T10:00:00Z",
      "status": "active",
      "worktreePath": "/path/to/worktree"
    }
  ]
}
```

**Error** (500):
```json
{
  "error": "Failed to read sessions directory",
  "details": "ENOENT: no such file or directory"
}
```

## POST /api/sessions

Create a new worktree session by executing the playbook start command.

**Request**:
```json
{
  "playbook": "feature-full",
  "feature": "018-new-idea"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| playbook | string | Yes | Playbook name to use |
| feature | string | Yes | Feature name for the worktree |

**Response** (201):
```json
{
  "session": {
    "id": "018-new-idea",
    "name": "018-new-idea",
    "playbook": "feature-full",
    "feature": "new-idea",
    "createdAt": "2026-02-19T12:00:00Z",
    "status": "active",
    "worktreePath": "/path/to/worktree"
  },
  "output": "Session created successfully..."
}
```

**Error** (400):
```json
{
  "error": "Missing required field: playbook"
}
```

**Error** (500):
```json
{
  "error": "Session creation failed",
  "details": "Command stderr output...",
  "exitCode": 1
}
```

## GET /api/playbooks

List available playbooks for session creation.

**Request**: No parameters.

**Response** (200):
```json
{
  "playbooks": [
    {
      "name": "feature-full",
      "title": "Full Feature Workflow",
      "description": "Complete feature lifecycle with BMAD + SpecKit"
    },
    {
      "name": "feature-quick",
      "title": "Quick Feature",
      "description": "Lightweight feature with quick spec"
    }
  ]
}
```

**Error** (500):
```json
{
  "error": "Failed to read playbooks",
  "details": "..."
}
```

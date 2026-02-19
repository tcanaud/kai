# Data Model: Kai UI

**Feature**: 017-kai-ui | **Date**: 2026-02-19

## Entities

### Session

Represents a worktree session managed by the playbook system.

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| id | string | Directory name in `.playbooks/sessions/` | Unique session identifier |
| name | string | Derived from session directory or `session.yaml` | Human-readable session name |
| playbook | string | `session.yaml` → playbook field | Playbook template used to create the session |
| feature | string | `session.yaml` → feature field | Feature name associated with the session |
| createdAt | string (ISO 8601) | `session.yaml` → created field | Session creation timestamp |
| status | string | `session.yaml` → status field | Session status (active, completed, etc.) |
| worktreePath | string | Derived from session configuration | Path to the git worktree directory |

**Source of truth**: `.playbooks/sessions/{id}/session.yaml`

**State transitions**: Created → Active → Completed (managed by playbook system, not by kai-ui)

### Panel

A UI component slot within a session view. Exists only in the React component tree — no filesystem persistence.

| Field | Type | Description |
|-------|------|-------------|
| type | enum | One of: `terminal`, `editor`, `playbook`, `chat`, `assistant` |
| sessionId | string | The session this panel belongs to |
| isActive | boolean | Whether the panel is currently visible/focused |

**Note**: Panel state (size, visibility) is ephemeral — lives in React state only. No persistence in MVP.

### Playbook

A workflow template available for session creation.

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| name | string | Filename in `.playbooks/playbooks/` | Playbook identifier |
| title | string | YAML frontmatter → title | Human-readable playbook name |
| description | string | YAML frontmatter → description | Brief description of what the playbook does |

**Source of truth**: `.playbooks/playbooks/*.yaml` and `.playbooks/_index.yaml`

## Relationships

```
Session 1──* Panel (each session has exactly 5 panel slots)
Session *──1 Playbook (each session was created from one playbook)
```

## Data Flow

1. **Read sessions**: API route reads `.playbooks/sessions/` directory, parses each `session.yaml`
2. **Create session**: API route executes `npx @tcanaud/playbook start {playbook} {feature}`, then re-reads sessions
3. **List playbooks**: API route reads `.playbooks/_index.yaml` or scans `.playbooks/playbooks/*.yaml`
4. **Panel state**: Managed entirely in React client state — no server interaction

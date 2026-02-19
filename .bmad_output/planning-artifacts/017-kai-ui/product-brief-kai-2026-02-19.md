---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - ".knowledge/guides/project-philosophy.md"
  - ".knowledge/snapshot.md"
  - ".knowledge/guides/create-new-package.md"
date: 2026-02-19
author: tcanaud
---

# Product Brief: kai

<!-- Content will be appended sequentially through collaborative workflow steps -->

## Executive Summary

Kai UI is a cyberpunk-themed web IDE that brings the kai governance stack to life through a visual interface. Launched via `npx kai-ui` from any kai-enabled project, it opens a local web server providing multi-worktree session management, each session embedding a terminal (xterm.js + tmux), a code editor (code-server), a playbook dashboard, and an AI conversation interface — all reading directly from the repository's kai file structure. The MVP delivers the full layout with placeholders for each panel and functional worktree session creation via the existing `npx @tcanaud/playbook start` command.

---

## Core Vision

### Problem Statement

Kai's governance stack (features, agreements, playbooks, knowledge, QA) is powerful but invisible — it lives in dotfiles and YAML, operated entirely through terminal commands and Claude Code slash commands. There is no unified view of what's happening across worktrees, no visual way to manage playbook sessions, and no integrated environment that combines code editing, terminal access, and AI assistance in a single interface purpose-built for kai workflows.

### Problem Impact

As kai matures with 16+ features and 7 subsystems, the cognitive overhead of context-switching between terminal, editor, and Claude Code increases. Each worktree is an isolated silo with no shared dashboard. New users face a steep learning curve with no visual onboarding. The creator's own workflow — the primary user — is slowed by constant tool-switching rather than fluid, integrated interaction.

### Why Existing Solutions Fall Short

- **VS Code + terminal**: Generic IDE, no kai awareness, no worktree session management, no integrated playbook UI
- **Claude Code CLI alone**: Powerful but text-only, no persistent visual state, no multi-session overview
- **Generic web dashboards**: Require databases, external services, authentication — violate kai's file-based philosophy
- **Existing dev IDEs (Cursor, Windsurf)**: AI-assisted but not kai-native, no governance awareness, no playbook integration

### Proposed Solution

A Next.js + shadcn/ui web application with a dark cyberpunk aesthetic (neon cyan/magenta/violet accents, glow effects, monospace typography). Launched as a local dev server via `npx kai-ui`, it reads kai's file structure directly and provides:

1. **Multi-worktree session management** — create/switch sessions, each backed by a git worktree via `npx @tcanaud/playbook start`
2. **Per-session panels** — xterm.js terminal (tmux-backed with deterministic session IDs for refresh persistence), code-server editor, playbook dashboard, AI chat interface
3. **AI assistant overlay** — hover-accessible AI helper across all views
4. **Responsive design** — desktop and mobile layouts
5. **Local state in `.kaiui/`** — session preferences and UI state tracked in the repo

### Key Differentiators

- **Kai-native**: Built specifically for the kai governance stack — not a generic IDE with plugins
- **File-based by design**: Reads `.features/`, `.playbooks/`, `specs/`, `.agreements/` directly — no database, no sync
- **Tmux-backed terminal persistence**: Deterministic session IDs mean page refresh restores the exact terminal state
- **Cyberpunk developer aesthetic**: Not another bland SaaS dashboard — a purpose-built, visually striking dev environment
- **Philosophy-aligned**: Respects kai's dogmas (git is the database, stateless, portable) with the deliberate exception of runtime dependencies (Next.js + shadcn require them)

## Target Users

### Primary Users

**Thibaud ("tcanaud")** — Solo developer and creator of the kai governance stack. Full-stack engineer who operates kai daily through terminal + Claude Code CLI, managing 16+ features across multiple worktrees. Needs a unified visual interface to reduce context-switching between terminal, editor, and AI assistant. Power user who knows every kai subsystem intimately and wants speed, not hand-holding.

**Problem Experience:** Constantly switches between terminal tabs, VS Code windows, and Claude Code sessions. Each worktree is a mental silo. No visual overview of active playbook sessions or feature progress. The governance stack works well but remains invisible — everything is `cat` and `grep`.

**Success Vision:** Opens `npx kai-ui`, sees all active worktrees at a glance, clicks into one, and has terminal + editor + playbooks + AI chat in a single cyberpunk-themed interface. Page refresh restores everything. Flow state preserved.

### Secondary Users

N/A — Single-user tool for now.

### User Journey

1. **Launch**: `npx kai-ui` from kai project root → browser opens on `localhost:3000`
2. **Session creation**: Creates a new worktree session via the UI (triggers `npx @tcanaud/playbook start`)
3. **Core usage**: Works within a session — terminal commands, code editing, playbook monitoring, AI conversations — all in one view
4. **Context switch**: Switches between worktree sessions without losing state (tmux persistence)
5. **End of day**: Closes browser. Next day, reopens — tmux sessions intact, UI state restored from `.kaiui/`

## Success Metrics

Kai UI is a personal tool — success is measured by adoption in daily workflow, not business KPIs.

**Primary success signal:** Kai UI becomes the default working environment. Ghostty, VS Code, and standalone terminal sessions are no longer opened for kai-related work.

**Measurable criteria:**
- **Daily usage**: Kai UI is launched every working day as the first dev tool
- **Terminal replacement**: No need to open Ghostty or other terminal emulators for kai workflows
- **Session persistence**: Worktree sessions survive browser restarts without manual reconfiguration
- **Multi-day streak**: Several consecutive working days spent entirely within Kai UI

**"It was worth it" moment:** Multiple days of work completed without opening any external terminal or editor — everything happens inside Kai UI.

### Business Objectives

N/A — Personal productivity tool. No revenue, no user growth targets.

### Key Performance Indicators

| KPI | Target | Measurement |
|-----|--------|-------------|
| Daily usage | 100% of working days | Self-observed |
| External terminal opens | 0 per day for kai work | Self-observed |
| Session restore reliability | Page refresh preserves full state | Tmux session survives |
| Time to first interaction | < 5 seconds after `npx kai-ui` | Subjective feel |

## MVP Scope

### Core Features

1. **Next.js + shadcn/ui application** — Launchable via `npx kai-ui`, opens `localhost:3000`
2. **Cyberpunk Dark UI shell** — Full design system: neon cyan/magenta/violet accents, glow effects, monospace typography, dark background. Desktop + mobile responsive from day one.
3. **Session sidebar** — List worktree sessions, create new ones via `npx @tcanaud/playbook start {playbook} {feature}`
4. **Per-session layout with 5 placeholder panels:**
   - Terminal (xterm.js + tmux) — placeholder
   - Code editor (code-server) — placeholder
   - Playbook dashboard — placeholder
   - AI chat interface — placeholder
   - AI assistant overlay (hover) — placeholder
5. **Panel layout system** — Resizable/switchable panels within a session view, ready to receive real implementations later

All panels display styled placeholder content with the cyberpunk aesthetic — the skeleton is visually complete but functionally inert beyond session creation.

### Out of Scope for MVP

- Functional xterm.js + tmux terminal
- Functional code-server integration
- Playbook file reading / dashboard logic
- AI chat or assistant functionality
- `.kaiui/` state persistence
- Authentication (not needed, ever)
- Any kai file reading (`.features/`, `.agreements/`, etc.)

### MVP Success Criteria

- `npx kai-ui` launches and opens browser successfully
- Session creation triggers `npx @tcanaud/playbook start` and adds a session to the sidebar
- All 5 placeholder panels render within a session with the cyberpunk D.A.
- Layout works on desktop and mobile
- The skeleton is architecturally sound — each panel is a pluggable component ready for real implementation

### Future Vision

1. **V1.1** — Functional xterm.js + tmux with deterministic session IDs, page-refresh persistence
2. **V1.2** — Code-server integration, opened in worktree context
3. **V1.3** — Playbook dashboard reading `.playbooks/` sessions and state
4. **V1.4** — AI chat interface (conversational, create/view threads)
5. **V1.5** — AI assistant overlay across all views
6. **V2.0** — Full kai-native IDE: reads `.features/`, `.agreements/`, `specs/` — governance-aware development environment
7. **Beyond** — `.kaiui/` state persistence, theme customization, multi-project support

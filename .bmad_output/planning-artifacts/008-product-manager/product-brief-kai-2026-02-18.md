---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - ".knowledge/guides/project-philosophy.md"
  - ".knowledge/index.yaml"
  - ".features/config.yaml"
  - ".features/index.yaml"
date: "2026-02-18"
author: "tcanaud"
feature: "008-product-manager"
workflow_path: "full"
---

# Product Brief: kai Product Manager

## Executive Summary

kai is a project governance system that lives entirely inside the repository — decisions, conventions, feature lifecycle, agreements, and documentation freshness are all plain text under version control. Today, kai covers the full journey from architecture decisions through feature specification to code delivery. But one critical gap remains: **there is no structured way to capture user feedback, triage it, and connect it to the planning pipeline.**

The Product Manager module closes this loop by adding a file-based feedback and backlog system to the kai governance stack. Feedback enters the system (from external tools or AI-assisted intake), gets triaged with semantic clustering, becomes backlog items, and — when significant enough — gets promoted into full features via the existing `/feature.workflow` pipeline. Every step is a versioned file. Every transition is a git diff. The complete lineage from user complaint to shipped code is traceable.

This is the 8th module in the kai governance stack, following the same dogmas: git is the database, drift is the enemy, zero dependencies, the interface is prose, convention before code.

---

## Core Vision

### Problem Statement

Project teams using kai can plan features (BMAD), specify implementations (SpecKit), enforce agreements, track architecture decisions, and manage feature lifecycle — but they have no structured way to:

1. **Capture feedback** from users, stakeholders, or automated systems in a consistent, versionable format
2. **Triage and prioritize** that feedback systematically — grouping related items, excluding noise, surfacing patterns
3. **Convert feedback into actionable work** that connects to the existing planning pipeline
4. **Trace the lineage** from a user's complaint all the way to the code that resolved it

Without this, feedback lives in Slack threads, email chains, sticky notes, or issue trackers that are disconnected from the governance system. The result: product decisions are made without structured input, feedback gets lost, and there is no way to verify that user needs were actually addressed.

### Problem Impact

- **Feedback black hole**: User input enters through informal channels and disappears — no audit trail, no accountability
- **Disconnected planning**: Features are planned based on intuition rather than structured, traceable user signals
- **No closure loop**: When code ships, there is no mechanism to verify that the original feedback was addressed
- **Invisible patterns**: Related feedback from different sources is never correlated — emerging themes go undetected
- **Governance gap**: kai tracks everything from ADR to release, but the "why did we build this?" question has no structured answer

### Why Existing Solutions Fall Short

| Solution | Limitation |
|----------|-----------|
| **GitHub Issues** | Platform-locked, no YAML frontmatter, no semantic triage, no link to kai governance stack |
| **Jira / Linear** | External service, requires authentication, breaks "git is the database" dogma |
| **git-bug** | Uses git object database (not human-readable files), no backlog concept, no product pipeline |
| **TrackDown** | Markdown only, no structured metadata, no triage workflow, no lifecycle tracking |
| **Sciit** | Branch-coupled, no persistent feedback tracking across branches |
| **Manual tracking** | Spreadsheets, docs — no version control, no drift detection, no automation |

None of these solutions follow the kai pattern: **YAML frontmatter + Markdown body, indexed centrally, tracked in git, queryable by glob+grep, with drift detection and AI-powered commands.**

### Proposed Solution

A new `.product/` directory (the 8th dotfile directory in the kai governance stack) containing:

1. **Feedback system** — structured feedback files (YAML frontmatter + Markdown body) organized in status-based subdirectories (`new/`, `triaged/`, `excluded/`, `resolved/`) where the filesystem literally reflects the triage state
2. **Backlog system** — backlog items that aggregate one or more feedbacks into actionable work, also in status-based subdirectories (`open/`, `in-progress/`, `done/`, `promoted/`, `cancelled/`)
3. **Inbox staging area** — a drop zone for external tools to deposit raw/unstructured feedback that gets processed into structured format
4. **AI-powered triage command** — `/product.triage` uses semantic clustering to group related feedback, detect duplicates, surface patterns, and propose batch actions
5. **Promotion pipeline** — `/product.promote` converts a backlog item into a full kai feature, preserving traceability links back to the original feedback
6. **Drift detection** — `/product.check` detects stale feedback, orphaned backlogs, desync between folder location and frontmatter status, and unresolved feedback chains

The complete lifecycle:

```
User complaint → inbox/ (raw) → /product.intake → feedbacks/new/ (structured)
  → /product.triage → feedbacks/triaged/ + backlogs/open/
    → /product.promote → .features/xxx.yaml + /feature.workflow
      → Brief → PRD → Spec → Tasks → Code → Release
        → feedbacks/resolved/ (closure)
```

### Key Differentiators

1. **Filesystem-as-state**: Feedback status is determined by its directory location (`new/`, `triaged/`, `excluded/`, `resolved/`). A `git mv` is a status transition. A `ls feedbacks/new/` is a query. The "unstacking" is literally visible.

2. **Full lifecycle traceability**: From user complaint to shipped code, every step is a versioned file with bidirectional links. No other file-based system connects feedback → backlog → feature → spec → tasks → code → release.

3. **AI-powered semantic triage**: Unlike keyword-based grouping, `/product.triage` uses Claude's language understanding to detect related feedback across different phrasings, surface emerging themes, and propose batch actions.

4. **Drift detection for product**: The same check/doctor/implement repair cycle that works for agreements now works for product management — stale feedbacks, orphaned backlogs, and unresolved chains are detected automatically.

5. **Zero dependencies, full kai compliance**: Follows every kai dogma — git is the database, zero runtime deps, Claude commands as UI, convention before code. No external service, no database, no dashboard.

---

## Target Users

### Primary Users

**Persona: TC — Solo Developer / Project Owner**

- Runs multiple projects using the kai governance stack
- Receives feedback from users, testers, and collaborators through various channels (chat, email, GitHub, verbal)
- Currently has no structured way to capture and track this feedback within the project repository
- Wants to make product decisions based on real signals, not gut feeling
- Values traceability: "why did we build this?" should have a documented, versioned answer
- Works primarily through Claude Code slash commands

**Day-to-day interaction:**
- Receives a user complaint → runs `/product.intake` with a description → structured feedback created in `feedbacks/new/`
- Periodically runs `/product.triage` → reviews AI-proposed groupings and actions → feedbacks move to `triaged/` or `excluded/`, backlogs are created
- When a backlog item is significant → runs `/product.promote BL-xxx` → a new feature is created and the full workflow begins
- Runs `/product.dashboard` to get a pulse on the product health

### Secondary Users

**External Tools / CI Systems**

- Automated systems that deposit raw feedback files into `.product/inbox/`
- Could be a webhook receiver, a form processor, a Slack bot, or a manual script
- They need a clear contract: "drop a file here in this format, and the system will process it"
- The `.product/inbox/` directory is their API

**Collaborators / Contributors**

- People who contribute feedback but don't run the triage themselves
- They can read the `.product/` directory to understand what feedback exists, what's being worked on, and why decisions were made
- The filesystem is self-documenting — no special tool needed to browse

### User Journey

1. **Discovery**: User adopts kai via `npx tcsetup` — the Product Manager module is available as an optional tool
2. **First feedback**: User runs `/product.intake "users say search is slow"` — sees a properly structured feedback file appear in `feedbacks/new/`
3. **Aha moment**: User runs `/product.triage` with 10+ accumulated feedbacks — AI groups 3 related auth complaints together and proposes a backlog item. User realizes: "I would never have connected these manually"
4. **Promotion**: User promotes a backlog item to a feature — sees the full `/feature.workflow` pipeline activate with traceability links back to the original feedbacks
5. **Closure**: Feature ships, feedbacks automatically move to `resolved/` — user runs `/product.dashboard` and sees the complete feedback→code conversion metrics
6. **Long-term**: The `.product/reviews/` directory accumulates periodic review reports — the team has a versioned history of product decisions and their rationale

---

## Success Metrics

### User Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Feedback capture rate | 100% of structured feedback enters `.product/` | No feedback lives outside the repository |
| Triage throughput | `feedbacks/new/` directory stays under 15 items | Count via `ls feedbacks/new/ \| wc -l` |
| Feedback-to-backlog conversion | >= 40% of feedbacks result in backlog items | `triaged count / (triaged + excluded) count` |
| Backlog-to-feature promotion | >= 20% of backlogs become features | `promoted count / total backlog count` |
| Resolution closure | Every shipped feature resolves its linked feedbacks | `/product.check` reports zero ORPHAN findings |
| Traceability completeness | Every feature can trace back to feedback source | Backlog items have non-empty `feedbacks:` arrays |

### Business Objectives

1. **Close the governance gap**: kai manages the full project lifecycle from feedback to release — no external tool needed for product management
2. **Increase tcsetup value proposition**: Adding a product management layer makes kai more compelling for adoption
3. **Demonstrate the kai pattern**: Prove that the file-based, git-native, AI-powered approach works for yet another domain (product management), reinforcing the architecture's generality

### Key Performance Indicators

| KPI | Definition | Target |
|-----|-----------|--------|
| Module adoption | Projects that enable `.product/` via tcsetup | Track via marker directory detection |
| Drift detection accuracy | `/product.check` findings that are actionable (not false positives) | >= 90% |
| Triage efficiency | Time from feedback creation to triage decision | < 1 week (measured via git log timestamps) |
| Pattern detection | Feedbacks correctly grouped by `/product.triage` | Qualitative — user confirms groupings are meaningful |

---

## MVP Scope

### Core Features

**MVP delivers the complete feedback→backlog pipeline with 6 commands:**

| # | Feature | Command | Description |
|---|---------|---------|-------------|
| 1 | **Feedback intake** | `/product.intake` | Create structured feedback from free-text description or process `inbox/` files |
| 2 | **AI triage** | `/product.triage` | Semantic clustering, duplicate detection, batch actions on `new/` feedbacks |
| 3 | **Backlog promotion** | `/product.promote` | Convert backlog item → kai feature with full traceability |
| 4 | **Drift detection** | `/product.check` | Detect stale, orphaned, desynced, and unresolved items |
| 5 | **Dashboard** | `/product.dashboard` | Overview of feedbacks by status, backlogs, trends, and warnings |
| 6 | **Backlog management** | `/product.backlog` | View and manage backlog items |

**Directory structure:**

```
.product/
  config.yaml              # module configuration
  index.yaml               # centralized index (feedbacks + backlogs)
  _templates/
    feedback.tpl.md        # feedback template
    backlog.tpl.md         # backlog item template
  inbox/                   # staging area for external tools
  feedbacks/
    new/                   # unprocessed
    triaged/               # analyzed, linked to backlog
    excluded/              # rejected with reason
    resolved/              # problem solved
  backlogs/
    open/                  # planned, not started
    in-progress/           # being worked on
    done/                  # completed
    promoted/              # became a full feature
    cancelled/             # dropped
```

**Feedback schema (YAML frontmatter):**

```yaml
---
id: FB-001
title: "Login crashes on Safari"
status: new              # canonical: derived from folder, cached here
priority: null           # null | low | medium | high | critical
source: user             # user | internal | automated | external
reporter: "tcanaud"
created: "2026-02-18"
updated: "2026-02-18"
tags: [auth, safari, crash]
linked_to:
  backlog: []
  features: []
  feedbacks: []          # for grouping related items
---
```

**Backlog schema (YAML frontmatter):**

```yaml
---
id: BL-001
title: "Improve authentication flow"
status: open             # canonical: derived from folder, cached here
priority: high
created: "2026-02-18"
updated: "2026-02-18"
owner: "tcanaud"
feedbacks: [FB-001, FB-003]
features: []             # link to feature if promoted
tags: [auth, ux]
---
```

**Key design decisions:**
- Folder is the **source of truth** for status; frontmatter is a cache
- Drift detection if frontmatter status does not match folder name
- IDs are sequential (`FB-001`, `BL-001`), auto-assigned by scanning filesystem
- Templates enforce consistent structure across all items

### Out of Scope for MVP

| Feature | Rationale | When |
|---------|-----------|------|
| `/product.review` — periodic review reports | Nice to have, not essential for core loop | v2 |
| Automated feedback resolution (auto-move to `resolved/` on feature release) | Requires deep integration with feature lifecycle | v2 |
| External tool bridge SDK / webhook receiver | External tools can drop files in `inbox/` — no SDK needed for MVP | v2 |
| Priority scoring algorithm | Manual priority assignment is sufficient for MVP | v2 |
| Backlog item dependency tracking | Backlogs are independent for MVP | v2 |
| tcsetup integration (installer) | Manual directory creation for MVP; tcsetup support after validation | v2 |
| Knowledge system integration (`.knowledge/` guide) | Document after the module stabilizes | Post-MVP |

### MVP Success Criteria

1. **End-to-end pipeline works**: A feedback can be created via `/product.intake`, triaged via `/product.triage`, converted to a backlog, and promoted to a feature via `/product.promote` — with all traceability links intact
2. **Filesystem-as-state validated**: Moving a file between status directories correctly updates its state; `/product.check` detects desync
3. **AI triage adds value**: `/product.triage` groups related feedbacks in a way the user confirms as meaningful (not just keyword matching)
4. **kai dogma compliance**: Zero runtime dependencies, file-based, git-native, Claude commands as UI, drift detection operational
5. **Index consistency**: `index.yaml` accurately reflects the filesystem state after every command

### Future Vision

**v2 — Automation & Integration:**
- Automated resolution: when a feature reaches `release` stage, linked feedbacks auto-move to `resolved/`
- `/product.review` generates periodic review reports in `.product/reviews/`
- tcsetup integration: `npx tcsetup` installs and configures `.product/` like other modules
- Knowledge system guide: `/k how does product management work?` returns verified documentation

**v3 — Intelligence & Analytics:**
- Priority scoring based on feedback frequency, severity, and business impact
- Trend analysis across review periods
- Predictive triage: suggest priority and category before user confirms
- Cross-project feedback aggregation (for multi-repo setups)

**Long-term vision:**
The Product Manager module completes the kai governance circle:

```
User feedback (.product/)
  → Product planning (_bmad/)
    → Implementation specs (specs/)
      → Architecture decisions (.adr/)
        → Agreements (.agreements/)
          → Feature lifecycle (.features/)
            → Documentation (.knowledge/)
              → Code delivery
                → User feedback (.product/)  ← full circle
```

Every project that runs `npx tcsetup` gets not just a development governance system, but a complete product management layer — from user signal to shipped code and back.

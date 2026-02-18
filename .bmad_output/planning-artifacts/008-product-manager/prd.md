---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
classification:
  projectType: cli_tool
  domain: general
  complexity: low
  projectContext: brownfield
inputDocuments:
  - ".bmad_output/planning-artifacts/008-product-manager/product-brief-kai-2026-02-18.md"
  - ".knowledge/architecture.md"
  - ".knowledge/snapshot.md"
  - ".knowledge/guides/project-philosophy.md"
  - ".knowledge/guides/create-new-package.md"
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 4
workflowType: 'prd'
---

# Product Requirements Document — kai Product Manager Module

**Author:** tcanaud
**Date:** 2026-02-18

## Executive Summary

kai is a file-based project governance system that lives entirely inside the repository — architecture decisions, conventions, feature lifecycle, agreements, and documentation freshness are all plain text under version control. Seven modules already cover the full journey from architecture decisions through feature specification to code delivery. The Product Manager module closes the last structural gap: **there is no structured, versionable way to capture user feedback, triage it into actionable work, and trace it through the planning pipeline to shipped code.**

The module introduces a `.product/` directory — the 8th dotfile directory in the kai governance stack — containing a feedback intake system, a backlog management layer, and an AI-powered triage engine. Feedback enters through an extensible inbox (manual today, connected to external sources tomorrow), gets semantically clustered and triaged by Claude, becomes backlog items, and — when significant enough — gets promoted into full features via the existing `/feature.workflow` pipeline. The target operating model: a single developer-supervisor periodically runs a full loop with Claude — triage new feedback, update the backlog, promote what matters, verify features in progress. Every step produces a versioned file. Every transition is a git diff. The complete lineage from user complaint to shipped code is traceable.

### What Makes This Special

The differentiator is the combination of **end-to-end traceability** and **AI-powered semantic triage** — each reinforcing the other. Traceability without intelligent triage is just a filing cabinet. Triage without traceability is just a suggestion engine. Together, they create a system where patterns invisible to manual review (related complaints across different phrasings, emerging themes across time) are surfaced and automatically linked to the work they produce. The filesystem-as-state model (directories ARE statuses, `git mv` IS a state transition) ensures the system remains queryable with `ls` and `grep`, auditable with `git log`, and fully portable — no external service, no database, no dashboard. The inbox architecture is designed as an extensible entry point: today it accepts manually dropped files, tomorrow it can receive webhooks, Slack exports, or form submissions — the processing pipeline stays identical.

## Project Classification

- **Project Type:** CLI tool / Developer tool — slash commands + filesystem operations, targeting developers using the kai governance stack
- **Domain:** General software tooling — no regulated domain, no compliance constraints
- **Complexity:** Low — well-established architectural patterns from 7 existing modules; conventions, ADRs, and agreements define the path
- **Project Context:** Brownfield — integrating into an existing ecosystem with clear conventions (ESM-only, zero runtime dependencies, file-based artifacts, Claude Code commands as UI)

## Success Criteria

### User Success

The primary success signal is **witnessing the complete lifecycle**: a feedback enters through `/product.intake`, gets semantically clustered by `/product.triage`, becomes a backlog item, gets promoted to a kai feature via `/product.promote`, flows through the existing `/feature.workflow` pipeline (brief → PRD → spec → tasks → code → release), and the original feedback automatically moves to `resolved/`. When that full loop completes for the first time with intact traceability links at every step, the module has proven its value.

Secondary success signals:
- `/product.triage` produces groupings that feel meaningful — not keyword matches, but genuine semantic clusters that surface non-obvious connections
- `/product.dashboard` gives an accurate pulse of product health in under 5 seconds
- `/product.check` catches real drift (stale feedbacks, orphaned backlogs, status desync) without false positives

### Business Success

The immediate business goal is **personal adoption**: the module becomes part of the daily kai workflow for the project owner. Success means running periodic triage loops with Claude becomes a natural habit, not a chore. External adoption via tcsetup is a v2 goal — the module must prove itself on real projects first before being offered to others.

### Technical Success

- **kai dogma compliance**: zero runtime dependencies, file-based, git-native, Claude commands as UI, drift detection operational
- **Filesystem-as-state validated**: moving a file between status directories correctly updates its state; `/product.check` detects desync between folder location and frontmatter status
- **Index consistency**: `index.yaml` accurately reflects the filesystem state after every command
- **Pattern integrity**: follows the same conventions as the 7 existing modules — YAML frontmatter + Markdown body, centralized index, glob+grep queryable

### Measurable Outcomes

| Metric | Target | Measurement |
|--------|--------|-------------|
| Full lifecycle completion | At least 1 feedback completes the entire loop (new → resolved) | Verify traceability links from feedback to shipped feature |
| Triage quality | AI groupings confirmed as meaningful by user | Qualitative — user validates clusters make sense |
| Drift detection accuracy | >= 90% actionable findings (no false positives) | `/product.check` findings reviewed by user |
| Index consistency | Zero desync after any command | `index.yaml` matches filesystem state |
| Feedback-to-backlog conversion | >= 40% of triaged feedbacks result in backlog items | Count ratio |
| Backlog-to-feature promotion | >= 20% of backlogs become features | Count ratio |

## User Journeys

### Journey 1: TC — First Feedback Loop (Happy Path)

TC runs three projects on the kai stack. After a demo of his latest tool, a colleague messages him: "search is unusable on large repos — takes 40 seconds." Instead of letting it rot in Slack, TC opens his terminal.

**Opening Scene:** TC creates a text file in `.product/inbox/` describing the complaint — source, context, severity. He runs `/product.intake`. The command processes the inbox file, generates a structured feedback with YAML frontmatter (auto-assigned `FB-001`, category proposed as `optimization`), and places it in `feedbacks/new/`. TC sees the file, confirms the category, and moves on. Three more feedbacks trickle in over the next week — a crash report from a tester, a feature request from a user, another performance complaint.

**Rising Action:** With 4 feedbacks accumulated in `new/`, TC runs `/product.triage`. Claude reads all new feedbacks, detects that FB-001 and FB-004 are both about search performance on large repos (different wording, same root cause), proposes grouping them. It also proposes FB-002 (the crash) as a standalone `critical-bug` backlog, and FB-003 (feature request) as a `new-feature` backlog. TC reviews the proposals, confirms the groupings, adjusts one category. Feedbacks move to `triaged/`, two backlog items appear in `backlogs/open/`.

**Climax:** BL-001 (search performance, 2 linked feedbacks) feels significant enough. TC runs `/product.promote BL-001`. The command creates `.features/009-search-perf.yaml`, moves the backlog to `promoted/`, preserves traceability links (BL-001 → FB-001, FB-004), and tells TC to run `/feature.workflow 009-search-perf`. The full kai pipeline activates — brief, PRD, spec, tasks, implementation.

**Resolution:** Weeks later, feature 009 reaches `release` stage. The two original feedbacks (FB-001, FB-004) automatically move to `resolved/` with links to the feature that fixed them. TC runs `/product.dashboard` — zero critical bugs, zero stale feedbacks, full lifecycle visible. He can trace "colleague said search is slow" → FB-001 → BL-001 → feature 009 → code → release. The loop is closed.

### Journey 2: TC — Regression Detection (Edge Case)

**Opening Scene:** Two weeks after deploying the search fix (feature 009), TC drops a new inbox file: a user reports search is slow again on a specific dataset. He runs `/product.intake` — FB-012 is created in `feedbacks/new/`.

**Rising Action:** TC runs `/product.triage`. Claude detects semantic similarity between FB-012 and FB-001 (resolved). It follows the traceability chain: FB-001 → BL-001 → feature 009-search-perf → `lifecycle.stage: release`, `stage_since: 2026-03-01`. FB-012 was created on 2026-03-15 — **after** the release.

**Climax:** Verdict: **REGRESSION**. Triage automatically creates a backlog item BL-008 with priority `critical`, tag `regression`, and links to the original backlog BL-001 and the feature 009. FB-012 moves to `triaged/`. No human judgment needed for the classification — the temporal logic is deterministic.

**Resolution:** TC sees the regression flag in `/product.dashboard`, promotes BL-008, and the repair cycle begins. The traceability chain shows exactly what broke and what the original fix was — debugging starts from knowledge, not from scratch.

### Journey 3: TC — Duplicate of Resolved Feedback

**Opening Scene:** A new tester joins the project and reports "search is slow on large repos" — unaware that this was already fixed in the latest release. TC drops it in inbox, runs `/product.intake` — FB-015 created.

**Rising Action:** `/product.triage` detects similarity with FB-001 (resolved). Same traceability chain: FB-001 → BL-001 → feature 009 → release on 2026-03-01. But FB-015 was created on 2026-02-28 — the tester was on an old version.

**Climax:** Verdict: **DUPLICATE-RESOLVED**. FB-015 moves to `excluded/` with reason `duplicate-resolved`, link to FB-001, and a reference to feature 009 that already shipped the fix.

**Resolution:** The audit trail is clean. The tester's feedback is acknowledged, not lost — but properly classified. `/product.dashboard` shows no new work needed.

### Journey 4: TC — Maintenance Loop (Ops/Periodic Review)

**Opening Scene:** Every Monday morning, TC starts his week with a product health check. He runs `/product.dashboard`.

**Rising Action:** The dashboard shows: 7 feedbacks in `new/`, 1 `critical-bug` flagged, 3 backlogs `in-progress`, 12 total feedbacks with 65% conversion to backlogs. The critical bug catches his eye.

**Climax:** TC runs `/product.triage` to process the 7 new feedbacks. Claude proposes: 2 are related to the critical bug (grouped), 3 are optimization requests (grouped into 1 backlog), 1 is a duplicate of an existing backlog, 1 is noise (excluded). TC reviews, confirms all, adjusts the category on one from `optimization` to `evolution`.

**Resolution:** TC runs `/product.check` — zero drift, zero orphaned backlogs, zero status desync. He promotes 1 backlog, adds the others to his mental roadmap. The weekly loop took 10 minutes. He runs `/product.dashboard` one more time to confirm: `new/` is empty, backlogs are updated, the product pulse is healthy.

### Journey 5: External Tools — Inbox Drop (Secondary User)

**Opening Scene:** TC has a simple script that watches a shared Slack channel. When someone posts with the hashtag `#feedback`, the script exports the message as a Markdown file and drops it in `.product/inbox/`.

**Rising Action:** Over the weekend, 3 Slack messages arrive. Monday morning, TC sees 3 files in `inbox/`. He runs `/product.intake` — the command processes all 3 files, creates structured feedbacks in `feedbacks/new/` with proper YAML frontmatter, and cleans up `inbox/`.

**Climax:** The feedbacks preserve the original source (`source: external`), reporter, and timestamp from the Slack messages. They're now fully integrated into the triage pipeline — indistinguishable from manually created feedbacks.

**Resolution:** The inbox contract is simple: drop a file, the system processes it. No API, no authentication, no SDK. The filesystem IS the API.

### Journey Requirements Summary

| Journey | Capabilities Revealed |
|---------|----------------------|
| 1 — First Loop | Intake processing, semantic triage, grouping, backlog creation, feature promotion, automatic resolution closure, dashboard visibility |
| 2 — Regression | Temporal comparison (feedback date vs release date), traceability chain traversal, automatic regression classification, critical priority escalation |
| 3 — Duplicate | Same temporal mechanism, `excluded/` management with reasons, traceability links to resolved feedbacks |
| 4 — Maintenance | Dashboard metrics, batch triage, drift detection, weekly operational loop |
| 5 — Inbox Drop | Inbox processing, external source support, batch intake, source preservation |

**Cross-cutting requirements:**
- **Category system**: `critical-bug`, `bug`, `optimization`, `evolution`, `new-feature` — proposed by AI, confirmed by user
- **Temporal regression detection**: deterministic duplicate vs regression classification based on feedback creation date vs feature release date
- **Traceability chain**: feedback → backlog → feature → release, traversable in both directions
- **Filesystem-as-API**: inbox as drop zone, directories as status, `git mv` as transition

## Innovation & Novel Patterns

### Detected Innovation Areas

**1. Filesystem-as-State Machine for Product Management**

No existing product management tool uses the filesystem as a literal state machine. In this system, directories ARE statuses (`feedbacks/new/`, `feedbacks/triaged/`, `feedbacks/resolved/`), and `git mv` IS a state transition. This means:
- `ls feedbacks/new/` is a query
- `git log --follow feedbacks/resolved/FB-001.md` is a complete audit trail
- `git diff` shows every state transition ever made
- No database, no migration, no schema evolution — the filesystem is the schema

This pattern exists in kai for feature lifecycle (computed from artifacts) but has never been applied to product management where the volume of items and frequency of transitions is significantly higher.

**2. Deterministic Temporal Regression Detection**

The system uses a novel mechanism to distinguish regressions from duplicates without human judgment: compare the feedback creation date against the release date of the feature that resolved the original feedback. This is:
- Fully deterministic — no ML model, no confidence threshold, no human decision
- Built on existing data — feedback timestamps and feature lifecycle dates already exist in the system
- A form of **temporal reasoning over the traceability chain** — the system traverses feedback → backlog → feature → release date to make an inference

No file-based issue tracker or feedback system implements this pattern.

**3. AI Semantic Triage on Filesystem Artifacts**

Using Claude's language understanding to perform semantic clustering on YAML+Markdown files in a git repository is an unprecedented combination. Existing AI-powered triage tools operate on database records or API payloads. Here, the AI reads files from disk, understands their content and metadata, proposes groupings, and the user confirms — producing new files as output. The entire triage session is a set of file operations, fully reproducible and auditable via `git diff`.

### Market Context & Competitive Landscape

| Tool | Approach | Gap This Fills |
|------|----------|---------------|
| Jira / Linear | Cloud database, proprietary API | Not file-based, not git-native, not portable |
| GitHub Issues | Platform-locked, no YAML frontmatter | No semantic triage, no filesystem-as-state, no kai integration |
| git-bug | Git object database (not human-readable) | No backlog concept, no promotion pipeline, no triage |
| TrackDown | Markdown files, no structured metadata | No triage workflow, no lifecycle tracking, no drift detection |
| Sciit | Branch-coupled issue tracking | No persistent feedback across branches, no AI triage |

None of these combine file-based state, AI-powered triage, deterministic regression detection, and full lifecycle traceability in a single system.

### Innovation Validation & Risk

| Innovation | Validation Approach | Risk | Mitigation |
|-----------|-------------------|------|-----------|
| Filesystem-as-state | Validate `git mv` transitions, `/product.check` desync detection, queryability at scale (50+ feedbacks) | Doesn't scale beyond 100+ per folder | Glob scanning fast enough for single-user; index.yaml as cached view |
| Temporal regression detection | Synthetic scenarios: inject feedbacks before/after release, verify automatic classification | False positives on unrelated similar feedbacks | Semantic similarity must be high; triage proposes, user confirms; fallback to manual |
| AI semantic triage | Accumulate 10+ feedbacks with varying phrasings, run `/product.triage`, confirm meaningful groupings | Inconsistent across runs | Always human-confirmed; system never auto-acts without supervision option |

## CLI Tool Specific Requirements

### Project-Type Overview

The Product Manager module is a set of Claude Code slash commands operating on filesystem artifacts. It is not a traditional CLI tool invoked from the shell — the interface is Claude Code, the runtime is Claude's language understanding, and the output is YAML+Markdown files in a git repository. There is no binary to install, no shell completion to configure, no interactive TUI to build.

### Command Structure

All 6 commands follow the existing kai slash command pattern — Markdown prompt templates in `.claude/commands/`:

| Command | Arguments | Flags | Behavior |
|---------|-----------|-------|----------|
| `/product.intake` | optional free-text description | — | Process `inbox/` files into structured feedbacks in `feedbacks/new/`. If free-text provided, create feedback directly without inbox file. |
| `/product.triage` | — | `--supervised` | Read all `feedbacks/new/`, perform semantic clustering, propose groupings and categories, create backlogs. Default: autonomous. `--supervised`: human confirms each action. |
| `/product.backlog` | optional BL-xxx | — | Without argument: list all backlogs by status. With argument: show detail for specific backlog item. |
| `/product.promote` | BL-xxx (required) | — | Convert backlog item to kai feature. Create `.features/xxx.yaml`, move backlog to `promoted/`, preserve traceability links. |
| `/product.check` | — | — | Drift detection: stale feedbacks, orphaned backlogs, status/folder desync, broken traceability chains. |
| `/product.dashboard` | — | `--json` | Overview of feedbacks by status, backlogs by status, category distribution, conversion metrics, warnings. `--json` for scripting. |

### Output Formats

- **Primary output**: YAML frontmatter + Markdown body files (feedbacks, backlogs) — human-readable, git-diffable, glob+grep queryable
- **Index output**: `index.yaml` — centralized registry of all feedbacks and backlogs with metadata, updated after every command
- **Dashboard output**: Markdown (default) or JSON (`--json` flag) — for human consumption or scripting integration
- **Check output**: structured findings report (same pattern as `/agreement.check`) — severity, description, suggested action

### Interaction Model

The default operating mode is **autonomous**: Claude reads the filesystem, makes decisions (groupings, categories, duplicate/regression classification), and writes the results. The human reviews after the fact via `git diff` or `/product.dashboard`.

The `--supervised` flag on `/product.triage` switches to **human-in-the-loop**: Claude proposes each action, the human confirms or rejects before it executes. This is the opt-in mode, not the default.

This inversion (AI-first, human optional) is deliberate — it enables the "periodic loop" operating model where a dev supervisor reviews a batch of Claude's decisions rather than approving each one individually.

### Implementation Considerations

- **No config.yaml**: conventions are sufficient. Categories are hardcoded in templates, triage mode is a command flag, owner is tracked in `.features/`. Convention before code.
- **No runtime binary**: all commands are Claude Code slash command templates (`.claude/commands/product.*.md`). Zero code to install.
- **Index as cache**: `index.yaml` is a performance optimization, not a source of truth. The filesystem (directories + file frontmatter) is always authoritative. `/product.check` detects index drift.
- **Template-driven schemas**: `_templates/feedback.tpl.md` and `_templates/backlog.tpl.md` define the YAML frontmatter schema. Changing the schema means changing the template — no migration needed.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Problem-solving MVP — deliver the complete feedback→code→resolution loop with all 6 commands + automatic resolution operational. The chain is the product; every link must work for the product to exist. No time pressure allows building each piece solid rather than shipping a partial loop.

**Resource Requirements:** Solo developer + Claude Code. No team coordination needed. All implementation is Claude Code slash command templates + filesystem conventions.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:** All 5 journeys — happy path, regression detection, duplicate resolution, maintenance loop, inbox drop.

**Must-Have Capabilities:**

| # | Capability | Command | Notes |
|---|-----------|---------|-------|
| 1 | Feedback intake (free-text + inbox processing) | `/product.intake` | Auto-assign ID, propose category, create in `feedbacks/new/` |
| 2 | AI semantic triage (autonomous + supervised mode) | `/product.triage` | Clustering, grouping, category assignment, duplicate/regression detection |
| 3 | Backlog management (list + detail) | `/product.backlog` | View by status, detail view with linked feedbacks |
| 4 | Feature promotion with traceability | `/product.promote` | Create feature YAML, move to `promoted/`, preserve links |
| 5 | Drift detection | `/product.check` | Stale feedbacks, orphaned backlogs, folder/frontmatter desync, broken chains |
| 6 | Dashboard (Markdown + JSON) | `/product.dashboard` | Status overview, category distribution, conversion metrics, warnings |
| 7 | Automatic resolution | (triggered by feature lifecycle) | When linked feature reaches `release`, feedbacks auto-move to `resolved/` |

**Category system (hardcoded in templates):** `critical-bug`, `bug`, `optimization`, `evolution`, `new-feature`

**Directory structure:**
```
.product/
  index.yaml
  _templates/
    feedback.tpl.md
    backlog.tpl.md
  inbox/
  feedbacks/{new,triaged,excluded,resolved}/
  backlogs/{open,in-progress,done,promoted,cancelled}/
```

### Post-MVP Features

**Phase 2 (Growth):**
- `/product.review` — periodic review reports in `.product/reviews/`
- tcsetup integration — `npx tcsetup` installs and configures `.product/`
- Knowledge system guide — `/k how does product management work?`
- Priority scoring based on feedback frequency and category distribution

**Phase 3 (Expansion):**
- Predictive triage — suggest priority and category before user confirms
- Inbox connected to external sources — webhooks, Slack bots, form processors
- Trend analysis across review periods
- Cross-project feedback aggregation for multi-repo setups

### Risk Mitigation Strategy

**Technical Risks:**
- Automatic resolution requires reading feature lifecycle transitions — if the mechanism is too complex, fallback to a `/product.resolve` manual command that checks linked features and moves feedbacks
- AI triage quality depends on prompt engineering — invest time in the slash command template; iterate on real feedbacks before considering it done

**Market Risks:**
- Single-user validation first (tcanaud on kai projects) before offering to others via tcsetup — no risk of premature generalization

**Resource Risks:**
- All 6+1 capabilities are slash command templates, not code. If time is limited, `/product.check` and `/product.dashboard` can be simplified (fewer drift checks, simpler metrics) without breaking the core loop.

## Functional Requirements

### Feedback Intake

- FR1: User can create a structured feedback from a free-text description provided directly to the command
- FR2: System can process all files in `inbox/` and convert each into a structured feedback in `feedbacks/new/`
- FR3: System can auto-assign a sequential feedback ID (FB-xxx) by scanning existing feedbacks
- FR4: System can propose a category (`critical-bug`, `bug`, `optimization`, `evolution`, `new-feature`) for each feedback based on content analysis
- FR5: System can preserve source metadata (reporter, source type, original timestamp) from inbox files
- FR6: System can clean up processed files from `inbox/` after successful intake

### Semantic Triage

- FR7: System can read all feedbacks in `feedbacks/new/` and perform semantic clustering to identify related items
- FR8: System can detect duplicate feedbacks based on semantic similarity (not keyword matching)
- FR9: System can detect similarity between new feedbacks and resolved feedbacks in `feedbacks/resolved/`
- FR10: System can determine if a similar-to-resolved feedback is a regression or a duplicate by comparing feedback creation date against the linked feature's release date
- FR11: System can automatically classify a post-release similar feedback as REGRESSION and create a critical-priority backlog
- FR12: System can automatically classify a pre-release similar feedback as DUPLICATE-RESOLVED and move it to `excluded/` with reason and traceability links
- FR13: System can propose batch actions (group, exclude, create backlog) for all new feedbacks in a single triage session
- FR14: System can assign or reassign categories to feedbacks during triage
- FR15: System can move triaged feedbacks from `feedbacks/new/` to `feedbacks/triaged/`
- FR16: System can move excluded feedbacks from `feedbacks/new/` to `feedbacks/excluded/` with an exclusion reason
- FR17: System can create backlog items from grouped feedbacks with bidirectional traceability links
- FR18: System can operate in autonomous mode (default) where Claude executes all triage decisions
- FR19: System can operate in supervised mode (`--supervised`) where each triage action requires human confirmation

### Backlog Management

- FR20: User can list all backlog items grouped by status directory
- FR21: User can view detail for a specific backlog item including linked feedbacks
- FR22: System can auto-assign a sequential backlog ID (BL-xxx) by scanning existing backlogs

### Feature Promotion

- FR23: User can promote a backlog item to a kai feature by specifying its ID
- FR24: System can create a `.features/xxx.yaml` file for the promoted backlog with the next available feature number
- FR25: System can move the promoted backlog from `backlogs/open/` to `backlogs/promoted/`
- FR26: System can preserve bidirectional traceability links (backlog → feature, backlog → feedbacks) during promotion
- FR27: System can instruct the user to run `/feature.workflow` for the newly created feature

### Automatic Resolution

- FR28: System can detect when a feature linked to feedbacks (via backlog → feature chain) reaches `release` stage
- FR29: System can automatically move linked feedbacks to `feedbacks/resolved/` when the associated feature is released
- FR30: System can update feedback frontmatter with resolution metadata (resolved date, resolving feature, resolving backlog)

### Drift Detection

- FR31: System can detect feedbacks whose frontmatter status does not match their directory location
- FR32: System can detect backlog items whose frontmatter status does not match their directory location
- FR33: System can detect stale feedbacks (in `feedbacks/new/` beyond a reasonable age threshold)
- FR34: System can detect orphaned backlogs (backlogs with no linked feedbacks)
- FR35: System can detect broken traceability chains (feedbacks linked to non-existent backlogs, backlogs linked to non-existent features)
- FR36: System can report findings with severity level, description, and suggested corrective action

### Dashboard & Visibility

- FR37: User can view a summary of all feedbacks grouped by status (new, triaged, excluded, resolved)
- FR38: User can view a summary of all backlogs grouped by status (open, in-progress, done, promoted, cancelled)
- FR39: User can view category distribution across all feedbacks
- FR40: User can view conversion metrics (feedback-to-backlog ratio, backlog-to-feature promotion rate)
- FR41: User can view active warnings (stale feedbacks, drift findings, critical bugs)
- FR42: User can export dashboard output as JSON (`--json` flag) for scripting integration

### Index Management

- FR43: System can maintain an `index.yaml` that reflects the current state of all feedbacks and backlogs
- FR44: System can update `index.yaml` after every command execution
- FR45: System can rebuild `index.yaml` from filesystem state if it becomes desynced

## Non-Functional Requirements

### Performance

- NFR1: `/product.dashboard` produces output in under 5 seconds for a repository with up to 200 feedbacks and 50 backlogs
- NFR2: `/product.triage` completes a full scan of `feedbacks/new/` with up to 30 items in a single Claude session (no context overflow)
- NFR3: `/product.check` completes all drift detection checks in under 10 seconds for a repository with up to 200 feedbacks
- NFR4: `index.yaml` rebuild from filesystem state completes in under 3 seconds

### Scalability

- NFR5: The filesystem-as-state model supports up to 200 feedbacks across all status directories without performance degradation of glob-based queries
- NFR6: `index.yaml` serves as a performance cache to avoid full filesystem scans for read-heavy operations (dashboard, backlog listing)
- NFR7: Sequential ID assignment (FB-xxx, BL-xxx) remains correct with up to 999 items per type

### Integration

- NFR8: Automatic resolution correctly reads `.features/xxx.yaml` lifecycle data (stage, stage_since) to determine feature release dates
- NFR9: Feature promotion produces `.features/xxx.yaml` files compatible with the existing `/feature.workflow` pipeline
- NFR10: All generated files (feedbacks, backlogs, index) follow kai conventions: YAML frontmatter + Markdown body, parseable by glob+grep
- NFR11: All filesystem operations use `git mv` semantics (move, not copy+delete) to preserve git history and enable `git log --follow`

### Portability

- NFR12: The module operates with zero runtime dependencies — all commands are Claude Code slash command templates, no npm packages required
- NFR13: The `.product/` directory is fully portable — cloning the repo includes the complete product management state
- NFR14: All artifacts are human-readable without specialized tooling — a user without Claude Code can browse and edit `.product/` manually

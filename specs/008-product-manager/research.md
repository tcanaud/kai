# Research: kai Product Manager Module

**Feature**: 008-product-manager
**Date**: 2026-02-18

## Research Questions

### R1: Two-layer architecture — npm package + slash commands

**Decision**: Follow the standard kai package pattern with two distinct layers:
1. **npm package** (`packages/product-manager/`) — ESM-only, zero-dependency Node.js installer/updater that creates `.product/`, copies templates, and installs the 6 slash commands. Provides `npx product-manager init` and `npx product-manager update`.
2. **Slash command templates** (`.claude/commands/product.*.md`) — Markdown files that Claude Code interprets at runtime. These define the AI-powered behavior (triage, intake, etc.).

**Rationale**: Every kai module follows this two-layer pattern (see `.knowledge/guides/create-new-package.md`):
- `adr-system` → package installs `.adr/` + commands
- `agreement-system` → package installs `.agreements/` + commands
- `feature-lifecycle` → package installs `.features/` + commands
- `knowledge-system` → package installs `.knowledge/` + commands

The installer handles directory scaffolding, template copying, and command installation. The slash commands handle the AI-powered runtime behavior. These are separate concerns. The PRD's "no runtime binary" refers to the commands themselves (no process runs; Claude interprets Markdown), not to the installer which follows the standard `npx` pattern.

**Alternatives considered**:
- Commands-only (no installer package) — rejected because it breaks the `npx tcsetup` promise; every other module is installable via tcsetup, and product-manager should be too
- MCP server — rejected because it adds a runtime dependency and breaks the zero-deps dogma
- Manual setup only — rejected because it creates friction and diverges from the established onboarding experience

### R2: Filesystem-as-state machine — directory layout

**Decision**: Use status-named subdirectories under `feedbacks/` and `backlogs/` where the directory name IS the canonical status. File movement between directories IS a state transition.

**Rationale**: This is a novel application of the kai file-based pattern. Existing modules use computed state (feature stage is derived from artifact presence), but product management benefits from explicit directory-based state because:
- Status changes frequently (new → triaged → resolved)
- `ls feedbacks/new/` is an instant query
- `git mv feedbacks/new/FB-001.md feedbacks/triaged/FB-001.md` is an atomic transition with full git history
- `git log --follow` traces the complete lifecycle

**Alternatives considered**:
- Single directory with status in frontmatter only — rejected because listing by status requires reading every file's frontmatter
- Database file (single index.yaml) as source of truth — rejected because it's not human-browsable and git diffs would be noisy

### R3: Sequential ID assignment strategy

**Decision**: Auto-assign IDs by scanning all existing files across ALL status directories, extracting the highest number, and incrementing. Format: `FB-001`, `BL-001` (zero-padded to 3 digits).

**Rationale**: Filesystem-based sequential assignment is simple, predictable, and sufficient for single-user operation. The scan covers all directories to prevent ID reuse after file movement.

**Alternatives considered**:
- UUID-based IDs — rejected because they're not human-friendly; `FB-001` is easier to reference in conversation and commands
- Timestamp-based IDs — rejected because they don't provide meaningful ordering and are harder to type
- Counter file — rejected because it introduces a coordination point; scanning is fast enough for <999 items

### R4: AI semantic triage — prompt engineering approach

**Decision**: The `/product.triage` command template will contain detailed instructions for Claude to:
1. Read all files in `feedbacks/new/`
2. Read all files in `feedbacks/resolved/` for comparison
3. Perform semantic clustering based on content similarity
4. For each cluster, propose: group action (create backlog), exclude action, or standalone treatment
5. For similarity to resolved feedbacks: compare dates for regression vs. duplicate classification
6. Present proposals to the user before executing (supervised mode) or execute directly (autonomous mode)

**Rationale**: Claude's language understanding is the triage engine — the prompt template defines the decision framework, Claude applies it to the actual feedback content. This is the same approach used by BMAD agents (e.g., `bmad-agent-bmm-pm.md`) which encode complex product management logic in Markdown prompts.

**Alternatives considered**:
- External NLP tool for clustering — rejected because it adds a dependency
- Keyword-based matching — rejected because the spec explicitly requires semantic similarity ("not keyword matching")
- Embedding-based similarity (pre-computed vectors) — rejected because it requires a runtime component; Claude's in-context understanding is sufficient for the target scale (30 items per triage session)

### R5: Index management strategy

**Decision**: `index.yaml` is a performance cache, not the source of truth. The filesystem (directories + file frontmatter) is authoritative. Every command updates the index after execution. A rebuild function reconstructs the index from filesystem state.

**Rationale**: This follows the kai pattern where computed state is derived from artifacts. The index prevents full filesystem scans for read-heavy operations (dashboard, backlog listing). If the index drifts, `/product.check` detects it, and any command can rebuild it.

**Alternatives considered**:
- No index (always scan filesystem) — rejected because it makes dashboard and listing commands slower for large repositories
- Index as source of truth — rejected because it creates a single point of failure and drift becomes harder to detect

### R6: Integration with feature lifecycle

**Decision**: `/product.promote` creates a `.features/{NNN}-{name}.yaml` file using the same template (`feature.tpl.yaml`) and updates `.features/index.yaml` — the exact same mechanism used by `/feature.workflow` when scaffolding a new feature. The promoted backlog retains a `features: ["NNN-name"]` field for traceability.

**Rationale**: Feature promotion must produce artifacts that are 100% compatible with the existing feature lifecycle system. Using the same template and index update mechanism ensures `/feature.workflow`, `/feature.status`, and `/feature.list` work immediately on promoted features.

**Alternatives considered**:
- Custom feature format — rejected because it would break compatibility with existing lifecycle commands
- Only creating the feature YAML (skip index) — rejected because `/feature.list` reads the index

### R7: Category system

**Decision**: Five predefined categories hardcoded in the feedback template: `critical-bug`, `bug`, `optimization`, `evolution`, `new-feature`. Categories are proposed by Claude during intake/triage and confirmed by the user.

**Rationale**: The PRD explicitly states "categories are hardcoded in templates" and "convention before code." Five categories cover the standard product management taxonomy without over-engineering. Extensibility is a post-MVP concern.

**Alternatives considered**:
- User-defined categories in config — rejected for MVP because it adds unnecessary configuration
- Free-form tags only — rejected because categories enable structured dashboard metrics (e.g., "3 critical bugs, 5 optimizations")
- Larger predefined set — rejected to keep the system simple; 5 categories are sufficient for single-project use

### R8: Stale feedback threshold

**Decision**: Default threshold of 14 days (2 weeks) for feedback in `feedbacks/new/` before triggering a staleness warning in `/product.check`.

**Rationale**: Two weeks aligns with a typical sprint cycle. Feedback that hasn't been triaged within one sprint cycle is likely being ignored. The threshold is documented as a convention in the `/product.check` command template, not a configuration value.

**Alternatives considered**:
- 7 days — too aggressive for a periodic triage workflow
- 30 days — too lenient; feedback should be triaged within 2 sprint cycles at most
- Configurable threshold — rejected for MVP; convention before code

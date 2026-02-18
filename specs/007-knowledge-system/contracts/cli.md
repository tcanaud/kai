# CLI Contract: knowledge-system

## Binary

`knowledge-system` (via `npx @tcanaud/knowledge-system <command>`)

## Commands

### `init`

**Purpose**: Scaffold `.knowledge/` directory with default config and templates.

**Input**: Flags (optional)
- `--yes` — skip confirmation prompts

**Behavior**:
1. Detect environment (BMAD, SpecKit, Agreements, ADR, Features)
2. Create `.knowledge/` directory structure
3. Write `config.yaml` with detected source paths
4. Write empty `index.yaml`
5. Write `architecture.md` scaffold
6. Create `guides/` directory
7. Copy Claude Code commands to `.claude/commands/`

**Output**: Console log of created files. Exit 0 on success.

**Idempotency**: Safe to re-run — preserves existing content, only adds missing structural files.

---

### `update`

**Purpose**: Refresh command templates without modifying user content.

**Input**: None

**Behavior**:
1. Verify `.knowledge/` exists (exit 1 with error if not)
2. Copy latest command templates to `.claude/commands/`
3. Update BMAD integration if detected

**Output**: Console log of updated files. Exit 0 on success.

**Guarantee**: Never modifies `architecture.md`, `guides/*.md`, `config.yaml` user settings, or `index.yaml`.

---

### `refresh`

**Purpose**: Regenerate `snapshot.md` and rebuild `index.yaml` from current project artifacts.

**Input**: None

**Behavior**:
1. Read `config.yaml` for source paths
2. Scan `.agreements/conv-*` for active conventions
3. Scan `.adr/` (global, domain, local) for ADRs
4. Scan `.features/` for feature manifests
5. Scan `.knowledge/guides/` for guide frontmatter
6. Check freshness of each guide (git log vs last_verified)
7. Write `index.yaml` with full catalog
8. Write `snapshot.md` with aggregated summaries

**Output**: Console log of scan results. Exit 0 on success.

**Guarantee**: Only writes to `.knowledge/index.yaml` and `.knowledge/snapshot.md`. Read-only access to all other directories.

---

### `check`

**Purpose**: Verify freshness of all knowledge guides.

**Input**: None

**Behavior**:
1. Read all guides from `.knowledge/guides/`
2. For each guide with `watched_paths`:
   - Run `git log -1 --format=%aI -- <path>` for each watched path
   - Compare last modification date against `last_verified`
   - Classify as VERIFIED, STALE, or UNKNOWN
3. For each guide with `references`:
   - Check if referenced conventions/ADRs still exist and are not superseded
4. Output report to stdout

**Output format**:
```
Knowledge Freshness Report
==========================

VERIFIED  release-package      (last verified: 2026-02-18)
STALE     add-feature           watched_paths changed:
                                 - .claude/commands/feature.workflow.md (2026-02-19)
UNKNOWN   debug-drift           (no watched_paths defined)

Summary: 1 verified, 1 stale, 1 unknown
```

**Exit codes**:
- 0 — all guides verified or unknown
- 1 — one or more guides stale

---

### `help`

**Purpose**: Display available commands.

**Input**: None

**Output**: Help text listing all commands with descriptions.

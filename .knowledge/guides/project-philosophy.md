---
id: project-philosophy
title: "kai philosophy — vision, dogmas, and design principles"
created: "2026-02-18"
last_verified: "2026-02-18T09:31:59Z"
references:
  conventions:
    - "conv-001-esm-zero-deps"
    - "conv-002-cli-entry-structure"
    - "conv-003-file-based-artifacts"
    - "conv-004-submodule-packages"
    - "conv-005-claude-commands"
    - "conv-006-trusted-publishing"
  adrs:
    - ".adr/global/20260218-esm-only-zero-deps.md"
    - ".adr/global/20260218-file-based-artifact-tracking.md"
    - ".adr/global/20260218-git-submodule-monorepo.md"
    - ".adr/global/20260218-claude-code-as-primary-ai-interface.md"
    - ".adr/global/20260218-use-adr-system.md"
  features: []
watched_paths:
  - ".gitmodules"
  - "package.json"
  - ".agreements/config.yaml"
  - ".features/config.yaml"
  - ".knowledge/config.yaml"
topics:
  - "philosophy"
  - "vision"
  - "dogma"
  - "principles"
  - "architecture"
  - "agreements"
  - "drift"
  - "portability"
  - "governance"
---

## Vision

kai is a project governance system that lives entirely inside the repository. No external service, no database, no dashboard. Everything — decisions, conventions, feature lifecycle, documentation freshness, agreements between product and code — is plain text under version control. The goal: any code project can adopt kai with a single `npx tcsetup` and immediately gain a self-governing, self-healing project management layer that travels with the code.

## The Five Dogmas

### 1. Git is the database

All state lives in files. Files live in git. There is no other persistence layer.

Git serves as query engine (`glob` + `grep`), audit trail (`git log`), temporal oracle (`git log -1 --format=%aI`), and freshness detector. Every state change produces a diff. Every diff is reviewable in a pull request. The entire history of decisions, conventions, feature evolution, and drift detection is `git log`. There is no separate audit trail — the repository is the audit trail.

This means a project can be cloned, forked, archived, or handed to a new team and the complete governance history comes with it.

### 2. Drift is the enemy; detection is the weapon

The system does not prevent drift — it makes drift visible immediately.

The same pattern repeats across five subsystems, each declaring what should be true and computing whether it still is:

| System | Watches | Signal | Response |
|--------|---------|--------|----------|
| Agreement check | interfaces + acceptance criteria vs. code | PASS / FAIL / BREAKING | `/agreement.doctor` generates corrective tasks |
| Feature lifecycle | artifact scan vs. last snapshot | stage regression, artifact disappeared | warning in feature.yaml |
| Health rules | computed metrics vs. thresholds | CRITICAL / WARNING / HEALTHY | suggests specific commands |
| Knowledge freshness | `watched_paths` vs. `git log` timestamps | VERIFIED / STALE | source tag in `/k` responses |
| Convention drift | `watched_paths` in convention vs. code | convention violation | `/agreement.check` for the convention |

Detection is always deterministic, always on-demand, always computed fresh at query time. No sync daemon, no background process, no webhook.

### 3. Zero dependencies is a security and portability philosophy

The rejection of npm runtime dependencies for CLI tools is not about performance. It is about eliminating the supply chain attack surface and ensuring that `npx tcsetup` works identically on any machine with Node.js 18, in any network condition, for any project, forever.

Every import uses the `node:` protocol (`import { readFileSync } from "node:fs"`) to prevent name-squatting attacks. YAML is parsed with regex, not a library. The cost is acknowledged (fragile manual parsing) and accepted as a deliberate trade for supply chain integrity.

### 4. The interface is prose

Claude Code slash commands (`.claude/commands/*.md`) are the user interface. The "source code" of the UI is Markdown prompt templates. No build step, no deploy step, no runtime, no state. Commands compose via handoffs: a check hands off to a doctor, a doctor to implement, implement back to check.

A user without Claude Code can still operate the system — every artifact is plain YAML and Markdown, editable by hand. The AI accelerates; it does not gate.

### 5. Convention before code

The `agreement-first` breaking change policy means the declaration of intent precedes the implementation of behavior. Code is the last thing that changes, not the first.

Feature stages are computed from artifacts, not declared. If `spec.md` does not exist, the feature cannot be in the `spec` stage — the system cannot lie. The only stage requiring human intervention is `release`. Everything else is derivable from the filesystem.

## The Agreement System — the Spine

The central architectural insight: when product (BMAD) produces artifacts and implementation (SpecKit) produces artifacts, nothing guarantees alignment with delivered code. The PRD says one thing, the API contract says another, the code does a third. Drift is invisible until something breaks.

The Agreement is the solution. It is not a fourth artifact — it is a **convergence point**:

```
BMAD (product: intent, why)
   ↘
     Agreement (the shared promise)
   ↗
SpecKit (implementation: contracts, how)
         ↓
       Code (the delivered behavior)
```

An agreement captures:
- **Product intent** — the why, sourced from BMAD
- **User outcomes** — what the user actually gets
- **Acceptance criteria** — verifiable promises
- **Interfaces** — the contract surface (CLI, API, schema) that can drift
- **Watched paths** — the files that define the drift detection boundary
- **References** — traceability links to BMAD specs, SpecKit plans, ADRs, and source code

One YAML file connects product vision, implementation plans, source code, and architecture decisions. Load a single agreement and you understand the full lineage of a feature.

## The Repair Cycle

The system is self-healing through a deterministic repair loop:

```
/agreement.check  →  FAIL (check-report.md with structured findings)
/agreement.doctor →  corrective tasks appended to tasks.md
/speckit.implement → executes the fix tasks like any other tasks
/agreement.check  →  PASS
```

There is no special "repair mode." Repair is just task execution. The doctor reads the structured FAIL report, reads the contracts (source of truth), and writes corrective tasks. The implementation engine does not know whether it is building or repairing.

## Portability — the `npx tcsetup` Promise

Any project with Node.js >= 18 can run `npx tcsetup` and receive in one command:

| Tool | Purpose | Marker directory |
|------|---------|-----------------|
| BMAD Method | Product planning (briefs, PRDs, architecture) | `_bmad/` |
| SpecKit | Implementation specs, plans, tasks | `.specify/` + `specs/` |
| Agreement System | Convergence + drift detection | `.agreements/` |
| ADR System | Architecture decision records | `.adr/` |
| Mermaid Workbench | Diagram rendering | `.mermaid/` |
| Feature Lifecycle | Artifact-driven stage tracking | `.features/` |
| Knowledge System | Verified documentation with freshness | `.knowledge/` |

Detection is purely filesystem-based: if `.adr/` exists, ADR System is installed. No registry, no config file, no external state. The `update` command detects installed tools by marker directory and refreshes only those present.

Each tool is an independent npm package with its own git repo, its own version, and its own CI/CD pipeline. Tools do not import each other at runtime. They communicate through the filesystem — one tool writes YAML, another reads it. This makes the system infinitely composable: adopt one tool or all seven.

## The Governance Stack

Everything a project needs lives in seven dotfile directories:

```
.adr/          → architecture decisions (Markdown + YAML frontmatter)
.agreements/   → feature promises + convention enforcement (YAML)
.features/     → lifecycle state, computed from artifacts (YAML)
.knowledge/    → verified documentation with freshness tracking (YAML + Markdown)
.claude/       → AI prompt templates — the user interface (Markdown)
specs/         → implementation specs, plans, contracts (Markdown)
_bmad/         → product planning artifacts (Markdown + YAML)
```

All plain text. All version-controlled. All portable. No provisioning, no migration, no external dependency. Open the repo and run `/feature.list`, `/agreement.check`, `/k how does X work?` — complete, current, verified picture of the project.

## Design Tradeoffs (acknowledged, not hidden)

| Tradeoff | Cost | Benefit |
|----------|------|---------|
| No YAML library | Fragile regex parsing | Zero dependencies |
| No query engine | Finding artifacts requires file scanning | No database to provision or migrate |
| Claude Code dependency | No fallback UI for non-Claude users | Zero-build AI interface via Markdown |
| File-based state | No concurrent writes, no transactions | Every change is a git diff |
| Submodule isolation | `git submodule update --init` friction | Independent versioning, publishing, CI/CD |
| On-demand computation | No cached state, re-scans every time | Always fresh, never stale by construction |

Every cost is documented in the ADRs. Every ADR documents what was rejected and why. The system does not pretend tradeoffs do not exist — it makes them explicit and traceable.

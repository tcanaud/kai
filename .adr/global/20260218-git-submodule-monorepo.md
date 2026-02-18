---
status: "accepted"
date: "2026-02-18"
deciders: "Thibaud Canaud"
tags: "architecture, monorepo, packaging"
scope:
  level: "global"
  domain: ""
  applies_to: ["**"]
relations:
  supersedes: []
  amends: []
  constrained_by: []
  related:
    - "20260218-esm-only-zero-deps.md"
references:
  features:
    - "001-adr-system"
    - "002-agreement-system"
    - "003-feature-lifecycle"
    - "004-mermaid-workbench"
    - "005-tcsetup"
  agreements:
    - "conv-004-submodule-packages"
  speckit_research: []
---

# Git Submodule Monorepo for Package Isolation

## Context and Problem Statement

The kai toolchain contains 5 packages that are published independently to npm. We need a repository structure that allows unified local development while preserving independent versioning, independent CI/CD pipelines, and independent git histories per package.

## Decision Drivers

- Each package must be independently versionable and publishable to npm
- Each package needs its own GitHub Actions workflow (trusted publishing requires per-repo OIDC)
- Local development should still allow cross-package testing
- Packages must not share runtime code (they are standalone CLI tools)
- Git history per package should be clean and independent

## Considered Options

- Git submodules with npm workspaces (hybrid approach)
- Traditional npm/pnpm workspaces monorepo (single repo, shared git history)
- Fully independent repositories with no aggregation
- Nx or Turborepo managed monorepo

## Decision Outcome

Chosen option: "Git submodules with npm workspaces", because it gives the best of both worlds — each package retains its own git repo, version tags, and CI workflow while the root kai workspace provides a unified development environment via npm workspaces.

### Positive Consequences

- Each package has its own git history, tags, and GitHub repo — enabling independent npm trusted publishing
- npm workspaces in the root provide a single npm install for local development
- Contributors can clone just one submodule if they only care about one package
- No build orchestration tool needed (no Nx, Turborepo, or Lerna)
- The root repo serves as a composition layer, not a build layer

### Negative Consequences

- Git submodules add operational complexity (submodule update, detached HEAD states)
- Contributors must learn git submodule workflows (init, update, push within submodule)
- Submodule pinning can fall behind — requires explicit "update submodules" commits in the root
- No shared code between packages (by design, but limits reuse)
- CI in the root repo does not automatically test submodule changes

## Links

- Convention: [conv-004-submodule-packages](../../.agreements/conv-004-submodule-packages/agreement.yaml)
- [Git submodules documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [npm workspaces](https://docs.npmjs.com/cli/using-npm/workspaces)

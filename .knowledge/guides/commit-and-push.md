---
id: commit-and-push
title: "How to commit and push in the kai monorepo"
created: "2026-02-18"
last_verified: "2026-02-18T09:31:59Z"
references:
  conventions:
    - "conv-004-submodule-packages"
    - "conv-006-trusted-publishing"
  adrs:
    - ".adr/global/20260218-git-submodule-monorepo.md"
  features: []
watched_paths:
  - ".gitmodules"
  - "package.json"
  - ".agreements/conv-004-submodule-packages/agreement.yaml"
  - ".agreements/conv-006-trusted-publishing/agreement.yaml"
topics:
  - "commit"
  - "push"
  - "git"
  - "submodule"
  - "tag"
  - "publish"
  - "version bump"
  - "ci/cd"
  - "workflow"
---

## Overview

The kai repo is a git-submodule monorepo: the parent repo tracks pointers to independent package repos under `packages/`. Every change to a package follows a strict inside-out order — commit the submodule first, push it, tag it, then update the parent pointer. Getting this order wrong breaks CI/CD publishing or leaves the parent pointing at an untagged commit.

## The Golden Rule

**Always work inside-out: submodule first, parent second.**

The parent repo never contains source code. It only tracks submodule pointers, root-level config (`.knowledge/`, `.agreements/`, `.features/`, `CLAUDE.md`), and `package.json`.

## Workflow A — Changing an existing package

### 1. Commit inside the submodule

```bash
cd packages/my-tool
# make your changes, then:
git add src/changed-file.js
git commit -m "fix: description of the change"
```

### 2. Bump the version

Edit `package.json` inside the submodule. Use semver:
- **patch** (1.0.0 → 1.0.1): bug fixes
- **minor** (1.0.1 → 1.1.0): new features, backwards-compatible
- **major** (1.1.0 → 2.0.0): breaking changes

The bump can be in the same commit as the change or in a dedicated commit:

```bash
# Option A: bump included in the feature commit (preferred for single changes)
git add -A && git commit -m "feat: add foobar — my-tool v1.2.0"

# Option B: separate bump commit (when multiple commits accumulated)
git add package.json && git commit -m "chore: bump version to 1.2.0"
```

### 3. Push the submodule

```bash
git push origin main
```

### 4. Tag and push the tag (triggers npm publish)

```bash
git tag v1.2.0
git push origin v1.2.0
```

This triggers `.github/workflows/publish.yml` via GitHub Actions trusted publishing. No npm token needed — OIDC handles auth.

### 5. Update the parent pointer

```bash
cd /path/to/kai
git add packages/my-tool
git commit -m "update my-tool submodule — v1.2.0 with description"
git push
```

## Workflow B — Changing multiple packages

When a change spans multiple packages (e.g. adding a feature to package A and integrating it in tcsetup):

```bash
# 1. Commit + push + tag package A
cd packages/package-a
git add -A && git commit -m "feat: new capability — package-a v1.3.0"
git push origin main && git tag v1.3.0 && git push origin v1.3.0

# 2. Commit + push + tag package B (e.g. tcsetup)
cd ../tcsetup
git add -A && git commit -m "feat: integrate package-a — tcsetup v1.5.0"
git push origin main && git tag v1.5.0 && git push origin v1.5.0

# 3. Update BOTH pointers in parent — single commit
cd /path/to/kai
git add packages/package-a packages/tcsetup
git commit -m "update submodules — package-a v1.3.0 + tcsetup v1.5.0"
git push
```

## Workflow C — Parent-only changes

Changes to root-level files (`.knowledge/`, `.agreements/`, `.features/`, `CLAUDE.md`, `package.json`) don't involve submodules:

```bash
git add .knowledge/guides/new-guide.md .knowledge/index.yaml
git commit -m "add new-guide knowledge guide"
git push
```

## Commit Message Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Feature (submodule) | `feat: description — pkg v1.X.0` | `feat: add onboard command — tcsetup v1.1.0` |
| Bugfix (submodule) | `fix: description` | `fix: strip quotes from block array values` |
| Version bump | `chore: bump version to X.Y.Z` | `chore: bump version to 1.0.1` |
| Submodule pointer (single) | `update <pkg> submodule — vX.Y.Z with description` | `update tcsetup submodule — v1.4.0 with knowledge-system support` |
| Submodule pointer (multi) | `update submodules — description` | `update submodules — v1.0.3 with repository.url fix` |
| Parent-only | Standard conventional commits | `add create-new-package knowledge guide` |

## CI/CD Publishing

Every submodule has an identical `.github/workflows/publish.yml`:
- **Trigger**: push of a `v*` tag
- **Auth**: GitHub OIDC trusted publishing (`id-token: write`, `NODE_AUTH_TOKEN: ""`)
- **Command**: `npm publish --provenance --access public`
- **Prerequisite**: trusted publishing configured on npmjs.com for the repo + workflow

**No npm token, no secrets.** If publish fails with auth errors, check that trusted publishing is configured on npmjs.com (Package Settings > Publishing).

## Key Invariants

1. **Tag before parent pointer** — the submodule tag is pushed first, then the parent pointer is updated
2. **Parent pointer tracks the tagged commit** — never point at a pre-tag or work-in-progress SHA
3. **Version lives in the submodule** — the parent repo never records version numbers in code
4. **One tag = one publish** — each `v*` tag push triggers exactly one npm publish

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Forgot to push submodule before parent | Parent points at a SHA that doesn't exist on remote | `cd packages/x && git push origin main` |
| Tagged wrong commit | npm publishes stale code | Delete tag, re-tag correct commit: `git tag -d v1.0.1 && git push origin :refs/tags/v1.0.1 && git tag v1.0.1 && git push origin v1.0.1` |
| Updated parent without tagging | Package version bumped but never published | `cd packages/x && git tag vX.Y.Z && git push origin vX.Y.Z` |
| Committed in parent before submodule | `git status` shows `modified: packages/x (new commits)` but submodule has uncommitted work | `cd packages/x && git add -A && git commit` first |
| `npm install` after submodule change | `package-lock.json` out of sync | Run `npm install` in root kai repo, commit the lockfile |
| Force-pushed a submodule | Parent pointer becomes dangling | Never force-push submodules; if needed, update parent pointer to new HEAD |

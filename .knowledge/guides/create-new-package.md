---
id: create-new-package
title: "How to create a new kai package"
created: "2026-02-18"
last_verified: "2026-02-18T05:34:16Z"
references:
  conventions:
    - "conv-001-esm-zero-deps"
    - "conv-002-cli-entry-structure"
    - "conv-004-submodule-packages"
    - "conv-005-claude-commands"
    - "conv-006-trusted-publishing"
  adrs:
    - ".adr/global/20260218-esm-only-zero-deps.md"
    - ".adr/global/20260218-git-submodule-monorepo.md"
    - ".adr/global/20260218-claude-code-as-primary-ai-interface.md"
  features: []
watched_paths:
  - ".gitmodules"
  - "package.json"
  - ".agreements/conv-001-esm-zero-deps/agreement.yaml"
  - ".agreements/conv-002-cli-entry-structure/agreement.yaml"
  - ".agreements/conv-004-submodule-packages/agreement.yaml"
topics:
  - "package"
  - "new package"
  - "scaffold"
  - "submodule"
  - "npm publish"
  - "tcsetup"
  - "ci/cd"
  - "trusted publishing"
---

## Overview

Every kai package follows an identical structure: independent git repo, git submodule in `packages/`, ESM-only with zero runtime dependencies, switch/case CLI router, and CI/CD via GitHub Actions trusted publishing. This guide covers the complete process from creation to publishing.

## Steps

### 1. Create the GitHub repo

```bash
gh repo create tcanaud/my-tool-name --public --description "Short description"
```

### 2. Initialize locally in kai

```bash
cd packages/
mkdir my-tool-name && cd my-tool-name
git init && git branch -m main
mkdir -p bin src templates/commands templates/core .github/workflows
```

### 3. Create package.json

```json
{
  "name": "my-tool-name",
  "version": "1.0.0",
  "type": "module",
  "description": "One-sentence description.",
  "bin": { "my-tool-name": "./bin/cli.js" },
  "engines": { "node": ">=18.0.0" },
  "files": ["bin/", "src/", "templates/"],
  "keywords": ["kai", "claude-code"],
  "author": "Thibaud Canaud",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/tcanaud/my-tool-name.git"
  }
}
```

**No `dependencies` field.** If npm rejects the name, use `@tcanaud/my-tool-name` as the `name` but keep the short name as the `bin` key.

### 4. Create bin/cli.js

```js
#!/usr/bin/env node
import { argv, exit } from "node:process";

const command = argv[2];
const flags = argv.slice(3);

const HELP = `
my-tool-name — Short description.

Usage:
  npx my-tool-name init      Do something
  npx my-tool-name update    Update commands and templates
  npx my-tool-name help      Show this help message

Options (init):
  --yes             Skip confirmation prompts
`;

switch (command) {
  case "init": {
    const { install } = await import("../src/installer.js");
    install(flags);
    break;
  }
  case "update": {
    const { update } = await import("../src/updater.js");
    update(flags);
    break;
  }
  case "help":
  case "--help":
  case "-h":
  case undefined:
    console.log(HELP);
    break;
  default:
    console.error(`Unknown command: ${command}`);
    console.log(HELP);
    exit(1);
}
```

**Set executable immediately**: `chmod +x bin/cli.js`

### 5. Create standard src/ modules

| File | Export | Purpose |
|------|--------|---------|
| `installer.js` | `install(flags)` | Full init: detect env, create dirs, copy templates, install commands |
| `updater.js` | `update(flags)` | Refresh commands/templates only, never touch user data |
| `detect.js` | `detect(projectRoot)` | Return `{ hasBmad, bmadDir, hasSpeckit, hasAgreements, ... }` |
| `config.js` | `readConfig()`, `generateConfig()` | Read/write config YAML via regex (no YAML lib) |

All imports must use `node:` protocol. All exports must be named (no default exports).

The `__dirname` boilerplate for referencing templates:
```js
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
const __dirname = dirname(fileURLToPath(import.meta.url));
```

### 6. Create templates/

- `templates/core/` — config.yaml, index.yaml, any scaffolded files
- `templates/commands/` — Claude Code `.md` command files

### 7. Create .github/workflows/publish.yml

```yaml
name: Publish to npm

on:
  push:
    tags:
      - "v*"

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: lts/*
      - run: npm publish --provenance --access public
        env:
          NODE_AUTH_TOKEN: ""
```

Copy this **verbatim** — no `registry-url`, explicit empty `NODE_AUTH_TOKEN`.

### 8. Initial commit, push, and publish

```bash
git add -A
git commit -m "feat: my-tool-name v1.0.0"
git remote add origin https://github.com/tcanaud/my-tool-name.git
git push -u origin main
git tag v1.0.0
git push origin v1.0.0
```

Then configure trusted publishing on npmjs.com: Package Settings > Publishing > add `tcanaud/my-tool-name` workflow `publish.yml`.

### 9. Register as submodule in kai

```bash
cd /path/to/kai
git submodule add https://github.com/tcanaud/my-tool-name.git packages/my-tool-name
```

Add to root `package.json` dependencies:
```json
"my-tool-name": "^1.0.0"
```

Run `npm install` to update lock file.

### 10. Add to tcsetup

**installer.js** — add to `steps` array:
```js
{ name: "My Tool", flag: "--skip-mytool", cmd: "npx my-tool-name init --yes" }
```

**updater.js** — add to `TOOLS` array:
```js
{ name: "My Tool", marker: ".mytool", pkg: "my-tool-name", cmd: "npx my-tool-name update" }
```

**bin/cli.js** — add `--skip-mytool` to HELP text.

Bump tcsetup version, commit, tag, push.

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Missing `chmod +x` on cli.js | "Permission denied" on npx | `chmod +x bin/cli.js && git update-index --chmod=+x bin/cli.js` |
| npm name conflict | E403 "too similar to existing package" | Use `@tcanaud/name` scope, update all `npx` references |
| `registry-url` in workflow | Publish auth fails despite OIDC | Remove `registry-url`, set `NODE_AUTH_TOKEN: ""` |
| Missing `repository.url` | Provenance attestation unverifiable | Add `repository` field to package.json |
| Barrel file re-exports | `ReferenceError: X is not defined` in same file | Use explicit `import` then `export { X }`, not `export { X } from "./x.js"` if you reference X locally |
| Forgot to commit submodule in parent | Package exists locally but not tracked by kai | `git add .gitmodules packages/name && git commit` |
| BMAD integration overwrites | Second tool erases first tool's customization | Append-safely: check if already present, then `appendFileSync` |

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| npm package | `kebab-case` (scope if needed) | `adr-system`, `@tcanaud/knowledge-system` |
| GitHub repo | `tcanaud/<npm-name>` | `tcanaud/adr-system` |
| bin entry key | Same as package name | `"adr-system": "./bin/cli.js"` |
| src/ files | `kebab-case.js` | `installer.js`, `detect.js` |
| Export names | camelCase | `install`, `update`, `scanAll` |
| Claude commands | `dot.notation.md` | `knowledge.check.md` |
| Installed dotdir | `.toolname/` | `.adr/`, `.knowledge/` |
| tcsetup flag | `--skip-<short>` | `--skip-knowledge` |

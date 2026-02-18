---
status: "accepted"
date: "2026-02-18"
deciders: "Thibaud Canaud"
tags: "runtime, dependencies, modules"
scope:
  level: "global"
  domain: ""
  applies_to: ["**"]
relations:
  supersedes: []
  amends: []
  constrained_by: []
  related:
    - "20260218-git-submodule-monorepo.md"
references:
  features:
    - "001-adr-system"
    - "002-agreement-system"
    - "003-feature-lifecycle"
    - "004-mermaid-workbench"
    - "005-tcsetup"
  agreements:
    - "conv-001-esm-zero-deps"
  speckit_research: []
---

# ESM-Only Modules with Zero Runtime Dependencies

## Context and Problem Statement

The kai toolchain consists of CLI packages that users install via npx. Each invocation downloads the package, runs it, and exits. We need to decide on the module system and dependency strategy. Heavy dependency trees slow down npx cold starts, increase supply-chain attack surface, and create version conflicts across the ecosystem.

## Decision Drivers

- npx cold-start time must be near-instant (no dependency tree to resolve)
- Supply-chain security: fewer dependencies = fewer attack vectors
- Node.js >= 18 provides a mature standard library (fs, path, url, readline, child_process)
- ESM is the forward-looking module system for Node.js
- The node: protocol makes built-in imports unambiguous and prevents name-squatting

## Considered Options

- ESM-only with zero runtime dependencies (stdlib only)
- ESM with minimal curated dependencies (e.g., chalk, commander, yaml)
- CommonJS with zero dependencies
- TypeScript source with build step

## Decision Outcome

Chosen option: "ESM-only with zero runtime dependencies", because it eliminates the entire dependency supply chain for CLI tools while leveraging Node.js 18+ built-in capabilities. The one exception is mermaid-workbench, which ships a browser-based viewer and legitimately requires Preact, Vite, and Mermaid as dependencies.

### Positive Consequences

- npx cold starts are fast — only the package itself is downloaded, no dependency tree
- Zero transitive dependency vulnerabilities for CLI-only packages
- The node: protocol prevents confusion between built-in and npm modules
- ESM enables top-level await and aligns with the platform's direction
- No build step required — source files are the shipped files

### Negative Consequences

- Some convenience libraries (chalk for colors, commander for arg parsing) must be reimplemented or forgone
- Manual YAML parsing is fragile without a library (feature-lifecycle works around this with regex-based parsing)
- New contributors familiar with rich npm ecosystems may find the stdlib-only constraint surprising
- mermaid-workbench is an explicit exception, which adds a rule to remember

## Links

- Convention: [conv-001-esm-zero-deps](../../.agreements/conv-001-esm-zero-deps/agreement.yaml)
- [Node.js ESM documentation](https://nodejs.org/api/esm.html)
- [node: protocol](https://nodejs.org/api/esm.html#node-imports)

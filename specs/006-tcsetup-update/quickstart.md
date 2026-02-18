# Quickstart: tcsetup update command

**Feature**: 006-tcsetup-update | **Date**: 2026-02-18

## What This Feature Does

Adds an `npx tcsetup update` command that updates all installed TC stack tools in a single command, refreshing packages, commands, and templates while preserving user data.

## How to Use It

### Update all installed tools

```bash
npx tcsetup update
```

This will:
1. Detect which TC tools are installed (by checking marker directories)
2. Update their npm packages to the latest versions
3. Run each tool's update command to refresh commands/templates
4. Refresh tcsetup's own command files in `.claude/commands/`

### Onboard a new project (unchanged)

```bash
npx tcsetup
# or explicitly:
npx tcsetup init
```

### See available commands

```bash
npx tcsetup help
```

## What Gets Updated (and What Doesn't)

**Updated** (safe to refresh):
- npm package versions for installed TC tools
- Claude Code command files (`.claude/commands/`)
- Tool templates (e.g., ADR templates, agreement templates)

**Never touched** (user data preserved):
- Existing ADRs in `.adr/`
- Existing agreements in `.agreements/`
- Feature YAML files in `.features/`
- Index files, configurations, and user-created content

## Development Setup

All changes are in `packages/tcsetup/`:

```bash
# Files to modify/create:
packages/tcsetup/bin/cli.js        # Refactor: add command routing
packages/tcsetup/src/installer.js  # New: extracted init logic
packages/tcsetup/src/updater.js    # New: update orchestration
packages/tcsetup/package.json      # Update: add "src/" to files
```

### Testing locally

```bash
# From a test project directory:
node /path/to/kai/packages/tcsetup/bin/cli.js update

# Or after npm link:
cd packages/tcsetup && npm link
cd /path/to/test-project && tcsetup update
```

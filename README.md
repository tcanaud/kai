# kai

**Project governance that lives inside your repo.**

kai is a collection of tools that give any code project self-governing superpowers — architecture decisions, feature tracking, verified documentation, product feedback, and drift detection — all as plain text files under version control.

No database. No dashboard. No external service. Clone the repo and everything comes with it.

## One Command Setup

```bash
npx tcsetup
```

That's it. Your project now has 8 governance modules, ready to use through Claude Code slash commands.

## What You Get

| Module | What it does | Talk to it |
|--------|-------------|------------|
| **BMAD Method** | Product briefs, PRDs, architecture docs | `/bmad-help` |
| **Spec Kit** | Specs, implementation plans, task breakdowns | `/speckit.specify`, `/speckit.plan` |
| **Agreement System** | Keeps code aligned with product promises | `/agreement.check` |
| **ADR System** | Track architecture decisions and their impact | `/adr.create`, `/adr.list` |
| **Feature Lifecycle** | Follow a feature from idea to release | `/feature.workflow`, `/feature.list` |
| **Knowledge System** | Verified docs with freshness tracking | `/k how does X work?` |
| **Product Manager** | Feedback intake, AI triage, backlog to feature | `/product.intake`, `/product.triage` |
| **Mermaid Workbench** | Generate and maintain diagrams | via BMAD tasks |

## The Idea

A project makes hundreds of decisions over its lifetime. Where do they live? In Slack threads, meeting notes, someone's head. When that person leaves or the Slack channel is archived, the knowledge is gone.

kai keeps all of it inside the repo:

- **Decisions** are ADR files that explain what was chosen, what was rejected, and why
- **Promises** are Agreements that link product intent to code and detect when they drift apart
- **Features** are tracked from first idea to release, with artifacts as proof of progress
- **Documentation** is verified against the code it describes — stale docs get flagged automatically
- **Feedback** flows from raw user complaints to triaged backlogs to shipped features, with full traceability

Everything is Markdown and YAML. Everything is diffable. Everything travels with the code.

## How It Looks

```
your-project/
├── .adr/              Architecture decisions
├── .agreements/       Feature promises + drift detection
├── .features/         Lifecycle tracking
├── .knowledge/        Verified documentation
├── .product/          Feedback & backlogs
├── .claude/commands/  AI-powered slash commands
├── specs/             Implementation specs & plans
└── _bmad/             Product planning (briefs, PRDs)
```

## A Taste of the Workflow

```
# You have a feature idea
/feature.workflow my-new-feature

# It tells you what to do next, step by step:
#   Brief → PRD → Spec → Plan → Tasks → Agreement → Code → Release

# Capture user feedback
/product.intake "search is too slow on large repos"

# AI triages it into backlog items
/product.triage

# Promote to a full feature when ready
/product.promote BL-001

# Check if code still matches what was promised
/agreement.check 009-search-performance

# Ask the knowledge base anything
/k how does the authentication flow work?
```

## Five Principles

1. **Git is the database** — All state is files. All files are in git. `git log` is the audit trail.
2. **Drift is the enemy** — The system doesn't prevent drift, it makes it visible immediately.
3. **Zero dependencies** — Every module runs on Node.js built-ins only. No supply chain risk.
4. **The interface is prose** — Claude Code slash commands are Markdown files. No build step.
5. **Convention before code** — Declare intent first, implement second.

## Selective Adoption

Don't need everything? Each module works independently:

```bash
npx tcsetup --skip-bmad --skip-mermaid --skip-product
```

Or install just one:

```bash
npx adr-system init
npx @tcanaud/product-manager init
npx @tcanaud/knowledge-system init
```

If `.adr/` exists, the ADR system is installed. If `.product/` exists, Product Manager is installed. Detection is purely filesystem-based — no registry, no config.

## Modules

| Package | npm | Repository |
|---------|-----|------------|
| tcsetup | [`tcsetup`](https://www.npmjs.com/package/tcsetup) | [tcanaud/tcsetup](https://github.com/tcanaud/tcsetup) |
| adr-system | [`adr-system`](https://www.npmjs.com/package/adr-system) | [tcanaud/adr-system](https://github.com/tcanaud/adr-system) |
| agreement-system | [`agreement-system`](https://www.npmjs.com/package/agreement-system) | [tcanaud/agreement-system](https://github.com/tcanaud/agreement-system) |
| feature-lifecycle | [`feature-lifecycle`](https://www.npmjs.com/package/feature-lifecycle) | [tcanaud/feature-lifecycle](https://github.com/tcanaud/feature-lifecycle) |
| knowledge-system | [`@tcanaud/knowledge-system`](https://www.npmjs.com/package/@tcanaud/knowledge-system) | [tcanaud/knowledge-system](https://github.com/tcanaud/knowledge-system) |
| product-manager | [`@tcanaud/product-manager`](https://www.npmjs.com/package/@tcanaud/product-manager) | [tcanaud/product-manager](https://github.com/tcanaud/product-manager) |
| mermaid-workbench | [`mermaid-workbench`](https://www.npmjs.com/package/mermaid-workbench) | [tcanaud/mermaid-workbench](https://github.com/tcanaud/mermaid-workbench) |

## Requirements

- Node.js >= 18.0.0
- Git
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (for slash commands)

Without Claude Code, everything still works — artifacts are plain Markdown and YAML, editable by hand. The AI accelerates; it doesn't gate.

## License

MIT

#!/usr/bin/env node

import { argv, exit } from "node:process";

const command = argv[2];
const args = argv.slice(3);

// Global error handler for unhandled rejections from async commands
process.on("unhandledRejection", (reason) => {
  console.error(`Error: ${reason?.message || reason}`);
  process.exitCode = 1;
  exit(1);
});

const HELP = `kai-product — Atomic CLI for kai product operations.

Usage:
  npx @tcanaud/kai-product init       Scaffold .product/ directory and install slash commands
  npx @tcanaud/kai-product update     Refresh slash commands
  npx @tcanaud/kai-product reindex    Regenerate index.yaml from filesystem scan
  npx @tcanaud/kai-product move       Move backlog item(s) to a new status
  npx @tcanaud/kai-product check      Check product directory integrity
  npx @tcanaud/kai-product promote    Promote a backlog item to a feature
  npx @tcanaud/kai-product triage     Triage new feedbacks
  npx @tcanaud/kai-product help       Show this help`;

switch (command) {
  case "reindex": {
    const { reindex } = await import("../src/commands/reindex.js");
    await reindex({ productDir: process.env.KAI_PRODUCT_DIR });
    break;
  }
  case "move": {
    const { move } = await import("../src/commands/move.js");
    await move(args, { productDir: process.env.KAI_PRODUCT_DIR });
    break;
  }
  case "check": {
    const jsonFlag = args.includes("--json");
    const { check } = await import("../src/commands/check.js");
    const result = await check({ productDir: process.env.KAI_PRODUCT_DIR, json: jsonFlag });
    if (result && !result.ok) process.exitCode = 1;
    break;
  }
  case "promote": {
    const { promote } = await import("../src/commands/promote.js");
    await promote(args, { productDir: process.env.KAI_PRODUCT_DIR });
    break;
  }
  case "triage": {
    const planFlag = args.includes("--plan");
    const applyIdx = args.indexOf("--apply");
    const { triagePlan, triageApply } = await import("../src/commands/triage.js");
    if (planFlag && applyIdx !== -1) {
      console.error("Error: --plan and --apply are mutually exclusive.");
      exit(1);
    } else if (planFlag) {
      await triagePlan({ productDir: process.env.KAI_PRODUCT_DIR });
    } else if (applyIdx !== -1) {
      const planFile = args[applyIdx + 1];
      if (!planFile) {
        console.error("Error: --apply requires a file path argument.");
        exit(1);
      }
      await triageApply(planFile, { productDir: process.env.KAI_PRODUCT_DIR });
    } else {
      console.error("Error: triage requires --plan or --apply <file>.");
      console.error("Usage:");
      console.error("  kai-product triage --plan              Output triage plan as JSON");
      console.error("  kai-product triage --apply <file>      Apply a triage plan");
      exit(1);
    }
    break;
  }
  case "init": {
    const yesFlag = args.includes("--yes");
    const { init } = await import("../src/installer.js");
    await init({ yes: yesFlag });
    break;
  }
  case "update": {
    const { update } = await import("../src/updater.js");
    await update();
    break;
  }
  case "help":
  case undefined: {
    console.log(HELP);
    break;
  }
  default: {
    console.error(`Unknown command: ${command}`);
    console.error(HELP);
    exit(1);
  }
}

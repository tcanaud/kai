/**
 * init command — Scaffold .product/ directory and install slash commands.
 */

import { mkdir, writeFile, copyFile, readdir, access } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createInterface } from "node:readline";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TEMPLATES_DIR = join(__dirname, "..", "templates");

const FEEDBACK_STATUSES = ["new", "triaged", "excluded", "resolved"];
const BACKLOG_STATUSES = ["open", "in-progress", "done", "promoted", "cancelled"];

const EMPTY_INDEX = `product_version: "1.0"
updated: ""

feedbacks:
  total: 0
  by_status:
    new: 0
    triaged: 0
    excluded: 0
    resolved: 0
  by_category:
    critical-bug: 0
    bug: 0
    optimization: 0
    evolution: 0
    new-feature: 0
  items: []

backlogs:
  total: 0
  by_status:
    open: 0
    in-progress: 0
    done: 0
    promoted: 0
    cancelled: 0
  items: []

metrics:
  feedback_to_backlog_rate: 0.00
  backlog_to_feature_rate: 0.00
`;

/**
 * @param {{ yes?: boolean }} options
 */
export async function init(options = {}) {
  const cwd = process.cwd();
  const productDir = join(cwd, ".product");

  if (!options.yes) {
    const confirmed = await confirm("This will scaffold .product/ and install slash commands. Continue? (y/N) ");
    if (!confirmed) {
      console.log("Aborted.");
      return;
    }
  }

  // Create directory structure
  console.log("Scaffolding .product/ directory...");

  for (const status of FEEDBACK_STATUSES) {
    const dir = join(productDir, "feedbacks", status);
    await mkdir(dir, { recursive: true });
    console.log(`  Created feedbacks/${status}/`);
  }

  for (const status of BACKLOG_STATUSES) {
    const dir = join(productDir, "backlogs", status);
    await mkdir(dir, { recursive: true });
    console.log(`  Created backlogs/${status}/`);
  }

  // Write initial index.yaml if it doesn't exist
  const indexPath = join(productDir, "index.yaml");
  try {
    await access(indexPath);
    console.log("  index.yaml already exists, skipping.");
  } catch {
    await writeFile(indexPath, EMPTY_INDEX, "utf-8");
    console.log("  Created index.yaml");
  }

  // Install slash command templates
  console.log("\nInstalling slash commands...");
  const commandsDir = join(cwd, ".claude", "commands");
  await mkdir(commandsDir, { recursive: true });

  try {
    const templates = await readdir(TEMPLATES_DIR);
    for (const template of templates) {
      if (!template.endsWith(".md")) continue;
      const src = join(TEMPLATES_DIR, template);
      const dest = join(commandsDir, template);
      await copyFile(src, dest);
      console.log(`  Installed ${template}`);
    }
  } catch (err) {
    console.error(`  Warning: Could not read templates: ${err.message}`);
  }

  console.log("\nDone! Run `kai-product help` for available commands.");
}

/**
 * Simple yes/no prompt.
 */
async function confirm(question) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === "y" || answer.toLowerCase() === "yes");
    });
  });
}

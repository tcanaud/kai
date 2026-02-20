/**
 * update command — Refresh slash commands without modifying .product/ data.
 */

import { mkdir, copyFile, readdir } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TEMPLATES_DIR = join(__dirname, "..", "templates");

export async function update() {
  const cwd = process.cwd();
  const commandsDir = join(cwd, ".claude", "commands");
  await mkdir(commandsDir, { recursive: true });

  console.log("Refreshing slash commands...");

  try {
    const templates = await readdir(TEMPLATES_DIR);
    for (const template of templates) {
      if (!template.endsWith(".md")) continue;
      const src = join(TEMPLATES_DIR, template);
      const dest = join(commandsDir, template);
      await copyFile(src, dest);
      console.log(`  Updated ${template}`);
    }
  } catch (err) {
    console.error(`Error: Could not read templates: ${err.message}`);
    process.exit(1);
  }

  console.log("\nSlash commands updated.");
}

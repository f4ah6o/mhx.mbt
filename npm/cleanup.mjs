import { rmSync, existsSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const distDir = join(root, "dist");

const filesToRemove = ["index.mjs", "index.js", "mhx_ffi.js"];

for (const file of filesToRemove) {
  const filePath = join(distDir, file);
  if (existsSync(filePath)) {
    rmSync(filePath);
    console.log(`Removed: ${file}`);
  }
}

console.log("Cleanup complete.");

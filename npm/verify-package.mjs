import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  lstatSync,
  readFileSync,
  readlinkSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const readmePath = join(root, "README.md");
const npmReadmePath = join(root, "README.npm.md");
const npmReadme = readFileSync(npmReadmePath, "utf8");

let restoreKind = "none";
let restoreValue = null;
if (existsSync(readmePath)) {
  const stat = lstatSync(readmePath);
  if (stat.isSymbolicLink()) {
    restoreKind = "symlink";
    restoreValue = readlinkSync(readmePath);
  } else {
    restoreKind = "file";
    restoreValue = readFileSync(readmePath, "utf8");
  }
  rmSync(readmePath);
}
writeFileSync(readmePath, npmReadme);

try {
  const output = execFileSync("npm", ["pack", "--dry-run", "--json"], {
    cwd: root,
    encoding: "utf8",
  });
  const pack = JSON.parse(output)[0];
  const files = pack.files.map((entry) => entry.path).sort();
  const expected = [
    "LICENSE",
    "README.mbt.md",
    "README.md",
    "README.npm.md",
    "dist/mhx.esm.js",
    "dist/mhx.umd.js",
    "package.json",
  ].sort();
  assert.deepEqual(files, expected, `unexpected published files: ${files.join(", ")}`);
  console.log(`Package file contract OK: ${files.join(", ")}`);
} finally {
  rmSync(readmePath);
  if (restoreKind === "symlink") {
    symlinkSync(restoreValue, readmePath);
  } else if (restoreKind === "file") {
    writeFileSync(readmePath, restoreValue);
  }
}

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const moonMod = JSON.parse(readFileSync(join(root, "moon.mod.json"), "utf8"));
const moonVersion = String(moonMod.version ?? "");

const files = [
  ["src/lib.mbt", /pub let version : String = "([^"]+)"/],
  ["src/lib_test.mbt", /inspect\(@mhx\.version, content="([^"]+)"\)/],
  ["src/API.mbt.md", /inspect\(@mhx\.version, content="([^"]+)"\)/],
];

for (const [file, regex] of files) {
  const text = readFileSync(join(root, file), "utf8");
  const match = text.match(regex);
  assert.ok(match, `expected version marker in ${file}`);
  assert.equal(
    match[1],
    moonVersion,
    `${file} must match moon.mod.json version ${moonVersion}`,
  );
}

console.log(`MoonBit version contract OK: ${moonVersion}`);

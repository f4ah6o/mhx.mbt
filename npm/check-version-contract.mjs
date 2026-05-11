import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const moonMod = JSON.parse(readFileSync(join(root, "moon.mod.json"), "utf8"));
const moonVersion = String(moonMod.version ?? "");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const npmVersion = String(packageJson.version ?? "");

const moonVersionFiles = [
  ["src/lib.mbt", /pub let version : String = "([^"]+)"/],
  ["src/lib_test.mbt", /inspect\(@mhx\.version, content="([^"]+)"\)/],
  ["src/API.mbt.md", /inspect\(@mhx\.version, content="([^"]+)"\)/],
  ["README.md", /"f4ah6o\/mhx": "([^"]+)"/],
  ["README.mbt.md", /"f4ah6o\/mhx": "([^"]+)"/],
];

for (const [file, regex] of moonVersionFiles) {
  const text = readFileSync(join(root, file), "utf8");
  const match = text.match(regex);
  assert.ok(match, `expected version marker in ${file}`);
  assert.equal(
    match[1],
    moonVersion,
    `${file} must match moon.mod.json version ${moonVersion}`,
  );
}

const npmVersionFiles = [
  ["README.npm.md", /mhx@([0-9][0-9A-Za-z._-]*)/g],
];

for (const [file, regex] of npmVersionFiles) {
  const text = readFileSync(join(root, file), "utf8");
  const matches = [...text.matchAll(regex)].map((match) => match[1]);
  assert.ok(matches.length > 0, `expected npm version marker in ${file}`);
  for (const value of matches) {
    assert.equal(
      value,
      npmVersion,
      `${file} npm URL examples must match package.json version ${npmVersion}`,
    );
  }
}

const readmeNpm = readFileSync(join(root, "README.npm.md"), "utf8");
assert.match(
  readmeNpm,
  /MoonBit package version: `moon\.mod\.json` \/ `@mhx\.version`/,
  "README.npm.md must name the MoonBit version domain",
);
assert.match(
  readmeNpm,
  /npm runtime version: `package\.json\.version` \/ JS `version` export/,
  "README.npm.md must name the npm runtime version domain",
);

const versioningDoc = readFileSync(join(root, "docs/versioning.md"), "utf8");
for (const required of [
  "## MoonBit package version",
  "## npm/runtime version",
  "## Release checklist",
  "pnpm verify:versions",
]) {
  assert.ok(
    versioningDoc.includes(required),
    `docs/versioning.md must include ${required}`,
  );
}

console.log(
  `Version contract OK: MoonBit ${moonVersion}, npm runtime ${npmVersion}`,
);

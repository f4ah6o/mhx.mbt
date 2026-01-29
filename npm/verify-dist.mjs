import { readFileSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const distIndex = join(root, "dist", "index.mjs");

const content = readFileSync(distIndex, "utf8");

const mustInclude = [
  "mhx_ffi.initMhxFfi",
  "export const init_mhx",
  "export { process, handle_event, get_instance }",
];

for (const needle of mustInclude) {
  if (!content.includes(needle)) {
    throw new Error(`dist/index.mjs missing: ${needle}`);
  }
}

const mustNotInclude = [
  "run_async_main((_cont",
];

for (const needle of mustNotInclude) {
  if (content.includes(needle)) {
    throw new Error(`dist/index.mjs should not include: ${needle}`);
  }
}

console.log("dist/index.mjs verified");

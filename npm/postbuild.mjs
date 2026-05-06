import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const distDir = join(root, "dist");
const releaseMain = join(root, "_build/js/release/build/main/main.js");
const debugMain = join(root, "_build/js/debug/build/main/main.js");
const buildMain = existsSync(releaseMain) ? releaseMain : debugMain;
const buildFfi = join(root, "src/ffi/mhx_ffi.js");

mkdirSync(distDir, { recursive: true });

const rawMainJs = readFileSync(buildMain, "utf8");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const packageVersion = String(packageJson.version ?? "0.0.0");

function mustMatch(regex, label) {
  const match = rawMainJs.match(regex);
  if (!match) {
    throw new Error(`Could not locate ${label} in compiled main.js`);
  }
  return match[1];
}

const globalMhx = mustMatch(/const (\S*core11global__mhx) = /, "global_mhx");
const coreInit = mustMatch(/function (\S*core9init__mhx)\(/, "init_mhx");
const coreHandleEvent = mustMatch(/function (\S*core13handle__event)\(/, "handle_event");
const coreProcessTree = mustMatch(/function (\S*core3Mhx13process__tree)\(/, "process_tree");
const fetchSuccess = mustMatch(/function (\S*network18on__fetch__success)\(/, "on_fetch_success");
const fetchError = mustMatch(/function (\S*network16on__fetch__error)\(/, "on_fetch_error");
const mutationObserved = mustMatch(/function (\S*core22on__mutation__observed)\(/, "on_mutation_observed");

const autorunRe = /\(\(\)\s*=>\s*\{\s*[\w$]+\(\);\s*\}\)\(\);\s*$/;
const rawMainJsNoAutorun = rawMainJs.replace(autorunRe, "");

const ffiInitBlock = `
const mhx_callbacks = {
  on_fetch_success: ${fetchSuccess},
  on_fetch_error: ${fetchError},
  on_mutation_observed: ${mutationObserved},
};
mhx_ffi.initMhxFfi(mhx_callbacks);
globalThis.mhx_callbacks = mhx_callbacks;
`;

let esmMainJs = rawMainJsNoAutorun;
const ffiHeader = 'import mhxFfi from "./mhx_ffi.js";\nconst mhx_ffi = mhxFfi;\n';
const stableExports = `
const process = (root) =>
  ${coreProcessTree}(${globalMhx}, root);
const handle_event = (event, target) =>
  ${coreHandleEvent}(event, target);
`;

if (!esmMainJs.startsWith('import mhxFfi from "./mhx_ffi.js";')) {
  esmMainJs = ffiHeader + esmMainJs;
}

const exportsBlock = `
export const init_mhx = ${coreInit};
export { process, handle_event };
export const version = ${JSON.stringify(packageVersion)};
const mhx = { init_mhx, process, handle_event, version };
export default mhx;
`;

if (!esmMainJs.includes("const process = (root) =>")) {
  esmMainJs += `\n${stableExports}`;
}
if (!esmMainJs.includes("mhx_ffi.initMhxFfi")) {
  esmMainJs += `\n${ffiInitBlock}`;
}
if (!esmMainJs.includes("export const init_mhx")) {
  esmMainJs += `\n${exportsBlock}`;
}

writeFileSync(join(distDir, "index.js"), rawMainJsNoAutorun);
writeFileSync(join(distDir, "index.mjs"), esmMainJs);
copyFileSync(buildFfi, join(distDir, "mhx_ffi.js"));

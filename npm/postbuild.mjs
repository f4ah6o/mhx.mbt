import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const distDir = join(root, "dist");
const buildMain = join(root, "_build/js/release/build/main/main.js");
const buildFfi = join(root, "src/ffi/mhx_ffi.js");

mkdirSync(distDir, { recursive: true });

const rawMainJs = readFileSync(buildMain, "utf8");
let esmMainJs = rawMainJs;
const ffiHeader =
  'import mhxFfi from "./mhx_ffi.js";\nconst mhx_ffi = mhxFfi;\n';
if (!esmMainJs.startsWith('import mhxFfi from "./mhx_ffi.js";')) {
  esmMainJs = ffiHeader + esmMainJs;
}
const exportsBlock = `
export const init_mhx = f4ah6o$mhx$core$$init_mhx;
export const process = f4ah6o$mhx$core$$process;
export const handle_event = f4ah6o$mhx$core$$handle_event;
export const get_instance = f4ah6o$mhx$core$$get_instance;
export const version = f4ah6o$mhx$$version;
export const on_fetch_success = f4ah6o$mhx$network$$on_fetch_success;
export const on_fetch_error = f4ah6o$mhx$network$$on_fetch_error;
export const on_mutation_observed = f4ah6o$mhx$core$$on_mutation_observed;
`;
if (!esmMainJs.includes("export const init_mhx")) {
  esmMainJs += `\n${exportsBlock}`;
}
writeFileSync(join(distDir, "index.js"), rawMainJs);
writeFileSync(join(distDir, "index.mjs"), esmMainJs);
copyFileSync(buildFfi, join(distDir, "mhx_ffi.js"));

import {
  copyFileSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const distDir = join(root, "dist");
const buildMain = join(root, "_build/js/release/build/main/main.js");
const buildFfi = join(root, "src/ffi/mhx_ffi.js");

mkdirSync(distDir, { recursive: true });

const rawMainJs = readFileSync(buildMain, "utf8");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const packageVersion = String(packageJson.version ?? "0.0.0");

const autorunRe =
  /\(\(\)\s*=>\s*\{\s*moonbitlang\$async\$\$run_async_main\([\s\S]*?\);\s*\}\)\(\);\s*/;
const rawMainJsNoAutorun = rawMainJs.replace(autorunRe, "");
let esmMainJs = rawMainJsNoAutorun;
const ffiHeader =
  'import mhxFfi from "./mhx_ffi.js";\nconst mhx_ffi = mhxFfi;\n';
const stableExports = `
const process = (root) =>
  f4ah6o$mhx$core$$Mhx$process_tree(f4ah6o$mhx$core$$global_mhx, root);
const handle_event = (event, target) =>
  f4ah6o$mhx$core$$Mhx$handle_event(
    f4ah6o$mhx$core$$global_mhx,
    event,
    target,
  );
const get_instance = () => f4ah6o$mhx$core$$global_mhx;
`;
if (!esmMainJs.startsWith('import mhxFfi from "./mhx_ffi.js";')) {
  esmMainJs = ffiHeader + esmMainJs;
}
const exportsBlock = `
export const init_mhx = f4ah6o$mhx$core$$init_mhx;
export { process, handle_event, get_instance };
export const version = ${JSON.stringify(packageVersion)};
export const on_fetch_success = f4ah6o$mhx$network$$on_fetch_success;
export const on_fetch_error = f4ah6o$mhx$network$$on_fetch_error;
export const on_mutation_observed = f4ah6o$mhx$core$$on_mutation_observed;
`;
const hasStableExports = esmMainJs.includes("const process = (root) =>");
if (!hasStableExports) {
  esmMainJs += `\n${stableExports}`;
}
if (!esmMainJs.includes("export const init_mhx")) {
  esmMainJs += `\n${exportsBlock}`;
}
writeFileSync(join(distDir, "index.js"), rawMainJsNoAutorun);
writeFileSync(join(distDir, "index.mjs"), esmMainJs);
copyFileSync(buildFfi, join(distDir, "mhx_ffi.js"));

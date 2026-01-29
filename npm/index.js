import * as mhx from "../dist/index.js";
import { initMhxFfi } from "../dist/mhx_ffi.js";

initMhxFfi({
  on_fetch_success: mhx.on_fetch_success,
  on_fetch_error: mhx.on_fetch_error,
  on_mutation_observed: mhx.on_mutation_observed,
});

export const init_mhx = mhx.init_mhx;
export const process = mhx.process;
export const handle_event = mhx.handle_event;
export const get_instance = mhx.get_instance;
export const version = mhx.version;
export const on_fetch_success = mhx.on_fetch_success;
export const on_fetch_error = mhx.on_fetch_error;
export const on_mutation_observed = mhx.on_mutation_observed;

export default mhx;

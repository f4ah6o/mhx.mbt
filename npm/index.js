import * as mhx from "../dist/index.js";
import { initMhxFfi } from "../dist/mhx_ffi.js";

initMhxFfi(mhx);

export const init_mhx = mhx.init_mhx;
export const process = mhx.process;
export const handle_event = mhx.handle_event;
export const get_instance = mhx.get_instance;
export const version = mhx.version;

export default mhx;

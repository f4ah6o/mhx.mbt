///|
/// FFI bindings for console logging
/// Useful for debugging

///|
/// Log a message to the console
pub fn console_log(message : String) -> Unit = "mhx_ffi" "console_log"

///|
/// Log a warning to the console
pub fn console_warn(message : String) -> Unit = "mhx_ffi" "console_warn"

///|
/// Log an error to the console
pub fn console_error(message : String) -> Unit = "mhx_ffi" "console_error"

///|
/// Log debug info to the console
pub fn console_debug(message : String) -> Unit = "mhx_ffi" "console_debug"

///|
/// Start a console timer
pub fn console_time(label : String) -> Unit = "mhx_ffi" "console_time"

///|
/// End a console timer and log elapsed time
pub fn console_time_end(label : String) -> Unit = "mhx_ffi" "console_time_end"

///|
/// Start a console group
pub fn console_group(label : String) -> Unit = "mhx_ffi" "console_group"

///|
/// Start a collapsed console group
pub fn console_group_collapsed(label : String) -> Unit = "mhx_ffi" "console_group_collapsed"

///|
/// End a console group
pub fn console_group_end() -> Unit = "mhx_ffi" "console_group_end"

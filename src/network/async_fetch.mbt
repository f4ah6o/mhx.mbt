///|
/// Async HTTP fetch operations for mhx
/// Uses callback-based async since JS promises require FFI glue

///|
/// Callback type for successful fetch response
pub(all) struct FetchCallback {
  on_success : (Response) -> Unit
}

///|
/// Callback type for fetch error
pub(all) struct FetchErrorCallback {
  on_error : (String) -> Unit
}

///|
/// Fetch result type
pub(all) enum FetchResult {
  Success(Response)
  Error(String)
  Pending
} derive(Show)

///|
/// Internal callback registry for managing async responses
struct CallbackRegistry {
  mut next_id : Int
  callbacks : Map[Int, (FetchCallback, FetchErrorCallback)]
}

///|
let callback_registry : CallbackRegistry = { next_id: 1, callbacks: {} }

///|
/// Register a callback pair and return the ID
fn register_callbacks(
  on_success : FetchCallback,
  on_error : FetchErrorCallback
) -> Int {
  let id = callback_registry.next_id
  callback_registry.next_id += 1
  callback_registry.callbacks[id] = (on_success, on_error)
  id
}

///|
/// Called from JS when fetch succeeds
pub fn on_fetch_success(callback_id : Int, response_text : String) -> Unit {
  match callback_registry.callbacks.get(callback_id) {
    Some((success_cb, _)) => {
      // Create a minimal response (in real impl, would have full JsResponse)
      // For now we'll create a placeholder
      let response = Response::from_text(response_text)
      (success_cb.on_success)(response)
      callback_registry.callbacks.remove(callback_id)
    }
    None => @ffi.console_error("Unknown callback ID: " + callback_id.to_string())
  }
}

///|
/// Called from JS when fetch fails
pub fn on_fetch_error(callback_id : Int, error_message : String) -> Unit {
  match callback_registry.callbacks.get(callback_id) {
    Some((_, error_cb)) => {
      (error_cb.on_error)(error_message)
      callback_registry.callbacks.remove(callback_id)
    }
    None => @ffi.console_error("Unknown callback ID: " + callback_id.to_string())
  }
}

///|
/// Initiate a fetch request with callbacks
pub fn fetch_async(
  url : String,
  options : RequestOptions,
  on_success : (Response) -> Unit,
  on_error : (String) -> Unit
) -> Int {
  let callback_id = register_callbacks(
    { on_success },
    { on_error },
  )
  // Create the fetch and register JS-side callbacks
  let json_options = options.to_json_string()
  // This FFI function will call on_fetch_success/on_fetch_error when done
  initiate_fetch_ffi(url, json_options, callback_id)
  callback_id
}

///|
/// FFI function to initiate fetch with callback ID
fn initiate_fetch_ffi(
  url : String,
  options_json : String,
  callback_id : Int
) -> Unit = "mhx_ffi" "initiate_fetch"

///|
/// Cancel a pending fetch request
pub fn cancel_fetch(callback_id : Int) -> Unit {
  callback_registry.callbacks.remove(callback_id)
  cancel_fetch_ffi(callback_id)
}

///|
/// FFI function to cancel fetch
fn cancel_fetch_ffi(callback_id : Int) -> Unit = "mhx_ffi" "cancel_fetch"

///|
/// Create a Response from text (placeholder until full response handling)
fn Response::from_text(text : String) -> Response {
  // This is a placeholder - in real implementation we'd have the full JsResponse
  // For now, create a minimal response structure
  { raw: create_dummy_response_ffi(), body: text }
}

///|
/// Create a dummy JsResponse for testing (FFI stub)
fn create_dummy_response_ffi() -> @ffi.JsResponse = "mhx_ffi" "create_dummy_response"

///|
/// Fetch with a simple promise-like interface using tasks
pub fn fetch_task(
  url : String,
  options : RequestOptions
) -> FetchTask {
  FetchTask::new(url, options)
}

///|
/// A task representing an in-flight fetch request
pub struct FetchTask {
  /// The request URL
  url : String
  /// Request options
  options : RequestOptions
  /// Internal callback ID (0 if not started)
  mut callback_id : Int
  /// Result storage
  mut result : FetchResult
}

///|
/// Create a new fetch task
pub fn FetchTask::new(url : String, options : RequestOptions) -> FetchTask {
  { url, options, callback_id: 0, result: FetchResult::Pending }
}

///|
/// Start the fetch task
pub fn FetchTask::start(
  self : FetchTask,
  on_complete : (FetchResult) -> Unit
) -> Unit {
  self.callback_id = fetch_async(
    self.url,
    self.options,
    fn(response) {
      self.result = FetchResult::Success(response)
      on_complete(self.result)
    },
    fn(error) {
      self.result = FetchResult::Error(error)
      on_complete(self.result)
    },
  )
}

///|
/// Cancel the fetch task
pub fn FetchTask::cancel(self : FetchTask) -> Unit {
  if self.callback_id > 0 {
    cancel_fetch(self.callback_id)
    self.callback_id = 0
  }
}

///|
/// Check if the task is pending
pub fn FetchTask::is_pending(self : FetchTask) -> Bool {
  self.result is Pending
}

///|
/// Get the result (may be Pending)
pub fn FetchTask::get_result(self : FetchTask) -> FetchResult {
  self.result
}

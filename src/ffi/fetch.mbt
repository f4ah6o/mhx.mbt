///|
/// FFI bindings for Fetch API
/// Provides async HTTP request functionality

///|
/// Opaque type representing a JS Promise
#external
pub type JsPromise

///|
/// Opaque type representing a fetch Response
#external
pub type JsResponse

///|
/// Opaque type representing request Headers
#external
pub type JsHeaders

///|
/// Opaque type representing FormData
#external
pub type JsFormData

///|
/// Opaque type representing AbortController
#external
pub type AbortController

///|
/// Opaque type representing AbortSignal
#external
pub type AbortSignal

///|
/// Perform a fetch request
/// Returns a Promise that resolves to Response
pub fn js_fetch(url : String, options : String) -> JsPromise = "mhx_ffi" "fetch"

///|
/// Get response status code
pub fn JsResponse::status(self : JsResponse) -> Int = "mhx_ffi" "response_status"

///|
/// Get response status text
pub fn JsResponse::status_text(self : JsResponse) -> String = "mhx_ffi" "response_status_text"

///|
/// Check if response is ok (status 200-299)
pub fn JsResponse::ok(self : JsResponse) -> Bool = "mhx_ffi" "response_ok"

///|
/// Get response headers
pub fn JsResponse::headers(self : JsResponse) -> JsHeaders = "mhx_ffi" "response_headers"

///|
/// Get response URL (after redirects)
pub fn JsResponse::url(self : JsResponse) -> String = "mhx_ffi" "response_url"

///|
/// Check if response was redirected
pub fn JsResponse::redirected(self : JsResponse) -> Bool = "mhx_ffi" "response_redirected"

///|
/// Get response body as text (returns Promise)
pub fn JsResponse::text(self : JsResponse) -> JsPromise = "mhx_ffi" "response_text"

///|
/// Get response body as JSON (returns Promise)
pub fn JsResponse::json(self : JsResponse) -> JsPromise = "mhx_ffi" "response_json"

///|
/// Get a header value (empty if not found)
pub fn JsHeaders::get(self : JsHeaders, name : String) -> String = "mhx_ffi" "headers_get"

///|
/// Check if a header exists
pub fn JsHeaders::has(self : JsHeaders, name : String) -> Bool = "mhx_ffi" "headers_has"

///|
/// Create new AbortController
pub fn AbortController::new() -> AbortController = "mhx_ffi" "abort_controller_new"

///|
/// Get the signal from AbortController
pub fn AbortController::signal(self : AbortController) -> AbortSignal = "mhx_ffi" "abort_controller_signal"

///|
/// Abort the request
pub fn AbortController::abort(self : AbortController) -> Unit = "mhx_ffi" "abort_controller_abort"

///|
/// Check if signal is aborted
pub fn AbortSignal::aborted(self : AbortSignal) -> Bool = "mhx_ffi" "abort_signal_aborted"

///|
/// Create new FormData
pub fn JsFormData::new() -> JsFormData = "mhx_ffi" "form_data_new"

///|
/// Create FormData from a form element
pub fn JsFormData::from_element(element : Element) -> JsFormData = "mhx_ffi" "form_data_from_element"

///|
/// Append a string value to FormData
pub fn JsFormData::append(
  self : JsFormData,
  name : String,
  value : String,
) -> Unit = "mhx_ffi" "form_data_append"

///|
/// Get a value from FormData (empty if not found)
pub fn JsFormData::get(self : JsFormData, name : String) -> String = "mhx_ffi" "form_data_get"

///|
/// Check if FormData has a key
pub fn JsFormData::has(self : JsFormData, name : String) -> Bool = "mhx_ffi" "form_data_has"

///|
/// Convert FormData to URL-encoded string
pub fn JsFormData::to_url_encoded(self : JsFormData) -> String = "mhx_ffi" "form_data_to_url_encoded"

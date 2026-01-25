///|
/// FFI bindings for Document and Window globals
/// Provides access to global DOM objects

///|
/// Opaque type representing the Document
#external
pub type Document

///|
/// Opaque type representing the Window
#external
pub type Window

///|
/// Get the global document object
pub fn document() -> Document = "mhx_ffi" "get_document"

///|
/// Get the global window object
pub fn window() -> Window = "mhx_ffi" "get_window"

///|
/// Get the document body element
pub fn Document::body_ffi(self : Document) -> Element = "mhx_ffi" "document_body"

///|
/// Get the document head element
pub fn Document::head_ffi(self : Document) -> Element = "mhx_ffi" "document_head"

///|
/// Get the document element (html)
pub fn Document::document_element_ffi(self : Document) -> Element = "mhx_ffi" "document_document_element"

///|
/// Query for a single element matching the selector
pub fn Document::query_selector_ffi(
  self : Document,
  selector : String,
) -> Element = "mhx_ffi" "document_query_selector"

///|
/// Check if query_selector found an element
pub fn Document::query_selector_exists(
  self : Document,
  selector : String,
) -> Bool = "mhx_ffi" "document_query_selector_exists"

///|
/// Get the number of elements matching selector
pub fn Document::query_selector_all_count(
  self : Document,
  selector : String,
) -> Int = "mhx_ffi" "document_query_selector_all_count"

///|
/// Get element at index from querySelectorAll result
pub fn Document::query_selector_all_at(
  self : Document,
  selector : String,
  index : Int,
) -> Element = "mhx_ffi" "document_query_selector_all_at"

///|
/// Get element by ID
pub fn Document::get_element_by_id_ffi(self : Document, id : String) -> Element = "mhx_ffi" "document_get_element_by_id"

///|
/// Check if element with ID exists
pub fn Document::element_exists(self : Document, id : String) -> Bool = "mhx_ffi" "document_element_exists"

///|
/// Create a new element
pub fn Document::create_element(self : Document, tag : String) -> Element = "mhx_ffi" "document_create_element"

///|
/// Get the current URL
pub fn Document::url(self : Document) -> String = "mhx_ffi" "document_url"

///|
/// Get the document title
pub fn Document::title(self : Document) -> String = "mhx_ffi" "document_title"

///|
/// Set the document title
pub fn Document::set_title(self : Document, title : String) -> Unit = "mhx_ffi" "document_set_title"

///|
/// Get the active (focused) element
pub fn Document::active_element_ffi(self : Document) -> Element = "mhx_ffi" "document_active_element"

///|
/// Check if there's an active element
pub fn Document::has_active_element(self : Document) -> Bool = "mhx_ffi" "document_has_active_element"

///|
/// Add event listener to document
pub fn Document::add_event_listener(
  self : Document,
  event_type : String,
  handler : (Event) -> Unit,
) -> Unit = "mhx_ffi" "document_add_event_listener"

///|
/// Add event listener to window
pub fn Window::add_event_listener(
  self : Window,
  event_type : String,
  handler : (Event) -> Unit,
) -> Unit = "mhx_ffi" "window_add_event_listener"

///|
/// Get the current location href
pub fn Window::location_href(self : Window) -> String = "mhx_ffi" "window_location_href"

///|
/// Set the location href (navigate)
pub fn Window::set_location_href(self : Window, href : String) -> Unit = "mhx_ffi" "window_set_location_href"

///|
/// Push state to history
pub fn Window::history_push_state(
  self : Window,
  url : String,
  title : String,
) -> Unit = "mhx_ffi" "window_history_push_state"

///|
/// Replace state in history
pub fn Window::history_replace_state(
  self : Window,
  url : String,
  title : String,
) -> Unit = "mhx_ffi" "window_history_replace_state"

///|
/// Go back in history
pub fn Window::history_back(self : Window) -> Unit = "mhx_ffi" "window_history_back"

///|
/// Go forward in history
pub fn Window::history_forward(self : Window) -> Unit = "mhx_ffi" "window_history_forward"

///|
/// Schedule a callback after delay (setTimeout)
pub fn Window::set_timeout(
  self : Window,
  handler : () -> Unit,
  delay_ms : Int,
) -> Int = "mhx_ffi" "window_set_timeout"

///|
/// Cancel a timeout
pub fn Window::clear_timeout(self : Window, id : Int) -> Unit = "mhx_ffi" "window_clear_timeout"

///|
/// Schedule a repeating callback (setInterval)
pub fn Window::set_interval(
  self : Window,
  handler : () -> Unit,
  interval_ms : Int,
) -> Int = "mhx_ffi" "window_set_interval"

///|
/// Cancel an interval
pub fn Window::clear_interval(self : Window, id : Int) -> Unit = "mhx_ffi" "window_clear_interval"

///|
/// Request animation frame
pub fn Window::request_animation_frame(
  self : Window,
  handler : (Double) -> Unit,
) -> Int = "mhx_ffi" "window_request_animation_frame"

///|
/// Cancel animation frame
pub fn Window::cancel_animation_frame(self : Window, id : Int) -> Unit = "mhx_ffi" "window_cancel_animation_frame"

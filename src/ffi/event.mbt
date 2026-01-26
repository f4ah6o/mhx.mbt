///|
/// FFI bindings for DOM Event type
/// Provides access to event properties and methods

///|
/// Opaque type representing a DOM Event
#external
pub type Event

///|
/// Get the event type (e.g., "click", "submit")
pub fn Event::type_(self : Event) -> String = "mhx_ffi" "event_type"

///|
/// Get the target element of the event (may be null)
pub fn Event::target_ffi(self : Event) -> Element = "mhx_ffi" "event_target"

///|
/// Get the current target element (the element the handler is attached to)
pub fn Event::current_target_ffi(self : Event) -> Element = "mhx_ffi" "event_current_target"

///|
/// Check if target exists
pub fn Event::has_target(self : Event) -> Bool = "mhx_ffi" "event_has_target"

///|
/// Prevent the default action
pub fn Event::prevent_default(self : Event) -> Unit = "mhx_ffi" "event_prevent_default"

///|
/// Stop propagation to parent elements
pub fn Event::stop_propagation(self : Event) -> Unit = "mhx_ffi" "event_stop_propagation"

///|
/// Stop immediate propagation (prevents other handlers on same element)
pub fn Event::stop_immediate_propagation(self : Event) -> Unit = "mhx_ffi" "event_stop_immediate_propagation"

///|
/// Check if the event is trusted (initiated by user action)
pub fn Event::is_trusted(self : Event) -> Bool = "mhx_ffi" "event_is_trusted"

///|
/// Check if default was prevented
pub fn Event::default_prevented(self : Event) -> Bool = "mhx_ffi" "event_default_prevented"

///|
/// Check if propagation was stopped (cancelBubble)
pub fn Event::cancel_bubble(self : Event) -> Bool = "mhx_ffi" "event_cancel_bubble"

///|
/// Get the event timestamp
pub fn Event::time_stamp(self : Event) -> Double = "mhx_ffi" "event_time_stamp"

///|
/// Evaluate a JavaScript expression in event context
/// Returns true if expression is truthy
pub fn Event::eval_filter(self : Event, expr : String) -> Bool =
  "mhx_ffi" "event_eval_filter"

///|
/// Opaque type for MouseEvent (extends Event)
#external
pub type MouseEvent

///|
/// Cast Event to MouseEvent (unsafe, caller must ensure type)
pub fn Event::as_mouse_event(self : Event) -> MouseEvent = "mhx_ffi" "event_as_mouse_event"

///|
/// Get client X coordinate
pub fn MouseEvent::client_x(self : MouseEvent) -> Int = "mhx_ffi" "mouse_event_client_x"

///|
/// Get client Y coordinate
pub fn MouseEvent::client_y(self : MouseEvent) -> Int = "mhx_ffi" "mouse_event_client_y"

///|
/// Check if Ctrl key was pressed
pub fn MouseEvent::ctrl_key(self : MouseEvent) -> Bool = "mhx_ffi" "mouse_event_ctrl_key"

///|
/// Check if Shift key was pressed
pub fn MouseEvent::shift_key(self : MouseEvent) -> Bool = "mhx_ffi" "mouse_event_shift_key"

///|
/// Check if Alt key was pressed
pub fn MouseEvent::alt_key(self : MouseEvent) -> Bool = "mhx_ffi" "mouse_event_alt_key"

///|
/// Check if Meta key was pressed
pub fn MouseEvent::meta_key(self : MouseEvent) -> Bool = "mhx_ffi" "mouse_event_meta_key"

///|
/// Get the button that was pressed (0=left, 1=middle, 2=right)
pub fn MouseEvent::button(self : MouseEvent) -> Int = "mhx_ffi" "mouse_event_button"

///|
/// Opaque type for KeyboardEvent (extends Event)
#external
pub type KeyboardEvent

///|
/// Cast Event to KeyboardEvent (unsafe, caller must ensure type)
pub fn Event::as_keyboard_event(self : Event) -> KeyboardEvent = "mhx_ffi" "event_as_keyboard_event"

///|
/// Get the key value
pub fn KeyboardEvent::key(self : KeyboardEvent) -> String = "mhx_ffi" "keyboard_event_key"

///|
/// Get the key code
pub fn KeyboardEvent::code(self : KeyboardEvent) -> String = "mhx_ffi" "keyboard_event_code"

///|
/// Check if Ctrl key was pressed
pub fn KeyboardEvent::ctrl_key(self : KeyboardEvent) -> Bool = "mhx_ffi" "keyboard_event_ctrl_key"

///|
/// Check if Shift key was pressed
pub fn KeyboardEvent::shift_key(self : KeyboardEvent) -> Bool = "mhx_ffi" "keyboard_event_shift_key"

///|
/// Check if Alt key was pressed
pub fn KeyboardEvent::alt_key(self : KeyboardEvent) -> Bool = "mhx_ffi" "keyboard_event_alt_key"

///|
/// Check if Meta key was pressed
pub fn KeyboardEvent::meta_key(self : KeyboardEvent) -> Bool = "mhx_ffi" "keyboard_event_meta_key"

///|
/// Check if this is a repeat event
pub fn KeyboardEvent::repeat(self : KeyboardEvent) -> Bool = "mhx_ffi" "keyboard_event_repeat"

///|
/// Opaque type for InputEvent
#external
pub type InputEvent

///|
/// Cast Event to InputEvent
pub fn Event::as_input_event(self : Event) -> InputEvent = "mhx_ffi" "event_as_input_event"

///|
/// Get the input data (characters inserted, empty if none)
pub fn InputEvent::data(self : InputEvent) -> String = "mhx_ffi" "input_event_data"

///|
/// Get the input type (e.g., "insertText", "deleteContentBackward")
pub fn InputEvent::input_type(self : InputEvent) -> String = "mhx_ffi" "input_event_input_type"

///|
/// Opaque type for SubmitEvent
#external
pub type SubmitEvent

///|
/// Cast Event to SubmitEvent
pub fn Event::as_submit_event(self : Event) -> SubmitEvent = "mhx_ffi" "event_as_submit_event"

///|
/// Get the submitter element (button that triggered submit)
pub fn SubmitEvent::submitter_ffi(self : SubmitEvent) -> Element = "mhx_ffi" "submit_event_submitter"

///|
/// Check if submitter exists
pub fn SubmitEvent::has_submitter(self : SubmitEvent) -> Bool = "mhx_ffi" "submit_event_has_submitter"

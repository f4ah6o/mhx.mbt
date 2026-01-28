///|
/// Event delegation system for mhx
/// Implements centralized event handling with bubbling simulation

///|
/// Event handler callback type
pub(all) struct EventHandler {
  handle : (MhxEvent) -> Unit
}

///|
/// Wrapped event with additional mhx context
pub(all) struct MhxEvent {
  /// The original DOM event
  event : @ffi.Event
  /// The element that matched (has mx-* attributes)
  matched_element : @ffi.Element
  /// The parsed configuration for this element
  config : ElementConfig
  /// The trigger definition that fired
  trigger : @trigger.TriggerDef
}

///|
/// Event delegation manager
/// Handles event registration and dispatch
pub struct EventDelegator {
  /// Registered event types
  registered_events : Map[String, Bool]
  /// Event handlers by event type
  handlers : Map[String, Array[EventHandler]]
  /// Configuration cache
  cache : ConfigCache
  /// Whether delegation is active
  mut active : Bool
}

///|
/// Create a new event delegator
pub fn EventDelegator::new() -> EventDelegator {
  {
    registered_events: {},
    handlers: {},
    cache: ConfigCache::new(),
    active: false,
  }
}

///|
/// Register an event type for delegation
pub fn EventDelegator::register_event(
  self : EventDelegator,
  event_type : String,
) -> Unit {
  if not(self.registered_events.contains(event_type)) {
    self.registered_events[event_type] = true
    self.handlers[event_type] = []
  }
}

///|
/// Add a handler for an event type
pub fn EventDelegator::add_handler(
  self : EventDelegator,
  event_type : String,
  handler : EventHandler,
) -> Unit {
  self.register_event(event_type)
  match self.handlers.get(event_type) {
    Some(handlers) => handlers.push(handler)
    None => self.handlers[event_type] = [handler]
  }
}

///|
/// Get the configuration cache
pub fn EventDelegator::get_cache(self : EventDelegator) -> ConfigCache {
  self.cache
}

///|
/// Check if delegation is active
pub fn EventDelegator::is_active(self : EventDelegator) -> Bool {
  self.active
}

///|
/// Set delegation active state
pub fn EventDelegator::set_active(self : EventDelegator, active : Bool) -> Unit {
  self.active = active
}

///|
/// Dispatch handlers for an event
pub fn EventDelegator::dispatch(
  self : EventDelegator,
  event_type : String,
  mhx_event : MhxEvent,
) -> Unit {
  match self.handlers.get(event_type) {
    Some(handlers) =>
      for handler in handlers {
        (handler.handle)(mhx_event)
      }
    None => ()
  }
}

///|
/// Get list of registered event types
pub fn EventDelegator::get_registered_events(
  self : EventDelegator,
) -> Array[String] {
  let events : Array[String] = []
  for event_type, _ in self.registered_events {
    events.push(event_type)
  }
  events
}

///|
/// Default event types to register
pub let default_events : Array[String] = [
  "click", "submit", "change", "input", "focus", "blur", "keydown", "keyup", "mouseenter",
  "mouseleave", "load", "revealed", "intersect",
]

///|
/// Register all default event types
pub fn EventDelegator::register_defaults(self : EventDelegator) -> Unit {
  for event_type in default_events {
    self.register_event(event_type)
  }
}

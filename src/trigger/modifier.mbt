///|
/// Modifier types for trigger definitions
/// Modifiers control how and when triggers fire

///|
/// Represents a modifier that changes trigger behavior
pub(all) enum Modifier {
  /// Fire only once, then remove the trigger
  Once
  /// Fire only when the value has changed
  Changed
  /// Delay before firing (milliseconds)
  Delay(Int)
  /// Throttle: fire at most once per interval (milliseconds)
  Throttle(Int)
  /// Debounce: fire after quiet period (milliseconds)
  Debounce(Int)
  /// Listen for events from a different element
  From(Selector)
  /// Specify the target element for the action
  Target(Selector)
  /// Call event.stopPropagation()
  Consume
  /// Call event.preventDefault()
  Prevent
  /// Filter condition (JavaScript expression string)
  /// e.g., [ctrlKey], [target.value!='']
  Filter(String)
  /// Queue behavior for requests
  Queue(QueueMode)
} derive(Show, Eq)

///|
/// Queue mode for concurrent request handling
pub(all) enum QueueMode {
  /// Drop new requests while one is in flight (default)
  Drop
  /// Cancel current request and start new one
  Replace
  /// Queue first request after current
  QueueFirst
  /// Queue last request after current
  QueueLast
  /// Queue all requests
  QueueAll
} derive(Show, Eq)

///|
pub impl ToJson for QueueMode with to_json(self) {
  match self {
    Drop => "drop".to_json()
    Replace => "replace".to_json()
    QueueFirst => "first".to_json()
    QueueLast => "last".to_json()
    QueueAll => "all".to_json()
  }
}

///|
pub impl ToJson for Modifier with to_json(self) {
  match self {
    Once => { "type": "once" }
    Changed => { "type": "changed" }
    Delay(ms) => { "type": "delay", "ms": ms.to_json() }
    Throttle(ms) => { "type": "throttle", "ms": ms.to_json() }
    Debounce(ms) => { "type": "debounce", "ms": ms.to_json() }
    From(sel) => { "type": "from", "selector": sel.to_json() }
    Target(sel) => { "type": "target", "selector": sel.to_json() }
    Consume => { "type": "consume" }
    Prevent => { "type": "prevent" }
    Filter(expr) => { "type": "filter", "expr": expr.to_json() }
    Queue(mode) => { "type": "queue", "mode": mode.to_json() }
  }
}

///|
/// Request synchronization strategies for mhx
/// Implements hx-sync equivalent functionality

///|
/// Sync strategies for request coordination
pub(all) enum SyncStrategy {
  /// Drop new requests if one is already in flight
  Drop
  /// Cancel existing request and start new one
  Replace
  /// Queue requests to run sequentially
  Queue(QueueBehavior)
} derive(Show, Eq)

///|
/// Queue behavior options
pub(all) enum QueueBehavior {
  /// First in, first out
  First
  /// Last in, first out (drop intermediate)
  Last
  /// Allow all in order
  All
} derive(Show, Eq)

///|
/// A request task with metadata
pub(all) struct RequestTask {
  /// Unique ID for this task
  id : Int
  /// Element ID that triggered the request
  element_id : Int
  /// URL to request
  url : String
  /// Request options
  options : RequestOptions
  /// Abort controller for cancellation
  controller : @ffi.AbortController
  /// Sync strategy
  sync_strategy : SyncStrategy
}

///|
/// Create a new request task
pub fn RequestTask::new(
  id : Int,
  element_id : Int,
  url : String,
  options : RequestOptions,
  sync_strategy : SyncStrategy
) -> RequestTask {
  let controller = @ffi.AbortController::new()
  let options_with_signal = options.with_signal(controller.signal())
  {
    id,
    element_id,
    url,
    options: options_with_signal,
    controller,
    sync_strategy,
  }
}

///|
/// Cancel this task
pub fn RequestTask::cancel(self : RequestTask) -> Unit {
  self.controller.abort()
}

///|
/// Check if this task is cancelled
pub fn RequestTask::is_cancelled(self : RequestTask) -> Bool {
  self.controller.signal().aborted()
}

///|
/// Request queue for an element
struct RequestQueue {
  /// Currently executing task (if any)
  mut current : RequestTask?
  /// Queued tasks waiting to execute
  pending : Array[RequestTask]
}

///|
/// Create a new request queue
fn RequestQueue::new() -> RequestQueue {
  { current: Option::None, pending: [] }
}

///|
/// Check if queue is empty (no current or pending)
fn RequestQueue::is_empty(self : RequestQueue) -> Bool {
  self.current is None && self.pending.is_empty()
}

///|
/// Check if there's a request in flight
fn RequestQueue::is_busy(self : RequestQueue) -> Bool {
  self.current is Some(_)
}

///|
/// Request manager handles coordination of concurrent requests
/// Implements hx-sync behavior
pub struct RequestManager {
  /// Request queues by element ID
  queues : Map[Int, RequestQueue]
  /// Next task ID
  mut next_id : Int
}

///|
/// Create a new request manager
pub fn RequestManager::new() -> RequestManager {
  { queues: {}, next_id: 1 }
}

///|
/// Get or create a queue for an element
fn RequestManager::get_queue(self : RequestManager, element_id : Int) -> RequestQueue {
  match self.queues.get(element_id) {
    Some(queue) => queue
    None => {
      let queue = RequestQueue::new()
      self.queues[element_id] = queue
      queue
    }
  }
}

///|
/// Result of scheduling a request
pub(all) enum ScheduleResult {
  /// Request was scheduled for immediate execution
  Execute(RequestTask)
  /// Request was queued for later
  Queued
  /// Request was dropped (due to sync strategy)
  Dropped
}

///|
/// Schedule a request according to its sync strategy
/// Returns the task to execute or None if dropped/queued
pub fn RequestManager::schedule(
  self : RequestManager,
  element_id : Int,
  url : String,
  options : RequestOptions,
  strategy : SyncStrategy
) -> ScheduleResult {
  let task_id = self.next_id
  self.next_id += 1
  let queue = self.get_queue(element_id)
  let task = RequestTask::new(task_id, element_id, url, options, strategy)
  match strategy {
    Drop => {
      // Only execute if no request is in flight
      if queue.is_busy() {
        ScheduleResult::Dropped
      } else {
        queue.current = Some(task)
        ScheduleResult::Execute(task)
      }
    }
    Replace => {
      // Cancel existing and start new
      match queue.current {
        Some(current) => current.cancel()
        None => ()
      }
      // Also clear any pending
      queue.pending.clear()
      queue.current = Some(task)
      ScheduleResult::Execute(task)
    }
    Queue(behavior) =>
      if queue.is_busy() {
        // Queue based on behavior
        match behavior {
          First => {
            // Add to end of queue
            queue.pending.push(task)
            ScheduleResult::Queued
          }
          Last => {
            // Replace any pending with just this one
            queue.pending.clear()
            queue.pending.push(task)
            ScheduleResult::Queued
          }
          All => {
            // Add to queue
            queue.pending.push(task)
            ScheduleResult::Queued
          }
        }
      } else {
        // Nothing in flight, execute immediately
        queue.current = Some(task)
        ScheduleResult::Execute(task)
      }
  }
}

///|
/// Mark a request as completed and get next queued request
pub fn RequestManager::complete(
  self : RequestManager,
  element_id : Int,
  _task_id : Int
) -> RequestTask? {
  match self.queues.get(element_id) {
    Some(queue) => {
      queue.current = Option::None
      // Get next pending task
      if queue.pending.is_empty() {
        Option::None
      } else {
        let next = queue.pending.remove(0)
        queue.current = Some(next)
        Some(next)
      }
    }
    None => Option::None
  }
}

///|
/// Cancel all requests for an element
pub fn RequestManager::cancel_all(
  self : RequestManager,
  element_id : Int
) -> Unit {
  match self.queues.get(element_id) {
    Some(queue) => {
      match queue.current {
        Some(current) => current.cancel()
        None => ()
      }
      for task in queue.pending {
        task.cancel()
      }
      queue.current = Option::None
      queue.pending.clear()
    }
    None => ()
  }
}

///|
/// Get count of pending requests for an element
pub fn RequestManager::pending_count(
  self : RequestManager,
  element_id : Int
) -> Int {
  match self.queues.get(element_id) {
    Some(queue) => {
      let current_count = if queue.current is Some(_) { 1 } else { 0 }
      current_count + queue.pending.length()
    }
    None => 0
  }
}

///|
/// Clear all queues
pub fn RequestManager::clear(self : RequestManager) -> Unit {
  for element_id, _ in self.queues {
    self.cancel_all(element_id)
  }
  self.queues.clear()
  self.next_id = 1
}

///|
/// Parse sync strategy from attribute value
pub fn parse_sync_strategy(value : String) -> SyncStrategy {
  let v = value.to_lower().trim().to_string()
  match v {
    "drop" => SyncStrategy::Drop
    "replace" => SyncStrategy::Replace
    "queue" | "queue first" | "queue:first" => SyncStrategy::Queue(
      QueueBehavior::First,
    )
    "queue last" | "queue:last" => SyncStrategy::Queue(QueueBehavior::Last)
    "queue all" | "queue:all" => SyncStrategy::Queue(QueueBehavior::All)
    _ => SyncStrategy::Drop // default
  }
}

///|
/// Request synchronization strategies for mhx
/// Implements hx-sync equivalent functionality

///|
/// Sync strategy alias for runtime scheduling
type SyncStrategy = @sync.SyncStrategy

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
  /// Whether the task was cancelled before completion
  mut cancelled : Bool
  /// Callback identifier for the active JS fetch bridge
  mut callback_id : Int
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
  sync_strategy : SyncStrategy,
) -> RequestTask {
  {
    id,
    element_id,
    url,
    options,
    cancelled: false,
    callback_id: 0,
    sync_strategy,
  }
}

///|
/// Attach the JS fetch callback identifier once execution starts.
pub fn RequestTask::attach_callback(
  self : RequestTask,
  callback_id : Int,
) -> Unit {
  self.callback_id = callback_id
}

///|
/// Clear the JS fetch callback identifier after completion.
pub fn RequestTask::clear_callback(self : RequestTask) -> Unit {
  self.callback_id = 0
}

///|
/// Cancel this task.
///
/// Sets a local cancellation flag and propagates to JS via cancel_fetch(callback_id),
/// which calls AbortController.abort() on the stored JS-side controller.
/// This avoids requiring the MoonBit-side AbortController FFI signal propagation;
/// the abort is routed through the callback-id registry instead.
pub fn RequestTask::cancel(self : RequestTask) -> Unit {
  self.cancelled = true
  if self.callback_id > 0 {
    cancel_fetch(self.callback_id)
    self.callback_id = 0
  }
}

///|
/// Check if this task is cancelled
pub fn RequestTask::is_cancelled(self : RequestTask) -> Bool {
  self.cancelled
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
fn RequestManager::get_queue(
  self : RequestManager,
  element_id : Int,
) -> RequestQueue {
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
  strategy : SyncStrategy,
) -> ScheduleResult {
  let task_id = self.next_id
  self.next_id += 1
  let queue = self.get_queue(element_id)
  let task = RequestTask::new(task_id, element_id, url, options, strategy)
  match strategy {
    @sync.SyncStrategy::Drop =>
      // Only execute if no request is in flight
      if queue.is_busy() {
        ScheduleResult::Dropped
      } else {
        queue.current = Some(task)
        ScheduleResult::Execute(task)
      }
    @sync.SyncStrategy::Replace => {
      // Cancel existing and start new
      match queue.current {
        Some(current) => current.cancel()
        None => ()
      }
      // Also clear any pending
      for pending in queue.pending {
        pending.cancel()
      }
      queue.pending.clear()
      queue.current = Some(task)
      ScheduleResult::Execute(task)
    }
    @sync.SyncStrategy::Queue(behavior) =>
      if queue.is_busy() {
        // Queue based on behavior
        match behavior {
          @sync.QueueMode::First =>
            // Preserve only the first queued task while busy
            if queue.pending.is_empty() {
              queue.pending.push(task)
              ScheduleResult::Queued
            } else {
              ScheduleResult::Dropped
            }
          @sync.QueueMode::Last => {
            // Replace any pending with just this one
            for pending in queue.pending {
              pending.cancel()
            }
            queue.pending.clear()
            queue.pending.push(task)
            ScheduleResult::Queued
          }
          @sync.QueueMode::All => {
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
  task_id : Int,
) -> RequestTask? {
  match self.queues.get(element_id) {
    Some(queue) =>
      match queue.current {
        Some(current) =>
          if current.id == task_id {
            queue.current = Option::None
            // Get next pending task
            if queue.pending.is_empty() {
              Option::None
            } else {
              let next = queue.pending.remove(0)
              queue.current = Some(next)
              Some(next)
            }
          } else {
            Option::None
          }
        None => Option::None
      }
    None => Option::None
  }
}

///|
/// Cancel all requests for an element
pub fn RequestManager::cancel_all(
  self : RequestManager,
  element_id : Int,
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
  element_id : Int,
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

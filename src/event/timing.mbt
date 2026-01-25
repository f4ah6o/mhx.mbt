///|
/// Timing modifiers implementation (delay, throttle, debounce)
/// Manages timing state for individual trigger instances

///|
/// State for a single timing instance
pub struct TimingState {
  /// Pending timeout ID for delay/debounce (0 if none)
  mut pending_timeout : Int
  /// Last execution time for throttle (0 if never)
  mut last_execution : Double
  /// Whether currently throttled
  mut is_throttled : Bool
  /// Queued action during throttle period
  mut queued_action : (() -> Unit)?
}

///|
/// Create a new timing state
pub fn TimingState::new() -> TimingState {
  {
    pending_timeout: 0,
    last_execution: 0.0,
    is_throttled: false,
    queued_action: None,
  }
}

///|
/// Reset the timing state
pub fn TimingState::reset(self : TimingState) -> Unit {
  if self.pending_timeout > 0 {
    let win = @ffi.window()
    win.clear_timeout(self.pending_timeout)
    self.pending_timeout = 0
  }
  self.is_throttled = false
  self.queued_action = None
}

///|
/// Manager for timing state across multiple triggers
pub struct TimingManager {
  /// Map from element ID + trigger index to timing state
  states : Map[String, TimingState]
}

///|
/// Create a new timing manager
pub fn TimingManager::new() -> TimingManager {
  { states: {} }
}

///|
/// Get or create timing state for an element/trigger combination
pub fn TimingManager::get_state(
  self : TimingManager,
  element_id : Int,
  trigger_index : Int,
) -> TimingState {
  let key = element_id.to_string() + "_" + trigger_index.to_string()
  match self.states.get(key) {
    Some(state) => state
    None => {
      let state = TimingState::new()
      self.states[key] = state
      state
    }
  }
}

///|
/// Remove timing state for an element
pub fn TimingManager::remove_element(
  self : TimingManager,
  element_id : Int,
) -> Unit {
  // Remove all states for this element (any trigger index)
  let prefix = element_id.to_string() + "_"
  let keys_to_remove : Array[String] = []
  for key, state in self.states {
    if key.has_prefix(prefix) {
      state.reset()
      keys_to_remove.push(key)
    }
  }
  for key in keys_to_remove {
    self.states.remove(key)
  }
}

///|
/// Apply delay modifier
/// Schedules action to run after delay_ms milliseconds
pub fn apply_delay(
  state : TimingState,
  delay_ms : Int,
  action : () -> Unit,
) -> Unit {
  // Cancel any pending timeout
  if state.pending_timeout > 0 {
    let win = @ffi.window()
    win.clear_timeout(state.pending_timeout)
  }
  // Schedule new timeout
  let win = @ffi.window()
  state.pending_timeout = win.set_timeout(
    fn() {
      state.pending_timeout = 0
      action()
    },
    delay_ms,
  )
}

///|
/// Apply throttle modifier
/// Ensures action runs at most once per throttle_ms milliseconds
pub fn apply_throttle(
  state : TimingState,
  throttle_ms : Int,
  action : () -> Unit,
) -> Unit {
  let now = current_time()
  let elapsed = now - state.last_execution
  if elapsed >= throttle_ms.to_double() {
    // Enough time has passed, execute immediately
    state.last_execution = now
    action()
  } else if not(state.is_throttled) {
    // Schedule execution after remaining time
    state.is_throttled = true
    let remaining = throttle_ms.to_double() - elapsed
    let win = @ffi.window()
    state.pending_timeout = win.set_timeout(
      fn() {
        state.pending_timeout = 0
        state.is_throttled = false
        state.last_execution = current_time()
        // Execute the queued action if any
        match state.queued_action {
          Some(queued) => {
            state.queued_action = None
            queued()
          }
          None => action()
        }
      },
      remaining.to_int(),
    )
  } else {
    // Already throttled, queue the latest action
    state.queued_action = Some(action)
  }
}

///|
/// Apply debounce modifier
/// Waits for debounce_ms of inactivity before executing
pub fn apply_debounce(
  state : TimingState,
  debounce_ms : Int,
  action : () -> Unit,
) -> Unit {
  // Cancel any pending timeout
  if state.pending_timeout > 0 {
    let win = @ffi.window()
    win.clear_timeout(state.pending_timeout)
  }
  // Schedule new timeout
  let win = @ffi.window()
  state.pending_timeout = win.set_timeout(
    fn() {
      state.pending_timeout = 0
      action()
    },
    debounce_ms,
  )
}

///|
/// Get current time in milliseconds
fn current_time() -> Double {
  current_time_ffi()
}

///|
/// FFI function to get current time (performance.now or Date.now)
fn current_time_ffi() -> Double = "mhx_ffi" "current_time"

///|
/// Apply timing modifiers from a trigger definition
/// Returns true if action should execute immediately, false if deferred
pub fn apply_timing_modifiers(
  state : TimingState,
  trigger : @trigger.TriggerDef,
  action : () -> Unit,
) -> Bool {
  // Check for delay modifier
  match trigger.get_delay() {
    Some(delay_ms) => {
      apply_delay(state, delay_ms, action)
      return false
    }
    None => ()
  }
  // Check for throttle modifier
  match trigger.get_throttle() {
    Some(throttle_ms) => {
      apply_throttle(state, throttle_ms, action)
      return false
    }
    None => ()
  }
  // Check for debounce modifier
  match trigger.get_debounce() {
    Some(debounce_ms) => {
      apply_debounce(state, debounce_ms, action)
      return false
    }
    None => ()
  }
  // No timing modifiers, execute immediately
  true
}

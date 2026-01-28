///|
/// Core integration for mhx
/// Ties together all components: FFI, triggers, events, network, swap

///|
/// MHX instance state
pub struct Mhx {
  /// Event delegator for handling DOM events
  delegator : @event.EventDelegator
  /// Request manager for coordinating HTTP requests
  request_manager : @network.RequestManager
  /// Configuration cache
  cache : @event.ConfigCache
  /// Timing manager for delay/throttle/debounce
  timing : @event.TimingManager
  /// Last observed input values for changed modifier
  changed_values : Map[Int, String]
  /// Whether mhx has been initialized
  mut initialized : Bool
  /// MutationObserver for auto-processing new elements
  mut observer : @ffi.MutationObserver?
  /// Callback ID for mutation observer
  mut observer_callback_id : Int
}

///|
/// Create a new MHX instance
pub fn Mhx::new() -> Mhx {
  let delegator = @event.EventDelegator::new()
  delegator.register_defaults()
  {
    delegator,
    request_manager: @network.RequestManager::new(),
    cache: @event.ConfigCache::new(),
    timing: @event.TimingManager::new(),
    changed_values: {},
    initialized: false,
    observer: None,
    observer_callback_id: 0,
  }
}

///|
/// Initialize mhx on the document
/// Sets up event delegation and processes existing elements
pub fn Mhx::init_mhx(self : Mhx) -> Unit {
  if self.initialized {
    return
  }
  self.initialized = true
  // Process existing elements with mx-* attributes
  let doc = @ffi.document()
  let body = doc.body_ffi()
  self.process_tree(body)
  // Set delegation as active
  self.delegator.set_active(true)
  // Set up MutationObserver to auto-process new elements
  self.setup_mutation_observer(body)
  // Register event listeners on document
  register_default_event_listeners()
}

///|
/// Process a DOM tree recursively, finding elements with mx-* attributes
pub fn Mhx::process_tree(self : Mhx, root : @ffi.Element) -> Unit {
  // Check if root has mx-* attributes
  if @event.has_mhx_attributes(root) {
    self.process_element(root)
  }
  // Process children
  let child_count = root.child_count()
  for i = 0; i < child_count; i = i + 1 {
    let child = root.child_at(i)
    if not(child.is_null()) {
      self.process_tree(child)
    }
  }
}

///|
/// Process a single element with mx-* attributes
pub fn Mhx::process_element(self : Mhx, element : @ffi.Element) -> Unit {
  // Generate element hash (using tag name + id as simple hash)
  let element_hash = hash_element(element)
  let element_id = self.cache.get_element_id(element_hash)
  // Skip if already processed
  if self.cache.has(element_id) {
    return
  }
  // Parse configuration
  let config : @event.ElementConfig = @event.parse_element_config(element) catch {
    err => {
      report_error(from_parse_error(err))
      return
    }
  }
  // Store configuration
  self.cache.set(element_id, config)
}

///|
/// Set up MutationObserver to automatically process new elements
fn Mhx::setup_mutation_observer(self : Mhx, root : @ffi.Element) -> Unit {
  // Register callback for mutation events
  let callback_id = register_mutation_callback()
  self.observer_callback_id = callback_id
  // Create the observer
  let observer = @ffi.MutationObserver::new_ffi(callback_id)
  // Observe the root for child additions with subtree
  // observe(target, subtree, child_list, attributes)
  observer.observe(root, true, true, true)
  self.observer = Some(observer)
}

///|
/// Disconnect the MutationObserver
pub fn Mhx::disconnect_observer(self : Mhx) -> Unit {
  match self.observer {
    Some(obs) => {
      obs.disconnect()
      self.observer = None
      if self.observer_callback_id > 0 {
        unregister_mutation_callback(self.observer_callback_id)
        self.observer_callback_id = 0
      }
    }
    None => ()
  }
}

///|
/// Internal mutation callback registry
priv struct MutationCallbackRegistry {
  mut next_id : Int
  callbacks : Map[Int, () -> Unit]
}

///|
let mutation_registry : MutationCallbackRegistry = { next_id: 1, callbacks: {} }

///|
/// Register a mutation callback and return its ID
fn register_mutation_callback() -> Int {
  let id = mutation_registry.next_id
  mutation_registry.next_id += 1
  // Store a callback that will process mutations via the global instance
  mutation_registry.callbacks[id] = fn() { process_pending_mutations(id) }
  id
}

///|
/// Unregister a mutation callback
fn unregister_mutation_callback(id : Int) -> Unit {
  mutation_registry.callbacks.remove(id)
}

///|
/// Called from JS when mutations are observed
pub fn on_mutation_observed(callback_id : Int) -> Unit {
  match mutation_registry.callbacks.get(callback_id) {
    Some(cb) => cb()
    None => ()
  }
}

///|
/// Process pending mutations from the observer
fn process_pending_mutations(callback_id : Int) -> Unit {
  let mhx = global_mhx
  match mhx.observer {
    Some(observer) => {
      // Only process if this is our callback
      if mhx.observer_callback_id != callback_id {
        return
      }
      let count = observer.records_count()
      for i = 0; i < count; i = i + 1 {
        let record = observer.record_at(i)
        process_mutation_record(mhx, record)
      }
      observer.clear_records()
    }
    None => ()
  }
}

///|
/// Process a single mutation record
fn process_mutation_record(mhx : Mhx, record : @ffi.MutationRecord) -> Unit {
  let mutation_type = record.type_()
  match mutation_type {
    "childList" => {
      // Process added nodes
      let added_count = record.added_nodes_count()
      for i = 0; i < added_count; i = i + 1 {
        let node = record.added_node_at(i)
        if node.is_element() {
          let element = node.as_element()
          mhx.process_tree(element)
        }
      }
    }
    "attributes" =>
      // An attribute was modified - reprocess if it's an mx-* attribute
      if record.has_attribute_name() {
        let attr_name = record.attribute_name()
        if attr_name.has_prefix("mx-") {
          let target_node = record.target()
          if target_node.is_element() {
            let element = target_node.as_element()
            // Invalidate cache and reprocess
            let element_hash = hash_element(element)
            let element_id = mhx.cache.get_element_id(element_hash)
            mhx.cache.remove(element_id)
            mhx.process_element(element)
          }
        }
      }
    _ => ()
  }
}

///|
/// Simple hash function for element identification
fn hash_element(element : @ffi.Element) -> Int {
  let id = element.id()
  let tag = element.tag_name()
  let combined = tag + "#" + id
  // Simple string hash
  let mut hash = 0
  for c in combined {
    hash = hash * 31 + c.to_int()
  }
  hash
}

///|
/// Handle an event (called from JS event listener)
pub fn Mhx::handle_event(
  self : Mhx,
  event : @ffi.Event,
  target : @ffi.Element,
) -> Unit {
  if not(self.delegator.is_active()) {
    return
  }
  let event_type = event.type_()
  // Walk up the DOM tree to find matching elements
  let mut current = target
  while not(current.is_null()) {
    // Check if element has mx-* attributes
    if @event.has_mhx_attributes(current) {
      // Get or create configuration
      let element_hash = hash_element(current)
      let element_id = self.cache.get_element_id(element_hash)
      let config : @event.ElementConfig? = match self.cache.get(element_id) {
        Some(c) => Some(c)
        None => {
          // Parse and cache on first access
          let parsed : @event.ElementConfig? = Some(
            @event.parse_element_config(current),
          ) catch {
            err => {
              report_error(from_parse_error(err))
              None
            }
          }
          match parsed {
            Some(c) => {
              self.cache.set(element_id, c)
              Some(c)
            }
            None => None
          }
        }
      }
      match config {
        Some(cfg) =>
          // Check if any trigger matches this event
          for trigger_index, trigger in cfg.triggers {
            if @event.trigger_matches_event(trigger, event_type) {
              // Check filter conditions
              if @event.check_filter_conditions(trigger, event) {
                // Apply changed modifier for input-like events
                if trigger.is_changed() &&
                  not(self.is_value_changed(current, trigger_index)) {
                  continue
                }
                // Get timing state for this element/trigger combination
                let timing_state = self.timing.get_state(
                  element_id, trigger_index,
                )
                // Apply timing modifiers (delay, throttle, debounce)
                let execute_now = @event.apply_timing_modifiers(
                  timing_state,
                  trigger,
                  fn() { self.execute_action(current, cfg, trigger, event) },
                )
                if execute_now {
                  // Execute immediately if no timing modifiers
                  self.execute_action(current, cfg, trigger, event)
                }
                // Handle once modifier
                if trigger.is_once() {
                  // Remove from cache to prevent re-triggering
                  self.cache.remove(element_id)
                }
                // Handle consume modifier
                if trigger.should_consume() {
                  event.stop_propagation()
                  break
                }
              }
            }
          }
        None => ()
      }
    }
    // Move to parent
    if not(current.has_parent()) {
      break
    }
    current = current.parent_element_ffi()
    // Check if event propagation was stopped
    if event.cancel_bubble() {
      break
    }
  }
}

///|
/// Check if element value changed since last trigger
fn Mhx::is_value_changed(
  self : Mhx,
  element : @ffi.Element,
  trigger_index : Int,
) -> Bool {
  let element_hash = hash_element(element)
  let element_id = self.cache.get_element_id(element_hash)
  let key = element_id * 100000 + trigger_index
  let current = element.value()
  match self.changed_values.get(key) {
    Some(prev) =>
      if prev == current {
        false
      } else {
        self.changed_values[key] = current
        true
      }
    None => {
      self.changed_values[key] = current
      true
    }
  }
}

///|
/// Execute an action for a matched trigger
fn Mhx::execute_action(
  self : Mhx,
  element : @ffi.Element,
  config : @event.ElementConfig,
  trigger : @trigger.TriggerDef,
  event : @ffi.Event,
) -> Unit {
  // Handle prevent modifier (preventDefault)
  if trigger.should_prevent() {
    event.prevent_default()
  }
  // Determine the URL and method
  let url = config.url
  if url.is_empty() {
    return
  }
  // Build request options
  let options = build_request_options(element, config)
  // Determine sync strategy
  let sync_strategy = get_sync_strategy(element, config)
  // Schedule the request
  let element_hash = hash_element(element)
  let element_id = self.cache.get_element_id(element_hash)
  let result = self.request_manager.schedule(
    element_id, url, options, sync_strategy,
  )
  match result {
    @network.ScheduleResult::Execute(task) => {
      // Add loading indicator
      element.add_class("mx-request")
      // Execute the request
      self.execute_request(element, task, config, trigger)
    }
    @network.ScheduleResult::Queued =>
      // Request is queued, will be executed later
      ()
    @network.ScheduleResult::Dropped =>
      // Request was dropped due to sync strategy
      ()
  }
}

///|
/// Build request options from element configuration
fn build_request_options(
  element : @ffi.Element,
  config : @event.ElementConfig,
) -> @network.RequestOptions {
  let http_method_str = match config.http_method {
    @event.HttpMethod::Get => "GET"
    @event.HttpMethod::Post => "POST"
    @event.HttpMethod::Put => "PUT"
    @event.HttpMethod::Patch => "PATCH"
    @event.HttpMethod::Delete => "DELETE"
  }
  let mut options : @network.RequestOptions = {
    http_method: http_method_str,
    headers: { "HX-Request": "true" },
    body: Option::None,
    signal: Option::None,
  }
  // For POST/PUT/PATCH, collect form data
  match config.http_method {
    @event.HttpMethod::Post
    | @event.HttpMethod::Put
    | @event.HttpMethod::Patch => {
      let body_data = build_request_body(element, config)
      if not(body_data.is_empty()) {
        options = { ..options, body: Some(body_data) }
        options = options.with_header(
          "Content-Type", "application/x-www-form-urlencoded",
        )
      }
    }
    _ => {
      let mx_vals_json = match config.vals {
        Some(v) => v
        None =>
          if element.has_attribute("mx-vals") {
            element.get_attribute("mx-vals")
          } else {
            ""
          }
      }
      if not(mx_vals_json.trim().is_empty()) {
        let merged_json = merge_vals_json("{}", mx_vals_json)
        options = options.with_header("HX-Trigger-Values", merged_json)
      }
    }
  }
  // Add HX-Trigger header
  if element.has_attribute("id") {
    options = options.with_header("HX-Trigger", element.id())
  }
  options
}

// helpers are defined in request_body.mbt and selector.mbt

///|
/// Collect form data from a form element
fn collect_form_data(form : @ffi.Element) -> String {
  let form_data = @ffi.JsFormData::from_element(form)
  form_data.to_url_encoded()
}

///|
/// Get sync strategy from element attributes
fn get_sync_strategy(
  element : @ffi.Element,
  config : @event.ElementConfig,
) -> @sync.SyncStrategy {
  match config.sync {
    Some(strategy) => strategy
    None =>
      if element.has_attribute("mx-sync") {
        @sync.parse_sync_strategy(element.get_attribute("mx-sync"))
      } else {
        @sync.SyncStrategy::Drop
      }
  }
}

///|
/// Execute an HTTP request and handle the response
fn Mhx::execute_request(
  self : Mhx,
  element : @ffi.Element,
  task : @network.RequestTask,
  config : @event.ElementConfig,
  trigger : @trigger.TriggerDef,
) -> Unit {
  let _callback_id = @network.fetch_async(
    task.url,
    task.options,
    fn(response) {
      self.handle_response(element, task, config, trigger, response)
    },
    fn(error_message) {
      element.remove_class("mx-request")
      report_error(network_error(task.url, error_message))
      self.finish_request(element, task, config, trigger)
    },
  )

}

///|
/// Handle a completed response
fn Mhx::handle_response(
  self : Mhx,
  element : @ffi.Element,
  task : @network.RequestTask,
  config : @event.ElementConfig,
  trigger : @trigger.TriggerDef,
  response : @network.Response,
) -> Unit {
  element.remove_class("mx-request")
  if response.ok() {
    let swap_target = resolve_swap_target_from_trigger(element, trigger, config)
    let swap_options = get_swap_options(element, config)
    @swap.perform_swap(swap_target, response.text(), swap_options)
    self.process_tree(swap_target)
  } else {
    let message = response.status().to_string() + " " + response.status_text()
    report_error(network_error(task.url, message))
  }
  self.finish_request(element, task, config, trigger)
}

///|
/// Complete a request and execute the next queued task
fn Mhx::finish_request(
  self : Mhx,
  element : @ffi.Element,
  task : @network.RequestTask,
  config : @event.ElementConfig,
  trigger : @trigger.TriggerDef,
) -> Unit {
  let element_hash = hash_element(element)
  let element_id = self.cache.get_element_id(element_hash)
  let next = self.request_manager.complete(element_id, task.id)
  match next {
    Some(next_task) => self.execute_request(element, next_task, config, trigger)
    None => ()
  }
}

///|
/// Resolve the swap target element
fn resolve_swap_target(
  element : @ffi.Element,
  config : @event.ElementConfig,
) -> @ffi.Element {
  match config.target {
    Some(selector) =>
      // Parse target selector
      if selector == "this" {
        element
      } else if selector.has_prefix("closest ") {
        let sel = selector.view(start_offset=8).to_string()
        if element.closest_exists(sel) {
          element.closest_ffi(sel)
        } else {
          element
        }
      } else if selector.has_prefix("find ") {
        let sel = selector.view(start_offset=5).to_string()
        if element.query_selector_exists(sel) {
          element.query_selector_ffi(sel)
        } else {
          element
        }
      } else {
        let doc = @ffi.document()
        if doc.query_selector_exists(selector) {
          doc.query_selector_ffi(selector)
        } else {
          element
        }
      }
    None => element
  }
}

///|
/// Get swap options from element attributes
fn get_swap_options(
  element : @ffi.Element,
  config : @event.ElementConfig,
) -> @swap_spec.SwapOptions {
  if element.has_attribute("mx-swap") {
    @swap_spec.SwapOptions::parse(element.get_attribute("mx-swap"))
  } else {
    @swap_spec.SwapOptions::with_strategy(config.swap)
  }
}

///|
/// Global MHX instance (singleton pattern)
let global_mhx : Mhx = Mhx::new()

///|
/// Initialize the global MHX instance
pub fn init_mhx() -> Unit {
  global_mhx.init_mhx()
}

///|
/// Get the global MHX instance
pub fn get_instance() -> Mhx {
  global_mhx
}

///|
/// Process new elements added to the DOM
/// Call this after dynamically adding HTML
pub fn process(root : @ffi.Element) -> Unit {
  global_mhx.process_tree(root)
}

///|
/// Handle an event from JS
/// This is the main entry point called from the JS event listener
pub fn handle_event(event : @ffi.Event, target : @ffi.Element) -> Unit {
  global_mhx.handle_event(event, target)
}

///|
/// Register default event listeners on the document
fn register_default_event_listeners() -> Unit {
  let doc = @ffi.document()
  for event_type in @event.default_events {
    doc.add_event_listener(event_type, fn(event) {
      if event.has_target() {
        let target = event.target_ffi()
        if not(target.is_null()) {
          handle_event(event, target)
        }
      }
    })
  }
}

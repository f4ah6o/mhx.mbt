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
  /// Whether mhx has been initialized
  mut initialized : Bool
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
    initialized: false,
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
  let config : @event.ElementConfig = try {
    @event.parse_element_config(element)
  } catch {
    _ => {
      // Log error and skip this element
      @ffi.console_error("mhx: Failed to parse element configuration")
      return
    }
  }
  // Store configuration
  self.cache.set(element_id, config)
}

///|
/// Simple hash function for element identification
fn hash_element(element : @ffi.Element) -> Int {
  let id = element.id()
  let tag = element.tag_name()
  let combined = tag + "#" + id
  // Simple string hash
  let mut hash = 0
  for c in combined.iter() {
    hash = hash * 31 + c.to_int()
  }
  hash
}

///|
/// Handle an event (called from JS event listener)
pub fn Mhx::handle_event(
  self : Mhx,
  event : @ffi.Event,
  target : @ffi.Element
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
          let parsed : @event.ElementConfig? = try {
            Some(@event.parse_element_config(current))
          } catch {
            _ =>
              // Skip invalid elements
              None
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
        Some(cfg) => {
          // Check if any trigger matches this event
          for trigger in cfg.triggers {
            if @event.trigger_matches_event(trigger, event_type) {
              // Check filter conditions
              if @event.check_filter_conditions(trigger, event) {
                // Execute the action
                self.execute_action(current, cfg, trigger, event)
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
/// Execute an action for a matched trigger
fn Mhx::execute_action(
  self : Mhx,
  element : @ffi.Element,
  config : @event.ElementConfig,
  _trigger : @trigger.TriggerDef,
  event : @ffi.Event
) -> Unit {
  // Handle prevent modifier (preventDefault)
  event.prevent_default()
  // Determine the URL and method
  let url = config.url
  if url.is_empty() {
    return
  }
  // Build request options
  let options = build_request_options(element, config)
  // Determine sync strategy
  let sync_strategy = get_sync_strategy(element)
  // Schedule the request
  let element_hash = hash_element(element)
  let element_id = self.cache.get_element_id(element_hash)
  let result = self.request_manager.schedule(
    element_id,
    url,
    options,
    sync_strategy,
  )
  match result {
    @network.ScheduleResult::Execute(task) => {
      // Add loading indicator
      element.add_class("mx-request")
      // Execute the request
      self.execute_request(element, task, config)
    }
    @network.ScheduleResult::Queued => {
      // Request is queued, will be executed later
      ()
    }
    @network.ScheduleResult::Dropped => {
      // Request was dropped due to sync strategy
      ()
    }
  }
}

///|
/// Build request options from element configuration
fn build_request_options(
  element : @ffi.Element,
  config : @event.ElementConfig
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
    headers: {
      "HX-Request": "true",
    },
    body: Option::None,
    signal: Option::None,
  }
  // For POST/PUT/PATCH, collect form data
  match config.http_method {
    @event.HttpMethod::Post | @event.HttpMethod::Put | @event.HttpMethod::Patch => {
      // Check if element is a form or find closest form
      let tag = element.tag_name()
      let body_data = if tag == "FORM" {
        collect_form_data(element)
      } else if element.closest_exists("form") {
        collect_form_data(element.closest_ffi("form"))
      } else {
        // Check for mx-vals attribute
        if element.has_attribute("mx-vals") {
          element.get_attribute("mx-vals")
        } else {
          ""
        }
      }
      if not(body_data.is_empty()) {
        options = { ..options, body: Some(body_data) }
        options = options.with_header(
          "Content-Type",
          "application/x-www-form-urlencoded",
        )
      }
    }
    _ => ()
  }
  // Add HX-Trigger header
  if element.has_attribute("id") {
    options = options.with_header("HX-Trigger", element.id())
  }
  options
}

///|
/// Collect form data from a form element
fn collect_form_data(form : @ffi.Element) -> String {
  let form_data = @ffi.JsFormData::from_element(form)
  form_data.to_url_encoded()
}

///|
/// Get sync strategy from element attributes
fn get_sync_strategy(element : @ffi.Element) -> @network.SyncStrategy {
  if element.has_attribute("mx-sync") {
    @network.parse_sync_strategy(element.get_attribute("mx-sync"))
  } else {
    @network.SyncStrategy::Drop // default
  }
}

///|
/// Execute an HTTP request and handle the response
fn Mhx::execute_request(
  self : Mhx,
  element : @ffi.Element,
  task : @network.RequestTask,
  config : @event.ElementConfig
) -> Unit {
  // In a real implementation, this would be async
  // For now, we'll set up the structure for future async support
  // The actual fetch would be called here and the response handled below

  // This is a placeholder - actual implementation would use:
  // let promise = @ffi.js_fetch(task.url, task.options.to_json_string())
  // And then handle the promise resolution

  // For now, log that we would make a request
  @ffi.console_log(
    "mhx: Would request " + task.options.http_method + " " + task.url,
  )
  // Remove loading indicator (in real impl, this happens after response)
  element.remove_class("mx-request")
  // The response handling logic:
  // 1. Parse response body as HTML
  // 2. Find target element (self or mx-target)
  // 3. Perform swap operation

  // Placeholder for swap target resolution
  let _swap_target = resolve_swap_target(element, config)
  let _swap_options = get_swap_options(element, config)
  // In real implementation:
  // @swap.perform_swap(swap_target, response_body, swap_options)

  // Complete the request in the manager
  let element_hash = hash_element(element)
  let element_id = self.cache.get_element_id(element_hash)
  let _next = self.request_manager.complete(element_id, task.id)
  // If there's a next request, execute it
  // match next {
  //   Some(next_task) => self.execute_request(element, next_task, config)
  //   None => ()
  // }
}

///|
/// Resolve the swap target element
fn resolve_swap_target(
  element : @ffi.Element,
  config : @event.ElementConfig
) -> @ffi.Element {
  match config.target {
    Some(selector) => {
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
    }
    None => element
  }
}

///|
/// Get swap options from element attributes
fn get_swap_options(
  element : @ffi.Element,
  config : @event.ElementConfig
) -> @swap.SwapOptions {
  if element.has_attribute("mx-swap") {
    @swap.SwapOptions::parse(element.get_attribute("mx-swap"))
  } else {
    // Convert from config
    let strategy = match config.swap {
      @event.SwapStrategy::InnerHTML => @swap.Strategy::InnerHTML
      @event.SwapStrategy::OuterHTML => @swap.Strategy::OuterHTML
      @event.SwapStrategy::BeforeBegin => @swap.Strategy::BeforeBegin
      @event.SwapStrategy::AfterBegin => @swap.Strategy::AfterBegin
      @event.SwapStrategy::BeforeEnd => @swap.Strategy::BeforeEnd
      @event.SwapStrategy::AfterEnd => @swap.Strategy::AfterEnd
      @event.SwapStrategy::Delete => @swap.Strategy::Delete
      @event.SwapStrategy::None_ => @swap.Strategy::None_
    }
    @swap.SwapOptions::with_strategy(strategy)
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

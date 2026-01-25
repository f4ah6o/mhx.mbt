///|
/// Event handler dispatch logic
/// Implements the core event handling flow

///|
/// mhx attribute prefix
pub let attr_prefix : String = "mx-"

///|
/// Check if an element has any mhx attributes
pub fn has_mhx_attributes(element : @ffi.Element) -> Bool {
  element.has_attribute("mx-get") ||
  element.has_attribute("mx-post") ||
  element.has_attribute("mx-put") ||
  element.has_attribute("mx-patch") ||
  element.has_attribute("mx-delete") ||
  element.has_attribute("mx-trigger")
}

///|
/// Get the HTTP method and URL from element attributes
pub fn get_request_info(element : @ffi.Element) -> (HttpMethod, String)? {
  if element.has_attribute("mx-get") {
    Some((HttpMethod::Get, element.get_attribute("mx-get")))
  } else if element.has_attribute("mx-post") {
    Some((HttpMethod::Post, element.get_attribute("mx-post")))
  } else if element.has_attribute("mx-put") {
    Some((HttpMethod::Put, element.get_attribute("mx-put")))
  } else if element.has_attribute("mx-patch") {
    Some((HttpMethod::Patch, element.get_attribute("mx-patch")))
  } else if element.has_attribute("mx-delete") {
    Some((HttpMethod::Delete, element.get_attribute("mx-delete")))
  } else {
    None
  }
}

///|
/// Parse element configuration from attributes
pub fn parse_element_config(
  element : @ffi.Element,
) -> ElementConfig raise @parser.ParseError {
  // Get HTTP method and URL
  let (http_method, url) = match get_request_info(element) {
    Some(info) => info
    None => (HttpMethod::Get, "")
  }
  // Parse trigger
  let trigger_str = if element.has_attribute("mx-trigger") {
    element.get_attribute("mx-trigger")
  } else {
    // Default trigger based on element type
    let tag = element.tag_name()
    match tag {
      "FORM" => "submit"
      "INPUT" | "TEXTAREA" | "SELECT" => "change"
      _ => "click"
    }
  }
  let triggers = @parser.parse_trigger(trigger_str)
  // Parse swap strategy
  let swap = if element.has_attribute("mx-swap") {
    parse_swap_strategy(element.get_attribute("mx-swap"))
  } else {
    SwapStrategy::InnerHTML
  }
  // Parse target
  let target = if element.has_attribute("mx-target") {
    Some(element.get_attribute("mx-target"))
  } else {
    None
  }
  { triggers, http_method, url, swap, target, processed: true }
}

///|
/// Check if a trigger matches the current event
pub fn trigger_matches_event(
  trigger : @trigger.TriggerDef,
  event_type : String,
) -> Bool {
  trigger.event_name == event_type
}

///|
/// Check if trigger filter conditions are satisfied
/// Note: Filter conditions are JavaScript expressions, which would need FFI eval
/// For now, we return true (no filtering)
pub fn check_filter_conditions(
  _trigger : @trigger.TriggerDef,
  _event : @ffi.Event,
) -> Bool {
  // TODO: Implement filter evaluation via FFI
  // This would require calling JavaScript to eval the filter expression
  true
}

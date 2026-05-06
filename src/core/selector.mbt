///|
/// Trigger selector resolution

///|
/// Resolve swap target element for a trigger.
fn resolve_swap_target_from_trigger(
  element : @ffi.Element,
  trigger : @trigger.TriggerDef,
  config : @event.ElementConfig,
) -> @ffi.Element? {
  match trigger.get_target() {
    Some(selector) => resolve_selector(element, selector)
    None => resolve_swap_target(element, config)
  }
}

///|
/// Resolve a trigger selector to an element.
fn resolve_selector(
  element : @ffi.Element,
  selector : @trigger.Selector,
) -> @ffi.Element? {
  let doc = @ffi.document()
  match selector {
    @trigger.Selector::This => Some(element)
    @trigger.Selector::Body => Some(doc.body_ffi())
    @trigger.Selector::Document => Some(doc.document_element_ffi())
    @trigger.Selector::Window => None
    @trigger.Selector::Closest(sel) =>
      if sel.is_empty() {
        None
      } else if element.closest_exists(sel) {
        Some(element.closest_ffi(sel))
      } else {
        None
      }
    @trigger.Selector::Find(sel) =>
      if sel.is_empty() {
        None
      } else if element.query_selector_exists(sel) {
        Some(element.query_selector_ffi(sel))
      } else {
        None
      }
    @trigger.Selector::Next(sel) => find_adjacent_sibling(element, sel, true)
    @trigger.Selector::Previous(sel) =>
      find_adjacent_sibling(element, sel, false)
    @trigger.Selector::Css(sel) =>
      if sel.is_empty() {
        None
      } else if doc.query_selector_exists(sel) {
        Some(doc.query_selector_ffi(sel))
      } else {
        None
      }
  }
}

///|
/// Find the next/previous sibling matching selector.
fn find_adjacent_sibling(
  element : @ffi.Element,
  selector : String,
  forward : Bool,
) -> @ffi.Element? {
  if selector.is_empty() || !element.has_parent() {
    return None
  }
  let parent = element.parent_element_ffi()
  if parent.is_null() {
    return None
  }
  let count = parent.child_count()
  if count <= 0 {
    return None
  }
  let mut index = find_child_index(parent, element)
  if index < 0 {
    return None
  }
  if forward {
    index += 1
    while index < count {
      let candidate = parent.child_at(index)
      if !candidate.is_null() && candidate.matches(selector) {
        return Some(candidate)
      }
      index += 1
    }
  } else {
    index -= 1
    while index >= 0 {
      let candidate = parent.child_at(index)
      if !candidate.is_null() && candidate.matches(selector) {
        return Some(candidate)
      }
      index -= 1
    }
  }
  None
}

///|
/// Find the index of a child element within its parent.
fn find_child_index(parent : @ffi.Element, child : @ffi.Element) -> Int {
  let count = parent.child_count()
  for i = 0; i < count; i = i + 1 {
    let candidate = parent.child_at(i)
    if candidate.same(child) {
      return i
    }
  }
  -1
}

///|
/// Resolve the config target selector to an element.
fn resolve_swap_target(
  element : @ffi.Element,
  config : @event.ElementConfig,
) -> @ffi.Element? {
  match config.target {
    Some(selector) => resolve_swap_target_string(element, selector)
    None => Some(element)
  }
}

///|
fn resolve_swap_target_string(
  element : @ffi.Element,
  selector : String,
) -> @ffi.Element? {
  let trimmed = selector.trim().to_string()
  if trimmed.is_empty() {
    return None
  }
  let doc = @ffi.document()
  if trimmed == "this" {
    Some(element)
  } else if trimmed == "body" {
    Some(doc.body_ffi())
  } else if trimmed == "document" {
    Some(doc.document_element_ffi())
  } else if trimmed == "window" {
    None
  } else if trimmed.has_prefix("closest ") {
    let inner = trimmed.view(start_offset=8).to_string().trim().to_string()
    if inner.is_empty() {
      None
    } else if element.closest_exists(inner) {
      Some(element.closest_ffi(inner))
    } else {
      None
    }
  } else if trimmed.has_prefix("find ") {
    let inner = trimmed.view(start_offset=5).to_string().trim().to_string()
    if inner.is_empty() {
      None
    } else if element.query_selector_exists(inner) {
      Some(element.query_selector_ffi(inner))
    } else {
      None
    }
  } else if trimmed.has_prefix("next ") {
    let inner = trimmed.view(start_offset=5).to_string().trim().to_string()
    find_adjacent_sibling(element, inner, true)
  } else if trimmed.has_prefix("previous ") {
    let inner = trimmed.view(start_offset=9).to_string().trim().to_string()
    find_adjacent_sibling(element, inner, false)
  } else if doc.query_selector_exists(trimmed) {
    Some(doc.query_selector_ffi(trimmed))
  } else {
    None
  }
}

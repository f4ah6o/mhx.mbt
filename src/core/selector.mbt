///|
/// Trigger selector resolution

///|
/// Resolve swap target element for a trigger
fn resolve_swap_target_from_trigger(
  element : @ffi.Element,
  trigger : @trigger.TriggerDef,
  config : @event.ElementConfig,
) -> @ffi.Element {
  match trigger.get_target() {
    Some(sel) => resolve_selector(element, sel)
    None => resolve_swap_target(element, config)
  }
}

///|
/// Resolve a trigger selector to an element
fn resolve_selector(
  element : @ffi.Element,
  selector : @trigger.Selector,
) -> @ffi.Element {
  match selector {
    @trigger.Selector::This => element
    @trigger.Selector::Body => @ffi.document().body_ffi()
    @trigger.Selector::Document => @ffi.document().document_element_ffi()
    @trigger.Selector::Window => element
    @trigger.Selector::Closest(sel) =>
      if element.closest_exists(sel) {
        element.closest_ffi(sel)
      } else {
        element
      }
    @trigger.Selector::Find(sel) =>
      if element.query_selector_exists(sel) {
        element.query_selector_ffi(sel)
      } else {
        element
      }
    @trigger.Selector::Next(sel) => find_adjacent_sibling(element, sel, true)
    @trigger.Selector::Previous(sel) =>
      find_adjacent_sibling(element, sel, false)
    @trigger.Selector::Css(sel) => {
      let doc = @ffi.document()
      if doc.query_selector_exists(sel) {
        doc.query_selector_ffi(sel)
      } else {
        element
      }
    }
  }
}

///|
/// Find the next/previous sibling matching selector
fn find_adjacent_sibling(
  element : @ffi.Element,
  selector : String,
  forward : Bool,
) -> @ffi.Element {
  let parent = if element.has_parent() {
    element.parent_element_ffi()
  } else {
    return element
  }
  if parent.is_null() {
    return element
  }
  let count = parent.child_count()
  if count <= 0 {
    return element
  }
  let mut index = find_child_index(parent, element)
  if index < 0 {
    return element
  }
  if forward {
    index += 1
    while index < count {
      let candidate = parent.child_at(index)
      if not(candidate.is_null()) && candidate.matches(selector) {
        return candidate
      }
      index += 1
    }
  } else {
    index -= 1
    while index >= 0 {
      let candidate = parent.child_at(index)
      if not(candidate.is_null()) && candidate.matches(selector) {
        return candidate
      }
      index -= 1
    }
  }
  element
}

///|
/// Find the index of a child element within its parent
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

///|
/// DOM swap operations for mhx
/// Implements the mx-swap attribute strategies

///|
/// Swap strategy enum (mirrors event/cache.mbt but standalone)
pub(all) enum Strategy {
  /// Replace innerHTML of target
  InnerHTML
  /// Replace the entire target element (outerHTML)
  OuterHTML
  /// Insert before the target element
  BeforeBegin
  /// Insert at the start of target's children
  AfterBegin
  /// Insert at the end of target's children
  BeforeEnd
  /// Insert after the target element
  AfterEnd
  /// Remove the target element
  Delete
  /// Do nothing with the response
  None_
} derive(Show, Eq)

///|
/// Parse a swap strategy from string
pub fn Strategy::from_string(s : String) -> Strategy {
  match s.to_lower().trim().to_string() {
    "innerhtml" => InnerHTML
    "outerhtml" => OuterHTML
    "beforebegin" => BeforeBegin
    "afterbegin" => AfterBegin
    "beforeend" => BeforeEnd
    "afterend" => AfterEnd
    "delete" => Delete
    "none" => None_
    _ => InnerHTML // default
  }
}

///|
/// Extended swap options with timing and scroll control
pub(all) struct SwapOptions {
  /// The swap strategy
  strategy : Strategy
  /// Delay before swap in milliseconds
  swap_delay : Int
  /// Delay before settling in milliseconds
  settle_delay : Int
  /// Scroll behavior: "top", "bottom", or empty for no scroll
  scroll : String
  /// Whether to scroll target into view
  show : String
  /// Focus scroll: scroll to focused element
  focus_scroll : Bool
} derive(Show)

///|
/// Create default swap options
pub fn SwapOptions::default() -> SwapOptions {
  {
    strategy: Strategy::InnerHTML,
    swap_delay: 0,
    settle_delay: 20,
    scroll: "",
    show: "",
    focus_scroll: false,
  }
}

///|
/// Create swap options with a specific strategy
pub fn SwapOptions::with_strategy(strategy : Strategy) -> SwapOptions {
  { ..SwapOptions::default(), strategy, }
}

///|
/// Parse swap options from mx-swap attribute value
/// Format: "strategy [modifier:value ...]"
/// e.g., "innerHTML swap:500ms settle:1s scroll:top"
pub fn SwapOptions::parse(value : String) -> SwapOptions {
  let trimmed = value.trim().to_string()
  if trimmed.is_empty() {
    return SwapOptions::default()
  }
  // Split by whitespace using split
  let parts : Array[String] = trimmed
    .split(" ")
    .filter(fn(sv) { not(sv.is_empty()) })
    .map(fn(sv) { sv.to_string() })
    .collect()
  if parts.is_empty() {
    return SwapOptions::default()
  }
  // First part is the strategy
  let strategy = Strategy::from_string(parts[0])
  let mut options = SwapOptions::with_strategy(strategy)
  // Parse remaining modifiers
  for i = 1; i < parts.length(); i = i + 1 {
    let part = parts[i]
    match part.find(":") {
      Some(colon_idx) => {
        let modifier = part.view(end_offset=colon_idx).to_string()
        let value = part.view(start_offset=colon_idx + 1).to_string()
        match modifier {
          "swap" => options = { ..options, swap_delay: parse_time_ms(value) }
          "settle" =>
            options = { ..options, settle_delay: parse_time_ms(value) }
          "scroll" => options = { ..options, scroll: value }
          "show" => options = { ..options, show: value }
          "focus-scroll" =>
            options = { ..options, focus_scroll: value == "true" }
          _ => () // ignore unknown modifiers
        }
      }
      None => ()
    }
  }
  options
}

///|
/// Parse time string to milliseconds
/// Supports: "500ms", "1s", "1.5s", or plain number as ms
fn parse_time_ms(s : String) -> Int {
  let trimmed = s.trim().to_string()
  if trimmed.has_suffix("ms") {
    let num_str = trimmed.view(end_offset=trimmed.length() - 2).to_string()
    parse_int_or(num_str, 0)
  } else if trimmed.has_suffix("s") {
    let num_str = trimmed.view(end_offset=trimmed.length() - 1).to_string()
    // Handle decimals like "1.5s"
    match num_str.find(".") {
      Some(dot_idx) => {
        let whole = parse_int_or(
          num_str.view(end_offset=dot_idx).to_string(),
          0,
        )
        let frac_str = num_str.view(start_offset=dot_idx + 1).to_string()
        let frac = parse_int_or(frac_str, 0)
        // Convert to ms: whole * 1000 + frac * (1000 / 10^len)
        let frac_len = frac_str.length()
        let divisor = pow10(frac_len)
        whole * 1000 + frac * 1000 / divisor
      }
      None => parse_int_or(num_str, 0) * 1000
    }
  } else {
    parse_int_or(trimmed, 0)
  }
}

///|
/// Simple power of 10
fn pow10(n : Int) -> Int {
  let mut result = 1
  for _i = 0; _i < n; _i = _i + 1 {
    result = result * 10
  }
  result
}

///|
/// Parse int or return default
fn parse_int_or(s : String, default_val : Int) -> Int {
  @strconv.parse_int(s) catch {
    _ => default_val
  }
}

///|
/// Perform a swap operation on a target element
pub fn perform_swap(
  target : @ffi.Element,
  content : String,
  options : SwapOptions,
) -> Unit {
  match options.strategy {
    InnerHTML => target.set_inner_html(content)
    OuterHTML => target.set_outer_html(content)
    BeforeBegin => target.insert_adjacent_html("beforebegin", content)
    AfterBegin => target.insert_adjacent_html("afterbegin", content)
    BeforeEnd => target.insert_adjacent_html("beforeend", content)
    AfterEnd => target.insert_adjacent_html("afterend", content)
    Delete => target.remove()
    None_ => () // do nothing
  }
}

///|
/// Perform a simple swap with default options
pub fn swap_inner_html(target : @ffi.Element, content : String) -> Unit {
  target.set_inner_html(content)
}

///|
/// Perform a swap replacing the entire element
pub fn swap_outer_html(target : @ffi.Element, content : String) -> Unit {
  target.set_outer_html(content)
}

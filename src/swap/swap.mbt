///|
/// DOM swap operations for mhx
/// Implements the mx-swap attribute strategies

///|
/// Swap options alias for runtime
type SwapOptions = @swap_spec.SwapOptions

///|
/// Perform a swap operation on a target element
pub fn perform_swap(
  target : @ffi.Element,
  content : String,
  options : SwapOptions,
) -> Unit {
  match options.strategy {
    @swap_spec.Strategy::InnerHTML => target.set_inner_html(content)
    @swap_spec.Strategy::OuterHTML => target.set_outer_html(content)
    @swap_spec.Strategy::BeforeBegin =>
      target.insert_adjacent_html("beforebegin", content)
    @swap_spec.Strategy::AfterBegin =>
      target.insert_adjacent_html("afterbegin", content)
    @swap_spec.Strategy::BeforeEnd =>
      target.insert_adjacent_html("beforeend", content)
    @swap_spec.Strategy::AfterEnd =>
      target.insert_adjacent_html("afterend", content)
    @swap_spec.Strategy::Delete => target.remove()
    @swap_spec.Strategy::None_ => () // do nothing
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

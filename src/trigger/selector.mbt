///|
/// Selector types for targeting elements in trigger definitions
/// Used in modifiers like `from:`, `target:`, etc.

///|
/// Represents a CSS selector or special element reference
pub(all) enum Selector {
  /// The element itself (default)
  This
  /// document.body
  Body
  /// window object
  Window
  /// document object
  Document
  /// Find closest ancestor matching selector
  Closest(String)
  /// Find descendant matching selector
  Find(String)
  /// Find next sibling matching selector
  Next(String)
  /// Find previous sibling matching selector
  Previous(String)
  /// Arbitrary CSS selector
  Css(String)
} derive(Show, Eq)

///|
pub impl ToJson for Selector with to_json(self) {
  match self {
    This => "this".to_json()
    Body => "body".to_json()
    Window => "window".to_json()
    Document => "document".to_json()
    Closest(s) => { "closest": s.to_json() }
    Find(s) => { "find": s.to_json() }
    Next(s) => { "next": s.to_json() }
    Previous(s) => { "previous": s.to_json() }
    Css(s) => { "css": s.to_json() }
  }
}

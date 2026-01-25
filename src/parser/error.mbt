///|
/// Parse error types with position information
/// Provides detailed error messages for debugging

///|
/// Position in the input string
pub(all) struct Position {
  offset : Int
  /// The character at this position (if available)
  char : Char
} derive(Show, Eq)

///|
pub impl ToJson for Position with to_json(self) {
  { "offset": self.offset.to_json(), "char": self.char.to_string().to_json() }
}

///|
/// Parse error with position and message
pub(all) suberror ParseError {
  UnexpectedChar(pos~ : Position, expected~ : String)
  UnexpectedEnd(pos~ : Position, expected~ : String)
  InvalidNumber(pos~ : Position, value~ : String)
  InvalidModifier(pos~ : Position, name~ : String)
  InvalidSelector(pos~ : Position, value~ : String)
} derive(Show, Eq)

///|
pub impl ToJson for ParseError with to_json(self) {
  match self {
    UnexpectedChar(pos~, expected~) =>
      {
        "type": "UnexpectedChar",
        "pos": pos.to_json(),
        "expected": expected.to_json(),
      }
    UnexpectedEnd(pos~, expected~) =>
      {
        "type": "UnexpectedEnd",
        "pos": pos.to_json(),
        "expected": expected.to_json(),
      }
    InvalidNumber(pos~, value~) =>
      {
        "type": "InvalidNumber",
        "pos": pos.to_json(),
        "value": value.to_json(),
      }
    InvalidModifier(pos~, name~) =>
      {
        "type": "InvalidModifier",
        "pos": pos.to_json(),
        "name": name.to_json(),
      }
    InvalidSelector(pos~, value~) =>
      {
        "type": "InvalidSelector",
        "pos": pos.to_json(),
        "value": value.to_json(),
      }
  }
}

///|
/// Create a position at the given offset
pub fn Position::at(offset : Int, input : String) -> Position {
  let char = if offset < input.length() {
    match input.get_char(offset) {
      Some(c) => c
      None => '\u0000'
    }
  } else {
    '\u0000'
  }
  { offset, char }
}

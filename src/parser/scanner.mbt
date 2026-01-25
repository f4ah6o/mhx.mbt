///|
/// Scanner for tokenizing trigger attribute values
/// Provides character-level access with position tracking

///|
/// Known modifier keywords
let modifier_keywords : Array[String] = [
  "once", "changed", "consume", "prevent", "delay", "throttle", "debounce", "from",
  "target", "queue",
]

///|
/// Scanner state for parsing
pub struct Scanner {
  input : String
  mut pos : Int
} derive(Show)

///|
/// Create a new scanner for the input string
pub fn Scanner::new(input : String) -> Scanner {
  { input, pos: 0 }
}

///|
/// Check if we've reached the end of input
pub fn Scanner::is_eof(self : Scanner) -> Bool {
  self.pos >= self.input.length()
}

///|
/// Get current position
pub fn Scanner::position(self : Scanner) -> Int {
  self.pos
}

///|
/// Get the current character without advancing
pub fn Scanner::peek(self : Scanner) -> Char? {
  if self.is_eof() {
    None
  } else {
    self.input.get_char(self.pos)
  }
}

///|
/// Get the current character (returns '\u0000' if at end)
pub fn Scanner::current(self : Scanner) -> Char {
  match self.peek() {
    Some(c) => c
    None => '\u0000'
  }
}

///|
/// Advance one character
pub fn Scanner::advance(self : Scanner) -> Unit {
  if self.pos < self.input.length() {
    self.pos += 1
  }
}

///|
/// Skip whitespace characters
pub fn Scanner::skip_whitespace(self : Scanner) -> Unit {
  while not(self.is_eof()) {
    match self.peek() {
      Some(' ' | '\t' | '\n' | '\r') => self.advance()
      _ => break
    }
  }
}

///|
/// Check if current character matches
pub fn Scanner::check(self : Scanner, c : Char) -> Bool {
  match self.peek() {
    Some(ch) => ch == c
    None => false
  }
}

///|
/// Consume a specific character or return error
pub fn Scanner::expect(self : Scanner, c : Char) -> Unit raise ParseError {
  if self.is_eof() {
    raise UnexpectedEnd(
      pos=Position::at(self.pos, self.input),
      expected=c.to_string(),
    )
  }
  match self.peek() {
    Some(ch) if ch == c => self.advance()
    Some(_) =>
      raise UnexpectedChar(
        pos=Position::at(self.pos, self.input),
        expected=c.to_string(),
      )
    None =>
      raise UnexpectedEnd(
        pos=Position::at(self.pos, self.input),
        expected=c.to_string(),
      )
  }
}

///|
/// Try to consume a specific character, returns true if consumed
pub fn Scanner::try_consume(self : Scanner, c : Char) -> Bool {
  if self.check(c) {
    self.advance()
    true
  } else {
    false
  }
}

///|
/// Check if character is a letter
fn is_letter(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
/// Check if character is a digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Check if character is alphanumeric or hyphen/underscore
fn is_ident_char(c : Char) -> Bool {
  is_letter(c) || is_digit(c) || c == '-' || c == '_'
}

///|
/// Check if string is a modifier keyword
fn is_modifier_keyword(s : String) -> Bool {
  modifier_keywords.iter().any(fn(k) { k == s })
}

///|
/// Scan an identifier (letters, digits, hyphens, underscores)
pub fn Scanner::scan_identifier(self : Scanner) -> String {
  let start = self.pos
  while not(self.is_eof()) {
    match self.peek() {
      Some(c) if is_ident_char(c) => self.advance()
      _ => break
    }
  }
  try! self.input[start:self.pos].to_string()
}

///|
/// Peek at the next word without consuming it
pub fn Scanner::peek_word(self : Scanner) -> String {
  let saved_pos = self.pos
  self.skip_whitespace()
  let word = self.scan_identifier()
  self.pos = saved_pos
  word
}

///|
/// Check if the next word is a modifier keyword or colon follows it
pub fn Scanner::is_at_modifier_start(self : Scanner) -> Bool {
  let saved_pos = self.pos
  self.skip_whitespace()
  let word = self.scan_identifier()
  // Check if it's a keyword and either is a simple modifier or has ':'
  let result = if is_modifier_keyword(word) {
    // Simple modifiers don't need :
    match word {
      "once" | "changed" | "consume" | "prevent" => true
      _ => {
        // Complex modifiers need :
        self.skip_whitespace()
        self.check(':')
      }
    }
  } else {
    false
  }
  self.pos = saved_pos
  result
}

///|
/// Scan an integer
pub fn Scanner::scan_int(self : Scanner) -> Int raise ParseError {
  let start = self.pos
  while not(self.is_eof()) {
    match self.peek() {
      Some(c) if is_digit(c) => self.advance()
      _ => break
    }
  }
  let num_str = try! self.input[start:self.pos].to_string()
  if num_str.is_empty() {
    raise InvalidNumber(pos=Position::at(start, self.input), value=num_str)
  }
  // Parse integer manually
  let mut result = 0
  for c in num_str {
    result = result * 10 + (c.to_int() - '0'.to_int())
  }
  result
}

///|
/// Scan until a specific character (not including that character)
pub fn Scanner::scan_until(self : Scanner, end_char : Char) -> String {
  let start = self.pos
  while not(self.is_eof()) {
    match self.peek() {
      Some(c) if c == end_char => break
      Some(_) => self.advance()
      None => break
    }
  }
  try! self.input[start:self.pos].to_string()
}

///|
/// Scan a bracketed expression [...]
pub fn Scanner::scan_bracketed(self : Scanner) -> String raise ParseError {
  self.expect('[')
  let content = self.scan_until(']')
  self.expect(']')
  content
}

///|
/// Scan a CSS selector value, reading until we hit a modifier keyword or comma
/// This handles multi-word selectors like "closest .parent"
pub fn Scanner::scan_selector_value(self : Scanner) -> String {
  let start = self.pos
  let mut depth = 0
  while not(self.is_eof()) {
    // Check for comma (separator)
    if self.check(',') && depth == 0 {
      break
    }
    // Check for opening bracket (filter starts)
    if self.check('[') && depth == 0 {
      break
    }
    // Check for next modifier keyword
    if depth == 0 && self.is_at_modifier_start() {
      break
    }
    match self.peek() {
      Some('(') => {
        depth += 1
        self.advance()
      }
      Some(')') => {
        depth -= 1
        self.advance()
      }
      Some(_) => self.advance()
      None => break
    }
  }
  (try! self.input[start:self.pos].to_string()).trim().to_string()
}

///|
/// Get a Position for error reporting
pub fn Scanner::make_position(self : Scanner) -> Position {
  Position::at(self.pos, self.input)
}

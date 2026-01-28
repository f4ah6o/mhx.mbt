///|
/// Request body composition helpers

///|
/// Build request body from form data and mx-vals
fn build_request_body(
  element : @ffi.Element,
  config : @event.ElementConfig,
) -> String {
  let form_values = if element.tag_name() == "FORM" {
    collect_form_data(element)
  } else if element.closest_exists("form") {
    collect_form_data(element.closest_ffi("form"))
  } else {
    ""
  }
  let mx_vals_json = match config.vals {
    Some(v) => v
    None =>
      if element.has_attribute("mx-vals") {
        element.get_attribute("mx-vals")
      } else {
        ""
      }
  }
  if mx_vals_json.trim().is_empty() {
    return form_values
  }
  let json_pairs = parse_mx_vals_pairs(mx_vals_json)
  let pairs : Array[(String, String)] = []
  if not(form_values.is_empty()) {
    for item in parse_form_encoded(form_values) {
      pairs.push(item)
    }
  }
  for item in json_pairs {
    pairs.push(item)
  }
  if pairs.is_empty() {
    ""
  } else {
    encode_form_pairs(pairs)
  }
}

///|
/// Merge form-encoded body with mx-vals JSON
pub fn merge_request_bodies(
  form_body : String,
  mx_vals_json : String,
) -> String {
  let pairs : Array[(String, String)] = []
  if not(form_body.is_empty()) {
    for item in parse_form_encoded(form_body) {
      pairs.push(item)
    }
  }
  for item in parse_mx_vals_pairs(mx_vals_json) {
    pairs.push(item)
  }
  if pairs.is_empty() {
    ""
  } else {
    encode_form_pairs(pairs)
  }
}

///|
/// Merge mx-vals into an existing JSON object string
fn merge_vals_json(base_json : String, mx_vals_json : String) -> String {
  let base_pairs = parse_mx_vals_pairs(base_json)
  let result : Map[String, String] = {}
  for pair in base_pairs {
    let (k, v) = pair
    result[k] = v
  }
  for pair in parse_mx_vals_pairs(mx_vals_json) {
    let (k, v) = pair
    result[k] = v
  }
  if result.length() == 0 {
    "{}"
  } else {
    json_object_string(result)
  }
}

///|
/// Parse application/x-www-form-urlencoded into pairs
fn parse_form_encoded(body : String) -> Array[(String, String)] {
  let pairs : Array[(String, String)] = []
  if body.is_empty() {
    return pairs
  }
  for part in body.split("&") {
    if part.is_empty() {
      continue
    }
    match part.find("=") {
      Some(idx) => {
        let key = part.view(end_offset=idx).to_string()
        let value = part.view(start_offset=idx + 1).to_string()
        pairs.push((decode_url_component(key), decode_url_component(value)))
      }
      None => pairs.push((decode_url_component(part.to_string()), ""))
    }
  }
  pairs
}

///|
/// Parse mx-vals JSON into pairs (flat object only)
fn parse_mx_vals_pairs(mx_vals_json : String) -> Array[(String, String)] {
  let pairs : Array[(String, String)] = []
  let trimmed = mx_vals_json.trim().to_string()
  if trimmed.is_empty() {
    return pairs
  }
  if not(trimmed.has_prefix("{") && trimmed.has_suffix("}")) {
    report_error(config_error("mx-vals", "expected JSON object"))
    return pairs
  }
  let inner = trimmed
    .view(start_offset=1, end_offset=trimmed.length() - 1)
    .to_string()
  if inner.trim().is_empty() {
    return pairs
  }
  for part in split_json_pairs(inner) {
    match part.find(":") {
      Some(idx) => {
        let raw_key = part.view(end_offset=idx).to_string().trim().to_string()
        let raw_val = part
          .view(start_offset=idx + 1)
          .to_string()
          .trim()
          .to_string()
        let key = match parse_json_string(raw_key) {
          Some(k) => k
          None => {
            report_error(config_error("mx-vals", "invalid key"))
            ""
          }
        }
        if key != "" {
          match parse_json_value(raw_val) {
            Some(value) => pairs.push((key, value))
            None => ()
          }
        }
      }
      None => ()
    }
  }
  pairs
}

///|
/// Split top-level JSON object entries
fn split_json_pairs(input : String) -> Array[String] {
  let parts : Array[String] = []
  let mut depth = 0
  let mut in_string = false
  let mut escape = false
  let mut start = 0
  let len = input.length()
  let mut i = 0
  while i < len {
    let c = match input.get_char(i) {
      Some(ch) => ch
      None => {
        i += 1
        continue
      }
    }
    if escape {
      escape = false
    } else if c == '\\' && in_string {
      escape = true
    } else if c == '"' {
      in_string = not(in_string)
    } else if not(in_string) {
      if c == '{' || c == '[' {
        depth += 1
      } else if c == '}' || c == ']' {
        depth -= 1
      } else if c == ',' && depth == 0 {
        parts.push(input.view(start_offset=start, end_offset=i).to_string())
        start = i + 1
      }
    }
    i += 1
  }
  if start < len {
    parts.push(input.view(start_offset=start).to_string())
  }
  parts.map(fn(p) { p.trim().to_string() })
}

///|
/// Parse a JSON string literal
fn parse_json_string(raw : String) -> String? {
  let t = raw.trim().to_string()
  if t.length() < 2 || t[0] != '"' || t[t.length() - 1] != '"' {
    None
  } else {
    let inner = t.view(start_offset=1, end_offset=t.length() - 1).to_string()
    Some(unescape_json_string(inner))
  }
}

///|
/// Parse a JSON value (string/number/bool/null)
fn parse_json_value(raw : String) -> String? {
  let t = raw.trim().to_string()
  if t.has_prefix("\"") {
    parse_json_string(t)
  } else if t == "true" || t == "false" || t == "null" {
    Some(t)
  } else {
    // number: accept as-is
    Some(t)
  }
}

///|
/// Encode key/value pairs into application/x-www-form-urlencoded
fn encode_form_pairs(pairs : Array[(String, String)]) -> String {
  let sb = StringBuilder::new()
  let mut first = true
  for pair in pairs {
    let (key, value) = pair
    if not(first) {
      sb.write_char('&')
    }
    first = false
    sb.write_string(encode_url_component(key))
    sb.write_char('=')
    sb.write_string(encode_url_component(value))
  }
  sb.to_string()
}

///|
/// Encode a URL component (minimal form encoding)
fn encode_url_component(value : String) -> String {
  let sb = StringBuilder::new()
  for c in value {
    match c {
      ' ' => sb.write_char('+')
      '%' => sb.write_string("%25")
      '&' => sb.write_string("%26")
      '=' => sb.write_string("%3D")
      '+' => sb.write_string("%2B")
      '\n' => sb.write_string("%0A")
      '\r' => sb.write_string("%0D")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
/// Decode a URL component (minimal form decoding)
fn decode_url_component(value : String) -> String {
  let sb = StringBuilder::new()
  let mut i = 0
  while i < value.length() {
    let c = match value.get_char(i) {
      Some(ch) => ch
      None => {
        i += 1
        continue
      }
    }
    if c == '+' {
      sb.write_char(' ')
      i += 1
    } else if c == '%' && i + 2 < value.length() {
      let hex = value.view(start_offset=i + 1, end_offset=i + 3).to_string()
      match parse_hex_byte(hex) {
        Some(b) => {
          sb.write_char(char_from_byte(b))
          i += 3
        }
        None => {
          sb.write_char(c)
          i += 1
        }
      }
    } else {
      sb.write_char(c)
      i += 1
    }
  }
  sb.to_string()
}

///|
/// Parse a two-digit hex byte
fn parse_hex_byte(hex : String) -> Byte? {
  if hex.length() != 2 {
    return None
  }
  let hi = match hex.get_char(0) {
    Some(ch) => hex_digit_value(ch)
    None => None
  }
  let lo = match hex.get_char(1) {
    Some(ch) => hex_digit_value(ch)
    None => None
  }
  match (hi, lo) {
    (Some(h), Some(l)) => Some((h * 16 + l).to_byte())
    _ => None
  }
}

///|
/// Convert Byte to Char (ASCII range)
fn char_from_byte(b : Byte) -> Char {
  let code : Int = b.to_int()
  match code.to_char() {
    Some(c) => c
    None => '\u0000'
  }
}

///|
/// Convert a hex digit to int
fn hex_digit_value(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
/// Build a JSON object string from map
fn json_object_string(values : Map[String, String]) -> String {
  let sb = StringBuilder::new()
  sb.write_char('{')
  let mut first = true
  for pair in values {
    let (key, value) = pair
    if not(first) {
      sb.write_char(',')
    }
    first = false
    sb.write_char('"')
    sb.write_string(escape_json_string(key))
    sb.write_string("\":")
    if value == "true" ||
      value == "false" ||
      value == "null" ||
      is_number_literal(value) {
      sb.write_string(value)
    } else {
      sb.write_char('"')
      sb.write_string(escape_json_string(value))
      sb.write_char('"')
    }
  }
  sb.write_char('}')
  sb.to_string()
}

///|
/// Check if string looks like a number
fn is_number_literal(value : String) -> Bool {
  if value.is_empty() {
    return false
  }
  let mut dot_seen = false
  for i = 0; i < value.length(); i = i + 1 {
    let c = match value.get_char(i) {
      Some(ch) => ch
      None => continue
    }
    if c == '.' {
      if dot_seen {
        return false
      }
      dot_seen = true
    } else if not(c >= '0' && c <= '9') {
      if i == 0 && (c == '-' || c == '+') {
        continue
      }
      return false
    }
  }
  true
}

///|
/// Escape JSON string
fn escape_json_string(value : String) -> String {
  let sb = StringBuilder::new()
  for c in value {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
/// Unescape JSON string
fn unescape_json_string(value : String) -> String {
  let sb = StringBuilder::new()
  let mut i = 0
  while i < value.length() {
    let c = match value.get_char(i) {
      Some(ch) => ch
      None => {
        i += 1
        continue
      }
    }
    if c == '\\' && i + 1 < value.length() {
      let next = match value.get_char(i + 1) {
        Some(ch) => ch
        None => {
          i += 1
          continue
        }
      }
      match next {
        '"' => sb.write_char('"')
        '\\' => sb.write_char('\\')
        'n' => sb.write_char('\n')
        'r' => sb.write_char('\r')
        't' => sb.write_char('\t')
        _ => sb.write_char(next)
      }
      i += 2
    } else {
      sb.write_char(c)
      i += 1
    }
  }
  sb.to_string()
}

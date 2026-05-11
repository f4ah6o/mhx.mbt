///|
test "validate_target_selector rejects incomplete extended selectors" {
  for selector in ["closest", "find", "next", "previous"] {
    match validate_target_selector(selector, Some("#source")) {
      Some(error) => {
        inspect(error.code(), content="MHX_PARSE_INVALID_SELECTOR")
        match error.attribute() {
          Some(attr) => fail("unexpected attribute: " + attr)
          None => ()
        }
        match error.source_element() {
          Some(source) => inspect(source, content="#source")
          None => fail("expected source_element to be Some")
        }
      }
      None => fail("expected selector validation error")
    }
  }
}

///|
test "validate_target_selector accepts complete extended selectors" {
  for
    selector in [
      "closest .panel", "find button", "next .item", "previous .item", "#result",
      "this",
    ] {
    match validate_target_selector(selector, Some("#source")) {
      Some(error) => fail("unexpected validation error: " + error.code())
      None => ()
    }
  }
}

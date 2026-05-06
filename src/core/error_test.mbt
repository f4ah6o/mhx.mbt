///|
test "config issues preserve stable structured fields" {
  let error = config_issue_error(
    "MHX_VALIDATE_EMPTY_REQUEST_URL",
    "mx-get",
    "Request URL must not be empty",
    Some(@parser.Position::at(0, "")),
    Some("#save"),
  )
  inspect(error.code(), content="MHX_VALIDATE_EMPTY_REQUEST_URL")
  match error.attribute() {
    Some(attr) => inspect(attr, content="mx-get")
    None => fail("expected attribute to be Some")
  }
  match error.source_element() {
    Some(el) => inspect(el, content="#save")
    None => fail("expected source_element to be Some")
  }
  json_inspect(error, content={
    "category": "ConfigError",
    "code": "MHX_VALIDATE_EMPTY_REQUEST_URL",
    "message": "Request URL must not be empty",
    "attribute": ["mx-get"],
    "sourceElement": ["#save"],
    "position": [{ "offset": 0, "char": "\u0000" }],
    "recoverable": true,
  })
}

///|
test "parse errors expose stable codes and positions" {
  let result : Result[Array[@trigger.TriggerDef], @parser.ParseError] = try? @parser.parse_trigger(
    "click [",
  )
  match result {
    Ok(_) => fail("expected parse failure")
    Err(err) => {
      let wrapped = from_parse_error(err)
      inspect(wrapped.code(), content="MHX_PARSE_UNEXPECTED_END")
      match wrapped.attribute() {
        Some(attr) => inspect(attr, content="mx-trigger")
        None => fail("expected attribute to be Some")
      }
      json_inspect(wrapped.position(), content=[
        { "offset": 7, "char": "\u0000" },
      ])
    }
  }
}

///|
test "selector errors report a stable source element" {
  let error = selector_error(
    "closest",
    "Extended selector `closest` requires a trailing selector",
    Some("#source"),
    code="MHX_PARSE_INVALID_SELECTOR",
  )
  inspect(error.code(), content="MHX_PARSE_INVALID_SELECTOR")
  match error.source_element() {
    Some(el) => inspect(el, content="#source")
    None => fail("expected source_element to be Some")
  }
}
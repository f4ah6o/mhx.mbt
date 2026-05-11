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
    "attribute": "mx-get",
    "sourceElement": "#save",
    "position": { "offset": 0, "char": "\u0000" },
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

///|
test "runtime error categories expose stable json shapes" {
  json_inspect(network_error_for_element("/save", "Failed to fetch", "#save"), content={
    "category": "NetworkError",
    "code": "MHX_NETWORK_ERROR",
    "message": "Failed to fetch",
    "attribute": null,
    "sourceElement": "#save",
    "position": null,
    "recoverable": true,
  })
  json_inspect(abort_error_for_element("/save", "#save"), content={
    "category": "AbortError",
    "code": "MHX_ABORT_ERROR",
    "message": "Request to `/save` was aborted",
    "attribute": null,
    "sourceElement": "#save",
    "position": null,
    "recoverable": true,
  })
  json_inspect(timeout_error("/slow", 1500), content={
    "category": "TimeoutError",
    "code": "MHX_TIMEOUT_ERROR",
    "message": "Request to `/slow` exceeded 1500ms",
    "attribute": null,
    "sourceElement": null,
    "position": null,
    "recoverable": true,
  })
  json_inspect(swap_error("#result", "outerHTML", "insert failed"), content={
    "category": "SwapError",
    "code": "MHX_SWAP_ERROR",
    "message": "Swap `outerHTML` failed: insert failed",
    "attribute": null,
    "sourceElement": null,
    "position": null,
    "recoverable": true,
  })
  json_inspect(ffi_error("element.dispatch_mhx_event", "boom"), content={
    "category": "FfiError",
    "code": "MHX_FFI_ERROR",
    "message": "FFI operation `element.dispatch_mhx_event` failed: boom",
    "attribute": null,
    "sourceElement": null,
    "position": null,
    "recoverable": true,
  })
  json_inspect(internal_error("MHX_INTERNAL_ERROR", "invariant failed"), content={
    "category": "InternalError",
    "code": "MHX_INTERNAL_ERROR",
    "message": "invariant failed",
    "attribute": null,
    "sourceElement": null,
    "position": null,
    "recoverable": false,
  })
}

///|
test "error handler receives structured errors" {
  let seen : Array[String] = []
  set_error_handler(fn(error : MhxError) {
    seen.push(error.category() + ":" + error.code())
  })
  report_error(network_error_for_element("/save", "Failed to fetch", "#save"))
  set_error_handler(default_error_handler)
  inspect(seen.join(","), content="NetworkError:MHX_NETWORK_ERROR")
}

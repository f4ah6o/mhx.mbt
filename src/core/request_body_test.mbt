///|
test "merge_request_bodies combines form and mx-vals" {
  let form_body = "name=hiro&count=1"
  let merged = merge_request_bodies(form_body, "{\"ok\":true}")
  inspect(merged, content="name=hiro&count=1&ok=true")
}

///|
test "merge_request_bodies appends mx-vals after duplicate form keys" {
  let merged = merge_request_bodies(
    "name=form&count=1", "{\"name\":\"vals\",\"enabled\":false,\"missing\":null}",
  )
  inspect(
    merged,
    content="name=form&count=1&name=vals&enabled=false&missing=null",
  )
}

///|
test "merge_request_bodies rejects nested mx-vals values" {
  let codes : Array[String] = []
  set_error_handler(fn(error : MhxError) { codes.push(error.code()) })
  let merged = merge_request_bodies("", "{\"payload\":{\"ok\":true}}")
  set_error_handler(default_error_handler)
  inspect(merged, content="")
  inspect(codes.join(","), content="MHX_CONFIG_ERROR")
}

///|
test "merge_request_bodies rejects array and non-object mx-vals" {
  let codes : Array[String] = []
  set_error_handler(fn(error : MhxError) { codes.push(error.code()) })
  let array_value = merge_request_bodies("name=hiro", "{\"tags\":[\"a\"]}")
  let top_level_array = merge_request_bodies("name=hiro", "[\"a\"]")
  set_error_handler(default_error_handler)
  inspect(array_value, content="name=hiro")
  inspect(top_level_array, content="name=hiro")
  inspect(codes.join(","), content="MHX_CONFIG_ERROR,MHX_CONFIG_ERROR")
}

///|
test "merge_request_bodies rejects malformed mx-vals pairs" {
  let codes : Array[String] = []
  set_error_handler(fn(error : MhxError) { codes.push(error.code()) })
  let merged = merge_request_bodies("name=hiro", "{\"broken\"}")
  set_error_handler(default_error_handler)
  inspect(merged, content="name=hiro")
  inspect(codes.join(","), content="MHX_CONFIG_ERROR")
}

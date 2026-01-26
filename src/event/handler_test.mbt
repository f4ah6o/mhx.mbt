///|
test "parse_element_config captures sync and vals" {
  let element = @ffi.document().create_element("button")
  element.set_attribute("mx-get", "/api")
  element.set_attribute("mx-sync", "queue:all")
  element.set_attribute("mx-vals", "{\"a\":1}")
  let config = parse_element_config(element)
  inspect(config.sync, content="Some(Queue(All))")
  inspect(config.vals, content="Some(\"{\\\"a\\\":1}\")")
}

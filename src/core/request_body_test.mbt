///|
test "merge_request_bodies combines form and mx-vals" {
  let form_body = "name=hiro&count=1"
  let merged = merge_request_bodies(form_body, "{\"ok\":true}")
  inspect(merged, content="name=hiro&count=1&ok=true")
}

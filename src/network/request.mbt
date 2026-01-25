///|
/// HTTP request handling for mhx
/// Wraps the Fetch API for making AJAX requests

///|
/// Request options for fetch
pub(all) struct RequestOptions {
  /// HTTP method (GET, POST, etc.)
  http_method : String
  /// Request headers
  headers : Map[String, String]
  /// Request body (for POST/PUT/PATCH)
  body : String?
  /// AbortSignal for cancellation
  signal : @ffi.AbortSignal?
}

///|
/// Create default GET request options
pub fn RequestOptions::default() -> RequestOptions {
  { http_method: "GET", headers: {}, body: Option::None, signal: Option::None }
}

///|
/// Create GET request options
pub fn RequestOptions::get() -> RequestOptions {
  RequestOptions::default()
}

///|
/// Create POST request options with body
pub fn RequestOptions::post(body : String) -> RequestOptions {
  {
    http_method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: Some(body),
    signal: Option::None,
  }
}

///|
/// Create POST request options with JSON body
pub fn RequestOptions::post_json(body : String) -> RequestOptions {
  {
    http_method: "POST",
    headers: { "Content-Type": "application/json" },
    body: Some(body),
    signal: Option::None,
  }
}

///|
/// Set abort signal
pub fn RequestOptions::with_signal(
  self : RequestOptions,
  signal : @ffi.AbortSignal,
) -> RequestOptions {
  { ..self, signal: Some(signal) }
}

///|
/// Add a header
pub fn RequestOptions::with_header(
  self : RequestOptions,
  name : String,
  value : String,
) -> RequestOptions {
  let headers = self.headers
  headers[name] = value
  { ..self, headers, }
}

///|
/// Convert to JSON string for FFI
pub fn RequestOptions::to_json_string(self : RequestOptions) -> String {
  let mut result = "{"
  result = result + "\"method\":\"" + self.http_method + "\""
  // Add headers if any
  if self.headers.length() > 0 {
    result = result + ",\"headers\":{"
    let mut first = true
    for key, value in self.headers {
      if not(first) {
        result = result + ","
      }
      result = result + "\"" + key + "\":\"" + value + "\""
      first = false
    }
    result = result + "}"
  }
  // Add body if present
  match self.body {
    Some(b) => result = result + ",\"body\":\"" + escape_json_string(b) + "\""
    None => ()
  }
  result = result + "}"
  result
}

///|
/// Escape special characters in JSON string
fn escape_json_string(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    match c {
      '"' => result = result + "\\\""
      '\\' => result = result + "\\\\"
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      _ => result = result + c.to_string()
    }
  }
  result
}

///|
/// Response wrapper with useful methods
pub(all) struct Response {
  /// The underlying JS response
  raw : @ffi.JsResponse
  /// Response body text (loaded after awaiting)
  body : String
}

///|
/// Create a Response from raw JS response and body
pub fn Response::new(raw : @ffi.JsResponse, body : String) -> Response {
  { raw, body }
}

///|
/// Get response status code
pub fn Response::status(self : Response) -> Int {
  self.raw.status()
}

///|
/// Check if response is ok (200-299)
pub fn Response::ok(self : Response) -> Bool {
  self.raw.ok()
}

///|
/// Get response body text
pub fn Response::text(self : Response) -> String {
  self.body
}

///|
/// Get a response header
pub fn Response::get_header(self : Response, name : String) -> String {
  self.raw.headers().get(name)
}

///|
/// Check if response was redirected
pub fn Response::redirected(self : Response) -> Bool {
  self.raw.redirected()
}

///|
/// Get final URL after redirects
pub fn Response::url(self : Response) -> String {
  self.raw.url()
}

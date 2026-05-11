# Security boundary

`mhx` fetches HTML fragments and inserts them into the DOM. The runtime treats
the response body as application-provided HTML, so the trust boundary is between
the application server and the browser runtime.

## Runtime responsibilities

`mhx` is responsible for deterministic request parsing, request scheduling,
target resolution, and DOM swap execution. It reports configuration, selector,
network, swap, and FFI failures through structured `MhxError` values.

`mhx` also validates `mx-vals` before those values are merged into request data.
`mx-vals` must be a JSON object whose values are flat scalars: string, number,
boolean, or `null`. Non-object input, malformed object entries, nested objects,
and arrays are rejected as `MHX_CONFIG_ERROR`. `mhx` never evaluates JavaScript
inside `mx-vals`.

## Application responsibilities

- no HTML sanitization
- no CSP management
- no cross-origin trust policy enforcement beyond the browser's own fetch rules

## Trust model

Applications should treat fetched fragments as trusted server output. If
untrusted HTML can reach the browser, the application must sanitize or reject it
before `mhx` swaps it into the DOM.

Same-origin responses are not automatically safe. They are only trusted when
the application controls the route that produced them and applies the same
authorization, escaping, and content validation that it would apply to a full
HTML page.

## Script handling policy

`mhx` relies on the browser's native handling of `innerHTML`, `outerHTML`, and
`insertAdjacentHTML`. It does not add a script execution layer, and it does not
strip `<script>` elements, inline event handlers, `javascript:` URLs, or other
executable markup before insertion.

Because browser behavior differs by DOM primitive and markup shape, application
code must not depend on `mhx` as a script blocker. If a route can return
attacker-controlled markup, sanitize that markup before it reaches the swap
boundary.

## Cross-origin guidance

Cross-origin requests are governed by browser `fetch` behavior, CORS,
credentials mode, cookies, and server policy. `mhx` does not add its own
cross-origin allowlist or blocklist.

Applications that intentionally fetch cross-origin fragments must make that
origin part of the application's trust model. Use normal origin controls such
as CORS, credential policy, CSP, and server-side authorization at the
application layer.

## Related contracts

- [Attribute contract](./attribute-contract.md) defines `mx-vals` shape and
  validation errors.
- [Swap contract](./swap-contract.md) defines the DOM primitives used for each
  swap strategy.
- [Error model](./error-model.md) defines structured `MhxError` fields and
  stable error codes.

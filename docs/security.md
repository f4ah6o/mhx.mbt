# security boundary

`mhx` fetches HTML fragments and inserts them into the DOM. That makes the trust boundary explicit.

## What mhx does not do

- no HTML sanitization
- no CSP management
- no cross-origin trust policy enforcement beyond the browser's own fetch rules
- no JavaScript evaluation inside `mx-vals`

## What mhx does do

- rejects malformed or unsafe `mx-vals` shapes (non-object input, nested objects, arrays)
- exposes structured errors for configuration, selector, swap, network, and FFI failures
- keeps runtime/package boundaries documented so application code knows where sanitization belongs

## Trust model

Applications should treat fetched fragments as trusted server output.
If untrusted HTML can reach the browser, the application must sanitize it before `mhx` swaps it into the DOM.

## Script handling policy

`mhx` relies on the browser's native handling of `innerHTML`, `outerHTML`, and `insertAdjacentHTML`.
It does not strip inline event handlers or other executable markup.

## Cross-origin guidance

Cross-origin requests are a browser/fetch concern, not a custom `mhx` policy.
Use normal origin controls (CORS, credentials, CSP, server trust boundaries) at the application layer.

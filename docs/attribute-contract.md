# mhx attribute contract

This document defines the stable `mx-*` attribute surface for `mhx`.
`mhx` is a low-level browser runtime. Anything not listed here is outside the
stable runtime contract and must not be relied on by applications.

Normative keywords such as "must", "must not", and "may" describe the public
contract. Error message text is not stable unless this document names a stable
error code.

## Supported attributes

| Attribute | Normative semantics | Default |
| --- | --- | --- |
| `mx-get` | Declares a GET request URL. The element becomes request-capable only when exactly one request attribute is present. | none |
| `mx-post` | Declares a POST request URL. Non-GET methods may include form data and `mx-vals` in the request body. | none |
| `mx-put` | Declares a PUT request URL. Non-GET methods may include form data and `mx-vals` in the request body. | none |
| `mx-patch` | Declares a PATCH request URL. Non-GET methods may include form data and `mx-vals` in the request body. | none |
| `mx-delete` | Declares a DELETE request URL. It uses the same method-selection and URL validation rules as the other request attributes. | none |
| `mx-trigger` | Declares the trigger DSL that schedules request execution. See [trigger spec](./trigger-spec.md). | tag-based default |
| `mx-target` | Declares the default swap target selector. A trigger-local `target:` modifier may override it. | triggering element |
| `mx-swap` | Declares the DOM swap strategy and options. See [swap contract](./swap-contract.md). | `innerHTML` |
| `mx-sync` | Declares element-local request coordination. See [request lifecycle](./request-lifecycle.md). | `drop` |
| `mx-vals` | Declares extra flat JSON scalar values that are merged into request data. | empty set |

## Defaults

- An element is request-capable only when exactly one of `mx-get`, `mx-post`,
  `mx-put`, `mx-patch`, or `mx-delete` is present. Elements that only carry
  non-request attributes such as `mx-trigger` or `mx-target` are inert for
  network execution.
- `mx-trigger` defaults to `submit` for `FORM`, `change` for `INPUT`,
  `TEXTAREA`, and `SELECT`, and `click` for every other tag.
- `mx-target` defaults to the triggering element, equivalent to `this`.
- `mx-swap` defaults to `innerHTML`.
- `mx-sync` defaults to `drop`.
- `mx-vals` defaults to an empty set of extra values.

## Request attribute precedence

`mx-get`, `mx-post`, `mx-put`, `mx-patch`, and `mx-delete` are mutually
exclusive. There is no implicit precedence order among request attributes. If
more than one request attribute appears on the same element, `mhx` must reject
the element before request execution with
`MHX_VALIDATE_CONFLICTING_REQUEST_METHODS`.

The selected request attribute value is the request URL. The URL must not be
empty after trimming ASCII whitespace. An empty request URL must be rejected
with `MHX_VALIDATE_EMPTY_REQUEST_URL`.

## Target and swap precedence

Target selection is evaluated in this order:

1. A trigger-local `target:` modifier in `mx-trigger`.
2. The element-level `mx-target` selector.
3. The triggering element itself.

`mx-target` and trigger-local target selectors may use the selector forms
defined by the trigger and swap contracts. The bare extended selector keywords
`closest`, `find`, `next`, and `previous` are incomplete by themselves and must
be rejected with `MHX_PARSE_INVALID_SELECTOR` when used as an element-level
`mx-target`.

`mx-swap` decides how a successful response mutates the resolved target. It
does not select the target and does not affect request scheduling.

## Trigger and sync precedence

`mx-trigger` controls when a request is scheduled. `mx-sync` controls how
concurrent requests for the same element are coordinated.

A trigger-local queue modifier and `mx-sync="queue ..."` express the same
coordination policy at different levels. Combining them on the same element is
invalid and must be rejected with `MHX_VALIDATE_TRIGGER_SYNC_CONFLICT`.

Other trigger modifiers such as `delay`, `throttle`, `debounce`, `once`,
`changed`, `consume`, and `prevent` remain trigger-local and do not override
`mx-sync`.

## Invalid combinations

`mhx` treats the following as configuration errors and refuses to process the
element:

- More than one request attribute on the same element.
- A request attribute whose URL is empty after trimming whitespace.
- `mx-target` selectors using incomplete extended forms such as `closest`,
  `find`, `next`, or `previous` without a trailing selector.
- A trigger-local queue modifier together with `mx-sync="queue ..."`.

## `mx-vals`

`mx-vals` must be a JSON object whose values are flat scalars:

- strings
- numbers
- booleans
- `null`

Nested objects and arrays are rejected with `MHX_CONFIG_ERROR`. Non-object
input, malformed key/value pairs, and invalid JSON object keys are also
configuration errors. `mhx` does not evaluate JavaScript inside `mx-vals`.

When request data is encoded, form fields are collected first and `mx-vals`
pairs are appended after them. Consumers that collapse duplicate keys into a map
must treat the later `mx-vals` value as the effective value. This gives
`mx-vals` precedence over same-named form fields without changing the raw
form-encoded order.

## Parse and validation behavior

- `mx-trigger` syntax errors surface as stable `MHX_PARSE_*` codes with parser
  positions.
- Runtime contract validation surfaces stable `MHX_VALIDATE_*` codes for
  conflicting methods, empty URLs, and queue/sync overlap.
- Element-level `mx-target` validation uses `MHX_PARSE_INVALID_SELECTOR` for
  incomplete extended selector syntax.
- `mx-swap` and `mx-sync` parsing must fall back to documented defaults for
  unknown strategy strings unless their own contract later defines stricter
  validation.
- Missing swap targets are runtime selector errors, not parse errors; see
  [swap contract](./swap-contract.md).

## Error code catalog

mhx exposes a stable error code on every `MhxError`. The `code()` method returns one of the following strings. Consumers should match on `code()` rather than `message()`, which may change between versions.

### Parse errors (`MHX_PARSE_*`)

These originate from the `mx-trigger` parser and carry a `position` field with the source offset and context.

| Code | Meaning |
| --- | --- |
| `MHX_PARSE_UNEXPECTED_CHAR` | Unexpected character while parsing trigger syntax |
| `MHX_PARSE_UNEXPECTED_END` | Unexpected end of input while parsing trigger syntax |
| `MHX_PARSE_INVALID_NUMBER` | Invalid numeric literal in trigger modifier |
| `MHX_PARSE_INVALID_MODIFIER` | Unknown trigger modifier name |
| `MHX_PARSE_INVALID_SELECTOR` | Invalid selector in trigger target |

### Validation errors (`MHX_VALIDATE_*`)

These are configuration-level checks that run before request execution. They carry `position=None` because they are not parser errors.

| Code | Meaning |
| --- | --- |
| `MHX_VALIDATE_CONFLICTING_REQUEST_METHODS` | Element has more than one request method attribute (`mx-get`, `mx-post`, etc.) |
| `MHX_VALIDATE_EMPTY_REQUEST_URL` | The request URL on a method attribute is empty |
| `MHX_VALIDATE_TRIGGER_SYNC_CONFLICT` | A trigger-local queue modifier conflicts with `mx-sync="queue ..."` |

### Runtime errors

| Code | Meaning |
| --- | --- |
| `MHX_NETWORK_ERROR` | Network request failed (non-abort, non-timeout) |
| `MHX_TIMEOUT_ERROR` | Request exceeded the timeout threshold |
| `MHX_ABORT_ERROR` | Request was cancelled (abort) |
| `MHX_DOM_ERROR` | DOM operation failed |
| `MHX_CONFIG_ERROR` | Generic configuration error (fallback for unspecified contract violations) |
| `MHX_SELECTOR_TARGET_NOT_FOUND` | Swap target selector did not match any DOM element |
| `MHX_SWAP_ERROR` | Swap operation failed |
| `MHX_FFI_ERROR` | JavaScript FFI bridge error |
| `MHX_INTERNAL_ERROR` | Internal runtime error |

### Error structure

Every `MhxError` exposes the public structured shape documented in
[error model](./error-model.md). The MoonBit API includes:

- `category()` – the variant name (`"ParseError"`, `"ConfigError"`, etc.)
- `code()` – the stable code string from the table above
- `message()` – human-readable description (not stable across versions)
- `attribute()` – the `mx-*` attribute that caused the error, if applicable
- `position()` – parser position, only for `ParseError` and config errors that originate from parsing
- `source_element()` – a description of the DOM element that triggered the error
- `is_recoverable()` / `recovery_strategy()` – whether the runtime can continue processing other elements

## Future compatibility policy

- new attributes must be documented here before they are considered stable
- unsupported `mx-*` attributes must not silently change the semantics of supported attributes
- runtime behavior may become stricter over time, but only by adding documented validation with stable error codes

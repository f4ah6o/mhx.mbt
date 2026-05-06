# mhx attribute contract

This document defines the supported `mx-*` attribute surface for `mhx`.
`mhx` is a low-level browser runtime. Anything not listed here is outside the v1 runtime contract.

## Supported attributes

| Attribute | Meaning | Default |
| --- | --- | --- |
| `mx-get` | issue a GET request | none |
| `mx-post` | issue a POST request | none |
| `mx-put` | issue a PUT request | none |
| `mx-patch` | issue a PATCH request | none |
| `mx-delete` | issue a DELETE request | none |
| `mx-trigger` | trigger DSL for request execution | tag-based default |
| `mx-target` | swap target selector | triggering element |
| `mx-swap` | DOM swap strategy/options | `innerHTML` |
| `mx-sync` | request coordination strategy | `drop` |
| `mx-vals` | extra flat JSON scalar values | none |

## Defaults

- request attributes are inert unless exactly one of `mx-get`, `mx-post`, `mx-put`, `mx-patch`, or `mx-delete` is present
- `mx-trigger` defaults to:
  - `submit` for `FORM`
  - `change` for `INPUT`, `TEXTAREA`, `SELECT`
  - `click` otherwise
- `mx-target` defaults to the triggering element (`this`)
- `mx-swap` defaults to `innerHTML`
- `mx-sync` defaults to `drop`
- `mx-vals` defaults to an empty set of extra values

## Invalid combinations

`mhx` treats the following as configuration errors and refuses to process the element:

- more than one request attribute on the same element
- an empty request URL
- `mx-target` selectors using incomplete extended forms such as `closest`, `find`, `next`, or `previous` without a trailing selector
- a trigger-local queue modifier together with `mx-sync="queue ..."`

## Precedence rules

- request method precedence is **not** implicit; multiple request attributes are invalid
- a trigger-local `target:` modifier overrides `mx-target`
- otherwise `mx-target` overrides the default `this`
- `mx-trigger` controls *when* a request is scheduled; `mx-sync` controls *how* concurrent requests are coordinated
- `mx-vals` augments form data; later `mx-vals` keys override same-named form fields in the encoded request body

## `mx-vals`

`mx-vals` must be a JSON object whose values are flat scalars:

- strings
- numbers
- booleans
- `null`

Nested objects and arrays are rejected with `MHX_CONFIG_ERROR`. `mhx` does not evaluate JavaScript inside `mx-vals`.

## Parse and validation behavior

- trigger syntax errors surface as stable `MHX_PARSE_*` codes with parser positions
- runtime contract validation surfaces stable `MHX_VALIDATE_*` codes for conflicting methods, empty URLs, and queue/sync overlap
- missing swap targets are runtime selector errors, not parse errors; see [swap contract](./swap-contract.md)

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

Every `MhxError` exposes:

- `category()` – the variant name (`"ParseError"`, `"ConfigError"`, etc.)
- `code()` – the stable code string from the table above
- `message()` – human-readable description (not stable across versions)
- `attribute()` – the `mx-*` attribute that caused the error, if applicable
- `position()` – parser position, only for `ParseError` and config errors that originate from parsing
- `source_element()` – a description of the DOM element that triggered the error
- `recoverable()` / `recovery_strategy()` – whether the runtime can continue processing other elements

## Future compatibility policy

- new attributes must be documented here before they are considered stable
- unsupported `mx-*` attributes must not silently change the semantics of supported attributes
- runtime behavior may become stricter over time, but only by adding documented validation with stable error codes

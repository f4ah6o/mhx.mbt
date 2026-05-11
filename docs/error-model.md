# mhx error model

`MhxError` is the public low-level error model for `mhx`.
Applications, logging code, and higher-level wrappers should match on stable
machine-readable fields instead of parsing human-readable messages.

## Public shape

Every `MhxError` is serializable as JSON with these stable keys:

| Field | Type | Semantics |
| --- | --- | --- |
| `category` | string | Stable error family. Current values are `ParseError`, `NetworkError`, `TimeoutError`, `AbortError`, `DomError`, `ConfigError`, `SelectorError`, `SwapError`, `FfiError`, and `InternalError`. |
| `code` | string | Stable machine-readable code. Consumers should branch on this field. |
| `message` | string | Human-readable diagnostic text. This is useful for logs, but not a stable matching surface. |
| `attribute` | string or `null` | The `mx-*` attribute associated with the error when the failure is attribute-scoped. |
| `sourceElement` | string or `null` | A compact source element description, such as `#save` or `button`, when the runtime knows the triggering element. |
| `position` | object or `null` | Parser position for parse-originated failures. |
| `recoverable` | boolean | Whether the runtime can continue processing other elements or requests after this error. |

MoonBit `Option` values serialize as `null` in the public JavaScript payload
when no value is available.

## Position shape

`position` is present for `ParseError` and for `ConfigError` values that wrap a
parser failure. It is `null` for network, timeout, abort, selector, swap, FFI,
internal, and non-parser configuration errors.

When present, `position` has this shape:

```json
{
  "offset": 7,
  "char": "\u0000"
}
```

`offset` is the zero-based offset in the parsed attribute value. `char` is the
character observed at that offset. End-of-input diagnostics use `"\u0000"`.

## Stable codes

The complete stable code catalog is maintained in
[attribute contract](./attribute-contract.md#error-code-catalog).
The current families are:

- `MHX_PARSE_*`
- `MHX_VALIDATE_*`
- `MHX_NETWORK_ERROR`
- `MHX_TIMEOUT_ERROR`
- `MHX_ABORT_ERROR`
- `MHX_DOM_ERROR`
- `MHX_CONFIG_ERROR`
- `MHX_SELECTOR_TARGET_NOT_FOUND`
- `MHX_SWAP_ERROR`
- `MHX_FFI_ERROR`
- `MHX_INTERNAL_ERROR`

## Error handler contract

`set_error_handler` receives the structured `MhxError` value, not just a text
message. Handlers can call `category()`, `code()`, `message()`, `attribute()`,
`source_element()`, `position()`, and `is_recoverable()`, or serialize the
whole value with `to_json()` for logging.

The default handler logs a JSON payload, so log processors can index stable
fields without parsing the message.

## Event detail contract

`mhx:error` event detail carries:

```json
{
  "error": {
    "category": "SelectorError",
    "code": "MHX_SELECTOR_TARGET_NOT_FOUND",
    "message": "No DOM element matched the requested swap target",
    "attribute": null,
    "sourceElement": "#save",
    "position": null,
    "recoverable": true
  },
  "sourceElement": "#save"
}
```

Failed `mhx:afterRequest` detail uses the same full `error` object. Successful
request events use `"error": null`.

## Compatibility

New categories or codes may be added in later versions. Existing `category`,
`code`, and field names must remain stable for documented errors. Message text
may change when diagnostics are clarified.

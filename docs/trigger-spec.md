# mhx trigger spec

`mx-trigger` is the request scheduling DSL consumed by `mhx-spec` and executed by `mhx`.

## Supported event forms

Examples:

- `click`
- `click once`
- `input changed debounce:300ms`
- `click[ctrlKey] delay:500ms`
- `submit prevent queue:last`
- `intersect once`

## Event names

`mhx` accepts ordinary DOM event names plus the runtime-level lifecycle names described in [request lifecycle](./request-lifecycle.md).

Common runtime-facing examples:

- `click`
- `submit`
- `change`
- `input`
- `keydown`
- `keyup`
- `mouseenter`
- `mouseleave`
- `load`
- `revealed`
- `intersect`

## Supported modifiers

- `once`
- `changed`
- `delay:<duration>`
- `throttle:<duration>`
- `debounce:<duration>`
- `from:<selector>`
- `target:<selector>`
- `consume`
- `prevent`
- `queue:drop`
- `queue:replace`
- `queue:first`
- `queue:last`
- `queue:all`
- `[filter]`

## Duration syntax

Current runtime parsing accepts:

- `100`
- `100ms`
- `1s`
- `1.5s`

## Filters

Filters are evaluated as JavaScript expressions against the DOM event object.
A filter failure prevents request execution.
A filter evaluation error is treated as `false`.

## Parse errors

Stable parse-oriented codes emitted by `mhx` are:

- `MHX_PARSE_UNEXPECTED_CHAR`
- `MHX_PARSE_UNEXPECTED_END`
- `MHX_PARSE_INVALID_NUMBER`
- `MHX_PARSE_INVALID_MODIFIER`
- `MHX_PARSE_INVALID_SELECTOR`

Parse errors carry parser positions (`offset`, `char`) through the structured `MhxError` payload.

## Notes

- `mx-trigger` decides scheduling only; request execution still depends on request attributes being valid
- trigger-local `target:` affects swap target selection
- trigger-local queue modifiers should not be combined with `mx-sync="queue ..."`

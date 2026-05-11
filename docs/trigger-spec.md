# mhx trigger spec

`mx-trigger` is the request scheduling DSL consumed by `mhx-spec` and executed by `mhx`.
The parser is independent from DOM, network, and browser runtime state: it turns an attribute string into a deterministic trigger AST or a structured parse error.

## Grammar overview

A trigger attribute is a comma-separated list of trigger definitions:

```text
trigger-list = trigger ("," trigger)*
trigger      = event-name filter? modifier*
filter       = "[" expression "]"
modifier     = name | name ":" value
```

Whitespace may appear between event names, filters, modifiers, colons, and comma separators.
Modifier order is preserved in the parsed output.

Supported examples:

- `click`
- `click once`
- `input changed debounce:300ms`
- `click[ctrlKey] delay:500ms`
- `submit prevent queue:last`
- `intersect once`
- `load, click once, input changed debounce:300ms`

## Event names

Event names are identifiers made from ASCII letters, digits, `_`, and `-`.
The parser does not maintain an allow-list; runtime behavior depends on whether the event can be observed by the browser integration.

Common DOM event names:

- `click`
- `submit`
- `change`
- `input`
- `keydown`
- `keyup`
- `mouseenter`
- `mouseleave`

Runtime lifecycle event names:

- `load` - fires when an element is processed for initial loading behavior
- `revealed` - fires when an element becomes visible according to runtime observation
- `intersect` - fires when an element intersects the viewport or observer root

## Filters

A filter follows the event name and is written as `[expression]`.
The expression is stored as a string without the surrounding brackets.

Examples:

- `click[ctrlKey]`
- `keyup[key=='Enter']`
- `input[target.value!='']`

Filters are evaluated by the runtime against the DOM event object.
A false result prevents request execution; an evaluation error is treated as false.
The parser only checks that the closing `]` exists.

## Modifiers

Boolean modifiers have no value:

- `once` - fire the trigger once
- `changed` - continue only when the element value changed since the previous matching trigger
- `consume` - call `stopPropagation()`
- `prevent` - call `preventDefault()`

Value modifiers use `name:value`:

- `delay:<duration>` - wait before scheduling the request
- `throttle:<duration>` - schedule at most once per duration
- `debounce:<duration>` - wait for a quiet period before scheduling
- `from:<selector>` - listen from another element
- `target:<selector>` - override the swap target for this trigger
- `queue:<mode>` - choose request queue behavior

## Duration values

Duration values are integer numbers with an optional unit:

- `300` means 300 milliseconds
- `300ms` means 300 milliseconds
- `1s` means 1000 milliseconds

Decimal values such as `1.5s` are not part of the current parser contract.
Use milliseconds for fractional-second durations, for example `1500ms`.

## Selectors

`from:` and `target:` values are parsed as selector expressions.

Special selectors:

- `this`
- `body`
- `window`
- `document`

Extended selectors:

- `closest <css-selector>`
- `find <css-selector>`
- `next <css-selector>`
- `previous <css-selector>`

Any other value is treated as a CSS selector.

Examples:

- `click from:body`
- `click target:#result`
- `click from:closest .item target:find .result`
- `click from:next .row target:previous .message`

## Queue modifiers

Queue modifiers use the colon form `queue:<mode>`.
Supported modes are:

- `queue:drop` - drop new requests while one is in flight
- `queue:replace` - replace the active request with the new request
- `queue:first` - keep only the first pending request
- `queue:last` - keep only the latest pending request
- `queue:all` - keep all pending requests in FIFO order

The default queue mode is `drop` when no queue modifier is present.
Trigger-local queue modifiers should not be combined with `mx-sync="queue ..."`.
That conflict is a configuration validation error rather than a trigger parse error.

## Parse output

The parser returns an array of trigger definitions.
Each definition has:

- `event` - the event name
- `modifiers` - modifiers in source order

Selector modifiers use the same JSON shape as `mhx-spec`:

- special selectors such as `this`, `body`, `window`, and `document` serialize
  as string values
- ordinary CSS selectors serialize as `{ "css": "<selector>" }`
- extended selectors serialize as `{ "closest": "<selector>" }`,
  `{ "find": "<selector>" }`, `{ "next": "<selector>" }`, or
  `{ "previous": "<selector>" }`

Golden tests assert the JSON form of this AST so output ordering remains deterministic.

Example:

```json
{
  "Ok": [
    {
      "event": "submit",
      "modifiers": [
        { "type": "prevent" },
        { "type": "queue", "mode": "last" }
      ]
    }
  ]
}
```

## Parse errors

Parse errors are structured values from `mhx-spec/parser`.
Each error includes the parser position (`offset`, `char`) and either an expected token or an invalid value.
Repo-local golden fixtures pair the original input with the error so diagnostics can include input, position, and reason.

Stable parse-oriented codes emitted by `mhx` when parser errors are wrapped are:

- `MHX_PARSE_UNEXPECTED_CHAR`
- `MHX_PARSE_UNEXPECTED_END`
- `MHX_PARSE_INVALID_NUMBER`
- `MHX_PARSE_INVALID_MODIFIER`
- `MHX_PARSE_INVALID_SELECTOR`

Representative invalid trigger expressions:

- `click delay` - missing `:` after a value modifier
- `click delay:abc` - missing integer duration
- `click queue:middle` - unsupported queue mode
- `click[ctrlKey` - unclosed filter
- `[ctrlKey]` - missing event name

## Boundaries

- `mx-trigger` decides scheduling only; request execution still requires a valid request attribute such as `mx-get` or `mx-post`.
- `target:` affects swap target selection for the matching trigger.
- DOM event observation, network execution, and selector lookup are runtime concerns outside the parser contract.

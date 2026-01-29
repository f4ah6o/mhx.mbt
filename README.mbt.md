# mhx - MoonBit Hypermedia X
<!-- bdg:begin -->
[![npm](https://img.shields.io/npm/v/mhx.svg)](https://www.npmjs.com/package/mhx)
![moonbit](https://img.shields.io/badge/moonbit-f4ah6o/mhx-informational)
[![license](https://img.shields.io/github/license/f4ah6o/mhx.mbt.svg)](https://github.com/f4ah6o/mhx.mbt)
[![CI](https://github.com/f4ah6o/mhx.mbt/actions/workflows/npm-publish.yaml/badge.svg)](https://github.com/f4ah6o/mhx.mbt/actions/workflows/npm-publish.yaml)
[![CI](https://github.com/f4ah6o/mhx.mbt/actions/workflows/ci.yaml/badge.svg)](https://github.com/f4ah6o/mhx.mbt/actions/workflows/ci.yaml)
<!-- bdg:end -->

A type-safe Hypermedia-Driven Architecture (HDA) library for MoonBit/WebAssembly, inspired by [htmx](https://htmx.org).

## Features

- **Type-safe trigger parsing** - Parser combinator-based DSL for `mx-trigger` attributes with compile-time safety
- **Event delegation** - Efficient single-listener pattern for handling DOM events
- **Async fetch** - Callback-based HTTP requests with request queuing and sync strategies
- **Timing modifiers** - Built-in support for `delay`, `throttle`, and `debounce`
- **MutationObserver integration** - Automatic processing of dynamically added elements
- **Minimal footprint** - Leverages WasmGC and JS String Builtins for zero-copy DOM interop

## Installation

Add to your `moon.mod.json`:

```json
{
  "deps": {
    "f4ah6o/mhx": "0.1.0"
  }
}
```

## Usage

### HTML Attributes

mhx uses `mx-*` attributes (not `hx-*`) to define hypermedia behaviors:

```html
<!-- Simple GET request -->
<button mx-get="/api/data" mx-target="#result">
  Load Data
</button>

<!-- POST with trigger modifiers -->
<form mx-post="/api/submit" mx-trigger="submit" mx-swap="outerHTML">
  <input name="email" type="email" />
  <button type="submit">Submit</button>
</form>

<!-- Click with delay and filter -->
<button mx-get="/api/action"
        mx-trigger="click[ctrlKey] delay:500ms">
  Ctrl+Click (with 500ms delay)
</button>

<!-- Debounced input -->
<input mx-get="/api/search"
       mx-trigger="input changed debounce:300ms"
       mx-target="#search-results"
       name="q" />
```

### Supported Attributes

| Attribute | Description |
|-----------|-------------|
| `mx-get` | Issue GET request to URL |
| `mx-post` | Issue POST request to URL |
| `mx-put` | Issue PUT request to URL |
| `mx-patch` | Issue PATCH request to URL |
| `mx-delete` | Issue DELETE request to URL |
| `mx-trigger` | Event that triggers the request |
| `mx-target` | CSS selector for response target |
| `mx-swap` | How to swap the response into DOM |
| `mx-sync` | Request synchronization strategy |
| `mx-vals` | JSON values to include in request |

### Trigger Syntax

The `mx-trigger` attribute supports a rich DSL:

```
event[filter] modifier:value, event2[filter2]
```

**Events:**
- Standard DOM events: `click`, `submit`, `input`, `change`, `keyup`, etc.
- Special events: `load`, `revealed`, `intersect`

**Modifiers:**
- `once` - Fire only once
- `changed` - Fire only when value changes
- `delay:Nms` - Delay before firing
- `throttle:Nms` - Fire at most once per interval
- `debounce:Nms` - Fire after quiet period
- `from:selector` - Listen on different element
- `target:selector` - Specify action target
- `consume` - Stop event propagation
- `prevent` - Prevent default behavior
- `queue:mode` - Request queue mode (`drop`, `replace`, `first`, `last`, `all`). Example: `queue all`.

**Filters:**
- `[ctrlKey]` - Require Ctrl key
- `[shiftKey]` - Require Shift key
- `[altKey]` - Require Alt key
- `[target.value!='']` - Custom JS expression

### Swap Strategies

| Strategy | Description |
|----------|-------------|
| `innerHTML` | Replace inner content (default) |
| `outerHTML` | Replace entire element |
| `beforebegin` | Insert before element |
| `afterbegin` | Insert at start of element |
| `beforeend` | Insert at end of element |
| `afterend` | Insert after element |
| `delete` | Remove the element |
| `none` | No swap, just trigger events |

### Selectors

Target and from selectors support:
- `this` - Current element
- `closest selector` - Find closest ancestor
- `find selector` - Find within element
- `body`, `document`, `window` - Special targets
- Any CSS selector

## Architecture

```
src/
+-- ffi/           # FFI bindings + mhx_ffi.js
|   +-- element.mbt, document.mbt, event.mbt
|   +-- fetch.mbt, mutation_observer.mbt
|   +-- mhx_ffi.js  # JS glue code
+-- event/         # Event system
|   +-- delegation.mbt, cache.mbt, handler.mbt, timing.mbt
+-- network/       # HTTP layer
|   +-- request.mbt, manager.mbt, async_fetch.mbt
+-- swap/          # DOM swap operations
+-- core/          # Main integration
    +-- mhx.mbt, error.mbt
```

Shared specification types and parsers now live in `mhx-spec.mbt/`.

### Key Components

- **TriggerDef** - Typed AST for trigger definitions
- **Modifier** - Enum of all trigger modifiers (Once, Delay, Throttle, etc.)
- **Selector** - Typed selector expressions (This, Closest, Find, Css)
- **EventDelegator** - Central event handling with delegation pattern
- **ConfigCache** - Caches parsed configurations per element
- **TimingManager** - Manages delay/throttle/debounce state
- **RequestManager** - Handles request queuing and sync strategies

## API

### Initialization

```moonbit
// Initialize mhx on document load
fn main {
  @core.init_mhx()
}
```

### Processing Dynamic Content

```moonbit
// Process newly added elements
let element = document.query_selector("#new-content")
@core.process(element)
```

### Error Handling

```moonbit
// Set custom error handler
@core.set_error_handler(fn(error : MhxError) {
  match error {
    Parse(msg, pos) => console.error("Parse error: " + msg)
    Network(status, msg) => console.error("Network error: " + msg)
    Timeout => console.error("Request timed out")
    _ => console.error("Error: " + error.to_string())
  }
})
```

## Development

```bash
# Check types
moon check --target js

# Run tests
moon test --target js

# Format code
moon fmt

# Build
moon build --target js
```

## Comparison with htmx

| Feature | htmx | mhx |
|---------|------|-----|
| Language | JavaScript | MoonBit/Wasm |
| Attribute prefix | `hx-*` | `mx-*` |
| Parsing | Regex/string split | Parser combinator |
| Type safety | Runtime | Compile-time |
| Error messages | Generic | Precise location |
| Bundle size | ~14KB gzip | <10KB (estimated) |
| DOM interop | Native | WasmGC + externref |

## Use mhx with tmpx

[tmpx](https://mooncakes.io/docs/#/f4ah6o/tmpx/) is a typed, functional HTML template DSL for MoonBit. While tmpx provides `hx-*` helpers for htmx, you can use mhx attributes directly:

### Basic mhx Attributes

```moonbit
// Using generic attr function for mx-* attributes
let button = @tmpx.button(
  [
    @tmpx.attr("mx-get", "/api/data"),
    @tmpx.attr("mx-target", "#result"),
    @tmpx.attr("mx-swap", "innerHTML"),
  ],
  [@tmpx.text("Load Data")],
)
```

### Full Example: Server-Side Template

```moonbit
fn ticket_card(id : Int, title : String) -> @tmpx.Node {
  @tmpx.div(
    [
      @tmpx.class_("card"),
      @tmpx.attr("mx-get", "/partials/ticket/\{id}"),
      @tmpx.attr("mx-target", "#pane-center"),
      @tmpx.attr("mx-swap", "innerHTML"),
      @tmpx.attr("mx-trigger", "click"),
    ],
    [
      @tmpx.h2([], [@tmpx.text("Ticket #\{id}")]),
      @tmpx.p([], [@tmpx.text(title)]),
    ],
  )
}

fn search_form() -> @tmpx.Node {
  @tmpx.input_(
    [
      @tmpx.type_("text"),
      @tmpx.name_("q"),
      @tmpx.attr("mx-get", "/api/search"),
      @tmpx.attr("mx-trigger", "input changed debounce:300ms"),
      @tmpx.attr("mx-target", "#search-results"),
    ],
  )
}
```

### Architecture with tmpx + mhx

```
Server (MoonBit + tmpx)          Browser (MoonBit/Wasm + mhx)
+------------------------+       +---------------------------+
| Generate HTML with     |       | Parse mx-* attributes     |
| mx-* attributes using  | ----> | Handle events             |
| tmpx templates         | <---- | Fetch HTML fragments      |
| Return HTML fragments  |       | Swap into DOM             |
+------------------------+       +---------------------------+
```

This architecture keeps all your code in MoonBit while following HATEOAS principles - the server returns hypermedia (HTML), not data (JSON).

## License

Apache-2.0
## npm Distribution

The JavaScript runtime can be packaged for npm with the compiled output in `dist/`.

1. Build the JS runtime:

```bash
moon -C mhx.mbt build --target js
```

2. Copy the JS output and FFI into `dist/`:

- `dist/index.js` (compiled output)
- `dist/mhx_ffi.js` (FFI glue)

3. Use the npm wrapper entry:

- `npm/index.js` initializes the FFI via `initMhxFfi` and re-exports the public API.






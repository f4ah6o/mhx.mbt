# mhx

MoonBit Hypermedia X (mhx) is a type-safe Hypermedia-Driven Architecture (HDA)
library for the browser, inspired by htmx. It uses `mx-*` attributes to declare
hypermedia behavior and runs as a compact JS runtime compiled from MoonBit.

## Install

```bash
npm install mhx
```

## Usage

Import the runtime and initialize it once on startup. The npm entry already
initializes the FFI glue.

```js
import mhx, { init_mhx } from "mhx";

init_mhx();
```

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
<button mx-get="/api/action" mx-trigger="click[ctrlKey] delay:500ms">
  Ctrl+Click (with 500ms delay)
</button>

<!-- Debounced input -->
<input
  mx-get="/api/search"
  mx-trigger="input changed debounce:300ms"
  mx-target="#search-results"
  name="q"
/>
```

## API

The npm entry exports the following helpers:

- `init_mhx()` - initialize mhx (call once after DOM is ready)
- `process(element)` - process newly added elements
- `handle_event(event)` - manually dispatch an event
- `get_instance()` - access the internal singleton instance
- `version` - runtime version string

```js
import { process } from "mhx";

const node = document.querySelector("#new-content");
process(node);
```

## Build from Source

```bash
pnpm build
```

This builds a single bundled file for each format:

- `dist/mhx.esm.js` - ES Module format
- `dist/mhx.umd.js` - UMD format (for script tags)

## CDN Usage

You can load mhx directly from a CDN without npm:

```html
<script src="https://unpkg.com/mhx/dist/mhx.umd.js"></script>
<script>
  mhx.init_mhx();
  mhx.process(document.body);
</script>
```

## Migration Guide

### From v2026.1.19 or earlier

The package structure has changed to use single-file bundles.

**Before (v2026.1.19):**

```js
// Entry point was npm/index.js which imported from dist/
import mhx from "mhx";
import ffi from "mhx/ffi"; // Separate FFI import was available
```

**After (v2026.1.20+):**

```js
// Single bundled entry point - FFI is included
import mhx from "mhx";
```

**Key changes:**

- The `mhx/ffi` export has been removed (FFI is now bundled)
- All functionality is in a single file per format
- UMD build available for direct `<script>` tag usage

## License

Apache-2.0

# FFI boundary

`mhx` runs across MoonBit code and a JavaScript glue layer in `src/ffi/mhx_ffi.js`.

## Stable browser-package exports

The npm/browser contract exposes only:

- `init_mhx`
- `process`
- `handle_event`
- `version`
- the default namespace object containing the same stable members

The bundle does **not** expose internal fetch callback hooks such as `on_fetch_success`, `on_fetch_error`, or mutation observer plumbing.

## Stable FFI responsibilities

Stable runtime FFI responsibilities are:

- DOM reads and writes used by swap execution
- event listener registration
- fetch bridge start/cancel
- MutationObserver callback bridge
- timer bridge
- lifecycle `CustomEvent` dispatch (`mhx:*`)
- console logging for diagnostics

## Internal-only FFI responsibilities

Internal-only glue includes:

- callback registries for async fetch bookkeeping
- MoonBit export registration helpers
- temporary build-time wiring needed to bootstrap the browser bundle

## Failure mapping

- fetch bridge failures become structured network or abort errors
- lifecycle `CustomEvent` dispatch failures become `MHX_FFI_ERROR`
- unstable internal callbacks are intentionally kept out of the public bundle surface

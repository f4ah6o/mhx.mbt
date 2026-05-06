# Formalize the JavaScript FFI boundary

Created: 2026-05-05
Model: N/A

## Summary

Formalize the JavaScript FFI boundary used by the MoonBit/Wasm runtime.

## Motivation

For a browser runtime implemented across MoonBit, Wasm, and JavaScript, the FFI boundary is effectively part of the kernel. It should be explicit which functions are stable and which are internal.

## Scope

Document FFI responsibilities for:

- DOM read/write functions
- event listener registration
- fetch bridge
- MutationObserver bridge
- timer bridge
- logging / error bridge

## Acceptance criteria

- `src/ffi/README.md` or `docs/ffi-boundary.md` exists
- FFI functions are classified as stable or internal
- ESM / UMD bundles do not expose unstable internals as public API
- FFI failure is converted into structured `MhxError`
- tests cover representative FFI failure behavior where possible

## Non-goals

- no alternate runtime backend required
- no Node.js DOM implementation required

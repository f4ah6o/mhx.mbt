# Formalize the JavaScript FFI boundary

Created: 2026-05-05
Completed: 2026-05-11
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

## 解決方法

- `docs/ffi-boundary.md` を更新し、npm/browser の stable exports、runtime FFI responsibilities、internal-only glue、failure mapping を明文化した。
- npm smoke test で ESM / UMD の public surface を `init_mhx` / `process` / `handle_event` / `version` / default namespace に固定し、package subpath exports が internal FFI glue を公開しないことを確認した。
- `src/core/mhx.mbt` に request / swap lifecycle event 用の dispatch helper を追加し、JavaScript FFI dispatch failure が `MHX_FFI_ERROR` の structured `MhxError` として report されるようにした。
- smoke test に representative FFI dispatch failure を追加し、JS FFI が例外を raw throw せず MoonBit 側で `MhxError` 化できる message として返すことを確認した。

# Stabilize MhxError as a structured error model

Created: 2026-05-05
Completed: 2026-05-11
Model: N/A

## Summary

Stabilize `MhxError` as a structured, machine-readable low-level error model.

## Motivation

Applications and higher-level libraries should not need to parse error message strings. mhx should expose stable error categories and codes.

## Proposed categories

- `ParseError`
- `SelectorError`
- `NetworkError`
- `TimeoutError`
- `SwapError`
- `FfiError`
- `InternalError`

## Proposed fields

Each error should include:

- `code`
- `message`
- `attribute`, when applicable
- `sourceElement`, when available
- `position`, for parse errors
- `recoverable`, when meaningful

## Acceptance criteria

- public error shape is documented
- errors are serializable for logging
- error handler receives structured data
- tests assert stable error codes, not only message text
- parse errors include enough location information for diagnostics

## Non-goals

- no application-specific error UI
- no localization requirement

## 解決方法

`docs/error-model.md` を追加し、`MhxError` の public JSON shape として `category`、`code`、`message`、`attribute`、`sourceElement`、`position`、`recoverable` を明文化した。`position` は `offset` と `char` を持つ parser position とし、optional field は JavaScript event detail では `null`、MoonBit snapshot では `[]` / `[value]` として扱うことを書いた。

既存の `MhxError::to_json()` と default error handler は structured JSON を出せていたため、広い refactor は避けた。request failure lifecycle event は `category` / `message` だけではなく full `MhxError` JSON を渡すようにし、abort error も source element を持てる helper を追加した。

`src/core/error_test.mbt` で parse / selector / network / abort / timeout / swap / FFI / internal / config の stable code と JSON shape を確認し、error handler が structured `MhxError` を受け取ることも確認した。npm smoke では failed request event detail が full structured error object を保持することを追加で固定した。
